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

            print(
                f"{'PASS' if passed else 'FAIL'}: {label}"
            )
            print(f"       Actual: {actual}")

        print("\n" + "=" * 65)
        print("MINISTRY DIMENSION FINAL VALIDATION")
        print("=" * 65)

        print("\nA. ROW COUNT")
        print("-" * 65)

        check(
            "Source contains 62 records",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import;
            """,
            62
        )

        check(
            "Dimension contains 62 records",
            """
            SELECT COUNT(*)
            FROM analytics.dim_ministry;
            """,
            62
        )

        print("\nB. PRIMARY KEY VALIDATION")
        print("-" * 65)

        check(
            "No duplicate ministry IDs",
            """
            SELECT COUNT(*)
            FROM (
                SELECT ministry_id
                FROM analytics.dim_ministry
                GROUP BY ministry_id
                HAVING COUNT(*) > 1
            ) x;
            """,
            0
        )

        print("\nC. MINISTRY CODE VALIDATION")
        print("-" * 65)

        check(
            "No duplicate ministry codes",
            """
            SELECT COUNT(*)
            FROM (
                SELECT ministry_code
                FROM analytics.dim_ministry
                GROUP BY ministry_code
                HAVING COUNT(*) > 1
            ) x;
            """,
            0
        )

        check(
            "No missing ministry codes",
            """
            SELECT COUNT(*)
            FROM analytics.dim_ministry
            WHERE ministry_code IS NULL
               OR TRIM(ministry_code) = '';
            """,
            0
        )

        check(
            "No missing ministry names",
            """
            SELECT COUNT(*)
            FROM analytics.dim_ministry
            WHERE ministry_name IS NULL
               OR TRIM(ministry_name) = '';
            """,
            0
        )

        print("\nD. SOURCE-TARGET COMPARISON")
        print("-" * 65)

        check(
            "No source records missing in dimension",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import s
            LEFT JOIN analytics.dim_ministry d
                ON d.ministry_code =
                   CAST(s.ministry_code AS VARCHAR)
            WHERE d.ministry_id IS NULL;
            """,
            0
        )

        check(
            "No ministry name mismatches",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import s
            JOIN analytics.dim_ministry d
                ON d.ministry_code =
                   CAST(s.ministry_code AS VARCHAR)
            WHERE d.ministry_name <> s.ministry_name;
            """,
            0
        )

        check(
            "No extra records in dimension",
            """
            SELECT COUNT(*)
            FROM analytics.dim_ministry d
            LEFT JOIN staging.statement_2_import s
                ON d.ministry_code =
                   CAST(s.ministry_code AS VARCHAR)
            WHERE s.ministry_code IS NULL;
            """,
            0
        )

        print("\nE. MINISTRY ID MAPPING PREVIEW")
        print("-" * 65)

        rows = conn.execute(text("""
            SELECT
                ministry_id,
                ministry_code,
                ministry_name
            FROM analytics.dim_ministry
            ORDER BY ministry_code
            LIMIT 10;
        """)).fetchall()

        for row in rows:
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
            print("\nALL MINISTRY DIMENSION CHECKS PASSED")
        else:
            print("\nVALIDATION FAILED")

finally:
    engine.dispose()