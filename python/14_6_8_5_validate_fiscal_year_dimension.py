from getpass import getpass

from sqlalchemy import create_engine, URL, text


password = getpass("PostgreSQL password: ")

url = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="government_budget_analytics"
)

engine = create_engine(url)


try:
    with engine.connect() as conn:

        checks = []

        def check(label, query, expected):
            actual = conn.execute(text(query)).scalar()
            passed = actual == expected

            checks.append(passed)

            print(f"{'PASS' if passed else 'FAIL'}: {label}")
            print(f"       Actual: {actual}")

        print("\n" + "=" * 65)
        print("FISCAL YEAR DIMENSION FINAL VALIDATION")
        print("=" * 65)

        print("\nA. ROW COUNT")
        print("-" * 65)

        check(
            "Exactly one fiscal year record exists",
            """
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year;
            """,
            1
        )

        print("\nB. FISCAL YEAR VALUE")
        print("-" * 65)

        check(
            "Financial year is 2024-2025",
            """
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year
            WHERE financial_year = '2024-2025';
            """,
            1
        )

        check(
            "Start year is 2024",
            """
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year
            WHERE start_year = 2024;
            """,
            1
        )

        check(
            "End year is 2025",
            """
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year
            WHERE end_year = 2025;
            """,
            1
        )

        print("\nC. PRIMARY KEY VALIDATION")
        print("-" * 65)

        check(
            "Fiscal year ID is 1",
            """
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year
            WHERE fiscal_year_id = 1;
            """,
            1
        )

        check(
            "No duplicate financial years",
            """
            SELECT COUNT(*)
            FROM (
                SELECT financial_year
                FROM analytics.dim_fiscal_year
                GROUP BY financial_year
                HAVING COUNT(*) > 1
            ) duplicates;
            """,
            0
        )

        print("\nD. FINAL RECORD")
        print("-" * 65)

        row = conn.execute(text("""
            SELECT
                fiscal_year_id,
                financial_year,
                start_year,
                end_year
            FROM analytics.dim_fiscal_year;
        """)).fetchone()

        print(row)

        print("\n" + "=" * 65)
        print("FINAL VALIDATION RESULT")
        print("=" * 65)

        passed = sum(checks)
        failed = len(checks) - passed

        print("Total checks:", len(checks))
        print("Passed:", passed)
        print("Failed:", failed)

        if failed == 0:
            print("\nALL FISCAL YEAR DIMENSION CHECKS PASSED")
        else:
            print("\nVALIDATION FAILED")

finally:
    engine.dispose()