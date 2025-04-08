#!/usr/bin/env python3
"""
This script looks up an HLA allele from IMGT/HLA FASTA files and writes a FASTA file
with the allele as the header and its sequence as the content.

Usage example:
  python lookup_hla.py --hla_dir /path/to/fasta_dir --allele A01:01 --output A01_01.fasta
"""

import os
import re
import pandas as pd
import glob
from collections import OrderedDict
import argparse

def parse_imgt_four_digit(hla_directory):
    """
    Parses IMGT/HLA FASTA files to extract unique HLA alleles at four-digit resolution.
    
    Args:
        hla_directory (str): Directory containing FASTA files (expected filenames end with "_prot.fasta").
    
    Returns:
        OrderedDict: Keys are four-digit HLA allele identifiers (e.g. "A*01:01") and values are nucleotide sequences.
    """
    file_paths = glob.glob(os.path.join(hla_directory, "*_prot.fasta"))
    fasta_dict = OrderedDict()

    for file_path in file_paths:
        with open(file_path, 'r') as file:
            header, sequence = None, []
            for line in file:
                line = line.strip()
                if line.startswith('>'):
                    if header and header not in fasta_dict:
                        fasta_dict[header] = ''.join(sequence)
                    # Assume header is in the format ">aa||A*01:01:01:06 ..." 
                    parts = line.split()
                    if len(parts) < 2:
                        continue
                    hla_id_full = parts[1]  # e.g. "A*01:01:01:06"
                    # Keep only the four-digit resolution: "A*01:01"
                    hla_id_four_digit = ":".join(hla_id_full.split(":")[:2])
                    if hla_id_four_digit not in fasta_dict:
                        header = hla_id_four_digit
                    else:
                        header = None  # Skip if already processed
                    sequence = []
                else:
                    sequence.append(line)
            if header and header not in fasta_dict:
                fasta_dict[header] = ''.join(sequence)
    return fasta_dict

def get_mhc_sequence(value, fasta_dict):
    """
    Given an MHC allele value (e.g. "A*01:01"), return the corresponding sequence from fasta_dict.
    
    Args:
        value (str): HLA allele string.
        fasta_dict (dict): Dictionary of parsed HLA alleles.
    
    Returns:
        str or None: The corresponding nucleotide sequence if found; otherwise, None.
    """
    try:
        allele, _ = value.split(';', 1)
    except (ValueError, AttributeError):
        allele = value
    return fasta_dict.get(allele, None)

def normalize_input_allele(allele):
    """
    Normalize the allele string. If the input allele is provided as "A01:01" (without a star),
    this function converts it to "A*01:01".
    
    Args:
        allele (str): Input allele string.
    
    Returns:
        str: Normalized allele string.
    """
    # If allele already contains '*', return as is.
    if '*' in allele:
        return allele
    # Use a regex to match a letter (A, B, or C) followed by two digits, a colon, and two digits.
    m = re.match(r'^([ABC])(\d+:\d+)$', allele)
    if m:
        return f"{m.group(1)}*{m.group(2)}"
    # Otherwise, return allele unchanged (or raise an error if you prefer)
    return allele

def main():
    parser = argparse.ArgumentParser(
        description="Lookup an HLA allele from IMGT/HLA FASTA files and output a FASTA file."
    )
    parser.add_argument(
        "--hla_dir",
        required=True,
        help="Directory containing IMGT/HLA FASTA files (filenames should end with '_prot.fasta')."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="CSV file containing HLA alleles and peptide sequences (not used in this script)."
    )
    args = parser.parse_args()

    pepmhc_table = pd.read_csv(args.input)

    for index, row in pepmhc_table.iterrows():
        peptide = row['Peptide']
        peptide_id = row['orf'] + '_' + str(row['Pos']) + '_' + row['binder']
        hla_allele = row['allele'] 
        # Normalize input allele to ensure it is in "A*01:01" format.
        normalized_allele = normalize_input_allele(hla_allele)
        
        # Parse FASTA files into a dictionary.
        fasta_dict = parse_imgt_four_digit(args.hla_dir)
        
        # Lookup the allele's sequence using the normalized allele string.
        sequence = get_mhc_sequence(normalized_allele, fasta_dict)
        if sequence is None:
            print(f"Error: Allele '{normalized_allele}' not found in FASTA files from {args.hla_dir}.")
            exit(1)
        out_path = peptide_id + '_' + hla_allele.replace(':', '_') + ".fasta"
        # Write output FASTA file with the allele as header and its sequence.
        with open(out_path, "w") as outfile:
            outfile.write(f">protein|name={peptide_id}\n")
            outfile.write(peptide + "\n")
            outfile.write(f">protein|name={hla_allele}\n")
            outfile.write(sequence + "\n")
    

if __name__ == "__main__":
    main()
