#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00

# Replace [budget code] below with your full project code
#SBATCH --account=e89-ic_c
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --export=none

echo "SLURM Job Report"
echo "--------------------------------------------"
echo "  Start Date : $(date)"
echo "  SLURM Job ID : ${SLURM_JOB_ID}"
echo "  Status"
squeue -j ${SLURM_JOB_ID} 2>&1
echo "--------------------------------------------"
echo ""

# Address the memory leak
export FI_MR_CACHE_MAX_COUNT=0

# Set number of threads and OMP level
export OMP_NUM_THREADS=1
export OMP_PLACES=cores

# Set temporary directory
export ESPRESSO_TMPDIR=$(pwd)/f1-scf_${SLURM_JOB_ID}

# start calculation: command added below by gen_sub
timeout 27m /mnt/lustre/a2fs-work3/work/e89/e89/hyz20ic/GitHub/crystal_shape_control/ARCHER2-Job-Submission/run_exec -set /mnt/lustre/a2fs-work3/work/e89/e89/hyz20ic/etc/runQE/settings -in f1-scf.in -ref  -- 'srun --hint=nomultithread --distribution=block:block /work/e89/e89/hyz20ic/apps/QuantumEspresso_v7.1/bin//pw.x < f1-scf.in'
/mnt/lustre/a2fs-work3/work/e89/e89/hyz20ic/GitHub/crystal_shape_control/ARCHER2-Job-Submission/post_proc -in f1-scf.in -set /mnt/lustre/a2fs-work3/work/e89/e89/hyz20ic/etc/runQE/settings


