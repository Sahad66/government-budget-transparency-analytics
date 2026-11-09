-- ============================================================
-- STEP 16.18: OPERATING VS DEVELOPMENT EXPENDITURE ANALYSIS
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 16.18.1 SECTOR-WISE OPERATING AND DEVELOPMENT EXPENDITURE

SELECT
    sector_name,
    ministry_count,

    ROUND(operating_expenditure::numeric, 4)
        AS operating_expenditure,

    ROUND(development_expenditure::numeric, 4)
        AS development_expenditure,

    ROUND(
        (operating_expenditure + development_expenditure)::numeric,
        4
    ) AS combined_expenditure,

    ROUND(actual_expenditure::numeric, 4)
        AS actual_expenditure,

    ROUND(
        (actual_expenditure - operating_expenditure
        - development_expenditure)::numeric,
        4
    ) AS component_difference

FROM analytics.vw_sector_financial_summary

ORDER BY actual_expenditure DESC;


-- 16.18.2 OPERATING AND DEVELOPMENT COMPOSITION

SELECT
    sector_name,

    ROUND(
        (operating_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure, 0
        ) * 100)::numeric,
        4
    ) AS operating_share_pct,

    ROUND(
        (development_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure, 0
        ) * 100)::numeric,
        4
    ) AS development_share_pct,

    CASE
        WHEN operating_expenditure >
             development_expenditure
            THEN 'OPERATING-HEAVY'
        WHEN development_expenditure >
             operating_expenditure
            THEN 'DEVELOPMENT-HEAVY'
        ELSE 'BALANCED'
    END AS expenditure_structure

FROM analytics.vw_sector_financial_summary

ORDER BY development_share_pct DESC;


-- 16.18.3 OPERATING EXPENDITURE RANKING

SELECT
    sector_name,

    ROUND(operating_expenditure::numeric, 4)
        AS operating_expenditure,

    ROUND(
        (operating_expenditure
        / NULLIF(SUM(operating_expenditure) OVER (), 0)
        * 100)::numeric,
        4
    ) AS operating_contribution_pct,

    RANK() OVER (
        ORDER BY operating_expenditure DESC
    ) AS operating_rank

FROM analytics.vw_sector_financial_summary

ORDER BY operating_rank;


-- 16.18.4 DEVELOPMENT EXPENDITURE RANKING

SELECT
    sector_name,

    ROUND(development_expenditure::numeric, 4)
        AS development_expenditure,

    ROUND(
        (development_expenditure
        / NULLIF(SUM(development_expenditure) OVER (), 0)
        * 100)::numeric,
        4
    ) AS development_contribution_pct,

    RANK() OVER (
        ORDER BY development_expenditure DESC
    ) AS development_rank

FROM analytics.vw_sector_financial_summary

ORDER BY development_rank;


-- 16.18.5 OVERALL OPERATING VS DEVELOPMENT KPI

SELECT
    COUNT(*) AS analyzed_sectors,

    SUM(ministry_count) AS mapped_ministries,

    ROUND(SUM(operating_expenditure)::numeric, 4)
        AS total_operating_expenditure,

    ROUND(SUM(development_expenditure)::numeric, 4)
        AS total_development_expenditure,

    ROUND(
        (SUM(operating_expenditure)
        + SUM(development_expenditure))::numeric,
        4
    ) AS combined_expenditure,

    ROUND(SUM(actual_expenditure)::numeric, 4)
        AS total_actual_expenditure,

    ROUND(
        (SUM(operating_expenditure)
        / NULLIF(
            SUM(operating_expenditure)
            + SUM(development_expenditure), 0
        ) * 100)::numeric,
        4
    ) AS overall_operating_share_pct,

    ROUND(
        (SUM(development_expenditure)
        / NULLIF(
            SUM(operating_expenditure)
            + SUM(development_expenditure), 0
        ) * 100)::numeric,
        4
    ) AS overall_development_share_pct,

    ROUND(
        (SUM(actual_expenditure)
        - SUM(operating_expenditure)
        - SUM(development_expenditure))::numeric,
        4
    ) AS component_difference

FROM analytics.vw_sector_financial_summary;


-- 16.18.6 COMPONENT RECONCILIATION VALIDATION

SELECT
    sector_name,

    ROUND(
        (actual_expenditure
        - operating_expenditure
        - development_expenditure)::numeric,
        4
    ) AS component_difference,

    CASE
        WHEN ABS(
            actual_expenditure
            - operating_expenditure
            - development_expenditure
        ) <= 0.001
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS reconciliation_status

FROM analytics.vw_sector_financial_summary

ORDER BY sector_name;


-- 16.18.7 COMPONENT DATA QUALITY CHECK

SELECT
    COUNT(*) AS sector_count,

    COUNT(*) FILTER (
        WHERE operating_expenditure IS NULL
    ) AS missing_operating_count,

    COUNT(*) FILTER (
        WHERE development_expenditure IS NULL
    ) AS missing_development_count,

    COUNT(*) FILTER (
        WHERE operating_expenditure < 0
    ) AS negative_operating_count,

    COUNT(*) FILTER (
        WHERE development_expenditure < 0
    ) AS negative_development_count,

    COUNT(*) FILTER (
        WHERE ABS(
            actual_expenditure
            - operating_expenditure
            - development_expenditure
        ) > 0.001
    ) AS component_mismatch_count,

    CASE
        WHEN COUNT(*) = 5
         AND COUNT(*) FILTER (
             WHERE operating_expenditure IS NULL
                OR development_expenditure IS NULL
                OR operating_expenditure < 0
                OR development_expenditure < 0
                OR ABS(
                    actual_expenditure
                    - operating_expenditure
                    - development_expenditure
                ) > 0.001
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS data_quality_status

FROM analytics.vw_sector_financial_summary;
