#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
---------------------------------------------------------------------------------------
  Example Nextflow script that runs netMHCpan on multiple FASTA + HLA allele pairs,
  including a help message.
---------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info """
    -----------------------------------------------------------------------------------
     NetMHCpan Pipeline
    -----------------------------------------------------------------------------------
     Usage:
       nextflow run netmhcpan.nf [options]

     Required parameters:
       --input.netmhcpan_path         Path to the netMHCpan executable
       --input.netmhcpan_folder       Path to the netMHCpan reference folder
       --input.netmhcpan_tmpdir       Path to the directory for netMHCpan temporary files
       --input.reference_fasta        Path or pattern to one or more FASTA files
       --input.hla_alleles            Path to a file containing one HLA allele per line
       --output.folder                Where to publish final results (e.g. ./results)

     Optional parameters:
       --conda=ENVIRONMENT            Name or file path of a conda environment
       --help                         Show this help message and exit

     Example:
       nextflow run netmhcpan.nf \\
         --input.netmhcpan_path '/usr/local/bin/netMHCpan' \\
         --input.reference_fasta 'fastas/*.fasta' \\
         --input.hla_alleles 'data/alleles.txt' \\
         --output.folder 'results_netmhc' \\
         --conda 'env/netmhcpan_env.yml'
    -----------------------------------------------------------------------------------
    """.stripIndent()
}

// If the user passed --help, show the message and exit
if (params.help) {
    helpMessage()
    exit 0
}

// Now define your netMHCpan process, channels, workflow, etc.

process runNetMHCpan {
  conda "$params.conda"
  label 'low_mem'
  errorStrategy 'ignore'
  environment = ["NETMHCpan": "$params.input.netmhcpan_folder",
                 "TMPDIR": "$params.input.netmhcpan_tmpdir"]

  input:
    each hla_row
    path fasta_path
    
  output:
    path "${results}", emit: mhcpan_out
    
  script:
    hla_allele = hla_row.trim()
    netmhc_path = "$params.input.netmhcpan_path"
    fasta_base = fasta_path.getSimpleName()
    results = "${fasta_base}_${hla_allele}.xls"
    """
    ${netmhc_path} -a ${hla_allele} -f ${fasta_path} -xls -xlsfile ${results} -inptype 0 
    """
}


process TRANSFORM_ALLELES {
  /*
    * Takes a single allele string at a time as input, calls Python,
    * applies the transform_hla_allele function, and prints the result.
    * That printed line is captured as the output (val).
    */
  conda "$params.conda"
  label 'low_mem'
  input:
    val allele

  output:
    stdout

  script:
  """
  python3 ${params.config.scripts_path}/transform_hla.py -a ${allele}
  """
}

process FORMAT_ALLELES {
  /*
    * Takes a single allele string at a time as input, calls Python,
    * applies the transform_hla_allele function, and prints the result.
    * That printed line is captured as the output (val).
    */
  publishDir "$params.output.folder/netmhcpan/", mode : "copy"
  conda "$params.conda"
  label 'low_mem'
  input:
    path netmhc_path

  output:
    path "*.csv", emit: netmhc_out

  script:
  """
  python3 ${params.config.scripts_path}/format_netmhcpan.py --xls ${netmhc_path} --binding_threshold 0.5
  """
}

process GENERATE_FASTA {
  conda "$params.conda"
  label 'low_mem'
  publishDir "$params.output.folder/pepmhc/", mode : "copy"
  input:
    path netmhc_results

  output:
    path "*.fasta", emit: fasta_out

  script:

  """
  python3 ${params.config.scripts_path}/lookup_hla.py --hla_dir ${params.config.hla_dir} --input ${netmhc_results} 
  """
}

workflow {
  fasta_files = Channel.fromPath(params.input.reference_fasta + '/*')
  hla_alleles = Channel.fromPath(params.input.hla_alleles).splitText().filter { it.trim() }

  main:
    TRANSFORM_ALLELES(hla_alleles)
    runNetMHCpan(TRANSFORM_ALLELES.out, fasta_files)
    FORMAT_ALLELES(runNetMHCpan.out)
    GENERATE_FASTA(FORMAT_ALLELES.out.netmhc_out)
}