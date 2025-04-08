#!/usr/bin/env python3

import os
import re
import argparse

def transform_hla_allele(allele):
    """
    Takes a raw HLA allele string, e.g. "A*03:01:01:01",
    and returns a normalized form, e.g. "HLA-A03:01".
    """
    gene, codes = allele.split("*", maxsplit=1)
    parts = codes.split(":")
    shortened = ":".join(parts[:2])
    normalized_allele = f"HLA-{gene}{shortened}"
    return normalized_allele

def main():
    parser = argparse.ArgumentParser(
        description="Normalize HLA allele notation."
    )
    parser.add_argument(
        "-a", "--allele",
        required=True,
        help="Raw HLA allele string, e.g. 'A*03:01:01:01'."
    )
    args = parser.parse_args()

    # Transform and print
    normalized = transform_hla_allele(args.allele)
    print(normalized)

if __name__ == "__main__":
    main()
