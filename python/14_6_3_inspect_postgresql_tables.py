
from sqlalchemy import create_engine, text, URL
from getpass import getpass

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

tables = [
    ("staging", "statement_1_raw"),
    ("staging", "statement_2_raw"),
    ("analytics", "dim_fiscal_year"),
    ("analytics", "dim_ministry"),
    ("analytics", "fact_government_budget_summary"),
    ("analytics", "fact_ministry_budget"),
    ("analytics", "source_documents")
]

try:
    with engine.connect() as conn:

        for schema, table in tables:

            print("\n" + "=" * 65)
            print(f"TABLE: {schema}.{table}")
            print("=" * 65)

            exists = conn.execute(
                text("""
                    SELECT EXISTS (
                        SELECT 1
                        FROM information_schema.tables
                        WHERE table_schema = :schema
                          AND table_name = :table
                    )
                """),
                {"schema": schema, "table": table}
            ).scalar()

            if not exists:
                print("TABLE NOT FOUND")
                continue

            columns = conn.execute(
                text("""
                    SELECT
                        column_name,
                        data_type,
                        is_nullable
                    FROM information_schema.columns
                    WHERE table_schema = :schema
                      AND table_name = :table
                    ORDER BY ordinal_position
                """),
                {"schema": schema, "table": table}
            ).fetchall()

            print("\nColumns:")

            for col in columns:
                print(
                    f"{col.column_name:<35} "
                    f"{col.data_type:<20} "
                    f"Nullable: {col.is_nullable}"
                )

            # Table names are from the fixed allowlist above.
            count = conn.execute(
                text(f'SELECT COUNT(*) FROM "{schema}"."{table}"')
            ).scalar()

            print(f"\nExisting rows: {count}")

    print("\nInspection completed successfully.")

except Exception as error:
    print("\nINSPECTION FAILED")
    print(error)

finally:
    engine.dispose()
