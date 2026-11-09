
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
    # All database changes happen inside one transaction.
    # Any exception automatically rolls back the transaction.

    with engine.begin() as conn:

        print("\n" + "=" * 75)
        print("MINISTRY FACT TABLE DATA LOADING")
        print("=" * 75)

        # ----------------------------------------------------
        # A. LOCK TARGET TABLE
        # ----------------------------------------------------

        conn.execute(text("""
            LOCK TABLE analytics.fact_ministry_budget
            IN SHARE ROW EXCLUSIVE MODE
        """))

        print("\nA. TARGET TABLE CHECK")
        print("-" * 75)

        existing_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        print(f"Existing fact records: {existing_count}")

        if existing_count != 0:
            raise ValueError(
                "Target fact table is not empty. Loading stopped."
            )

        # ----------------------------------------------------
        # B. SOURCE MAPPING VALIDATION
        # ----------------------------------------------------

        print("\nB. SOURCE MAPPING VALIDATION")
        print("-" * 75)

        mapping_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import s

            JOIN analytics.dim_ministry d
                ON d.ministry_code = s.ministry_code::varchar

            JOIN analytics.dim_fiscal_year fy
                ON fy.financial_year = s.financial_year

            JOIN analytics.source_documents sd
                ON sd.source_document_id = 2

            WHERE
                fy.fiscal_year_id = 1
                AND s.standard_unit = 'BDT Crore'
                AND s.total_budget IS NOT NULL
                AND s.actual_expenditure IS NOT NULL
                AND s.total_budget <> 0
        """)).scalar_one()

        print(f"Valid source mappings: {mapping_count}")

        if mapping_count != 62:
            raise ValueError(
                f"Expected 62 mappings, found {mapping_count}"
            )

        duplicate_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM (
                SELECT d.ministry_id
                FROM staging.statement_2_import s

                JOIN analytics.dim_ministry d
                    ON d.ministry_code = s.ministry_code::varchar

                JOIN analytics.dim_fiscal_year fy
                    ON fy.financial_year = s.financial_year

                WHERE fy.fiscal_year_id = 1

                GROUP BY d.ministry_id
                HAVING COUNT(*) > 1
            ) duplicates
        """)).scalar_one()

        print(f"Duplicate ministry mappings: {duplicate_count}")

        if duplicate_count != 0:
            raise ValueError("Duplicate ministry mappings found.")

        # ----------------------------------------------------
        # C. INSERT INTO FACT TABLE
        # ----------------------------------------------------

        print("\nC. INSERTING MINISTRY FACT RECORDS")
        print("-" * 75)

        insert_result = conn.execute(text("""
            INSERT INTO analytics.fact_ministry_budget
            (
                fiscal_year_id,
                ministry_id,
                source_document_id,
                targeted_revenue,
                actual_revenue,
                total_budget,
                actual_expenditure,
                operating_expenditure,
                development_expenditure,
                budget_utilization_rate,
                budget_variance,
                standard_unit
            )

            SELECT
                fy.fiscal_year_id,
                d.ministry_id,
                sd.source_document_id,
                s.targeted_revenue,
                s.actual_revenue,
                s.total_budget,
                s.actual_expenditure,
                s.operating_expenditure,
                s.development_expenditure,

                ROUND(
                    s.actual_expenditure
                    / NULLIF(s.total_budget, 0) * 100,
                    4
                ),

                s.total_budget - s.actual_expenditure,

                s.standard_unit

            FROM staging.statement_2_import s

            JOIN analytics.dim_ministry d
                ON d.ministry_code = s.ministry_code::varchar

            JOIN analytics.dim_fiscal_year fy
                ON fy.financial_year = s.financial_year

            JOIN analytics.source_documents sd
                ON sd.source_document_id = 2

            WHERE
                fy.fiscal_year_id = 1
                AND s.standard_unit = 'BDT Crore'
                AND s.total_budget IS NOT NULL
                AND s.actual_expenditure IS NOT NULL
                AND s.total_budget <> 0

            ORDER BY s.ministry_code
        """))

        inserted_count = insert_result.rowcount

        print(f"Inserted records: {inserted_count}")

        if inserted_count != 62:
            raise ValueError(
                f"Expected 62 inserted records, got {inserted_count}"
            )

        # ----------------------------------------------------
        # D. POST-INSERT ROW COUNT
        # ----------------------------------------------------

        print("\nD. POST-INSERT VALIDATION")
        print("-" * 75)

        final_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        print(f"Target table records: {final_count}")

        if final_count != 62:
            raise ValueError(
                f"Expected 62 target records, found {final_count}"
            )

        # ----------------------------------------------------
        # E. KPI TOTAL CHECK
        # ----------------------------------------------------

        print("\nE. KPI TOTAL CHECK")
        print("-" * 75)

        totals = conn.execute(text("""
            SELECT
                SUM(total_budget) AS total_budget,
                SUM(actual_expenditure) AS total_actual,
                SUM(budget_variance) AS total_variance,
                ROUND(
                    SUM(actual_expenditure)
                    / NULLIF(SUM(total_budget), 0) * 100,
                    4
                ) AS overall_utilization
            FROM analytics.fact_ministry_budget
        """)).mappings().one()

        print(f"Total budget: {totals['total_budget']}")
        print(f"Total actual: {totals['total_actual']}")
        print(f"Total variance: {totals['total_variance']}")
        print(
            f"Overall utilization: "
            f"{totals['overall_utilization']}%"
        )

        from decimal import Decimal

        expected_budget = Decimal("796999.8907")
        expected_actual = Decimal("633314.6279")
        expected_variance = Decimal("163685.2628")

        actual_budget = Decimal(str(totals["total_budget"]))
        actual_actual = Decimal(str(totals["total_actual"]))
        actual_variance = Decimal(str(totals["total_variance"]))

        if actual_budget != expected_budget:
            raise ValueError(f"Budget mismatch: {actual_budget}")

        if actual_actual != expected_actual:
            raise ValueError(f"Actual mismatch: {actual_actual}")

        if actual_variance != expected_variance:
            raise ValueError(f"Variance mismatch: {actual_variance}")

        print("PASS: Total budget reconciliation")
        print("PASS: Total actual reconciliation")
        print("PASS: Total variance reconciliation")

        # ----------------------------------------------------
        # F. FINAL LOADING RESULT
        # ----------------------------------------------------

        print("\n" + "=" * 75)
        print("MINISTRY FACT TABLE LOADING RESULT")
        print("=" * 75)

        print("PASS: Target table was initially empty")
        print("PASS: 62 source mappings validated")
        print("PASS: 62 records inserted")
        print("PASS: Final row count verified")
        print("PASS: Budget total verified")
        print("PASS: Actual expenditure total verified")
        print("PASS: Budget variance verified")

        print("\nSTEP 14.6.10.4 COMPLETED SUCCESSFULLY")
        print("Transaction is ready to commit.")

    # engine.begin() commits only after all checks succeed.
    print("\nDATABASE TRANSACTION COMMITTED SUCCESSFULLY.")

except Exception as error:

    print("\nMINISTRY FACT TABLE LOADING FAILED")
    print(f"Error: {error}")
    print("Transaction rolled back if it had started.")

    raise

finally:
    engine.dispose()
