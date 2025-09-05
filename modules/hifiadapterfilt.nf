process HIFIADAPTERFILT {
    publishDir "${params.outdir}/qc/hifiadapterfilt", mode: 'copy', pattern: "${basename}.blocklist"
    publishDir "${params.outdir}/qc/hifiadapterfilt", mode: 'copy',  pattern: "${basename}.contaminant.blastout"
    publishDir "${params.outdir}/qc/hifiadapterfilt", mode: 'copy',  pattern: "${basename}.stats"

    input:
    path file
    
    output:
    path "${basename}.blocklist", emit: blocklist
    path "${basename}.contaminant.blastout", emit: blastout
    path "${basename}.filt.fastq.gz", emit: filt_fastq_gz
    path "${basename}.stats", emit: stats

    script:
    basename = file.getBaseName(1)
    """
    hifiadapterfilt.sh -l ${params.hifiadapterfilt_l} -m ${params.hifiadapterfilt_m} -t ${task.cpus}
    """
}