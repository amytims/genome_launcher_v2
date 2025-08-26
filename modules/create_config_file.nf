process CREATE_CONFIG_FILE {
    publishDir "${params.outdir}/config", mode: 'copy'
    publishDir "results/config", mode: 'copy'

    input:
    tuple val(busco_lineage), val(Genus_species)
    path filtered_pacbio
    path hic
    
    output:
    path "config_file.yaml"

"""
echo "dataset:" >> config_file.yaml
echo "  id: ${params.sample_id}"  >> config_file.yaml
echo "  pacbio:" >> config_file.yaml
echo "    reads:" >> config_file.yaml
echo "        - reads: ${params.outdir}/reads/hifi/${filtered_pacbio}" >> config_file.yaml
echo "  HiC:" >> config_file.yaml
echo "    reads:" >> config_file.yaml
if [! -v ${hic}]
then
echo "        - reads: ${params.outdir}/reads/hic/${hic}" >> config_file.yaml
fi
echo "hic_motif: GATC,GANTC,CTNAG,TTAA" >> config_file.yaml
echo "hic_aligner: bwamem2" >> config_file.yaml
echo "busco:" >> config_file.yaml
echo "  lineage: ${busco_lineage}" >> config_file.yaml
echo "mito:" >> config_file.yaml
echo "  species: ${Genus_species}" >> config_file.yaml
echo "  min_length: 15000" >> config_file.yaml
echo "  code: 5" >> config_file.yaml

"""
}