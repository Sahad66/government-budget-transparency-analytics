import pandas as pd
from pathlib import Path

files = {
    "Statement 1": Path(
        "data/transformed/statement_1_standardized.csv"
    ),
    "Statement 2": Path(
        "data/transformed/statement_2_standardized.csv"
    )
}

for name, path in files.items():

    print("\n" + "=" * 70)
    print(name)
    print("=" * 70)

    df = pd.read_csv(path)

    print("\nOriginal row count:", len(df))

    print("\nFirst 15 records:")
    print(df.head(15).to_string(index=False))

    print("\nCompletely empty rows:")
    print(df.isna().all(axis=1).sum())

    print("\nCompletely empty columns:")
    print(df.isna().all(axis=0).sum())

    print("\nDuplicate rows:")
    print(df.duplicated().sum())

    print("\nMissing values by column:")
    print(df.isna().sum().to_string())