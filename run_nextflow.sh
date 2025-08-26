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

# install hifiadapterfilt
#singularity run https://depot.galaxyproject.org/singularity/hifiadapterfilt:3.0.0--hdfd78af_0

# install seqtk
#singularity run https://depot.galaxyproject.org/singularity/seqtk:1.4--h577a1d6_3

# run nextflow
bin/nextflow run main.nf -profile pawsey --BPA_API_TOKEN ${BPA_API_TOKEN} \
    --hic_data true --hifiadapterfilt false --read_length_summary false