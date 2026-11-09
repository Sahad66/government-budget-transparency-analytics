
from sqlalchemy import create_engine, text
from getpass import getpass
from urllib.parse import quote_plus
from decimal import Decimal


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


# ============================================================
# EXPECTED SOURCE VALUES
# ============================================================

EXPECTED = {
    "original_budget": Decimal("797000"),
    "revised_budget": Decimal("744000"),
    "actual_expenditure": Decimal("633314"),
    "original_budget_balance": Decimal("163686"),
    "revised_budget_balance": Decimal("110686"),
    "actual_budget_percentage": Decimal("80"),
    "actual_revised_percentage": Decimal("85"),
    "operating_expenditure": Decimal("476302"),
    "development_expenditure": Decimal("156729"),
}

EXPECTED_UNIT = "BDT Crore"


def to_decimal(value):
    return Decimal(str(value))


# ============================================================
# MAIN LOAD PROCESS
# ============================================================

try:
    with engine.begin() as conn:

        print("\n" + "=" * 70)
        print("GOVERNMENT FACT TABLE LOAD")
        print("=" * 70)

        # ----------------------------------------------------
        # 1. Lock target table
        # ----------------------------------------------------

        conn.execute(text("""
            LOCK TABLE analytics.fact_government_budget_summary
            IN EXCLUSIVE MODE
        """))

        # ----------------------------------------------------
        # 2. Confirm target table is empty
        # ----------------------------------------------------

        existing_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary
        """)).scalar_one()

        print(f"\nExisting fact records: {existing_count}")

        if existing_count != 0:
            raise ValueError(
                "Target fact table is not empty. "
                "Insert cancelled to prevent duplicate records."
            )

        # ----------------------------------------------------
        # 3. Read source data and dimensions
        # ----------------------------------------------------

        mapping_query = text("""
            SELECT
                fy.fiscal_year_id,
                sd.source_document_id,

                total.budget_2024_25 AS original_budget,
                total.revised_budget_2024_25 AS revised_budget,
                total.actual_2024_25 AS actual_expenditure,

                total.balance_budget AS original_budget_balance,
                total.balance_revised AS revised_budget_balance,

                total.actual_budget_pct AS actual_budget_percentage,
                total.actual_revised_pct AS actual_revised_percentage,

                operating.actual_2024_25 AS operating_expenditure,
                development.actual_2024_25 AS development_expenditure,

                total.unit AS standard_unit

            FROM staging.statement_1_import total

            JOIN analytics.dim_fiscal_year fy
                ON fy.financial_year = '2024-2025'

            JOIN analytics.source_documents sd
                ON sd.source_document_id = 1

            JOIN staging.statement_1_import operating
                ON operating.description = 'Operating Expenditure'
                AND operating.unit = 'BDT Crore'

            JOIN staging.statement_1_import development
                ON development.description = 'Development Expenditure'
                AND development.unit = 'BDT Crore'

            WHERE total.description = 'Total Expenditure :'
              AND total.section = 'Summary'
              AND total.unit = 'BDT Crore'
        """)

        mapping_rows = conn.execute(mapping_query).mappings().all()

        if len(mapping_rows) != 1:
            raise ValueError(
                f"Expected exactly one mapping row; found {len(mapping_rows)}"
            )

        data = dict(mapping_rows[0])

        # ----------------------------------------------------
        # 4. Validate dimensions and source values
        # ----------------------------------------------------

        if data["fiscal_year_id"] != 1:
            raise ValueError("Unexpected fiscal_year_id")

        if data["source_document_id"] != 1:
            raise ValueError("Unexpected source_document_id")

        if data["standard_unit"] != EXPECTED_UNIT:
            raise ValueError("Incorrect standard unit")

        for column, expected_value in EXPECTED.items():
            actual_value = to_decimal(data[column])

            if actual_value != expected_value:
                raise ValueError(
                    f"{column} mismatch: "
                    f"expected {expected_value}, got {actual_value}"
                )

        print("\nPASS: Source mapping validated")
        print("PASS: Fiscal year and source document validated")
        print("PASS: All expected financial values matched")
        print("PASS: Unit is BDT Crore")

        # ----------------------------------------------------
        # 5. Preserve reconciliation difference
        # ----------------------------------------------------

        component_total = (
            to_decimal(data["operating_expenditure"])
            + to_decimal(data["development_expenditure"])
        )

        reconciliation_difference = (
            to_decimal(data["actual_expenditure"])
            - component_total
        )

        print("\nRECONCILIATION")
        print("-" * 50)
        print(f"Government total actual : {data['actual_expenditure']}")
        print(f"Operating + Development : {component_total}")
        print(f"Difference              : {reconciliation_difference}")

        if reconciliation_difference != Decimal("283"):
            raise ValueError(
                "Unexpected reconciliation difference. Insert cancelled."
            )

        # ----------------------------------------------------
        # 6. Detect primary key generation strategy
        # ----------------------------------------------------

        identity_info = conn.execute(text("""
            SELECT
                is_identity,
                identity_generation,
                column_default
            FROM information_schema.columns
            WHERE table_schema = 'analytics'
              AND table_name = 'fact_government_budget_summary'
              AND column_name = 'government_budget_id'
        """)).mappings().one_or_none()

        if identity_info is None:
            raise ValueError("government_budget_id column not found")

        is_identity = identity_info["is_identity"] == "YES"
        has_default = identity_info["column_default"] is not None

        insert_columns = [
            "fiscal_year_id",
            "source_document_id",
            "revised_budget",
            "actual_expenditure",
            "original_budget_balance",
            "actual_budget_percentage",
            "operating_expenditure",
            "development_expenditure",
            "standard_unit",
            "original_budget",
            "revised_budget_balance",
            "actual_revised_percentage",
        ]

        if is_identity or has_default:
            print("\nPASS: Primary key will be generated automatically")
        else:
            next_id = conn.execute(text("""
                SELECT COALESCE(MAX(government_budget_id), 0) + 1
                FROM analytics.fact_government_budget_summary
            """)).scalar_one()

            data["government_budget_id"] = next_id
            insert_columns.insert(0, "government_budget_id")

            print(f"\nPrimary key assigned safely: {next_id}")

        # ----------------------------------------------------
        # 7. Insert exactly one fact record
        # ----------------------------------------------------

        column_sql = ", ".join(insert_columns)
        parameter_sql = ", ".join(
            f":{column}" for column in insert_columns
        )

        insert_query = text(f"""
            INSERT INTO analytics.fact_government_budget_summary
            ({column_sql})
            VALUES ({parameter_sql})
            RETURNING government_budget_id
        """)

        inserted_id = conn.execute(
            insert_query, data
        ).scalar_one()

        # ----------------------------------------------------
        # 8. Verify inserted record
        # ----------------------------------------------------

        final_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary
        """)).scalar_one()

        if final_count != 1:
            raise ValueError(
                f"Expected one fact record; found {final_count}"
            )

        inserted_record = conn.execute(text("""
            SELECT *
            FROM analytics.fact_government_budget_summary
            WHERE government_budget_id = :record_id
        """), {"record_id": inserted_id}).mappings().one()

        if to_decimal(inserted_record["actual_expenditure"]) != Decimal("633314"):
            raise ValueError("Inserted actual expenditure verification failed")

        if inserted_record["standard_unit"] != EXPECTED_UNIT:
            raise ValueError("Inserted unit verification failed")

        print("\n" + "=" * 70)
        print("GOVERNMENT FACT LOAD REPORT")
        print("=" * 70)

        print(f"Inserted Government Budget ID: {inserted_id}")
        print(f"Final fact table row count: {final_count}")
        print("PASS: Exactly one record inserted")
        print("PASS: Inserted record verified")
        print("PASS: Reconciliation difference preserved")

        print("\nSTEP 14.6.9.5 COMPLETED SUCCESSFULLY")

except Exception as error:
    print("\n" + "=" * 70)
    print("GOVERNMENT FACT LOAD FAILED")
    print("=" * 70)
    print(f"Error: {error}")
    print("Database transaction rolled back.")
    raise

finally:
    engine.dispose()
