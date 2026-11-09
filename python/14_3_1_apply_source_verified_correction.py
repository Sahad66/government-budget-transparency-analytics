
import pandas as pd
from pathlib import Path
import shutil

# --------------------------------------------------
# 1. FILE PATHS
# --------------------------------------------------

PROJECT_DIR = Path(__file__).resolve().parent.parent

FILE_PATH = (
    PROJECT_DIR
    / "data"
    / "transformed"
    / "statement_2_standardized.csv"
)

BACKUP_PATH = (
    PROJECT_DIR
    / "data"
    / "transformed"
    / "statement_2_standardized_before_correction.csv"
)

# --------------------------------------------------
# 2. LOAD DATA
# --------------------------------------------------

df = pd.read_csv(
    FILE_PATH,
    dtype={"ministry_code": str}
)

# --------------------------------------------------
# 3. FIND POWER DIVISION
# --------------------------------------------------

mask = (
    df["ministry_code"].astype(str).str.strip() == "156"
) & (
    df["ministry_name"].astype(str).str.strip()
    == "Power Division"
)

matching_rows = df.loc[mask]

if len(matching_rows) != 1:
    raise ValueError(
        f"Expected exactly 1 Power Division row, "
        f"but found {len(matching_rows)}."
    )

# --------------------------------------------------
# 4. CREATE BACKUP
# --------------------------------------------------

if not BACKUP_PATH.exists():
    shutil.copy2(FILE_PATH, BACKUP_PATH)
    print("Backup created successfully.")

# --------------------------------------------------
# 5. APPLY PDF-VERIFIED VALUE
# --------------------------------------------------

# Original PDF value:
# -16,99,59 Taka in Thousands = -169959

df.loc[mask, "operating_expenditure_original"] = -169959

# Convert Taka Thousands to BDT Crore
df.loc[mask, "operating_expenditure"] = -169959 / 10000

# --------------------------------------------------
# 6. RECALCULATE EXPENDITURE
# --------------------------------------------------

calculated = (
    df.loc[mask, "operating_expenditure"]
    + df.loc[mask, "development_expenditure"]
)

if "calculated_expenditure" in df.columns:
    df.loc[mask, "calculated_expenditure"] = calculated.values

# --------------------------------------------------
# 7. SAVE CORRECTED FILE
# --------------------------------------------------

df.to_csv(FILE_PATH, index=False)

# --------------------------------------------------
# 8. VERIFY RESULT
# --------------------------------------------------

row = df.loc[mask].iloc[0]

difference = (
    row["actual_expenditure"]
    - row["operating_expenditure"]
    - row["development_expenditure"]
)

print("\nPOWER DIVISION CORRECTION")
print("--------------------------------")
print("Ministry Code:", row["ministry_code"])
print("Ministry Name:", row["ministry_name"])

print(
    "Operating Expenditure (Original):",
    row["operating_expenditure_original"]
)

print(
    "Operating Expenditure (BDT Crore):",
    row["operating_expenditure"]
)

print(
    "Development Expenditure:",
    row["development_expenditure"]
)

print(
    "Actual Expenditure:",
    row["actual_expenditure"]
)

print("Reconciliation Difference:", difference)

if abs(difference) <= 0.0002:
    print("\nSTATUS: RECONCILIATION PASSED")
else:
    print("\nSTATUS: RECONCILIATION NEEDS INVESTIGATION")
