#! /usr/bin/env zsh 

source /home/ubuntu/miniconda3/etc/profile.d/conda.sh
conda activate ADHD

sudo service ssh start

exec zsh -il
