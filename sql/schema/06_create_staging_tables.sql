-- ============================================================
-- Step 14: Create Staging Tables
-- Purpose: Store imported source CSV records
-- Schema: staging
-- ============================================================


-- ------------------------------------------------------------
-- 1. Statement 1: Government Budget Summary
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.statement_1_raw (

    record_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    source_document_id INTEGER,

    financial_year VARCHAR(20),

    revised_budget NUMERIC(20,4),

    actual_expenditure NUMERIC(20,4),

    budget_balance NUMERIC(20,4),

    actual_budget_percentage NUMERIC(12,4),

    operating_expenditure NUMERIC(20,4),

    development_expenditure NUMERIC(20,4)

);


-- ------------------------------------------------------------
-- 2. Statement 2: Ministry-wise Expenditure
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.statement_2_raw (

    record_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    source_document_id INTEGER,

    financial_year VARCHAR(20),

    ministry_code VARCHAR(50),

    ministry_name VARCHAR(300),

    targeted_revenue NUMERIC(20,4),

    actual_revenue NUMERIC(20,4),

    total_budget NUMERIC(20,4),

    actual_expenditure NUMERIC(20,4),

    operating_expenditure NUMERIC(20,4),

    development_expenditure NUMERIC(20,4)

);



SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE ministry_name IS NULL
    ) AS missing_ministry_names,
    COUNT(*) FILTER (
        WHERE total_budget IS NULL
    ) AS missing_budgets,
    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
    ) AS missing_expenditure
FROM staging.statement_2_raw;