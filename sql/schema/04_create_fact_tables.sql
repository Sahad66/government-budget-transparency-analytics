-- ============================================
-- FILE: 04_create_fact_tables.sql
-- PURPOSE: Create Fact Tables
-- ============================================


-- --------------------------------------------
-- TABLE 01: fact_government_budget_summary
-- PURPOSE: Store Government-Level Budget Figures
-- SOURCE: Statement 1
-- --------------------------------------------

CREATE TABLE analytics.fact_government_budget_summary (

    government_budget_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    fiscal_year_id BIGINT NOT NULL,

    source_document_id BIGINT NOT NULL,

    revised_budget NUMERIC(20, 4),

    actual_expenditure NUMERIC(20, 4),

    budget_balance NUMERIC(20, 4),

    actual_budget_percentage NUMERIC(12, 4),

    operating_expenditure NUMERIC(20, 4),

    development_expenditure NUMERIC(20, 4),

    standard_unit VARCHAR(30)
        NOT NULL DEFAULT 'BDT Crore',

    CONSTRAINT fk_government_fiscal_year
        FOREIGN KEY (fiscal_year_id)
        REFERENCES analytics.dim_fiscal_year(fiscal_year_id),

    CONSTRAINT fk_government_source
        FOREIGN KEY (source_document_id)
        REFERENCES analytics.source_documents(source_document_id)
);


-- --------------------------------------------
-- TABLE 02: fact_ministry_budget
-- PURPOSE: Store Ministry-Level Financial Figures
-- SOURCE: Statement 2
-- --------------------------------------------

CREATE TABLE analytics.fact_ministry_budget (

    ministry_budget_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    fiscal_year_id BIGINT NOT NULL,

    ministry_id BIGINT NOT NULL,

    source_document_id BIGINT NOT NULL,

    targeted_revenue NUMERIC(20, 4),

    actual_revenue NUMERIC(20, 4),

    total_budget NUMERIC(20, 4),

    actual_expenditure NUMERIC(20, 4),

    operating_expenditure NUMERIC(20, 4),

    development_expenditure NUMERIC(20, 4),

    budget_utilization_rate NUMERIC(12, 4),

    budget_variance NUMERIC(20, 4),

    standard_unit VARCHAR(30)
        NOT NULL DEFAULT 'BDT Crore',

    CONSTRAINT fk_ministry_fiscal_year
        FOREIGN KEY (fiscal_year_id)
        REFERENCES analytics.dim_fiscal_year(fiscal_year_id),

    CONSTRAINT fk_ministry_dimension
        FOREIGN KEY (ministry_id)
        REFERENCES analytics.dim_ministry(ministry_id),

    CONSTRAINT fk_ministry_source
        FOREIGN KEY (source_document_id)
        REFERENCES analytics.source_documents(source_document_id)
);