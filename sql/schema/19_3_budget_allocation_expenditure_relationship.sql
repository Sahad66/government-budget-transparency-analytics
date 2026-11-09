-- ============================================================
-- STEP 19.3: BUDGET ALLOCATION VS EXPENDITURE RELATIONSHIP
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 19.3.1 Pearson Correlation
-- Measures linear relationship between budget and expenditure.

SELECT
    COUNT(*) AS ministry_count,
    ROUND(
        CORR(total_budget::double precision,
             actual_expenditure::double precision)::numeric,
        4
    ) AS pearson_correlation,
    CASE
        WHEN CORR(total_budget::double precision,
                  actual_expenditure::double precision) IS NULL
            THEN 'NOT CALCULABLE'
        WHEN ABS(CORR(total_budget::double precision,
                      actual_expenditure::double precision)) >= 0.70
            THEN 'STRONG LINEAR RELATIONSHIP'
        WHEN ABS(CORR(total_budget::double precision,
                      actual_expenditure::double precision)) >= 0.40
            THEN 'MODERATE LINEAR RELATIONSHIP'
        ELSE 'WEAK LINEAR RELATIONSHIP'
    END AS relationship_interpretation
FROM analytics.fact_ministry_budget
WHERE total_budget IS NOT NULL
  AND actual_expenditure IS NOT NULL;


-- 19.3.2 Spearman Rank Correlation
-- Measures monotonic relationship using ministry rankings.

WITH ranked_data AS (
    SELECT
        ministry_id,
        RANK() OVER (ORDER BY total_budget) AS budget_rank,
        RANK() OVER (ORDER BY actual_expenditure) AS expenditure_rank
    FROM analytics.fact_ministry_budget
    WHERE total_budget IS NOT NULL
      AND actual_expenditure IS NOT NULL
)
SELECT
    COUNT(*) AS ministry_count,
    ROUND(
        CORR(budget_rank::double precision,
             expenditure_rank::double precision)::numeric,
        4
    ) AS spearman_rank_correlation
FROM ranked_data;


-- 19.3.3 Pearson Correlation Excluding Finance Division
-- Checks the influence of the largest budget allocation.

SELECT
    COUNT(*) AS ministry_count_excluding_finance,
    ROUND(
        CORR(f.total_budget::double precision,
             f.actual_expenditure::double precision)::numeric,
        4
    ) AS pearson_correlation_excluding_finance
FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id
WHERE f.total_budget IS NOT NULL
  AND f.actual_expenditure IS NOT NULL
  AND m.ministry_name <> 'Finance Division';


-- 19.3.4 Budget Size Quartile vs Expenditure Analysis

WITH budget_quartiles AS (
    SELECT
        f.ministry_id,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        NTILE(4) OVER (
            ORDER BY f.total_budget DESC, f.ministry_id
        ) AS budget_quartile
    FROM analytics.fact_ministry_budget f
    WHERE f.total_budget IS NOT NULL
      AND f.actual_expenditure IS NOT NULL
)
SELECT
    budget_quartile,
    CASE budget_quartile
        WHEN 1 THEN 'TOP BUDGET QUARTILE'
        WHEN 2 THEN 'UPPER-MIDDLE BUDGET QUARTILE'
        WHEN 3 THEN 'LOWER-MIDDLE BUDGET QUARTILE'
        WHEN 4 THEN 'BOTTOM BUDGET QUARTILE'
    END AS quartile_category,
    COUNT(*) AS ministry_count,
    ROUND(SUM(total_budget)::numeric, 4) AS total_budget,
    ROUND(SUM(actual_expenditure)::numeric, 4) AS actual_expenditure,
    ROUND(SUM(budget_variance)::numeric, 4) AS total_variance,
    ROUND(
        SUM(actual_expenditure)::numeric
        / NULLIF(SUM(total_budget)::numeric, 0) * 100,
        4
    ) AS utilization_pct,
    ROUND(AVG(total_budget)::numeric, 4) AS avg_budget,
    ROUND(AVG(actual_expenditure)::numeric, 4) AS avg_actual_expenditure
FROM budget_quartiles
GROUP BY budget_quartile
ORDER BY budget_quartile;


-- 19.3.5 Ministry Budget Share vs Actual Expenditure Share

WITH ministry_shares AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        SUM(f.total_budget) OVER () AS grand_total_budget,
        SUM(f.actual_expenditure) OVER () AS grand_total_actual
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    ministry_id,
    ministry_name,
    ROUND(total_budget::numeric, 4) AS total_budget,
    ROUND(actual_expenditure::numeric, 4) AS actual_expenditure,
    ROUND(
        total_budget::numeric
        / NULLIF(grand_total_budget::numeric, 0) * 100,
        4
    ) AS budget_share_pct,
    ROUND(
        actual_expenditure::numeric
        / NULLIF(grand_total_actual::numeric, 0) * 100,
        4
    ) AS expenditure_share_pct,
    ROUND(
        (
            actual_expenditure::numeric
            / NULLIF(grand_total_actual::numeric, 0) * 100
        )
        -
        (
            total_budget::numeric
            / NULLIF(grand_total_budget::numeric, 0) * 100
        ),
        4
    ) AS share_difference_pp
FROM ministry_shares
ORDER BY ABS(
    (
        actual_expenditure::numeric
        / NULLIF(grand_total_actual::numeric, 0) * 100
    )
    -
    (
        total_budget::numeric
        / NULLIF(grand_total_budget::numeric, 0) * 100
    )
) DESC;


-- 19.3.6 Data Quality Validation

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT f.ministry_id) AS distinct_ministries,

    COUNT(*) FILTER (
        WHERE f.ministry_id IS NULL
    ) AS missing_ministry_id,

    COUNT(*) FILTER (
        WHERE f.total_budget IS NULL
    ) AS missing_budget,

    COUNT(*) FILTER (
        WHERE f.actual_expenditure IS NULL
    ) AS missing_actual_expenditure,

    COUNT(*) FILTER (
        WHERE f.total_budget < 0
    ) AS invalid_budget_count,

    COUNT(*) FILTER (
        WHERE f.actual_expenditure < 0
    ) AS negative_actual_count,

    COUNT(*) FILTER (
        WHERE f.budget_variance IS NULL
           OR ABS(
               f.budget_variance
               - (f.total_budget - f.actual_expenditure)
           ) > 0.0001
    ) AS variance_mismatch_count,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT f.ministry_id) = 62
         AND COUNT(*) FILTER (
             WHERE f.ministry_id IS NULL
                OR f.total_budget IS NULL
                OR f.actual_expenditure IS NULL
                OR f.total_budget < 0
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


-- END OF STEP 19.3