
from pathlib import Path
import pandas as pd

# --------------------------------------------------
# PROJECT PATHS
# --------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent

INPUT_FILE = ROOT / "data" / "reconstructed" / "statement_1_reconstructed.csv"
OUTPUT_DIR = ROOT / "data" / "cleaned"
REPORT_DIR = ROOT / "reports"

OUTPUT_FILE = OUTPUT_DIR / "statement_1_final_cleaned.csv"
REPORT_FILE = REPORT_DIR / "statement_1_final_cleaning_report.txt"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)

# --------------------------------------------------
# LOAD DATA
# --------------------------------------------------

df = pd.read_csv(INPUT_FILE)

original_rows = len(df)

financial_columns = [
    "budget_2024_25",
    "revised_budget_2024_25",
    "actual_2024_25",
    "balance_budget",
    "balance_revised",
    "actual_budget_pct",
    "actual_revised_pct"
]

required_columns = [
    "description",
    "section",
    "source_page",
    "unit",
    "fiscal_year",
    "source_status",
    "source_file"
] + financial_columns

# --------------------------------------------------
# VALIDATION
# --------------------------------------------------

checks = {}

checks["Required columns exist"] = all(
    col in df.columns for col in required_columns
)

if not checks["Required columns exist"]:
    raise ValueError("Required columns are missing.")

checks["Expected row count is 36"] = len(df) == 36

checks["No missing descriptions"] = (
    df["description"].notna().all()
)

checks["No duplicate complete records"] = (
    not df.duplicated().any()
)

checks["No missing financial values"] = (
    df[financial_columns].notna().all().all()
)

checks["Financial columns are numeric"] = all(
    pd.api.types.is_numeric_dtype(df[col])
    for col in financial_columns
)

checks["Unit classification is correct"] = (
    (
        df.loc[
            df["description"].str.strip()
            == "(In percent of GDP) :",
            "unit"
        ] == "Percent of GDP"
    ).all()
    and
    (
        df.loc[
            df["description"].str.strip()
            != "(In percent of GDP) :",
            "unit"
        ] == "BDT Crore"
    ).all()
)

checks["Fiscal year is 2024-25"] = (
    (df["fiscal_year"] == "2024-25").all()
)

checks["Source status is Draft"] = (
    (df["source_status"] == "Draft").all()
)

checks["Source pages are valid"] = (
    df["source_page"].isin([1, 2]).all()
)

checks["Negative values preserved"] = (
    (df["actual_2024_25"] < 0).any()
    and
    (df["balance_budget"] < 0).any()
)

# --------------------------------------------------
# CLEANING
# --------------------------------------------------

# Remove accidental leading/trailing spaces in text metadata.
text_columns = [
    "description",
    "section",
    "unit",
    "fiscal_year",
    "source_status",
    "source_file"
]

for col in text_columns:
    df[col] = df[col].astype("string").str.strip()

# Keep source row order and all original financial values.
df = df.reset_index(drop=True)

# --------------------------------------------------
# FINAL UNIT COUNTS
# --------------------------------------------------

unit_counts = df["unit"].value_counts().to_dict()

# --------------------------------------------------
# STOP IF ANY CHECK FAILS
# --------------------------------------------------

print("=" * 65)
print("STATEMENT 1 FINAL CLEANING REPORT")
print("=" * 65)

for name, result in checks.items():
    print(f"{'PASS' if result else 'FAIL'}: {name}")

print("\nUnit distribution:")

for unit, count in unit_counts.items():
    print(f"{unit}: {count}")

if not all(checks.values()):
    raise ValueError("Final cleaning validation failed.")

# --------------------------------------------------
# SAVE FINAL DATASET
# --------------------------------------------------

df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8-sig")

# --------------------------------------------------
# SAVE REPORT
# --------------------------------------------------

report = [
    "STATEMENT 1 FINAL CLEANING REPORT",
    "=" * 50,
    f"Original rows: {original_rows}",
    f"Final rows: {len(df)}",
    f"BDT Crore rows: {unit_counts.get('BDT Crore', 0)}",
    f"Percent of GDP rows: {unit_counts.get('Percent of GDP', 0)}",
    f"Negative numeric cells: {int((df[financial_columns] < 0).sum().sum())}",
    "",
    "VALIDATION RESULTS"
]

for name, result in checks.items():
    report.append(
        f"{'PASS' if result else 'FAIL'}: {name}"
    )

report.extend([
    "",
    "Financial values were preserved from the reconstructed source.",
    "No missing values were imputed.",
    "No negative values were converted to positive.",
    "No source financial values were recalculated.",
    "",
    f"Output file: {OUTPUT_FILE}",
    "Final status: ALL CHECKS PASSED"
])

REPORT_FILE.write_text(
    "\n".join(report),
    encoding="utf-8"
)

print("\nOutput:")
print(OUTPUT_FILE)

print("\nReport:")
print(REPORT_FILE)

print("\nFinal status:")
print("ALL CHECKS PASSED")
print("Statement 1 final cleaning completed.")
