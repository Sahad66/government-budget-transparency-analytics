-- ============================================================
-- STEP 16.24: FINAL SECTOR ANALYSIS VALIDATION
-- Project: Government Budget Transparency & Spending Efficiency
-- Unit: BDT Crore
-- Read-only validation
-- ============================================================


-- 16.24.1 SECTOR AND MAPPING COVERAGE

SELECT
    (SELECT COUNT(*)
     FROM analytics.dim_sector) AS defined_sector_count,

    (SELECT COUNT(*)
     FROM analytics.bridge_ministry_sector
     WHERE mapping_status = 'approved') AS approved_mapping_count,

    (SELECT COUNT(DISTINCT ministry_id)
     FROM analytics.bridge_ministry_sector
     WHERE mapping_status = 'approved') AS mapped_ministry_count,

    (SELECT COUNT(*)
     FROM analytics.dim_ministry) AS total_ministry_count,

    (SELECT COUNT(*)
     FROM analytics.dim_ministry m
     WHERE NOT EXISTS (
         SELECT 1
         FROM analytics.bridge_ministry_sector b
         WHERE b.ministry_id = m.ministry_id
           AND b.mapping_status = 'approved'
     )) AS unmapped_ministry_count;


-- 16.24.2 APPROVED MAPPING QUALITY

SELECT
    COUNT(*) AS approved_mapping_count,

    COUNT(*) FILTER (
        WHERE allocation_share IS NULL
           OR allocation_share <> 100
    ) AS allocation_issues,

    COUNT(*) FILTER (
        WHERE mapping_source IS NULL
           OR BTRIM(mapping_source) = ''
    ) AS missing_source_count,

    COUNT(*) FILTER (
        WHERE mapping_status <> 'approved'
    ) AS invalid_status_count,

    CASE
        WHEN COUNT(*) = 13
         AND COUNT(*) FILTER (
             WHERE allocation_share IS NULL
                OR allocation_share <> 100
                OR mapping_source IS NULL
                OR BTRIM(mapping_source) = ''
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS mapping_quality_status

FROM analytics.bridge_ministry_sector
WHERE mapping_status = 'approved';


-- 16.24.3 SECTOR FINANCIAL SUMMARY VALIDATION

SELECT
    COUNT(*) AS analyzed_sector_count,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
           OR actual_expenditure IS NULL
           OR operating_expenditure IS NULL
           OR development_expenditure IS NULL
    ) AS missing_financial_metrics,

    COUNT(*) FILTER (
        WHERE total_budget <= 0
           OR actual_expenditure < 0
           OR operating_expenditure < 0
           OR development_expenditure < 0
    ) AS invalid_financial_records,

    CASE
        WHEN COUNT(*) = 5
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR operating_expenditure IS NULL
                OR development_expenditure IS NULL
                OR total_budget <= 0
                OR actual_expenditure < 0
                OR operating_expenditure < 0
                OR development_expenditure < 0
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS sector_summary_status

FROM analytics.vw_sector_financial_summary;


-- 16.24.4 MAPPED AND UNMAPPED FINANCIAL RECONCILIATION

WITH ministry_totals AS (
    SELECT
        COUNT(*) AS ministry_record_count,

        COUNT(*) FILTER (
            WHERE EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND b.mapping_status = 'approved'
            )
        ) AS mapped_record_count,

        SUM(f.total_budget) AS total_budget,
        SUM(f.actual_expenditure) AS total_actual,

        SUM(f.total_budget) FILTER (
            WHERE EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND b.mapping_status = 'approved'
            )
        ) AS mapped_budget,

        SUM(f.actual_expenditure) FILTER (
            WHERE EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND b.mapping_status = 'approved'
            )
        ) AS mapped_actual

    FROM analytics.fact_ministry_budget f
),

sector_totals AS (
    SELECT
        SUM(total_budget) AS sector_budget,
        SUM(actual_expenditure) AS sector_actual
    FROM analytics.vw_sector_financial_summary
)

SELECT
    mt.ministry_record_count,
    mt.mapped_record_count,

    mt.ministry_record_count - mt.mapped_record_count
        AS unmapped_record_count,

    ROUND(mt.total_budget::numeric, 4)
        AS total_ministry_budget,

    ROUND(mt.mapped_budget::numeric, 4)
        AS mapped_ministry_budget,

    ROUND(
        (mt.total_budget - mt.mapped_budget)::numeric, 4
    ) AS unmapped_ministry_budget,

    ROUND(st.sector_budget::numeric, 4)
        AS sector_budget,

    ROUND(
        (st.sector_budget - mt.mapped_budget)::numeric, 4
    ) AS budget_difference,

    ROUND(mt.total_actual::numeric, 4)
        AS total_ministry_actual,

    ROUND(mt.mapped_actual::numeric, 4)
        AS mapped_ministry_actual,

    ROUND(
        (mt.total_actual - mt.mapped_actual)::numeric, 4
    ) AS unmapped_ministry_actual,

    ROUND(st.sector_actual::numeric, 4)
        AS sector_actual,

    ROUND(
        (st.sector_actual - mt.mapped_actual)::numeric, 4
    ) AS actual_difference,

    CASE
        WHEN ABS(st.sector_budget - mt.mapped_budget) <= 0.001
         AND ABS(st.sector_actual - mt.mapped_actual) <= 0.001
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS financial_reconciliation_status

FROM ministry_totals mt
CROSS JOIN sector_totals st;


-- 16.24.5 OPERATING AND DEVELOPMENT RECONCILIATION

SELECT
    COUNT(*) AS sector_count,

    COUNT(*) FILTER (
        WHERE ABS(
            actual_expenditure
            - operating_expenditure
            - development_expenditure
        ) > 0.001
    ) AS component_mismatch_count,

    ROUND(
        SUM(actual_expenditure)::numeric, 4
    ) AS total_actual_expenditure,

    ROUND(
        SUM(operating_expenditure)::numeric, 4
    ) AS total_operating_expenditure,

    ROUND(
        SUM(development_expenditure)::numeric, 4
    ) AS total_development_expenditure,

    ROUND(
        (
            SUM(actual_expenditure)
            - SUM(operating_expenditure)
            - SUM(development_expenditure)
        )::numeric, 4
    ) AS total_component_difference,

    CASE
        WHEN COUNT(*) = 5
         AND COUNT(*) FILTER (
             WHERE ABS(
                 actual_expenditure
                 - operating_expenditure
                 - development_expenditure
             ) > 0.001
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS component_reconciliation_status

FROM analytics.vw_sector_financial_summary;


-- 16.24.6 DUPLICATE MINISTRY-YEAR VALIDATION

SELECT
    COUNT(*) AS duplicate_group_count

FROM (
    SELECT
        ministry_id,
        fiscal_year_id

    FROM analytics.fact_ministry_budget

    GROUP BY ministry_id, fiscal_year_id

    HAVING COUNT(*) > 1
) duplicates;


-- 16.24.7 FINAL STEP 16 VALIDATION STATUS

WITH mapping_metrics AS (
    SELECT
        COUNT(*) AS approved_mapping_count,

        COUNT(*) FILTER (
            WHERE allocation_share <> 100
               OR mapping_source IS NULL
               OR BTRIM(mapping_source) = ''
        ) AS mapping_issue_count,

        COUNT(DISTINCT ministry_id) AS mapped_ministry_count

    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
),

sector_metrics AS (
    SELECT
        COUNT(*) AS sector_count,

        COUNT(*) FILTER (
            WHERE total_budget IS NULL
               OR actual_expenditure IS NULL
               OR operating_expenditure IS NULL
               OR development_expenditure IS NULL
               OR total_budget <= 0
               OR actual_expenditure < 0
               OR operating_expenditure < 0
               OR development_expenditure < 0
        ) AS sector_quality_issue_count,

        SUM(total_budget) AS sector_budget,
        SUM(actual_expenditure) AS sector_actual,

        COUNT(*) FILTER (
            WHERE ABS(
                actual_expenditure
                - operating_expenditure
                - development_expenditure
            ) > 0.001
        ) AS component_issue_count

    FROM analytics.vw_sector_financial_summary
),

ministry_metrics AS (
    SELECT
        COUNT(*) AS ministry_count,

        SUM(total_budget) AS total_budget,
        SUM(actual_expenditure) AS total_actual,

        SUM(total_budget) FILTER (
            WHERE EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND b.mapping_status = 'approved'
            )
        ) AS mapped_budget,

        SUM(actual_expenditure) FILTER (
            WHERE EXISTS (
                SELECT 1
                FROM analytics.bridge_ministry_sector b
                WHERE b.ministry_id = f.ministry_id
                  AND b.mapping_status = 'approved'
            )
        ) AS mapped_actual

    FROM analytics.fact_ministry_budget f
),

duplicate_metrics AS (
    SELECT COUNT(*) AS duplicate_count
    FROM (
        SELECT ministry_id, fiscal_year_id
        FROM analytics.fact_ministry_budget
        GROUP BY ministry_id, fiscal_year_id
        HAVING COUNT(*) > 1
    ) d
)

SELECT
    mm.approved_mapping_count,
    mm.mapped_ministry_count,
    sm.sector_count,
    fm.ministry_count,

    dm.duplicate_count,

    CASE
        WHEN mm.approved_mapping_count = 13
         AND mm.mapped_ministry_count = 13
         AND sm.sector_count = 5
         AND fm.ministry_count = 62
         AND mm.mapping_issue_count = 0
         AND sm.sector_quality_issue_count = 0
         AND sm.component_issue_count = 0
         AND dm.duplicate_count = 0
         AND ABS(sm.sector_budget - fm.mapped_budget) <= 0.001
         AND ABS(sm.sector_actual - fm.mapped_actual) <= 0.001
        THEN 'STEP 16 VALIDATION PASSED'
        ELSE 'REVIEW REQUIRED'
    END AS final_step_16_status

FROM mapping_metrics mm
CROSS JOIN sector_metrics sm
CROSS JOIN ministry_metrics fm
CROSS JOIN duplicate_metrics dm;
