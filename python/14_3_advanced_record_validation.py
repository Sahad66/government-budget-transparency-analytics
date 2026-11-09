import pandas as pd
from pathlib import Path

path = Path(
    "data/transformed/statement_2_standardized.csv"
)

df = pd.read_csv(path)

print("=" * 70)
print("ADVANCED RECORD VALIDATION")
print("=" * 70)

# 1. Identify repeated headers

header_rows = df[
    df["ministry_code"].astype(str).str.contains(
        "Min/Div", case=False, na=False
    )
]

print("\nRepeated Header Rows:")
print(
    header_rows[
        ["ministry_code", "ministry_name"]
    ].to_string(index=True)
)


# 2. Identify missing financial values

financial_columns = [
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure"
]

missing_mask = df[financial_columns].isna().any(axis=1)

print("\nRecords with Missing Financial Values:")

print(
    df.loc[
        missing_mask,
        ["ministry_code", "ministry_name"] + financial_columns
    ].to_string(index=True)
)


# 3. Expenditure reconciliation
# Only compare rows where both components exist.

valid_mask = (
    df["actual_expenditure"].notna()
    & df["operating_expenditure"].notna()
    & df["development_expenditure"].notna()
)

df["calculated_expenditure"] = (
    df["operating_expenditure"]
    + df["development_expenditure"]
)

df["expenditure_difference"] = (
    df["actual_expenditure"]
    - df["calculated_expenditure"]
)

# Rows that cannot be reconciled

uncheckable = df[~valid_mask]

print("\nRecords Not Eligible for Reconciliation:")

print(
    uncheckable[
        ["ministry_code", "ministry_name"]
        + financial_columns
    ].to_string(index=True)
)

# Actual reconciliation differences

issues = df[
    valid_mask
    & (df["expenditure_difference"].abs() > 0.0002)
]

print("\nExpenditure Reconciliation Issues:")

print(
    issues[
        [
            "ministry_code",
            "ministry_name",
            "actual_expenditure",
            "calculated_expenditure",
            "expenditure_difference"
        ]
    ].to_string(index=True)
)


# 4. Original vs standardized conversion check

conversion_columns = [
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure"
]

print("\nConversion Validation:")

for col in conversion_columns:

    original_col = f"{col}_original"

    if original_col not in df.columns:
        continue

    expected = df[original_col] / 10000

    difference = (
        df[col] - expected
    ).abs()

    invalid = (
        difference > 0.0002
    ) & df[col].notna() & expected.notna()

    print(
        f"{col}:",
        int(invalid.sum()),
        "conversion mismatches"
    )


print("\nAdvanced validation completed.")



