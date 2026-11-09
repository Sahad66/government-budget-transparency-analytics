
-- ============================================================
-- PROJECT: GOVERNMENT BUDGET TRANSPARENCY & SPENDING EFFICIENCY
-- PHASE 4: ADVANCED SQL & BUSINESS ANALYSIS
-- STEP 15: DEPARTMENT-WISE BUDGET ANALYSIS
-- DATABASE: government_budget_analytics
-- ============================================================


-- 15.1 MINISTRY-WISE BUDGET OVERVIEW
-- Expected: 62 rows

SELECT
    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,
    f.budget_variance,
    f.budget_utilization_rate,
    
    f.operating_expenditure,
    f.development_expenditure,
    f.standard_unit

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY f.total_budget DESC;


-- 15.2 TOP 10 MINISTRIES BY BUDGET ALLOCATION

SELECT
    ROW_NUMBER() OVER (
        ORDER BY f.total_budget DESC
    ) AS budget_rank,

    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,
    f.budget_variance,
    f.budget_utilization_rate

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY f.total_budget DESC

LIMIT 10;


-- 15.3 BOTTOM 10 MINISTRIES BY BUDGET ALLOCATION

SELECT
    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,
    f.budget_variance,
    f.budget_utilization_rate

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY f.total_budget ASC

LIMIT 10;


-- 15.4 TOP 10 MINISTRIES BY ACTUAL EXPENDITURE

SELECT
    DENSE_RANK() OVER (
        ORDER BY f.actual_expenditure DESC
    ) AS expenditure_rank,

    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,
    f.budget_variance,
    f.budget_utilization_rate

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY f.actual_expenditure DESC

LIMIT 10;


-- 15.5 HIGHEST AND LOWEST BUDGET UTILIZATION

SELECT
    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,
    f.budget_utilization_rate,
    f.budget_variance,

    CASE
        WHEN f.budget_utilization_rate > 100
            THEN 'Above Budget'
        WHEN f.budget_utilization_rate = 100
            THEN 'Fully Utilized'
        WHEN f.budget_utilization_rate < 100
            THEN 'Below Budget'
        ELSE 'Not Classified'
    END AS utilization_status

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY f.budget_utilization_rate DESC;


-- 15.6 MINISTRIES WITH HIGHEST UNSPENT BUDGET

SELECT
    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,

    f.budget_variance AS unspent_budget,

    f.budget_utilization_rate

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

WHERE f.budget_variance > 0

ORDER BY f.budget_variance DESC

LIMIT 10;


-- 15.7 MINISTRIES WITH BUDGET OVERRUN

SELECT
    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure,

    ABS(f.budget_variance) AS amount_above_budget,

    f.budget_variance,
    f.budget_utilization_rate

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

WHERE f.budget_variance < 0

ORDER BY f.budget_variance ASC;


-- 15.8 OPERATING VS DEVELOPMENT EXPENDITURE

SELECT
    d.ministry_code,
    d.ministry_name,

    f.operating_expenditure,
    f.development_expenditure,
    f.actual_expenditure,

    ROUND(
        f.operating_expenditure
        / NULLIF(f.actual_expenditure, 0) * 100,
        2
    ) AS operating_share_pct,

    ROUND(
        f.development_expenditure
        / NULLIF(f.actual_expenditure, 0) * 100,
        2
    ) AS development_share_pct

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY f.actual_expenditure DESC;


-- 15.9 OVERALL MINISTRY BUDGET KPIs

SELECT
    COUNT(*) AS total_ministries,

    ROUND(SUM(f.total_budget), 4)
        AS total_budget,

    ROUND(SUM(f.actual_expenditure), 4)
        AS total_actual_expenditure,

    ROUND(SUM(f.budget_variance), 4)
        AS total_budget_variance,

    ROUND(
        SUM(f.actual_expenditure)
        / NULLIF(SUM(f.total_budget), 0) * 100,
        4
    ) AS overall_utilization_pct,

    ROUND(AVG(f.budget_utilization_rate), 4)
        AS average_ministry_utilization,

    COUNT(*) FILTER (
        WHERE f.budget_variance < 0
    ) AS overspending_ministries,

    COUNT(*) FILTER (
        WHERE f.budget_variance > 0
    ) AS underspending_ministries

FROM analytics.fact_ministry_budget f;


-- 15.10 TOP 10 MINISTRIES' SHARE OF TOTAL BUDGET

WITH ranked_ministries AS (

    SELECT
        d.ministry_name,
        f.total_budget,

        ROW_NUMBER() OVER (
            ORDER BY f.total_budget DESC
        ) AS budget_rank

    FROM analytics.fact_ministry_budget f

    JOIN analytics.dim_ministry d
        ON f.ministry_id = d.ministry_id
),

budget_summary AS (

    SELECT
        SUM(total_budget) AS total_budget

    FROM ranked_ministries
)

SELECT
    SUM(r.total_budget) AS top_10_budget,

    b.total_budget AS overall_budget,

    ROUND(
        SUM(r.total_budget)
        / NULLIF(b.total_budget, 0) * 100,
        2
    ) AS top_10_budget_share_pct

FROM ranked_ministries r

CROSS JOIN budget_summary b

WHERE r.budget_rank <= 10

GROUP BY b.total_budget;


-- 15.11 FINAL MINISTRY PERFORMANCE CLASSIFICATION

SELECT
    d.ministry_code,
    d.ministry_name,

    f.total_budget,
    f.actual_expenditure,
    f.budget_variance,
    f.budget_utilization_rate,

    CASE
        WHEN f.budget_variance < 0
            THEN 'Budget Overrun'

        WHEN f.budget_utilization_rate >= 90
            THEN 'High Utilization'

        WHEN f.budget_utilization_rate >= 70
            THEN 'Moderate Utilization'

        ELSE 'Low Utilization'
    END AS budget_performance_category

FROM analytics.fact_ministry_budget f

JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id

ORDER BY
    f.budget_utilization_rate DESC;
