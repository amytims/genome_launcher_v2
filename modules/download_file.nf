process DOWNLOAD_FILE {
    publishDir "${params.outdir}/raw_reads/${data_type}", mode: 'symlink'

    input:
    tuple val(sample_id), val(file_name), val(url), val(file_checksum)
    val(data_type)

    output:
    tuple val("$sample_id"), val("$file_name"), val("$url"), emit: info
    path "$file_name", emit: file

    script:
    """
    wget --header="X-CKAN-API-Key: ${params.bpa_api_token}" $url -O $file_name

    echo "$file_checksum $file_name" | md5sum -c

    """
}