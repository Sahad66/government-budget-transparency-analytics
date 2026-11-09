
from sqlalchemy import create_engine, text, URL
from getpass import getpass

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

ddl_statements = [

    """
    CREATE TABLE IF NOT EXISTS staging.statement_1_import (
        description TEXT NOT NULL,
        budget_2024_25 NUMERIC,
        revised_budget_2024_25 NUMERIC,
        actual_2024_25 NUMERIC,
        balance_budget NUMERIC,
        balance_revised NUMERIC,
        actual_budget_pct NUMERIC,
        actual_revised_pct NUMERIC,
        section TEXT,
        source_page INTEGER,
        unit VARCHAR(50),
        fiscal_year VARCHAR(20),
        source_status VARCHAR(30),
        source_file TEXT
    );
    """,

    """
    CREATE TABLE IF NOT EXISTS staging.statement_2_import (
        ministry_code INTEGER NOT NULL,
        ministry_name TEXT NOT NULL,
        targeted_revenue NUMERIC,
        actual_revenue NUMERIC,
        total_budget NUMERIC,
        actual_expenditure NUMERIC,
        operating_expenditure NUMERIC,
        development_expenditure NUMERIC,
        source_page INTEGER,
        source_table INTEGER,
        targeted_revenue_original NUMERIC,
        actual_revenue_original NUMERIC,
        total_budget_original NUMERIC,
        actual_expenditure_original NUMERIC,
        operating_expenditure_original NUMERIC,
        development_expenditure_original NUMERIC,
        source_unit VARCHAR(50),
        standard_unit VARCHAR(50),
        financial_year VARCHAR(20),
        conversion_check NUMERIC,
        calculated_expenditure NUMERIC,
        expenditure_difference NUMERIC
    );
    """
]

try:
    with engine.begin() as conn:

        for ddl in ddl_statements:
            conn.execute(text(ddl))

    print("\nImport tables created or already exist.")

    with engine.connect() as conn:

        tables = conn.execute(
            text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'staging'
                  AND table_name IN (
                      'statement_1_import',
                      'statement_2_import'
                  )
                ORDER BY table_name;
            """)
        ).fetchall()

        print("\nVerified Import Tables:")

        for table in tables:
            print("-", table[0])

        if len(tables) != 2:
            raise RuntimeError(
                "Both import tables were not found."
            )

    print("\nStep 14.6.5 completed successfully.")

except Exception as error:
    print("\nTABLE CREATION FAILED")
    print(error)

finally:
    engine.dispose()
