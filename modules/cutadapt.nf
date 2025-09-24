process CUTADAPT {
    publishDir "${params.outdir}/qc/cutadapt", mode: 'copy',  pattern: "${basename}.cutadapt.log"

    input:
    path fastq
    path adapters

    output:
    path "${basename}.trim.fastq.gz", emit: filt_fastq_gz
    path "${basename}.cutadapt.log", emit: cutadapt_log

    script:
    basename = fastq.getBaseName(1)
    def args = task.ext.args ?: ''
    """
    cutadapt --cores ${task.cpus} --anywhere 'file:${adapters}' \
        ${args} \
        --output ${basename}.trim.fastq \
        ${fastq} \
        > ${basename}.cutadapt.log

    pigz --fast ${basename}.trim.fastq
    """
}
