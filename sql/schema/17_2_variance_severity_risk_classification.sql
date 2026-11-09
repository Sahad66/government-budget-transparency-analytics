-- ============================================================
-- STEP 17.2: VARIANCE SEVERITY & FINANCIAL RISK CLASSIFICATION
-- Unit: BDT Crore
-- Classification is exploratory, not an official audit rating.
-- ============================================================


-- 17.2.1 MINISTRY-WISE VARIANCE SEVERITY

WITH metrics AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,

        f.budget_variance
        / NULLIF(f.total_budget, 0) * 100 AS variance_pct

    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
      ON m.ministry_id = f.ministry_id
)

SELECT
    ministry_code,
    ministry_name,

    ROUND(total_budget::numeric, 4) AS total_budget,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(budget_variance::numeric, 4)
        AS budget_variance,

    ROUND(variance_pct::numeric, 4) AS variance_pct,

    CASE
        WHEN budget_variance < 0 THEN 'OVERSPENDING'
        WHEN variance_pct >= 50 THEN 'VERY HIGH VARIANCE'
        WHEN variance_pct >= 25 THEN 'HIGH VARIANCE'
        WHEN variance_pct >= 10 THEN 'MODERATE VARIANCE'
        ELSE 'LOW VARIANCE'
    END AS variance_severity

FROM metrics

ORDER BY variance_pct ASC;


-- 17.2.2 HIGHEST VARIANCE AMOUNT

SELECT
    m.ministry_name,

    ROUND(f.total_budget::numeric, 4) AS total_budget,

    ROUND(f.actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(f.budget_variance::numeric, 4)
        AS budget_variance,

    ROUND(
        (f.budget_variance
        / NULLIF(f.total_budget, 0) * 100)::numeric, 4
    ) AS variance_pct

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
  ON m.ministry_id = f.ministry_id

WHERE f.budget_variance > 0

ORDER BY f.budget_variance DESC

LIMIT 15;


-- 17.2.3 HIGHEST VARIANCE PERCENTAGE

SELECT
    m.ministry_name,

    ROUND(f.total_budget::numeric, 4) AS total_budget,

    ROUND(f.actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (f.budget_variance
        / NULLIF(f.total_budget, 0) * 100)::numeric, 4
    ) AS variance_pct

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
  ON m.ministry_id = f.ministry_id

WHERE f.budget_variance > 0

ORDER BY variance_pct DESC

LIMIT 15;


-- 17.2.4 VARIANCE SEVERITY DISTRIBUTION

WITH metrics AS (
    SELECT
        f.budget_variance,
        f.budget_variance
        / NULLIF(f.total_budget, 0) * 100 AS variance_pct

    FROM analytics.fact_ministry_budget f
)

SELECT
    CASE
        WHEN budget_variance < 0 THEN 'OVERSPENDING'
        WHEN variance_pct >= 50 THEN 'VERY HIGH VARIANCE'
        WHEN variance_pct >= 25 THEN 'HIGH VARIANCE'
        WHEN variance_pct >= 10 THEN 'MODERATE VARIANCE'
        ELSE 'LOW VARIANCE'
    END AS variance_severity,

    COUNT(*) AS ministry_count,

    ROUND(
        (COUNT(*)::numeric
        / NULLIF(SUM(COUNT(*)) OVER (), 0) * 100), 2
    ) AS ministry_share_pct

FROM metrics

GROUP BY 1

ORDER BY ministry_count DESC;


-- 17.2.5 FINANCIAL IMPACT BY VARIANCE CATEGORY

WITH metrics AS (
    SELECT
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,

        f.budget_variance
        / NULLIF(f.total_budget, 0) * 100 AS variance_pct

    FROM analytics.fact_ministry_budget f
),

classified AS (
    SELECT
        *,
        CASE
            WHEN budget_variance < 0 THEN 'OVERSPENDING'
            WHEN variance_pct >= 50 THEN 'VERY HIGH VARIANCE'
            WHEN variance_pct >= 25 THEN 'HIGH VARIANCE'
            WHEN variance_pct >= 10 THEN 'MODERATE VARIANCE'
            ELSE 'LOW VARIANCE'
        END AS variance_severity

    FROM metrics
)

SELECT
    variance_severity,

    COUNT(*) AS ministry_count,

    ROUND(SUM(total_budget)::numeric, 4)
        AS total_budget,

    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS actual_expenditure,

    ROUND(SUM(budget_variance)::numeric, 4)
        AS net_budget_variance

FROM classified

GROUP BY variance_severity

ORDER BY net_budget_variance;


-- 17.2.6 VARIANCE DATA QUALITY VALIDATION

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE budget_variance IS NULL
    ) AS missing_variance_count,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL OR total_budget <= 0
    ) AS invalid_budget_count,

    COUNT(*) FILTER (
        WHERE ABS(
            budget_variance
            - (total_budget - actual_expenditure)
        ) > 0.001
    ) AS variance_calculation_mismatch,

    COUNT(*) FILTER (
        WHERE budget_variance < 0
    ) AS overspending_record_count,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(*) FILTER (
             WHERE budget_variance IS NULL
                OR total_budget IS NULL
                OR total_budget <= 0
                OR actual_expenditure IS NULL
                OR ABS(
                    budget_variance
                    - (total_budget - actual_expenditure)
                ) > 0.001
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS variance_quality_status

FROM analytics.fact_ministry_budget;
