-- ============================================================
-- STEP 19.6: ADVANCED SQL DATA VALIDATION
-- Project: Government Budget Analytics
-- Read-only validation. No data modifications.
-- ============================================================

-- 19.6.1 Ministry-Fiscal Year grain and dimension integrity
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT f.ministry_id) AS distinct_ministries,
    COUNT(DISTINCT f.fiscal_year_id) AS distinct_fiscal_years,
    COUNT(*) FILTER (WHERE f.ministry_id IS NULL) AS missing_ministry_id,
    COUNT(*) FILTER (WHERE f.fiscal_year_id IS NULL) AS missing_fiscal_year_id,
    COUNT(*) FILTER (WHERE m.ministry_id IS NULL) AS orphan_ministry_reference,
    COUNT(*) FILTER (WHERE y.fiscal_year_id IS NULL) AS orphan_fiscal_year_reference
FROM analytics.fact_ministry_budget f
LEFT JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id
LEFT JOIN analytics.dim_fiscal_year y
    ON f.fiscal_year_id = y.fiscal_year_id;

-- Duplicate ministry-fiscal-year combinations
SELECT
    ministry_id,
    fiscal_year_id,
    COUNT(*) AS duplicate_count
FROM analytics.fact_ministry_budget
GROUP BY ministry_id, fiscal_year_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, ministry_id;


-- 19.6.2 Financial calculation validation
WITH calculated AS (
    SELECT
        f.ministry_id,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        f.total_budget - f.actual_expenditure AS calculated_variance,
        CASE
            WHEN f.total_budget > 0
            THEN (f.actual_expenditure / f.total_budget) * 100
            ELSE NULL
        END AS calculated_utilization
    FROM analytics.fact_ministry_budget f
    LEFT JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
)
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE total_budget IS NULL
    ) AS missing_budget,
    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
    ) AS missing_actual,
    COUNT(*) FILTER (
        WHERE budget_variance IS NULL
    ) AS missing_variance,
    COUNT(*) FILTER (
        WHERE total_budget <= 0
    ) AS non_positive_budget,
    COUNT(*) FILTER (
        WHERE actual_expenditure < 0
    ) AS negative_actual,
    COUNT(*) FILTER (
        WHERE ABS(budget_variance - calculated_variance) > 0.0001
    ) AS variance_mismatch_count,
    COUNT(*) FILTER (
        WHERE calculated_utilization IS NULL
    ) AS invalid_utilization_calculation,
    CASE
        WHEN COUNT(*) FILTER (
            WHERE total_budget IS NULL
               OR actual_expenditure IS NULL
               OR budget_variance IS NULL
               OR total_budget <= 0
               OR actual_expenditure < 0
               OR ABS(budget_variance - calculated_variance) > 0.0001
               OR calculated_utilization IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS financial_validation_status
FROM calculated;


-- 19.6.3 Operating and development component reconciliation
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE operating_expenditure IS NULL
    ) AS missing_operating,
    COUNT(*) FILTER (
        WHERE development_expenditure IS NULL
    ) AS missing_development,
    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
    ) AS missing_actual,
    COUNT(*) FILTER (
        WHERE ABS(
            COALESCE(operating_expenditure, 0)
            + COALESCE(development_expenditure, 0)
            - actual_expenditure
        ) > 0.001
    ) AS component_mismatch_count,
    COUNT(*) FILTER (
        WHERE operating_expenditure < 0
    ) AS negative_operating_count,
    COUNT(*) FILTER (
        WHERE development_expenditure < 0
    ) AS negative_development_count,
    CASE
        WHEN COUNT(*) FILTER (
            WHERE operating_expenditure IS NULL
               OR development_expenditure IS NULL
               OR actual_expenditure IS NULL
               OR ABS(
                    COALESCE(operating_expenditure, 0)
                    + COALESCE(development_expenditure, 0)
                    - actual_expenditure
               ) > 0.001
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS component_validation_status
FROM analytics.fact_ministry_budget;


-- 19.6.4 Source values requiring additional review
SELECT
    f.ministry_id,
    m.ministry_name,
    f.total_budget,
    f.actual_expenditure,
    f.budget_variance,
    f.operating_expenditure,
    f.development_expenditure,
    CASE
        WHEN f.operating_expenditure < 0
          OR f.development_expenditure < 0
        THEN 'NEGATIVE COMPONENT REVIEW'
        ELSE 'NO NEGATIVE COMPONENT'
    END AS component_review_status,
    CASE
        WHEN f.budget_variance < 0
        THEN 'OVERSPENDING REVIEW'
        WHEN f.budget_variance > 0
        THEN 'UNSPENT BUDGET REVIEW'
        ELSE 'FULLY UTILIZED'
    END AS variance_review_status
FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id
WHERE f.operating_expenditure < 0
   OR f.development_expenditure < 0
   OR f.budget_variance < 0
ORDER BY
    CASE
        WHEN f.operating_expenditure < 0
          OR f.development_expenditure < 0
        THEN 1
        WHEN f.budget_variance < 0
        THEN 2
        ELSE 3
    END,
    m.ministry_name;


-- 19.6.5 Final consolidated validation
WITH base AS (
    SELECT
        f.*,
        m.ministry_id AS matched_ministry_id,
        y.fiscal_year_id AS matched_fiscal_year_id
    FROM analytics.fact_ministry_budget f
    LEFT JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    LEFT JOIN analytics.dim_fiscal_year y
        ON f.fiscal_year_id = y.fiscal_year_id
),
duplicate_groups AS (
    SELECT COUNT(*) AS duplicate_group_count
    FROM (
        SELECT ministry_id, fiscal_year_id
        FROM analytics.fact_ministry_budget
        GROUP BY ministry_id, fiscal_year_id
        HAVING COUNT(*) > 1
    ) d
),
checks AS (
    SELECT
        COUNT(*) AS total_records,
        COUNT(DISTINCT ministry_id) AS distinct_ministries,
        COUNT(*) FILTER (
            WHERE matched_ministry_id IS NULL
        ) AS orphan_ministry_count,
        COUNT(*) FILTER (
            WHERE matched_fiscal_year_id IS NULL
        ) AS orphan_fiscal_year_count,
        COUNT(*) FILTER (
            WHERE total_budget IS NULL
               OR actual_expenditure IS NULL
               OR budget_variance IS NULL
               OR operating_expenditure IS NULL
               OR development_expenditure IS NULL
        ) AS missing_financial_values,
        COUNT(*) FILTER (
            WHERE total_budget <= 0
        ) AS invalid_budget_count,
        COUNT(*) FILTER (
            WHERE actual_expenditure < 0
        ) AS negative_actual_count,
        COUNT(*) FILTER (
            WHERE ABS(
                budget_variance - (total_budget - actual_expenditure)
            ) > 0.0001
        ) AS variance_mismatch_count,
        COUNT(*) FILTER (
            WHERE ABS(
                COALESCE(operating_expenditure, 0)
                + COALESCE(development_expenditure, 0)
                - actual_expenditure
            ) > 0.001
        ) AS component_mismatch_count,
        COUNT(*) FILTER (
            WHERE operating_expenditure < 0
        ) AS negative_operating_count,
        COUNT(*) FILTER (
            WHERE development_expenditure < 0
        ) AS negative_development_count
    FROM base
)
SELECT
    c.*,
    d.duplicate_group_count,
    CASE
        WHEN c.total_records = 62
         AND c.distinct_ministries = 62
         AND c.orphan_ministry_count = 0
         AND c.orphan_fiscal_year_count = 0
         AND c.missing_financial_values = 0
         AND c.invalid_budget_count = 0
         AND c.negative_actual_count = 0
         AND c.variance_mismatch_count = 0
         AND c.component_mismatch_count = 0
         AND d.duplicate_group_count = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS final_validation_status
FROM checks c
CROSS JOIN duplicate_groups d;