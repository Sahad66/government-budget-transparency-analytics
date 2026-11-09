import pandas as pd
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent

DOCS_DIR = PROJECT_DIR / "docs"
DOCS_DIR.mkdir(exist_ok=True)

data = [
    {
        "original_name": "Ministry Code",
        "standard_name": "ministry_code",
        "description": "Unique code assigned to a ministry or division",
        "data_type": "TEXT",
        "unit": "N/A",
        "source": "Statement 2",
        "nullable": "To be verified",
        "validation_rule": "Check consistency and uniqueness"
    },
    {
        "original_name": "Ministry Name",
        "standard_name": "ministry_name",
        "description": "Name of the ministry or division",
        "data_type": "TEXT",
        "unit": "N/A",
        "source": "Statement 2",
        "nullable": "To be verified",
        "validation_rule": "Should not be blank for ministry records"
    },
    {
        "original_name": "Total Budget",
        "standard_name": "total_budget",
        "description": "Total budget allocated to the ministry or division",
        "data_type": "DECIMAL",
        "unit": "Taka in Thousands",
        "source": "Statement 2",
        "nullable": "To be verified",
        "validation_rule": "Check numeric values and source definitions"
    },
    {
        "original_name": "Actual Expenditure",
        "standard_name": "actual_expenditure",
        "description": "Actual expenditure reported for the financial year",
        "data_type": "DECIMAL",
        "unit": "Taka in Thousands",
        "source": "Statement 2",
        "nullable": "To be verified",
        "validation_rule": "Check numeric values and source definitions"
    }
]

df = pd.DataFrame(data)

output_file = DOCS_DIR / "data_dictionary.csv"

df.to_csv(output_file, index=False, encoding="utf-8-sig")

print("Data Dictionary created successfully!")
print("File:", output_file)
print("\nPreview:")
print(df.to_string(index=False))