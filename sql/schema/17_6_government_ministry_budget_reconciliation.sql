-- ============================================================
-- STEP 17.6
-- GOVERNMENT-LEVEL VS MINISTRY-LEVEL BUDGET RECONCILIATION
-- Difference convention: Ministry aggregate - Government figure
-- All amounts are in BDT Crore
-- ============================================================

DROP TABLE IF EXISTS pg_temp.tmp_budget_reconciliation;

CREATE TEMP TABLE tmp_budget_reconciliation AS
WITH government AS (
    SELECT
        COUNT(*) AS government_record_count,
        SUM(original_budget) AS government_original_budget,
        SUM(revised_budget) AS government_revised_budget,
        SUM(actual_expenditure) AS government_actual_expenditure,
        SUM(operating_expenditure) AS government_operating_expenditure,
        SUM(development_expenditure) AS government_development_expenditure
    FROM analytics.fact_government_budget_summary
),
ministry AS (
    SELECT
        COUNT(*) AS ministry_record_count,
        COUNT(DISTINCT fmb.ministry_id) AS distinct_ministry_count,
        SUM(fmb.total_budget) AS ministry_total_budget,
        SUM(fmb.actual_expenditure) AS ministry_actual_expenditure,
        SUM(fmb.operating_expenditure) AS ministry_operating_expenditure,
        SUM(fmb.development_expenditure) AS ministry_development_expenditure
    FROM analytics.fact_ministry_budget fmb
)
SELECT
    g.government_record_count,
    m.ministry_record_count,
    m.distinct_ministry_count,

    g.government_original_budget,
    g.government_revised_budget,
    m.ministry_total_budget,

    m.ministry_total_budget - g.government_original_budget
        AS original_budget_difference,

    m.ministry_total_budget - g.government_revised_budget
        AS revised_budget_comparison_difference,

    g.government_actual_expenditure,
    m.ministry_actual_expenditure,

    m.ministry_actual_expenditure - g.government_actual_expenditure
        AS actual_expenditure_difference,

    g.government_operating_expenditure,
    m.ministry_operating_expenditure,

    m.ministry_operating_expenditure - g.government_operating_expenditure
        AS operating_expenditure_difference,

    g.government_development_expenditure,
    m.ministry_development_expenditure,

    m.ministry_development_expenditure - g.government_development_expenditure
        AS development_expenditure_difference,

    g.government_operating_expenditure
        + g.government_development_expenditure
        AS government_component_total,

    m.ministry_operating_expenditure
        + m.ministry_development_expenditure
        AS ministry_component_total,

    g.government_actual_expenditure
        - (
            g.government_operating_expenditure
            + g.government_development_expenditure
        ) AS government_actual_vs_components_difference,

    m.ministry_actual_expenditure
        - (
            m.ministry_operating_expenditure
            + m.ministry_development_expenditure
        ) AS ministry_actual_vs_components_difference

FROM government g
CROSS JOIN ministry m;


-- ============================================================
-- 17.6.1 GOVERNMENT VS MINISTRY RECONCILIATION DETAIL
-- ============================================================

SELECT
    government_record_count,
    ministry_record_count,
    distinct_ministry_count,

    ROUND(government_original_budget, 4)
        AS government_original_budget,
    ROUND(ministry_total_budget, 4)
        AS ministry_total_budget,
    ROUND(original_budget_difference, 4)
        AS original_budget_difference,

    ROUND(government_revised_budget, 4)
        AS government_revised_budget,
    ROUND(revised_budget_comparison_difference, 4)
        AS revised_budget_comparison_difference,

    ROUND(government_actual_expenditure, 4)
        AS government_actual_expenditure,
    ROUND(ministry_actual_expenditure, 4)
        AS ministry_actual_expenditure,
    ROUND(actual_expenditure_difference, 4)
        AS actual_expenditure_difference

FROM tmp_budget_reconciliation;


-- ============================================================
-- 17.6.2 OPERATING AND DEVELOPMENT COMPONENT RECONCILIATION
-- ============================================================

SELECT
    ROUND(government_operating_expenditure, 4)
        AS government_operating_expenditure,
    ROUND(ministry_operating_expenditure, 4)
        AS ministry_operating_expenditure,
    ROUND(operating_expenditure_difference, 4)
        AS operating_expenditure_difference,

    ROUND(government_development_expenditure, 4)
        AS government_development_expenditure,
    ROUND(ministry_development_expenditure, 4)
        AS ministry_development_expenditure,
    ROUND(development_expenditure_difference, 4)
        AS development_expenditure_difference,

    ROUND(government_component_total, 4)
        AS government_component_total,
    ROUND(ministry_component_total, 4)
        AS ministry_component_total,

    ROUND(government_actual_expenditure, 4)
        AS government_actual_expenditure,
    ROUND(government_actual_vs_components_difference, 4)
        AS government_actual_vs_components_difference,

    ROUND(ministry_actual_expenditure, 4)
        AS ministry_actual_expenditure,
    ROUND(ministry_actual_vs_components_difference, 4)
        AS ministry_actual_vs_components_difference

FROM tmp_budget_reconciliation;


-- ============================================================
-- 17.6.3 RECONCILIATION STATUS SUMMARY
-- ============================================================

SELECT
    CASE
        WHEN ABS(original_budget_difference) <= 0.001
            THEN 'MATCH'
        ELSE 'DIFFERENCE IDENTIFIED'
    END AS original_budget_status,

    CASE
        WHEN ABS(actual_expenditure_difference) <= 0.001
            THEN 'MATCH'
        ELSE 'DIFFERENCE IDENTIFIED'
    END AS actual_expenditure_status,

    CASE
        WHEN ABS(government_actual_vs_components_difference) <= 0.001
            THEN 'MATCH'
        ELSE 'COMPONENT DIFFERENCE IDENTIFIED'
    END AS government_component_status,

    CASE
        WHEN ABS(ministry_actual_vs_components_difference) <= 0.001
            THEN 'MATCH'
        ELSE 'COMPONENT DIFFERENCE IDENTIFIED'
    END AS ministry_component_status,

    CASE
        WHEN ABS(revised_budget_comparison_difference) <= 0.001
            THEN 'MATCH'
        ELSE 'NOT DIRECTLY COMPARABLE / DIFFERENCE'
    END AS revised_budget_comparison_status

FROM tmp_budget_reconciliation;


-- ============================================================
-- 17.6.4 FINAL RECONCILIATION DATA VALIDATION
-- Differences are reported, not treated as automatic failures.
-- ============================================================

SELECT
    government_record_count,
    ministry_record_count,
    distinct_ministry_count,

    COUNT(*) FILTER (
        WHERE government_original_budget IS NULL
           OR government_revised_budget IS NULL
           OR government_actual_expenditure IS NULL
           OR government_operating_expenditure IS NULL
           OR government_development_expenditure IS NULL
           OR ministry_total_budget IS NULL
           OR ministry_actual_expenditure IS NULL
           OR ministry_operating_expenditure IS NULL
           OR ministry_development_expenditure IS NULL
    ) AS missing_reconciliation_values,

    COUNT(*) FILTER (
        WHERE original_budget_difference IS NULL
           OR actual_expenditure_difference IS NULL
           OR operating_expenditure_difference IS NULL
           OR development_expenditure_difference IS NULL
    ) AS missing_difference_calculations,

    CASE
        WHEN government_record_count = 1
         AND ministry_record_count = 62
         AND distinct_ministry_count = 62
         AND COUNT(*) FILTER (
             WHERE government_original_budget IS NULL
                OR government_revised_budget IS NULL
                OR government_actual_expenditure IS NULL
                OR government_operating_expenditure IS NULL
                OR government_development_expenditure IS NULL
                OR ministry_total_budget IS NULL
                OR ministry_actual_expenditure IS NULL
                OR ministry_operating_expenditure IS NULL
                OR ministry_development_expenditure IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE original_budget_difference IS NULL
                OR actual_expenditure_difference IS NULL
                OR operating_expenditure_difference IS NULL
                OR development_expenditure_difference IS NULL
         ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM tmp_budget_reconciliation
GROUP BY
    government_record_count,
    ministry_record_count,
    distinct_ministry_count;


-- ============================================================
-- END OF STEP 17.6
-- ============================================================