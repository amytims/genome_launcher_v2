process BAM_TO_FASTQ {
    input:
    path input_bam
    
    output:
    path "${basename}.fastq", emit: fastq

    script:
    basename = input_bam.getBaseName(1)
    """
    # Note: --threads value represents *additional* CPUs to allocate (total CPUs = 1 + --threads)
    samtools fastq --threads ${task.cpus-1} $input_bam > ${basename}.fastq
    """
}