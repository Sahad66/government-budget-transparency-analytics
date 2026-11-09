
from pathlib import Path
import pandas as pd

# ============================================================
# STEP 14.5.2
# SOURCE-VERIFIED STATEMENT 1 RECONSTRUCTION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

OUTPUT_DIR = PROJECT_ROOT / "data" / "reconstructed"
REPORT_DIR = PROJECT_ROOT / "reports"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_FILE = OUTPUT_DIR / "statement_1_reconstructed.csv"
REPORT_FILE = REPORT_DIR / "statement_1_reconstruction_report.txt"

COLUMNS = [
    "description",
    "budget_2024_25",
    "revised_budget_2024_25",
    "actual_2024_25",
    "balance_budget",
    "balance_revised",
    "actual_budget_pct",
    "actual_revised_pct",
    "section",
    "source_page",
]

# Values transcribed from the uploaded original Draft PDF.
# Monetary values are in BDT Crore.
# Percentage values are percentages, not monetary amounts.

rows = [

    # ========================================================
    # PAGE 1 — REVENUE AND FOREIGN GRANTS
    # ========================================================

    (
        "Revenues (Statement I)",
        540972, 517976, 436875, 104097, 81101, 80, 84,
        "Revenue and Foreign Grants", 1
    ),
    (
        "Tax Revenue",
        494999, 478000, 377697, 117302, 100303, 76, 79,
        "Revenue and Foreign Grants", 1
    ),
    (
        "NBR Tax Revenue",
        480000, 463500, 368682, 111318, 94818, 76, 79,
        "Revenue and Foreign Grants", 1
    ),
    (
        "Non-NBR Tax Revenue",
        14999, 14500, 9015, 5984, 5485, 60, 62,
        "Revenue and Foreign Grants", 1
    ),
    (
        "Non-Tax Revenue",
        45973, 39976, 59178, -13205, -19202, 128, 148,
        "Revenue and Foreign Grants", 1
    ),
    (
        "Foreign Grants/1 (Statement V)",
        4400, 4400, 4817, -417, -417, 109, 109,
        "Revenue and Foreign Grants", 1
    ),
    (
        "Total :",
        545372, 522376, 441692, 103680, 80684, 81, 85,
        "Revenue and Foreign Grants", 1
    ),

    # ========================================================
    # PAGE 1 — EXPENDITURE
    # ========================================================

    (
        "Operating Expenditure",
        506971, 506002, 476302, 30669, 29700, 94, 94,
        "Expenditure", 1
    ),
    (
        "Recurrent Expenditure (Statement III)",
        468983, 482876, 459753, 9230, 23123, 98, 95,
        "Expenditure", 1
    ),
    (
        "of which Interest",
        112655, 120655, 134430, -21775, -13775, 119, 111,
        "Expenditure", 1
    ),
    (
        "Domestic Interest",
        93000, 99500, 116617, -23617, -17117, 125, 117,
        "Expenditure", 1
    ),
    (
        "Foreign Interest",
        20500, 22000, 17812, 2688, 4188, 86, 81,
        "Expenditure", 1
    ),
    (
        "Capital Expenditure/2 (Statement IV)",
        37989, 23126, 16549, 21440, 6577, 43, 71,
        "Expenditure", 1
    ),
    (
        "Net Outlay for Food Account Operation (Statement VIII)",
        119, 1008, 439, -320, 569, 368, 43,
        "Expenditure", 1
    ),
    (
        "Loans & Advances (Net)/3 (Statement VIA)",
        8457, 5391, -156, 0, 0, -1, -2,
        "Expenditure", 1
    ),
    (
        "Development Expenditure",
        281453, 231599, 156729, 124724, 74870, 55, 67,
        "Expenditure", 1
    ),
    (
        "Scheme/4 (Statement X)",
        5943, 4653, 3136, 2807, 1517, 52, 67,
        "Expenditure", 1
    ),
    (
        "Non-ADP Special Project (Statement VIA)",
        7627, 8371, 7478, 149, 893, 98, 89,
        "Expenditure", 1
    ),
    (
        "Annual Development Programme/5 (Statement IX)",
        265000, 216000, 144356, 120644, 71644, 54, 66,
        "Expenditure", 1
    ),
    (
        "Non-ADP FFW and Transfer/6 (Statement X)",
        2884, 2575, 1758, 1126, 817, 61, 68,
        "Expenditure", 1
    ),

    # ========================================================
    # PAGE 2 — SUMMARY
    # ========================================================

    (
        "Total Expenditure :",
        797000, 744000, 633314, 163686, 110686, 80, 85,
        "Summary", 2
    ),
    (
        "Overall Deficit (Including Grants) :",
        -251628.0, -221624, -191622, 0, 0, 76, 87,
        "Summary", 2
    ),
    (
        "(In percent of GDP) :",
        -4.5, -4.0, -3.5, -0.7, -0.5, 84.4, 87.5,
        "Summary", 2
    ),
    (
        "Overall Deficit (Excluding Grants) :",
        -256028, -226024, -196439, 0, 0, 77, 87,
        "Summary", 2
    ),
    (
        "(In percent of GDP) :",
        -4.6, -4.1, -3.5, -0.7, -0.6, 84.8, 85.4,
        "Summary", 2
    ),

    # ========================================================
    # PAGE 2 — FINANCING
    # ========================================================

    (
        "Foreign Borrowing-Net",
        90700, 104600, 64774, 25926, 39826, 71, 61,
        "Financing", 2
    ),
    (
        "Foreign Borrowing (Statement V)",
        133910, 144810, 99163, 34747, 45647, 74, 68,
        "Financing", 2
    ),
    (
        "Foreign Debt Repayment (Statement IX)",
        -43210, -40210, -34389, 0, 0, 79, 85,
        "Financing", 2
    ),
    (
        "Domestic Borrowing (Statement VIB)",
        160900, 117000, 128529, 32371, -11529, 79, 109,
        "Financing", 2
    ),
    (
        "Borrowing from Banking System (Net)",
        137500, 99000, 114161, 23339, -15161, 83, 115,
        "Financing", 2
    ),
    (
        "Long-Term Debt (Net)",
        72682, 114163, 122202, -49520, -8039, 168, 107,
        "Financing", 2
    ),
    (
        "Short-Term Debt (Net)",
        64818, -15163, -8041, 0, 0, -12, 53,
        "Financing", 2
    ),
    (
        "Non-Bank Borrowing (Net)",
        23400, 18000, 14368, 9032, 3632, 61, 79,
        "Financing", 2
    ),
    (
        "National Savings Schemes (Net)",
        15400, 14000, 3401, 11999, 10599, 22, 24,
        "Financing", 2
    ),
    (
        "Others (Net)/7 (Statement VII)",
        8000, 4000, 10967, -2967, -6967, 137, 274,
        "Financing", 2
    ),
    (
        "Total - Financing :",
        251600, 221600, 193303, 58297, 28297, 77, 87,
        "Financing", 2
    ),
]

# ============================================================
# CREATE DATAFRAME
# ============================================================

df = pd.DataFrame(rows, columns=COLUMNS)

# Add source metadata
df["unit"] = df["description"].apply(
    lambda x: (
        "Percent of GDP"
        if x.strip() == "(In percent of GDP) :"
        else "BDT Crore"
    )
)

df["fiscal_year"] = "2024-25"
df["source_status"] = "Draft"
df["source_file"] = "FY2024-25_Statement_1_Budget_and_Accounts.pdf"

# ============================================================
# VALIDATION
# ============================================================

financial_columns = [
    "budget_2024_25",
    "revised_budget_2024_25",
    "actual_2024_25",
    "balance_budget",
    "balance_revised",
    "actual_budget_pct",
    "actual_revised_pct",
]

checks = {}

checks["Expected row count is 36"] = len(df) == 36
checks["No missing descriptions"] = df["description"].notna().all()
checks["No duplicate complete records"] = (
    not df.duplicated(
        subset=COLUMNS
    ).any()
)
checks["No missing financial values"] = (
    df[financial_columns].notna().all().all()
)
checks["Only PDF pages 1 and 2"] = df["source_page"].isin([1, 2]).all()

checks["Unit classification is correct"] = (
    (
        df.loc[
            df["description"].str.strip() == "(In percent of GDP) :",
            "unit"
        ] == "Percent of GDP"
    ).all()
    and
    (
        df.loc[
            df["description"].str.strip() != "(In percent of GDP) :",
            "unit"
        ] == "BDT Crore"
    ).all()
)

# Source-specific checks
def get_value(description, column):
    result = df.loc[df["description"] == description, column]
    if len(result) != 1:
        raise ValueError(f"Expected one row for: {description}")
    return result.iloc[0]

checks["Total Expenditure Actual = 633314"] = (
    get_value("Total Expenditure :", "actual_2024_25") == 633314
)

checks["Loans & Advances Actual = -156"] = (
    get_value(
        "Loans & Advances (Net)/3 (Statement VIA)",
        "actual_2024_25"
    ) == -156
)

checks["Short-Term Debt Actual = -8041"] = (
    get_value("Short-Term Debt (Net)", "actual_2024_25") == -8041
)

checks["Negative Non-Tax Revenue balance preserved"] = (
    get_value("Non-Tax Revenue", "balance_budget") == -13205
)

# ============================================================
# SAVE CSV
# ============================================================

df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8-sig")

# ============================================================
# GENERATE REPORT
# ============================================================

report = []

report.append("=" * 65)
report.append("STATEMENT 1 RECONSTRUCTION REPORT")
report.append("=" * 65)

report.append(f"Total reconstructed rows: {len(df)}")
report.append(f"Page 1 rows: {(df['source_page'] == 1).sum()}")
report.append(f"Page 2 rows: {(df['source_page'] == 2).sum()}")

report.append("\nSection-wise row counts:")

for section, count in df["section"].value_counts().items():
    report.append(f"{section}: {count}")

report.append("\nValidation Results:")

for check, passed in checks.items():
    status = "PASS" if passed else "FAIL"
    report.append(f"{status}: {check}")

report.append("\nNegative financial values:")
negative_count = (
    df[financial_columns]
    .select_dtypes(include="number")
    .lt(0)
    .sum()
    .sum()
)

report.append(f"Negative numeric cells: {negative_count}")

report.append("\nOutput:")
report.append(str(OUTPUT_FILE))

all_passed = all(checks.values())

report.append("\nFinal status:")
report.append("ALL CHECKS PASSED" if all_passed else "VALIDATION FAILED")

REPORT_FILE.write_text("\n".join(report), encoding="utf-8")

print("\n".join(report))

if not all_passed:
    raise ValueError(
        "Reconstruction validation failed. "
        "Review the report before continuing."
    )

print("\nReconstruction completed successfully.")
