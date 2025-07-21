#!/bin/bash
#SBATCH --job-name=DESI_cmprsdCMB_SNe_chains
#SBATCH --output=/vol/calvin/data/rranjan/internship_stuff/DESIDR2_cmprsdCMB_chains/DESI_cmprsdCMB_SNe_outputs/logs/%x_%A_%a.out
#SBATCH --error=/vol/calvin/data/rranjan/internship_stuff/DESIDR2_cmprsdCMB_chains/DESI_cmprsdCMB_SNe_outputs/logs/%x_%A_%a.err
#SBATCH --array=0-15%4
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=48:00:00
#SBATCH --partition=aifa-science
#SBATCH --mem-per-cpu=4G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=rranjan@astro.uni-bonn.de

# Define user‐settable paths & configs
BASE=/vol/calvin/data/rranjan/internship_stuff/DESIDR2_cmprsdCMB_chains
OUTDIR=${BASE}/DESI_cmprsdCMB_SNe_outputs
CONFIG_DIR=${BASE}

# List the yaml file configs here:
CONFIGS=(DR2_cmprsdCMB.yaml DR2_cmprsdCMB_PantheonPlus.yaml DR2_cmprsdCMB_Union3.yaml DR2_cmprsdCMB_DESY5.yaml)

# Derive config‐index and chain‐index from SLURM_ARRAY_TASK_ID
JOB0=$(( SLURM_ARRAY_TASK_ID ))	  # zero-based
CFG=$(( JOB0 / 4 ))			  # integer division → 0..3
CHAIN=$(( JOB0 % 4 ))			  # 0..3

# sanity check
if (( CFG < 0 || CFG >= ${#CONFIGS[@]} )); then
  echo “ERROR: computed CFG=${CFG} out of range [0..$(( ${#CONFIGS[@]}-1 ))]”
  exit 1
fi

CFG_YAML=${CONFIGS[$CFG]}
CFG_PATH=${CONFIG_DIR}/${CFG_YAML}

# Prepare output directory for the chain
CHAIN_OUT=${OUTDIR}/${CFG_YAML%.yaml}_chain${CHAIN}

# Activate conda env
source /vol/calvin/data/rranjan/anaconda/etc/profile.d/conda.sh
conda activate cobaya_venv
export PYTHONNOUSERSITE=1

# Only use if the mpirun feature returns the mpi4py={} error while executing the script
export COBAYA_USE_FILE_LOCKING=False

# Run Cobaya under MPI
cd "${BASE}"
echo “Running chain $CHAIN with config $CFG_YAML → out ${CHAIN_OUT}”
mpirun -n $SLURM_NTASKS \
  cobaya-run "${CFG_PATH}" -o "${CHAIN_OUT}" \
    2>&1 | tee "${CHAIN_OUT}.log"
