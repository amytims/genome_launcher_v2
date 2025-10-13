#!/bin/bash -l
#SBATCH --job-name=atol-bpa-data-mover-test
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
SAMPLE_ID="GadopsisMarmoratus135755"

# # sanger_tol pipeline parameters
# PIPELINE_VERSION="a6f7cb6"
SOURCE_DIRNAME="Gadopsis_marmoratus"
# RESULT_DIRNAME="PseudomugilHalophilus3240756" # dataset_id for DToL pipeline - do not include underscores!
# RESULT_VERSION="v1"

# PIPELINE_PARAMS=(
#         "--input" "results/config/config_file.yaml"
#         "--outdir" "s3://pawsey1132.afgi.assemblies/${RESULT_DIRNAME}/results/sanger_tol"
#         "--timestamp" "${RESULT_VERSION}"
#         "--hifiasm_hic_on"
#         "-profile" "singularity,pawsey"
#         "-r" "${PIPELINE_VERSION}"
#         "-c" "sangertol_nf.config"
# )

# where to put the results files
#OUTPUT_DIRECTORY="s3://pawsey1132.afgi.assemblies/${RESULT_DIRNAME}/results/sanger_tol"
OUTPUT_DIRECTORY="results"

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

## run bpa-data-mover
#nextflow run atol-bpa-data-mover.nf -c atol-bpa-data-mover.config -profile pawsey \
#    --outdir ${OUTPUT_DIRECTORY} \
#    --sample_id ${SAMPLE_ID} \
#    --jsonl /home/atims/data_mapper_output_250919 \
#    --bpa_api_token ${BPA_API_TOKEN} 
#exit 0

# run bpa-data-mover
nextflow run atol-bpa-data-mover.nf -c atol-bpa-data-mover.config -profile pawsey \
    --outdir ${OUTPUT_DIRECTORY} \
    --sample_id ${SAMPLE_ID} \
    --use_samplesheet \
    --samplesheet test_samplesheet.csv \
    --pacbio_data \
    --hic_data \
    --bpa_api_token ${BPA_API_TOKEN} 
exit 0

# run bpa-qc-raw-read on pacbio data
nextflow run atol-qc-raw-read.nf -c atol-qc-raw-read.config -profile pawsey \
    --indir ${OUTPUT_DIRECTORY} \
    --outdir ${OUTPUT_DIRECTORY} \
    --pacbio_data \
    --filter_pacbio_adapters false \
    --read_length_summary false
exit 0
 
# # check assembly pipeline before running
# nextflow \
#        -log "nextflow_logs/nextflow_inspect.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
#        inspect \
#        -concretize sanger-tol/genomeassembly \
#        "${PIPELINE_PARAMS[@]}"
# exit 0
 
# # run assembly pipeline
# nextflow \
#         -log "nextflow_logs/nextflow_run.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
#         run \
#         sanger-tol/genomeassembly \
#         "${PIPELINE_PARAMS[@]}" \
#         -resume