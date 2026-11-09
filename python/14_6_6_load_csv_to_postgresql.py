
import csv
from pathlib import Path
from getpass import getpass

from sqlalchemy import create_engine, URL


# --------------------------------------------------
# 1. PROJECT PATHS
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent

STATEMENT_1_FILE = (
    BASE_DIR / "data" / "cleaned" / "statement_1_final_cleaned.csv"
)

STATEMENT_2_FILE = (
    BASE_DIR / "data" / "cleaned" / "statement_2_final_cleaned.csv"
)


# --------------------------------------------------
# 2. DATABASE CONNECTION
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
# 3. EXPECTED CSV CONFIGURATION
# --------------------------------------------------

IMPORT_CONFIG = [
    {
        "name": "Statement 1",
        "file": STATEMENT_1_FILE,
        "table": "staging.statement_1_import",
        "expected_rows": 36,
        "columns": [
            "description",
            "budget_2024_25",
            "revised_budget_2024_25",
            "actual_2024_25",
            "balance_budget",
            "balance_revised",
            "actual_budget_pct",
            "actual_revised_pct",
            "section",
            "source_page",
            "unit",
            "fiscal_year",
            "source_status",
            "source_file"
        ]
    },
    {
        "name": "Statement 2",
        "file": STATEMENT_2_FILE,
        "table": "staging.statement_2_import",
        "expected_rows": 62,
        "columns": [
            "ministry_code",
            "ministry_name",
            "targeted_revenue",
            "actual_revenue",
            "total_budget",
            "actual_expenditure",
            "operating_expenditure",
            "development_expenditure",
            "source_page",
            "source_table",
            "targeted_revenue_original",
            "actual_revenue_original",
            "total_budget_original",
            "actual_expenditure_original",
            "operating_expenditure_original",
            "development_expenditure_original",
            "source_unit",
            "standard_unit",
            "financial_year",
            "conversion_check",
            "calculated_expenditure",
            "expenditure_difference"
        ]
    }
]


# --------------------------------------------------
# 4. VALIDATE CSV FILES BEFORE DATABASE IMPORT
# --------------------------------------------------

def validate_csv(config):

    file_path = config["file"]

    if not file_path.exists():
        raise FileNotFoundError(
            f"CSV file not found: {file_path}"
        )

    with open(
        file_path,
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as file:

        reader = csv.reader(file)

        headers = next(reader, None)

        if headers != config["columns"]:
            raise ValueError(
                f"Column mismatch in {config['name']}"
            )

        row_count = sum(1 for _ in reader)

    if row_count != config["expected_rows"]:
        raise ValueError(
            f"{config['name']}: Expected "
            f"{config['expected_rows']} rows, "
            f"found {row_count}"
        )

    print(
        f"PASS: {config['name']} CSV validated "
        f"({row_count} rows, {len(headers)} columns)"
    )


# --------------------------------------------------
# 5. LOAD CSV FILES INTO POSTGRESQL
# --------------------------------------------------

raw_connection = None

try:

    print("\nVALIDATING SOURCE CSV FILES")
    print("=" * 60)

    for config in IMPORT_CONFIG:
        validate_csv(config)

    raw_connection = engine.raw_connection()
    cursor = raw_connection.cursor()

    print("\nCHECKING IMPORT TABLES")
    print("=" * 60)

    # Prevent accidental duplicate imports.
    for config in IMPORT_CONFIG:

        cursor.execute(
            f"SELECT COUNT(*) FROM {config['table']}"
        )

        existing_rows = cursor.fetchone()[0]

        print(
            f"{config['table']}: "
            f"{existing_rows} existing rows"
        )

        if existing_rows != 0:
            raise RuntimeError(
                f"{config['table']} is not empty. "
                "Import stopped to prevent duplicate rows."
            )

    print("\nLOADING CSV FILES")
    print("=" * 60)

    for config in IMPORT_CONFIG:

        column_list = ", ".join(config["columns"])

        copy_sql = f"""
            COPY {config['table']} ({column_list})
            FROM STDIN
            WITH (
                FORMAT CSV,
                HEADER TRUE,
                ENCODING 'UTF8'
            );
        """

        with open(
            config["file"],
            "r",
            encoding="utf-8-sig",
            newline=""
        ) as file:

            cursor.copy_expert(copy_sql, file)

        print(
            f"PASS: {config['name']} loaded successfully"
        )

    # Verify imported row counts before committing.
    print("\nVERIFYING IMPORTED ROW COUNTS")
    print("=" * 60)

    for config in IMPORT_CONFIG:

        cursor.execute(
            f"SELECT COUNT(*) FROM {config['table']}"
        )

        actual_rows = cursor.fetchone()[0]

        print(
            f"{config['table']}: "
            f"{actual_rows} rows"
        )

        if actual_rows != config["expected_rows"]:
            raise RuntimeError(
                f"Row count mismatch in {config['table']}"
            )

    raw_connection.commit()

    print("\n" + "=" * 60)
    print("ALL CSV IMPORTS COMPLETED SUCCESSFULLY")
    print("=" * 60)

    print("Statement 1: 36 rows")
    print("Statement 2: 62 rows")
    print("Total imported rows: 98")

    print("\nStep 14.6.6 completed successfully.")

except Exception as error:

    if raw_connection is not None:
        raw_connection.rollback()

    print("\nCSV IMPORT FAILED")
    print(error)
    print("Database transaction rolled back.")

finally:

    if raw_connection is not None:
        raw_connection.close()

    engine.dispose()
