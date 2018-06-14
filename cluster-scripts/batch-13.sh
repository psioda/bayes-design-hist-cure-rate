#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 36:00:00
#SBATCH --mem 3000
#SBATCH --output=./../cluster-out/13-%a.out
#SBATCH --error=./../cluster-err/13-%a.err
#SBATCH --array=1-486

## add SAS
module add sas/9.4


## run SAS command
sas -work /dev/shm -noterminal ./../programs/13-calculate-power.sas -log "./../cluster-logs/13-$SLURM_ARRAY_TASK_ID.log" -sysparm "$SLURM_ARRAY_TASK_ID"