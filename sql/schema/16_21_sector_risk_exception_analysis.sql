-- ============================================================
-- STEP 16.21: SECTOR-WISE RISK & EXCEPTION ANALYSIS
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- Read-only analytical queries
-- ============================================================


-- 16.21.1 LOW UTILIZATION REVIEW

SELECT
    sector_name,
    ministry_count,
    ROUND(
        (actual_expenditure / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS utilization_pct,

    CASE
        WHEN total_budget <= 0 THEN 'INVALID BUDGET'
        WHEN actual_expenditure / NULLIF(total_budget, 0) < 0.60
            THEN 'LOW UTILIZATION - REVIEW'
        ELSE 'NO LOW UTILIZATION FLAG'
    END AS exception_status

FROM analytics.vw_sector_financial_summary

ORDER BY utilization_pct;


-- 16.21.2 HIGH SPENDING GAP REVIEW

SELECT
    sector_name,
    total_budget,
    actual_expenditure,

    ROUND(
        ((total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS spending_gap_pct,

    ROUND(
        (total_budget - actual_expenditure)::numeric,
        4
    ) AS unspent_budget,

    CASE
        WHEN total_budget <= 0 THEN 'INVALID BUDGET'
        WHEN actual_expenditure > total_budget
            THEN 'OVERSPENDING'
        WHEN (total_budget - actual_expenditure)
             / NULLIF(total_budget, 0) > 0.30
            THEN 'HIGH GAP - REVIEW'
        ELSE 'NO HIGH GAP FLAG'
    END AS exception_status

FROM analytics.vw_sector_financial_summary

ORDER BY spending_gap_pct DESC;


-- 16.21.3 OVERSPENDING EXCEPTION REVIEW

SELECT
    sector_name,
    total_budget,
    actual_expenditure,

    ROUND(
        (actual_expenditure - total_budget)::numeric,
        4
    ) AS overspending_amount,

    ROUND(
        ((actual_expenditure - total_budget)
        / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS overspending_pct,

    CASE
        WHEN actual_expenditure > total_budget
            THEN 'OVERSPENDING - INVESTIGATION REQUIRED'
        ELSE 'NO OVERSPENDING'
    END AS exception_status

FROM analytics.vw_sector_financial_summary

ORDER BY overspending_amount DESC;


-- 16.21.4 OPERATING + DEVELOPMENT COMPONENT MISMATCH

SELECT
    sector_name,

    ROUND(operating_expenditure::numeric, 4)
        AS operating_expenditure,

    ROUND(development_expenditure::numeric, 4)
        AS development_expenditure,

    ROUND(
        (operating_expenditure + development_expenditure)::numeric,
        4
    ) AS combined_components,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (actual_expenditure
        - operating_expenditure
        - development_expenditure)::numeric,
        4
    ) AS component_difference,

    CASE
        WHEN ABS(
            actual_expenditure
            - operating_expenditure
            - development_expenditure
        ) > 0.001
            THEN 'MISMATCH - REVIEW'
        ELSE 'WITHIN TOLERANCE'
    END AS component_status

FROM analytics.vw_sector_financial_summary

ORDER BY ABS(
    actual_expenditure
    - operating_expenditure
    - development_expenditure
) DESC;


-- 16.21.5 COMBINED SECTOR RISK SCREENING

WITH sector_metrics AS (
    SELECT
        sector_name,
        ministry_count,
        total_budget,
        actual_expenditure,
        operating_expenditure,
        development_expenditure,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100 AS utilization_pct,

        (total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100 AS spending_gap_pct,

        ABS(
            actual_expenditure
            - operating_expenditure
            - development_expenditure
        ) AS component_difference

    FROM analytics.vw_sector_financial_summary
),

risk_flags AS (
    SELECT
        *,

        (utilization_pct < 60) AS low_utilization_flag,

        (spending_gap_pct > 30) AS high_gap_flag,

        (actual_expenditure > total_budget)
            AS overspending_flag,

        (component_difference > 0.001)
            AS component_mismatch_flag

    FROM sector_metrics
)

SELECT
    sector_name,

    ROUND(utilization_pct::numeric, 4)
        AS utilization_pct,

    ROUND(spending_gap_pct::numeric, 4)
        AS spending_gap_pct,

    ROUND(component_difference::numeric, 4)
        AS component_difference,

    low_utilization_flag,
    high_gap_flag,
    overspending_flag,
    component_mismatch_flag,

    (
        low_utilization_flag::integer
        + high_gap_flag::integer
        + overspending_flag::integer
        + component_mismatch_flag::integer
    ) AS exception_flag_count,

    CASE
        WHEN overspending_flag
          OR component_mismatch_flag
            THEN 'PRIORITY REVIEW'

        WHEN low_utilization_flag AND high_gap_flag
            THEN 'HIGH REVIEW PRIORITY'

        WHEN low_utilization_flag OR high_gap_flag
            THEN 'MODERATE REVIEW PRIORITY'

        ELSE 'NO FLAG UNDER CURRENT RULES'
    END AS analytical_review_category

FROM risk_flags

ORDER BY exception_flag_count DESC, utilization_pct;


-- 16.21.6 RISK & EXCEPTION SUMMARY

WITH sector_metrics AS (
    SELECT
        sector_name,
        total_budget,
        actual_expenditure,
        operating_expenditure,
        development_expenditure,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100 AS utilization_pct,

        (total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100 AS spending_gap_pct,

        ABS(
            actual_expenditure
            - operating_expenditure
            - development_expenditure
        ) AS component_difference

    FROM analytics.vw_sector_financial_summary
)

SELECT
    COUNT(*) AS total_sectors,

    COUNT(*) FILTER (
        WHERE utilization_pct < 60
    ) AS low_utilization_sectors,

    COUNT(*) FILTER (
        WHERE spending_gap_pct > 30
    ) AS high_gap_sectors,

    COUNT(*) FILTER (
        WHERE actual_expenditure > total_budget
    ) AS overspending_sectors,

    COUNT(*) FILTER (
        WHERE component_difference > 0.001
    ) AS component_mismatch_sectors,

    COUNT(*) FILTER (
        WHERE utilization_pct < 60
           OR spending_gap_pct > 30
           OR actual_expenditure > total_budget
           OR component_difference > 0.001
    ) AS sectors_with_any_exception

FROM sector_metrics;


-- 16.21.7 FINAL DATA QUALITY VALIDATION

SELECT
    COUNT(*) AS sector_count,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
           OR actual_expenditure IS NULL
           OR operating_expenditure IS NULL
           OR development_expenditure IS NULL
    ) AS missing_metric_count,

    COUNT(*) FILTER (
        WHERE total_budget <= 0
    ) AS invalid_budget_count,

    COUNT(*) FILTER (
        WHERE actual_expenditure < 0
           OR operating_expenditure < 0
           OR development_expenditure < 0
    ) AS negative_value_count,

    CASE
        WHEN COUNT(*) = 5
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR operating_expenditure IS NULL
                OR development_expenditure IS NULL
                OR total_budget <= 0
                OR actual_expenditure < 0
                OR operating_expenditure < 0
                OR development_expenditure < 0
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS risk_analysis_data_quality

FROM analytics.vw_sector_financial_summary;
