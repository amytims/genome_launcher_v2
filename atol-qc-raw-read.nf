def help_file() {
    log.info """
    #######################################################################################
    ##################### RUN QC AND SUMMARY STATS ON DOWNLOADED DATA #####################
    #######################################################################################

        --indir <PATH/TO/INPUT/DIRECTORY>
                File path to raw_reads directory where the output of 
                atol-bpa-data-mover.nf is stored
                Default is './results/raw_reads'
        
        --outdir <PATH/TO/OUTPUT/DIRECTORY>
                File path to where processed reads and QC results should be stored
                Default is './results'

        --pacbio_data
                Are there PacBio HiFi data files to run, or not?
                Default is 'false'

        --hic_data
                Are there HiC data files to run, or not?
                Default is 'false'

        --ont_data
                Are there Oxford Nanopore data files to run, or not?
                Default is 'false'

        --filter_pacbio_adapters
                Run cutadapt on pacbio data to filter residual adapters?
                Default is 'true'
                
                Following Hanrahan et al. 2025 (doi.org/10.1093/g3journal/jkaf046),
                cutadapt is run with the following parameters: 
                    --error-rate 0.1 
                    --overlap 25 
                    --match-read-wildcards 
                    --revcomp 
                    --discard-trimmed

                To change this, edit the ext.args line in atol-qc-raw-read.config

        --pacbio_adapters_fasta
                Path to .fasta file containing PacBio HiFi adapters to filter
                Default is 'assets/pacbio_adapters.fa'

        --read_length_summary
                Plot read length distribution summary and calculate stats?
                Default is 'true'

    #######################################################################################
    """.stripIndent()
}


// print help file if requested
if ( params.remove('help') ) {
    help_file()
    exit 0
}

// check no unexpected parameters were specified
allowed_params = [
    // pipeline inputs
    "indir",
    "outdir",
    "pacbio_data",
    "hic_data",
    "ont_data",

    "filter_pacbio_adapters",
    "pacbio_adapters_fasta",
    "read_length_summary",

    // Pawsey options
    "max_cpus",
    "max_memory"
]

params.each { entry ->
    if ( !allowed_params.contains(entry.key) ) {
        println("The parameter <${entry.key}> is not known");
        exit 0;
    }
}


include { BAM_TO_FASTQ } from './modules/bam_to_fastq.nf'
include { CUTADAPT } from './modules/cutadapt.nf'
include { READ_LENGTH_SUMMARY } from './modules/read_length_summary.nf'
include { PLOT_READ_LENGTHS } from './modules/plot_read_length_summary.nf'
include { CONCAT_PACBIO_READS } from './modules/concat_pacbio_reads.nf'


// 
workflow {
    // process any pacbio data
    if ( params.pacbio_data ) {
        
        pacbio_samples_ch = Channel.fromPath("${params.indir}/hifi/*")
        pacbio_samples_ch.view()

        // filter adapters if desired
        if ( params.filter_pacbio_adapters ) {
            BAM_TO_FASTQ(pacbio_samples_ch)
            CUTADAPT(BAM_TO_FASTQ.out.fastq, "${params.pacbio_adapters_fasta}")
        }

        // sumarize read lengths if desired
        if ( params.read_length_summary ) {

            if ( params.filter_pacbio_adapters ) {
                read_length_summary_ch = CUTADAPT.out.filt_fastq_gz
            } else {
                read_length_summary_ch = pacbio_samples_ch
            }

            READ_LENGTH_SUMMARY(read_length_summary_ch)

            plot_read_lengths_ch = READ_LENGTH_SUMMARY.out.read_lengths.collect()

            PLOT_READ_LENGTHS(plot_read_lengths_ch)
        }

        // concat pacbio reads and convert to fasta.gz output
        if ( params.filter_pacbio_adapters ) {
            concat_pacbio_reads_ch = CUTADAPT.out.filt_fastq_gz.collect()
        } else {
            concat_pacbio_reads_ch = pacbio_samples_ch.collect()
        }

        CONCAT_PACBIO_READS(concat_pacbio_reads_ch)
    }
}