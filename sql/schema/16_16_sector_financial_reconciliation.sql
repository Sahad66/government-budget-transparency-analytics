-- ============================================================
-- STEP 16.16: SECTOR FINANCIAL RECONCILIATION
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 16.16.1 APPROVED MINISTRY ALLOCATION VALIDATION
SELECT
    m.ministry_code,
    m.ministry_name,
    ROUND(SUM(b.allocation_share)::numeric, 4)
        AS approved_allocation_pct
FROM analytics.dim_ministry m
JOIN analytics.bridge_ministry_sector b
    ON m.ministry_id = b.ministry_id
WHERE LOWER(b.mapping_status) = 'approved'
GROUP BY
    m.ministry_id,
    m.ministry_code,
    m.ministry_name
HAVING ROUND(SUM(b.allocation_share)::numeric, 4) <> 100
ORDER BY m.ministry_code;


-- 16.16.2 SECTOR VIEW VS BASE TABLE RECONCILIATION
WITH base_sector AS (
    SELECT
        s.sector_name,
        COUNT(DISTINCT m.ministry_id) AS ministry_count,

        SUM(
            f.total_budget
            * b.allocation_share / 100.0
        ) AS total_budget,

        SUM(
            f.actual_expenditure
            * b.allocation_share / 100.0
        ) AS actual_expenditure

    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    JOIN analytics.bridge_ministry_sector b
        ON m.ministry_id = b.ministry_id
    JOIN analytics.dim_sector s
        ON b.sector_id = s.sector_id

    WHERE LOWER(b.mapping_status) = 'approved'

    GROUP BY s.sector_name
)

SELECT
    COALESCE(b.sector_name, v.sector_name) AS sector_name,

    COALESCE(b.ministry_count, 0) AS base_ministry_count,
    COALESCE(v.ministry_count, 0) AS view_ministry_count,

    ROUND(
        (COALESCE(b.total_budget, 0)
        - COALESCE(v.total_budget, 0))::numeric,
        4
    ) AS budget_difference,

    ROUND(
        (COALESCE(b.actual_expenditure, 0)
        - COALESCE(v.actual_expenditure, 0))::numeric,
        4
    ) AS actual_difference,

    CASE
        WHEN b.sector_name IS NOT NULL
         AND v.sector_name IS NOT NULL
         AND b.ministry_count = v.ministry_count
         AND ABS(COALESCE(b.total_budget, 0)
             - COALESCE(v.total_budget, 0)) < 0.0001
         AND ABS(COALESCE(b.actual_expenditure, 0)
             - COALESCE(v.actual_expenditure, 0)) < 0.0001
        THEN 'PASS'
        ELSE 'REVIEW'
    END AS reconciliation_status

FROM base_sector b
FULL OUTER JOIN analytics.vw_sector_financial_summary v
    ON b.sector_name = v.sector_name

ORDER BY sector_name;


-- 16.16.3 MAPPED MINISTRY VS SECTOR SUMMARY TOTAL
WITH mapped_ministry AS (
    SELECT
        SUM(
            f.total_budget * b.allocation_share / 100.0
        ) AS mapped_budget,

        SUM(
            f.actual_expenditure * b.allocation_share / 100.0
        ) AS mapped_actual

    FROM analytics.fact_ministry_budget f
    JOIN analytics.bridge_ministry_sector b
        ON f.ministry_id = b.ministry_id

    WHERE LOWER(b.mapping_status) = 'approved'
),

sector_total AS (
    SELECT
        SUM(total_budget) AS sector_budget,
        SUM(actual_expenditure) AS sector_actual
    FROM analytics.vw_sector_financial_summary
)

SELECT
    ROUND(mapped_budget::numeric, 4) AS mapped_ministry_budget,
    ROUND(sector_budget::numeric, 4) AS sector_summary_budget,

    ROUND(
        (mapped_budget - sector_budget)::numeric,
        4
    ) AS budget_difference,

    ROUND(mapped_actual::numeric, 4) AS mapped_ministry_actual,
    ROUND(sector_actual::numeric, 4) AS sector_summary_actual,

    ROUND(
        (mapped_actual - sector_actual)::numeric,
        4
    ) AS actual_difference,

    CASE
        WHEN ABS(mapped_budget - sector_budget) < 0.0001
         AND ABS(mapped_actual - sector_actual) < 0.0001
        THEN 'PASS'
        ELSE 'REVIEW'
    END AS reconciliation_status

FROM mapped_ministry
CROSS JOIN sector_total;


-- 16.16.4 TOTAL MINISTRY BUDGET RECONCILIATION
WITH ministry_totals AS (
    SELECT
        SUM(f.total_budget) AS overall_budget,
        SUM(f.actual_expenditure) AS overall_actual
    FROM analytics.fact_ministry_budget f
),

mapped_totals AS (
    SELECT
        SUM(f.total_budget) AS mapped_budget,
        SUM(f.actual_expenditure) AS mapped_actual
    FROM analytics.fact_ministry_budget f
    WHERE EXISTS (
        SELECT 1
        FROM analytics.bridge_ministry_sector b
        WHERE b.ministry_id = f.ministry_id
          AND LOWER(b.mapping_status) = 'approved'
    )
),

unmapped_totals AS (
    SELECT
        SUM(f.total_budget) AS unmapped_budget,
        SUM(f.actual_expenditure) AS unmapped_actual
    FROM analytics.fact_ministry_budget f
    WHERE NOT EXISTS (
        SELECT 1
        FROM analytics.bridge_ministry_sector b
        WHERE b.ministry_id = f.ministry_id
          AND LOWER(b.mapping_status) = 'approved'
    )
)

SELECT
    ROUND(t.overall_budget::numeric, 4) AS overall_budget,
    ROUND(m.mapped_budget::numeric, 4) AS mapped_budget,
    ROUND(u.unmapped_budget::numeric, 4) AS unmapped_budget,

    ROUND(
        (t.overall_budget - m.mapped_budget
         - u.unmapped_budget)::numeric,
        4
    ) AS budget_difference,

    ROUND(t.overall_actual::numeric, 4) AS overall_actual,
    ROUND(m.mapped_actual::numeric, 4) AS mapped_actual,
    ROUND(u.unmapped_actual::numeric, 4) AS unmapped_actual,

    ROUND(
        (t.overall_actual - m.mapped_actual
         - u.unmapped_actual)::numeric,
        4
    ) AS actual_difference

FROM ministry_totals t
CROSS JOIN mapped_totals m
CROSS JOIN unmapped_totals u;


-- 16.16.5 DUPLICATE MINISTRY-YEAR VALIDATION
SELECT
    m.ministry_code,
    m.ministry_name,
    f.fiscal_year_id,
    COUNT(*) AS duplicate_count

FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id

GROUP BY
    m.ministry_code,
    m.ministry_name,
    f.fiscal_year_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- 16.16.6 FINAL RECONCILIATION STATUS
WITH allocation_check AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT ministry_id
        FROM analytics.bridge_ministry_sector
        WHERE LOWER(mapping_status) = 'approved'
        GROUP BY ministry_id
        HAVING ABS(SUM(allocation_share) - 100) >= 0.0001
    ) q
),

duplicate_check AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT ministry_id, fiscal_year_id
        FROM analytics.fact_ministry_budget
        GROUP BY ministry_id, fiscal_year_id
        HAVING COUNT(*) > 1
    ) q
),

financial_check AS (
    SELECT
        SUM(f.total_budget) AS overall_budget,
        SUM(f.actual_expenditure) AS overall_actual,

        SUM(
            CASE WHEN EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND LOWER(b.mapping_status) = 'approved'
            )
            THEN f.total_budget ELSE 0 END
        ) AS mapped_budget,

        SUM(
            CASE WHEN NOT EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND LOWER(b.mapping_status) = 'approved'
            )
            THEN f.total_budget ELSE 0 END
        ) AS unmapped_budget,

        SUM(
            CASE WHEN EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND LOWER(b.mapping_status) = 'approved'
            )
            THEN f.actual_expenditure ELSE 0 END
        ) AS mapped_actual,

        SUM(
            CASE WHEN NOT EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND LOWER(b.mapping_status) = 'approved'
            )
            THEN f.actual_expenditure ELSE 0 END
        ) AS unmapped_actual

    FROM analytics.fact_ministry_budget f
)

SELECT
    a.issue_count AS allocation_issues,
    d.issue_count AS duplicate_issues,

    ROUND(
        (f.overall_budget - f.mapped_budget
         - f.unmapped_budget)::numeric,
        4
    ) AS budget_difference,

    ROUND(
        (f.overall_actual - f.mapped_actual
         - f.unmapped_actual)::numeric,
        4
    ) AS actual_difference,

    CASE
        WHEN a.issue_count = 0
         AND d.issue_count = 0
         AND ABS(f.overall_budget - f.mapped_budget
             - f.unmapped_budget) < 0.0001
         AND ABS(f.overall_actual - f.mapped_actual
             - f.unmapped_actual) < 0.0001
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS final_reconciliation_status

FROM allocation_check a
CROSS JOIN duplicate_check d
CROSS JOIN financial_check f;
