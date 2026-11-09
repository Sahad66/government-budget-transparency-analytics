from sqlalchemy import create_engine, text
from getpass import getpass
from urllib.parse import quote_plus

password = quote_plus(getpass("PostgreSQL password: "))

engine = create_engine(
    f"postgresql+psycopg2://postgres:{password}"
    "@localhost:5432/government_budget_analytics"
)

try:
    with engine.connect() as conn:

        print("\n" + "=" * 65)
        print("MINISTRY FACT TABLE ROLLBACK CHECK")
        print("=" * 65)

        count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        print(f"\nFact table row count: {count}")

        if count == 0:
            print("PASS: Transaction rollback confirmed.")
        else:
            print("WARNING: Fact table contains records.")

        totals = conn.execute(text("""
            SELECT
                SUM(total_budget) AS total_budget,
                SUM(actual_expenditure) AS total_actual,
                SUM(budget_variance) AS total_variance
            FROM analytics.fact_ministry_budget
        """)).mappings().one()

        for column, value in totals.items():
            print(f"{column}: {value!r}")
            print(f"Python type: {type(value).__name__}")

        print("\nNo database records were modified.")

finally:
    engine.dispose()