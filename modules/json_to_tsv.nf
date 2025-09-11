process JSON_TO_TSV {
    //publishDir = "${params.outdir}"

    input:
    path jsonl

    output:
    path "reformatted_json.tsv", emit: tsv

    script:
    """
    echo "organism_grouping_key\tbpa_sample_id\tlibrary_strategy\tplatform\tfile_name\tfile_checksum\turl\tbusco_lineage\tGenus_species" > reformatted_json.tsv

    cat ${jsonl} | jq -r '(. as \$r | \$r.runs[] | [
        \$r.organism.organism_grouping_key,
        \$r.sample.bpa_sample_id,
        \$r.experiment.library_strategy,
        \$r.experiment.platform,
        .file_name,
        .file_checksum,
        .bioplatforms_url,
        \$r.organism.busco_dataset_name,
        \$r.organism.scientific_name
    ]) | @tsv' >> reformatted_json.tsv

    """
}