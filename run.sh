#!/bin/bash
set -Eeuo pipefail

# Run preprocess workflow
nextflow run main.nf -entry Chai -c config.yml
# -resume \