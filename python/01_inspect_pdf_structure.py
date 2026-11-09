
from pathlib import Path
import pdfplumber
import pandas as pd

# Project directories
PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "data" / "raw"

# NEW 1: Create processed directory for CSV output
PROCESSED_DIR = PROJECT_DIR / "data" / "processed"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


# PDF files
pdf_files = [
    RAW_DIR / "FY2024-25_Statement_1_Budget_and_Accounts.pdf",
    RAW_DIR / "FY2024-25_Statement_2_Ministry_Wise_Expenditure.pdf"
]

for pdf_file in pdf_files:

    print("\n" + "=" * 60)
    print("FILE:", pdf_file.name)
    print("=" * 60)

    # Check file existence
    if not pdf_file.exists():
        print("ERROR: File not found!")
        continue

    with pdfplumber.open(pdf_file) as pdf:

        print("Total Pages:", len(pdf.pages))

        total_tables = 0

        # NEW 2: Store all extracted tables from this PDF
        all_tables = []

        for page_number, page in enumerate(pdf.pages, start=1):

            print(f"\n--- PAGE {page_number} ---")

            # Extract text
            text = page.extract_text()

            if text:
                print("\nTEXT PREVIEW:")
                print(text[:1000])
            else:
                print("No readable text found.")

            # Extract tables
            tables = page.extract_tables()

            print("\nTables Found:", len(tables))

            for table_number, table in enumerate(tables, start=1):

                total_tables += 1

                if not table:
                    continue

                df = pd.DataFrame(table)

                # NEW 3: Add source page and table information
                # This helps identify where each table came from
                df["source_page"] = page_number
                df["source_table"] = table_number

                # NEW 4: Store extracted DataFrame
                all_tables.append(df)

                print(f"\nTABLE {table_number}")
                print("Rows:", len(df))
                print("Columns:", len(df.columns))

                print("\nTable Preview:")
                print(df.head(5).to_string(index=False))

        print("\nTOTAL TABLES:", total_tables)

        # NEW 5: Combine all extracted tables
        if all_tables:

            final_df = pd.concat(
                all_tables,
                ignore_index=True,
                sort=False
            )

            # NEW 6: Define output CSV filename
            if "Statement_1" in pdf_file.name:
                output_name = "statement_1_extracted.csv"

            elif "Statement_2" in pdf_file.name:
                output_name = "statement_2_extracted.csv"

            else:
                output_name = pdf_file.stem + "_extracted.csv"

            output_file = PROCESSED_DIR / output_name

            # NEW 7: Save extracted tables as CSV
            final_df.to_csv(
                output_file,
                index=False,
                encoding="utf-8-sig"
            )

            print("\nCSV SAVED SUCCESSFULLY!")
            print("Output:", output_file)
            print("Total Extracted Rows:", len(final_df))
            print("Total Extracted Columns:", len(final_df.columns))

        else:
            print("\nNo tables found to save.")
