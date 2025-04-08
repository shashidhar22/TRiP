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

process formatTCR {
  conda "$params.conda"
  label 'low_mem'
  publishDir "$params.output.folder/tcrconvert/", mode : "copy"
  input:
    path tcr_input
    
  output:
    path "tcr_formatted.csv", emit: tcr_table
    
  script:
    """
    python3 ${params.config.scripts_path}/format_tcr.py -i ${tcr_input} -o tcr_formatted.csv
    """
}

process stitchTCR {
  conda "$params.conda"
  label 'low_mem'
  publishDir "$params.output.folder/stitcher/", mode : "copy"
  input:
    each tcr
    
  output:
    path "${tcr.ID}_tcr_fasta.fa", emit: tcr_fasta
    
  script:
    """
    stitchr -v ${tcr.BV} -j ${tcr.BJ} -c ${tcr.BC} -cdr3 ${tcr.BCDR3} -n ${tcr.ID}_TRB -m AA_FA -sw > trb_output.txt
    python3 ${params.config.scripts_path}/generate_tcr_sequence.py -i trb_output.txt -o trb_fasta.fa
    stitchr -v ${tcr.AV} -j ${tcr.AJ} -cdr3 ${tcr.ACDR3} -n ${tcr.ID}_TRA -m AA_FA -sw > tra_output.txt
    python3 ${params.config.scripts_path}/generate_tcr_sequence.py -i tra_output.txt  -o tra_fasta.fa
    cat tra_fasta.fa trb_fasta.fa > ${tcr.ID}_tcr_fasta.fa
    """
}


workflow {
  tcr_table = Channel.fromPath(params.input.tcr_table)

  main:
    formatTCR(tcr_table)
    stitchTCR(formatTCR.out.tcr_table.splitCsv(header:true, quote: '\"', sep: ','))
}