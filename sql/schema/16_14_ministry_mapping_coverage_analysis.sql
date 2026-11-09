-- ============================================================
-- STEP 16.14: MINISTRY MAPPING COVERAGE ANALYSIS
-- Project: Government Budget Analytics
-- Read-only analysis
-- ============================================================


-- 16.14.1 OVERALL MINISTRY MAPPING COVERAGE

WITH mapping_summary AS (
    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total,
        BOOL_AND(
            mapping_source IS NOT NULL
            AND BTRIM(mapping_source) <> ''
        ) AS has_source,
        COUNT(*) FILTER (
            WHERE mapping_status = 'approved'
        ) AS approved_count
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
    GROUP BY ministry_id
),
ministry_status AS (
    SELECT
        m.ministry_id,
        CASE
            WHEN ms.ministry_id IS NOT NULL
             AND ABS(ms.allocation_total - 100) <= 0.0001
             AND ms.has_source
            THEN 'FULLY MAPPED'
            ELSE 'UNMAPPED OR INCOMPLETE'
        END AS mapping_status
    FROM analytics.dim_ministry m
    LEFT JOIN mapping_summary ms
        ON m.ministry_id = ms.ministry_id
)
SELECT
    mapping_status,
    COUNT(*) AS ministry_count,
    ROUND(
        COUNT(*)::numeric
        / NULLIF(SUM(COUNT(*)) OVER (), 0) * 100,
        2
    ) AS coverage_pct
FROM ministry_status
GROUP BY mapping_status
ORDER BY mapping_status;


-- 16.14.2 SECTOR-WISE MINISTRY COVERAGE

SELECT
    s.sector_name,
    COUNT(DISTINCT b.ministry_id) AS mapped_ministry_count,
    ROUND(SUM(b.allocation_share), 4)
        AS total_allocation_share
FROM analytics.dim_sector s
LEFT JOIN analytics.bridge_ministry_sector b
    ON s.sector_id = b.sector_id
   AND b.mapping_status = 'approved'
GROUP BY s.sector_id, s.sector_name
ORDER BY mapped_ministry_count DESC, s.sector_name;


-- 16.14.3 UNMAPPED OR INCOMPLETE MINISTRY LIST

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
    m.ministry_code,
    m.ministry_name,
    CASE
        WHEN ms.ministry_id IS NULL
            THEN 'NO APPROVED MAPPING'
        WHEN ABS(ms.allocation_total - 100) > 0.0001
            THEN 'ALLOCATION INCOMPLETE'
        WHEN NOT ms.has_source
            THEN 'SOURCE EVIDENCE MISSING'
        ELSE 'FULLY MAPPED'
    END AS mapping_status
FROM analytics.dim_ministry m
LEFT JOIN mapping_summary ms
    ON m.ministry_id = ms.ministry_id
WHERE ms.ministry_id IS NULL
   OR ABS(ms.allocation_total - 100) > 0.0001
   OR NOT COALESCE(ms.has_source, FALSE)
ORDER BY m.ministry_code;


-- 16.14.4 FINANCIAL COVERAGE BY MAPPING STATUS

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
classified AS (
    SELECT
        f.total_budget,
        f.actual_expenditure,
        CASE
            WHEN ms.ministry_id IS NOT NULL
             AND ABS(ms.allocation_total - 100) <= 0.0001
             AND ms.has_source
            THEN 'FULLY MAPPED'
            ELSE 'UNMAPPED OR INCOMPLETE'
        END AS mapping_status
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    LEFT JOIN mapping_summary ms
        ON f.ministry_id = ms.ministry_id
)
SELECT
    mapping_status,
    COUNT(*) AS ministry_fact_rows,
    ROUND(SUM(total_budget), 4) AS total_budget,
    ROUND(SUM(actual_expenditure), 4) AS actual_expenditure
FROM classified
GROUP BY mapping_status
ORDER BY mapping_status;


-- 16.14.5 MAPPING SOURCE COVERAGE

SELECT
    mapping_source,
    COUNT(DISTINCT ministry_id) AS ministry_count,
    COUNT(*) AS mapping_rows
FROM analytics.bridge_ministry_sector
WHERE mapping_status = 'approved'
GROUP BY mapping_source
ORDER BY ministry_count DESC;


-- ============================================================
-- END OF STEP 16.14
-- ============================================================