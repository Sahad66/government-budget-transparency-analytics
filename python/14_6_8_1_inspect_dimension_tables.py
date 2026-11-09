from getpass import getpass

from sqlalchemy import create_engine, URL, text


# --------------------------------------------------
# 1. DATABASE CONNECTION
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
# 2. INSPECT DIMENSION TABLES
# --------------------------------------------------

with engine.connect() as conn:

    print("\n" + "=" * 65)
    print("DIMENSION TABLE INSPECTION")
    print("=" * 65)

    tables = [
        "dim_fiscal_year",
        "dim_ministry"
    ]

    for table in tables:

        print(f"\nTABLE: analytics.{table}")
        print("-" * 65)

        count = conn.execute(text(f"""
            SELECT COUNT(*)
            FROM analytics.{table};
        """)).scalar()

        print(f"Total Records: {count}")

        columns = conn.execute(text("""
            SELECT
                column_name,
                data_type,
                is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'analytics'
              AND table_name = :table_name
            ORDER BY ordinal_position;
        """), {"table_name": table}).fetchall()

        print("\nColumns:")

        for column in columns:
            print(
                f"{column.column_name:<30}"
                f"{column.data_type:<20}"
                f"Nullable: {column.is_nullable}"
            )

    # --------------------------------------------------
    # 3. PRIMARY KEY AND FOREIGN KEY INSPECTION
    # --------------------------------------------------

    print("\n" + "=" * 65)
    print("TABLE CONSTRAINTS")
    print("=" * 65)

    constraints = conn.execute(text("""
        SELECT
            tc.table_name,
            tc.constraint_name,
            tc.constraint_type,
            kcu.column_name
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
           AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'analytics'
          AND tc.table_name IN (
              'dim_fiscal_year',
              'dim_ministry'
          )
        ORDER BY tc.table_name, tc.constraint_type;
    """)).fetchall()

    for row in constraints:
        print(
            row.table_name,
            "|",
            row.constraint_name,
            "|",
            row.constraint_type,
            "|",
            row.column_name
        )

    # --------------------------------------------------
    # 4. FISCAL YEAR DATA
    # --------------------------------------------------

    print("\n" + "=" * 65)
    print("EXISTING FISCAL YEAR DATA")
    print("=" * 65)

    fiscal_years = conn.execute(text("""
        SELECT *
        FROM analytics.dim_fiscal_year
        ORDER BY fiscal_year_id;
    """)).fetchall()

    for row in fiscal_years:
        print(row)

    # --------------------------------------------------
    # 5. MINISTRY DATA
    # --------------------------------------------------

    print("\n" + "=" * 65)
    print("EXISTING MINISTRY DATA")
    print("=" * 65)

    ministries = conn.execute(text("""
        SELECT *
        FROM analytics.dim_ministry
        ORDER BY ministry_code
        LIMIT 10;
    """)).fetchall()

    if ministries:
        for row in ministries:
            print(row)
    else:
        print("No ministry records found.")

    print("\n" + "=" * 65)
    print("DIMENSION TABLE INSPECTION COMPLETED")
    print("=" * 65)


engine.dispose()