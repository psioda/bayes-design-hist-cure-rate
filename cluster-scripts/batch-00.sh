#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 48:00:00
#SBATCH --mem 4000
#SBATCH --output=./../cluster-out/00-%a.out
#SBATCH --error=./../cluster-err/00-%a.err
#SBATCH --array=1-1

## add SAS
module add sas/9.4


## run SAS command
sas -work /dev/shm -noterminal ./../programs/00-import-raw.sas -log "./../cluster-logs/00-$SLURM_ARRAY_TASK_ID.log" -sysparm "$SLURM_ARRAY_TASK_ID"