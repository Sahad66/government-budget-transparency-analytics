-- ============================================================
-- STEP 19.5: ADVANCED CTE & CONDITIONAL AGGREGATION
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 19.5.1 Ministry-wise Consolidated Financial Profile

WITH ministry_base AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        f.operating_expenditure,
        f.development_expenditure,
        ROUND(
            f.actual_expenditure::numeric
            / NULLIF(f.total_budget::numeric, 0) * 100,
            4
        ) AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
classified AS (
    SELECT *,
        CASE
            WHEN utilization_pct > 100 THEN 'OVER 100%'
            WHEN utilization_pct >= 90 THEN '90-100%'
            WHEN utilization_pct >= 75 THEN '75-89.99%'
            WHEN utilization_pct >= 50 THEN '50-74.99%'
            ELSE 'BELOW 50%'
        END AS utilization_category,

        CASE
            WHEN budget_variance < 0 THEN 'OVERSPENDING'
            WHEN budget_variance > 0 THEN 'UNSPENT BUDGET'
            ELSE 'FULLY UTILIZED'
        END AS variance_direction,

        CASE
            WHEN operating_expenditure < 0
              OR development_expenditure < 0
                THEN 'NEGATIVE COMPONENT REVIEW'
            WHEN operating_expenditure > development_expenditure
                THEN 'OPERATING DOMINANT'
            WHEN development_expenditure > operating_expenditure
                THEN 'DEVELOPMENT DOMINANT'
            ELSE 'BALANCED'
        END AS expenditure_composition
    FROM ministry_base
)
SELECT
    ministry_id,
    ministry_name,
    ROUND(total_budget::numeric, 4) AS total_budget,
    ROUND(actual_expenditure::numeric, 4) AS actual_expenditure,
    ROUND(budget_variance::numeric, 4) AS budget_variance,
    utilization_pct,
    utilization_category,
    variance_direction,
    ROUND(operating_expenditure::numeric, 4)
        AS operating_expenditure,
    ROUND(development_expenditure::numeric, 4)
        AS development_expenditure,
    expenditure_composition
FROM classified
ORDER BY utilization_pct DESC, ministry_id;


-- 19.5.2 Conditional Aggregation by Utilization Category

WITH ministry_base AS (
    SELECT
        f.ministry_id,
        f.total_budget,
        f.actual_expenditure,
        ROUND(
            f.actual_expenditure::numeric
            / NULLIF(f.total_budget::numeric, 0) * 100,
            4
        ) AS utilization_pct
    FROM analytics.fact_ministry_budget f
),
classified AS (
    SELECT *,
        CASE
            WHEN utilization_pct > 100 THEN 'OVER 100%'
            WHEN utilization_pct >= 90 THEN '90-100%'
            WHEN utilization_pct >= 75 THEN '75-89.99%'
            WHEN utilization_pct >= 50 THEN '50-74.99%'
            ELSE 'BELOW 50%'
        END AS utilization_category
    FROM ministry_base
)
SELECT
    utilization_category,
    COUNT(*) AS ministry_count,
    ROUND(SUM(total_budget)::numeric, 4) AS total_budget,
    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS actual_expenditure,
    ROUND(SUM(total_budget - actual_expenditure)::numeric, 4)
        AS total_variance,
    ROUND(
        SUM(actual_expenditure)::numeric
        / NULLIF(SUM(total_budget)::numeric, 0) * 100,
        4
    ) AS combined_utilization_pct,

    COUNT(*) FILTER (
        WHERE utilization_pct > 100
    ) AS overspending_count,

    COUNT(*) FILTER (
        WHERE utilization_pct < 50
    ) AS below_50_pct_count

FROM classified
GROUP BY utilization_category
ORDER BY
    CASE utilization_category
        WHEN 'OVER 100%' THEN 1
        WHEN '90-100%' THEN 2
        WHEN '75-89.99%' THEN 3
        WHEN '50-74.99%' THEN 4
        WHEN 'BELOW 50%' THEN 5
    END;


-- 19.5.3 Budget Variance Direction vs Utilization

WITH ministry_base AS (
    SELECT
        f.ministry_id,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        ROUND(
            f.actual_expenditure::numeric
            / NULLIF(f.total_budget::numeric, 0) * 100,
            4
        ) AS utilization_pct
    FROM analytics.fact_ministry_budget f
),
classified AS (
    SELECT *,
        CASE
            WHEN budget_variance < 0 THEN 'OVERSPENDING'
            WHEN budget_variance > 0 THEN 'UNSPENT BUDGET'
            ELSE 'FULLY UTILIZED'
        END AS variance_direction,

        CASE
            WHEN utilization_pct > 100 THEN 'OVER 100%'
            WHEN utilization_pct >= 90 THEN '90-100%'
            WHEN utilization_pct >= 75 THEN '75-89.99%'
            WHEN utilization_pct >= 50 THEN '50-74.99%'
            ELSE 'BELOW 50%'
        END AS utilization_category
    FROM ministry_base
)
SELECT
    variance_direction,
    COUNT(*) AS ministry_count,
    COUNT(*) FILTER (
        WHERE utilization_category = 'OVER 100%'
    ) AS over_100_count,
    COUNT(*) FILTER (
        WHERE utilization_category = '90-100%'
    ) AS high_utilization_count,
    COUNT(*) FILTER (
        WHERE utilization_category = '75-89.99%'
    ) AS moderate_utilization_count,
    COUNT(*) FILTER (
        WHERE utilization_category = '50-74.99%'
    ) AS low_utilization_count,
    COUNT(*) FILTER (
        WHERE utilization_category = 'BELOW 50%'
    ) AS very_low_utilization_count,
    ROUND(SUM(total_budget)::numeric, 4) AS total_budget,
    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS actual_expenditure,
    ROUND(SUM(budget_variance)::numeric, 4) AS net_variance
FROM classified
GROUP BY variance_direction
ORDER BY
    CASE variance_direction
        WHEN 'OVERSPENDING' THEN 1
        WHEN 'UNSPENT BUDGET' THEN 2
        ELSE 3
    END;


-- 19.5.4 Operating vs Development Composition Summary

WITH composition AS (
    SELECT
        ministry_id,
        operating_expenditure,
        development_expenditure,
        actual_expenditure,
        CASE
            WHEN operating_expenditure < 0
              OR development_expenditure < 0
                THEN 'NEGATIVE COMPONENT REVIEW'
            WHEN operating_expenditure > development_expenditure
                THEN 'OPERATING DOMINANT'
            WHEN development_expenditure > operating_expenditure
                THEN 'DEVELOPMENT DOMINANT'
            ELSE 'BALANCED'
        END AS composition_category
    FROM analytics.fact_ministry_budget
)
SELECT
    composition_category,
    COUNT(*) AS ministry_count,
    ROUND(SUM(operating_expenditure)::numeric, 4)
        AS total_operating_expenditure,
    ROUND(SUM(development_expenditure)::numeric, 4)
        AS total_development_expenditure,
    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS total_actual_expenditure,
    COUNT(*) FILTER (
        WHERE operating_expenditure < 0
    ) AS negative_operating_count,
    COUNT(*) FILTER (
        WHERE development_expenditure < 0
    ) AS negative_development_count
FROM composition
GROUP BY composition_category
ORDER BY composition_category;


-- 19.5.5 Ministry-wise Financial Review Exception List

WITH ministry_flags AS (
    SELECT
        m.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        f.operating_expenditure,
        f.development_expenditure,
        ROUND(
            f.actual_expenditure::numeric
            / NULLIF(f.total_budget::numeric, 0) * 100,
            4
        ) AS utilization_pct
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
review_flags AS (
    SELECT *,
        CASE WHEN budget_variance < 0
            THEN 1 ELSE 0 END AS overspending_flag,

        CASE WHEN utilization_pct < 50
            THEN 1 ELSE 0 END AS low_utilization_flag,

        CASE WHEN operating_expenditure < 0
            THEN 1 ELSE 0 END AS negative_operating_flag,

        CASE WHEN development_expenditure < 0
            THEN 1 ELSE 0 END AS negative_development_flag,

        CASE WHEN budget_variance > 0
            THEN 1 ELSE 0 END AS positive_variance_flag
    FROM ministry_flags
)
SELECT
    ministry_id,
    ministry_name,
    ROUND(total_budget::numeric, 4) AS total_budget,
    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,
    ROUND(budget_variance::numeric, 4) AS budget_variance,
    utilization_pct,
    overspending_flag,
    low_utilization_flag,
    negative_operating_flag,
    negative_development_flag,
    positive_variance_flag,
    (
        overspending_flag
        + low_utilization_flag
        + negative_operating_flag
        + negative_development_flag
    ) AS review_flag_count
FROM review_flags
WHERE overspending_flag = 1
   OR low_utilization_flag = 1
   OR negative_operating_flag = 1
   OR negative_development_flag = 1
ORDER BY
    review_flag_count DESC,
    ABS(budget_variance) DESC,
    ministry_id;


-- 19.5.6 Data Quality & Component Reconciliation Validation

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT ministry_id) AS distinct_ministries,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
    ) AS missing_budget,

    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
    ) AS missing_actual,

    COUNT(*) FILTER (
        WHERE operating_expenditure IS NULL
    ) AS missing_operating,

    COUNT(*) FILTER (
        WHERE development_expenditure IS NULL
    ) AS missing_development,

    COUNT(*) FILTER (
        WHERE budget_variance IS NULL
           OR ABS(
               budget_variance
               - (total_budget - actual_expenditure)
           ) > 0.0001
    ) AS variance_mismatch_count,

    COUNT(*) FILTER (
        WHERE ABS(
            operating_expenditure
            + development_expenditure
            - actual_expenditure
        ) > 0.001
    ) AS component_mismatch_over_tolerance,

    COUNT(*) FILTER (
        WHERE operating_expenditure < 0
    ) AS negative_operating_count,

    COUNT(*) FILTER (
        WHERE development_expenditure < 0
    ) AS negative_development_count,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT ministry_id) = 62
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR operating_expenditure IS NULL
                OR development_expenditure IS NULL
                OR budget_variance IS NULL
                OR ABS(
                    budget_variance
                    - (total_budget - actual_expenditure)
                ) > 0.0001
         ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM analytics.fact_ministry_budget;


-- END OF STEP 19.5