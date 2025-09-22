

def help_file() {
    log.info """
    #######################################################################################
    ######################### DOWNLOAD FILES FROM BPA DATA PORTAL #########################
    #######################################################################################

        --sample_id SAMPLE_ID
                BPA organism grouping key of species for which to download data. Input
                .jsonl will be filtered on this field so only files corresponding to the 
                grouping key will be downloaded. Sample ID should be of the form 
                'txid12345', where 12345 is the NCBI taxonomy id of the species

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
                Does the sample_id have corresponding PacBio HiFi data, or not?
                Default is 'false'

        --hic_data
                Does the sample_id have corresponding HiC data, or not?
                Default is 'false'

        --ont_data
                Does the sample_id have corresponding Oxford Nanopore data, or not?
                Default is 'false'

    #######################################################################################
    """.stripIndent()
}

if (params.remove('help')) {
    help_file()
    exit 0
}

allowed_params = [
                "sample_id",
                "jsonl",
                "bpa_api_token",
                "outdir",
                "pacbio_data",
                "hic_data",
                "ont_data"
                ]

params.each { entry ->
  if (!allowed_params.contains(entry.key)) {
      println("The parameter <${entry.key}> is not known");
      exit 0;
  }
}

if (!params.sample_id) {error(
    """
    No organism grouping key provided: \'--sample_id\'
    """
)}

if (!params.jsonl) {error(
    """
    No data mapper output file provided: \'--jsonl\'
    """
)}

if (file(params.jsonl).!exists()) {error(
    """
    Data mapper output file provided by \'--jsonl\' does not exist
    """
)}

if (!params.bpa_api_token) {error(
    """
    No BPA API token provided: \'--bpa_api_token\'
    """
)}

if (!params.hifi_data && !params.hic_data && !params.ont_data) {error(
    """
    \'--hifi_data\', \'--hic_data\', and \'--ont_data\' flags are all set to false.
    No data files will be downloaded. Please set at least one data flag.
    """
)}


include { JSON_TO_TSV } from './modules/json_to_tsv.nf'

include { DOWNLOAD_FILE as DOWNLOAD_FILE_PACBIO} from './modules/download_file.nf'
include { DOWNLOAD_FILE as DOWNLOAD_FILE_HIC} from './modules/download_file.nf'
include { DOWNLOAD_FILE as DOWNLOAD_FILE_ONT} from './modules/download_file.nf'

workflow {

    // ################################
    // ### getting lists of samples ###
    // ################################

    // set up channel for input jsonl file
    json_to_tsv_ch = Channel.fromPath(params.jsonl)

    // parse it to tsv format for legibility
    JSON_TO_TSV(json_to_tsv_ch)

    // read in all the rows of the new tsv file
    all_samples = JSON_TO_TSV.out.tsv
        .splitCsv(header:true, sep:'\t')
        //.view()

    // ##################################################
    // ### get pacbio reads for sample_id of interest ###
    // ##################################################

    if ( params.pacbio_data ) {

        pacbio_samples = all_samples
            .filter { sample -> sample.organism_grouping_key == "${params.sample_id}" } // keeps only the samples for the species we want
            .filter { sample -> sample.platform == "PACBIO_SMRT" } // keeps only the PacBio samples
            .filter { sample -> sample.library_strategy == "WGS" } // keeps only the WGS ones - filters out longread RNA-seq 
                    // NOTE: also filters out a few samples with WGA library strategy
                    // if we want to keep these, maybe instead filter on "library_source: GENOMIC"
            .filter { sample -> sample.optional_file == "false" } // filters out any .subreads.bam files
            .map {sample -> [sample.organism_grouping_key, sample.file_name, sample.url, sample.file_checksum] }

        // if no PacBio Samples are found, throw an error and exit the process
        pacbio_samples.ifEmpty { error(
            """
            \'--pacbio_data\' is set as true, but no PacBio samples corresponding to sample id 
            \"${params.sample_id}\" could be found.
            Check sample information or turn off \'--pacbio_data\' flag
            """
            ) }
        //pacbio_samples.view()

        DOWNLOAD_FILE_PACBIO(pacbio_samples, 'hifi')

    }


    // ###############################################
    // ### get hic reads for sample_id of interest ###
    // ###############################################

    if ( params.hic_data ) {
        hic_samples = all_samples
            .filter { sample -> sample.organism_grouping_key == "${params.sample_id}" }
            .filter { sample -> sample.library_strategy == "Hi-C" }
            .map { sample -> [sample.organism_grouping_key, sample.file_name, sample.url] }

        hic_samples.ifEmpty { error(
            """
            \'--hic_data\' is flagged, but no Hi-C samples corresponding to sample id 
            \"${params.sample_id}\" could be found.
            Check sample information or turn off \'--hic_data\' flag
            """) }

        DOWNLOAD_FILE_HIC(hic_samples, 'hic')
    }


    // ###############################################
    // ### get ont reads for sample_id of interest ###
    // ###############################################

    // NOTE: there is currently no nanopore data in the data mapper output

    // if ( params.ont_data ) {
    //     ont_samples = all_samples
    //         .filter { sample -> sample.organism_grouping_key == "${params.sample_id}" }
    //         .filter { sample -> sample.library_strategy == "ONT" }
    //         .map { sample -> [sample.organism_grouping_key, sample.file_name, sample.url] }

    //     ont_samples.ifEmpty { error(
    //         """
    //         \'--ont_data\' is flagged, but no ONT samples corresponding to sample id 
    //         \"${params.sample_id}\" could be found.
    //         Check sample information or turn off \'--ont_data\' flag
    //         """) }

    //     DOWNLOAD_FILE_ONT(hic_samples, 'ont')
    // }

}