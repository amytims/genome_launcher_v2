#!/bin/bash -l
#SBATCH --job-name=afgi_p_halophilus
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4g
#SBATCH --time=1-00
#SBATCH --account=pawsey1132
#SBATCH --partition=work

module load singularity/4.1.0-nohost

unset SBATCH_EXPORT

# Application specific commands:
set -eux

# for debugging purposes
printenv | grep "SLURM" > vars_in_main_script.txt

# sample to run - organism grouping key
SAMPLE_ID="Pseudomugil_sp_h_PU_2024_3240756"

# sanger_tol pipeline parameters
PIPELINE_VERSION="a6f7cb6"
SOURCE_DIRNAME="Pseudomugil_halophilus"
RESULT_DIRNAME="PseudomugilHalophilus3240756" # dataset_id for DToL pipeline - do not include underscores!
RESULT_VERSION="v1"

PIPELINE_PARAMS=(
        "--input" "results/config/config_file.yaml"
        "--outdir" "s3://pawsey1132.afgi.assemblies/${RESULT_DIRNAME}/results/sanger_tol"
        "--timestamp" "${RESULT_VERSION}"
        "--hifiasm_hic_on"
        "-profile" "singularity,pawsey"
        "-r" "${PIPELINE_VERSION}"
        "-c" "sangertol_nf.config"
)

# where to put the results files
OUTPUT_DIRECTORY="s3://pawsey1132.afgi.assemblies/${RESULT_DIRNAME}/results/sanger_tol"
#OUTPUT_DIRECTORY="results_${SAMPLE_ID}"

# where to put singularity files
if [ -z "${SINGULARITY_CACHEDIR}" ]; then
	export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/atims/.singularity
	export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

export NXF_APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}/library"
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}/library"

# load the manual nextflow install
export PATH="${PATH}:/software/projects/pawsey1132/atims/assembly_testing/bin"
printf "nextflow: %s\n" "$( readlink -f $( which nextflow ) )"

# set the NXF home for plugins etc
export NXF_HOME="/software/projects/pawsey1132/atims/assembly_testing/${SOURCE_DIRNAME}/.nextflow"
export NXF_CACHE_DIR="/scratch/pawsey1132/atims/assembly_testing/${SOURCE_DIRNAME}/.nextflow"
export NXF_WORK="${NXF_CACHE_DIR}/work"
printf "NXF_HOME: %s\n" "${NXF_HOME}"
printf "NXF_WORK: %s\n" "${NXF_WORK}"

# run launcher nextflow workflow
nextflow run main.nf -profile pawsey --BPA_API_TOKEN ${BPA_API_TOKEN} \
    --outdir ${OUTPUT_DIRECTORY} --sample_id ${SAMPLE_ID} \
    --hic_data true --hifiadapterfilt true --read_length_summary true \
    --jsonl /home/atims/data_mapper_output_250828 \
    -c launcher.config -resume
exit 0
 
# check assembly pipeline before running
nextflow \
       -log "nextflow_logs/nextflow_inspect.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
       inspect \
       -concretize sanger-tol/genomeassembly \
       "${PIPELINE_PARAMS[@]}"
exit 0
 
# run assembly pipeline
nextflow \
        -log "nextflow_logs/nextflow_run.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
        run \
        sanger-tol/genomeassembly \
        "${PIPELINE_PARAMS[@]}" \
        -resume