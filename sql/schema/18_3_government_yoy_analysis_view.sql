-- ============================================================
-- STEP 18.3: GOVERNMENT-LEVEL YOY ANALYSIS VIEW
-- Project: Government Budget Transparency & Spending Efficiency
-- Purpose: Government-level fiscal year comparison
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_government_yoy_analysis AS

WITH base AS (
    SELECT
        g.fiscal_year_id,
        fy.financial_year,
        fy.start_year,

        g.original_budget,
        g.revised_budget,
        g.actual_expenditure,
        g.operating_expenditure,
        g.development_expenditure

    FROM analytics.fact_government_budget_summary g
    JOIN analytics.dim_fiscal_year fy
        ON g.fiscal_year_id = fy.fiscal_year_id
),

lagged AS (
    SELECT
        *,

        LAG(financial_year) OVER (
            ORDER BY start_year
        ) AS previous_fiscal_year,

        LAG(original_budget) OVER (
            ORDER BY start_year
        ) AS previous_original_budget,

        LAG(revised_budget) OVER (
            ORDER BY start_year
        ) AS previous_revised_budget,

        LAG(actual_expenditure) OVER (
            ORDER BY start_year
        ) AS previous_actual_expenditure,

        LAG(operating_expenditure) OVER (
            ORDER BY start_year
        ) AS previous_operating_expenditure,

        LAG(development_expenditure) OVER (
            ORDER BY start_year
        ) AS previous_development_expenditure

    FROM base
)

SELECT
    financial_year,
    previous_fiscal_year,

    ROUND(original_budget::numeric, 4)
        AS current_original_budget,

    ROUND(previous_original_budget::numeric, 4)
        AS previous_original_budget,

    ROUND(
        ((original_budget - previous_original_budget)
        / NULLIF(previous_original_budget, 0) * 100)::numeric,
        4
    ) AS original_budget_growth_pct,

    ROUND(revised_budget::numeric, 4)
        AS current_revised_budget,

    ROUND(previous_revised_budget::numeric, 4)
        AS previous_revised_budget,

    ROUND(
        ((revised_budget - previous_revised_budget)
        / NULLIF(previous_revised_budget, 0) * 100)::numeric,
        4
    ) AS revised_budget_growth_pct,

    ROUND(actual_expenditure::numeric, 4)
        AS current_actual_expenditure,

    ROUND(previous_actual_expenditure::numeric, 4)
        AS previous_actual_expenditure,

    ROUND(
        ((actual_expenditure - previous_actual_expenditure)
        / NULLIF(previous_actual_expenditure, 0) * 100)::numeric,
        4
    ) AS actual_expenditure_growth_pct,

    ROUND(operating_expenditure::numeric, 4)
        AS current_operating_expenditure,

    ROUND(previous_operating_expenditure::numeric, 4)
        AS previous_operating_expenditure,

    ROUND(
        ((operating_expenditure - previous_operating_expenditure)
        / NULLIF(previous_operating_expenditure, 0) * 100)::numeric,
        4
    ) AS operating_expenditure_growth_pct,

    ROUND(development_expenditure::numeric, 4)
        AS current_development_expenditure,

    ROUND(previous_development_expenditure::numeric, 4)
        AS previous_development_expenditure,

    ROUND(
        ((development_expenditure - previous_development_expenditure)
        / NULLIF(previous_development_expenditure, 0) * 100)::numeric,
        4
    ) AS development_expenditure_growth_pct,

    CASE
        WHEN previous_original_budget IS NOT NULL
         AND previous_actual_expenditure IS NOT NULL
        THEN 'COMPARISON AVAILABLE'
        ELSE 'INSUFFICIENT HISTORICAL DATA'
    END AS yoy_status

FROM lagged;


-- 18.3.1 Government-level YoY view output
SELECT *
FROM analytics.vw_government_yoy_analysis
ORDER BY financial_year;


-- 18.3.2 Government YoY readiness summary
SELECT
    COUNT(*) AS total_fiscal_year_records,

    COUNT(previous_fiscal_year)
        AS records_with_previous_year,

    COUNT(original_budget_growth_pct)
        AS original_budget_growth_available,

    COUNT(revised_budget_growth_pct)
        AS revised_budget_growth_available,

    COUNT(actual_expenditure_growth_pct)
        AS actual_growth_available,

    COUNT(operating_expenditure_growth_pct)
        AS operating_growth_available,

    COUNT(development_expenditure_growth_pct)
        AS development_growth_available,

    COUNT(*) FILTER (
        WHERE yoy_status = 'INSUFFICIENT HISTORICAL DATA'
    ) AS insufficient_history_count

FROM analytics.vw_government_yoy_analysis;


-- 18.3.3 Government YoY data quality validation
SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT financial_year) AS distinct_fiscal_years,

    COUNT(*) FILTER (
        WHERE current_original_budget IS NULL
           OR current_revised_budget IS NULL
           OR current_actual_expenditure IS NULL
           OR current_operating_expenditure IS NULL
           OR current_development_expenditure IS NULL
    ) AS missing_current_financial_values,

    COUNT(*) FILTER (
        WHERE yoy_status IS NULL
    ) AS missing_yoy_status,

    CASE
        WHEN COUNT(*) = (
            SELECT COUNT(*)
            FROM analytics.fact_government_budget_summary
        )
        AND COUNT(*) FILTER (
            WHERE current_original_budget IS NULL
               OR current_revised_budget IS NULL
               OR current_actual_expenditure IS NULL
               OR current_operating_expenditure IS NULL
               OR current_development_expenditure IS NULL
        ) = 0
        AND COUNT(*) FILTER (
            WHERE yoy_status IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS validation_status

FROM analytics.vw_government_yoy_analysis;