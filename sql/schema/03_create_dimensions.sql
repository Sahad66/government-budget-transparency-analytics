-- ============================================
-- FILE: 03_create_dimensions.sql
-- PURPOSE: Create Dimension Tables
-- ============================================


-- --------------------------------------------
-- TABLE 01: dim_fiscal_year
-- PURPOSE: Store Financial Year Information
-- --------------------------------------------

CREATE TABLE analytics.dim_fiscal_year (

    fiscal_year_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    financial_year VARCHAR(9) NOT NULL UNIQUE,

    start_year SMALLINT NOT NULL,

    end_year SMALLINT NOT NULL,

    CONSTRAINT chk_fiscal_year
        CHECK (end_year = start_year + 1)
);


-- Insert Financial Year Record

INSERT INTO analytics.dim_fiscal_year
(
    financial_year,
    start_year,
    end_year
)
VALUES
(
    '2024-2025',
    2024,
    2025
);


-- --------------------------------------------
-- TABLE 02: dim_ministry
-- PURPOSE: Store Ministry Codes and Names
-- --------------------------------------------

CREATE TABLE analytics.dim_ministry (

    ministry_id BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    ministry_code VARCHAR(50),

    ministry_name VARCHAR(300) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);