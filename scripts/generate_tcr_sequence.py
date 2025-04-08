#!/usr/bin/env python3

import sys
import argparse

def fasta_to_amino_acids(fasta_text: str) -> str:
    """
    Given a FASTA-like string with a header line and multiple lines of sequence,
    return a single string of amino acids. Any line starting with '>', '-', or
    blank is ignored.
    """
    lines = fasta_text.split('\n')
    seq_lines = []
    for line in lines:
        line = line.strip()
        # Skip empty lines, header lines (start with '>'),
        # and lines of dashes (start with '-')
        if not line or line.startswith('-'):
            continue
        elif line.startswith('>'): 
            header = line.split('|')[1]
            seq_lines.append('>protein|name=' +header+'\n')
        else:
            seq_lines.append(line+'\n')
    return ''.join(seq_lines)

def main():
    parser = argparse.ArgumentParser(
        description="Convert a FASTA-like output to a single amino acid sequence string."
    )
    parser.add_argument(
        "--infile", "-i",
        default=None,
        help="Path to the input file. If not provided, reads from stdin."
    )
    parser.add_argument(
        "--out", "-o",
        default=None,
        help="Path to the output file. If not provided, prints to stdout."
    )
    args = parser.parse_args()

    # Read input
    if args.infile is None:
        # Read from stdin
        fasta_text = sys.stdin.read()
    else:
        with open(args.infile, 'r', encoding="utf-8") as f:
            fasta_text = f.read()

    # Convert to a single AA sequence
    amino_acids = fasta_to_amino_acids(fasta_text)

    # Write output
    if args.out is None:
        # Print to stdout
        print(amino_acids)
    else:
        with open(args.out, 'w', encoding="utf-8") as f:
            f.write(amino_acids)


if __name__ == "__main__":
    main()
