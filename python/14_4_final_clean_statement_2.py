
import pandas as pd
from pathlib import Path

# ==================================================
# 1. PROJECT PATHS
# ==================================================

PROJECT_DIR = Path(__file__).resolve().parent.parent

INPUT_FILE = (
    PROJECT_DIR
    / "data"
    / "transformed"
    / "statement_2_standardized.csv"
)

OUTPUT_DIR = PROJECT_DIR / "data" / "cleaned"

OUTPUT_FILE = OUTPUT_DIR / "statement_2_final_cleaned.csv"

REPORT_DIR = PROJECT_DIR / "reports"

REPORT_FILE = (
    REPORT_DIR / "statement_2_final_cleaning_report.txt"
)

MISSING_FILE = (
    REPORT_DIR / "statement_2_missing_values.csv"
)

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)


# ==================================================
# 2. LOAD STANDARDIZED DATA
# ==================================================

if not INPUT_FILE.exists():
    raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

df = pd.read_csv(
    INPUT_FILE,
    dtype={"ministry_code": str}
)

original_row_count = len(df)

print("=" * 65)
print("STATEMENT 2 FINAL DATA CLEANING")
print("=" * 65)

print(f"\nOriginal rows: {original_row_count}")


# ==================================================
# 3. VALIDATE REQUIRED COLUMNS
# ==================================================

required_columns = [
    "ministry_code",
    "ministry_name",
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure",
    "source_page",
    "source_table",
    "source_unit",
    "standard_unit",
    "financial_year"
]

missing_columns = [
    col for col in required_columns
    if col not in df.columns
]

if missing_columns:
    raise ValueError(
        f"Required columns missing: {missing_columns}"
    )


# ==================================================
# 4. REMOVE REPEATED HEADER ROWS
# ==================================================

df["ministry_code"] = (
    df["ministry_code"].astype("string").str.strip()
)

df["ministry_name"] = (
    df["ministry_name"].astype("string").str.strip()
)

header_mask = (
    df["ministry_code"].str.contains(
        "Min/Div", case=False, na=False
    )
    |
    df["ministry_name"].str.contains(
        "Ministry/Division Description",
        case=False,
        na=False
    )
)

repeated_headers_removed = int(header_mask.sum())

df = df.loc[~header_mask].copy()

print(f"Repeated headers removed: {repeated_headers_removed}")


# ==================================================
# 5. CLEAN IDENTIFIER TEXT
# ==================================================

df["ministry_code"] = df["ministry_code"].str.strip()

df["ministry_name"] = (
    df["ministry_name"]
    .str.replace(r"\s+", " ", regex=True)
    .str.strip()
)


# ==================================================
# 6. CONVERT FINANCIAL COLUMNS TO NUMERIC
# ==================================================

financial_columns = [
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure",
    "targeted_revenue_original",
    "actual_revenue_original",
    "total_budget_original",
    "actual_expenditure_original",
    "operating_expenditure_original",
    "development_expenditure_original"
]

for col in financial_columns:
    if col in df.columns:
        df[col] = pd.to_numeric(
            df[col],
            errors="coerce"
        )


# ==================================================
# 7. VERIFY POWER DIVISION
# ==================================================

power_mask = (
    df["ministry_code"].astype(str).str.strip() == "156"
) & (
    df["ministry_name"].astype(str).str.strip()
    == "Power Division"
)

power_count = int(power_mask.sum())

if power_count != 1:
    raise ValueError(
        f"Expected one Power Division record, found {power_count}"
    )

power_row = df.loc[power_mask].iloc[0]

power_operating = power_row["operating_expenditure"]

if pd.isna(power_operating):
    raise ValueError(
        "Power Division Operating Expenditure is still missing."
    )

if power_operating >= 0:
    raise ValueError(
        "Power Division Operating Expenditure is not negative. "
        "Check the PDF-verified correction before continuing."
    )

print("\nPower Division verification:")
print("Operating Expenditure:", power_operating)
print("Negative value preserved: YES")


# ==================================================
# 8. CALCULATE EXPENDITURE RECONCILIATION
# ==================================================

df["calculated_expenditure"] = (
    df["operating_expenditure"]
    + df["development_expenditure"]
)

df["expenditure_difference"] = (
    df["actual_expenditure"]
    - df["calculated_expenditure"]
)

eligible = (
    df["actual_expenditure"].notna()
    & df["operating_expenditure"].notna()
    & df["development_expenditure"].notna()
)

reconciliation_tolerance = 0.0002

reconciliation_issues = (
    eligible
    & (
        df["expenditure_difference"].abs()
        > reconciliation_tolerance
    )
)

eligible_count = int(eligible.sum())
issue_count = int(reconciliation_issues.sum())


# ==================================================
# 9. FINAL MISSING VALUE REPORT
# ==================================================

missing_counts = df.isna().sum()

missing_percentages = (
    df.isna().mean() * 100
).round(2)

missing_report = pd.DataFrame({
    "column_name": df.columns,
    "missing_count": [
        int(missing_counts[col]) for col in df.columns
    ],
    "missing_percentage": [
        float(missing_percentages[col]) for col in df.columns
    ]
})

missing_report.to_csv(
    MISSING_FILE,
    index=False
)


# ==================================================
# 10. CHECK DUPLICATE RECORDS
# ==================================================

duplicate_count = int(df.duplicated().sum())


# ==================================================
# 11. SAVE FINAL CLEANED DATA
# ==================================================

df.to_csv(
    OUTPUT_FILE,
    index=False
)

final_row_count = len(df)


# ==================================================
# 12. GENERATE FINAL CLEANING REPORT
# ==================================================

missing_financial_records = int(
    df[[
        "targeted_revenue",
        "actual_revenue",
        "total_budget",
        "actual_expenditure",
        "operating_expenditure",
        "development_expenditure"
    ]].isna().any(axis=1).sum()
)

report_lines = [
    "=" * 65,
    "STATEMENT 2 FINAL CLEANING REPORT",
    "=" * 65,
    "",
    f"Input file: {INPUT_FILE.name}",
    f"Output file: {OUTPUT_FILE.name}",
    "",
    f"Original row count: {original_row_count}",
    f"Repeated headers removed: {repeated_headers_removed}",
    f"Final row count: {final_row_count}",
    "",
    f"Duplicate rows: {duplicate_count}",
    f"Records with missing financial values: {missing_financial_records}",
    "",
    f"Power Division records: {power_count}",
    f"Power Division Operating Expenditure: {power_operating}",
    "Power Division negative value preserved: YES",
    "",
    f"Reconciliation eligible records: {eligible_count}",
    f"Reconciliation issues: {issue_count}",
    "",
    "Missing value report:",
    str(MISSING_FILE),
    "",
    "Final cleaned dataset:",
    str(OUTPUT_FILE),
    "",
    "Note: Missing values were not replaced with zero.",
    "Original and standardized input files were not modified.",
    "=" * 65
]

REPORT_FILE.write_text(
    "\n".join(report_lines),
    encoding="utf-8"
)


# ==================================================
# 13. PRINT FINAL RESULTS
# ==================================================

print("\n" + "=" * 65)
print("FINAL CLEANING SUMMARY")
print("=" * 65)

print("Original rows:", original_row_count)
print("Headers removed:", repeated_headers_removed)
print("Final rows:", final_row_count)
print("Duplicate rows:", duplicate_count)
print(
    "Missing financial records:",
    missing_financial_records
)

print("Reconciliation eligible:", eligible_count)
print("Reconciliation issues:", issue_count)

print("\nOutput files:")
print(OUTPUT_FILE)
print(REPORT_FILE)
print(MISSING_FILE)

print("\nFinal cleaning completed.")
