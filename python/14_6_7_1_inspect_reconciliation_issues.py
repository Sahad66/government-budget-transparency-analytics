
from getpass import getpass

from sqlalchemy import create_engine, URL, text


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

        print("\n" + "=" * 100)
        print("STATEMENT 2 - EXPENDITURE RECONCILIATION INVESTIGATION")
        print("=" * 100)

        # ------------------------------------------
        # 1. Inspect all 12 problematic records
        # ------------------------------------------

        query = text("""
            SELECT
                ministry_code,
                ministry_name,
                operating_expenditure,
                development_expenditure,
                actual_expenditure,
                calculated_expenditure,
                expenditure_difference,

                actual_expenditure
                    - operating_expenditure
                    - development_expenditure
                    AS recalculated_difference

            FROM staging.statement_2_import

            WHERE ABS(expenditure_difference) > 0.00011

            OR expenditure_difference IS NULL;
            ORDER BY ABS(expenditure_difference) DESC;
        """)

        rows = conn.execute(query).fetchall()

        print(f"\nProblematic records found: {len(rows)}")

        for row in rows:
            print("\n" + "-" * 100)
            print(f"Ministry Code: {row[0]}")
            print(f"Ministry Name: {row[1]}")
            print(f"Operating Expenditure: {row[2]}")
            print(f"Development Expenditure: {row[3]}")
            print(f"Actual Expenditure: {row[4]}")
            print(f"Calculated Expenditure: {row[5]}")
            print(f"Stored Difference: {row[6]}")
            print(f"Recalculated Difference: {row[7]}")

        # ------------------------------------------
        # 2. Overall difference statistics
        # ------------------------------------------

        print("\n" + "=" * 100)
        print("RECONCILIATION SUMMARY")
        print("=" * 100)

        summary = conn.execute(text("""
            SELECT
                COUNT(*) AS total_records,

                COUNT(*) FILTER (
                    WHERE ABS(expenditure_difference) <= 0.0001
                ) AS within_tolerance,

                COUNT(*) FILTER (
                    WHERE ABS(expenditure_difference) > 0.00011
                ) AS outside_tolerance,

                MIN(expenditure_difference),
                MAX(expenditure_difference)

            FROM staging.statement_2_import;
        """)).fetchone()

        print(f"Total records: {summary[0]}")
        print(f"Within tolerance: {summary[1]}")
        print(f"Outside tolerance: {summary[2]}")
        print(f"Minimum difference: {summary[3]}")
        print(f"Maximum difference: {summary[4]}")

        print("\nInvestigation completed.")

except Exception as error:
    print("\nINVESTIGATION FAILED")
    print(error)

finally:
    engine.dispose()
