#!/usr/bin/env python3

import os
import tcrconvert
import pandas as pd
import argparse

def format_tcr(input_file, output_file):
    """
    Reads a CSV file containing TCR sequences, reformats the data for both TRB and TRA chains,
    converts the format from 'tenx' to 'imgt' using tcrconvert, concatenates the formatted tables,
    and writes the result to a CSV output file.
    
    Parameters:
      input_file  : str, path to the input CSV file.
      output_file : str, path to the output CSV file.
    """
    tcr_table = pd.read_csv(input_file)
    
    # Extract and rename TRB columns
    trb_table = tcr_table[['ID', 'TRBV', 'TRBJ', 'TRBC', 'TRB_CDR3']]
    trb_table = trb_table.rename(columns={
        'TRBV': 'v_gene',
        'TRBJ': 'j_gene',
        'TRBC': 'c_gene',
        'TRB_CDR3': 'cdr3'
    })
    
    # Extract and rename TRA columns
    tra_table = tcr_table[['ID', 'TRAV', 'TRAJ', 'TRA_CDR3']]
    tra_table = tra_table.rename(columns={
        'TRAV': 'v_gene',
        'TRAJ': 'j_gene',
        'TRA_CDR3': 'cdr3'
    })
    
    # Format using tcrconvert (convert from tenx to imgt)
    trb_formatted = tcrconvert.convert_gene(trb_table, frm='tenx', to='imgt')
    tra_formatted = tcrconvert.convert_gene(tra_table, frm='tenx', to='imgt')
    
    trb_formatted = trb_formatted.rename(columns={
        'v_gene': 'BV',
        'j_gene': 'BJ',
        'c_gene': 'BC',
        'cdr3': 'BCDR3'
    })
    tra_formatted = tra_formatted.rename(columns={
        'v_gene': 'AV',
        'j_gene': 'AJ',
        'cdr3': 'ACDR3'
    })


    # Concatenate the two formatted dataframes and write to CSV
    tcr_formatted = pd.merge(
        trb_formatted,
        tra_formatted,
        on='ID',
        how='inner'
    )
    tcr_formatted = tcr_formatted.dropna()
    tcr_formatted.to_csv(output_file, index=False)

def main():
    parser = argparse.ArgumentParser(
        description="Reformat TCR sequences from tenx to imgt format."
    )
    parser.add_argument(
        "--input_file", "-i",
        required=True,
        help="Path to the input CSV file containing TCR sequences."
    )
    parser.add_argument(
        "--output_file", "-o",
        required=True,
        help="Path to the output CSV file where formatted TCR sequences will be saved."
    )
    args = parser.parse_args()
    
    format_tcr(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
