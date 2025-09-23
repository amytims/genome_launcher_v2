def help_file() {
    log.info """
    #######################################################################################
    ######################### RUN QC AND SUMMARY STATS ON RAW DATA #########################
    #######################################################################################

        --sample_id SAMPLE_ID
                BPA organism grouping key of species for which to download data. 
                Input .jsonl will be filtered on this field so only files corresponding 
                to the grouping key will be downloaded. Sample ID should be of the form 
                'taxid12345', where 12345 is the NCBI taxonomy id of the species

        --jsonl <PATH/TO/JSONL/FILE>
                Path to the .jsonl file outputted by the data mapper

        --bpa_api_token BPA_API_TOKEN
                API token for BioPlatforms Australia, enables downloading of datasets
                that may not be publically accessible. Token can be created by logging 
                into https://data.bioplatforms.com/, then going to
                https://data.bioplatforms.com/user/<username>/api-tokens, and clicking 
                'Create API Token'. 

        --outdir <PATH/TO/OUTPUT/DIRECTORY>
                File path to where results should be stored
                Default is './results'

        --pacbio_data
                Does the sample_id have PacBio HiFi data files to download, or not?
                Default is 'false'

        --hic_data
                Does the sample_id have HiC data files to download, or not?
                Default is 'false'

        --ont_data
                Does the sample_id have Oxford Nanopore data files to download, or not?
                Default is 'false'

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
        
        pacbio_samples_ch = Channel.fromPath("${params.outdir}/raw_reads/hifi")
        pacbio_samples_ch.view()

        // filter adapters if desired
        if ( params.filter_pacbio_adapters ) {
            BAM_TO_FASTQ(pacbio_samples_ch)
            CUTADAPT(BAM_TO_FASTQ.out.fastq)
        }

        // sumarize read lengths if desired
        if ( params.read_length_summary ) {

            if ( params.filter_adapters ) {
                read_length_summary_ch = CUTADAPT.out.filt_fastq_gz
            } else {
                read_length_summary_ch = pacbio_samples_ch
            }

            READ_LENGTH_SUMMARY(read_length_summary_ch)

            plot_read_lengths_ch = READ_LENGTH_SUMMARY.out.read_lengths.collect()

            PLOT_READ_LENGTHS(plot_read_lengths_ch)
        }

        // concat pacbio reads and convert to fasta.gz output
        if ( params.filter_adapters ) {
            concat_and_zip_ch = CUTADAPT.out.filt_fastq_gz.collect()
        } else {
            concat_and_zip_ch = pacbio_samples_ch.collect()
        }

        CONCAT_AND_ZIP(concat_and_zip_ch)
    }
}