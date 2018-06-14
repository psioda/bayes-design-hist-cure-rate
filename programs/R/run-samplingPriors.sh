#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 96:00:00
#SBATCH --mem 8000
#SBATCH --output=./out/arrayJob_%A_%a.out
#SBATCH --error=./err/arrayJob_%A_%a.err
#SBATCH --array=1-760

## add R module
module add r/3.3.1

## run R command
R CMD BATCH "--no-save --args $SLURM_ARRAY_TASK_ID" samplingPriors.R ./out/samplingPriors.Rout_$SLURM_ARRAY_TASK_ID