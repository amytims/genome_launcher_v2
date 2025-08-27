process PLOT_READ_LENGTHS {
    publishDir "${params.outdir}/qc/read_length_distributions", mode: 'copy'

    input:
    path "*"

    output:
    path "*_read_length_distributions.pdf", emit: pdf

    script:
    """
    module load ${params.R}
    echo \${PWD}
    cat *_read_lengths.txt > read_lengths.txt

    Rscript ${projectDir}/scripts/read_lengths.R \${PWD} ${params.sample_id}
    """
}