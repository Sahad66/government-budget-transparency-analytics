from pathlib import Path
import pandas as pd
import numpy as np

PROJECT_DIR = Path(__file__).resolve().parent.parent

PROCESSED_DIR = PROJECT_DIR / "data" / "processed"

TRANSFORMED_DIR = PROJECT_DIR / "data" / "transformed"

TRANSFORMED_DIR.mkdir(
    parents=True,
    exist_ok=True
)




statement_1 = pd.read_csv(
    PROCESSED_DIR / "statement_1_cleaned.csv"
)

statement_2 = pd.read_csv(
    PROCESSED_DIR / "statement_2_cleaned.csv"
)

print("Statement 1:", statement_1.shape)
print("Statement 2:", statement_2.shape)

print(statement_1.columns.tolist())
print(statement_2.columns.tolist()) 




def convert_thousands_to_crore(df, columns):

    df = df.copy()

    for column in columns:

        if column in df.columns:

            original_column = f"{column}_original"

            df[original_column] = df[column]

            df[column] = (
                pd.to_numeric(
                    df[column],
                    errors="coerce"
                ) / 10000
            )

    return df


financial_columns = [
    "targeted_revenue",
    "actual_revenue",
    "total_budget",
    "actual_expenditure",
    "operating_expenditure",
    "development_expenditure"
]

statement_2 = convert_thousands_to_crore(
    statement_2,
    financial_columns
)

print(statement_2.head())


statement_1["source_unit"] = "BDT Crore"
statement_2["source_unit"] = "BDT Thousand"

statement_1["standard_unit"] = "BDT Crore"
statement_2["standard_unit"] = "BDT Crore"




def standardize_financial_year(value):

    if pd.isna(value):
        return pd.NA

    value = str(value).strip()

    value = value.replace("FY", "")
    value = value.replace("/", "-")

    value = value.strip()

    if len(value) == 7:
        start_year, end_year = value.split("-")

        if len(end_year) == 2:
            end_year = start_year[:2] + end_year

        return f"{start_year}-{end_year}"

    return value

statement_1["financial_year"] = "2024-2025"
statement_2["financial_year"] = "2024-2025"



def standardize_ministry_names(df):

    df = df.copy()

    if "ministry_name" in df.columns:

        df["ministry_name"] = (
            df["ministry_name"]
            .astype("string")
            .str.strip()
            .str.replace(
                r"\s+",
                " ",
                regex=True
            )
            .str.title()
        )

    return df


def calculate_utilization(df):

    df = df.copy()

    if all(
        col in df.columns
        for col in [
            "total_budget",
            "actual_expenditure"
        ]
    ):

        df["budget_utilization_rate"] = (
            df["actual_expenditure"]
            / df["total_budget"].replace(0, np.nan)
        ) * 100

    return df





if "total_budget_original" in statement_2.columns:

    statement_2["conversion_check"] = (
        statement_2["total_budget_original"] / 10000
    )

    print(
        statement_2[
            [
                "total_budget_original",
                "total_budget",
                "conversion_check"
            ]
        ].head()
    )




required_columns = [
    "operating_expenditure",
    "development_expenditure"
]

if all(
    col in statement_2.columns
    for col in required_columns
):

    statement_2["calculated_expenditure"] = (
        statement_2["operating_expenditure"]
        + statement_2["development_expenditure"]
    )

    print(
        statement_2[
            [
                "calculated_expenditure",
                "actual_expenditure"
            ]
        ].head()
    )




statement_1.to_csv(
    TRANSFORMED_DIR / "statement_1_standardized.csv",
    index=False,
    encoding="utf-8-sig"
)

statement_2.to_csv(
    TRANSFORMED_DIR / "statement_2_standardized.csv",
    index=False,
    encoding="utf-8-sig"
)

print("Transformation completed!")





