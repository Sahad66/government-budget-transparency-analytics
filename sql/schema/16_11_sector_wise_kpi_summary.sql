-- ============================================================
-- STEP 16.11: SECTOR-WISE KPI SUMMARY
-- Project: Government Budget Transparency & Spending Efficiency
-- Unit: BDT Crore
-- ============================================================

-- 16.11.1 SECTOR-WISE KPI SUMMARY

SELECT
    sector_name,
    ministry_count,

    ROUND(total_budget, 4) AS total_budget,
    ROUND(actual_expenditure, 4) AS actual_expenditure,

    ROUND(
        total_budget - actual_expenditure, 4
    ) AS budget_variance,

    ROUND(
        actual_expenditure
        / NULLIF(total_budget, 0) * 100, 4
    ) AS utilization_rate_pct,

    ROUND(
        actual_expenditure
        / NULLIF(SUM(actual_expenditure) OVER (), 0) * 100,
        4
    ) AS expenditure_contribution_pct,

    ROUND(
        total_budget
        / NULLIF(SUM(total_budget) OVER (), 0) * 100,
        4
    ) AS budget_contribution_pct,

    ROUND(
        operating_expenditure
        / NULLIF(actual_expenditure, 0) * 100, 4
    ) AS operating_share_pct,

    ROUND(
        development_expenditure
        / NULLIF(actual_expenditure, 0) * 100, 4
    ) AS development_share_pct

FROM analytics.vw_sector_financial_summary
ORDER BY total_budget DESC;


-- 16.11.2 MAPPED SECTOR OVERALL KPI

SELECT
    COUNT(*) AS sector_count,
    SUM(ministry_count) AS mapped_ministry_count,

    ROUND(SUM(total_budget), 4) AS mapped_total_budget,
    ROUND(SUM(actual_expenditure), 4) AS mapped_actual_expenditure,

    ROUND(
        SUM(total_budget) - SUM(actual_expenditure), 4
    ) AS mapped_budget_variance,

    ROUND(
        SUM(actual_expenditure)
        / NULLIF(SUM(total_budget), 0) * 100, 4
    ) AS mapped_utilization_rate_pct,

    ROUND(SUM(operating_expenditure), 4)
        AS mapped_operating_expenditure,

    ROUND(SUM(development_expenditure), 4)
        AS mapped_development_expenditure

FROM analytics.vw_sector_financial_summary;


-- 16.11.3 HIGHEST AND LOWEST KPI PERFORMANCE

(
    SELECT
        'Highest Utilization' AS kpi,
        sector_name,
        ROUND(
            actual_expenditure
            / NULLIF(total_budget, 0) * 100, 4
        ) AS kpi_value_pct
    FROM analytics.vw_sector_financial_summary
    ORDER BY
        actual_expenditure / NULLIF(total_budget, 0) DESC
    LIMIT 1
)

UNION ALL

(
    SELECT
        'Lowest Utilization' AS kpi,
        sector_name,
        ROUND(
            actual_expenditure
            / NULLIF(total_budget, 0) * 100, 4
        ) AS kpi_value_pct
    FROM analytics.vw_sector_financial_summary
    ORDER BY
        actual_expenditure / NULLIF(total_budget, 0) ASC
    LIMIT 1
);


-- 16.11.4 KPI DATA QUALITY VALIDATION

SELECT
    COUNT(*) AS sector_records,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
    ) AS missing_budget,

    COUNT(*) FILTER (
        WHERE actual_expenditure IS NULL
    ) AS missing_actual,

    COUNT(*) FILTER (
        WHERE total_budget <= 0
    ) AS non_positive_budget,

    COUNT(*) FILTER (
        WHERE actual_expenditure < 0
    ) AS negative_actual,

    COUNT(*) FILTER (
        WHERE ministry_count <= 0
    ) AS invalid_ministry_count

FROM analytics.vw_sector_financial_summary;


-- 16.11.5 OPERATING + DEVELOPMENT COMPONENT CHECK

SELECT
    sector_name,

    ROUND(
        operating_expenditure
        + development_expenditure
        - actual_expenditure, 4
    ) AS component_difference,

    CASE
        WHEN ABS(
            operating_expenditure
            + development_expenditure
            - actual_expenditure
        ) <= 0.001
        THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM analytics.vw_sector_financial_summary
ORDER BY sector_name;


-- ============================================================
-- END OF STEP 16.11
-- ============================================================
