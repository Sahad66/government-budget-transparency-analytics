
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent

FILES = {
    "STATEMENT 1": ROOT / "data/cleaned/statement_1_final_cleaned.csv",
    "STATEMENT 2": ROOT / "data/cleaned/statement_2_final_cleaned.csv"
}

for dataset_name, file_path in FILES.items():

    print("\n" + "=" * 70)
    print(dataset_name)
    print("=" * 70)

    if not file_path.exists():
        print(f"FILE NOT FOUND: {file_path}")
        continue

    df = pd.read_csv(file_path)

    print(f"\nFile: {file_path}")
    print(f"Rows: {len(df)}")
    print(f"Columns: {len(df.columns)}")

    print("\nColumn Names:")
    for i, column in enumerate(df.columns, start=1):
        print(f"{i}. {column}")

    print("\nData Types:")
    print(df.dtypes.to_string())

    print("\nMissing Values:")
    print(df.isnull().sum().to_string())

    print("\nDuplicate Complete Rows:")
    print(df.duplicated().sum())

    print("\nFirst 3 Records:")
    print(df.head(3).to_string(index=False))

    print("\nDataset Inspection Completed.")

print("\n" + "=" * 70)
print("PRE-LOAD INSPECTION FINISHED")
print("=" * 70)
