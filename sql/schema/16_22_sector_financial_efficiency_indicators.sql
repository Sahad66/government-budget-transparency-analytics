-- ============================================================
-- STEP 16.22: SECTOR-WISE FINANCIAL INDICATORS
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- Read-only analytical queries
-- ============================================================


-- 16.22.1 CONSOLIDATED FINANCIAL INDICATORS

WITH sector_metrics AS (
    SELECT
        sector_name,
        ministry_count,
        total_budget,
        actual_expenditure,
        operating_expenditure,
        development_expenditure,

        total_budget - actual_expenditure AS unspent_budget

    FROM analytics.vw_sector_financial_summary
)

SELECT
    sector_name,
    ministry_count,

    ROUND(total_budget::numeric, 4)
        AS total_budget,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(unspent_budget::numeric, 4)
        AS unspent_budget,

    ROUND(
        (actual_expenditure / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS budget_execution_ratio_pct,

    ROUND(
        (unspent_budget / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS unspent_budget_ratio_pct,

    ROUND(
        (operating_expenditure
        / NULLIF(actual_expenditure, 0) * 100)::numeric,
        4
    ) AS operating_expenditure_ratio_pct,

    ROUND(
        (development_expenditure
        / NULLIF(actual_expenditure, 0) * 100)::numeric,
        4
    ) AS development_expenditure_ratio_pct

FROM sector_metrics

ORDER BY budget_execution_ratio_pct DESC;


-- 16.22.2 ACTUAL EXPENDITURE CONTRIBUTION

SELECT
    sector_name,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (actual_expenditure
        / NULLIF(SUM(actual_expenditure) OVER (), 0) * 100)::numeric,
        4
    ) AS actual_expenditure_contribution_pct

FROM analytics.vw_sector_financial_summary

ORDER BY actual_expenditure_contribution_pct DESC;


-- 16.22.3 BUDGET CONTRIBUTION

SELECT
    sector_name,

    ROUND(total_budget::numeric, 4)
        AS total_budget,

    ROUND(
        (total_budget
        / NULLIF(SUM(total_budget) OVER (), 0) * 100)::numeric,
        4
    ) AS budget_contribution_pct

FROM analytics.vw_sector_financial_summary

ORDER BY budget_contribution_pct DESC;


-- 16.22.4 OPERATING EXPENDITURE CONTRIBUTION

SELECT
    sector_name,

    ROUND(operating_expenditure::numeric, 4)
        AS operating_expenditure,

    ROUND(
        (operating_expenditure
        / NULLIF(SUM(operating_expenditure) OVER (), 0) * 100)::numeric,
        4
    ) AS operating_expenditure_contribution_pct

FROM analytics.vw_sector_financial_summary

ORDER BY operating_expenditure_contribution_pct DESC;


-- 16.22.5 DEVELOPMENT EXPENDITURE CONTRIBUTION

SELECT
    sector_name,

    ROUND(development_expenditure::numeric, 4)
        AS development_expenditure,

    ROUND(
        (development_expenditure
        / NULLIF(SUM(development_expenditure) OVER (), 0) * 100)::numeric,
        4
    ) AS development_expenditure_contribution_pct

FROM analytics.vw_sector_financial_summary

ORDER BY development_expenditure_contribution_pct DESC;


-- 16.22.6 FINANCIAL INDICATOR RANKING

WITH sector_metrics AS (
    SELECT
        sector_name,
        total_budget,
        actual_expenditure,
        operating_expenditure,
        development_expenditure,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100 AS execution_ratio,

        (total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100 AS unspent_ratio

    FROM analytics.vw_sector_financial_summary
)

SELECT
    sector_name,

    ROUND(execution_ratio::numeric, 4)
        AS execution_ratio_pct,

    RANK() OVER (
        ORDER BY execution_ratio DESC
    ) AS execution_rank,

    ROUND(unspent_ratio::numeric, 4)
        AS unspent_ratio_pct,

    RANK() OVER (
        ORDER BY unspent_ratio ASC
    ) AS lowest_unspent_ratio_rank,

    RANK() OVER (
        ORDER BY actual_expenditure DESC
    ) AS actual_expenditure_rank,

    RANK() OVER (
        ORDER BY operating_expenditure DESC
    ) AS operating_expenditure_rank,

    RANK() OVER (
        ORDER BY development_expenditure DESC
    ) AS development_expenditure_rank

FROM sector_metrics

ORDER BY execution_rank;


-- 16.22.7 MAPPED SECTOR TOTAL INDICATORS

SELECT
    COUNT(*) AS sector_count,

    SUM(ministry_count) AS mapped_ministry_count,

    ROUND(SUM(total_budget)::numeric, 4)
        AS mapped_total_budget,

    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS mapped_actual_expenditure,

    ROUND(
        (SUM(total_budget) - SUM(actual_expenditure))::numeric,
        4
    ) AS mapped_unspent_budget,

    ROUND(
        (SUM(actual_expenditure)
        / NULLIF(SUM(total_budget), 0) * 100)::numeric,
        4
    ) AS overall_execution_ratio_pct,

    ROUND(SUM(operating_expenditure)::numeric, 4)
        AS total_operating_expenditure,

    ROUND(SUM(development_expenditure)::numeric, 4)
        AS total_development_expenditure,

    ROUND(
        (SUM(operating_expenditure)
        / NULLIF(SUM(actual_expenditure), 0) * 100)::numeric,
        4
    ) AS overall_operating_ratio_pct,

    ROUND(
        (SUM(development_expenditure)
        / NULLIF(SUM(actual_expenditure), 0) * 100)::numeric,
        4
    ) AS overall_development_ratio_pct

FROM analytics.vw_sector_financial_summary;


-- 16.22.8 FINAL INDICATOR DATA QUALITY

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

    COUNT(*) FILTER (
        WHERE operating_expenditure
              + development_expenditure <= 0
    ) AS invalid_component_total_count,

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
                OR operating_expenditure
                   + development_expenditure <= 0
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS indicator_data_quality

FROM analytics.vw_sector_financial_summary;
