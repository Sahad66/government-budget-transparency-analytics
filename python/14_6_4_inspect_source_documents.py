
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

try:
    with engine.connect() as conn:

        print("=" * 70)
        print("SOURCE DOCUMENTS")
        print("=" * 70)

        documents = conn.execute(
            text("""
                SELECT
                    source_document_id,
                    document_name,
                    report_title,
                    source_url,
                    original_unit,
                    document_status,
                    financial_year
                FROM analytics.source_documents
                ORDER BY source_document_id;
            """)
        ).fetchall()

        for doc in documents:
            print("\nSource Document ID:", doc.source_document_id)
            print("Document Name:", doc.document_name)
            print("Report Title:", doc.report_title)
            print("Source URL:", doc.source_url)
            print("Original Unit:", doc.original_unit)
            print("Status:", doc.document_status)
            print("Financial Year:", doc.financial_year)

        print("\n" + "=" * 70)
        print("FISCAL YEAR DIMENSION")
        print("=" * 70)

        years = conn.execute(
            text("""
                SELECT *
                FROM analytics.dim_fiscal_year
                ORDER BY fiscal_year_id;
            """)
        ).fetchall()

        for year in years:
            print(year)

    print("\nSource document inspection completed.")

except Exception as error:
    print("\nINSPECTION FAILED")
    print(error)

finally:
    engine.dispose()
