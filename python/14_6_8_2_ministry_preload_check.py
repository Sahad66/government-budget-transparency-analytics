from getpass import getpass

from sqlalchemy import create_engine, URL, text


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


try:
    with engine.connect() as conn:

        print("\n" + "=" * 65)
        print("MINISTRY PRE-LOAD READINESS CHECK")
        print("=" * 65)

        # --------------------------------------------------
        # 1. SOURCE ROW COUNT
        # --------------------------------------------------

        print("\nA. SOURCE DATA COUNT")
        print("-" * 65)

        total_rows = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import;
        """)).scalar()

        print("Total source records:", total_rows)

        # --------------------------------------------------
        # 2. NULL VALIDATION
        # --------------------------------------------------

        print("\nB. NULL VALIDATION")
        print("-" * 65)

        null_records = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import
            WHERE ministry_code IS NULL
               OR ministry_name IS NULL
               OR TRIM(ministry_name) = '';
        """)).scalar()

        print("Records with missing code/name:", null_records)

        # --------------------------------------------------
        # 3. DUPLICATE CODE VALIDATION
        # --------------------------------------------------

        print("\nC. DUPLICATE MINISTRY CODE CHECK")
        print("-" * 65)

        duplicate_codes = conn.execute(text("""
            SELECT
                ministry_code,
                COUNT(*) AS record_count
            FROM staging.statement_2_import
            GROUP BY ministry_code
            HAVING COUNT(*) > 1
            ORDER BY ministry_code;
        """)).fetchall()

        if duplicate_codes:
            for row in duplicate_codes:
                print(row)
        else:
            print("No duplicate ministry codes found.")

        # --------------------------------------------------
        # 4. DISTINCT MINISTRY COUNT
        # --------------------------------------------------

        print("\nD. DISTINCT MINISTRY COUNT")
        print("-" * 65)

        distinct_count = conn.execute(text("""
            SELECT COUNT(DISTINCT ministry_code)
            FROM staging.statement_2_import;
        """)).scalar()

        print("Distinct ministry codes:", distinct_count)

        # --------------------------------------------------
        # 5. MINISTRY ID GENERATION CHECK
        # --------------------------------------------------

        print("\nE. MINISTRY ID GENERATION")
        print("-" * 65)

        id_info = conn.execute(text("""
            SELECT
                column_default,
                is_identity,
                identity_generation
            FROM information_schema.columns
            WHERE table_schema = 'analytics'
              AND table_name = 'dim_ministry'
              AND column_name = 'ministry_id';
        """)).fetchone()

        print("Column default:", id_info.column_default)
        print("Is identity:", id_info.is_identity)
        print("Identity generation:", id_info.identity_generation)

        # --------------------------------------------------
        # 6. SOURCE MINISTRY PREVIEW
        # --------------------------------------------------

        print("\nF. SOURCE MINISTRY PREVIEW")
        print("-" * 65)

        preview = conn.execute(text("""
            SELECT DISTINCT
                ministry_code,
                ministry_name
            FROM staging.statement_2_import
            ORDER BY ministry_code
            LIMIT 10;
        """)).fetchall()

        for row in preview:
            print(row)

        # --------------------------------------------------
        # 7. FINAL READINESS
        # --------------------------------------------------

        print("\n" + "=" * 65)
        print("PRE-LOAD READINESS SUMMARY")
        print("=" * 65)

        print("Expected source rows: 62")
        print("Actual source rows:", total_rows)
        print("Distinct ministry codes:", distinct_count)
        print("Missing records:", null_records)
        print("Duplicate ministry codes:", len(duplicate_codes))

        ready = (
            total_rows == 62
            and distinct_count == 62
            and null_records == 0
            and len(duplicate_codes) == 0
        )

        print(
            "Ministry source data ready:",
            "YES" if ready else "NO"
        )

        print("\nPre-load inspection completed.")


finally:
    engine.dispose()