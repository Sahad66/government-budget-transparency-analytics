-- ============================================================
-- STEP 16.13: ANALYTICAL COMPLETENESS VALIDATION
-- Read-only validation
-- Unit: BDT Crore
-- ============================================================


-- 16.13.1 SECTOR COVERAGE
SELECT
    d.sector_name,
    COALESCE(v.ministry_count, 0) AS ministry_count,
    v.total_budget,
    v.actual_expenditure,
    CASE
        WHEN v.sector_name IS NULL THEN 'NO FINANCIAL DATA'
        WHEN v.total_budget IS NULL
          OR v.actual_expenditure IS NULL THEN 'INCOMPLETE'
        ELSE 'AVAILABLE'
    END AS analytical_status
FROM analytics.dim_sector d
LEFT JOIN analytics.vw_sector_financial_summary v
    ON d.sector_name = v.sector_name
ORDER BY d.sector_name;


-- 16.13.2 SECTOR COUNT AND DATA COVERAGE
SELECT
    (SELECT COUNT(*)
     FROM analytics.dim_sector) AS defined_sectors,

    (SELECT COUNT(*)
     FROM analytics.vw_sector_financial_summary) AS analyzed_sectors,

    (SELECT COUNT(*)
     FROM analytics.dim_sector d
     JOIN analytics.vw_sector_financial_summary v
       ON d.sector_name = v.sector_name) AS sectors_with_data;


-- 16.13.3 FULLY MAPPED MINISTRIES
WITH mapping_summary AS (
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
)
SELECT
    COUNT(*) AS total_ministries,
    COUNT(*) FILTER (
        WHERE ms.ministry_id IS NOT NULL
          AND ABS(ms.allocation_total - 100) <= 0.0001
          AND ms.has_source
    ) AS fully_mapped_ministries,
    COUNT(*) FILTER (
        WHERE ms.ministry_id IS NULL
           OR ABS(ms.allocation_total - 100) > 0.0001
           OR NOT COALESCE(ms.has_source, FALSE)
    ) AS unmapped_or_incomplete_ministries
FROM analytics.dim_ministry m
LEFT JOIN mapping_summary ms
    ON m.ministry_id = ms.ministry_id;


-- 16.13.4 MAPPED VS UNMAPPED FINANCIAL TOTALS
WITH mapping_summary AS (
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
    FROM mapping_summary
    WHERE ABS(allocation_total - 100) <= 0.0001
      AND has_source
),
overall_totals AS (
    SELECT
        SUM(total_budget) AS total_budget,
        SUM(actual_expenditure) AS actual_expenditure
    FROM analytics.fact_ministry_budget
),
mapped_totals AS (
    SELECT
        SUM(total_budget) AS total_budget,
        SUM(actual_expenditure) AS actual_expenditure
    FROM analytics.vw_sector_financial_summary
),
unmapped_totals AS (
    SELECT
        SUM(f.total_budget) AS total_budget,
        SUM(f.actual_expenditure) AS actual_expenditure
    FROM analytics.fact_ministry_budget f
    LEFT JOIN fully_mapped fm
        ON f.ministry_id = fm.ministry_id
    WHERE fm.ministry_id IS NULL
)
SELECT
    ROUND(o.total_budget, 4) AS overall_budget,
    ROUND(m.total_budget, 4) AS mapped_budget,
    ROUND(u.total_budget, 4) AS unmapped_budget,

    ROUND(o.actual_expenditure, 4) AS overall_actual,
    ROUND(m.actual_expenditure, 4) AS mapped_actual,
    ROUND(u.actual_expenditure, 4) AS unmapped_actual,

    ROUND(
        o.total_budget - m.total_budget - u.total_budget, 4
    ) AS budget_reconciliation_difference,

    ROUND(
        o.actual_expenditure
        - m.actual_expenditure
        - u.actual_expenditure, 4
    ) AS actual_reconciliation_difference

FROM overall_totals o
CROSS JOIN mapped_totals m
CROSS JOIN unmapped_totals u;


-- 16.13.5 SECTOR BUDGET AND EXPENDITURE CONTRIBUTION
SELECT
    sector_name,

    ROUND(
        total_budget
        / NULLIF(SUM(total_budget) OVER (), 0) * 100,
        4
    ) AS mapped_budget_share_pct,

    ROUND(
        actual_expenditure
        / NULLIF(SUM(actual_expenditure) OVER (), 0) * 100,
        4
    ) AS mapped_expenditure_share_pct

FROM analytics.vw_sector_financial_summary
ORDER BY total_budget DESC;


-- 16.13.6 ANALYTICAL COMPLETENESS STATUS
WITH sector_check AS (
    SELECT
        COUNT(*) AS defined_sectors,
        COUNT(v.sector_name) AS analyzed_sectors,
        COUNT(*) FILTER (
            WHERE v.sector_name IS NULL
               OR v.total_budget IS NULL
               OR v.actual_expenditure IS NULL
        ) AS incomplete_sectors
    FROM analytics.dim_sector d
    LEFT JOIN analytics.vw_sector_financial_summary v
        ON d.sector_name = v.sector_name
)
SELECT
    defined_sectors,
    analyzed_sectors,
    incomplete_sectors,
    CASE
        WHEN defined_sectors = analyzed_sectors
         AND incomplete_sectors = 0
        THEN 'PASS: DEFINED SECTOR DATA COMPLETE'
        ELSE 'REVIEW: SECTOR DATA INCOMPLETE'
    END AS validation_status
FROM sector_check;


-- ============================================================
-- END OF STEP 16.13
-- ============================================================