-- ============================================================
-- STEP 16.15: UNMAPPED MINISTRY FINANCIAL IMPACT ANALYSIS
-- Unit: BDT Crore
-- Read-only analysis
-- ============================================================

-- 16.15.1 UNMAPPED MINISTRY FINANCIAL IMPACT SUMMARY

WITH approved_mapping AS (
    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total,
        BOOL_AND(
            mapping_source IS NOT NULL
            AND BTRIM(mapping_source) <> ''
        ) AS has_source
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
    GROUP BY ministry_id
),
fully_mapped AS (
    SELECT ministry_id
    FROM approved_mapping
    WHERE ABS(allocation_total - 100) <= 0.0001
      AND has_source
),
financial_summary AS (
    SELECT
        COUNT(*) AS total_ministries,
        COUNT(*) FILTER (
            WHERE fm.ministry_id IS NOT NULL
        ) AS mapped_ministries,
        COUNT(*) FILTER (
            WHERE fm.ministry_id IS NULL
        ) AS unmapped_ministries,

        SUM(f.total_budget) AS total_budget,
        SUM(f.actual_expenditure) AS total_actual,

        SUM(f.total_budget) FILTER (
            WHERE fm.ministry_id IS NULL
        ) AS unmapped_budget,

        SUM(f.actual_expenditure) FILTER (
            WHERE fm.ministry_id IS NULL
        ) AS unmapped_actual

    FROM analytics.fact_ministry_budget f
    LEFT JOIN fully_mapped fm
        ON f.ministry_id = fm.ministry_id
)
SELECT
    total_ministries,
    mapped_ministries,
    unmapped_ministries,

    ROUND(total_budget, 4) AS total_budget,
    ROUND(unmapped_budget, 4) AS unmapped_budget,

    ROUND(
        unmapped_budget
        / NULLIF(total_budget, 0) * 100, 4
    ) AS unmapped_budget_pct,

    ROUND(total_actual, 4) AS total_actual,
    ROUND(unmapped_actual, 4) AS unmapped_actual,

    ROUND(
        unmapped_actual
        / NULLIF(total_actual, 0) * 100, 4
    ) AS unmapped_actual_pct

FROM financial_summary;


-- 16.15.2 TOP 10 UNMAPPED MINISTRIES BY BUDGET

WITH approved_mapping AS (
    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total,
        BOOL_AND(
            mapping_source IS NOT NULL
            AND BTRIM(mapping_source) <> ''
        ) AS has_source
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
    GROUP BY ministry_id
),
fully_mapped AS (
    SELECT ministry_id
    FROM approved_mapping
    WHERE ABS(allocation_total - 100) <= 0.0001
      AND has_source
)
SELECT
    m.ministry_code,
    m.ministry_name,
    ROUND(f.total_budget, 4) AS total_budget,
    ROUND(f.actual_expenditure, 4) AS actual_expenditure,
    ROUND(
        f.total_budget - f.actual_expenditure, 4
    ) AS budget_variance,
    ROUND(
        f.actual_expenditure
        / NULLIF(f.total_budget, 0) * 100, 4
    ) AS utilization_pct

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id
LEFT JOIN fully_mapped fm
    ON f.ministry_id = fm.ministry_id
WHERE fm.ministry_id IS NULL
ORDER BY f.total_budget DESC
LIMIT 10;


-- 16.15.3 TOP 10 UNMAPPED MINISTRIES BY ACTUAL EXPENDITURE

WITH approved_mapping AS (
    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total,
        BOOL_AND(
            mapping_source IS NOT NULL
            AND BTRIM(mapping_source) <> ''
        ) AS has_source
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
    GROUP BY ministry_id
),
fully_mapped AS (
    SELECT ministry_id
    FROM approved_mapping
    WHERE ABS(allocation_total - 100) <= 0.0001
      AND has_source
)
SELECT
    m.ministry_code,
    m.ministry_name,
    ROUND(f.actual_expenditure, 4) AS actual_expenditure,
    ROUND(f.total_budget, 4) AS total_budget,
    ROUND(
        f.actual_expenditure
        / NULLIF(f.total_budget, 0) * 100, 4
    ) AS utilization_pct

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id
LEFT JOIN fully_mapped fm
    ON f.ministry_id = fm.ministry_id
WHERE fm.ministry_id IS NULL
ORDER BY f.actual_expenditure DESC
LIMIT 10;


-- 16.15.4 MAPPED VS UNMAPPED FINANCIAL COVERAGE

WITH approved_mapping AS (
    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total,
        BOOL_AND(
            mapping_source IS NOT NULL
            AND BTRIM(mapping_source) <> ''
        ) AS has_source
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
    GROUP BY ministry_id
),
fully_mapped AS (
    SELECT ministry_id
    FROM approved_mapping
    WHERE ABS(allocation_total - 100) <= 0.0001
      AND has_source
)
SELECT
    CASE
        WHEN fm.ministry_id IS NOT NULL THEN 'MAPPED'
        ELSE 'UNMAPPED'
    END AS mapping_status,

    COUNT(*) AS ministry_count,

    ROUND(SUM(f.total_budget), 4) AS total_budget,

    ROUND(
        SUM(f.total_budget)
        / NULLIF(
            SUM(SUM(f.total_budget)) OVER (), 0
        ) * 100, 4
    ) AS budget_share_pct,

    ROUND(SUM(f.actual_expenditure), 4) AS actual_expenditure,

    ROUND(
        SUM(f.actual_expenditure)
        / NULLIF(
            SUM(SUM(f.actual_expenditure)) OVER (), 0
        ) * 100, 4
    ) AS expenditure_share_pct

FROM analytics.fact_ministry_budget f
LEFT JOIN fully_mapped fm
    ON f.ministry_id = fm.ministry_id
GROUP BY mapping_status
ORDER BY mapping_status;


-- 16.15.5 SECTOR ANALYSIS COVERAGE LIMITATION

WITH totals AS (
    SELECT
        SUM(total_budget) AS total_budget,
        SUM(actual_expenditure) AS total_actual
    FROM analytics.fact_ministry_budget
),
mapped AS (
    SELECT
        SUM(total_budget) AS mapped_budget,
        SUM(actual_expenditure) AS mapped_actual
    FROM analytics.vw_sector_financial_summary
)
SELECT
    ROUND(t.total_budget, 4) AS overall_budget,
    ROUND(m.mapped_budget, 4) AS sector_analyzed_budget,

    ROUND(
        m.mapped_budget / NULLIF(t.total_budget, 0) * 100, 4
    ) AS budget_coverage_pct,

    ROUND(
        100 - (
            m.mapped_budget / NULLIF(t.total_budget, 0) * 100
        ), 4
    ) AS budget_outside_sector_analysis_pct,

    ROUND(t.total_actual, 4) AS overall_actual,
    ROUND(m.mapped_actual, 4) AS sector_analyzed_actual,

    ROUND(
        m.mapped_actual / NULLIF(t.total_actual, 0) * 100, 4
    ) AS actual_coverage_pct,

    ROUND(
        100 - (
            m.mapped_actual / NULLIF(t.total_actual, 0) * 100
        ), 4
    ) AS actual_outside_sector_analysis_pct

FROM totals t
CROSS JOIN mapped m;


-- 16.15.6 RECONCILIATION VALIDATION

WITH approved_mapping AS (
    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total,
        BOOL_AND(
            mapping_source IS NOT NULL
            AND BTRIM(mapping_source) <> ''
        ) AS has_source
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
    GROUP BY ministry_id
),
fully_mapped AS (
    SELECT ministry_id
    FROM approved_mapping
    WHERE ABS(allocation_total - 100) <= 0.0001
      AND has_source
),
totals AS (
    SELECT
        SUM(total_budget) AS total_budget,
        SUM(actual_expenditure) AS total_actual
    FROM analytics.fact_ministry_budget
),
mapped AS (
    SELECT
        SUM(total_budget) AS budget,
        SUM(actual_expenditure) AS actual
    FROM analytics.fact_ministry_budget f
    JOIN fully_mapped fm
        ON f.ministry_id = fm.ministry_id
),
unmapped AS (
    SELECT
        SUM(total_budget) AS budget,
        SUM(actual_expenditure) AS actual
    FROM analytics.fact_ministry_budget f
    LEFT JOIN fully_mapped fm
        ON f.ministry_id = fm.ministry_id
    WHERE fm.ministry_id IS NULL
)
SELECT
    ROUND(t.total_budget - m.budget - u.budget, 4)
        AS budget_difference,

    ROUND(t.total_actual - m.actual - u.actual, 4)
        AS actual_difference,

    CASE
        WHEN ABS(t.total_budget - m.budget - u.budget) <= 0.0001
         AND ABS(t.total_actual - m.actual - u.actual) <= 0.0001
        THEN 'PASS'
        ELSE 'REVIEW'
    END AS reconciliation_status

FROM totals t
CROSS JOIN mapped m
CROSS JOIN unmapped u;


-- ============================================================
-- END OF STEP 16.15
-- ============================================================