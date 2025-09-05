def help_file() {
    log.info """
    #######################################################################################
    ######################### THIS WILL EVENTUALLY BE A HELP FILE #########################
    #######################################################################################

        --outdir <PATH/TO/OUTPUT/DIRECTORY>
                File path to where results should be stored

        --hic_data
                Does the sample_id have corresponding HiC data, or not?
                Default is 'true'

        --jsonl <PATH/TO/JSONL/FILE>
                Path to the .jsonl file outputted by the data mapper

        --samplesheet [DEPRECATE OR LEAVE IN FOR FUTURE?]
                Path to the samplesheet containing information on samples to be
                downloaded. This will definitely be updated soon, but for now it's
                a .csv with the following column headers:
                    sample_id       Sample ID on which data in the samplesheet will be
                                        filtered. Should correspond to an individual.

                    data_type       The type of data within each file. Currently
                                        supported types: 'PacBio', 'HiC'

                    file_name       The name of the file to be downloaded

                    url             The URL from which to download the file

                    busco_lineage   The busco lineage to be used with the sample in
                                        downstream analyses

                    Genus_species   Binomial name of the sample specimen

        --sample_id SAMPLE_ID
                Name of the sample to be analysed. Input samplesheet will be filtered
                so only files corresponding to the sample id will be processed

        --hifiadapterfilt
                Option to run hifiadapterfilt on input PacBio files to remove any
                remaining adapters.
                Default is 'false'

        --hifiadapterfilt_path <PATH/TO/HIFIADAPTERFILT/SOFTWARE>
                    >>>> TO FIX WHEN I FIGURE OUT HOW TO CONTAINERS BETTER <<<<
                Path to downloaded hifiadapterfilt program. This program is not an
                included module on Pawsey and if I use a container it falls over
                because it can't access bamtools or blast dependencies.
                Default is '/software/projects/PROJECTNAME/USERNAME/HiFiAdapterFilt'

        --hifiadapterfilt_l <INT>
                Default is 25

        --hifiadapterfilt_m <INT>
                Default is 97

        --read_length_summary
                Option to generate a histogram of read lengths for input PacBio files
                Default is 'false'

        --R <MODULE_VERSION>
                Version of R to be invoked by 'module load' in 'plot_read_length_summary'
                Default is r/4.4.1

        --bamtools <MODULE_VERSION>
                Version of bamtools to be invoked by 'module load' in 'hifiadapterfilt'
                Default is 'bamtools/2.5.2--hd03093a_0'
                
        --blast <MODULE_VERSION>
                Version of blast to be invoked by 'module load' in 'hifiadapterfilt'
                Default is 'blast/2.12.0--pl5262h3289130_0'
        
    #######################################################################################
    """.stripIndent()
}

include { JSON_TO_TSV } from './modules/json_to_tsv.nf'

include { DOWNLOAD_FILE as DOWNLOAD_FILE_PACBIO} from './modules/download_file.nf'
include { DOWNLOAD_FILE as DOWNLOAD_FILE_HIC} from './modules/download_file.nf'

include { HIFIADAPTERFILT } from './modules/hifiadapterfilt.nf'

include { READ_LENGTH_SUMMARY } from './modules/read_length_summary.nf'
include { PLOT_READ_LENGTHS } from './modules/plot_read_length_summary.nf'

include { CONCAT_AND_ZIP } from './modules/concat_and_zip.nf'
include { CONCAT_HIC_READS } from './modules/concat_hic_reads.nf'

include { CREATE_CONFIG_FILE } from './modules/create_config_file.nf'

workflow {

    if (params.remove('help')) {
        help_file()
        exit 0
    }

    // ~~~ getting lists of samples ~~~

    // set up channel for input jsonl file
    json_to_tsv_ch = Channel.fromPath(params.jsonl)

    // parse it to tsv format for legibility
    JSON_TO_TSV(json_to_tsv_ch)

    // read in all the rows of the new tsv file
    all_samples = JSON_TO_TSV.out.tsv
        .splitCsv(header:true, sep:'\t')
        //.view()

    // get pacbio read urls for sample of interest
    pacbio_samples = all_samples
        .filter { sample -> sample.organism_grouping_key == "${params.sample_id}" }
        .filter { sample -> sample.library_strategy == "WGS" }
        .filter { sample -> sample.platform == "PACBIO_SMRT" }
        .map {sample -> [sample.organism_grouping_key, sample.file_name, sample.url] }

    // if no PacBio Samples are found, throw an error and exit the process
    pacbio_samples.ifEmpty { error("Error: No PacBio samples corresponding to sample id \"${params.sample_id}\" could be found.") }
    //pacbio_samples.view()

    // get hic read urls for the sample of interest

    if ( params.hic_data ) {
        hic_samples = all_samples
            .filter { sample -> sample.organism_grouping_key == "${params.sample_id}" }
            .filter { sample -> sample.library_strategy == "Hi-C" }
            .map { sample -> [sample.organism_grouping_key, sample.file_name, sample.url] }

        hic_samples.ifEmpty { error(
            """
            \'--hic_data\' param is set to true, but no Hi-C samples corresponding to sample id \"${params.sample_id}\" could be found.
            Check sample information or set \'--hic_data false\'
            """) }
        //hic_samples.view()
    }


    // ~~~ PACBIO READ PROCESSING ~~~

    // download the pacbio files
    DOWNLOAD_FILE_PACBIO(pacbio_samples)

    if (params.hifiadapterfilt) {
        HIFIADAPTERFILT(DOWNLOAD_FILE_PACBIO.out.file)
    }

    if (params.read_length_summary) {

        if (params.hifiadapterfilt) {
            read_length_summary_ch = HIFIADAPTERFILT.out.filt_fastq_gz
        } else {
            read_length_summary_ch = DOWNLOAD_FILE_PACBIO.out.file
        }

    READ_LENGTH_SUMMARY(read_length_summary_ch)

    plot_read_lengths_ch = READ_LENGTH_SUMMARY.out.read_lengths.collect()

    PLOT_READ_LENGTHS(plot_read_lengths_ch)
    }

    if (params.hifiadapterfilt) {
        concat_and_zip_ch = HIFIADAPTERFILT.out.filt_fastq_gz.collect()
    } else {
        concat_and_zip_ch = DOWNLOAD_FILE_PACBIO.out.file.collect()
    }

    CONCAT_AND_ZIP(concat_and_zip_ch)


    // ~~~ HI-C READ PROCESSING ~~~

    // download the pacbio files
    DOWNLOAD_FILE_HIC(hic_samples)
    //DOWNLOAD_FILE_HIC.out.file.collect.view()

    hic_concat_ch = DOWNLOAD_FILE_HIC.out.file.collect()
    //hic_concat_ch.view()

    CONCAT_HIC_READS(hic_concat_ch)
 

    // ~~~ set up input channels for config file ~~~

    // pacbio samples file
    pacbio_config_ch = CONCAT_AND_ZIP.out.filtered_pacbio
    //pacbio_config_ch.view()

    // busco lineage, etc
    other_info = all_samples
         .filter { sample -> sample.organism_grouping_key == "${params.sample_id}" }
         .map {sample -> [sample.busco_lineage, sample.Genus_species] }
         .unique()
         //.view()

    // hic file - if empty because no hic files, point at empty dummy file
    if (!params.hic_data) {
        hic_config_ch = file("${projectDir}/assets/dummy_hic")
    } else {
        hic_config_ch = CONCAT_HIC_READS.out.cram
    }

    //hic_config_ch.view()

    // ~~~ create the config file ~~~
    CREATE_CONFIG_FILE(other_info, pacbio_config_ch, hic_config_ch)
}