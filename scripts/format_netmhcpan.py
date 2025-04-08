#!/usr/bin/env python3
import os
import argparse
import pandas as pd


def format_netmhc_output(xls_path, binding_threshold=2):
    """
    Reads a NetMHC XLS output file (tab-separated, skipping the first line),
    creates a 'binder' column, and filters rows based on the binding_threshold
    applied to 'EL_Rank'.
    Returns a DataFrame of the filtered results.
    """
    df = pd.read_csv(xls_path, sep="\t", skiprows=1)
    df["binder"] = df["EL_Rank"].apply(
        lambda x: "SB" if x <= 0.5 else "WB" if x <= 2 else "NB"
    )
    df = df[df["EL_Rank"] <= binding_threshold]
    return df


def main():
    parser = argparse.ArgumentParser(
        description="Format NetMHC output and filter by binding threshold."
    )
    parser.add_argument(
        "--xls",
        required=True,
        help="Path to the NetMHC XLS output file."
    )
    parser.add_argument(
        "--binding_threshold",
        type=float,
        default=2.0,
        help="Filter threshold on EL_Rank. Rows with EL_Rank <= threshold are kept."
    )
    parser.add_argument(
        "--out",
        default="{orf}_{formatted_allele}_filtered_netmhc.csv",
        help="Name of output CSV file (default: {orf}_{formatted_allele}_filtered_netmhc.csv)."
    )
    args = parser.parse_args()

    # Process the file
    df_filtered = format_netmhc_output(args.xls, args.binding_threshold)

    # Get the base name of the input file
    base_name = os.path.splitext(os.path.basename(args.xls))[0]
    orf = base_name.split("_HLA-")[0]
    allele = base_name.split("_HLA-")[1].split("_")[0]
    df_filtered["orf"] = orf
    df_filtered["allele"] = allele
    formatted_allele = allele.replace(":", "_")
    output_file = f"{orf}_{formatted_allele}_filtered_netmhc.csv"
    # Write to CSV
    df_filtered.to_csv(output_file, index=False)

    print(f"Wrote {len(df_filtered)} filtered rows to {args.out}")


if __name__ == "__main__":
    main()
