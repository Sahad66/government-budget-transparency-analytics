import pandas as pd
from pathlib import Path

# Load transformed files
s1_path = Path(
    "data/transformed/statement_1_standardized.csv"
)

s2_path = Path(
    "data/transformed/statement_2_standardized.csv"
)

s1 = pd.read_csv(s1_path)
s2 = pd.read_csv(s2_path)


# -----------------------------------
# 1. STATEMENT 1 RECORD INSPECTION
# -----------------------------------

print("\n" + "=" * 70)
print("STATEMENT 1 — ALL RECORDS")
print("=" * 70)

for index, row in s1.iterrows():

    print(f"\nRecord Index: {index}")

    for column, value in row.items():

        if pd.notna(value):
            print(f"{column}: {value}")


# -----------------------------------
# 2. STATEMENT 2 MISSING RECORDS
# -----------------------------------

print("\n" + "=" * 70)
print("STATEMENT 2 — MISSING FINANCIAL VALUES")
print("=" * 70)

financial_columns = [
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure"
]

missing_records = s2[
    s2[financial_columns].isna().any(axis=1)
]

print(
    missing_records[
        ["ministry_code", "ministry_name"] + financial_columns
    ].to_string(index=True)
)


# -----------------------------------
# 3. EXPENDITURE RECONCILIATION
# -----------------------------------

print("\n" + "=" * 70)
print("STATEMENT 2 — EXPENDITURE RECONCILIATION")
print("=" * 70)

s2["expenditure_difference"] = (
    s2["actual_expenditure"]
    - (
        s2["operating_expenditure"]
        + s2["development_expenditure"]
    )
)

reconciliation_issues = s2[
    s2["expenditure_difference"].abs() > 0.0002
]

print(
    reconciliation_issues[
        [
            "ministry_code",
            "ministry_name",
            "actual_expenditure",
            "operating_expenditure",
            "development_expenditure",
            "expenditure_difference"
        ]
    ].to_string(index=False)
)

print("\nValidation inspection completed.")