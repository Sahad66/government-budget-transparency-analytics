-- ============================================================
-- STEP 16.23: SECTOR-WISE COMPARATIVE ANALYSIS
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- Read-only analytical queries
-- ============================================================


-- 16.23.1 BUDGET VS ACTUAL COMPARISON

SELECT
    sector_name,
    ministry_count,

    ROUND(total_budget::numeric, 4)
        AS total_budget,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (total_budget - actual_expenditure)::numeric, 4
    ) AS spending_gap,

    ROUND(
        (actual_expenditure
        / NULLIF(total_budget, 0) * 100)::numeric, 4
    ) AS utilization_pct

FROM analytics.vw_sector_financial_summary

ORDER BY total_budget DESC;


-- 16.23.2 UTILIZATION AND SPENDING GAP COMPARISON

SELECT
    sector_name,

    ROUND(
        (actual_expenditure
        / NULLIF(total_budget, 0) * 100)::numeric, 4
    ) AS utilization_pct,

    ROUND(
        ((total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100)::numeric, 4
    ) AS spending_gap_pct,

    RANK() OVER (
        ORDER BY actual_expenditure
        / NULLIF(total_budget, 0) DESC
    ) AS utilization_rank,

    RANK() OVER (
        ORDER BY (total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) ASC
    ) AS lowest_gap_rank

FROM analytics.vw_sector_financial_summary

ORDER BY utilization_rank;


-- 16.23.3 OPERATING VS DEVELOPMENT COMPARISON

SELECT
    sector_name,

    ROUND(operating_expenditure::numeric, 4)
        AS operating_expenditure,

    ROUND(development_expenditure::numeric, 4)
        AS development_expenditure,

    ROUND(
        (operating_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure, 0
        ) * 100)::numeric, 4
    ) AS operating_share_pct,

    ROUND(
        (development_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure, 0
        ) * 100)::numeric, 4
    ) AS development_share_pct,

    CASE
        WHEN operating_expenditure > development_expenditure
            THEN 'OPERATING-ORIENTED'
        WHEN development_expenditure > operating_expenditure
            THEN 'DEVELOPMENT-ORIENTED'
        ELSE 'BALANCED'
    END AS expenditure_profile

FROM analytics.vw_sector_financial_summary

ORDER BY development_expenditure DESC;


-- 16.23.4 BUDGET, ACTUAL AND UTILIZATION RANKING

SELECT
    sector_name,

    RANK() OVER (
        ORDER BY total_budget DESC
    ) AS budget_rank,

    RANK() OVER (
        ORDER BY actual_expenditure DESC
    ) AS actual_expenditure_rank,

    RANK() OVER (
        ORDER BY actual_expenditure
        / NULLIF(total_budget, 0) DESC
    ) AS utilization_rank,

    RANK() OVER (
        ORDER BY total_budget - actual_expenditure DESC
    ) AS spending_gap_amount_rank,

    ROUND(total_budget::numeric, 4)
        AS total_budget,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure

FROM analytics.vw_sector_financial_summary

ORDER BY budget_rank;


-- 16.23.5 SECTOR CONTRIBUTION COMPARISON

SELECT
    sector_name,

    ROUND(
        (total_budget
        / NULLIF(SUM(total_budget) OVER (), 0) * 100)::numeric,
        4
    ) AS budget_contribution_pct,

    ROUND(
        (actual_expenditure
        / NULLIF(SUM(actual_expenditure) OVER (), 0) * 100)::numeric,
        4
    ) AS actual_contribution_pct,

    ROUND(
        (
            actual_expenditure
            / NULLIF(SUM(actual_expenditure) OVER (), 0) * 100
            -
            total_budget
            / NULLIF(SUM(total_budget) OVER (), 0) * 100
        )::numeric,
        4
    ) AS contribution_difference_pp

FROM analytics.vw_sector_financial_summary

ORDER BY budget_contribution_pct DESC;


-- 16.23.6 CONSOLIDATED COMPARATIVE SUMMARY

SELECT
    COUNT(*) AS sector_count,

    SUM(ministry_count) AS mapped_ministry_count,

    ROUND(SUM(total_budget)::numeric, 4)
        AS total_budget,

    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (SUM(total_budget) - SUM(actual_expenditure))::numeric,
        4
    ) AS spending_gap,

    ROUND(
        (SUM(actual_expenditure)
        / NULLIF(SUM(total_budget), 0) * 100)::numeric,
        4
    ) AS overall_utilization_pct,

    ROUND(SUM(operating_expenditure)::numeric, 4)
        AS operating_expenditure,

    ROUND(SUM(development_expenditure)::numeric, 4)
        AS development_expenditure,

    ROUND(
        (SUM(operating_expenditure)
        / NULLIF(SUM(operating_expenditure)
        + SUM(development_expenditure), 0) * 100)::numeric,
        4
    ) AS operating_share_pct,

    ROUND(
        (SUM(development_expenditure)
        / NULLIF(SUM(operating_expenditure)
        + SUM(development_expenditure), 0) * 100)::numeric,
        4
    ) AS development_share_pct

FROM analytics.vw_sector_financial_summary;


-- 16.23.7 COMPARATIVE RECONCILIATION

WITH totals AS (
    SELECT
        SUM(total_budget) AS sector_budget,
        SUM(actual_expenditure) AS sector_actual
    FROM analytics.vw_sector_financial_summary
),

mapped_totals AS (
    SELECT
        SUM(
            f.total_budget * b.allocation_share / 100.0
        ) AS mapped_budget,

        SUM(
            f.actual_expenditure * b.allocation_share / 100.0
        ) AS mapped_actual

    FROM analytics.fact_ministry_budget f

    JOIN analytics.bridge_ministry_sector b
      ON b.ministry_id = f.ministry_id

    WHERE b.mapping_status = 'approved'
)

SELECT
    ROUND(t.sector_budget::numeric, 4)
        AS sector_budget,

    ROUND(m.mapped_budget::numeric, 4)
        AS mapped_ministry_budget,

    ROUND(
        (t.sector_budget - m.mapped_budget)::numeric, 4
    ) AS budget_difference,

    ROUND(t.sector_actual::numeric, 4)
        AS sector_actual,

    ROUND(m.mapped_actual::numeric, 4)
        AS mapped_ministry_actual,

    ROUND(
        (t.sector_actual - m.mapped_actual)::numeric, 4
    ) AS actual_difference,

    CASE
        WHEN ABS(t.sector_budget - m.mapped_budget) <= 0.001
         AND ABS(t.sector_actual - m.mapped_actual) <= 0.001
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS reconciliation_status

FROM totals t
CROSS JOIN mapped_totals m;

-- 16.23.8 FINAL COMPARATIVE DATA QUALITY

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
    END AS comparative_data_quality

FROM analytics.vw_sector_financial_summary;
