#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 72:00:00
#SBATCH --mem 3000
#SBATCH --output=./../cluster-out/06-%a.out
#SBATCH --error=./../cluster-err/06-%a.err
#SBATCH --array=1-700

## add SAS
module add sas/9.4


## run SAS command
sas -work /dev/shm -noterminal ./../programs/06-calibrate-a0.sas -log "./../cluster-logs/06-$SLURM_ARRAY_TASK_ID.log" -sysparm "$SLURM_ARRAY_TASK_ID"