-- ============================================================
-- STEP 17.3: VARIANCE CONTRIBUTION & CONCENTRATION ANALYSIS
-- Project: Government Budget Transparency & Spending Efficiency
-- Unit: BDT Crore
-- ============================================================

-- 17.3.1 Ministry-wise contribution to positive budget variance
WITH ministry_variance AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        CASE
            WHEN f.budget_variance > 0 THEN f.budget_variance
            ELSE 0
        END AS positive_variance
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
ranked_variance AS (
    SELECT
        *,
        SUM(positive_variance) OVER () AS total_positive_variance,
        SUM(positive_variance) OVER (
            ORDER BY positive_variance DESC, ministry_code
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_variance
    FROM ministry_variance
)
SELECT
    ministry_code,
    ministry_name,
    total_budget,
    actual_expenditure,
    budget_variance,
    positive_variance,
    ROUND(
        positive_variance / NULLIF(total_positive_variance, 0) * 100,
        4
    ) AS contribution_pct,
    ROUND(
        cumulative_variance / NULLIF(total_positive_variance, 0) * 100,
        4
    ) AS cumulative_contribution_pct
FROM ranked_variance
WHERE positive_variance > 0
ORDER BY positive_variance DESC, ministry_code;


-- 17.3.2 Top 5, 10 and 20 ministries: cumulative contribution
WITH ranked_variance AS (
    SELECT
        m.ministry_name,
        f.budget_variance,
        SUM(
            CASE WHEN f.budget_variance > 0
                 THEN f.budget_variance ELSE 0 END
        ) OVER () AS total_positive_variance,
        ROW_NUMBER() OVER (
            ORDER BY
                CASE WHEN f.budget_variance > 0
                     THEN f.budget_variance ELSE 0 END DESC,
                m.ministry_code
        ) AS variance_rank
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
concentration AS (
    SELECT
        SUM(CASE WHEN variance_rank <= 5
                 AND budget_variance > 0
                 THEN budget_variance ELSE 0 END) AS top_5_variance,
        SUM(CASE WHEN variance_rank <= 10
                 AND budget_variance > 0
                 THEN budget_variance ELSE 0 END) AS top_10_variance,
        SUM(CASE WHEN variance_rank <= 20
                 AND budget_variance > 0
                 THEN budget_variance ELSE 0 END) AS top_20_variance,
        MAX(total_positive_variance) AS total_positive_variance
    FROM ranked_variance
)
SELECT
    total_positive_variance,
    top_5_variance,
    ROUND(top_5_variance / NULLIF(total_positive_variance, 0) * 100, 4)
        AS top_5_contribution_pct,
    top_10_variance,
    ROUND(top_10_variance / NULLIF(total_positive_variance, 0) * 100, 4)
        AS top_10_contribution_pct,
    top_20_variance,
    ROUND(top_20_variance / NULLIF(total_positive_variance, 0) * 100, 4)
        AS top_20_contribution_pct
FROM concentration;


-- 17.3.3 Ministry-wise contribution to gross overspending
WITH overspending AS (
    SELECT
        m.ministry_code,
        m.ministry_name,
        f.total_budget,
        f.actual_expenditure,
        f.budget_variance,
        ABS(f.budget_variance) AS overspending_amount
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
    WHERE f.budget_variance < 0
),
ranked_overspending AS (
    SELECT
        *,
        SUM(overspending_amount) OVER () AS total_overspending,
        SUM(overspending_amount) OVER (
            ORDER BY overspending_amount DESC, ministry_code
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_overspending
    FROM overspending
)
SELECT
    ministry_code,
    ministry_name,
    total_budget,
    actual_expenditure,
    budget_variance,
    overspending_amount,
    ROUND(
        overspending_amount / NULLIF(total_overspending, 0) * 100,
        4
    ) AS overspending_contribution_pct,
    ROUND(
        cumulative_overspending / NULLIF(total_overspending, 0) * 100,
        4
    ) AS cumulative_overspending_pct
FROM ranked_overspending
ORDER BY overspending_amount DESC;


-- 17.3.4 Gross positive, gross negative and net variance reconciliation
SELECT
    COUNT(*) AS ministry_count,
    ROUND(SUM(total_budget), 4) AS total_budget,
    ROUND(SUM(actual_expenditure), 4) AS total_actual_expenditure,
    ROUND(
        SUM(CASE WHEN budget_variance > 0
                 THEN budget_variance ELSE 0 END),
        4
    ) AS gross_positive_variance,
    ROUND(
        SUM(CASE WHEN budget_variance < 0
                 THEN ABS(budget_variance) ELSE 0 END),
        4
    ) AS gross_overspending,
    ROUND(SUM(budget_variance), 4) AS net_budget_variance,
    ROUND(
        SUM(CASE WHEN budget_variance > 0
                 THEN budget_variance ELSE 0 END)
        -
        SUM(CASE WHEN budget_variance < 0
                 THEN ABS(budget_variance) ELSE 0 END),
        4
    ) AS calculated_net_variance
FROM analytics.fact_ministry_budget;


-- 17.3.5 Positive variance concentration bands
WITH ranked_variance AS (
    SELECT
        m.ministry_name,
        f.budget_variance,
        ROW_NUMBER() OVER (
            ORDER BY
                CASE WHEN f.budget_variance > 0
                     THEN f.budget_variance ELSE 0 END DESC,
                m.ministry_code
        ) AS variance_rank
    FROM analytics.fact_ministry_budget f
    JOIN analytics.dim_ministry m
        ON f.ministry_id = m.ministry_id
),
positive_total AS (
    SELECT
        SUM(CASE WHEN budget_variance > 0
                 THEN budget_variance ELSE 0 END) AS total_positive_variance
    FROM ranked_variance
),
bands AS (
    SELECT
        CASE
            WHEN variance_rank <= 5 THEN 'TOP 5'
            WHEN variance_rank <= 10 THEN 'RANK 6-10'
            WHEN variance_rank <= 20 THEN 'RANK 11-20'
            ELSE 'REMAINING'
        END AS concentration_band,
        SUM(
            CASE WHEN budget_variance > 0
                 THEN budget_variance ELSE 0 END
        ) AS variance_amount
    FROM ranked_variance
    GROUP BY 1
)
SELECT
    b.concentration_band,
    ROUND(b.variance_amount, 4) AS variance_amount,
    ROUND(
        b.variance_amount / NULLIF(p.total_positive_variance, 0) * 100,
        4
    ) AS contribution_pct
FROM bands b
CROSS JOIN positive_total p
ORDER BY
    CASE b.concentration_band
        WHEN 'TOP 5' THEN 1
        WHEN 'RANK 6-10' THEN 2
        WHEN 'RANK 11-20' THEN 3
        ELSE 4
    END;


-- 17.3.6 Data quality validation
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE budget_variance IS NULL)
        AS missing_variance_count,
    COUNT(*) FILTER (
        WHERE total_budget IS NULL OR total_budget <= 0
    ) AS invalid_budget_count,
    COUNT(*) FILTER (
        WHERE budget_variance IS NOT NULL
          AND total_budget IS NOT NULL
          AND actual_expenditure IS NOT NULL
          AND ABS(
              budget_variance - (total_budget - actual_expenditure)
          ) > 0.0001
    ) AS variance_calculation_mismatch,
    COUNT(*) FILTER (WHERE budget_variance > 0)
        AS positive_variance_count,
    COUNT(*) FILTER (WHERE budget_variance < 0)
        AS overspending_count,
    CASE
        WHEN COUNT(*) = 62
         AND COUNT(*) FILTER (WHERE budget_variance IS NULL) = 0
         AND COUNT(*) FILTER (
             WHERE total_budget IS NULL OR total_budget <= 0
         ) = 0
         AND COUNT(*) FILTER (
             WHERE budget_variance IS NOT NULL
               AND total_budget IS NOT NULL
               AND actual_expenditure IS NOT NULL
               AND ABS(
                   budget_variance - (total_budget - actual_expenditure)
               ) > 0.0001
         ) = 0
        THEN 'PASS'
        ELSE 'REVIEW REQUIRED'
    END AS data_quality_status
FROM analytics.fact_ministry_budget;

-- END OF STEP 17.3