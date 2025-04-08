#!/usr/bin/env python3
import os
import argparse

def main():
    parser = argparse.ArgumentParser(
        description="Concatenate two FASTA files and compute the output filename."
    )
    parser.add_argument(
        "--file1", "-f1",
        required=True,
        help="Path to the first FASTA file (e.g. ORF6_Q2HRD3_0_SB_B15_10.fasta)"
    )
    parser.add_argument(
        "--file2", "-f2",
        required=True,
        help="Path to the second FASTA file (e.g. 2_tcr_fasta.fa)"
    )
    parser.add_argument(
        "--output", "-o",
        help="Path to the output FASTA file. If not provided, the filename is computed automatically."
    )
    args = parser.parse_args()

    # Compute the base names for both input files.
    base1, _ = os.path.splitext(os.path.basename(args.file1))  # e.g. "ORF6_Q2HRD3_0_SB_B15_10"
    base2, _ = os.path.splitext(os.path.basename(args.file2))  # e.g. "2_tcr_fasta"
    
    # Remove the "_fasta" suffix from the second base name if present.
    base2 = base2.replace("_fasta", "")  # becomes "2_tcr"
    
    # Compute output filename if not provided.
    if args.output:
        output_file = args.output
    else:
        output_file = f"{base1}_{base2}_chai.fasta"

    # Open and concatenate both files into the output file.
    with open(args.file1, 'r') as f1, open(args.file2, 'r') as f2, open(output_file, 'w') as out:
        out.write(f1.read())
        # Optionally add a newline separator between files.
        out.write("\n")
        out.write(f2.read())

    print(f"Concatenated file written to: {output_file}")

if __name__ == "__main__":
    main()
