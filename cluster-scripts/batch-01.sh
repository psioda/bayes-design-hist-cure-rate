#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH --mem 6000
#SBATCH --output=./../cluster-out/01-%a.out
#SBATCH --error=./../cluster-err/01%a.err
#SBATCH --array=1-25

## add R module
module add r/3.3.1

## run R command
R CMD BATCH "--no-save --args $SLURM_ARRAY_TASK_ID" ./../programs/01-sampling-priors.R ./../cluster-logs/01-$SLURM_ARRAY_TASK_ID.Rout