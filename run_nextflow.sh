#!/bin/bash
#SBATCH --job-name=nextflow-master
#SBATCH --time=1-00:00:00
#SBATCH --mem=4G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

module load singularity/4.1.0-nohost

unset SBATCH_EXPORT

# Application specific commands:
set -eux

# where to put singularity files
if [ -z "${SINGULARITY_CACHEDIR}" ]; then
	export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/atims/.singularity
	export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

export NXF_APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}/library"
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}/library"

# sample to run
SAMPLE_ID="yalmyTest460406"

# where to put the results files
#OUTPUT_DIRECTORY="s3://pawsey1132.amy.testing/${SAMPLE_ID}/results/sanger_tol"
OUTPUT_DIRECTORY="results"

# run nextflow
bin/nextflow run main.nf -profile pawsey --BPA_API_TOKEN ${BPA_API_TOKEN} \
    --outdir ${OUTPUT_DIRECTORY} --sample_id ${SAMPLE_ID} \
    --hic_data true --hifiadapterfilt false --read_length_summary false