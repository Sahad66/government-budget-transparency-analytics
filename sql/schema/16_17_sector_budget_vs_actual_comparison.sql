-- ============================================================
-- STEP 16.17: SECTOR-WISE BUDGET VS ACTUAL COMPARISON
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 16.17.1 SECTOR-WISE BUDGET VS ACTUAL
SELECT
    sector_name,
    ministry_count,

    ROUND(total_budget::numeric, 4)
        AS allocated_budget,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (total_budget - actual_expenditure)::numeric,
        4
    ) AS unspent_budget,

    ROUND(
        (actual_expenditure / NULLIF(total_budget, 0)
        * 100)::numeric,
        4
    ) AS utilization_pct

FROM analytics.vw_sector_financial_summary

ORDER BY total_budget DESC;


-- 16.17.2 SECTOR-WISE SPENDING GAP RANKING
SELECT
    sector_name,

    ROUND(total_budget::numeric, 4)
        AS allocated_budget,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (total_budget - actual_expenditure)::numeric,
        4
    ) AS spending_gap,

    RANK() OVER (
        ORDER BY total_budget - actual_expenditure DESC
    ) AS spending_gap_rank

FROM analytics.vw_sector_financial_summary

ORDER BY spending_gap_rank;


-- 16.17.3 UTILIZATION PERFORMANCE RANKING
SELECT
    sector_name,
    ministry_count,

    ROUND(
        (actual_expenditure / NULLIF(total_budget, 0)
        * 100)::numeric,
        4
    ) AS utilization_pct,

    CASE
        WHEN total_budget <= 0 THEN 'INVALID BUDGET'
        WHEN actual_expenditure / NULLIF(total_budget, 0) > 1
            THEN 'ABOVE 100%'
        WHEN actual_expenditure / NULLIF(total_budget, 0) >= 0.80
            THEN 'HIGH UTILIZATION'
        WHEN actual_expenditure / NULLIF(total_budget, 0) >= 0.60
            THEN 'MODERATE UTILIZATION'
        ELSE 'LOW UTILIZATION'
    END AS performance_category,

    DENSE_RANK() OVER (
        ORDER BY
            actual_expenditure / NULLIF(total_budget, 0) DESC
    ) AS utilization_rank

FROM analytics.vw_sector_financial_summary

ORDER BY utilization_rank;


-- 16.17.4 SECTOR CONTRIBUTION TO MAPPED BUDGET AND ACTUAL
SELECT
    sector_name,

    ROUND(total_budget::numeric, 4)
        AS allocated_budget,

    ROUND(
        (total_budget / NULLIF(
            SUM(total_budget) OVER (), 0
        ) * 100)::numeric,
        4
    ) AS budget_contribution_pct,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (actual_expenditure / NULLIF(
            SUM(actual_expenditure) OVER (), 0
        ) * 100)::numeric,
        4
    ) AS expenditure_contribution_pct

FROM analytics.vw_sector_financial_summary

ORDER BY actual_expenditure DESC;


-- 16.17.5 OVERALL MAPPED SECTOR COMPARISON KPI
SELECT
    COUNT(*) AS analyzed_sectors,

    SUM(ministry_count) AS mapped_ministries,

    ROUND(SUM(total_budget)::numeric, 4)
        AS total_allocated_budget,

    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS total_actual_expenditure,

    ROUND(
        (SUM(total_budget) - SUM(actual_expenditure))::numeric,
        4
    ) AS total_spending_gap,

    ROUND(
        (SUM(actual_expenditure)
        / NULLIF(SUM(total_budget), 0) * 100)::numeric,
        4
    ) AS overall_utilization_pct,

    ROUND(
        (MAX(actual_expenditure / NULLIF(total_budget, 0))
        * 100)::numeric,
        4
    ) AS highest_sector_utilization_pct,

    ROUND(
        (MIN(actual_expenditure / NULLIF(total_budget, 0))
        * 100)::numeric,
        4
    ) AS lowest_sector_utilization_pct

FROM analytics.vw_sector_financial_summary;


-- 16.17.6 BUDGET VS ACTUAL DATA QUALITY CHECK
SELECT
    COUNT(*) AS sector_count,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
    ) AS missing_budget_count,

    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
    ) AS missing_actual_count,

    COUNT(*) FILTER (
        WHERE total_budget <= 0
    ) AS non_positive_budget_count,

    COUNT(*) FILTER (
        WHERE actual_expenditure < 0
    ) AS negative_actual_count,

    COUNT(*) FILTER (
        WHERE actual_expenditure > total_budget
    ) AS overspending_sector_count,

    CASE
        WHEN COUNT(*) = 5
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR total_budget <= 0
                OR actual_expenditure < 0
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS data_quality_status

FROM analytics.vw_sector_financial_summary;
