from getpass import getpass

import pandas as pd
from sqlalchemy import create_engine, text, URL


password = getpass("PostgreSQL password: ")

url = URL.create(
    "postgresql+psycopg2",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="government_budget_analytics"
)

engine = create_engine(url)


try:

    with engine.connect() as conn:

        # Source data
        df = pd.read_sql(text("""
            SELECT *
            FROM staging.statement_1_import;
        """), conn)

        # Fiscal year mapping
        fiscal_year_id = conn.execute(text("""
            SELECT fiscal_year_id
            FROM analytics.dim_fiscal_year
            WHERE financial_year = '2024-2025';
        """)).scalar_one()

        # Source document mapping
        source_document_id = conn.execute(text("""
            SELECT source_document_id
            FROM analytics.source_documents
            WHERE source_document_id = 1;
        """)).scalar_one()

        # Fact table count
        fact_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary;
        """)).scalar_one()

    # Exact source descriptions
    def get_record(description):

        result = df[
            df["description"].str.strip() == description
        ]

        if len(result) != 1:
            raise ValueError(
                f"Expected exactly one row for: {description}. "
                f"Found: {len(result)}"
            )

        row = result.iloc[0]

        if row["unit"] != "BDT Crore":
            raise ValueError(
                f"Incorrect unit for {description}"
            )

        return row

    total = get_record("Total Expenditure :")
    operating = get_record("Operating Expenditure")
    development = get_record("Development Expenditure")

    # Prepare mapping
    mapping = {
        "fiscal_year_id": fiscal_year_id,
        "source_document_id": source_document_id,

        "original_budget": total["budget_2024_25"],
        "revised_budget": total["revised_budget_2024_25"],
        "actual_expenditure": total["actual_2024_25"],

        "original_budget_balance": total["balance_budget"],
        "revised_budget_balance": total["balance_revised"],

        "actual_budget_percentage": total["actual_budget_pct"],
        "actual_revised_percentage": total["actual_revised_pct"],

        "operating_expenditure": operating["actual_2024_25"],
        "development_expenditure": development["actual_2024_25"],

        "standard_unit": "BDT Crore"
    }

    print("\n" + "=" * 70)
    print("GOVERNMENT FACT MAPPING PREVIEW")
    print("=" * 70)

    for key, value in mapping.items():
        print(f"{key:<35}: {value}")

    # Reconciliation
    component_total = (
        mapping["operating_expenditure"]
        + mapping["development_expenditure"]
    )

    difference = (
        mapping["actual_expenditure"] - component_total
    )

    print("\nRECONCILIATION CHECK")
    print("-" * 70)

    print(f"Total Expenditure Actual : {mapping['actual_expenditure']}")
    print(f"Operating + Development  : {component_total}")
    print(f"Difference               : {difference}")

    print("\nPRE-LOAD VALIDATION")
    print("-" * 70)

    print(f"Fiscal Year ID: {fiscal_year_id}")
    print(f"Source Document ID: {source_document_id}")
    print(f"Existing Fact Records: {fact_count}")

    assert fact_count == 0, "Fact table is not empty"
    assert mapping["standard_unit"] == "BDT Crore"
    assert mapping["actual_expenditure"] == 633314

    print("PASS: Source mapping validated")
    print("PASS: Fact table is empty")
    print("PASS: Unit is BDT Crore")

    print("\nNo database records were inserted or modified.")

except Exception as error:

    print("\nMAPPING PREPARATION FAILED")
    print(f"Reason: {error}")

finally:
    engine.dispose()