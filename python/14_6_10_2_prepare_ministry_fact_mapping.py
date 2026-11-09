
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


def to_decimal(value):
    return Decimal(str(value))


def calculate_utilization(actual, budget):
    actual = to_decimal(actual)
    budget = to_decimal(budget)

    if budget == 0:
        return None

    return (
        actual / budget * Decimal("100")
    ).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)


def calculate_variance(budget, actual):
    return to_decimal(budget) - to_decimal(actual)


try:
    with engine.connect() as conn:

        print("\n" + "=" * 75)
        print("MINISTRY FACT MAPPING PREPARATION")
        print("=" * 75)

        # ----------------------------------------------------
        # A. TARGET TABLE PRE-LOAD CHECK
        # ----------------------------------------------------

        print("\nA. TARGET TABLE CHECK")
        print("-" * 75)

        target_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM analytics.fact_ministry_budget
        """)).scalar_one()

        print(f"Existing fact records: {target_count}")

        if target_count != 0:
            raise ValueError(
                "Ministry fact table is not empty. "
                "Mapping preparation stopped."
            )

        # ----------------------------------------------------
        # B. SOURCE-TO-DIMENSION MAPPING
        # ----------------------------------------------------

        print("\nB. SOURCE-TO-DIMENSION MAPPING")
        print("-" * 75)

        query = text("""
            SELECT
                fy.fiscal_year_id,
                s.ministry_code,
                d.ministry_id,
                s.ministry_name,
                s.targeted_revenue,
                s.actual_revenue,
                s.total_budget,
                s.actual_expenditure,
                s.operating_expenditure,
                s.development_expenditure,
                s.standard_unit,
                s.financial_year,
                sd.source_document_id

            FROM staging.statement_2_import s

            JOIN analytics.dim_ministry d
                ON d.ministry_code = s.ministry_code::varchar

            JOIN analytics.dim_fiscal_year fy
                ON fy.financial_year = s.financial_year

            JOIN analytics.source_documents sd
                ON sd.source_document_id = 2

            ORDER BY s.ministry_code
        """)

        rows = conn.execute(query).mappings().all()

        print(f"Mapped records: {len(rows)}")

        if len(rows) != 62:
            raise ValueError(
                f"Expected 62 mapped records, found {len(rows)}"
            )

        # ----------------------------------------------------
        # C. VALIDATE SOURCE VALUES AND CALCULATE KPIs
        # ----------------------------------------------------

        print("\nC. KPI CALCULATION")
        print("-" * 75)

        mapping = []

        for row in rows:

            budget = to_decimal(row["total_budget"])
            actual = to_decimal(row["actual_expenditure"])

            utilization = calculate_utilization(actual, budget)
            variance = calculate_variance(budget, actual)

            if row["standard_unit"] != "BDT Crore":
                raise ValueError(
                    f"Incorrect unit for ministry {row['ministry_code']}"
                )

            if row["fiscal_year_id"] != 1:
                raise ValueError(
                    f"Unexpected fiscal year for ministry {row['ministry_code']}"
                )

            if row["source_document_id"] != 2:
                raise ValueError(
                    f"Unexpected source document for ministry {row['ministry_code']}"
                )

            if utilization is None:
                raise ValueError(
                    f"Zero budget found for ministry {row['ministry_code']}; "
                    "review before loading."
                )

            mapping.append({
                "ministry_code": row["ministry_code"],
                "ministry_id": row["ministry_id"],
                "ministry_name": row["ministry_name"],
                "fiscal_year_id": row["fiscal_year_id"],
                "source_document_id": row["source_document_id"],
                "targeted_revenue": row["targeted_revenue"],
                "actual_revenue": row["actual_revenue"],
                "total_budget": budget,
                "actual_expenditure": actual,
                "operating_expenditure": row["operating_expenditure"],
                "development_expenditure": row["development_expenditure"],
                "budget_utilization_rate": utilization,
                "budget_variance": variance,
                "standard_unit": row["standard_unit"],
            })

        print("PASS: All 62 records mapped")
        print("PASS: Ministry dimension matches validated")
        print("PASS: Fiscal year references validated")
        print("PASS: Source document references validated")
        print("PASS: All units are BDT Crore")
        print("PASS: KPI calculations completed")

        # ----------------------------------------------------
        # D. KPI SUMMARY
        # ----------------------------------------------------

        print("\nD. KPI SUMMARY")
        print("-" * 75)

        total_budget = sum(
            (item["total_budget"] for item in mapping),
            Decimal("0")
        )

        total_actual = sum(
            (item["actual_expenditure"] for item in mapping),
            Decimal("0")
        )

        total_variance = total_budget - total_actual

        overall_utilization = (
            total_actual / total_budget * Decimal("100")
        ).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)

        print(f"Total Ministry Budget : {total_budget}")
        print(f"Total Ministry Actual : {total_actual}")
        print(f"Total Budget Variance : {total_variance}")
        print(f"Overall Utilization  : {overall_utilization}%")

        # ----------------------------------------------------
        # E. SAMPLE MAPPING PREVIEW
        # ----------------------------------------------------

        print("\nE. FIRST 10 MAPPING RECORDS")
        print("-" * 75)

        for item in mapping[:10]:
            print(
                f"Code: {item['ministry_code']} | "
                f"ID: {item['ministry_id']} | "
                f"Name: {item['ministry_name']}"
            )

            print(
                f"Budget: {item['total_budget']} | "
                f"Actual: {item['actual_expenditure']} | "
                f"Utilization: {item['budget_utilization_rate']}% | "
                f"Variance: {item['budget_variance']}"
            )

        # ----------------------------------------------------
        # F. KPI EDGE CASES
        # ----------------------------------------------------

        print("\nF. KPI EDGE CASE CHECK")
        print("-" * 75)

        negative_variance = sum(
            1 for item in mapping
            if item["budget_variance"] < 0
        )

        zero_variance = sum(
            1 for item in mapping
            if item["budget_variance"] == 0
        )

        above_100_utilization = sum(
            1 for item in mapping
            if item["budget_utilization_rate"] > 100
        )

        print(f"Negative budget variance: {negative_variance}")
        print(f"Zero budget variance: {zero_variance}")
        print(f"Utilization above 100%: {above_100_utilization}")

        # ----------------------------------------------------
        # G. FINAL PRE-LOAD VALIDATION
        # ----------------------------------------------------

        print("\nG. PRE-LOAD VALIDATION")
        print("-" * 75)

        unique_ministries = len({
            item["ministry_id"] for item in mapping
        })

        unique_codes = len({
            item["ministry_code"] for item in mapping
        })

        print(f"Mapping records: {len(mapping)}")
        print(f"Unique ministry IDs: {unique_ministries}")
        print(f"Unique ministry codes: {unique_codes}")

        if unique_ministries != 62 or unique_codes != 62:
            raise ValueError(
                "Duplicate ministry mapping detected."
            )

        print("PASS: Exactly 62 unique ministry mappings")
        print("PASS: Target fact table remains empty")

        print("\n" + "=" * 75)
        print("MINISTRY FACT MAPPING PREPARATION COMPLETED")
        print("No database records were inserted or modified.")
        print("=" * 75)


except Exception as error:
    print("\nMINISTRY MAPPING PREPARATION FAILED")
    print(f"Error: {error}")
    raise

finally:
    engine.dispose()
