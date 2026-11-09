-- ============================================================
-- STEP 16.19: SECTOR-WISE STATISTICAL ANALYSIS
-- Project: Government Budget Analytics
-- Unit: BDT Crore unless otherwise specified
-- ============================================================


-- 16.19.1 BUDGET STATISTICAL SUMMARY

SELECT
    COUNT(*) AS sector_count,

    ROUND(AVG(total_budget)::numeric, 4)
        AS mean_budget,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY total_budget)::numeric,
        4
    ) AS median_budget,

    ROUND(MIN(total_budget)::numeric, 4)
        AS minimum_budget,

    ROUND(MAX(total_budget)::numeric, 4)
        AS maximum_budget,

    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY total_budget)::numeric,
        4
    ) AS q1_budget,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY total_budget)::numeric,
        4
    ) AS q3_budget,

    ROUND(
        (
            PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY total_budget)
            -
            PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY total_budget)
        )::numeric,
        4
    ) AS budget_iqr,

    ROUND(STDDEV_POP(total_budget)::numeric, 4)
        AS population_stddev,

    ROUND(VARIANCE(total_budget)::numeric, 4)
        AS sample_variance

FROM analytics.vw_sector_financial_summary;


-- 16.19.2 ACTUAL EXPENDITURE STATISTICAL SUMMARY

SELECT
    COUNT(*) AS sector_count,

    ROUND(AVG(actual_expenditure)::numeric, 4)
        AS mean_actual,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY actual_expenditure)::numeric,
        4
    ) AS median_actual,

    ROUND(MIN(actual_expenditure)::numeric, 4)
        AS minimum_actual,

    ROUND(MAX(actual_expenditure)::numeric, 4)
        AS maximum_actual,

    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY actual_expenditure)::numeric,
        4
    ) AS q1_actual,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY actual_expenditure)::numeric,
        4
    ) AS q3_actual,

    ROUND(
        (
            PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY actual_expenditure)
            -
            PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY actual_expenditure)
        )::numeric,
        4
    ) AS actual_iqr,

    ROUND(STDDEV_POP(actual_expenditure)::numeric, 4)
        AS population_stddev,

    ROUND(VARIANCE(actual_expenditure)::numeric, 4)
        AS sample_variance

FROM analytics.vw_sector_financial_summary;


-- 16.19.3 UTILIZATION RATE STATISTICAL SUMMARY

WITH utilization_data AS (
    SELECT
        sector_name,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100
            AS utilization_pct

    FROM analytics.vw_sector_financial_summary
)

SELECT
    COUNT(*) AS sector_count,

    ROUND(AVG(utilization_pct)::numeric, 4)
        AS mean_utilization_pct,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY utilization_pct)::numeric,
        4
    ) AS median_utilization_pct,

    ROUND(MIN(utilization_pct)::numeric, 4)
        AS minimum_utilization_pct,

    ROUND(MAX(utilization_pct)::numeric, 4)
        AS maximum_utilization_pct,

    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY utilization_pct)::numeric,
        4
    ) AS q1_utilization_pct,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY utilization_pct)::numeric,
        4
    ) AS q3_utilization_pct,

    ROUND(
        (
            PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY utilization_pct)
            -
            PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY utilization_pct)
        )::numeric,
        4
    ) AS utilization_iqr,

    ROUND(STDDEV_POP(utilization_pct)::numeric, 4)
        AS population_stddev

FROM utilization_data;


-- 16.19.4 SPENDING GAP STATISTICAL SUMMARY

WITH spending_data AS (
    SELECT
        sector_name,
        total_budget - actual_expenditure AS spending_gap
    FROM analytics.vw_sector_financial_summary
)

SELECT
    COUNT(*) AS sector_count,

    ROUND(AVG(spending_gap)::numeric, 4)
        AS mean_spending_gap,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY spending_gap)::numeric,
        4
    ) AS median_spending_gap,

    ROUND(MIN(spending_gap)::numeric, 4)
        AS minimum_spending_gap,

    ROUND(MAX(spending_gap)::numeric, 4)
        AS maximum_spending_gap,

    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY spending_gap)::numeric,
        4
    ) AS q1_spending_gap,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY spending_gap)::numeric,
        4
    ) AS q3_spending_gap,

    ROUND(
        (
            PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY spending_gap)
            -
            PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY spending_gap)
        )::numeric,
        4
    ) AS spending_gap_iqr,

    ROUND(STDDEV_POP(spending_gap)::numeric, 4)
        AS population_stddev

FROM spending_data;


-- 16.19.5 SECTOR-LEVEL Z-SCORE ANALYSIS
-- Population standard deviation is used.

WITH sector_metrics AS (
    SELECT
        sector_name,
        total_budget,
        actual_expenditure,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100
            AS utilization_pct,

        total_budget - actual_expenditure
            AS spending_gap

    FROM analytics.vw_sector_financial_summary
),

statistics AS (
    SELECT
        AVG(total_budget) AS avg_budget,
        STDDEV_POP(total_budget) AS sd_budget,

        AVG(actual_expenditure) AS avg_actual,
        STDDEV_POP(actual_expenditure) AS sd_actual,

        AVG(utilization_pct) AS avg_utilization,
        STDDEV_POP(utilization_pct) AS sd_utilization

    FROM sector_metrics
)

SELECT
    m.sector_name,

    ROUND(
        ((m.total_budget - s.avg_budget)
        / NULLIF(s.sd_budget, 0))::numeric,
        4
    ) AS budget_z_score,

    ROUND(
        ((m.actual_expenditure - s.avg_actual)
        / NULLIF(s.sd_actual, 0))::numeric,
        4
    ) AS actual_z_score,

    ROUND(
        ((m.utilization_pct - s.avg_utilization)
        / NULLIF(s.sd_utilization, 0))::numeric,
        4
    ) AS utilization_z_score

FROM sector_metrics m
CROSS JOIN statistics s

ORDER BY m.sector_name;


-- 16.19.6 IQR-BASED POTENTIAL OUTLIER REVIEW
-- Statistical flags only; no records are modified.

WITH sector_metrics AS (
    SELECT
        sector_name,
        total_budget,
        actual_expenditure,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100
            AS utilization_pct

    FROM analytics.vw_sector_financial_summary
),

quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY utilization_pct) AS q1,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY utilization_pct) AS q3

    FROM sector_metrics
),

bounds AS (
    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound

    FROM quartiles
)

SELECT
    m.sector_name,

    ROUND(m.utilization_pct::numeric, 4)
        AS utilization_pct,

    ROUND(b.q1::numeric, 4)
        AS q1,

    ROUND(b.q3::numeric, 4)
        AS q3,

    ROUND(b.iqr::numeric, 4)
        AS iqr,

    ROUND(b.lower_bound::numeric, 4)
        AS lower_bound,

    ROUND(b.upper_bound::numeric, 4)
        AS upper_bound,

    CASE
        WHEN m.utilization_pct < b.lower_bound
          OR m.utilization_pct > b.upper_bound
        THEN 'POTENTIAL OUTLIER'
        ELSE 'WITHIN RANGE'
    END AS statistical_status

FROM sector_metrics m
CROSS JOIN bounds b

ORDER BY m.utilization_pct;


-- 16.19.7 STATISTICAL INPUT DATA QUALITY

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
    ) AS invalid_budget_count,

    COUNT(*) FILTER (
        WHERE total_budget IS NOT NULL
          AND actual_expenditure IS NOT NULL
          AND total_budget > 0
          AND actual_expenditure / total_budget * 100 < 0
    ) AS invalid_utilization_count,

    CASE
        WHEN COUNT(*) = 5
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR total_budget <= 0
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS statistical_input_status

FROM analytics.vw_sector_financial_summary;
