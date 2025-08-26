process CONCAT_AND_ZIP {
    publishDir "${params.outdir}/reads/hifi"
    input:
    path "*"

    output:
    path "${params.sample_id}_ccs_reads.fasta.gz", emit: filtered_pacbio

    script:
    if params.hifiadapterfilt
        container 'depot.galaxyproject.org/singularity/seqtk-1.4--h577a1d6_3.img'
        """
        if command -v pigz &> /dev/null
        then
            zcat *.fastq.gz | seqtk -a | pigz -p ${task.cpus} --fast > "${params.sample_id}_ccs_reads.fasta.gz"
        else
            zcat *.fastq.gz | seqtk -a | gzip > "${params.sample_id}_ccs_reads.fasta.gz"
        fi
        """
    else
        container "depot.galaxyproject.org/singularity/samtools-1.17--h00cdaf9_0.img"
        """
        samtools cat *.bam | samtools fasta -@${task.cpus} -0 "${params.sample_id}_ccs_reads.fasta.gz" 
        """
}