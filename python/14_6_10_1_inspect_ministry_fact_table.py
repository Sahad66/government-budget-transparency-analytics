
from sqlalchemy import create_engine, text
from getpass import getpass
from urllib.parse import quote_plus


# ============================================================
# DATABASE CONNECTION
# ============================================================

DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "government_budget_analytics"
DB_USER = "postgres"

password = quote_plus(getpass("PostgreSQL password: "))

DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:{password}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

engine = create_engine(DATABASE_URL)


try:
    with engine.connect() as conn:

        print("\n" + "=" * 70)
        print("MINISTRY FACT TABLE INSPECTION")
        print("=" * 70)

        # ----------------------------------------------------
        # A. TARGET TABLE ROW COUNT
        # ----------------------------------------------------

        print("\nA. TARGET TABLE")
        print("-" * 70)

        row_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        print(f"Current fact table rows: {row_count}")

        # ----------------------------------------------------
        # B. TABLE COLUMNS
        # ----------------------------------------------------

        print("\nB. TABLE STRUCTURE")
        print("-" * 70)

        columns = conn.execute(text("""
            SELECT
                ordinal_position,
                column_name,
                data_type,
                is_nullable,
                column_default,
                is_identity,
                identity_generation
            FROM information_schema.columns
            WHERE table_schema = 'analytics'
              AND table_name = 'fact_ministry_budget'
            ORDER BY ordinal_position
        """)).mappings().all()

        for column in columns:
            print(
                f"{column['ordinal_position']}. "
                f"{column['column_name']} | "
                f"Type: {column['data_type']} | "
                f"Nullable: {column['is_nullable']} | "
                f"Identity: {column['is_identity']} | "
                f"Generation: {column['identity_generation']} | "
                f"Default: {column['column_default']}"
            )

        # ----------------------------------------------------
        # C. CONSTRAINTS
        # ----------------------------------------------------

        print("\nC. TABLE CONSTRAINTS")
        print("-" * 70)

        constraints = conn.execute(text("""
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
                AND tc.table_name = kcu.table_name

            LEFT JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.constraint_name
                AND tc.constraint_schema = ccu.constraint_schema

            WHERE tc.table_schema = 'analytics'
              AND tc.table_name = 'fact_ministry_budget'

            ORDER BY tc.constraint_type, tc.constraint_name
        """)).mappings().all()

        if constraints:
            for item in constraints:
                print(
                    f"{item['constraint_name']} | "
                    f"Type: {item['constraint_type']} | "
                    f"Column: {item['column_name']} | "
                    f"References: "
                    f"{item['foreign_table_schema']}."
                    f"{item['foreign_table_name']}."
                    f"{item['foreign_column_name']}"
                )
        else:
            print("No constraints found.")

        # ----------------------------------------------------
        # D. SOURCE DATA COUNT
        # ----------------------------------------------------

        print("\nD. STATEMENT 2 SOURCE DATA")
        print("-" * 70)

        source_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import
        """)).scalar_one()

        distinct_codes = conn.execute(text("""
            SELECT COUNT(DISTINCT ministry_code)
            FROM staging.statement_2_import
        """)).scalar_one()

        print(f"Source records: {source_count}")
        print(f"Distinct ministry codes: {distinct_codes}")

        # ----------------------------------------------------
        # E. MINISTRY DIMENSION COUNT
        # ----------------------------------------------------

        print("\nE. MINISTRY DIMENSION")
        print("-" * 70)

        dimension_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.dim_ministry
        """)).scalar_one()

        print(f"Ministry dimension records: {dimension_count}")

        # ----------------------------------------------------
        # F. SOURCE-TO-DIMENSION MAPPING
        # ----------------------------------------------------

        print("\nF. SOURCE-TO-DIMENSION MAPPING")
        print("-" * 70)

        mapping = conn.execute(text("""
            SELECT
                COUNT(*) AS source_records,
                COUNT(d.ministry_id) AS matched_records,
                COUNT(*) - COUNT(d.ministry_id) AS unmatched_records

            FROM staging.statement_2_import s

            LEFT JOIN analytics.dim_ministry d
                ON d.ministry_code = s.ministry_code::varchar
        """)).mappings().one()

        print(f"Source records: {mapping['source_records']}")
        print(f"Matched records: {mapping['matched_records']}")
        print(f"Unmatched records: {mapping['unmatched_records']}")

        # ----------------------------------------------------
        # G. DUPLICATE DIMENSION MAPPING CHECK
        # ----------------------------------------------------

        print("\nG. DUPLICATE MAPPING CHECK")
        print("-" * 70)

        duplicate_mappings = conn.execute(text("""
            SELECT
                s.ministry_code,
                COUNT(d.ministry_id) AS matched_dimension_rows

            FROM staging.statement_2_import s

            LEFT JOIN analytics.dim_ministry d
                ON d.ministry_code = s.ministry_code::varchar

            GROUP BY s.ministry_code
            HAVING COUNT(d.ministry_id) > 1
        """)).mappings().all()

        print(
            f"Ministry codes with multiple dimension matches: "
            f"{len(duplicate_mappings)}"
        )

        for item in duplicate_mappings:
            print(
                f"Code: {item['ministry_code']} | "
                f"Matches: {item['matched_dimension_rows']}"
            )

        # ----------------------------------------------------
        # H. SAMPLE SOURCE RECORDS
        # ----------------------------------------------------

        print("\nH. SOURCE DATA SAMPLE")
        print("-" * 70)

        samples = conn.execute(text("""
            SELECT
                ministry_code,
                ministry_name,
                total_budget,
                actual_expenditure,
                operating_expenditure,
                development_expenditure,
                source_unit,
                standard_unit,
                financial_year

            FROM staging.statement_2_import

            ORDER BY ministry_code
            LIMIT 5
        """)).mappings().all()

        for item in samples:
            print(dict(item))

        # ----------------------------------------------------
        # I. FINANCIAL DATA SUMMARY
        # ----------------------------------------------------

        print("\nI. FINANCIAL DATA SUMMARY")
        print("-" * 70)

        summary = conn.execute(text("""
            SELECT
                COUNT(*) AS total_records,
                COUNT(total_budget) AS non_null_budgets,
                COUNT(actual_expenditure) AS non_null_actuals,
                COUNT(operating_expenditure) AS non_null_operating,
                COUNT(development_expenditure) AS non_null_development,
                COUNT(standard_unit) AS non_null_units,
                MIN(total_budget) AS minimum_budget,
                MAX(total_budget) AS maximum_budget,
                SUM(total_budget) AS total_budget_sum,
                SUM(actual_expenditure) AS total_actual_sum

            FROM staging.statement_2_import
        """)).mappings().one()

        for key, value in summary.items():
            print(f"{key}: {value}")

        print("\n" + "=" * 70)
        print("MINISTRY FACT TABLE INSPECTION COMPLETED")
        print("No database records were inserted or modified.")
        print("=" * 70)


except Exception as error:
    print(f"\nInspection failed: {error}")
    raise

finally:
    engine.dispose()
