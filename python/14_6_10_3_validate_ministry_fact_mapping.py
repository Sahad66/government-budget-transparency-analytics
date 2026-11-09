
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
        print("MINISTRY KPI AND MAPPING VALIDATION")
        print("=" * 75)

        # ----------------------------------------------------
        # A. TARGET TABLE MUST REMAIN EMPTY
        # ----------------------------------------------------

        print("\nA. TARGET TABLE CHECK")
        print("-" * 75)

        target_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        check(
            "Ministry fact table remains empty before loading",
            target_count == 0,
            f"Existing records: {target_count}"
        )

        # ----------------------------------------------------
        # B. REBUILD SOURCE MAPPING
        # ----------------------------------------------------

        print("\nB. SOURCE MAPPING")
        print("-" * 75)

        rows = conn.execute(text("""
            SELECT
                s.ministry_code,
                s.ministry_name,
                d.ministry_id,
                fy.fiscal_year_id,
                sd.source_document_id,
                s.total_budget,
                s.actual_expenditure,
                s.targeted_revenue,
                s.actual_revenue,
                s.operating_expenditure,
                s.development_expenditure,
                s.standard_unit

            FROM staging.statement_2_import s

            JOIN analytics.dim_ministry d
                ON d.ministry_code = s.ministry_code::varchar

            JOIN analytics.dim_fiscal_year fy
                ON fy.financial_year = s.financial_year

            JOIN analytics.source_documents sd
                ON sd.source_document_id = 2

            ORDER BY s.ministry_code
        """)).mappings().all()

        check(
            "Exactly 62 source records mapped",
            len(rows) == 62,
            f"Actual: {len(rows)}"
        )

        codes = [row["ministry_code"] for row in rows]
        ids = [row["ministry_id"] for row in rows]

        check(
            "No duplicate ministry codes",
            len(codes) == len(set(codes))
        )

        check(
            "No duplicate ministry dimension IDs",
            len(ids) == len(set(ids))
        )

        # ----------------------------------------------------
        # C. FINANCIAL AND DIMENSION VALIDATION
        # ----------------------------------------------------

        print("\nC. FINANCIAL AND DIMENSION VALIDATION")
        print("-" * 75)

        valid_rows = True

        for row in rows:

            if row["fiscal_year_id"] != 1:
                valid_rows = False

            if row["source_document_id"] != 2:
                valid_rows = False

            if row["standard_unit"] != "BDT Crore":
                valid_rows = False

            if row["total_budget"] is None:
                valid_rows = False

            if row["actual_expenditure"] is None:
                valid_rows = False

            if row["total_budget"] is not None:
                if D(row["total_budget"]) == 0:
                    valid_rows = False

        check(
            "All dimensions, units and financial values valid",
            valid_rows
        )

        # ----------------------------------------------------
        # D. INDEPENDENT KPI CALCULATIONS
        # ----------------------------------------------------

        print("\nD. INDEPENDENT KPI CALCULATIONS")
        print("-" * 75)

        calculated = []

        for row in rows:

            budget = D(row["total_budget"])
            actual = D(row["actual_expenditure"])

            utilization = calculate_utilization(actual, budget)
            variance = calculate_variance(budget, actual)

            calculated.append({
                "ministry_code": row["ministry_code"],
                "ministry_name": row["ministry_name"],
                "budget": budget,
                "actual": actual,
                "utilization": utilization,
                "variance": variance,
            })

        total_budget = sum(
            (item["budget"] for item in calculated),
            Decimal("0")
        )

        total_actual = sum(
            (item["actual"] for item in calculated),
            Decimal("0")
        )

        total_variance = total_budget - total_actual

        overall_utilization = (
            total_actual / total_budget * Decimal("100")
        ).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)

        check(
            "Total budget matches mapping result",
            total_budget == Decimal("796999.8907"),
            f"Actual: {total_budget}"
        )

        check(
            "Total actual matches mapping result",
            total_actual == Decimal("633314.6279"),
            f"Actual: {total_actual}"
        )

        check(
            "Total variance is correct",
            total_variance == Decimal("163685.2628"),
            f"Actual: {total_variance}"
        )

        check(
            "Overall utilization is correct",
            overall_utilization == Decimal("79.4623"),
            f"Actual: {overall_utilization}%"
        )

        # ----------------------------------------------------
        # E. EXCEPTION RECORDS
        # ----------------------------------------------------

        print("\nE. KPI EXCEPTION RECORDS")
        print("-" * 75)

        negative_variance = [
            item for item in calculated
            if item["variance"] < 0
        ]

        above_100 = [
            item for item in calculated
            if item["utilization"] > 100
        ]

        zero_variance = [
            item for item in calculated
            if item["variance"] == 0
        ]

        print(f"Negative variance records: {len(negative_variance)}")

        for item in negative_variance:
            print(
                f"Code: {item['ministry_code']} | "
                f"{item['ministry_name']} | "
                f"Variance: {item['variance']}"
            )

        print(f"\nUtilization above 100%: {len(above_100)}")

        for item in above_100:
            print(
                f"Code: {item['ministry_code']} | "
                f"{item['ministry_name']} | "
                f"Utilization: {item['utilization']}%"
            )

        check(
            "Negative variance count matches inspection",
            len(negative_variance) == 3
        )

        check(
            "Above 100% utilization count matches inspection",
            len(above_100) == 3
        )

        check(
            "Zero variance count matches inspection",
            len(zero_variance) == 0
        )

        # ----------------------------------------------------
        # F. SOURCE RECONCILIATION
        # ----------------------------------------------------

        print("\nF. SOURCE TOTAL RECONCILIATION")
        print("-" * 75)

        government_fact = conn.execute(text("""
            SELECT
                original_budget,
                actual_expenditure
            FROM analytics.fact_government_budget_summary
            WHERE government_budget_id = 1
        """)).mappings().one_or_none()

        check(
            "Government summary fact record exists",
            government_fact is not None
        )

        if government_fact is not None:

            budget_difference = (
                D(government_fact["original_budget"]) - total_budget
            )

            actual_difference = (
                D(government_fact["actual_expenditure"]) - total_actual
            )

            print(
                f"Government original budget: "
                f"{government_fact['original_budget']}"
            )

            print(f"Ministry total budget: {total_budget}")
            print(f"Budget difference: {budget_difference}")

            print(
                f"\nGovernment actual expenditure: "
                f"{government_fact['actual_expenditure']}"
            )

            print(f"Ministry total actual: {total_actual}")
            print(f"Actual difference: {actual_difference}")

            check(
                "Budget source difference is preserved and measurable",
                budget_difference != 0
            )

            check(
                "Actual source difference is preserved and measurable",
                actual_difference != 0
            )

        # ----------------------------------------------------
        # G. FINAL SUMMARY
        # ----------------------------------------------------

        print("\n" + "=" * 75)
        print("MINISTRY MAPPING VALIDATION SUMMARY")
        print("=" * 75)

        passed = sum(1 for _, status in checks if status)
        failed = sum(1 for _, status in checks if not status)

        print(f"Total checks: {len(checks)}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")

        if failed == 0:
            print("\nALL MINISTRY MAPPING VALIDATION CHECKS PASSED")
            print("STEP 14.6.10.3 COMPLETED SUCCESSFULLY")
        else:
            print("\nVALIDATION FAILED")
            raise ValueError(
                f"{failed} validation checks failed."
            )

        print("\nNo database records were inserted or modified.")


except Exception as error:
    print("\nMINISTRY MAPPING VALIDATION FAILED")
    print(f"Error: {error}")
    raise

finally:
    engine.dispose()
