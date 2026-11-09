
import pdfplumber
import pandas as pd

from pathlib import Path
from datetime import datetime


# ==========================================================
# 1. PROJECT PATHS
# ==========================================================

PROJECT_DIR = Path(__file__).resolve().parent.parent

PDF_FILE = (
    PROJECT_DIR
    / "data"
    / "raw"
    / "FY2024-25_Statement_1_Budget_and_Accounts.pdf"
)

INSPECTION_DIR = (
    PROJECT_DIR
    / "data"
    / "inspection"
    / "statement_1"
)

TEXT_DIR = INSPECTION_DIR / "extracted_text"
LINES_DIR = INSPECTION_DIR / "tables_lines"
TEXT_TABLE_DIR = INSPECTION_DIR / "tables_text"
WORDS_DIR = INSPECTION_DIR / "word_coordinates"

REPORT_DIR = PROJECT_DIR / "reports"

REPORT_FILE = (
    REPORT_DIR / "statement_1_extraction_report.txt"
)

# Create folders
for folder in [
    TEXT_DIR,
    LINES_DIR,
    TEXT_TABLE_DIR,
    WORDS_DIR,
    REPORT_DIR
]:
    folder.mkdir(parents=True, exist_ok=True)


# ==========================================================
# 2. CHECK PDF
# ==========================================================

if not PDF_FILE.exists():
    raise FileNotFoundError(
        f"PDF not found: {PDF_FILE}"
    )


print("=" * 70)
print("STATEMENT 1 PDF RE-EXTRACTION")
print("=" * 70)

print("\nInput PDF:", PDF_FILE.name)


# ==========================================================
# 3. TABLE EXTRACTION SETTINGS
# ==========================================================

lines_settings = {
    "vertical_strategy": "lines",
    "horizontal_strategy": "lines",
    "snap_tolerance": 3,
    "join_tolerance": 3,
    "intersection_tolerance": 5
}

text_settings = {
    "vertical_strategy": "text",
    "horizontal_strategy": "text",
    "text_x_tolerance": 3,
    "text_y_tolerance": 3,
    "intersection_tolerance": 5
}


# ==========================================================
# 4. EXTRACTION COUNTERS
# ==========================================================

total_pages = 0
lines_table_count = 0
text_table_count = 0

report_lines = []

report_lines.append(
    "STATEMENT 1 PDF EXTRACTION REPORT"
)

report_lines.append("=" * 70)

report_lines.append(
    f"PDF File: {PDF_FILE.name}"
)

report_lines.append(
    f"Extraction Date: {datetime.now()}"
)


# ==========================================================
# 5. OPEN PDF
# ==========================================================

with pdfplumber.open(PDF_FILE) as pdf:

    total_pages = len(pdf.pages)

    print("\nTotal PDF pages:", total_pages)

    report_lines.append(
        f"Total PDF Pages: {total_pages}"
    )

    # ------------------------------------------------------
    # PROCESS EACH PAGE
    # ------------------------------------------------------

    for page_number, page in enumerate(
        pdf.pages,
        start=1
    ):

        print("\n" + "-" * 60)

        print(f"PROCESSING PAGE {page_number}")

        print("-" * 60)

        report_lines.append("")
        report_lines.append(
            f"PAGE {page_number}"
        )

        # ==================================================
        # 5A. EXTRACT ORIGINAL PAGE TEXT
        # ==================================================

        page_text = page.extract_text(
            layout=False
        )

        text_file = (
            TEXT_DIR
            / f"page_{page_number:02d}_text.txt"
        )

        text_file.write_text(
            page_text or "NO TEXT EXTRACTED",
            encoding="utf-8"
        )

        print("Page text saved:", text_file.name)

        report_lines.append(
            f"Text extraction: {len(page_text or '')} characters"
        )

        # ==================================================
        # 5B. EXTRACT WORD COORDINATES
        # ==================================================

        words = page.extract_words(
            x_tolerance=3,
            y_tolerance=3,
            keep_blank_chars=False
        )

        if words:

            words_df = pd.DataFrame(words)

            words_file = (
                WORDS_DIR
                / f"page_{page_number:02d}_words.csv"
            )

            words_df.to_csv(
                words_file,
                index=False
            )

            print(
                "Word coordinates saved:",
                words_file.name
            )

        # ==================================================
        # 5C. LINES-BASED TABLE EXTRACTION
        # ==================================================

        try:

            line_tables = page.extract_tables(
                table_settings=lines_settings
            )

        except Exception as error:

            print(
                "Lines extraction error:",
                error
            )

            line_tables = []

        print(
            "\nLines-based tables:",
            len(line_tables)
        )

        report_lines.append(
            f"Lines-based tables: {len(line_tables)}"
        )

        for table_number, table in enumerate(
            line_tables,
            start=1
        ):

            if not table:
                continue

            table_df = pd.DataFrame(table)

            output_file = (
                LINES_DIR
                / (
                    f"page_{page_number:02d}_"
                    f"table_{table_number:02d}.csv"
                )
            )

            table_df.to_csv(
                output_file,
                index=False,
                header=False,
                encoding="utf-8-sig"
            )

            lines_table_count += 1

            print(
                "Saved:",
                output_file.name,
                "| Shape:",
                table_df.shape
            )

        # ==================================================
        # 5D. TEXT-BASED TABLE EXTRACTION
        # ==================================================

        try:

            text_tables = page.extract_tables(
                table_settings=text_settings
            )

        except Exception as error:

            print(
                "Text extraction error:",
                error
            )

            text_tables = []

        print(
            "\nText-based tables:",
            len(text_tables)
        )

        report_lines.append(
            f"Text-based tables: {len(text_tables)}"
        )

        for table_number, table in enumerate(
            text_tables,
            start=1
        ):

            if not table:
                continue

            table_df = pd.DataFrame(table)

            output_file = (
                TEXT_TABLE_DIR
                / (
                    f"page_{page_number:02d}_"
                    f"table_{table_number:02d}.csv"
                )
            )

            table_df.to_csv(
                output_file,
                index=False,
                header=False,
                encoding="utf-8-sig"
            )

            text_table_count += 1

            print(
                "Saved:",
                output_file.name,
                "| Shape:",
                table_df.shape
            )


# ==========================================================
# 6. SAVE EXTRACTION REPORT
# ==========================================================

report_lines.extend([
    "",
    "=" * 70,
    "EXTRACTION SUMMARY",
    "=" * 70,
    f"Total pages: {total_pages}",
    f"Lines-based tables: {lines_table_count}",
    f"Text-based tables: {text_table_count}",
    "",
    "Output folders:",
    str(TEXT_DIR),
    str(LINES_DIR),
    str(TEXT_TABLE_DIR),
    str(WORDS_DIR),
    "",
    "IMPORTANT:",
    "This is an extraction inspection stage.",
    "No financial values were manually changed.",
    "No final cleaned dataset was generated.",
    "Original PDF remains unchanged."
])

REPORT_FILE.write_text(
    "\n".join(report_lines),
    encoding="utf-8"
)


# ==========================================================
# 7. FINAL OUTPUT
# ==========================================================

print("\n" + "=" * 70)

print("PDF EXTRACTION COMPLETED")

print("=" * 70)

print("Total pages:", total_pages)

print("Lines-based tables:", lines_table_count)

print("Text-based tables:", text_table_count)

print("\nExtracted files saved successfully.")

print("\nReport:", REPORT_FILE)

print("\nNext task: Review extracted tables against original PDF.")
