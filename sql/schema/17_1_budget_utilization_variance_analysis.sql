-- ============================================================
-- STEP 17.1: BUDGET UTILIZATION & VARIANCE ANALYSIS
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 17.1.1 MINISTRY-WISE UTILIZATION AND VARIANCE

SELECT
    m.ministry_code,
    m.ministry_name,

    ROUND(f.total_budget::numeric, 4) AS total_budget,

    ROUND(f.actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(f.budget_variance::numeric, 4)
        AS recorded_budget_variance,

    ROUND(
        (f.total_budget - f.actual_expenditure)::numeric, 4
    ) AS calculated_budget_variance,

    ROUND(
        (f.actual_expenditure
        / NULLIF(f.total_budget, 0) * 100)::numeric, 4
    ) AS utilization_pct,

    CASE
        WHEN f.actual_expenditure > f.total_budget
            THEN 'OVERSPENDING'
        WHEN f.actual_expenditure = f.total_budget
            THEN 'FULLY UTILIZED'
        WHEN f.actual_expenditure < f.total_budget
            THEN 'UNDERUTILIZED'
        ELSE 'REVIEW REQUIRED'
    END AS utilization_status

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
  ON m.ministry_id = f.ministry_id

ORDER BY utilization_pct DESC;


-- 17.1.2 UTILIZATION PERFORMANCE CLASSIFICATION

WITH ministry_metrics AS (
    SELECT
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,

        f.actual_expenditure
        / NULLIF(f.total_budget, 0) * 100 AS utilization_pct

    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
      ON m.ministry_id = f.ministry_id
)

SELECT
    ministry_name,

    ROUND(utilization_pct::numeric, 4) AS utilization_pct,

    CASE
        WHEN utilization_pct > 100 THEN 'OVER 100%'
        WHEN utilization_pct >= 90 THEN 'HIGH: 90-100%'
        WHEN utilization_pct >= 75 THEN 'MODERATE: 75-89.99%'
        WHEN utilization_pct >= 50 THEN 'LOW: 50-74.99%'
        ELSE 'VERY LOW: BELOW 50%'
    END AS utilization_category

FROM ministry_metrics

ORDER BY utilization_pct DESC;


-- 17.1.3 HIGHEST UNDERUTILIZED MINISTRIES

SELECT
    m.ministry_name,

    ROUND(f.total_budget::numeric, 4) AS total_budget,

    ROUND(f.actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (f.total_budget - f.actual_expenditure)::numeric, 4
    ) AS unspent_budget,

    ROUND(
        ((f.total_budget - f.actual_expenditure)
        / NULLIF(f.total_budget, 0) * 100)::numeric, 4
    ) AS unspent_budget_pct

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
  ON m.ministry_id = f.ministry_id

WHERE f.total_budget > f.actual_expenditure

ORDER BY unspent_budget DESC

LIMIT 15;


-- 17.1.4 OVERSPENDING MINISTRIES

SELECT
    m.ministry_name,

    ROUND(f.total_budget::numeric, 4) AS total_budget,

    ROUND(f.actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (f.actual_expenditure - f.total_budget)::numeric, 4
    ) AS overspending_amount,

    ROUND(
        ((f.actual_expenditure - f.total_budget)
        / NULLIF(f.total_budget, 0) * 100)::numeric, 4
    ) AS overspending_pct,

    ROUND(
        (f.actual_expenditure
        / NULLIF(f.total_budget, 0) * 100)::numeric, 4
    ) AS utilization_pct

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
  ON m.ministry_id = f.ministry_id

WHERE f.actual_expenditure > f.total_budget

ORDER BY overspending_amount DESC;


-- 17.1.5 BUDGET VARIANCE RANKING

SELECT
    m.ministry_name,

    ROUND(f.total_budget::numeric, 4) AS total_budget,

    ROUND(f.actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(f.budget_variance::numeric, 4)
        AS budget_variance,

    RANK() OVER (
        ORDER BY f.budget_variance DESC
    ) AS highest_positive_variance_rank,

    RANK() OVER (
        ORDER BY f.budget_variance ASC
    ) AS lowest_variance_rank

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
  ON m.ministry_id = f.ministry_id

ORDER BY f.budget_variance DESC;


-- 17.1.6 UTILIZATION CATEGORY DISTRIBUTION

WITH ministry_metrics AS (
    SELECT
        f.actual_expenditure
        / NULLIF(f.total_budget, 0) * 100 AS utilization_pct

    FROM analytics.fact_ministry_budget f
)

SELECT
    CASE
        WHEN utilization_pct > 100 THEN 'OVER 100%'
        WHEN utilization_pct >= 90 THEN 'HIGH: 90-100%'
        WHEN utilization_pct >= 75 THEN 'MODERATE: 75-89.99%'
        WHEN utilization_pct >= 50 THEN 'LOW: 50-74.99%'
        ELSE 'VERY LOW: BELOW 50%'
    END AS utilization_category,

    COUNT(*) AS ministry_count,

    ROUND(
        (COUNT(*)::numeric
        / NULLIF(SUM(COUNT(*)) OVER (), 0) * 100), 2
    ) AS ministry_share_pct

FROM ministry_metrics

GROUP BY 1

ORDER BY ministry_count DESC;


-- 17.1.7 OVERALL BUDGET UTILIZATION KPI

SELECT
    COUNT(*) AS ministry_count,

    ROUND(SUM(total_budget)::numeric, 4)
        AS total_budget,

    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (SUM(total_budget) - SUM(actual_expenditure))::numeric, 4
    ) AS total_budget_variance,

    ROUND(
        (SUM(actual_expenditure)
        / NULLIF(SUM(total_budget), 0) * 100)::numeric, 4
    ) AS overall_utilization_pct,

    COUNT(*) FILTER (
        WHERE actual_expenditure > total_budget
    ) AS overspending_ministries,

    COUNT(*) FILTER (
        WHERE actual_expenditure < total_budget
    ) AS underutilized_ministries,

    COUNT(*) FILTER (
        WHERE actual_expenditure = total_budget
    ) AS fully_utilized_ministries

FROM analytics.fact_ministry_budget;


-- 17.1.8 VARIANCE AND UTILIZATION DATA QUALITY

SELECT
    COUNT(*) AS total_records,

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
        WHERE actual_expenditure < 0
    ) AS negative_actual_count,

    COUNT(*) FILTER (
        WHERE ABS(
            budget_variance
            - (total_budget - actual_expenditure)
        ) > 0.001
    ) AS variance_mismatch_count,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR budget_variance IS NULL
                OR total_budget <= 0
                OR actual_expenditure < 0
                OR ABS(
                    budget_variance
                    - (total_budget - actual_expenditure)
                ) > 0.001
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS data_quality_status

FROM analytics.fact_ministry_budget;
