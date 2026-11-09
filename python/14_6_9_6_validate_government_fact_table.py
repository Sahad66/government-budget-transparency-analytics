
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
# VALIDATION HELPERS
# ============================================================

checks = []


def check(name, condition, details=""):
    status = bool(condition)
    checks.append((name, status))

    print(f"{'PASS' if status else 'FAIL'}: {name}")

    if details:
        print(f"       {details}")


def decimal_equal(actual, expected):
    return Decimal(str(actual)) == Decimal(str(expected))


# ============================================================
# EXPECTED VALUES
# ============================================================

EXPECTED = {
    "government_budget_id": 1,
    "fiscal_year_id": 1,
    "source_document_id": 1,
    "original_budget": Decimal("797000"),
    "revised_budget": Decimal("744000"),
    "actual_expenditure": Decimal("633314"),
    "original_budget_balance": Decimal("163686"),
    "revised_budget_balance": Decimal("110686"),
    "actual_budget_percentage": Decimal("80"),
    "actual_revised_percentage": Decimal("85"),
    "operating_expenditure": Decimal("476302"),
    "development_expenditure": Decimal("156729"),
    "standard_unit": "BDT Crore",
}


try:
    with engine.connect() as conn:

        print("\n" + "=" * 70)
        print("GOVERNMENT FACT TABLE FINAL VALIDATION")
        print("=" * 70)

        # ----------------------------------------------------
        # A. ROW COUNT
        # ----------------------------------------------------

        row_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary
        """)).scalar_one()

        print("\nA. ROW COUNT")
        print("-" * 70)

        check(
            "Exactly one government fact record exists",
            row_count == 1,
            f"Actual rows: {row_count}"
        )

        # ----------------------------------------------------
        # B. READ INSERTED RECORD
        # ----------------------------------------------------

        record = conn.execute(text("""
            SELECT *
            FROM analytics.fact_government_budget_summary
            WHERE government_budget_id = 1
        """)).mappings().one_or_none()

        print("\nB. PRIMARY RECORD VALIDATION")
        print("-" * 70)

        check(
            "Government fact record ID 1 exists",
            record is not None
        )

        if record is None:
            raise ValueError(
                "Government fact record not found. "
                "Cannot continue validation."
            )

        # ----------------------------------------------------
        # C. DIMENSION AND SOURCE REFERENCES
        # ----------------------------------------------------

        print("\nC. FOREIGN KEY REFERENCE VALIDATION")
        print("-" * 70)

        fiscal_year_exists = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.dim_fiscal_year
            WHERE fiscal_year_id = :id
        """), {"id": record["fiscal_year_id"]}).scalar_one()

        source_document_exists = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.source_documents
            WHERE source_document_id = :id
        """), {"id": record["source_document_id"]}).scalar_one()

        check(
            "Fiscal year dimension reference exists",
            fiscal_year_exists == 1
        )

        check(
            "Source document reference exists",
            source_document_exists == 1
        )

        # ----------------------------------------------------
        # D. FINANCIAL VALUE VALIDATION
        # ----------------------------------------------------

        print("\nD. FINANCIAL VALUE VALIDATION")
        print("-" * 70)

        for column, expected in EXPECTED.items():

            actual = record[column]

            if isinstance(expected, Decimal):
                passed = decimal_equal(actual, expected)
            else:
                passed = actual == expected

            check(
                f"{column} matches expected value",
                passed,
                f"Actual: {actual}"
            )

        # ----------------------------------------------------
        # E. SOURCE-TO-FACT VALIDATION
        # ----------------------------------------------------

        print("\nE. SOURCE-TO-FACT VALIDATION")
        print("-" * 70)

        source_rows = conn.execute(text("""
            SELECT
                total.budget_2024_25 AS original_budget,
                total.revised_budget_2024_25 AS revised_budget,
                total.actual_2024_25 AS actual_expenditure,
                total.balance_budget AS original_budget_balance,
                total.balance_revised AS revised_budget_balance,
                total.actual_budget_pct AS actual_budget_percentage,
                total.actual_revised_pct AS actual_revised_percentage,
                operating.actual_2024_25 AS operating_expenditure,
                development.actual_2024_25 AS development_expenditure

            FROM staging.statement_1_import total

            JOIN staging.statement_1_import operating
                ON operating.description = 'Operating Expenditure'
                AND operating.unit = 'BDT Crore'

            JOIN staging.statement_1_import development
                ON development.description = 'Development Expenditure'
                AND development.unit = 'BDT Crore'

            WHERE total.description = 'Total Expenditure :'
              AND total.section = 'Summary'
              AND total.unit = 'BDT Crore'
        """)).mappings().all()

        check(
            "Exactly one source mapping row exists",
            len(source_rows) == 1,
            f"Source mapping rows: {len(source_rows)}"
        )

        if len(source_rows) != 1:
            raise ValueError(
                "Source mapping is missing or ambiguous."
            )

        source = source_rows[0]

        source_columns = [
            "original_budget",
            "revised_budget",
            "actual_expenditure",
            "original_budget_balance",
            "revised_budget_balance",
            "actual_budget_percentage",
            "actual_revised_percentage",
            "operating_expenditure",
            "development_expenditure",
        ]

        for column in source_columns:
            check(
                f"{column} matches staging source",
                decimal_equal(record[column], source[column]),
                f"Fact: {record[column]} | Source: {source[column]}"
            )

        # ----------------------------------------------------
        # F. RECONCILIATION VALIDATION
        # ----------------------------------------------------

        print("\nF. RECONCILIATION VALIDATION")
        print("-" * 70)

        component_total = (
            Decimal(str(record["operating_expenditure"]))
            + Decimal(str(record["development_expenditure"]))
        )

        total_actual = Decimal(str(record["actual_expenditure"]))

        difference = total_actual - component_total

        print(f"Government Actual Expenditure : {total_actual}")
        print(f"Operating + Development       : {component_total}")
        print(f"Reconciliation Difference     : {difference}")

        check(
            "Reconciliation difference of 283 is preserved",
            difference == Decimal("283")
        )

        # ----------------------------------------------------
        # G. DUPLICATE AND ORPHAN CHECKS
        # ----------------------------------------------------

        print("\nG. DATABASE INTEGRITY VALIDATION")
        print("-" * 70)

        duplicate_ids = conn.execute(text("""
            SELECT COUNT(*)
            FROM (
                SELECT government_budget_id
                FROM analytics.fact_government_budget_summary
                GROUP BY government_budget_id
                HAVING COUNT(*) > 1
            ) duplicates
        """)).scalar_one()

        orphan_fiscal_years = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary f
            LEFT JOIN analytics.dim_fiscal_year d
                ON f.fiscal_year_id = d.fiscal_year_id
            WHERE d.fiscal_year_id IS NULL
        """)).scalar_one()

        orphan_sources = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary f
            LEFT JOIN analytics.source_documents s
                ON f.source_document_id = s.source_document_id
            WHERE s.source_document_id IS NULL
        """)).scalar_one()

        check(
            "No duplicate government fact IDs",
            duplicate_ids == 0
        )

        check(
            "No orphan fiscal year references",
            orphan_fiscal_years == 0
        )

        check(
            "No orphan source document references",
            orphan_sources == 0
        )

        # ----------------------------------------------------
        # H. FINAL REPORT
        # ----------------------------------------------------

        print("\n" + "=" * 70)
        print("FINAL VALIDATION SUMMARY")
        print("=" * 70)

        passed = sum(1 for _, status in checks if status)
        failed = sum(1 for _, status in checks if not status)

        print(f"Total checks : {len(checks)}")
        print(f"Passed       : {passed}")
        print(f"Failed       : {failed}")

        if failed == 0:
            print("\nALL GOVERNMENT FACT VALIDATION CHECKS PASSED")
            print("STEP 14.6.9 COMPLETED SUCCESSFULLY")
        else:
            print("\nVALIDATION FAILED")
            raise ValueError(
                f"{failed} validation check(s) failed."
            )

except Exception as error:
    print("\n" + "=" * 70)
    print("GOVERNMENT FACT VALIDATION ERROR")
    print("=" * 70)
    print(f"Error: {error}")
    raise

finally:
    engine.dispose()
