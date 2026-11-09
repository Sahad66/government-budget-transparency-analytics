-- ============================================================
-- STEP 19.1: MINISTRY FINANCIAL PERFORMANCE BENCHMARKING
-- ============================================================

-- 19.1.1 Overall financial benchmarks
WITH ministry_metrics AS (
    SELECT
        ministry_id,
        total_budget,
        actual_expenditure,
        budget_variance,
        actual_expenditure
            / NULLIF(total_budget, 0) * 100 AS utilization_pct
    FROM analytics.fact_ministry_budget
)
SELECT
    COUNT(*) AS ministry_count,
    ROUND(AVG(total_budget)::numeric, 4) AS avg_budget,
    ROUND(AVG(actual_expenditure)::numeric, 4) AS avg_actual_expenditure,
    ROUND(AVG(utilization_pct)::numeric, 4) AS avg_utilization_pct,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY utilization_pct)::numeric,
        4
    ) AS median_utilization_pct,
    ROUND(MIN(utilization_pct)::numeric, 4) AS min_utilization_pct,
    ROUND(MAX(utilization_pct)::numeric, 4) AS max_utilization_pct,
    ROUND(STDDEV_POP(utilization_pct)::numeric, 4)
        AS utilization_stddev
FROM ministry_metrics;


-- 19.1.2 Ministry-wise deviation from average utilization
WITH ministry_metrics AS (
    SELECT
        f.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        f.actual_expenditure
            / NULLIF(f.total_budget, 0) * 100 AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
benchmark AS (
    SELECT AVG(utilization_pct) AS avg_utilization_pct
    FROM ministry_metrics
)
SELECT
    mm.ministry_id,
    mm.ministry_name,
    ROUND(mm.total_budget::numeric, 4) AS total_budget,
    ROUND(mm.actual_expenditure::numeric, 4) AS actual_expenditure,
    ROUND(mm.utilization_pct::numeric, 4) AS utilization_pct,
    ROUND(b.avg_utilization_pct::numeric, 4)
        AS average_utilization_pct,
    ROUND(
        (mm.utilization_pct - b.avg_utilization_pct)::numeric,
        4
    ) AS deviation_from_average_pp
FROM ministry_metrics mm
CROSS JOIN benchmark b
ORDER BY deviation_from_average_pp DESC;


-- 19.1.3 Ministry performance benchmark classification
WITH ministry_metrics AS (
    SELECT
        f.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.actual_expenditure
            / NULLIF(f.total_budget, 0) * 100 AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
benchmark AS (
    SELECT AVG(utilization_pct) AS avg_utilization_pct
    FROM ministry_metrics
)
SELECT
    mm.ministry_name,
    ROUND(mm.utilization_pct::numeric, 4) AS utilization_pct,
    ROUND(b.avg_utilization_pct::numeric, 4)
        AS average_utilization_pct,
    CASE
        WHEN mm.utilization_pct > 100
            THEN 'ABOVE BUDGET'
        WHEN mm.utilization_pct >= b.avg_utilization_pct
            THEN 'ABOVE AVERAGE UTILIZATION'
        ELSE 'BELOW AVERAGE UTILIZATION'
    END AS benchmark_category
FROM ministry_metrics mm
CROSS JOIN benchmark b
ORDER BY mm.utilization_pct DESC;


-- 19.1.4 Benchmark category distribution
WITH ministry_metrics AS (
    SELECT
        f.ministry_id,
        f.total_budget,
        f.actual_expenditure,
        f.actual_expenditure
            / NULLIF(f.total_budget, 0) * 100 AS utilization_pct
    FROM analytics.fact_ministry_budget f
),
benchmark AS (
    SELECT AVG(utilization_pct) AS avg_utilization_pct
    FROM ministry_metrics
),
classified AS (
    SELECT
        CASE
            WHEN mm.utilization_pct > 100
                THEN 'ABOVE BUDGET'
            WHEN mm.utilization_pct >= b.avg_utilization_pct
                THEN 'ABOVE AVERAGE UTILIZATION'
            ELSE 'BELOW AVERAGE UTILIZATION'
        END AS benchmark_category
    FROM ministry_metrics mm
    CROSS JOIN benchmark b
)
SELECT
    benchmark_category,
    COUNT(*) AS ministry_count,
    ROUND(
        COUNT(*)::numeric
        / NULLIF(SUM(COUNT(*)) OVER (), 0) * 100,
        2
    ) AS ministry_share_pct
FROM classified
GROUP BY benchmark_category
ORDER BY ministry_count DESC;


-- 19.1.5 Benchmark data quality validation
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT ministry_id) AS distinct_ministries,
    COUNT(*) FILTER (
        WHERE total_budget IS NULL
           OR actual_expenditure IS NULL
    ) AS missing_financial_values,
    COUNT(*) FILTER (
        WHERE total_budget <= 0
    ) AS invalid_budget_records,
    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
           OR total_budget IS NULL
    ) AS invalid_utilization_records,
    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT ministry_id) = 62
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR total_budget <= 0
         ) = 0
        THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS validation_status
FROM analytics.fact_ministry_budget;