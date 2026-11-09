
from sqlalchemy import create_engine, text
from getpass import getpass
from urllib.parse import quote_plus
from decimal import Decimal, ROUND_HALF_UP


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


def calculate_utilization(actual, budget):
    if D(budget) == 0:
        return None

    return (
        D(actual) / D(budget) * Decimal("100")
    ).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)


def calculate_variance(budget, actual):
    return D(budget) - D(actual)


try:
    with engine.connect() as conn:

        print("\n" + "=" * 75)
        print("MINISTRY FACT TABLE FINAL VALIDATION")
        print("=" * 75)

        # ----------------------------------------------------
        # A. ROW COUNT
        # ----------------------------------------------------

        print("\nA. ROW COUNT VALIDATION")
        print("-" * 75)

        fact_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        source_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM staging.statement_2_import
        """)).scalar_one()

        check(
            "Fact table contains exactly 62 records",
            fact_count == 62,
            f"Actual: {fact_count}"
        )

        check(
            "Source and fact row counts match",
            fact_count == source_count,
            f"Source: {source_count} | Fact: {fact_count}"
        )

        # ----------------------------------------------------
        # B. FACT TABLE MAPPING
        # ----------------------------------------------------

        print("\nB. DIMENSION AND SOURCE MAPPING")
        print("-" * 75)

        mapping = conn.execute(text("""
            SELECT
                f.ministry_budget_id,
                f.fiscal_year_id,
                f.ministry_id,
                f.source_document_id,
                d.ministry_code,
                f.targeted_revenue,
                f.actual_revenue,
                f.total_budget,
                f.actual_expenditure,
                f.operating_expenditure,
                f.development_expenditure,
                f.budget_utilization_rate,
                f.budget_variance,
                f.standard_unit

            FROM analytics.fact_ministry_budget f

            JOIN analytics.dim_ministry d
                ON d.ministry_id = f.ministry_id

            ORDER BY d.ministry_code
        """)).mappings().all()

        check(
            "All 62 fact records have valid ministry dimensions",
            len(mapping) == 62,
            f"Mapped records: {len(mapping)}"
        )

        ministry_ids = [r["ministry_id"] for r in mapping]
        ministry_codes = [r["ministry_code"] for r in mapping]

        check(
            "No duplicate ministry IDs",
            len(ministry_ids) == len(set(ministry_ids))
        )

        check(
            "No duplicate ministry codes",
            len(ministry_codes) == len(set(ministry_codes))
        )

        check(
            "All records belong to fiscal year ID 1",
            all(r["fiscal_year_id"] == 1 for r in mapping)
        )

        check(
            "All records reference source document ID 2",
            all(r["source_document_id"] == 2 for r in mapping)
        )

        check(
            "All records use BDT Crore",
            all(r["standard_unit"] == "BDT Crore" for r in mapping)
        )

        # ----------------------------------------------------
        # C. FINANCIAL DATA VALIDATION
        # ----------------------------------------------------

        print("\nC. FINANCIAL DATA VALIDATION")
        print("-" * 75)

        required_fields = [
            "total_budget",
            "actual_expenditure",
            "operating_expenditure",
            "development_expenditure",
            "budget_utilization_rate",
            "budget_variance",
        ]

        financial_values_valid = all(
            row[field] is not None
            for row in mapping
            for field in required_fields
        )

        check(
            "All required financial and KPI fields are populated",
            financial_values_valid
        )

        nonzero_budgets = all(
            D(row["total_budget"]) != 0
            for row in mapping
        )

        check(
            "No zero-budget records",
            nonzero_budgets
        )

        # ----------------------------------------------------
        # D. INDEPENDENT KPI VALIDATION
        # ----------------------------------------------------

        print("\nD. INDEPENDENT KPI VALIDATION")
        print("-" * 75)

        utilization_valid = True
        variance_valid = True

        for row in mapping:

            budget = D(row["total_budget"])
            actual = D(row["actual_expenditure"])

            expected_utilization = calculate_utilization(
                actual, budget
            )

            expected_variance = calculate_variance(
                budget, actual
            )

            if D(row["budget_utilization_rate"]) != expected_utilization:
                utilization_valid = False

            if D(row["budget_variance"]) != expected_variance:
                variance_valid = False

        check(
            "Budget utilization formulas are correct",
            utilization_valid
        )

        check(
            "Budget variance formulas are correct",
            variance_valid
        )

        # ----------------------------------------------------
        # E. TOTAL RECONCILIATION
        # ----------------------------------------------------

        print("\nE. TOTAL FINANCIAL RECONCILIATION")
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

        total_budget = D(totals["total_budget"])
        total_actual = D(totals["total_actual"])
        total_variance = D(totals["total_variance"])

        print(f"Total budget: {total_budget}")
        print(f"Total actual: {total_actual}")
        print(f"Total variance: {total_variance}")
        print(f"Overall utilization: {totals['overall_utilization']}%")

        check(
            "Total budget reconciliation",
            total_budget == Decimal("796999.8907")
        )

        check(
            "Total actual reconciliation",
            total_actual == Decimal("633314.6279")
        )

        check(
            "Total variance reconciliation",
            total_variance == Decimal("163685.2628")
        )

        check(
            "Overall utilization reconciliation",
            D(totals["overall_utilization"]) == Decimal("79.4623")
        )

        # ----------------------------------------------------
        # F. DUPLICATE AND ORPHAN CHECKS
        # ----------------------------------------------------

        print("\nF. DUPLICATE AND ORPHAN VALIDATION")
        print("-" * 75)

        duplicate_count = conn.execute(text("""
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
            ) duplicates
        """)).scalar_one()

        orphan_count = conn.execute(text("""
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
            "No duplicate ministry fact combinations",
            duplicate_count == 0,
            f"Duplicate groups: {duplicate_count}"
        )

        check(
            "No orphan foreign key references",
            orphan_count == 0,
            f"Orphan records: {orphan_count}"
        )

        # ----------------------------------------------------
        # G. EXCEPTION PRESERVATION
        # ----------------------------------------------------

        print("\nG. FINANCIAL EXCEPTION VALIDATION")
        print("-" * 75)

        negative_variance_count = sum(
            1 for row in mapping
            if D(row["budget_variance"]) < 0
        )

        above_100_count = sum(
            1 for row in mapping
            if D(row["budget_utilization_rate"]) > 100
        )

        print(
            f"Negative variance records: {negative_variance_count}"
        )

        print(
            f"Utilization above 100%: {above_100_count}"
        )

        check(
            "Three negative variance records preserved",
            negative_variance_count == 3
        )

        check(
            "Three above-100% utilization records preserved",
            above_100_count == 3
        )

        # ----------------------------------------------------
        # H. FINAL SUMMARY
        # ----------------------------------------------------

        print("\n" + "=" * 75)
        print("MINISTRY FACT TABLE FINAL VALIDATION SUMMARY")
        print("=" * 75)

        passed = sum(1 for _, status in checks if status)
        failed = sum(1 for _, status in checks if not status)

        print(f"Total checks: {len(checks)}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")

        if failed == 0:
            print("\nALL MINISTRY FACT TABLE VALIDATION CHECKS PASSED")
            print("STEP 14.6.10.5 COMPLETED SUCCESSFULLY")
        else:
            print("\nVALIDATION FAILED")
            raise ValueError(
                f"{failed} validation checks failed."
            )

        print("\nNo database records were inserted, updated or deleted.")


except Exception as error:
    print("\nMINISTRY FACT TABLE VALIDATION FAILED")
    print(f"Error: {error}")
    raise

finally:
    engine.dispose()
