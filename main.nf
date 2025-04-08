#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
***************************************************************************************
  Chai Pipeline Workflow
***************************************************************************************
This pipeline integrates several modules to process HLA and TCR data.
It performs the following steps:

1. TRANSFORM_ALLELES: Processes and cleans raw HLA allele strings.
2. runNetMHCpan: Runs netMHCpan on the transformed HLA alleles together with a set
   of FASTA files containing reference sequences.
3. FORMAT_ALLELES: Formats the netMHCpan results.
4. GENERATE_FASTA: Creates a FASTA file from the formatted netMHCpan output.
5. formatTCR: Processes a TCR table CSV input.
6. stitchTCR: Stitches together TCR sequences from the processed TCR table.
7. prepChai: Combines the stitched TCR FASTA files with the generated netMHCpan FASTA.
8. runChai: (Optionally) Executes the final Chai analysis command on the prepared FASTA.

Required input parameters are expected to be defined in the config file.
***************************************************************************************
*/

def helpMessage() {
    log.info """
    ---------------------------------------------------------------------------------------
    Chai Pipeline Workflow

    Usage:
      nextflow run <pipeline_script> -c <config_file> [options]

    Required Parameters (via config or command line):
      --input.reference_fasta   Directory containing reference FASTA files.
      --input.hla_alleles       Path to the file with raw HLA alleles (one per line).
      --input.tcr_table         Path to the TCR table CSV file.
      --conda                   Conda environment to be used by the modules.
      --output.folder           Base output folder for pipeline results.
      --config.scripts_path     Path to the directory containing required scripts.

    Description:
      This workflow processes HLA alleles and TCR sequences through multiple modules:
        - HLA module (in './modules/hla_binder'): transforms alleles, runs netMHCpan, formats
          the results, and generates a FASTA file.
        - TCR module (in './modules/tcr_stricther'): formats and stitches TCR sequences.
        - Chai module (in './modules/chai'): prepares and optionally runs the final Chai command.

    Example:
      nextflow run chai_pipeline.nf -c my_config.config

    ---------------------------------------------------------------------------------------
    """.stripIndent()
}

if (params.help) {
    helpMessage()
    exit 0
}

// Include the modules from the respective folders.
include { TRANSFORM_ALLELES; runNetMHCpan; FORMAT_ALLELES; GENERATE_FASTA } from './modules/hla_binder'
include { formatTCR; stitchTCR } from './modules/tcr_stricther'
include { prepChai; runChai } from './modules/chai'

workflow Chai {
    /*
     * Channels
     */
    // Channel of reference FASTA files (all files under the given directory).
    fasta_files = Channel.fromPath(params.input.reference_fasta + '/*')
    
    // Channel of HLA alleles: read the file, split into lines, then filter out empty lines.
    hla_alleles = Channel.fromPath(params.input.hla_alleles).splitText().filter { it.trim() }
    
    // Channel of TCR table CSV input.
    tcr_table = Channel.fromPath(params.input.tcr_table)
    
    main:
    // Transform raw HLA allele strings.
    TRANSFORM_ALLELES(hla_alleles)
    
    // Run netMHCpan using the output from TRANSFORM_ALLELES and the FASTA files.
    runNetMHCpan(TRANSFORM_ALLELES.out, fasta_files)
    
    // Format the netMHCpan results.
    FORMAT_ALLELES(runNetMHCpan.out)
    
    // Generate a FASTA file from the formatted netMHCpan output.
    GENERATE_FASTA(FORMAT_ALLELES.out.netmhc_out)
    
    // Process the TCR table CSV.
    formatTCR(tcr_table)
    
    // Stitch together TCR FASTA sequences, reading the TCR table as CSV.
    stitchTCR(formatTCR.out.tcr_table.splitCsv(header:true, quote: '\"', sep: ','))
    
    // Prepare the final Chai input by concatenating stitched TCR FASTA output with 
    // the generated FASTA output from the HLA module.
    prepChai(
         stitchTCR.out.tcr_fasta.toSortedList().flatten(),
         GENERATE_FASTA.out.fasta_out.toSortedList().flatten()
    )
    
    // Optionally, run the final Chai analysis process.
    // runChai(prepChai.out.fasta_out)
}
