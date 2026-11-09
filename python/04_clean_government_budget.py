
from pathlib import Path
import pandas as pd
import numpy as np


# ==========================================
# STEP 1: PROJECT DIRECTORIES
# ==========================================

PROJECT_DIR = Path(__file__).resolve().parent.parent

RAW_DIR = PROJECT_DIR / "data" / "raw"
PROCESSED_DIR = PROJECT_DIR / "data" / "processed"
REPORT_DIR = PROJECT_DIR / "reports"

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)


# ==========================================
# STEP 2: LOAD EXTRACTED DATASETS
# ==========================================

statement_1 = pd.read_csv(
    PROCESSED_DIR / "statement_1_extracted.csv"
)

statement_2 = pd.read_csv(
    PROCESSED_DIR / "statement_2_extracted.csv"
)


# Preserve original datasets before cleaning

raw_statement_1 = statement_1.copy()
raw_statement_2 = statement_2.copy()


print("\n========== RAW DATASETS ==========")

print("\nStatement 1:")
print(statement_1.head())

print("\nStatement 2:")
print(statement_2.head())


# ==========================================
# STEP 3: STANDARDIZE COLUMN NAMES
# ==========================================

# Assign meaningful column names to Statement 1.

statement_1.columns = [
    "description",
    "budget_2024_25",
    "revised_budget_2024_25",
    "actual_2024_25",
    "balance_budget",
    "balance_revised",
    "actual_budget_percentage",
    "actual_revised_percentage",
    "source_page",
    "source_table"
]


# Assign meaningful column names to Statement 2.

statement_2.columns = [
    "ministry_code",
    "ministry_name",
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure",
    "source_page",
    "source_table"
]


print("\n========== STANDARDIZED COLUMNS ==========")

print("\nStatement 1:")
print(statement_1.columns.tolist())

print("\nStatement 2:")
print(statement_2.columns.tolist())


print("\nDATASET SHAPES")

print("Statement 1:", statement_1.shape)
print("Statement 2:", statement_2.shape)


# ==========================================
# STEP 4: CLEAN TEXT COLUMNS
# ==========================================

def clean_text_columns(df):

    df = df.copy()

    text_columns = df.select_dtypes(
        include=["object", "string"]
    ).columns

    for column in text_columns:

        df[column] = (
            df[column]
            .astype("string")
            .str.strip()
        )

        df[column] = df[column].replace(
            r"^\s*$",
            pd.NA,
            regex=True
        )

    return df


statement_1 = clean_text_columns(statement_1)

statement_2 = clean_text_columns(statement_2)


# ==========================================
# STEP 5: FINANCIAL COLUMNS
# ==========================================

financial_columns_1 = [
    "budget_2024_25",
    "revised_budget_2024_25",
    "actual_2024_25",
    "balance_budget",
    "balance_revised",
    "actual_budget_percentage",
    "actual_revised_percentage"
]


financial_columns_2 = [
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure"
]


# ==========================================
# STEP 6: CONVERT FINANCIAL COLUMNS
# ==========================================

def convert_financial_columns(df, columns):

    df = df.copy()

    for column in columns:

        if column in df.columns:

            cleaned_values = (
                df[column]
                .astype("string")
                .str.replace(",", "", regex=False)
                .str.strip()
            )

            df[column] = pd.to_numeric(
                cleaned_values,
                errors="coerce"
            )

    return df


statement_1 = convert_financial_columns(
    statement_1,
    financial_columns_1
)


statement_2 = convert_financial_columns(
    statement_2,
    financial_columns_2
)


print("\n========== DATA TYPES ==========")

print("\nStatement 1:")
print(statement_1.dtypes)

print("\nStatement 2:")
print(statement_2.dtypes)


# ==========================================
# STEP 7: INVESTIGATE MISSING VALUES
# ==========================================

print("\n========== MISSING VALUES ==========")

print("\nStatement 1:")

missing_statement_1 = statement_1.isnull().sum()

print(missing_statement_1)


print("\nStatement 2:")

missing_statement_2 = statement_2.isnull().sum()

print(missing_statement_2)


# ==========================================
# STEP 8: INVESTIGATE DUPLICATE RECORDS
# ==========================================

duplicate_statement_1 = statement_1[
    statement_1.duplicated(keep=False)
]

duplicate_statement_2 = statement_2[
    statement_2.duplicated(keep=False)
]


print("\n========== DUPLICATE RECORDS ==========")

print("\nStatement 1 duplicates:")
print(duplicate_statement_1)

print("\nStatement 2 duplicates:")
print(duplicate_statement_2)


# ==========================================
# STEP 9: VALIDATE NEGATIVE VALUES
# ==========================================

print("\n========== NEGATIVE FINANCIAL VALUES ==========")

print("\nStatement 1:")

for column in financial_columns_1:

    if column in statement_1.columns:

        negative_count = (
            statement_1[column] < 0
        ).sum()

        print(
            column,
            "Negative values:",
            negative_count
        )


print("\nStatement 2:")

for column in financial_columns_2:

    if column in statement_2.columns:

        negative_count = (
            statement_2[column] < 0
        ).sum()

        print(
            column,
            "Negative values:",
            negative_count
        )


# ==========================================
# STEP 10: EXPORT CLEANED DATASETS
# ==========================================

statement_1.to_csv(
    PROCESSED_DIR / "statement_1_cleaned.csv",
    index=False,
    encoding="utf-8-sig"
)


statement_2.to_csv(
    PROCESSED_DIR / "statement_2_cleaned.csv",
    index=False,
    encoding="utf-8-sig"
)


print("\nCleaned datasets exported successfully!")


# ==========================================
# STEP 11: BEFORE VS AFTER VALIDATION
# ==========================================

def compare_datasets(raw_df, clean_df, name):

    print("\nDATASET:", name)

    print("Raw Shape:", raw_df.shape)

    print("Cleaned Shape:", clean_df.shape)

    print(
        "Raw Missing Values:",
        raw_df.isnull().sum().sum()
    )

    print(
        "Cleaned Missing Values:",
        clean_df.isnull().sum().sum()
    )

    print(
        "Raw Duplicate Rows:",
        raw_df.duplicated().sum()
    )

    print(
        "Cleaned Duplicate Rows:",
        clean_df.duplicated().sum()
    )


print("\n========== BEFORE VS AFTER VALIDATION ==========")

compare_datasets(
    raw_statement_1,
    statement_1,
    "Statement 1"
)


compare_datasets(
    raw_statement_2,
    statement_2,
    "Statement 2"
)


# ==========================================
# STEP 12: FINAL COMPLETION MESSAGE         
# ==========================================

print("\n======================================")

print("PROJECT 01 - STEP 10 COMPLETED")

print("Data Cleaning Process Finished")

print("Check data/processed/ folder")

print("======================================")
