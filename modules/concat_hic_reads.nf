process CONCAT_HIC_READS {
    publishDir "${params.outdir}/reads/hic", mode: 'copy'

    input:
        path "*"

    output:
        path "${params.sample_id}.cram", emit: cram
        path "${params.sample_id}.cram.crai", emit: crai
        path "${params.sample_id}.flagstat", emit: flagstat

    script:
    """
    cat *_R1_*.fastq.gz > hic_merged_R1.fastq.gz &
    cat *_R2_*.fastq.gz > hic_merged_R2.fastq.gz &

    wait

    samtools import -@${task.cpus} hic_merged_R1.fastq.gz hic_merged_R2.fastq.gz \
    -r ID:${params.sample_id} \
    -r CN:"arima" \
    -r PU:${params.sample_id} \
    -r SM:${params.sample_id} \
    -o "${params.sample_id}.cram" 

    rm hic_merged_R1.fastq.gz
    rm hic_merged_R2.fastq.gz

    samtools index "${params.sample_id}.cram" 

    samtools flagstat "${params.sample_id}.cram" > "${params.sample_id}.flagstat" 

    """

}