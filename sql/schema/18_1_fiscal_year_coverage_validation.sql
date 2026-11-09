-- ============================================================
-- STEP 18.1: FISCAL YEAR COVERAGE VALIDATION
-- Project: Government Budget Transparency & Spending Efficiency
-- Purpose: Verify whether sufficient fiscal-year data exists
-- ============================================================

-- 18.1.1 Fiscal year dimension coverage
SELECT
    fiscal_year_id,
    financial_year,
    start_year,
    end_year
FROM analytics.dim_fiscal_year
ORDER BY start_year;


-- 18.1.2 Ministry fact table coverage by fiscal year
SELECT
    fy.financial_year,
    COUNT(DISTINCT f.ministry_id) AS ministry_count,
    ROUND(SUM(f.total_budget)::numeric, 4) AS total_budget,
    ROUND(SUM(f.actual_expenditure)::numeric, 4) AS actual_expenditure,
    ROUND(SUM(f.budget_variance)::numeric, 4) AS budget_variance,
    ROUND(
        SUM(f.actual_expenditure)
        / NULLIF(SUM(f.total_budget), 0) * 100,
        4
    ) AS utilization_pct
FROM analytics.fact_ministry_budget f
JOIN analytics.dim_fiscal_year fy
    ON f.fiscal_year_id = fy.fiscal_year_id
GROUP BY fy.financial_year, fy.start_year
ORDER BY fy.start_year;


-- 18.1.3 Government-level fact table coverage
SELECT
    fy.financial_year,
    COUNT(*) AS government_record_count,
    ROUND(SUM(g.original_budget)::numeric, 4) AS original_budget,
    ROUND(SUM(g.revised_budget)::numeric, 4) AS revised_budget,
    ROUND(SUM(g.actual_expenditure)::numeric, 4) AS actual_expenditure
FROM analytics.fact_government_budget_summary g
JOIN analytics.dim_fiscal_year fy
    ON g.fiscal_year_id = fy.fiscal_year_id
GROUP BY fy.financial_year, fy.start_year
ORDER BY fy.start_year;


-- 18.1.4 YoY availability validation
WITH year_coverage AS (
    SELECT
        COUNT(*) AS fiscal_year_count,
        COUNT(DISTINCT financial_year) AS distinct_year_labels
    FROM analytics.dim_fiscal_year
),
ministry_coverage AS (
    SELECT
        COUNT(DISTINCT fiscal_year_id) AS ministry_fact_year_count,
        COUNT(*) AS ministry_fact_records
    FROM analytics.fact_ministry_budget
),
government_coverage AS (
    SELECT
        COUNT(DISTINCT fiscal_year_id) AS government_fact_year_count,
        COUNT(*) AS government_fact_records
    FROM analytics.fact_government_budget_summary
)
SELECT
    y.fiscal_year_count,
    y.distinct_year_labels,
    m.ministry_fact_year_count,
    m.ministry_fact_records,
    g.government_fact_year_count,
    g.government_fact_records,
    CASE
        WHEN y.distinct_year_labels >= 2
         AND m.ministry_fact_year_count >= 2
        THEN 'YOY ANALYSIS POSSIBLE'
        ELSE 'NOT CALCULABLE - ONLY ONE FISCAL YEAR'
    END AS yoy_analysis_status
FROM year_coverage y
CROSS JOIN ministry_coverage m
CROSS JOIN government_coverage g;


-- 18.1.5 Final data coverage quality check
SELECT
    (SELECT COUNT(*)
     FROM analytics.dim_fiscal_year) AS fiscal_year_records,

    (SELECT COUNT(DISTINCT fiscal_year_id)
     FROM analytics.fact_ministry_budget) AS ministry_fact_years,

    (SELECT COUNT(*)
     FROM analytics.fact_ministry_budget) AS ministry_fact_records,

    (SELECT COUNT(*)
     FROM analytics.fact_government_budget_summary) AS government_fact_records,

    CASE
        WHEN (SELECT COUNT(*) FROM analytics.dim_fiscal_year) >= 1
         AND (SELECT COUNT(*) FROM analytics.fact_ministry_budget) > 0
         AND (SELECT COUNT(*) FROM analytics.fact_government_budget_summary) > 0
        THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS coverage_validation_status;