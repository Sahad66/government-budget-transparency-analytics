
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

        print("\n" + "=" * 70)
        print("TOLERANCE DIAGNOSTIC")
        print("=" * 70)

        # 1. Stored difference check
        for tolerance in [0.0001, 0.00011, 0.0002]:

            result = conn.execute(
                text("""
                    SELECT COUNT(*)
                    FROM staging.statement_2_import
                    WHERE ABS(expenditure_difference) > :tolerance
                       OR expenditure_difference IS NULL;
                """),
                {"tolerance": tolerance}
            ).scalar()

            print(
                f"\nTolerance: {tolerance}"
                f"\nRecords outside tolerance: {result}"
            )

        # 2. Recalculate difference directly
        result = conn.execute(text("""
            SELECT
                COUNT(*) FILTER (
                    WHERE ABS(
                        actual_expenditure
                        - operating_expenditure
                        - development_expenditure
                    ) > 0.00011
                ) AS outside_tolerance,

                COUNT(*) FILTER (
                    WHERE ABS(
                        actual_expenditure
                        - operating_expenditure
                        - development_expenditure
                    ) <= 0.00011
                ) AS within_tolerance

            FROM staging.statement_2_import;
        """)).fetchone()

        print("\nRecalculated difference:")
        print("Outside tolerance:", result[0])
        print("Within tolerance:", result[1])

        # 3. Compare stored and recalculated differences
        print("\nStored vs recalculated difference:")

        rows = conn.execute(text("""
            SELECT
                ministry_code,
                ministry_name,
                expenditure_difference AS stored_difference,

                actual_expenditure
                - operating_expenditure
                - development_expenditure
                AS recalculated_difference

            FROM staging.statement_2_import

            WHERE ABS(
                expenditure_difference
                - (
                    actual_expenditure
                    - operating_expenditure
                    - development_expenditure
                )
            ) > 0.000000001

            ORDER BY ministry_code;
        """)).fetchall()

        print("Records with stored/recalculated mismatch:", len(rows))

        for row in rows:
            print(row)

        print("\nDiagnostic completed.")

except Exception as error:
    print("\nDIAGNOSTIC FAILED")
    print(error)

finally:
    engine.dispose()
