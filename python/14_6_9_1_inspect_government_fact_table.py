from getpass import getpass

import pandas as pd
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
# 1. INSPECT FACT TABLE COLUMNS
# --------------------------------------------------

print("\n" + "=" * 70)
print("GOVERNMENT BUDGET FACT TABLE INSPECTION")
print("=" * 70)

columns_query = text("""
    SELECT
        column_name,
        data_type,
        is_nullable,
        column_default,
        is_identity,
        identity_generation
    FROM information_schema.columns
    WHERE table_schema = 'analytics'
      AND table_name = 'fact_government_budget_summary'
    ORDER BY ordinal_position;
""")

with engine.connect() as conn:

    columns = pd.read_sql(columns_query, conn)

    print("\nA. FACT TABLE COLUMNS")
    print("-" * 70)
    print(columns.to_string(index=False))


# --------------------------------------------------
# 2. INSPECT CONSTRAINTS
# --------------------------------------------------

constraints_query = text("""
    SELECT
        tc.constraint_name,
        tc.constraint_type,
        kcu.column_name,
        ccu.table_schema AS foreign_table_schema,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints tc

    LEFT JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.constraint_schema = kcu.constraint_schema

    LEFT JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
        AND tc.constraint_schema = ccu.constraint_schema

    WHERE tc.table_schema = 'analytics'
      AND tc.table_name = 'fact_government_budget_summary'

    ORDER BY tc.constraint_type, tc.constraint_name;
""")

with engine.connect() as conn:

    constraints = pd.read_sql(constraints_query, conn)

    print("\nB. TABLE CONSTRAINTS")
    print("-" * 70)

    if constraints.empty:
        print("No constraints found.")
    else:
        print(constraints.to_string(index=False))


# --------------------------------------------------
# 3. CHECK EXISTING FACT RECORDS
# --------------------------------------------------

with engine.connect() as conn:

    existing_count = conn.execute(
        text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary;
        """)
    ).scalar_one()

    print("\nC. EXISTING FACT RECORDS")
    print("-" * 70)
    print(f"Existing records: {existing_count}")


# --------------------------------------------------
# 4. INSPECT STATEMENT 1 SOURCE RECORDS
# --------------------------------------------------

source_query = text("""
    SELECT
        description,
        section,
        unit,
        budget_2024_25,
        revised_budget_2024_25,
        actual_2024_25,
        balance_budget,
        balance_revised,
        actual_budget_pct,
        actual_revised_pct,
        source_page
    FROM staging.statement_1_import
    ORDER BY source_page, section, description;
""")

with engine.connect() as conn:

    source_data = pd.read_sql(source_query, conn)

    print("\nD. STATEMENT 1 SOURCE RECORDS")
    print("-" * 70)

    print(f"Total source records: {len(source_data)}")

    print(source_data.to_string(index=False))


# --------------------------------------------------
# 5. SECTION AND UNIT DISTRIBUTION
# --------------------------------------------------

print("\nE. SECTION DISTRIBUTION")
print("-" * 70)

print(
    source_data["section"]
    .value_counts(dropna=False)
    .to_string()
)

print("\nF. UNIT DISTRIBUTION")
print("-" * 70)

print(
    source_data["unit"]
    .value_counts(dropna=False)
    .to_string()
)


# --------------------------------------------------
# FINAL SUMMARY
# --------------------------------------------------

print("\n" + "=" * 70)
print("INSPECTION SUMMARY")
print("=" * 70)

print(f"Fact table columns: {len(columns)}")
print(f"Existing fact records: {existing_count}")
print(f"Statement 1 source records: {len(source_data)}")

print("\nInspection completed successfully.")

engine.dispose()