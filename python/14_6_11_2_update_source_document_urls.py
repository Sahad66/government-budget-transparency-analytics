
from sqlalchemy import create_engine, text
from getpass import getpass
from urllib.parse import quote_plus


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
# OFFICIAL SOURCE URLS
# ============================================================

source_urls = {
    1: (
        "https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/"
        "n/axvjbnqprylg/b/V2Ministry/o/office-mof/2024/12/"
        "1ab818d125f4490b9df56731aa0d432b.pdf"
    ),

    2: (
        "https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/"
        "n/axvjbnqprylg/b/V2Ministry/o/office-mof/2026/5/"
        "2740ed25-4207-4d57-a9e0-d7b7652066fe.pdf"
    ),
}


try:
    with engine.begin() as conn:

        print("\n" + "=" * 75)
        print("SOURCE DOCUMENT URL UPDATE")
        print("=" * 75)

        # ----------------------------------------------------
        # A. INSPECT TARGET RECORDS
        # ----------------------------------------------------

        print("\nA. TARGET RECORD INSPECTION")
        print("-" * 75)

        before = conn.execute(text("""
            SELECT
                source_document_id,
                source_url
            FROM analytics.source_documents
            WHERE source_document_id IN (1, 2, 3, 4)
            ORDER BY source_document_id
        """)).mappings().all()

        if len(before) != 4:
            raise ValueError(
                f"Expected 4 source records, found {len(before)}"
            )

        before_dict = {
            row["source_document_id"]: row["source_url"]
            for row in before
        }

        for document_id in (1, 2):
            if document_id not in before_dict:
                raise ValueError(
                    f"Source document {document_id} not found"
                )

        print("PASS: Source documents 1, 2, 3 and 4 exist")

        # ----------------------------------------------------
        # B. UPDATE ONLY ID 1 AND ID 2
        # ----------------------------------------------------

        print("\nB. UPDATING OFFICIAL SOURCE URLS")
        print("-" * 75)

        for document_id, source_url in source_urls.items():

            result = conn.execute(
                text("""
                    UPDATE analytics.source_documents
                    SET source_url = :source_url
                    WHERE source_document_id = :document_id
                """),
                {
                    "source_url": source_url,
                    "document_id": document_id,
                }
            )

            if result.rowcount != 1:
                raise ValueError(
                    f"Expected one updated row for ID {document_id}; "
                    f"updated: {result.rowcount}"
                )

            print(
                f"PASS: Official URL updated for document ID "
                f"{document_id}"
            )

        # ----------------------------------------------------
        # C. VERIFY UPDATED URLS
        # ----------------------------------------------------

        print("\nC. URL VERIFICATION")
        print("-" * 75)

        after = conn.execute(text("""
            SELECT
                source_document_id,
                source_url
            FROM analytics.source_documents
            WHERE source_document_id IN (1, 2, 3, 4)
            ORDER BY source_document_id
        """)).mappings().all()

        after_dict = {
            row["source_document_id"]: row["source_url"]
            for row in after
        }

        for document_id, expected_url in source_urls.items():

            actual_url = after_dict.get(document_id)

            if actual_url != expected_url:
                raise ValueError(
                    f"URL verification failed for ID {document_id}"
                )

            print(
                f"PASS: Document ID {document_id} URL verified"
            )

        # ----------------------------------------------------
        # D. PROTECT DUPLICATE METADATA RECORDS
        # ----------------------------------------------------

        print("\nD. UNTOUCHED RECORD VALIDATION")
        print("-" * 75)

        duplicates_unchanged = all(
            after_dict.get(document_id) == before_dict[document_id]
            for document_id in (3, 4)
        )

        if not duplicates_unchanged:
            raise ValueError(
                "Source document ID 3 or 4 was unexpectedly modified"
            )

        print("PASS: Document ID 3 remains unchanged")
        print("PASS: Document ID 4 remains unchanged")

        # ----------------------------------------------------
        # E. FINAL RESULT
        # ----------------------------------------------------

        print("\n" + "=" * 75)
        print("SOURCE URL UPDATE RESULT")
        print("=" * 75)

        print("PASS: Exactly two source URLs updated")
        print("PASS: Both official URLs verified")
        print("PASS: Duplicate metadata records untouched")
        print("\nSTEP 14.6.11.2 COMPLETED SUCCESSFULLY")

    print("\nDATABASE TRANSACTION COMMITTED SUCCESSFULLY.")


except Exception as error:
    print("\nSOURCE URL UPDATE FAILED")
    print(f"Error: {error}")
    raise

finally:
    engine.dispose()
