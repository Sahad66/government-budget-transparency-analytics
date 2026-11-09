from getpass import getpass

from sqlalchemy import create_engine, text, URL


# --------------------------------------------------
# DATABASE CONNECTION
# --------------------------------------------------

password = getpass("PostgreSQL password: ")

connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="government_budget_analytics"
)

engine = create_engine(connection_url)


# --------------------------------------------------
# EXPECTED EXISTING COLUMNS
# --------------------------------------------------

required_existing_columns = {
    "government_budget_id",
    "fiscal_year_id",
    "source_document_id",
    "revised_budget",
    "actual_expenditure",
    "budget_balance",
    "actual_budget_percentage",
    "operating_expenditure",
    "development_expenditure",
    "standard_unit"
}


# --------------------------------------------------
# SCHEMA ENHANCEMENT
# --------------------------------------------------

print("\n" + "=" * 65)
print("GOVERNMENT FACT TABLE SCHEMA ENHANCEMENT")
print("=" * 65)

try:

    with engine.begin() as conn:

        # Check existing columns
        existing_columns = conn.execute(text("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'analytics'
              AND table_name = 'fact_government_budget_summary';
        """)).scalars().all()

        existing_columns = set(existing_columns)

        print("\nA. PRE-ALTER VALIDATION")
        print("-" * 65)

        missing = required_existing_columns - existing_columns

        if missing:
            raise RuntimeError(
                f"Required existing columns missing: {missing}"
            )

        print("PASS: All expected existing columns found")

        # Check that table is empty
        row_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary;
        """)).scalar_one()

        print(f"Existing fact records: {row_count}")

        if row_count != 0:
            raise RuntimeError(
                "Fact table is not empty. Migration stopped safely."
            )

        print("PASS: Fact table is empty")

        # Prevent duplicate migration
        new_columns = {
            "original_budget",
            "revised_budget_balance",
            "actual_revised_percentage"
        }

        already_present = new_columns.intersection(existing_columns)

        if already_present:
            raise RuntimeError(
                f"Some new columns already exist: {already_present}"
            )

        if "original_budget_balance" in existing_columns:
            raise RuntimeError(
                "original_budget_balance already exists."
            )

        print("PASS: Schema is ready for enhancement")

        # Rename ambiguous column
        conn.execute(text("""
            ALTER TABLE analytics.fact_government_budget_summary
            RENAME COLUMN budget_balance
            TO original_budget_balance;
        """))

        print("PASS: budget_balance renamed")

        # Add new columns
        conn.execute(text("""
            ALTER TABLE analytics.fact_government_budget_summary
            ADD COLUMN original_budget NUMERIC,
            ADD COLUMN revised_budget_balance NUMERIC,
            ADD COLUMN actual_revised_percentage NUMERIC;
        """))

        print("PASS: Three new columns added")

        # Verify final structure
        final_columns = conn.execute(text("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'analytics'
              AND table_name = 'fact_government_budget_summary'
            ORDER BY ordinal_position;
        """)).scalars().all()

        print("\nB. FINAL TABLE STRUCTURE")
        print("-" * 65)

        for column in final_columns:
            print(column)

        expected_new_columns = {
            "original_budget",
            "original_budget_balance",
            "revised_budget_balance",
            "actual_revised_percentage"
        }

        if not expected_new_columns.issubset(set(final_columns)):
            raise RuntimeError(
                "Final schema validation failed."
            )

        if "budget_balance" in final_columns:
            raise RuntimeError(
                "Old budget_balance column still exists."
            )

        print("\nPASS: Final schema validation successful")


    print("\n" + "=" * 65)
    print("SCHEMA ENHANCEMENT COMPLETED")
    print("=" * 65)

except Exception as error:

    print("\nSCHEMA ENHANCEMENT FAILED")
    print(f"Reason: {error}")
    print("Transaction rolled back if an error occurred.")

finally:
    engine.dispose()