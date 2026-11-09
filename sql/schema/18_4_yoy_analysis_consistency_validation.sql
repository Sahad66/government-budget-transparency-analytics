-- ============================================================
-- STEP 18.4: YOY ANALYSIS CONSISTENCY VALIDATION
-- ============================================================

-- 18.4.1 Ministry-level validation
SELECT
    COUNT(*) AS ministry_records,
    COUNT(DISTINCT ministry_id) AS distinct_ministries,
    COUNT(*) FILTER (
        WHERE yoy_status = 'INSUFFICIENT HISTORICAL DATA'
    ) AS insufficient_history,
    COUNT(*) FILTER (
        WHERE yoy_status = 'COMPARISON AVAILABLE'
    ) AS comparison_available,
    COUNT(*) FILTER (
        WHERE budget_growth_pct IS NOT NULL
    ) AS budget_growth_available,
    COUNT(*) FILTER (
        WHERE actual_expenditure_growth_pct IS NOT NULL
    ) AS actual_growth_available
FROM analytics.vw_ministry_yoy_analysis;


-- 18.4.2 Government-level validation
SELECT
    COUNT(*) AS government_records,
    COUNT(DISTINCT financial_year) AS distinct_fiscal_years,
    COUNT(*) FILTER (
        WHERE yoy_status = 'INSUFFICIENT HISTORICAL DATA'
    ) AS insufficient_history,
    COUNT(*) FILTER (
        WHERE yoy_status = 'COMPARISON AVAILABLE'
    ) AS comparison_available,
    COUNT(*) FILTER (
        WHERE actual_expenditure_growth_pct IS NOT NULL
    ) AS actual_growth_available
FROM analytics.vw_government_yoy_analysis;


-- 18.4.3 Combined YoY readiness summary
WITH ministry_check AS (
    SELECT
        COUNT(*) AS ministry_records,
        COUNT(*) FILTER (
            WHERE previous_fiscal_year IS NOT NULL
        ) AS ministry_previous_year_available,
        COUNT(*) FILTER (
            WHERE yoy_status = 'INSUFFICIENT HISTORICAL DATA'
        ) AS ministry_insufficient_history
    FROM analytics.vw_ministry_yoy_analysis
),
government_check AS (
    SELECT
        COUNT(*) AS government_records,
        COUNT(*) FILTER (
            WHERE previous_fiscal_year IS NOT NULL
        ) AS government_previous_year_available,
        COUNT(*) FILTER (
            WHERE yoy_status = 'INSUFFICIENT HISTORICAL DATA'
        ) AS government_insufficient_history
    FROM analytics.vw_government_yoy_analysis
)
SELECT
    m.ministry_records,
    m.ministry_previous_year_available,
    m.ministry_insufficient_history,
    g.government_records,
    g.government_previous_year_available,
    g.government_insufficient_history,
    CASE
        WHEN m.ministry_records = 62
         AND g.government_records >= 1
         AND m.ministry_previous_year_available = 0
         AND g.government_previous_year_available = 0
         AND m.ministry_insufficient_history = 62
         AND g.government_insufficient_history = g.government_records
        THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS combined_validation_status
FROM ministry_check m
CROSS JOIN government_check g;