#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
***************************************************************************************
  Chai Preprocessing Pipeline
***************************************************************************************
This pipeline processes TCR/chai input data in two main steps:

1. prepChai:
   - Uses a conda environment as defined by `params.conda` with a low-memory label.
   - Publishes its output in the directory: "$params.output.folder/chaiprep/"
   - Accepts two inputs:
         a) stitcher_results (e.g., FASTA output from a stitcher process)
         b) netmhc_results (e.g., FASTA output from a netMHC process)
   - Runs a Python script (concat_fasta.py) located in 
         "$params.config.scripts_path" to concatenate the two input files.
   - Produces an output file matching the pattern "*_chai.fasta".

2. runChai:
   - Uses the same conda environment with a label 'maestro'.
   - Publishes its output in the directory: "$params.output.folder/chai/"
   - Accepts a FASTA file produced by prepChai.
   - Extracts the simple name from the input FASTA (using getSimpleName() method),
     then runs the command "chai-lab fold" to generate a folded output.
   - The output file is named based on the simple name of the input FASTA.
   
Required parameters (and defaults or additional details) should be specified in your config file.

Usage:
  nextflow run <pipeline_script> -c <config_file> [--help]

***************************************************************************************
*/

def helpMessage() {
    log.info """
    ---------------------------------------------------------------------------------------
    Chai Preprocessing Pipeline Help

    Usage:
      nextflow run <pipeline_script> -c <config_file> [options]

    Required Parameters:
      --conda                Conda environment specification.
      --output.folder        Output directory for pipeline results.
      --config.scripts_path  Path to directory containing scripts (e.g. concat_fasta.py).
      --input.stitcher_results  (Optional) Pattern/path for stitcher results.
      --input.netmhc_results  (Optional) Pattern/path for netMHC results.
    
    Description:
      This pipeline consists of two sequential processes:
       - prepChai: Concatenates the FASTA outputs from stitcher and netMHC to produce a file ending in _chai.fasta.
       - runChai: Runs the "chai-lab fold" command on the concatenated FASTA file.
    
    ---------------------------------------------------------------------------------------
    """.stripIndent()
}

// Check for help parameter
if (params.help) {
    helpMessage()
    exit 0
}

process prepChai {
    // Use the specified conda environment and low memory label.
    conda "$params.conda"
    label 'low_mem'
    // Publish output files (copy them) to the specified output folder.
    publishDir "$params.output.folder/chaiprep/", mode: "copy"

    input:
        each stitcher_results   // Expect a file or channel element for stitcher results.
        each netmhc_results     // Expect a file or channel element for netMHC results.
        
    output:
        path "*_chai.fasta", emit: fasta_out

    script:
        """
        python3 ${params.config.scripts_path}/concat_fasta.py \
            -f1 ${stitcher_results} -f2 ${netmhc_results}
        """
}

process runChai {
    // Use the specified conda environment and the 'maestro' label.
    conda "$params.conda"
    label 'maestro'
    // Publish output files to the specified folder.
    publishDir "$params.output.folder/chai/", mode: "copy"

    input:
        path fasta_path      // Accepts the concatenated FASTA file from prepChai.
    
    output:
        path "${out_path}", emit: chai_preds

    script:
        // Get the simple name of the input file, which will be used as output file name.
        out_path = fasta_path.getSimpleName()
        """
        chai-lab fold ${fasta_path} ${out_path}
        """
}

workflow {
    /*
     * Example channel creation:
     * If your config provides patterns for stitcher and netMHC results,
     * you can define channels as follows (or adjust per your pipeline requirements).
     */
    def stitcher_results_ch = Channel.fromPath(params.input.stitcher_results)
    def netmhc_results_ch   = Channel.fromPath(params.input.netmhc_results)

    // Run prepChai to generate concatenated FASTA files.
    prepChai(stitcher_results_ch, netmhc_results_ch)
    
    // Pass the output FASTA files from prepChai to runChai for folding.
    runChai(prepChai.fasta_out)
}
