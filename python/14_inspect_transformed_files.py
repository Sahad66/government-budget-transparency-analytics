import pandas as pd
from pathlib import Path

files = [
    Path("data/transformed/statement_1_standardized.csv"),
    Path("data/transformed/statement_2_standardized.csv")
]

for file in files:

    print("\n" + "=" * 60)
    print("FILE:", file)

    if not file.exists():
        print("FILE NOT FOUND")
        continue

    df = pd.read_csv(file)

    print("Rows:", len(df))
    print("Columns:", list(df.columns))

    print("\nData Types:")
    print(df.dtypes)

    print("\nSample Records:")
    print(df.head(5).to_string(index=False))