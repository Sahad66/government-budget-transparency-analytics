-- ============================================
-- FILE: 02_create_source_documents.sql
-- PURPOSE: Create Source Documents Table
-- ============================================

-- Table: analytics.source_documents
-- Purpose: Store source document metadata,
-- original units, document status and financial year.

CREATE TABLE analytics.source_documents (

    source_document_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    document_name VARCHAR(255) NOT NULL,

    report_title VARCHAR(300) NOT NULL,

    source_url TEXT,

    original_unit VARCHAR(100) NOT NULL,

    document_status VARCHAR(30) NOT NULL,

    financial_year VARCHAR(9) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_document_status
        CHECK (
            document_status IN (
                'Draft',
                'Final',
                'Unknown'
            )
        )
);

-- Insert Source Document Records

INSERT INTO analytics.source_documents
(
    document_name,
    report_title,
    source_url,
    original_unit,
    document_status,
    financial_year
)
VALUES

(
    'FY2024-25_Statement_1_Budget_and_Accounts.pdf',
    'Budget and Accounts at a Glance',
    'Official source URL for Statement 1',
    'BDT Crore',
    'Draft',
    '2024-2025'
),

(
    'FY2024-25_Statement_2_Ministry_Wise_Expenditure.pdf',
    'Ministry/Division Wise Expenditure',
    'Official source URL for Statement 2',
    'BDT Thousand',
    'Draft',
    '2024-2025'
);