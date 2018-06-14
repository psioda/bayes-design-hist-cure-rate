#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 96:00:00
#SBATCH --mem 8000
#SBATCH --output=./out/arrayJob_%A_%a.out
#SBATCH --error=./err/arrayJob_%A_%a.err
#SBATCH --array=1-1

## add SAS
module add sas/9.4


## run SAS command
sas -noterminal samplingPriors_process.sas -log "./logs/samplingPriors_process.log"