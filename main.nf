include { DOWNLOAD_FILE as DOWNLOAD_FILE_PACBIO} from './modules/download_file.nf'
include { DOWNLOAD_FILE as DOWNLOAD_FILE_HIC} from './modules/download_file.nf'

include { HIFIADAPTERFILT } from './modules/hifiadapterfilt.nf'

include { READ_LENGTH_SUMMARY } from './modules/read_length_summary.nf'
include { PLOT_READ_LENGTHS } from './modules/plot_read_length_summary.nf'

include { CONCAT_AND_ZIP } from './modules/concat_and_zip.nf'

include { CREATE_CONFIG_FILE } from './modules/create_config_file.nf'

workflow {

    // ~~~ getting lists of samples ~~~

    // read in all the rows of the sample sheet
    all_samples = Channel.fromPath(params.samplesheet)
        .splitCsv(header:true)
        //.view()

    // get pacbio read urls for sample of interest
    pacbio_samples = all_samples
        .filter { sample -> sample.sample_id == "${params.sample_id}" }
        .filter { sample -> sample.data_type == "PacBio" }
        .map {sample -> [sample.sample_id, sample.file_name, sample.url] }

    // if no PacBio Samples are found, throw an error and exit the process
    pacbio_samples.ifEmpty { error("Error: No PacBio samples corresponding to sample id \"${params.sample_id}\" could be found.") }
    //pacbio_samples.view()

    // get hic read urls for the sample of interest

    if ( params.hic_data ) {
        hic_samples = all_samples
            .filter { sample -> sample.sample_id == "${params.sample_id}" }
            .filter { sample -> sample.data_type == "HiC" }
            .map { sample -> [sample.sample_id, sample.file_name, sample.url] }

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

    // ~~~ set up input channels for config file ~~~

    // pacbio samples file
    pacbio_config_ch = CONCAT_AND_ZIP.out.filtered_pacbio
    //pacbio_config_ch.view()

    // busco lineage, etc
    other_info = all_samples
         .filter { sample -> sample.sample_id == "${params.sample_id}" }
         .map {sample -> [sample.busco_lineage, sample.Genus_species] }
         .unique()
         .view()

    // hic file - if empty because no hic files, point at empty dummy file
    if (!params.hic_data) {
        hic_config_ch = file("${projectDir}/assets/dummy_hic")
    }

    //hic_config_ch.view()

    // ~~~ create the config file ~~~
    CREATE_CONFIG_FILE(other_info, pacbio_config_ch, hic_config_ch)
}