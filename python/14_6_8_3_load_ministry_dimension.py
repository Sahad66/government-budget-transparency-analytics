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

    with engine.begin() as conn:

        print("\n" + "=" * 65)
        print("MINISTRY DIMENSION TABLE LOADING")
        print("=" * 65)

        # --------------------------------------------------
        # 1. CHECK SOURCE ROWS
        # --------------------------------------------------

        source_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import;
        """)).scalar()

        print("\nSource records:", source_count)

        if source_count != 62:
            raise ValueError(
                f"Expected 62 source records, found {source_count}"
            )

        # --------------------------------------------------
        # 2. CHECK TARGET TABLE
        # --------------------------------------------------

        target_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.dim_ministry;
        """)).scalar()

        print("Existing target records:", target_count)

        if target_count != 0:
            raise ValueError(
                "Target table is not empty. Loading cancelled."
            )

        # --------------------------------------------------
        # 3. INSERT MINISTRY DATA
        # --------------------------------------------------

        print("\nLoading ministry records...")

        result = conn.execute(text("""
            INSERT INTO analytics.dim_ministry
                (
                    ministry_code,
                    ministry_name,
                    created_at
                )
            SELECT
                CAST(ministry_code AS VARCHAR),
                ministry_name,
                CURRENT_TIMESTAMP
            FROM staging.statement_2_import
            ORDER BY ministry_code
            RETURNING ministry_id;
        """))

        inserted_ids = result.fetchall()

        print("Inserted records:", len(inserted_ids))

        # --------------------------------------------------
        # 4. VALIDATE TARGET COUNT
        # --------------------------------------------------

        final_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.dim_ministry;
        """)).scalar()

        print("Final target records:", final_count)

        if final_count != 62:
            raise ValueError(
                f"Expected 62 target records, found {final_count}"
            )

        # --------------------------------------------------
        # 5. VALIDATE DUPLICATE CODES
        # --------------------------------------------------

        duplicate_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM (
                SELECT ministry_code
                FROM analytics.dim_ministry
                GROUP BY ministry_code
                HAVING COUNT(*) > 1
            ) duplicates;
        """)).scalar()

        print("Duplicate ministry codes:", duplicate_count)

        if duplicate_count != 0:
            raise ValueError("Duplicate ministry codes detected.")

        # --------------------------------------------------
        # 6. VALIDATE SOURCE-TARGET MATCH
        # --------------------------------------------------

        unmatched_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import s
            LEFT JOIN analytics.dim_ministry d
                ON d.ministry_code =
                   CAST(s.ministry_code AS VARCHAR)
            WHERE d.ministry_id IS NULL
               OR d.ministry_name <> s.ministry_name;
        """)).scalar()

        print("Unmatched source records:", unmatched_count)

        if unmatched_count != 0:
            raise ValueError(
                "Source and target ministry records do not match."
            )

        print("\n" + "=" * 65)
        print("MINISTRY DIMENSION LOADING RESULT")
        print("=" * 65)

        print("Source records: 62")
        print("Inserted records:", len(inserted_ids))
        print("Target records:", final_count)
        print("Duplicate codes:", duplicate_count)
        print("Unmatched records:", unmatched_count)

        print("\nALL MINISTRY LOADING CHECKS PASSED")

except Exception as error:

    print("\nERROR:", error)
    print("Transaction rolled back. No partial changes committed.")

finally:
    engine.dispose()