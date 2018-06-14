#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH --mem 6000
#SBATCH --output=./../cluster-out/07-%a.out
#SBATCH --error=./../cluster-err/07-%a.err
#SBATCH --array=1-1

## add SAS
module add sas/9.4


## run SAS command
sas -work /dev/shm -noterminal ./../programs/07-simulation-controls.sas -log "./../cluster-logs/07-$SLURM_ARRAY_TASK_ID.log" -sysparm "$SLURM_ARRAY_TASK_ID"