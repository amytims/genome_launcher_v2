process HIFIADAPTERFILT {
    publishDir "${params.outdir}/qc/hifiadapterfilt", pattern: "${basename}.blocklist"
    publishDir "${params.outdir}/qc/hifiadapterfilt", pattern: "${basename}.contaminant.blastout"
    publishDir "${params.outdir}/qc/hifiadapterfilt", pattern: "${basename}.stats"

    input:
    path file
    
    output:
    path "${basename}.blocklist", emit: blocklist
    path "${basename}.contaminant.blastout", emit: blastout
    path "${basename}.filt.fastq.gz", emit: filt_fastq_gz
    path "${basename}.stats", emit: stats

    when:
    params.hifiadapterfilt == true

    script:
    basename = file.getBaseName(2)
    """
    export PATH=$PATH:${params.hifiadapterfilt_path}:${params.hifiadapterfilt_path}/DB
    echo $PATH

    module load ${params.bamtools}
    module load ${params.blast}

    hifiadapterfilt.sh -p ${basename} -l ${params.hifiadapterfilt_l} -m ${params.hifiadapterfilt_m} -t ${task.cpus}
    """
}