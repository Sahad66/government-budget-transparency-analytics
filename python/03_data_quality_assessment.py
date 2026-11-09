from pathlib import Path
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent

PROCESSED_DIR = PROJECT_DIR / "data" / "processed"
REPORT_DIR = PROJECT_DIR / "reports"

REPORT_DIR.mkdir(exist_ok=True)

FILES = {
    "Statement 1": PROCESSED_DIR / "statement_1_extracted.csv",
    "Statement 2": PROCESSED_DIR / "statement_2_extracted.csv"
}


def assess_dataset(dataset_name, file_path):

    print("\n" + "=" * 65)
    print("DATA QUALITY REPORT:", dataset_name)
    print("=" * 65)

    if not file_path.exists():
        print("FILE NOT FOUND:", file_path)
        return

    df = pd.read_csv(file_path)

    print("\n1. DATASET OVERVIEW")
    print("Rows:", df.shape[0])
    print("Columns:", df.shape[1])

    print("\n2. COLUMN NAMES")
    print(df.columns.tolist())

    print("\n3. DATA TYPES")
    print(df.dtypes)

    print("\n4. MISSING VALUES")
    missing = df.isnull().sum()
    print(missing)

    print("\n5. MISSING VALUE PERCENTAGE")
    missing_percentage = (
        df.isnull().mean() * 100
    ).round(2)
    print(missing_percentage)

    print("\n6. DUPLICATE ROWS")
    print("Duplicate count:", df.duplicated().sum())

    print("\n7. BLANK STRING VALUES")
    blank_counts = (
        df.select_dtypes(include="object")
        .apply(lambda col: col.astype("string").str.strip().eq("").sum())
    )
    print(blank_counts)

    print("\n8. UNIQUE VALUES")
    for column in df.columns:
        print(column, ":", df[column].nunique(dropna=True))

    print("\n9. NUMERIC SUMMARY")
    print(df.describe(include="number"))

    print("\n10. SAMPLE RECORDS")
    print(df.head(10).to_string(index=False))

    report_path = REPORT_DIR / (
        dataset_name.lower().replace(" ", "_")
        + "_quality_report.txt"
    )

    with open(report_path, "w", encoding="utf-8") as file:
        file.write(f"DATA QUALITY REPORT: {dataset_name}\n")
        file.write("=" * 50 + "\n\n")
        file.write(f"Shape: {df.shape}\n\n")
        file.write("Data Types:\n")
        file.write(df.dtypes.to_string() + "\n\n")
        file.write("Missing Values:\n")
        file.write(missing.to_string() + "\n\n")
        file.write("Missing Percentage:\n")
        file.write(missing_percentage.to_string() + "\n\n")
        file.write(f"Duplicate Rows: {df.duplicated().sum()}\n\n")
        file.write("Blank Values:\n")
        file.write(blank_counts.to_string() + "\n")

    print("\nREPORT SAVED:", report_path)


for name, path in FILES.items():
    assess_dataset(name, path)
