process BAM_TO_FASTA {
    input:
    path input_bam
    
    output:
    path "${basename}.fasta.gz", emit: fasta_gz

    script:
    basename = input_bam.getBaseName(1)
       // # -c 1 -0 ${basename}.fasta.gz
    """
    # Note: --threads value represents *additional* CPUs to allocate (total CPUs = 1 + --threads)
    samtools fasta --threads ${task.cpus-1} $input_bam > ${basename}.fasta

    """
}