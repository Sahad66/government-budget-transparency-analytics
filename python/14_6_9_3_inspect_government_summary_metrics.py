from getpass import getpass

import pandas as pd
from sqlalchemy import create_engine, text, URL


# --------------------------------------------------
# DATABASE CONNECTION
# --------------------------------------------------

password = getpass("PostgreSQL password: ")

connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="government_budget_analytics"
)

engine = create_engine(connection_url)


# --------------------------------------------------
# LOAD SOURCE DATA
# --------------------------------------------------

query = text("""
    SELECT
        description,
        section,
        unit,
        budget_2024_25,
        revised_budget_2024_25,
        actual_2024_25,
        balance_budget,
        balance_revised,
        actual_budget_pct,
        actual_revised_pct,
        source_page
    FROM staging.statement_1_import
    ORDER BY source_page, description;
""")


try:

    with engine.connect() as conn:
        df = pd.read_sql(query, conn)

    print("\n" + "=" * 75)
    print("GOVERNMENT SUMMARY METRIC INSPECTION")
    print("=" * 75)

    print(f"\nTotal source records: {len(df)}")

    # --------------------------------------------------
    # 1. ALL SOURCE DESCRIPTIONS
    # --------------------------------------------------

    print("\nA. COMPLETE SOURCE DESCRIPTION LIST")
    print("-" * 75)

    for index, row in df.iterrows():
        print(
            f"{index + 1:02d}. "
            f"{row['description']} | "
            f"Section: {row['section']} | "
            f"Unit: {row['unit']}"
        )

    # --------------------------------------------------
    # 2. TARGET METRIC CANDIDATES
    # --------------------------------------------------

    keywords = [
        "total expenditure",
        "operating expenditure",
        "development expenditure"
    ]

    print("\nB. TARGET METRIC CANDIDATES")
    print("-" * 75)

    for keyword in keywords:

        matches = df[
            df["description"].str.contains(
                keyword,
                case=False,
                na=False,
                regex=False
            )
        ]

        print(f"\nKeyword: {keyword}")
        print(f"Matching rows: {len(matches)}")

        if matches.empty:
            print("No matching source record found.")
        else:
            print(
                matches.to_string(index=False)
            )

    # --------------------------------------------------
    # 3. UNIT VALIDATION
    # --------------------------------------------------

    print("\nC. BDT CRORE RECORDS")
    print("-" * 75)

    crore_data = df[
        df["unit"].str.strip().str.lower() == "bdt crore"
    ]

    print(f"BDT Crore records: {len(crore_data)}")
    print(f"Non-BDT Crore records: {len(df) - len(crore_data)}")

    # --------------------------------------------------
    # 4. SUMMARY
    # --------------------------------------------------

    print("\nD. INSPECTION SUMMARY")
    print("-" * 75)

    print("Source table: staging.statement_1_import")
    print(f"Total records: {len(df)}")
    print(f"BDT Crore records: {len(crore_data)}")

    print("\nInspection completed successfully.")

except Exception as error:

    print("\nINSPECTION FAILED")
    print(f"Reason: {error}")

finally:
    engine.dispose()