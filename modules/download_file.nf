process DOWNLOAD_FILE {
    input:
    tuple val(sample_id), val(file_name), val(url)
    
    output:
    tuple val("$sample_id"), val("$file_name"), val("$url"), emit: info
    path "$file_name", emit: file
    
    script:
    """
    wget --header="X-CKAN-API-Key: ${params.BPA_API_TOKEN}" $url -O $file_name
    """
}