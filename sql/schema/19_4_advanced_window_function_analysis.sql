-- ============================================================
-- STEP 19.4: ADVANCED WINDOW FUNCTION COMPARATIVE ANALYSIS
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 19.4.1 Cumulative Budget Allocation & Contribution

WITH budget_ranking AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.total_budget,
        SUM(f.total_budget) OVER () AS grand_total_budget,
        SUM(f.total_budget) OVER (
            ORDER BY f.total_budget DESC, m.ministry_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_budget,
        RANK() OVER (
            ORDER BY f.total_budget DESC
        ) AS budget_rank
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    ministry_id,
    ministry_name,
    budget_rank,
    ROUND(total_budget::numeric, 4) AS total_budget,
    ROUND(cumulative_budget::numeric, 4) AS cumulative_budget,
    ROUND(
        total_budget::numeric
        / NULLIF(grand_total_budget::numeric, 0) * 100,
        4
    ) AS individual_budget_share_pct,
    ROUND(
        cumulative_budget::numeric
        / NULLIF(grand_total_budget::numeric, 0) * 100,
        4
    ) AS cumulative_budget_share_pct
FROM budget_ranking
ORDER BY budget_rank, ministry_id;


-- 19.4.2 Cumulative Actual Expenditure Contribution

WITH expenditure_ranking AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.actual_expenditure,
        SUM(f.actual_expenditure) OVER () AS grand_total_actual,
        SUM(f.actual_expenditure) OVER (
            ORDER BY f.actual_expenditure DESC, m.ministry_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_actual,
        RANK() OVER (
            ORDER BY f.actual_expenditure DESC
        ) AS expenditure_rank
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    ministry_id,
    ministry_name,
    expenditure_rank,
    ROUND(actual_expenditure::numeric, 4) AS actual_expenditure,
    ROUND(cumulative_actual::numeric, 4) AS cumulative_actual,
    ROUND(
        actual_expenditure::numeric
        / NULLIF(grand_total_actual::numeric, 0) * 100,
        4
    ) AS individual_expenditure_share_pct,
    ROUND(
        cumulative_actual::numeric
        / NULLIF(grand_total_actual::numeric, 0) * 100,
        4
    ) AS cumulative_expenditure_share_pct
FROM expenditure_ranking
ORDER BY expenditure_rank, ministry_id;


-- 19.4.3 Positive Budget Variance Contribution

WITH positive_variance AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.budget_variance,
        SUM(f.budget_variance) OVER () AS total_positive_variance,
        SUM(f.budget_variance) OVER (
            ORDER BY f.budget_variance DESC, m.ministry_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_positive_variance,
        ROW_NUMBER() OVER (
            ORDER BY f.budget_variance DESC, m.ministry_id
        ) AS variance_rank
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    WHERE f.budget_variance > 0
)
SELECT
    ministry_id,
    ministry_name,
    variance_rank,
    ROUND(budget_variance::numeric, 4) AS positive_variance,
    ROUND(
        budget_variance::numeric
        / NULLIF(total_positive_variance::numeric, 0) * 100,
        4
    ) AS individual_contribution_pct,
    ROUND(cumulative_positive_variance::numeric, 4)
        AS cumulative_positive_variance,
    ROUND(
        cumulative_positive_variance::numeric
        / NULLIF(total_positive_variance::numeric, 0) * 100,
        4
    ) AS cumulative_contribution_pct
FROM positive_variance
ORDER BY variance_rank;


-- 19.4.4 Operating vs Development Expenditure Composition

WITH expenditure_composition AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.operating_expenditure,
        f.development_expenditure,
        f.actual_expenditure,
        SUM(f.operating_expenditure) OVER () AS total_operating,
        SUM(f.development_expenditure) OVER () AS total_development,
        SUM(f.actual_expenditure) OVER () AS total_actual
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    ministry_id,
    ministry_name,
    ROUND(operating_expenditure::numeric, 4) AS operating_expenditure,
    ROUND(development_expenditure::numeric, 4) AS development_expenditure,
    ROUND(actual_expenditure::numeric, 4) AS actual_expenditure,
    ROUND(
        operating_expenditure::numeric
        / NULLIF(actual_expenditure::numeric, 0) * 100,
        4
    ) AS operating_share_pct,
    ROUND(
        development_expenditure::numeric
        / NULLIF(actual_expenditure::numeric, 0) * 100,
        4
    ) AS development_share_pct,
    ROUND(
        operating_expenditure::numeric
        / NULLIF(total_operating::numeric, 0) * 100,
        4
    ) AS share_of_total_operating_pct,
    ROUND(
        development_expenditure::numeric
        / NULLIF(total_development::numeric, 0) * 100,
        4
    ) AS share_of_total_development_pct
FROM expenditure_composition
ORDER BY actual_expenditure DESC, ministry_id;


-- 19.4.5 Ministry Performance vs Overall Average

WITH performance_comparison AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        ROUND(
            f.actual_expenditure::numeric
            / NULLIF(f.total_budget::numeric, 0) * 100,
            4
        ) AS utilization_pct,
        AVG(
            f.actual_expenditure::numeric
            / NULLIF(f.total_budget::numeric, 0) * 100
        ) OVER () AS overall_avg_utilization,
        RANK() OVER (
            ORDER BY
                f.actual_expenditure::numeric
                / NULLIF(f.total_budget::numeric, 0) DESC
        ) AS utilization_rank,
        PERCENT_RANK() OVER (
            ORDER BY
                f.actual_expenditure::numeric
                / NULLIF(f.total_budget::numeric, 0)
        ) AS utilization_percentile
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    WHERE f.total_budget > 0
)
SELECT
    ministry_id,
    ministry_name,
    ROUND(total_budget::numeric, 4) AS total_budget,
    ROUND(actual_expenditure::numeric, 4) AS actual_expenditure,
    utilization_rank,
    utilization_pct,
    ROUND(overall_avg_utilization::numeric, 4)
        AS overall_avg_utilization_pct,
    ROUND(
        utilization_pct - overall_avg_utilization::numeric,
        4
    ) AS deviation_from_average_pp,
    ROUND(utilization_percentile::numeric * 100, 4)
        AS utilization_percentile_pct,
    CASE
        WHEN utilization_pct > 100 THEN 'ABOVE BUDGET'
        WHEN utilization_pct > overall_avg_utilization
            THEN 'ABOVE AVERAGE'
        ELSE 'BELOW OR EQUAL TO AVERAGE'
    END AS performance_comparison
FROM performance_comparison
ORDER BY utilization_rank, ministry_id;


-- 19.4.6 Data Quality Validation

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT f.ministry_id) AS distinct_ministries,

    COUNT(*) FILTER (
        WHERE f.total_budget IS NULL
    ) AS missing_budget,

    COUNT(*) FILTER (
        WHERE f.actual_expenditure IS NULL
    ) AS missing_actual,

    COUNT(*) FILTER (
        WHERE f.operating_expenditure IS NULL
    ) AS missing_operating_expenditure,

    COUNT(*) FILTER (
        WHERE f.development_expenditure IS NULL
    ) AS missing_development_expenditure,

    COUNT(*) FILTER (
        WHERE f.total_budget <= 0
    ) AS non_positive_budget,

    COUNT(*) FILTER (
        WHERE f.actual_expenditure < 0
    ) AS negative_actual,

    COUNT(*) FILTER (
        WHERE f.budget_variance IS NULL
           OR ABS(
               f.budget_variance
               - (f.total_budget - f.actual_expenditure)
           ) > 0.0001
    ) AS variance_mismatch,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT f.ministry_id) = 62
         AND COUNT(*) FILTER (
             WHERE f.total_budget IS NULL
                OR f.actual_expenditure IS NULL
                OR f.operating_expenditure IS NULL
                OR f.development_expenditure IS NULL
                OR f.total_budget <= 0
                OR f.actual_expenditure < 0
                OR f.budget_variance IS NULL
                OR ABS(
                    f.budget_variance
                    - (f.total_budget - f.actual_expenditure)
                ) > 0.0001
         ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM analytics.fact_ministry_budget f;


-- END OF STEP 19.4