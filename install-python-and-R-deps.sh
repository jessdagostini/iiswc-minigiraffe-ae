#!/bin/sh

sudo Rscript -e "install.packages('tidyverse')"
python3 -m venv ./venv
source ./venv/bin/activate && pip3 install pandas pyDOE3 requests