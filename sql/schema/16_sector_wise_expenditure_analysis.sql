/* =====================================================================
   PROJECT 01: GOVERNMENT BUDGET ANALYTICS
   PHASE 4 - STEP 16: SECTOR-WISE EXPENDITURE ANALYSIS
   PostgreSQL | Steps 16.1 - 16.24

   IMPORTANT:
   1. No invented Ministry-to-Sector classification.
   2. Only approved mappings with 100% allocation are analyzed.
   3. NULL financial values are not converted to zero.
   4. Government-level and Ministry-level facts remain separate.
   5. Review mapping evidence before approving any mapping.
   ===================================================================== */


/* =====================================================================
   16.1 SOURCE STRUCTURE AND DATA VALIDATION
   ===================================================================== */

-- 16.1.1 Table row counts

SELECT 'dim_ministry' AS table_name, COUNT(*) AS total_rows
FROM analytics.dim_ministry

UNION ALL

SELECT 'fact_ministry_budget', COUNT(*)
FROM analytics.fact_ministry_budget

UNION ALL

SELECT 'dim_fiscal_year', COUNT(*)
FROM analytics.dim_fiscal_year;


-- 16.1.2 Ministry-wise source data

SELECT
    m.ministry_id,
    m.ministry_code,
    m.ministry_name,
    fy.financial_year,
    f.total_budget,
    f.actual_expenditure,
    f.operating_expenditure,
    f.development_expenditure,
    f.budget_variance,
    f.budget_utilization_rate,
    f.standard_unit
FROM analytics.fact_ministry_budget f
JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id
JOIN analytics.dim_fiscal_year fy
    ON f.fiscal_year_id = fy.fiscal_year_id
ORDER BY fy.financial_year, m.ministry_name;


-- 16.1.3 Source document metadata

SELECT
    source_document_id,
    document_name,
    report_title,
    original_unit,
    document_status,
    financial_year
FROM analytics.source_documents
ORDER BY source_document_id;


-- 16.1.4 Duplicate Ministry-Fiscal Year records

SELECT
    ministry_id,
    fiscal_year_id,
    COUNT(*) AS record_count
FROM analytics.fact_ministry_budget
GROUP BY ministry_id, fiscal_year_id
HAVING COUNT(*) > 1;


-- 16.1.5 Missing financial values

SELECT
    COUNT(*) AS total_records,

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
    ) AS missing_development

FROM analytics.fact_ministry_budget;


-- 16.1.6 Ministry expenditure component comparison

SELECT
    ministry_id,
    total_budget,
    actual_expenditure,
    operating_expenditure,
    development_expenditure,

    CASE
        WHEN operating_expenditure IS NULL
          OR development_expenditure IS NULL
          OR actual_expenditure IS NULL
            THEN 'INCOMPLETE COMPONENT DATA'

        WHEN ABS(
            operating_expenditure
            + development_expenditure
            - actual_expenditure
        ) > 0.01
            THEN 'COMPONENT DIFFERENCE'

        ELSE 'MATCH'
    END AS component_check

FROM analytics.fact_ministry_budget;


/* =====================================================================
   16.2 CREATE SECTOR DIMENSION
   ===================================================================== */

CREATE TABLE IF NOT EXISTS analytics.dim_sector (

    sector_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    sector_name VARCHAR(150) NOT NULL UNIQUE,

    sector_description TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);


/* =====================================================================
   16.3 CREATE MINISTRY-SECTOR MAPPING TABLE
   ===================================================================== */

CREATE TABLE IF NOT EXISTS analytics.bridge_ministry_sector (

    ministry_id BIGINT NOT NULL,

    sector_id BIGINT NOT NULL,

    allocation_share NUMERIC(7,4) NOT NULL
        CHECK (
            allocation_share > 0
            AND allocation_share <= 100
        ),

    mapping_status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            mapping_status IN (
                'pending',
                'approved',
                'rejected'
            )
        ),

    mapping_source TEXT,

    mapping_notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (ministry_id, sector_id),

    FOREIGN KEY (ministry_id)
        REFERENCES analytics.dim_ministry(ministry_id),

    FOREIGN KEY (sector_id)
        REFERENCES analytics.dim_sector(sector_id)

);


-- 16.3.1 Mapping status

SELECT
    mapping_status,
    COUNT(*) AS mapping_records,
    COUNT(DISTINCT ministry_id) AS ministries
FROM analytics.bridge_ministry_sector
GROUP BY mapping_status
ORDER BY mapping_status;


-- 16.3.2 Ministries without approved mappings

SELECT
    m.ministry_id,
    m.ministry_code,
    m.ministry_name
FROM analytics.dim_ministry m
WHERE NOT EXISTS (
    SELECT 1
    FROM analytics.bridge_ministry_sector b
    WHERE b.ministry_id = m.ministry_id
      AND b.mapping_status = 'approved'
)
ORDER BY m.ministry_name;


-- 16.3.3 Allocation share validation

SELECT
    m.ministry_id,
    m.ministry_name,
    SUM(b.allocation_share) AS allocation_total
FROM analytics.dim_ministry m
JOIN analytics.bridge_ministry_sector b
    ON m.ministry_id = b.ministry_id
WHERE b.mapping_status = 'approved'
GROUP BY m.ministry_id, m.ministry_name
HAVING ABS(
    SUM(b.allocation_share) - 100
) > 0.0001;


-- 16.3.4 Approved mappings without source evidence

SELECT
    m.ministry_name,
    s.sector_name,
    b.allocation_share,
    b.mapping_source
FROM analytics.bridge_ministry_sector b
JOIN analytics.dim_ministry m
    ON b.ministry_id = m.ministry_id
JOIN analytics.dim_sector s
    ON b.sector_id = s.sector_id
WHERE b.mapping_status = 'approved'
  AND (
      b.mapping_source IS NULL
      OR TRIM(b.mapping_source) = ''
  );


-- 16.3.5 Mapping coverage

SELECT
    COUNT(*) AS total_ministries,

    COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1
            FROM analytics.bridge_ministry_sector b
            WHERE b.ministry_id = m.ministry_id
              AND b.mapping_status = 'approved'
            GROUP BY b.ministry_id
            HAVING ABS(SUM(b.allocation_share) - 100) <= 0.0001
        )
    ) AS fully_mapped_ministries,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM analytics.bridge_ministry_sector b
            WHERE b.ministry_id = m.ministry_id
              AND b.mapping_status = 'approved'
            GROUP BY b.ministry_id
            HAVING ABS(SUM(b.allocation_share) - 100) <= 0.0001
        )
    ) AS not_fully_mapped_ministries

FROM analytics.dim_ministry m;


/* =====================================================================
   REUSABLE VIEW 1: VALID MINISTRY-SECTOR FINANCIAL RECORDS

   A ministry is included only if:
   - It has approved mappings.
   - Its approved allocation shares total 100%.
   - Mapping source evidence is present.
   ===================================================================== */

CREATE OR REPLACE VIEW analytics.vw_sector_ministry_financials AS

WITH approved_mapping AS (

    SELECT
        b.ministry_id,
        b.sector_id,
        b.allocation_share
    FROM analytics.bridge_ministry_sector b
    WHERE b.mapping_status = 'approved'
      AND b.mapping_source IS NOT NULL
      AND TRIM(b.mapping_source) <> ''

),

valid_ministries AS (

    SELECT
        ministry_id
    FROM approved_mapping
    GROUP BY ministry_id
    HAVING ABS(
        SUM(allocation_share) - 100
    ) <= 0.0001

)

SELECT
    fy.fiscal_year_id,
    fy.financial_year,

    m.ministry_id,
    m.ministry_name,

    s.sector_id,
    s.sector_name,

    b.allocation_share,

    f.standard_unit,

    f.total_budget
        * b.allocation_share / 100
        AS allocated_budget,

    f.actual_expenditure
        * b.allocation_share / 100
        AS allocated_actual_expenditure,

    f.operating_expenditure
        * b.allocation_share / 100
        AS allocated_operating_expenditure,

    f.development_expenditure
        * b.allocation_share / 100
        AS allocated_development_expenditure,

    f.total_budget IS NULL
        AS budget_is_missing,

    f.actual_expenditure IS NULL
        AS actual_is_missing,

    f.operating_expenditure IS NULL
        AS operating_is_missing,

    f.development_expenditure IS NULL
        AS development_is_missing

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry m
    ON f.ministry_id = m.ministry_id

JOIN analytics.dim_fiscal_year fy
    ON f.fiscal_year_id = fy.fiscal_year_id

JOIN approved_mapping b
    ON f.ministry_id = b.ministry_id

JOIN valid_ministries vm
    ON b.ministry_id = vm.ministry_id

JOIN analytics.dim_sector s
    ON b.sector_id = s.sector_id;


/* =====================================================================
   REUSABLE VIEW 2: SECTOR FINANCIAL SUMMARY
   ===================================================================== */

CREATE OR REPLACE VIEW analytics.vw_sector_financial_summary AS

SELECT
    fiscal_year_id,
    financial_year,
    sector_id,
    sector_name,
    standard_unit,

    COUNT(DISTINCT ministry_id)
        AS ministry_count,

    SUM(allocated_budget)
        AS total_budget,

    SUM(allocated_actual_expenditure)
        AS actual_expenditure,

    SUM(allocated_operating_expenditure)
        AS operating_expenditure,

    SUM(allocated_development_expenditure)
        AS development_expenditure,

    COUNT(*) FILTER (
        WHERE budget_is_missing
    ) AS missing_budget_records,

    COUNT(*) FILTER (
        WHERE actual_is_missing
    ) AS missing_actual_records,

    COUNT(*) FILTER (
        WHERE operating_is_missing
    ) AS missing_operating_records,

    COUNT(*) FILTER (
        WHERE development_is_missing
    ) AS missing_development_records,

    COUNT(*) AS source_record_count

FROM analytics.vw_sector_ministry_financials

GROUP BY
    fiscal_year_id,
    financial_year,
    sector_id,
    sector_name,
    standard_unit;


/* =====================================================================
   16.4 SECTOR-WISE BUDGET ALLOCATION
   ===================================================================== */

SELECT
    financial_year,
    sector_name,
    standard_unit,
    ministry_count,
    ROUND(total_budget, 4) AS sector_budget
FROM analytics.vw_sector_financial_summary
ORDER BY financial_year, sector_budget DESC;


/* =====================================================================
   16.5 SECTOR-WISE ACTUAL EXPENDITURE
   ===================================================================== */

SELECT
    financial_year,
    sector_name,
    standard_unit,
    ROUND(actual_expenditure, 4)
        AS actual_expenditure
FROM analytics.vw_sector_financial_summary
ORDER BY financial_year, actual_expenditure DESC;


/* =====================================================================
   16.6 SECTOR-WISE BUDGET VARIANCE
   Positive = Actual below budget.
   Negative = Actual above budget.
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    ROUND(total_budget, 4) AS total_budget,

    ROUND(actual_expenditure, 4)
        AS actual_expenditure,

    ROUND(
        total_budget - actual_expenditure,
        4
    ) AS budget_variance

FROM analytics.vw_sector_financial_summary
WHERE total_budget IS NOT NULL
  AND actual_expenditure IS NOT NULL
ORDER BY financial_year, budget_variance DESC;


/* =====================================================================
   16.7 SECTOR UTILIZATION
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    ROUND(total_budget, 4) AS total_budget,

    ROUND(actual_expenditure, 4)
        AS actual_expenditure,

    ROUND(
        actual_expenditure
        / NULLIF(total_budget, 0) * 100,
        4
    ) AS utilization_percentage,

    CASE
        WHEN total_budget = 0
            THEN 'ZERO BUDGET'

        WHEN actual_expenditure
             / NULLIF(total_budget, 0) * 100 > 100
            THEN 'ABOVE 100%'

        WHEN actual_expenditure
             / NULLIF(total_budget, 0) * 100 >= 80
            THEN 'HIGH UTILIZATION'

        WHEN actual_expenditure
             / NULLIF(total_budget, 0) * 100 >= 50
            THEN 'MODERATE UTILIZATION'

        ELSE 'LOW UTILIZATION'
    END AS utilization_category

FROM analytics.vw_sector_financial_summary
WHERE total_budget IS NOT NULL
  AND actual_expenditure IS NOT NULL
ORDER BY financial_year, utilization_percentage DESC;


/* =====================================================================
   16.8 OPERATING VS DEVELOPMENT EXPENDITURE
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    ROUND(operating_expenditure, 4)
        AS operating_expenditure,

    ROUND(development_expenditure, 4)
        AS development_expenditure,

    ROUND(
        operating_expenditure
        + development_expenditure,
        4
    ) AS combined_component_expenditure,

    ROUND(
        operating_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure,
            0
        ) * 100,
        4
    ) AS operating_share_percentage,

    ROUND(
        development_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure,
            0
        ) * 100,
        4
    ) AS development_share_percentage

FROM analytics.vw_sector_financial_summary
WHERE operating_expenditure IS NOT NULL
  AND development_expenditure IS NOT NULL
ORDER BY financial_year, sector_name;


/* =====================================================================
   16.9 TOP AND BOTTOM SECTORS BY ACTUAL EXPENDITURE
   ===================================================================== */

WITH ranked AS (

    SELECT
        financial_year,
        sector_name,
        actual_expenditure,

        DENSE_RANK() OVER (
            PARTITION BY financial_year
            ORDER BY actual_expenditure DESC
        ) AS highest_rank,

        DENSE_RANK() OVER (
            PARTITION BY financial_year
            ORDER BY actual_expenditure ASC
        ) AS lowest_rank

    FROM analytics.vw_sector_financial_summary
    WHERE actual_expenditure IS NOT NULL

)

SELECT
    financial_year,
    sector_name,
    actual_expenditure,
    highest_rank,
    lowest_rank
FROM ranked
WHERE highest_rank <= 5
   OR lowest_rank <= 5
ORDER BY financial_year, highest_rank;


/* =====================================================================
   16.10 SECTOR CONTRIBUTION TO MAPPED EXPENDITURE
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    ROUND(actual_expenditure, 4)
        AS actual_expenditure,

    ROUND(
        actual_expenditure
        / NULLIF(
            SUM(actual_expenditure) OVER (
                PARTITION BY fiscal_year_id
            ),
            0
        ) * 100,
        4
    ) AS mapped_expenditure_contribution_pct

FROM analytics.vw_sector_financial_summary
WHERE actual_expenditure IS NOT NULL
ORDER BY financial_year,
         mapped_expenditure_contribution_pct DESC;


/* =====================================================================
   16.11 CONSOLIDATED SECTOR KPI SUMMARY
   ===================================================================== */

SELECT
    financial_year,
    sector_name,
    standard_unit,
    ministry_count,

    ROUND(total_budget, 4) AS total_budget,

    ROUND(actual_expenditure, 4)
        AS actual_expenditure,

    ROUND(
        total_budget - actual_expenditure,
        4
    ) AS budget_variance,

    ROUND(
        actual_expenditure
        / NULLIF(total_budget, 0) * 100,
        4
    ) AS utilization_percentage,

    ROUND(operating_expenditure, 4)
        AS operating_expenditure,

    ROUND(development_expenditure, 4)
        AS development_expenditure

FROM analytics.vw_sector_financial_summary
ORDER BY financial_year, total_budget DESC;


/* =====================================================================
   16.12 SECTOR DATA QUALITY VALIDATION
   ===================================================================== */

-- A. Missing financial components

SELECT *
FROM analytics.vw_sector_financial_summary
WHERE missing_budget_records > 0
   OR missing_actual_records > 0
   OR missing_operating_records > 0
   OR missing_development_records > 0;


-- B. Operating + Development vs Actual

SELECT
    financial_year,
    sector_name,

    ROUND(
        operating_expenditure
        + development_expenditure,
        4
    ) AS combined_components,

    ROUND(actual_expenditure, 4)
        AS actual_expenditure,

    ROUND(
        operating_expenditure
        + development_expenditure
        - actual_expenditure,
        4
    ) AS component_difference

FROM analytics.vw_sector_financial_summary
WHERE operating_expenditure IS NOT NULL
  AND development_expenditure IS NOT NULL
  AND actual_expenditure IS NOT NULL
  AND ABS(
      operating_expenditure
      + development_expenditure
      - actual_expenditure
  ) > 0.01;


-- C. Approved mapping evidence validation

SELECT
    b.*,
    m.ministry_name,
    s.sector_name
FROM analytics.bridge_ministry_sector b
JOIN analytics.dim_ministry m
    ON b.ministry_id = m.ministry_id
JOIN analytics.dim_sector s
    ON b.sector_id = s.sector_id
WHERE b.mapping_status = 'approved'
  AND (
      b.mapping_source IS NULL
      OR TRIM(b.mapping_source) = ''
  );


/* =====================================================================
   16.13 SECTOR ANALYSIS COMPLETENESS
   ===================================================================== */

SELECT
    COUNT(DISTINCT sector_id) AS analyzed_sectors,

    COUNT(*) AS sector_year_records,

    COUNT(*) FILTER (
        WHERE total_budget IS NOT NULL
    ) AS records_with_budget,

    COUNT(*) FILTER (
        WHERE actual_expenditure IS NOT NULL
    ) AS records_with_actual,

    COUNT(*) FILTER (
        WHERE total_budget IS NOT NULL
          AND actual_expenditure IS NOT NULL
    ) AS records_with_both

FROM analytics.vw_sector_financial_summary;


/* =====================================================================
   16.14 MAPPING COVERAGE ANALYSIS
   ===================================================================== */

WITH approved_totals AS (

    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
      AND mapping_source IS NOT NULL
      AND TRIM(mapping_source) <> ''
    GROUP BY ministry_id

)

SELECT
    COUNT(*) AS total_ministries,

    COUNT(*) FILTER (
        WHERE a.allocation_total IS NOT NULL
          AND ABS(a.allocation_total - 100) <= 0.0001
    ) AS fully_mapped_ministries,

    COUNT(*) FILTER (
        WHERE a.allocation_total IS NULL
           OR ABS(a.allocation_total - 100) > 0.0001
    ) AS not_fully_mapped_ministries,

    ROUND(
        COUNT(*) FILTER (
            WHERE a.allocation_total IS NOT NULL
              AND ABS(a.allocation_total - 100) <= 0.0001
        )::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS mapping_coverage_pct

FROM analytics.dim_ministry m
LEFT JOIN approved_totals a
    ON m.ministry_id = a.ministry_id;


/* =====================================================================
   16.15 UNMAPPED MINISTRY FINANCIAL IMPACT
   ===================================================================== */

WITH valid_ministries AS (

    SELECT
        b.ministry_id
    FROM analytics.bridge_ministry_sector b
    WHERE b.mapping_status = 'approved'
      AND b.mapping_source IS NOT NULL
      AND TRIM(b.mapping_source) <> ''
    GROUP BY b.ministry_id
    HAVING ABS(
        SUM(b.allocation_share) - 100
    ) <= 0.0001

)

SELECT
    fy.financial_year,

    COUNT(*) AS unmapped_fact_records,

    SUM(f.total_budget)
        AS unmapped_budget,

    SUM(f.actual_expenditure)
        AS unmapped_actual_expenditure

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_fiscal_year fy
    ON f.fiscal_year_id = fy.fiscal_year_id

LEFT JOIN valid_ministries vm
    ON f.ministry_id = vm.ministry_id

WHERE vm.ministry_id IS NULL

GROUP BY fy.financial_year
ORDER BY fy.financial_year;


/* =====================================================================
   16.16 SECTOR VS MINISTRY RECONCILIATION
   ===================================================================== */

WITH mapping_totals AS (

    SELECT
        ministry_id,
        SUM(allocation_share) AS allocation_total
    FROM analytics.bridge_ministry_sector
    WHERE mapping_status = 'approved'
      AND mapping_source IS NOT NULL
      AND TRIM(mapping_source) <> ''
    GROUP BY ministry_id

),

valid_ministries AS (

    SELECT ministry_id
    FROM mapping_totals
    WHERE ABS(allocation_total - 100) <= 0.0001

),

ministry_totals AS (

    SELECT
        f.fiscal_year_id,
        SUM(f.total_budget) AS ministry_budget,
        SUM(f.actual_expenditure) AS ministry_actual
    FROM analytics.fact_ministry_budget f
    GROUP BY f.fiscal_year_id

),

mapped_totals AS (

    SELECT
        fiscal_year_id,
        SUM(total_budget) AS mapped_budget,
        SUM(actual_expenditure) AS mapped_actual
    FROM analytics.vw_sector_financial_summary
    GROUP BY fiscal_year_id

)

SELECT
    fy.financial_year,

    mt.ministry_budget,
    st.mapped_budget,

    mt.ministry_budget - st.mapped_budget
        AS unmapped_or_excluded_budget,

    mt.ministry_actual,
    st.mapped_actual,

    mt.ministry_actual - st.mapped_actual
        AS unmapped_or_excluded_actual

FROM ministry_totals mt

JOIN analytics.dim_fiscal_year fy
    ON mt.fiscal_year_id = fy.fiscal_year_id

LEFT JOIN mapped_totals st
    ON mt.fiscal_year_id = st.fiscal_year_id

ORDER BY fy.financial_year;


/* =====================================================================
   16.17 OPERATING AND DEVELOPMENT SHARE ANALYSIS
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    ROUND(
        operating_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure,
            0
        ) * 100,
        2
    ) AS operating_share_pct,

    ROUND(
        development_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure,
            0
        ) * 100,
        2
    ) AS development_share_pct

FROM analytics.vw_sector_financial_summary
WHERE operating_expenditure IS NOT NULL
  AND development_expenditure IS NOT NULL
ORDER BY financial_year, sector_name;


/* =====================================================================
   16.18 MULTI-METRIC SECTOR RANKING
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    DENSE_RANK() OVER (
        PARTITION BY fiscal_year_id
        ORDER BY total_budget DESC NULLS LAST
    ) AS budget_rank,

    DENSE_RANK() OVER (
        PARTITION BY fiscal_year_id
        ORDER BY actual_expenditure DESC NULLS LAST
    ) AS expenditure_rank,

    DENSE_RANK() OVER (
        PARTITION BY fiscal_year_id
        ORDER BY
            actual_expenditure
            / NULLIF(total_budget, 0) DESC NULLS LAST
    ) AS utilization_rank

FROM analytics.vw_sector_financial_summary
ORDER BY financial_year, budget_rank;


/* =====================================================================
   16.19 UTILIZATION OUTLIER ANALYSIS USING IQR

   Outliers are statistical flags, not proof of error or misconduct.
   ===================================================================== */

WITH utilization AS (

    SELECT
        fiscal_year_id,
        financial_year,
        sector_name,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100
            AS utilization_pct

    FROM analytics.vw_sector_financial_summary

    WHERE total_budget > 0
      AND actual_expenditure IS NOT NULL

),

quartiles AS (

    SELECT
        fiscal_year_id,

        PERCENTILE_CONT(0.25)
            WITHIN GROUP (
                ORDER BY utilization_pct
            ) AS q1,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (
                ORDER BY utilization_pct
            ) AS q3

    FROM utilization
    GROUP BY fiscal_year_id

)

SELECT
    u.financial_year,
    u.sector_name,
    ROUND(u.utilization_pct::numeric, 4) AS utilization_pct,

    ROUND(q.q1::numeric, 4) AS q1,
    ROUND(q.q3::numeric, 4) AS q3,

    ROUND((q.q3 - q.q1)::numeric, 4) AS iqr,

    CASE
        WHEN u.utilization_pct
             < q.q1 - 1.5 * (q.q3 - q.q1)
            THEN 'LOW OUTLIER'

        WHEN u.utilization_pct
             > q.q3 + 1.5 * (q.q3 - q.q1)
            THEN 'HIGH OUTLIER'

        ELSE 'WITHIN RANGE'
    END AS outlier_status

FROM utilization u

JOIN quartiles q
    ON u.fiscal_year_id = q.fiscal_year_id

ORDER BY u.financial_year, u.utilization_pct DESC;


/* =====================================================================
   16.20 DATA QUALITY SCORECARD
   ===================================================================== */

SELECT
    financial_year,
    sector_name,

    source_record_count,

    missing_budget_records,
    missing_actual_records,
    missing_operating_records,
    missing_development_records,

    CASE
        WHEN missing_budget_records = 0
         AND missing_actual_records = 0
         AND missing_operating_records = 0
         AND missing_development_records = 0
            THEN 'COMPLETE'

        ELSE 'REQUIRES REVIEW'
    END AS financial_data_quality_status

FROM analytics.vw_sector_financial_summary
ORDER BY financial_year, sector_name;


/* =====================================================================
   16.21 SQL PERFORMANCE OPTIMIZATION
   ===================================================================== */

CREATE INDEX IF NOT EXISTS idx_bridge_sector_status
ON analytics.bridge_ministry_sector (
    mapping_status,
    ministry_id,
    sector_id
);

CREATE INDEX IF NOT EXISTS idx_fact_ministry_fiscal_year
ON analytics.fact_ministry_budget (
    fiscal_year_id,
    ministry_id
);

CREATE INDEX IF NOT EXISTS idx_fact_ministry_id
ON analytics.fact_ministry_budget (
    ministry_id
);


-- Review query plan for sector summary

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM analytics.vw_sector_financial_summary
ORDER BY financial_year, total_budget DESC;


/* =====================================================================
   16.22 POWER BI DATASET EXPORT
   =====================================================================

   Create outputs/step_16 before running these commands.

   Run from psql. These are psql \copy commands, not ordinary SQL.
   They export the result to the local machine running psql.
   ===================================================================== */

-- \copy (SELECT financial_year, sector_name, standard_unit, ministry_count, total_budget FROM analytics.vw_sector_financial_summary ORDER BY financial_year, total_budget DESC) TO 'outputs/step_16/sector_budget_analysis.csv' WITH (FORMAT CSV, HEADER TRUE);

-- \copy (SELECT financial_year, sector_name, standard_unit, actual_expenditure FROM analytics.vw_sector_financial_summary ORDER BY financial_year, actual_expenditure DESC) TO 'outputs/step_16/sector_expenditure_analysis.csv' WITH (FORMAT CSV, HEADER TRUE);

-- \copy (SELECT financial_year, sector_name, total_budget, actual_expenditure, total_budget - actual_expenditure AS budget_variance FROM analytics.vw_sector_financial_summary WHERE total_budget IS NOT NULL AND actual_expenditure IS NOT NULL ORDER BY financial_year, sector_name) TO 'outputs/step_16/sector_variance_analysis.csv' WITH (FORMAT CSV, HEADER TRUE);

-- \copy (SELECT financial_year, sector_name, total_budget, actual_expenditure, actual_expenditure / NULLIF(total_budget, 0) * 100 AS utilization_percentage FROM analytics.vw_sector_financial_summary WHERE total_budget IS NOT NULL AND actual_expenditure IS NOT NULL ORDER BY financial_year, sector_name) TO 'outputs/step_16/sector_utilization_analysis.csv' WITH (FORMAT CSV, HEADER TRUE);

-- \copy (SELECT financial_year, sector_name, operating_expenditure, development_expenditure FROM analytics.vw_sector_financial_summary ORDER BY financial_year, sector_name) TO 'outputs/step_16/sector_operating_development.csv' WITH (FORMAT CSV, HEADER TRUE);

-- \copy (SELECT financial_year, sector_name, total_budget, actual_expenditure, DENSE_RANK() OVER (PARTITION BY fiscal_year_id ORDER BY actual_expenditure DESC NULLS LAST) AS expenditure_rank FROM analytics.vw_sector_financial_summary ORDER BY financial_year, expenditure_rank) TO 'outputs/step_16/sector_ranking.csv' WITH (FORMAT CSV, HEADER TRUE);

-- \copy (SELECT financial_year, sector_name, total_budget, actual_expenditure, missing_budget_records, missing_actual_records, missing_operating_records, missing_development_records FROM analytics.vw_sector_financial_summary ORDER BY financial_year, sector_name) TO 'outputs/step_16/sector_kpi_summary.csv' WITH (FORMAT CSV, HEADER TRUE);


/* =====================================================================
   16.23 BUSINESS INSIGHT SUPPORTING QUERIES
   ===================================================================== */

-- A. Highest budget sector

SELECT
    financial_year,
    sector_name,
    total_budget
FROM analytics.vw_sector_financial_summary
WHERE total_budget IS NOT NULL
ORDER BY fiscal_year_id, total_budget DESC;


-- B. Highest actual expenditure sector

SELECT
    financial_year,
    sector_name,
    actual_expenditure
FROM analytics.vw_sector_financial_summary
WHERE actual_expenditure IS NOT NULL
ORDER BY fiscal_year_id, actual_expenditure DESC;


-- C. Highest positive variance

SELECT
    financial_year,
    sector_name,
    total_budget - actual_expenditure AS positive_variance
FROM analytics.vw_sector_financial_summary
WHERE total_budget IS NOT NULL
  AND actual_expenditure IS NOT NULL
  AND total_budget > actual_expenditure
ORDER BY fiscal_year_id, positive_variance DESC;


-- D. Sectors with expenditure above budget

SELECT
    financial_year,
    sector_name,
    total_budget,
    actual_expenditure,
    actual_expenditure - total_budget AS above_budget_amount
FROM analytics.vw_sector_financial_summary
WHERE total_budget IS NOT NULL
  AND actual_expenditure IS NOT NULL
  AND actual_expenditure > total_budget
ORDER BY fiscal_year_id, above_budget_amount DESC;


-- E. Sector operating/development composition

SELECT
    financial_year,
    sector_name,
    operating_expenditure,
    development_expenditure
FROM analytics.vw_sector_financial_summary
WHERE operating_expenditure IS NOT NULL
  AND development_expenditure IS NOT NULL
ORDER BY financial_year, sector_name;


/* =====================================================================
   16.24 FINAL STEP VALIDATION
   ===================================================================== */

-- A. Dimension and mapping counts

SELECT
    (SELECT COUNT(*)
     FROM analytics.dim_sector)
        AS total_sectors,

    (SELECT COUNT(*)
     FROM analytics.bridge_ministry_sector)
        AS total_mapping_records,

    (SELECT COUNT(*)
     FROM analytics.bridge_ministry_sector
     WHERE mapping_status = 'approved')
        AS approved_mapping_records;


-- B. Invalid approved allocation totals

SELECT
    ministry_id,
    SUM(allocation_share) AS allocation_total
FROM analytics.bridge_ministry_sector
WHERE mapping_status = 'approved'
GROUP BY ministry_id
HAVING ABS(
    SUM(allocation_share) - 100
) > 0.0001;


-- C. Approved mapping without evidence

SELECT COUNT(*) AS approved_mapping_without_evidence
FROM analytics.bridge_ministry_sector
WHERE mapping_status = 'approved'
  AND (
      mapping_source IS NULL
      OR TRIM(mapping_source) = ''
  );


-- D. Sector analytical view record count

SELECT
    COUNT(*) AS sector_year_records,
    COUNT(DISTINCT sector_id) AS analyzed_sectors,
    COUNT(DISTINCT fiscal_year_id) AS analyzed_fiscal_years
FROM analytics.vw_sector_financial_summary;


-- E. Final status overview

SELECT
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM analytics.bridge_ministry_sector
            WHERE mapping_status = 'approved'
        )
            THEN 'PENDING: NO APPROVED MAPPINGS'

        WHEN EXISTS (
            SELECT 1
            FROM analytics.bridge_ministry_sector
            WHERE mapping_status = 'approved'
              AND (
                  mapping_source IS NULL
                  OR TRIM(mapping_source) = ''
              )
        )
            THEN 'REVIEW: MAPPING EVIDENCE MISSING'

        WHEN EXISTS (
            SELECT ministry_id
            FROM analytics.bridge_ministry_sector
            WHERE mapping_status = 'approved'
            GROUP BY ministry_id
            HAVING ABS(
                SUM(allocation_share) - 100
            ) > 0.0001
        )
            THEN 'REVIEW: INVALID ALLOCATION TOTAL'

        WHEN NOT EXISTS (
            SELECT 1
            FROM analytics.vw_sector_financial_summary
        )
            THEN 'PENDING: NO ANALYTICAL RECORDS'

        ELSE 'MAPPING CHECKS PASSED: REVIEW DATA QUALITY BEFORE SIGN-OFF'
    END AS step_16_status;
