-- ============================================================
-- STEP 16.12: ADVANCED DATA QUALITY CHECKS
-- Project: Government Budget Transparency & Spending Efficiency
-- Unit: BDT Crore
-- Read-only validation: No data modification
-- ============================================================


-- 16.12.1 DUPLICATE MINISTRY-FISCAL YEAR RECORDS
SELECT
    fiscal_year_id,
    ministry_id,
    COUNT(*) AS duplicate_count
FROM analytics.fact_ministry_budget
GROUP BY fiscal_year_id, ministry_id
HAVING COUNT(*) > 1;


-- 16.12.2 MISSING FINANCIAL VALUES
SELECT
    ministry_budget_id,
    ministry_id,
    fiscal_year_id,
    total_budget,
    actual_expenditure,
    operating_expenditure,
    development_expenditure,
    budget_utilization_rate,
    budget_variance,
    standard_unit
FROM analytics.fact_ministry_budget
WHERE total_budget IS NULL
   OR actual_expenditure IS NULL
   OR operating_expenditure IS NULL
   OR development_expenditure IS NULL
   OR budget_utilization_rate IS NULL
   OR budget_variance IS NULL
   OR standard_unit IS NULL;


-- 16.12.3 NEGATIVE FINANCIAL VALUE REVIEW
-- Negative values are flagged for review, not automatically changed.
SELECT
    ministry_budget_id,
    ministry_id,
    total_budget,
    actual_expenditure,
    operating_expenditure,
    development_expenditure
FROM analytics.fact_ministry_budget
WHERE total_budget < 0
   OR actual_expenditure < 0
   OR operating_expenditure < 0
   OR development_expenditure < 0;


-- 16.12.4 APPROVED MAPPINGS WITHOUT SOURCE EVIDENCE
SELECT
    b.ministry_id,
    m.ministry_code,
    m.ministry_name,
    s.sector_name,
    b.mapping_status,
    b.mapping_source
FROM analytics.bridge_ministry_sector b
JOIN analytics.dim_ministry m
    ON b.ministry_id = m.ministry_id
JOIN analytics.dim_sector s
    ON b.sector_id = s.sector_id
WHERE b.mapping_status = 'approved'
  AND (
      b.mapping_source IS NULL
      OR BTRIM(b.mapping_source) = ''
  );


-- 16.12.5 APPROVED MINISTRY ALLOCATION MISMATCH
SELECT
    b.ministry_id,
    m.ministry_name,
    ROUND(SUM(b.allocation_share), 4) AS total_allocation_share
FROM analytics.bridge_ministry_sector b
JOIN analytics.dim_ministry m
    ON b.ministry_id = m.ministry_id
WHERE b.mapping_status = 'approved'
GROUP BY b.ministry_id, m.ministry_name
HAVING ABS(SUM(b.allocation_share) - 100) > 0.0001;


-- 16.12.6 APPROVED MAPPING REFERENCE CHECK
SELECT
    b.ministry_id,
    b.sector_id
FROM analytics.bridge_ministry_sector b
LEFT JOIN analytics.dim_ministry m
    ON b.ministry_id = m.ministry_id
LEFT JOIN analytics.dim_sector s
    ON b.sector_id = s.sector_id
WHERE b.mapping_status = 'approved'
  AND (
      m.ministry_id IS NULL
      OR s.sector_id IS NULL
  );


-- 16.12.7 SECTOR FINANCIAL COMPLETENESS
SELECT
    sector_name,
    ministry_count,
    total_budget,
    actual_expenditure,
    operating_expenditure,
    development_expenditure
FROM analytics.vw_sector_financial_summary
WHERE ministry_count IS NULL
   OR ministry_count <= 0
   OR total_budget IS NULL
   OR actual_expenditure IS NULL
   OR operating_expenditure IS NULL
   OR development_expenditure IS NULL;


-- 16.12.8 OPERATING + DEVELOPMENT COMPONENT VALIDATION
-- Tolerance: 0.001 BDT Crore
SELECT
    sector_name,
    ROUND(
        operating_expenditure
        + development_expenditure
        - actual_expenditure, 4
    ) AS component_difference
FROM analytics.vw_sector_financial_summary
WHERE ABS(
    operating_expenditure
    + development_expenditure
    - actual_expenditure
) > 0.001;


-- 16.12.9 MAPPING COVERAGE SUMMARY
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
coverage AS (
    SELECT
        m.ministry_id,
        CASE
            WHEN a.ministry_id IS NOT NULL
             AND ABS(a.allocation_total - 100) <= 0.0001
             AND a.has_source
            THEN 1
            ELSE 0
        END AS fully_mapped
    FROM analytics.dim_ministry m
    LEFT JOIN approved_mapping a
        ON m.ministry_id = a.ministry_id
)
SELECT
    COUNT(*) AS total_ministries,
    SUM(fully_mapped) AS fully_mapped_ministries,
    COUNT(*) - SUM(fully_mapped) AS unmapped_or_incomplete_ministries,
    ROUND(
        SUM(fully_mapped)::numeric
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS mapping_coverage_pct
FROM coverage;


-- 16.12.10 FINAL DATA QUALITY CHECK SUMMARY
SELECT
    (SELECT COUNT(*)
     FROM analytics.fact_ministry_budget) AS ministry_fact_rows,

    (SELECT COUNT(*)
     FROM analytics.dim_ministry) AS total_ministries,

    (SELECT COUNT(*)
     FROM analytics.dim_sector) AS total_sectors,

    (SELECT COUNT(*)
     FROM analytics.bridge_ministry_sector
     WHERE mapping_status = 'approved') AS approved_mapping_rows,

    (SELECT COUNT(*)
     FROM analytics.vw_sector_financial_summary) AS sector_summary_rows;


-- ============================================================
-- END OF STEP 16.12
-- ============================================================