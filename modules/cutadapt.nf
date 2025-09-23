process CUTADAPT {
    publishDir 

    input:
    path fastq

    output:
    path "${basename}.trim.fastq.gz", emit: filt_fastq_gz
    path "${basename}.cutadapt.log", emit: cutadapt_log

    script:
    basename = file.getBaseName(1)
    def args = task.ext.args ?: ''
    """
    cutadapt --cores ${task.cpus} --anywhere 'file:${params.pacbio_adapters_fasta}' \
        --error-rate 0.1 --overlap 25 ${args} \
        --output ${basename}.trim.fastq \
        ${fastq} \
        > ${basename}.cutadapt.log

    pigz --fast ${basename}.trim.fastq
    """
}