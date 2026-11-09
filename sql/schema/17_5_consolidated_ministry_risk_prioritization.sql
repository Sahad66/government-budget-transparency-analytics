-- ============================================================
-- STEP 17.5
-- CONSOLIDATED MINISTRY-WISE FINANCIAL RISK PRIORITIZATION
-- Purpose: Analytical review-priority ranking
-- ============================================================

DROP TABLE IF EXISTS pg_temp.tmp_ministry_risk_prioritization;

CREATE TEMP TABLE tmp_ministry_risk_prioritization AS
WITH base AS (
    SELECT
        dm.ministry_id,
        dm.ministry_code,
        dm.ministry_name,
        fmb.total_budget,
        fmb.actual_expenditure,
        fmb.budget_variance,
        ROUND(
            fmb.actual_expenditure
            / NULLIF(fmb.total_budget, 0) * 100,
            4
        ) AS utilization_pct
    FROM analytics.fact_ministry_budget fmb
    INNER JOIN analytics.dim_ministry dm
        ON fmb.ministry_id = dm.ministry_id
),
variance_bounds AS (
    -- Positive variance only, consistent with Step 17.4.2
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY budget_variance::double precision)
            AS q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY budget_variance::double precision)
            AS q3
    FROM base
    WHERE budget_variance > 0
),
utilization_bounds AS (
    -- Utilization benchmarks across all ministries
    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY utilization_pct::double precision)
            AS q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY utilization_pct::double precision)
            AS q3
    FROM base
),
thresholds AS (
    SELECT
        (vb.q3 + 1.5 * (vb.q3 - vb.q1))::numeric AS variance_upper_bound,
        (ub.q1 - 1.5 * (ub.q3 - ub.q1))::numeric AS utilization_lower_bound,
        (ub.q3 + 1.5 * (ub.q3 - ub.q1))::numeric AS utilization_upper_bound
    FROM variance_bounds vb
    CROSS JOIN utilization_bounds ub
),
flags AS (
    SELECT
        b.*,
        t.variance_upper_bound,
        t.utilization_lower_bound,
        t.utilization_upper_bound,

        (b.budget_variance < 0) AS overspending_flag,

        (
            b.budget_variance > t.variance_upper_bound
            AND b.budget_variance > 0
        ) AS high_variance_outlier_flag,

        (
            b.utilization_pct < t.utilization_lower_bound
        ) AS low_utilization_outlier_flag,

        (
            b.utilization_pct > t.utilization_upper_bound
        ) AS high_utilization_outlier_flag

    FROM base b
    CROSS JOIN thresholds t
),
scored AS (
    SELECT
        *,
        (
            CASE WHEN overspending_flag THEN 3 ELSE 0 END
            +
            CASE WHEN high_variance_outlier_flag THEN 2 ELSE 0 END
            +
            CASE WHEN low_utilization_outlier_flag THEN 2 ELSE 0 END
            +
            CASE WHEN high_utilization_outlier_flag THEN 2 ELSE 0 END
        ) AS review_priority_score
    FROM flags
)
SELECT
    *,
    CASE
        WHEN review_priority_score >= 3
            THEN 'HIGH REVIEW PRIORITY'
        WHEN review_priority_score >= 2
            THEN 'MEDIUM REVIEW PRIORITY'
        ELSE 'ROUTINE MONITORING'
    END AS review_priority
FROM scored;


-- ============================================================
-- 17.5.1 MINISTRY-WISE REVIEW PRIORITY DETAIL
-- ============================================================

SELECT
    ministry_code,
    ministry_name,
    ROUND(total_budget, 4) AS total_budget,
    ROUND(actual_expenditure, 4) AS actual_expenditure,
    ROUND(budget_variance, 4) AS budget_variance,
    utilization_pct,

    overspending_flag,
    high_variance_outlier_flag,
    low_utilization_outlier_flag,
    high_utilization_outlier_flag,

    review_priority_score,
    review_priority

FROM tmp_ministry_risk_prioritization
ORDER BY
    review_priority_score DESC,
    ABS(budget_variance) DESC,
    ministry_name;


-- ============================================================
-- 17.5.2 REVIEW PRIORITY SUMMARY
-- ============================================================

SELECT
    review_priority,
    COUNT(*) AS ministry_count,
    ROUND(
        COUNT(*) * 100.0
        / NULLIF((SELECT COUNT(*) FROM tmp_ministry_risk_prioritization), 0),
        2
    ) AS ministry_share_pct,

    SUM(overspending_flag::integer) AS overspending_count,
    SUM(high_variance_outlier_flag::integer) AS high_variance_outlier_count,
    SUM(low_utilization_outlier_flag::integer) AS low_utilization_outlier_count,
    SUM(high_utilization_outlier_flag::integer) AS high_utilization_outlier_count,

    ROUND(SUM(total_budget), 4) AS total_budget,
    ROUND(SUM(actual_expenditure), 4) AS actual_expenditure,
    ROUND(SUM(budget_variance), 4) AS net_budget_variance

FROM tmp_ministry_risk_prioritization
GROUP BY review_priority
ORDER BY
    CASE review_priority
        WHEN 'HIGH REVIEW PRIORITY' THEN 1
        WHEN 'MEDIUM REVIEW PRIORITY' THEN 2
        WHEN 'ROUTINE MONITORING' THEN 3
        ELSE 4
    END;


-- ============================================================
-- 17.5.3 FLAG SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_ministries,
    SUM(overspending_flag::integer) AS overspending_ministries,
    SUM(high_variance_outlier_flag::integer) AS high_variance_outliers,
    SUM(low_utilization_outlier_flag::integer) AS low_utilization_outliers,
    SUM(high_utilization_outlier_flag::integer) AS high_utilization_outliers,
    SUM(CASE WHEN review_priority = 'HIGH REVIEW PRIORITY' THEN 1 ELSE 0 END)
        AS high_review_priority_count,
    SUM(CASE WHEN review_priority = 'MEDIUM REVIEW PRIORITY' THEN 1 ELSE 0 END)
        AS medium_review_priority_count,
    SUM(CASE WHEN review_priority = 'ROUTINE MONITORING' THEN 1 ELSE 0 END)
        AS routine_monitoring_count
FROM tmp_ministry_risk_prioritization;


-- ============================================================
-- 17.5.4 FINAL DATA QUALITY & LOGIC VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT ministry_id) AS distinct_ministries,
    COUNT(DISTINCT ministry_code) AS distinct_ministry_codes,

    COUNT(*) FILTER (
        WHERE ministry_id IS NULL
           OR ministry_code IS NULL
           OR ministry_name IS NULL
    ) AS missing_ministry_identity,

    COUNT(*) FILTER (
        WHERE total_budget IS NULL
           OR actual_expenditure IS NULL
           OR budget_variance IS NULL
           OR utilization_pct IS NULL
    ) AS missing_financial_metrics,

    COUNT(*) FILTER (
        WHERE overspending_flag IS NULL
           OR high_variance_outlier_flag IS NULL
           OR low_utilization_outlier_flag IS NULL
           OR high_utilization_outlier_flag IS NULL
           OR review_priority_score IS NULL
           OR review_priority IS NULL
    ) AS missing_risk_outputs,

    COUNT(*) FILTER (
        WHERE budget_variance
              <> ROUND(total_budget - actual_expenditure, 4)
    ) AS variance_calculation_mismatch,

    COUNT(*) FILTER (
        WHERE review_priority_score <>
            (
                CASE WHEN overspending_flag THEN 3 ELSE 0 END
                +
                CASE WHEN high_variance_outlier_flag THEN 2 ELSE 0 END
                +
                CASE WHEN low_utilization_outlier_flag THEN 2 ELSE 0 END
                +
                CASE WHEN high_utilization_outlier_flag THEN 2 ELSE 0 END
            )
    ) AS score_calculation_mismatch,

    CASE
        WHEN COUNT(*) = 62
         AND COUNT(DISTINCT ministry_id) = 62
         AND COUNT(DISTINCT ministry_code) = 62
         AND COUNT(*) FILTER (
             WHERE ministry_id IS NULL
                OR ministry_code IS NULL
                OR ministry_name IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL
                OR actual_expenditure IS NULL
                OR budget_variance IS NULL
                OR utilization_pct IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE overspending_flag IS NULL
                OR high_variance_outlier_flag IS NULL
                OR low_utilization_outlier_flag IS NULL
                OR high_utilization_outlier_flag IS NULL
                OR review_priority_score IS NULL
                OR review_priority IS NULL
         ) = 0
         AND COUNT(*) FILTER (
             WHERE budget_variance
                   <> ROUND(total_budget - actual_expenditure, 4)
         ) = 0
         AND COUNT(*) FILTER (
             WHERE review_priority_score <>
                (
                    CASE WHEN overspending_flag THEN 3 ELSE 0 END
                    +
                    CASE WHEN high_variance_outlier_flag THEN 2 ELSE 0 END
                    +
                    CASE WHEN low_utilization_outlier_flag THEN 2 ELSE 0 END
                    +
                    CASE WHEN high_utilization_outlier_flag THEN 2 ELSE 0 END
                )
         ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM tmp_ministry_risk_prioritization;

-- ============================================================
-- END OF STEP 17.5
-- ============================================================