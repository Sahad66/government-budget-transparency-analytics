-- ============================================================
-- STEP 19.2: MINISTRY RANKING & PERCENTILE ANALYSIS
-- ============================================================

-- 19.2.1 Complete ministry ranking
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
)
SELECT
    ministry_id,
    ministry_name,

    ROUND(total_budget::numeric, 4) AS total_budget,

    RANK() OVER (
        ORDER BY total_budget DESC
    ) AS budget_rank,

    DENSE_RANK() OVER (
        ORDER BY total_budget DESC
    ) AS budget_dense_rank,

    ROW_NUMBER() OVER (
        ORDER BY total_budget DESC, ministry_id
    ) AS budget_row_number,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    RANK() OVER (
        ORDER BY actual_expenditure DESC
    ) AS actual_expenditure_rank,

    ROUND(utilization_pct::numeric, 4)
        AS utilization_pct,

    RANK() OVER (
        ORDER BY utilization_pct DESC
    ) AS utilization_rank,

    RANK() OVER (
        ORDER BY budget_variance ASC
    ) AS variance_rank

FROM ministry_metrics
ORDER BY budget_rank, ministry_id;


-- 19.2.2 Utilization percentile ranking
WITH ministry_metrics AS (
    SELECT
        f.ministry_id,
        m.ministry_name,
        f.actual_expenditure
            / NULLIF(f.total_budget, 0) * 100 AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    ministry_id,
    ministry_name,
    ROUND(utilization_pct::numeric, 4) AS utilization_pct,

    ROUND(
        (PERCENT_RANK() OVER (
            ORDER BY utilization_pct
        ) * 100)::numeric,
        2
    ) AS utilization_percentile,

    ROUND(
        (CUME_DIST() OVER (
            ORDER BY utilization_pct
        ) * 100)::numeric,
        2
    ) AS cumulative_distribution_pct

FROM ministry_metrics
ORDER BY utilization_pct DESC;


-- 19.2.3 Ministry quartile classification
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
quartiles AS (
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY utilization_pct DESC, ministry_id
        ) AS utilization_quartile
    FROM ministry_metrics
)
SELECT
    utilization_quartile,
    CASE utilization_quartile
        WHEN 1 THEN 'TOP QUARTILE'
        WHEN 2 THEN 'UPPER-MIDDLE QUARTILE'
        WHEN 3 THEN 'LOWER-MIDDLE QUARTILE'
        WHEN 4 THEN 'BOTTOM QUARTILE'
    END AS quartile_category,
    COUNT(*) AS ministry_count,
    ROUND(AVG(utilization_pct)::numeric, 4)
        AS avg_utilization_pct,
    ROUND(MIN(utilization_pct)::numeric, 4)
        AS min_utilization_pct,
    ROUND(MAX(utilization_pct)::numeric, 4)
        AS max_utilization_pct
FROM quartiles
GROUP BY utilization_quartile
ORDER BY utilization_quartile;


-- 19.2.4 Top 10 ministries by budget
WITH ranked AS (
    SELECT
        m.ministry_name,
        f.total_budget,
        RANK() OVER (
            ORDER BY f.total_budget DESC
        ) AS budget_rank
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    budget_rank,
    ministry_name,
    ROUND(total_budget::numeric, 4) AS total_budget
FROM ranked
WHERE budget_rank <= 10
ORDER BY budget_rank;


-- 19.2.5 Ranking distribution validation
WITH ranked AS (
    SELECT
        ministry_id,
        RANK() OVER (
            ORDER BY total_budget DESC
        ) AS budget_rank,
        RANK() OVER (
            ORDER BY actual_expenditure DESC
        ) AS actual_rank,
        RANK() OVER (
            ORDER BY actual_expenditure
                / NULLIF(total_budget, 0) DESC
        ) AS utilization_rank,
        NTILE(4) OVER (
            ORDER BY actual_expenditure
                / NULLIF(total_budget, 0) DESC,
                ministry_id
        ) AS utilization_quartile
    FROM analytics.fact_ministry_budget
)
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT ministry_id) AS distinct_ministries,
    COUNT(*) FILTER (
        WHERE budget_rank IS NULL
           OR actual_rank IS NULL
           OR utilization_rank IS NULL
           OR utilization_quartile IS NULL
    ) AS missing_ranking_values,
    COUNT(DISTINCT utilization_quartile) AS quartile_count,
    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT ministry_id) = 62
         AND COUNT(*) FILTER (
             WHERE budget_rank IS NULL
                OR actual_rank IS NULL
                OR utilization_rank IS NULL
                OR utilization_quartile IS NULL
         ) = 0
         AND COUNT(DISTINCT utilization_quartile) = 4
        THEN 'PASS'
        ELSE 'CHECK REQUIRED'
    END AS validation_status
FROM ranked;