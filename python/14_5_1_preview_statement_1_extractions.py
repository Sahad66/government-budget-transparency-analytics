
import pandas as pd
from pathlib import Path

# ============================================
# 1. PROJECT PATHS
# ============================================

PROJECT_DIR = Path(__file__).resolve().parent.parent

BASE_DIR = (
    PROJECT_DIR
    / "data"
    / "inspection"
    / "statement_1"
)

TEXT_DIR = BASE_DIR / "extracted_text"
LINES_DIR = BASE_DIR / "tables_lines"
TABLES_DIR = BASE_DIR / "tables_text"

REPORT_DIR = PROJECT_DIR / "reports"

OUTPUT_FILE = (
    REPORT_DIR
    / "statement_1_extraction_preview.txt"
)

REPORT_DIR.mkdir(parents=True, exist_ok=True)

report = []


def add_section(title, content):

    report.append("\n" + "=" * 80)
    report.append(title)
    report.append("=" * 80)
    report.append(str(content))


# ============================================
# 2. READ ORIGINAL PAGE TEXT
# ============================================

for page_number in [1, 2]:

    file_path = (
        TEXT_DIR
        / f"page_{page_number:02d}_text.txt"
    )

    if file_path.exists():

        content = file_path.read_text(
            encoding="utf-8"
        )

        add_section(
            f"PAGE {page_number} ORIGINAL TEXT",
            content
        )


# ============================================
# 3. READ LINES-BASED TABLES
# ============================================

for page_number in [1, 2]:

    file_path = (
        LINES_DIR
        / f"page_{page_number:02d}_table_01.csv"
    )

    if file_path.exists():

        df = pd.read_csv(
            file_path,
            header=None
        )

        add_section(
            f"PAGE {page_number} LINES-BASED TABLE",
            df.to_string(index=False, header=False)
        )


# ============================================
# 4. READ TEXT-BASED TABLES
# ============================================

for page_number in [1, 2]:

    file_path = (
        TABLES_DIR
        / f"page_{page_number:02d}_table_01.csv"
    )

    if file_path.exists():

        df = pd.read_csv(
            file_path,
            header=None
        )

        add_section(
            f"PAGE {page_number} TEXT-BASED TABLE",
            df.to_string(index=False, header=False)
        )


# ============================================
# 5. SAVE PREVIEW REPORT
# ============================================

OUTPUT_FILE.write_text(
    "\n".join(report),
    encoding="utf-8"
)

print("=" * 65)
print("STATEMENT 1 EXTRACTION PREVIEW")
print("=" * 65)

print("Preview sections:", len(report) // 4)

print("\nOutput saved:")
print(OUTPUT_FILE)

print("\nPreview generation completed.")
