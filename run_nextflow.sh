#!/bin/bash
#SBATCH --job-name=nextflow-master
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=04:00:00
#SBATCH --partition=work

unset SBATCH_EXPORT

# Application specific commands:
set -eux

module load singularity/4.1.0-slurm

# where to put singularity files
if [ -z "${SINGULARITY_CACHEDIR}" ]; then
	export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/atims/.singularity
	export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

export NXF_APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}/library"
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}/library"

# sample to run
SAMPLE_ID="Nematalosa_erebi_316163"

# where to put the results files
#OUTPUT_DIRECTORY="s3://pawsey1132.amy.testing/${SAMPLE_ID}/results/sanger_tol"
OUTPUT_DIRECTORY="results_${SAMPLE_ID}"

# run nextflow
bin/nextflow run main.nf -profile pawsey --BPA_API_TOKEN ${BPA_API_TOKEN} \
    --outdir ${OUTPUT_DIRECTORY} --sample_id ${SAMPLE_ID} \
    --hic_data true --hifiadapterfilt true --read_length_summary true \
    --jsonl /home/atims/data_mapper_output