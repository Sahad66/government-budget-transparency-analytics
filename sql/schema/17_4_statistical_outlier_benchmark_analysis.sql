-- ============================================================
-- STEP 17.4: STATISTICAL OUTLIER & BENCHMARK ANALYSIS
-- Unit: BDT Crore
-- ============================================================

-- 17.4.1 Overall statistical benchmarks
WITH metrics AS (
    SELECT
        COUNT(*) AS ministry_count,
        AVG(budget_variance) AS avg_variance,
        STDDEV_POP(budget_variance) AS stddev_variance,
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY budget_variance) AS q1_variance,
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY budget_variance) AS median_variance,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY budget_variance) AS q3_variance,
        AVG(
            actual_expenditure / NULLIF(total_budget, 0) * 100
        ) AS avg_utilization,
        STDDEV_POP(
            actual_expenditure / NULLIF(total_budget, 0) * 100
        ) AS stddev_utilization,
        PERCENTILE_CONT(0.25) WITHIN GROUP (
            ORDER BY actual_expenditure / NULLIF(total_budget, 0) * 100
        ) AS q1_utilization,
        PERCENTILE_CONT(0.50) WITHIN GROUP (
            ORDER BY actual_expenditure / NULLIF(total_budget, 0) * 100
        ) AS median_utilization,
        PERCENTILE_CONT(0.75) WITHIN GROUP (
            ORDER BY actual_expenditure / NULLIF(total_budget, 0) * 100
        ) AS q3_utilization
    FROM analytics.fact_ministry_budget
)
SELECT
    ministry_count,
    ROUND(avg_variance, 4) AS avg_variance,
    ROUND(stddev_variance, 4) AS stddev_variance,
    ROUND(q1_variance::numeric, 4) AS q1_variance,
    ROUND(median_variance::numeric, 4) AS median_variance,
    ROUND(q3_variance::numeric, 4) AS q3_variance,
    ROUND(avg_utilization, 4) AS avg_utilization_pct,
    ROUND(stddev_utilization, 4) AS stddev_utilization_pct,
    ROUND(q1_utilization::numeric, 4) AS q1_utilization_pct,
    ROUND(median_utilization::numeric, 4) AS median_utilization_pct,
    ROUND(q3_utilization::numeric, 4) AS q3_utilization_pct
FROM metrics;


-- 17.4.2 Positive variance IQR outliers
WITH base AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.budget_variance
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    WHERE f.budget_variance > 0
),
quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY budget_variance) AS q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY budget_variance) AS q3
    FROM base
),
bounds AS (
    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM quartiles
)
SELECT
    b.ministry_code,
    b.ministry_name,
    ROUND(b.budget_variance, 4) AS budget_variance,
    ROUND(x.upper_bound::numeric, 4) AS iqr_upper_bound,
    CASE
        WHEN b.budget_variance > x.upper_bound
            THEN 'HIGH VARIANCE OUTLIER'
        ELSE 'WITHIN IQR RANGE'
    END AS outlier_status
FROM base b
CROSS JOIN bounds x
ORDER BY b.budget_variance DESC;


-- 17.4.3 Utilization IQR outliers
WITH base AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.actual_expenditure / NULLIF(f.total_budget, 0) * 100
            AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    WHERE f.total_budget > 0
),
quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY utilization_pct) AS q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY utilization_pct) AS q3
    FROM base
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
    b.ministry_code,
    b.ministry_name,
    ROUND(b.utilization_pct, 4) AS utilization_pct,
    ROUND(x.lower_bound::numeric, 4) AS iqr_lower_bound,
    ROUND(x.upper_bound::numeric, 4) AS iqr_upper_bound,
    CASE
        WHEN b.utilization_pct < x.lower_bound
            THEN 'LOW UTILIZATION OUTLIER'
        WHEN b.utilization_pct > x.upper_bound
            THEN 'HIGH UTILIZATION OUTLIER'
        ELSE 'WITHIN IQR RANGE'
    END AS outlier_status
FROM base b
CROSS JOIN bounds x
ORDER BY b.utilization_pct;


-- 17.4.4 Budget variance Z-score
WITH base AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.budget_variance
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
stats AS (
    SELECT
        AVG(budget_variance) AS mean_variance,
        STDDEV_POP(budget_variance) AS stddev_variance
    FROM base
)
SELECT
    b.ministry_code,
    b.ministry_name,
    ROUND(b.budget_variance, 4) AS budget_variance,
    ROUND(s.mean_variance::numeric, 4) AS mean_variance,
    ROUND(((b.budget_variance - s.mean_variance) / NULLIF(s.stddev_variance, 0))::numeric, 4) AS variance_z_score,
    CASE
        WHEN ABS(
            (b.budget_variance - s.mean_variance)
            / NULLIF(s.stddev_variance, 0)
        ) >= 3 THEN 'EXTREME OUTLIER'
        WHEN ABS(
            (b.budget_variance - s.mean_variance)
            / NULLIF(s.stddev_variance, 0)
        ) >= 2 THEN 'POTENTIAL OUTLIER'
        ELSE 'WITHIN BENCHMARK'
    END AS benchmark_status
FROM base b
CROSS JOIN stats s
ORDER BY ABS(
    (b.budget_variance - s.mean_variance)
    / NULLIF(s.stddev_variance, 0)
) DESC;


-- 17.4.5 Outlier summary
WITH base AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.budget_variance,
        f.actual_expenditure / NULLIF(f.total_budget, 0) * 100
            AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
variance_bounds AS (
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY budget_variance) AS q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY budget_variance) AS q3
    FROM base WHERE budget_variance > 0
),
utilization_bounds AS (
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY utilization_pct) AS q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY utilization_pct) AS q3
    FROM base
)
SELECT
    COUNT(*) AS total_ministries,
    COUNT(*) FILTER (
        WHERE b.budget_variance >
            (v.q3 + 1.5 * (v.q3 - v.q1))
    ) AS high_variance_outlier_count,
    COUNT(*) FILTER (
        WHERE b.utilization_pct <
            (u.q1 - 1.5 * (u.q3 - u.q1))
    ) AS low_utilization_outlier_count,
    COUNT(*) FILTER (
        WHERE b.utilization_pct >
            (u.q3 + 1.5 * (u.q3 - u.q1))
    ) AS high_utilization_outlier_count
FROM base b
CROSS JOIN variance_bounds v
CROSS JOIN utilization_bounds u;


-- 17.4.6 Data quality validation
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE budget_variance IS NULL
    ) AS missing_variance_count,
    COUNT(*) FILTER (
        WHERE total_budget IS NULL OR total_budget <= 0
    ) AS invalid_budget_count,
    COUNT(*) FILTER (
        WHERE total_budget > 0
          AND actual_expenditure IS NULL
    ) AS missing_actual_count,
    COUNT(*) FILTER (
        WHERE total_budget > 0
          AND actual_expenditure IS NOT NULL
          AND budget_variance IS NOT NULL
          AND ABS(
              budget_variance - (total_budget - actual_expenditure)
          ) > 0.0001
    ) AS variance_mismatch_count,
    CASE
        WHEN COUNT(*) = 62
         AND COUNT(*) FILTER (
             WHERE budget_variance IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL OR total_budget <= 0
         ) = 0
         AND COUNT(*) FILTER (
             WHERE total_budget > 0
               AND actual_expenditure IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE total_budget > 0
               AND actual_expenditure IS NOT NULL
               AND budget_variance IS NOT NULL
               AND ABS(
                   budget_variance - (total_budget - actual_expenditure)
               ) > 0.0001
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS data_quality_status
FROM analytics.fact_ministry_budget;

-- END OF STEP 17.4