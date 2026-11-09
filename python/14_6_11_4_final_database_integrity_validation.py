
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
# HELPERS
# ============================================================

checks = []


def check(name, condition, details=""):
    passed = bool(condition)
    checks.append((name, passed))

    print(f"{'PASS' if passed else 'FAIL'}: {name}")

    if details:
        print(f"       {details}")


def D(value):
    return Decimal(str(value))


try:
    with engine.connect() as conn:

        print("\n" + "=" * 80)
        print("FINAL DATABASE INTEGRITY VALIDATION")
        print("=" * 80)

        # ----------------------------------------------------
        # A. STAGING TABLE VALIDATION
        # ----------------------------------------------------

        print("\nA. STAGING TABLE VALIDATION")
        print("-" * 80)

        statement_1_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_1_import
        """)).scalar_one()

        statement_2_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import
        """)).scalar_one()

        print(f"Statement 1 import records: {statement_1_count}")
        print(f"Statement 2 import records: {statement_2_count}")

        check(
            "Statement 1 staging contains 36 records",
            statement_1_count == 36
        )

        check(
            "Statement 2 staging contains 62 records",
            statement_2_count == 62
        )

        # ----------------------------------------------------
        # B. DIMENSION TABLE VALIDATION
        # ----------------------------------------------------

        print("\nB. DIMENSION TABLE VALIDATION")
        print("-" * 80)

        ministry_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.dim_ministry
        """)).scalar_one()

        ministry_distinct_count = conn.execute(text("""
            SELECT COUNT(DISTINCT ministry_code)
            FROM analytics.dim_ministry
        """)).scalar_one()

        fiscal_year_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year
        """)).scalar_one()

        fiscal_year = conn.execute(text("""
            SELECT financial_year
            FROM analytics.dim_fiscal_year
            WHERE fiscal_year_id = 1
        """)).scalar_one_or_none()

        print(f"Ministry dimension records: {ministry_count}")
        print(f"Distinct ministry codes: {ministry_distinct_count}")
        print(f"Fiscal year dimension records: {fiscal_year_count}")
        print(f"Fiscal year: {fiscal_year}")

        check(
            "Ministry dimension contains 62 records",
            ministry_count == 62
        )

        check(
            "All ministry codes are unique",
            ministry_distinct_count == ministry_count
        )

        check(
            "Fiscal year dimension contains one record",
            fiscal_year_count == 1
        )

        check(
            "Fiscal year is 2024-2025",
            fiscal_year == "2024-2025"
        )

        # ----------------------------------------------------
        # C. SOURCE DOCUMENT VALIDATION
        # ----------------------------------------------------

        print("\nC. SOURCE DOCUMENT VALIDATION")
        print("-" * 80)

        source_docs = conn.execute(text("""
            SELECT
                source_document_id,
                source_url,
                original_unit,
                document_status,
                financial_year
            FROM analytics.source_documents
            ORDER BY source_document_id
        """)).mappings().all()

        source_map = {
            row["source_document_id"]: row
            for row in source_docs
        }

        statement_1_url = (
            "https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/"
            "n/axvjbnqprylg/b/V2Ministry/o/office-mof/2024/12/"
            "1ab818d125f4490b9df56731aa0d432b.pdf"
        )

        statement_2_url = (
            "https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/"
            "n/axvjbnqprylg/b/V2Ministry/o/office-mof/2026/5/"
            "2740ed25-4207-4d57-a9e0-d7b7652066fe.pdf"
        )

        print(f"Source document records: {len(source_docs)}")

        check(
            "Four source document metadata records exist",
            len(source_docs) == 4
        )

        check(
            "Statement 1 official URL verified",
            (
                1 in source_map
                and source_map[1]["source_url"] == statement_1_url
            )
        )

        check(
            "Statement 2 official URL verified",
            (
                2 in source_map
                and source_map[2]["source_url"] == statement_2_url
            )
        )

        check(
            "Statement 1 original unit preserved",
            (
                1 in source_map
                and source_map[1]["original_unit"] == "BDT Crore"
            )
        )

        check(
            "Statement 2 original unit preserved",
            (
                2 in source_map
                and source_map[2]["original_unit"] == "BDT Thousand"
            )
        )

        check(
            "Both source documents retain Draft status",
            (
                1 in source_map
                and 2 in source_map
                and source_map[1]["document_status"] == "Draft"
                and source_map[2]["document_status"] == "Draft"
            )
        )

        check(
            "Both source documents retain financial year 2024-2025",
            (
                1 in source_map
                and 2 in source_map
                and source_map[1]["financial_year"] == "2024-2025"
                and source_map[2]["financial_year"] == "2024-2025"
            )
        )

        # ----------------------------------------------------
        # D. GOVERNMENT FACT TABLE VALIDATION
        # ----------------------------------------------------

        print("\nD. GOVERNMENT FACT TABLE VALIDATION")
        print("-" * 80)

        government_rows = conn.execute(text("""
            SELECT
                government_budget_id,
                fiscal_year_id,
                source_document_id,
                original_budget,
                actual_expenditure
            FROM analytics.fact_government_budget_summary
        """)).mappings().all()

        government_count = len(government_rows)

        check(
            "Government fact table contains exactly one record",
            government_count == 1,
            f"Actual: {government_count}"
        )

        government_fact = (
            government_rows[0] if government_count == 1 else None
        )

        if government_fact is not None:

            check(
                "Government fact uses fiscal year ID 1",
                government_fact["fiscal_year_id"] == 1
            )

            check(
                "Government fact references source document ID 1",
                government_fact["source_document_id"] == 1
            )

            check(
                "Government original budget is 797000",
                D(government_fact["original_budget"])
                == Decimal("797000")
            )

            check(
                "Government actual expenditure is 633314",
                D(government_fact["actual_expenditure"])
                == Decimal("633314")
            )

        # ----------------------------------------------------
        # E. MINISTRY FACT TABLE VALIDATION
        # ----------------------------------------------------

        print("\nE. MINISTRY FACT TABLE VALIDATION")
        print("-" * 80)

        ministry_fact_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        ministry_fact_totals = conn.execute(text("""
            SELECT
                SUM(total_budget) AS total_budget,
                SUM(actual_expenditure) AS total_actual,
                SUM(budget_variance) AS total_variance
            FROM analytics.fact_ministry_budget
        """)).mappings().one()

        print(f"Ministry fact records: {ministry_fact_count}")
        print(f"Total budget: {ministry_fact_totals['total_budget']}")
        print(f"Total actual: {ministry_fact_totals['total_actual']}")
        print(f"Total variance: {ministry_fact_totals['total_variance']}")

        check(
            "Ministry fact table contains 62 records",
            ministry_fact_count == 62
        )

        check(
            "Ministry total budget reconciliation",
            D(ministry_fact_totals["total_budget"])
            == Decimal("796999.8907")
        )

        check(
            "Ministry total actual reconciliation",
            D(ministry_fact_totals["total_actual"])
            == Decimal("633314.6279")
        )

        check(
            "Ministry total variance reconciliation",
            D(ministry_fact_totals["total_variance"])
            == Decimal("163685.2628")
        )

        # ----------------------------------------------------
        # F. FOREIGN KEY INTEGRITY
        # ----------------------------------------------------

        print("\nF. FOREIGN KEY INTEGRITY")
        print("-" * 80)

        government_orphans = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary f

            LEFT JOIN analytics.dim_fiscal_year fy
                ON fy.fiscal_year_id = f.fiscal_year_id

            LEFT JOIN analytics.source_documents sd
                ON sd.source_document_id = f.source_document_id

            WHERE
                fy.fiscal_year_id IS NULL
                OR sd.source_document_id IS NULL
        """)).scalar_one()

        ministry_orphans = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget f

            LEFT JOIN analytics.dim_ministry d
                ON d.ministry_id = f.ministry_id

            LEFT JOIN analytics.dim_fiscal_year fy
                ON fy.fiscal_year_id = f.fiscal_year_id

            LEFT JOIN analytics.source_documents sd
                ON sd.source_document_id = f.source_document_id

            WHERE
                d.ministry_id IS NULL
                OR fy.fiscal_year_id IS NULL
                OR sd.source_document_id IS NULL
        """)).scalar_one()

        check(
            "No orphan government fact references",
            government_orphans == 0,
            f"Orphans: {government_orphans}"
        )

        check(
            "No orphan ministry fact references",
            ministry_orphans == 0,
            f"Orphans: {ministry_orphans}"
        )

        # ----------------------------------------------------
        # G. DUPLICATE AND DATABASE CONSTRAINT VALIDATION
        # ----------------------------------------------------

        print("\nG. DUPLICATE AND CONSTRAINT VALIDATION")
        print("-" * 80)

        duplicate_ministry_facts = conn.execute(text("""
            SELECT COUNT(*)
            FROM (
                SELECT
                    fiscal_year_id,
                    ministry_id,
                    source_document_id
                FROM analytics.fact_ministry_budget
                GROUP BY
                    fiscal_year_id,
                    ministry_id,
                    source_document_id
                HAVING COUNT(*) > 1
            ) duplicate_rows
        """)).scalar_one()

        invalid_constraints = conn.execute(text("""
            SELECT COUNT(*)
            FROM pg_constraint c
            JOIN pg_namespace n
                ON n.oid = c.connamespace
            WHERE n.nspname IN ('analytics', 'staging')
              AND c.contype = 'f'
              AND NOT c.convalidated
        """)).scalar_one()

        check(
            "No duplicate ministry fact combinations",
            duplicate_ministry_facts == 0
        )

        check(
            "All foreign key constraints are validated",
            invalid_constraints == 0,
            f"Unvalidated constraints: {invalid_constraints}"
        )

        # ----------------------------------------------------
        # H. FINAL SUMMARY
        # ----------------------------------------------------

        print("\n" + "=" * 80)
        print("FINAL DATABASE INTEGRITY REPORT")
        print("=" * 80)

        passed = sum(1 for _, status in checks if status)
        failed = sum(1 for _, status in checks if not status)

        print(f"Total checks: {len(checks)}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")

        if failed == 0:
            print("\nALL FINAL DATABASE INTEGRITY CHECKS PASSED")
            print("STEP 14.6.11.4 COMPLETED SUCCESSFULLY")
            print("\nSTEP 14.6.11 COMPLETED SUCCESSFULLY")
            print("\nPHASE 3 STEP 14 COMPLETED SUCCESSFULLY")
        else:
            print("\nFINAL DATABASE INTEGRITY VALIDATION FAILED")

            failed_checks = [
                name for name, status in checks if not status
            ]

            for name in failed_checks:
                print(f"FAILED CHECK: {name}")

            raise ValueError(
                f"{failed} final database integrity checks failed."
            )

        print("\nREAD-ONLY VALIDATION: No database records modified.")


except Exception as error:
    print("\nFINAL DATABASE INTEGRITY VALIDATION ERROR")
    print(f"Error: {error}")
    raise

finally:
    engine.dispose()
