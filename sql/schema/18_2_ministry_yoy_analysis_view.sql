-- ============================================================
-- STEP 18.2: MINISTRY-WISE YOY ANALYSIS VIEW
-- Purpose: Create reusable year-over-year comparison framework
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_ministry_yoy_analysis AS

WITH base AS (
    SELECT
        f.ministry_id,
        fy.fiscal_year_id,
        fy.financial_year,
        fy.start_year,

        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,

        f.actual_expenditure
            / NULLIF(f.total_budget, 0) * 100
            AS utilization_pct

    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_fiscal_year fy
        ON f.fiscal_year_id = fy.fiscal_year_id
),

lagged AS (
    SELECT
        *,

        LAG(financial_year) OVER (
            PARTITION BY ministry_id
            ORDER BY start_year
        ) AS previous_fiscal_year,

        LAG(total_budget) OVER (
            PARTITION BY ministry_id
            ORDER BY start_year
        ) AS previous_budget,

        LAG(actual_expenditure) OVER (
            PARTITION BY ministry_id
            ORDER BY start_year
        ) AS previous_actual_expenditure,

        LAG(budget_variance) OVER (
            PARTITION BY ministry_id
            ORDER BY start_year
        ) AS previous_budget_variance,

        LAG(utilization_pct) OVER (
            PARTITION BY ministry_id
            ORDER BY start_year
        ) AS previous_utilization_pct

    FROM base
)

SELECT
    ministry_id,
    financial_year,
    previous_fiscal_year,

    ROUND(total_budget::numeric, 4) AS current_budget,
    ROUND(previous_budget::numeric, 4) AS previous_budget,

    ROUND(
        ((total_budget - previous_budget)
        / NULLIF(previous_budget, 0) * 100)::numeric,
        4
    ) AS budget_growth_pct,

    ROUND(actual_expenditure::numeric, 4)
        AS current_actual_expenditure,

    ROUND(previous_actual_expenditure::numeric, 4)
        AS previous_actual_expenditure,

    ROUND(
        ((actual_expenditure - previous_actual_expenditure)
        / NULLIF(previous_actual_expenditure, 0) * 100)::numeric,
        4
    ) AS actual_expenditure_growth_pct,

    ROUND(budget_variance::numeric, 4)
        AS current_budget_variance,

    ROUND(previous_budget_variance::numeric, 4)
        AS previous_budget_variance,

    ROUND(utilization_pct::numeric, 4)
        AS current_utilization_pct,

    ROUND(previous_utilization_pct::numeric, 4)
        AS previous_utilization_pct,

    ROUND(
        (utilization_pct - previous_utilization_pct)::numeric,
        4
    ) AS utilization_change_percentage_points,

    CASE
        WHEN previous_budget IS NOT NULL
         AND previous_actual_expenditure IS NOT NULL
        THEN 'COMPARISON AVAILABLE'
        ELSE 'INSUFFICIENT HISTORICAL DATA'
    END AS yoy_status

FROM lagged;


-- 18.2.1 View output sample
SELECT *
FROM analytics.vw_ministry_yoy_analysis
ORDER BY ministry_id
LIMIT 10;


-- 18.2.2 YoY readiness summary
SELECT
    COUNT(*) AS total_ministries,

    COUNT(previous_fiscal_year) AS ministries_with_previous_year,

    COUNT(budget_growth_pct) AS budget_growth_available,

    COUNT(actual_expenditure_growth_pct)
        AS actual_growth_available,

    COUNT(*) FILTER (
        WHERE yoy_status = 'INSUFFICIENT HISTORICAL DATA'
    ) AS insufficient_history_count,

    COUNT(*) FILTER (
        WHERE yoy_status = 'COMPARISON AVAILABLE'
    ) AS comparison_available_count

FROM analytics.vw_ministry_yoy_analysis;


-- 18.2.3 Data quality validation
SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT ministry_id) AS distinct_ministries,

    COUNT(*) FILTER (
        WHERE current_budget IS NULL
           OR current_actual_expenditure IS NULL
    ) AS missing_current_financial_values,

    COUNT(*) FILTER (
        WHERE yoy_status IS NULL
    ) AS missing_yoy_status,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT ministry_id) = 62
         AND COUNT(*) FILTER (
             WHERE current_budget IS NULL
                OR current_actual_expenditure IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE yoy_status IS NULL
         ) = 0
        THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS validation_status

FROM analytics.vw_ministry_yoy_analysis;