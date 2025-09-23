process CONCAT_PACBIO_READS {
    publishDir "${params.outdir}/processed_reads/hifi", mode: 'copy'

    container = (params.filter_pacbio_adapters ? 'depot.galaxyproject.org/singularity/seqkit:2.10.1--he881be0_0':'depot.galaxyproject.org/singularity/samtools_1.22.1--h96c455f_0')

    input:
    path "*"

    output:
    path "ccs_reads.fasta.gz", emit: filtered_pacbio

    script:
    
    if ( params.filter_adapters )
        """
        seqkit fq2fa -j ${task_cpus} -o ccs_reads.fasta.gz
        """
    else
        """
        samtools cat *.bam | samtools fasta -@${task.cpus-1} -0 ccs_reads.fasta.gz
        """
}