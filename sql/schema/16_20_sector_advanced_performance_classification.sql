-- ============================================================
-- STEP 16.20: SECTOR ADVANCED PERFORMANCE CLASSIFICATION
-- Project: Government Budget Analytics
-- Unit: BDT Crore
-- ============================================================


-- 16.20.1 UTILIZATION-BASED CLASSIFICATION

SELECT
    sector_name,

    ROUND(
        (actual_expenditure
        / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS utilization_pct,

    CASE
        WHEN total_budget <= 0 THEN 'INVALID BUDGET'
        WHEN actual_expenditure / NULLIF(total_budget, 0) > 1
            THEN 'ABOVE 100%'
        WHEN actual_expenditure / NULLIF(total_budget, 0) >= 0.80
            THEN 'HIGH'
        WHEN actual_expenditure / NULLIF(total_budget, 0) >= 0.60
            THEN 'MODERATE'
        ELSE 'LOW'
    END AS utilization_class

FROM analytics.vw_sector_financial_summary

ORDER BY utilization_pct DESC;


-- 16.20.2 SPENDING GAP PERCENTAGE CLASSIFICATION

SELECT
    sector_name,

    ROUND(
        ((total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100)::numeric,
        4
    ) AS spending_gap_pct,

    CASE
        WHEN total_budget <= 0 THEN 'INVALID BUDGET'
        WHEN actual_expenditure > total_budget
            THEN 'OVERSHOOT'
        WHEN (total_budget - actual_expenditure)
             / NULLIF(total_budget, 0) <= 0.10
            THEN 'LOW GAP'
        WHEN (total_budget - actual_expenditure)
             / NULLIF(total_budget, 0) <= 0.30
            THEN 'MODERATE GAP'
        ELSE 'HIGH GAP'
    END AS spending_gap_class

FROM analytics.vw_sector_financial_summary

ORDER BY spending_gap_pct DESC;


-- 16.20.3 EXPENDITURE STRUCTURE CLASSIFICATION

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
            THEN 'OPERATING-ORIENTED'
        WHEN development_expenditure >
             operating_expenditure
            THEN 'DEVELOPMENT-ORIENTED'
        ELSE 'BALANCED'
    END AS expenditure_structure

FROM analytics.vw_sector_financial_summary

ORDER BY development_share_pct DESC;


-- 16.20.4 BUDGET VS EXPENDITURE CONTRIBUTION GAP

WITH sector_contribution AS (
    SELECT
        sector_name,
        total_budget,
        actual_expenditure,

        total_budget
        / NULLIF(SUM(total_budget) OVER (), 0) * 100
            AS budget_share_pct,

        actual_expenditure
        / NULLIF(SUM(actual_expenditure) OVER (), 0) * 100
            AS actual_share_pct

    FROM analytics.vw_sector_financial_summary
)

SELECT
    sector_name,

    ROUND(budget_share_pct::numeric, 4)
        AS budget_share_pct,

    ROUND(actual_share_pct::numeric, 4)
        AS actual_share_pct,

    ROUND(
        (actual_share_pct - budget_share_pct)::numeric,
        4
    ) AS contribution_difference_pp,

    CASE
        WHEN actual_share_pct > budget_share_pct
            THEN 'EXPENDITURE SHARE ABOVE BUDGET SHARE'
        WHEN actual_share_pct < budget_share_pct
            THEN 'EXPENDITURE SHARE BELOW BUDGET SHARE'
        ELSE 'SHARES ALIGNED'
    END AS contribution_status

FROM sector_contribution

ORDER BY contribution_difference_pp DESC;


-- 16.20.5 COMBINED ANALYTICAL CLASSIFICATION

WITH sector_metrics AS (
    SELECT
        sector_name,
        ministry_count,
        total_budget,
        actual_expenditure,
        operating_expenditure,
        development_expenditure,

        actual_expenditure
        / NULLIF(total_budget, 0) * 100
            AS utilization_pct,

        (total_budget - actual_expenditure)
        / NULLIF(total_budget, 0) * 100
            AS spending_gap_pct,

        operating_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure, 0
        ) * 100 AS operating_share_pct,

        development_expenditure
        / NULLIF(
            operating_expenditure + development_expenditure, 0
        ) * 100 AS development_share_pct

    FROM analytics.vw_sector_financial_summary
),

classified AS (
    SELECT
        *,

        CASE
            WHEN utilization_pct >= 80
                THEN 'HIGH'
            WHEN utilization_pct >= 60
                THEN 'MODERATE'
            ELSE 'LOW'
        END AS utilization_class,

        CASE
            WHEN spending_gap_pct <= 10
                THEN 'LOW GAP'
            WHEN spending_gap_pct <= 30
                THEN 'MODERATE GAP'
            ELSE 'HIGH GAP'
        END AS gap_class,

        CASE
            WHEN operating_share_pct >
                 development_share_pct
                THEN 'OPERATING-ORIENTED'
            WHEN development_share_pct >
                 operating_share_pct
                THEN 'DEVELOPMENT-ORIENTED'
            ELSE 'BALANCED'
        END AS expenditure_structure

    FROM sector_metrics
)

SELECT
    sector_name,
    ministry_count,

    ROUND(utilization_pct::numeric, 4)
        AS utilization_pct,

    utilization_class,

    ROUND(spending_gap_pct::numeric, 4)
        AS spending_gap_pct,

    gap_class,

    expenditure_structure,

    CASE
        WHEN utilization_class = 'HIGH'
         AND gap_class = 'LOW GAP'
            THEN 'HIGH UTILIZATION / LOW GAP'

        WHEN utilization_class = 'HIGH'
         AND gap_class = 'MODERATE GAP'
            THEN 'HIGH UTILIZATION / MODERATE GAP'

        WHEN utilization_class = 'HIGH'
         AND gap_class = 'HIGH GAP'
            THEN 'HIGH UTILIZATION / HIGH GAP'

        WHEN utilization_class = 'MODERATE'
         AND gap_class = 'LOW GAP'
            THEN 'MODERATE UTILIZATION / LOW GAP'

        WHEN utilization_class = 'MODERATE'
         AND gap_class = 'MODERATE GAP'
            THEN 'MODERATE UTILIZATION / MODERATE GAP'

        WHEN utilization_class = 'MODERATE'
         AND gap_class = 'HIGH GAP'
            THEN 'MODERATE UTILIZATION / HIGH GAP'

        WHEN utilization_class = 'LOW'
         AND gap_class = 'LOW GAP'
            THEN 'LOW UTILIZATION / LOW GAP'

        WHEN utilization_class = 'LOW'
         AND gap_class = 'MODERATE GAP'
            THEN 'LOW UTILIZATION / MODERATE GAP'

        ELSE 'LOW UTILIZATION / HIGH GAP'
    END AS combined_analytical_profile

FROM classified

ORDER BY utilization_pct DESC;


-- 16.20.6 CLASSIFICATION DISTRIBUTION SUMMARY

WITH classification AS (
    SELECT
        sector_name,

        CASE
            WHEN actual_expenditure
                 / NULLIF(total_budget, 0) >= 0.80
                THEN 'HIGH'
            WHEN actual_expenditure
                 / NULLIF(total_budget, 0) >= 0.60
                THEN 'MODERATE'
            ELSE 'LOW'
        END AS utilization_class

    FROM analytics.vw_sector_financial_summary
)

SELECT
    utilization_class,
    COUNT(*) AS sector_count,

    ROUND(
        (COUNT(*) * 100.0
        / NULLIF(SUM(COUNT(*)) OVER (), 0))::numeric,
        4
    ) AS sector_distribution_pct

FROM classification

GROUP BY utilization_class

ORDER BY
    CASE utilization_class
        WHEN 'HIGH' THEN 1
        WHEN 'MODERATE' THEN 2
        WHEN 'LOW' THEN 3
    END;


-- 16.20.7 FINAL CLASSIFICATION DATA QUALITY

SELECT
    COUNT(*) AS sector_count,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
           OR actual_expenditure IS NULL
           OR operating_expenditure IS NULL
           OR development_expenditure IS NULL
    ) AS missing_metric_count,

    COUNT(*) FILTER (
        WHERE total_budget <= 0
    ) AS invalid_budget_count,

    COUNT(*) FILTER (
        WHERE actual_expenditure < 0
           OR operating_expenditure < 0
           OR development_expenditure < 0
    ) AS negative_value_count,

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
    END AS classification_data_quality

FROM analytics.vw_sector_financial_summary;
