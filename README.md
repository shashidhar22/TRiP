# TRiP: T-cell receptor, Peptide, MHC Interaction Predictor Tool

TRiP is a tool for predicting T-cell receptor (TCR) interactions with peptides and MHC molecules. It combines several established tools to streamline the prediction workflow and standardize data inputs using best-in-class bioinformatics resources.

---

## Table of Contents

1. [Overview](#overview)
2. [Dependencies](#dependencies)
3. [Installation](#installation)
    - [NetMHCpan and NetMHCIIpan](#netmhcpan-and-netmhciipan)
    - [tcrconvert](#tcrconvert)
    - [Stitchr](#stitchr)
    - [Nextflow](#nextflow)
4. [Environment Setup](#environment-setup)
5. [Conda Environment Setup](#conda-environment-setup)
6. [Example Execution](#example-execution)
7. [License](#license)
8. [Contact](#contact)
9. [Citations](#citations)

---

## Overview

TRiP (T-cell Receptor, Peptide, MHC Interaction Predictor) is designed to facilitate the analysis and prediction of TCR–peptide–MHC interactions. The pipeline integrates predictive tools and utilities including NetMHCpan/NetMHCIIpan for MHC binding predictions, tcrconvert for standardizing V(D)J gene annotations, Stitchr for TCR sequence assembly, and Nextflow for orchestrating the workflow.

---

## Dependencies

TRiP depends on the following external tools and libraries:

- **NetMHCpan 4.1** (for MHC Class I binding predictions)  
  [NetMHCpan-4.1](https://services.healthtech.dtu.dk/services/NetMHCpan-4.1/)  
  *Note: An academic license is required to download and use this tool.*

- **NetMHCIIpan 4.3** (for MHC Class II binding predictions)  
  [NetMHCIIpan-4.3](https://services.healthtech.dtu.dk/services/NetMHCIIpan-4.3/)  
  *Note: An academic license is required to download and use this tool.*

- **tcrconvert** – for standardizing V(D)J gene nomenclature.  
  [tcrconvert on GitHub](https://github.com/seshadrilab/tcrconvert)  
  **Requirements:**
  - Python >= 3.9
  - pandas >= 1.5.0
  - click >= 8.1.7
  - platformdirs >= 4.2.2

- **Stitchr** – tool for assembling T-cell receptor sequences.  
  [Stitchr on GitHub](https://github.com/JamieHeather/stitchr)

- **Nextflow** – workflow management system to run the pipeline.  
  [Nextflow Documentation](https://www.nextflow.io/docs/latest/overview.html)

In addition, a conda environment specifying many of the dependencies is included in the `env` folder.

---

## Installation

### NetMHCpan and NetMHCIIpan

1. **Request an Academic License:**  
   Visit the following webpages and complete the academic license request forms:
   - [NetMHCpan-4.1](https://services.healthtech.dtu.dk/services/NetMHCpan-4.1/)
   - [NetMHCIIpan-4.3](https://services.healthtech.dtu.dk/services/NetMHCIIpan-4.3/)

2. **Download and Extract:**  
   After approval, download the installation packages (e.g., `.tar.gz` files) and extract them:
   ```bash
   tar -zxvf netMHCpan-4.1.Linux.tar.gz
   tar -zxvf netMHCIIpan-4.3.Linux.tar.gz
   ```
3. **Configure Installation:**  
   Place the extracted directories at a convenient location (e.g., `/home/username/software/netmhcpan/`).  
   *Further configuration (including setting executable permissions) should follow the guidelines provided in each tool’s README/INSTALL file.*

### tcrconvert

Install directly from GitHub using pip:
```bash
pip install git+https://github.com/seshadrilab/tcrconvert
```
This command will install `tcrconvert` along with its dependencies.

### Stitchr

Install Stitchr using pip:
```bash
pip install stitchr
# In order to automatically download the necessary data for stitching, IMGTgeneDL is also required. If it’s not automatically installed alongside stitchr, it can be installed with:
pip install IMGTgeneDL
# After installing stitchr via pip, IMGTgeneDL can be used via the stitchrdl command to download suitably formatted data sets to the required directory like so:
stitchrdl -s human
# The -aa alignment function of stitchr requires Biopython
pip install Bio
```
Follow the instructions in the repository to install and set up Stitchr.

### Nextflow

Download and install Nextflow by following the [Nextflow official documentation](https://www.nextflow.io/docs/latest/overview.html).

---

## Environment Setup

Before running TRiP, ensure you export the necessary environment variables. This helps the pipeline locate installations and manage temporary files.

Add the following lines to your shell configuration file (e.g., `~/.bashrc` or `~/.zshrc`):

```bash
export NETMHCpan="/home/username/software/netmhcpan/netMHCpan-4.1"
export TMPDIR="/home/username/tmp"
```
> **Note:** Replace `/home/username/...` with the appropriate paths for your system.

---

## Conda Environment Setup

A conda environment file is provided in the `env` directory to simplify dependency installation. To create the environment, use the following command:
```bash
mamba env create -f env/environment.yml
```
This will install all necessary packages specified in the environment file. Activate the environment with:
```bash
mamba activate <environment_name>
```
Replace `<environment_name>` with the actual name specified in the `environment.yml`.

---

## Example Execution

Below is an config template that can be used to run the TRiP pipeline. Adjust the paths and parameters according to your setup:

```yaml
params:
  input:
    netmhcpan_path: "/dummy/path/netMHCpan/bin/netMHCpan"
    netmhcpan_folder: "/dummy/path/netMHCpan"
    netmhcpan_tmpdir: "/dummy/temp/netmhcpan"
    reference_fasta: "dummy/test/"
    hla_alleles: "dummy/data/alleles.txt"
    tcr_table: "dummy/data/ks_tcr_list.csv"
  output:
    folder: "/dummy/output/chai"
  conda: "/dummy/envs/quest"
  config:
    scripts_path: "/dummy/projects/TRiP/scripts/"
    hla_dir: "/dummy/databases/IMGTHLA/fasta/"

workDir: "/dummy/work/chai"

```
> **Note:** Replace all dummy paths with your actual file system paths.

To run the pipeline, execute the following command in your terminal:
```bash
nextflow run main.nf -c config.yml 
```
This command will initiate the TRiP pipeline using the specified configuration file and conda profile.



## Contact

For any questions or further information, please contact:

**Name:** Shashidhar Ravishankar
**Email:** sravisha@fredhutch.org

---

This README is intended to serve as the comprehensive guide to setting up, configuring, and running the TRiP pipeline. Modify and expand the instructions as necessary for your specific environment and project requirements.

## Citations

- [NetMHCpan 4.1](https://services.healthtech.dtu.dk/services/NetMHCpan-4.1/)
- [NetMHCIIpan 4.3](https://services.healthtech.dtu.dk/services/NetMHCIIpan-4.3/)
- [tcrconvert](https://github.com/seshadrilab/tcrconvert)
- [Stitchr](https://github.com/JamieHeather/stitchr)
- [Nextflow](https://www.nextflow.io/docs/latest/install.html)
