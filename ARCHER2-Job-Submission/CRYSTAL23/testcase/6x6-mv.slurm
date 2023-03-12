#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00

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

# start calculation: command added below by gen_sub
timeout 7m /mnt/lustre/a2fs-work3/work/e89/e89/hyz20ic/GitHub/crystal_shape_control/ARCHER2-Job-Submission/run_exec -set /work/e89/e89/hyz20ic//etc/runCRYSTAL/settings -in 6x6-mv.d12 -ref  -- 'srun --hint=nomultithread --distribution=block:block Pcrystal'
/mnt/lustre/a2fs-work3/work/e89/e89/hyz20ic/GitHub/crystal_shape_control/ARCHER2-Job-Submission/post_proc -in 6x6-mv.d12 -set /work/e89/e89/hyz20ic//etc/runCRYSTAL/settings


