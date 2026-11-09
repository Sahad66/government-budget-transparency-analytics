
from getpass import getpass

from sqlalchemy import create_engine, URL, text


# --------------------------------------------------
# 1. DATABASE CONNECTION
# --------------------------------------------------

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


# --------------------------------------------------
# 2. VALIDATION FUNCTIONS
# --------------------------------------------------

def run_check(conn, title, query, expected=True):

    result = conn.execute(text(query)).scalar()

    passed = result == expected

    status = "PASS" if passed else "FAIL"

    print(f"{status}: {title}")
    print(f"       Actual: {result}")

    return passed


def print_value(conn, title, query):

    result = conn.execute(text(query)).fetchall()

    print(f"\n{title}")

    for row in result:
        print(" ", row)


# --------------------------------------------------
# 3. VALIDATION
# --------------------------------------------------

checks = []

try:

    with engine.connect() as conn:

        print("\n" + "=" * 65)
        print("POSTGRESQL DATA QUALITY VALIDATION")
        print("=" * 65)

        # ==========================================
        # A. ROW COUNT VALIDATION
        # ==========================================

        print("\nA. ROW COUNT VALIDATION")
        print("-" * 65)

        checks.append(run_check(
            conn,
            "Statement 1 contains exactly 36 rows",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import;
            """,
            36
        ))

        checks.append(run_check(
            conn,
            "Statement 2 contains exactly 62 rows",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import;
            """,
            62
        ))

        # ==========================================
        # B. STATEMENT 1 VALIDATION
        # ==========================================

        print("\nB. STATEMENT 1 VALIDATION")
        print("-" * 65)

        checks.append(run_check(
            conn,
            "No missing descriptions",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import
            WHERE description IS NULL
               OR TRIM(description) = '';
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "No missing financial values",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import
            WHERE budget_2024_25 IS NULL
               OR revised_budget_2024_25 IS NULL
               OR actual_2024_25 IS NULL
               OR balance_budget IS NULL
               OR balance_revised IS NULL
               OR actual_budget_pct IS NULL
               OR actual_revised_pct IS NULL;
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "No duplicate complete records",
            """
            SELECT COUNT(*)
            FROM (
                SELECT
                    description,
                    budget_2024_25,
                    revised_budget_2024_25,
                    actual_2024_25,
                    balance_budget,
                    balance_revised,
                    actual_budget_pct,
                    actual_revised_pct,
                    section,
                    source_page,
                    unit,
                    fiscal_year,
                    source_status,
                    source_file
                FROM staging.statement_1_import
                GROUP BY
                    description,
                    budget_2024_25,
                    revised_budget_2024_25,
                    actual_2024_25,
                    balance_budget,
                    balance_revised,
                    actual_budget_pct,
                    actual_revised_pct,
                    section,
                    source_page,
                    unit,
                    fiscal_year,
                    source_status,
                    source_file
                HAVING COUNT(*) > 1
            ) duplicates;
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "All Statement 1 units are classified correctly",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import
            WHERE unit NOT IN ('BDT Crore', 'Percent of GDP')
               OR unit IS NULL;
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "Statement 1 has 34 BDT Crore rows",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import
            WHERE unit = 'BDT Crore';
            """,
            34
        ))

        checks.append(run_check(
            conn,
            "Statement 1 has 2 Percent of GDP rows",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import
            WHERE unit = 'Percent of GDP';
            """,
            2
        ))

        checks.append(run_check(
            conn,
            "Negative Statement 1 values are preserved",
            """
            SELECT COUNT(*)
            FROM staging.statement_1_import
            WHERE budget_2024_25 < 0
               OR revised_budget_2024_25 < 0
               OR actual_2024_25 < 0
               OR balance_budget < 0
               OR balance_revised < 0
               OR actual_budget_pct < 0
               OR actual_revised_pct < 0;
            """,
            # At least one negative value must exist.
            # This check uses a separate comparison below.
            0
        ) if False else run_check(
            conn,
            "At least one negative Statement 1 value exists",
            """
            SELECT CASE WHEN COUNT(*) > 0
                        THEN TRUE ELSE FALSE END
            FROM staging.statement_1_import
            WHERE budget_2024_25 < 0
               OR revised_budget_2024_25 < 0
               OR actual_2024_25 < 0
               OR balance_budget < 0
               OR balance_revised < 0
               OR actual_budget_pct < 0
               OR actual_revised_pct < 0;
            """,
            True
        ))

        # ==========================================
        # C. STATEMENT 2 VALIDATION
        # ==========================================

        print("\nC. STATEMENT 2 VALIDATION")
        print("-" * 65)

        checks.append(run_check(
            conn,
            "No missing ministry codes",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import
            WHERE ministry_code IS NULL;
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "No missing ministry names",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import
            WHERE ministry_name IS NULL
               OR TRIM(ministry_name) = '';
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "No missing standardized financial values",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import
            WHERE targeted_revenue IS NULL
               OR actual_revenue IS NULL
               OR total_budget IS NULL
               OR actual_expenditure IS NULL
               OR operating_expenditure IS NULL
               OR development_expenditure IS NULL;
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "No duplicate ministry codes",
            """
            SELECT COUNT(*)
            FROM (
                SELECT ministry_code
                FROM staging.statement_2_import
                GROUP BY ministry_code
                HAVING COUNT(*) > 1
            ) duplicates;
            """,
            0
        ))

        checks.append(run_check(
            conn,
            "No duplicate complete records",
            """
            SELECT COUNT(*)
            FROM (
                SELECT *
                FROM staging.statement_2_import
                GROUP BY
                    ministry_code,
                    ministry_name,
                    targeted_revenue,
                    actual_revenue,
                    total_budget,
                    actual_expenditure,
                    operating_expenditure,
                    development_expenditure,
                    source_page,
                    source_table,
                    targeted_revenue_original,
                    actual_revenue_original,
                    total_budget_original,
                    actual_expenditure_original,
                    operating_expenditure_original,
                    development_expenditure_original,
                    source_unit,
                    standard_unit,
                    financial_year,
                    conversion_check,
                    calculated_expenditure,
                    expenditure_difference
                HAVING COUNT(*) > 1
            ) duplicates;
            """,
            0
        ))

        # ==========================================
        # D. FINANCIAL RECONCILIATION
        # ==========================================

        print("\nD. FINANCIAL RECONCILIATION")
        print("-" * 65)

        checks.append(run_check(
            conn,
            "All ministry expenditure differences are within tolerance",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import
            WHERE ABS(expenditure_difference) > 0.00011
               OR expenditure_difference IS NULL;
            """,
            0
        ))

        # Check original values / 10,000 = standardized values.
        conversion_pairs = [
            ("targeted_revenue_original", "targeted_revenue"),
            ("actual_revenue_original", "actual_revenue"),
            ("total_budget_original", "total_budget"),
            ("actual_expenditure_original", "actual_expenditure"),
            ("operating_expenditure_original", "operating_expenditure"),
            ("development_expenditure_original", "development_expenditure")
        ]

        for original_col, standard_col in conversion_pairs:

            query = f"""
                SELECT COUNT(*)
                FROM staging.statement_2_import
                WHERE ABS(
                    {original_col} / 10000.0 - {standard_col}
                ) > 0.0001
                   OR {original_col} IS NULL
                   OR {standard_col} IS NULL;
            """

            checks.append(run_check(
                conn,
                f"Unit conversion verified: {original_col}",
                query,
                0
            ))

        # ==========================================
        # E. SOURCE-SPECIFIC VALUE CHECKS
        # ==========================================

        print("\nE. SOURCE-SPECIFIC VALUE CHECKS")
        print("-" * 65)

        checks.append(run_check(
            conn,
            "Power Division operating expenditure is preserved",
            """
            SELECT COUNT(*)
            FROM staging.statement_2_import
            WHERE ministry_code = 156
              AND ABS(operating_expenditure - (-16.9959)) < 0.0001;
            """,
            1
        ))

        # ==========================================
        # F. INFORMATIONAL SUMMARIES
        # ==========================================

        print("\nF. IMPORTED DATA SUMMARY")
        print("-" * 65)

        print_value(
            conn,
            "Statement 1 unit distribution:",
            """
            SELECT unit, COUNT(*)
            FROM staging.statement_1_import
            GROUP BY unit
            ORDER BY unit;
            """
        )

        print_value(
            conn,
            "Statement 1 section distribution:",
            """
            SELECT section, COUNT(*)
            FROM staging.statement_1_import
            GROUP BY section
            ORDER BY section;
            """
        )

        print_value(
            conn,
            "Statement 2 source unit distribution:",
            """
            SELECT source_unit, standard_unit, COUNT(*)
            FROM staging.statement_2_import
            GROUP BY source_unit, standard_unit;
            """
        )

        print_value(
            conn,
            "Power Division imported values:",
            """
            SELECT
                ministry_code,
                ministry_name,
                operating_expenditure,
                development_expenditure,
                actual_expenditure
            FROM staging.statement_2_import
            WHERE ministry_code = 156;
            """
        )

        # ==========================================
        # G. FINAL RESULT
        # ==========================================

        passed = sum(checks)
        failed = len(checks) - passed

        print("\n" + "=" * 65)
        print("FINAL DATA QUALITY VALIDATION RESULT")
        print("=" * 65)

        print(f"Total checks: {len(checks)}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")

        if failed == 0:
            print("\nALL DATABASE VALIDATION CHECKS PASSED")
        else:
            print("\nSOME VALIDATION CHECKS FAILED")
            print("Review the failed checks before proceeding.")

except Exception as error:

    print("\nVALIDATION SCRIPT FAILED")
    print(error)

finally:

    engine.dispose()

