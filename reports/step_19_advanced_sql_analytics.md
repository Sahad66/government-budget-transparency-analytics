# Step 19 — Advanced SQL Analytics Report

## 1. Project Overview

**Project:** Government Budget Transparency & Spending Efficiency Analytics  
**Phase:** Phase 4 — Advanced SQL Analytics  
**Step:** 19 — Advanced SQL Analytics  
**Dataset:** Bangladesh Government Budget 2024–2025  
**Unit:** BDT Crore  
**Coverage:** 62 ministries/divisions  
**Source status:** Draft government budget documents

This report consolidates the findings from:

- 19.1 Ministry Financial Performance Benchmarking
- 19.2 Ministry Ranking & Percentile Analysis
- 19.3 Budget Allocation vs Expenditure Relationship Analysis
- 19.4 Window Function Comparative Analysis
- 19.5 Advanced CTE & Conditional Aggregation
- 19.6 Advanced SQL Data Validation

## 2. Dataset Scope and Important Limitations

The analysis covers 62 ministry-level records for one fiscal year: 2024–2025.

Important data handling principles:

1. Financial values are expressed in BDT Crore.
2. Original source values are preserved.
3. Missing values are not automatically treated as zero.
4. Negative financial component values are preserved for review.
5. Government-level and ministry-level financial records remain separate.
6. Source documents are Draft, not audited final figures.
7. Only one fiscal year is available; historical growth comparisons cannot be calculated.

## 3. Step 19.1 — Ministry Financial Performance Benchmarking

### Objective

Compare ministry-level budget utilization against the overall ministry benchmark.

### Overall benchmark results

| Metric | Result |
|---|---:|
| Ministry count | 62 |
| Average budget | 12,854.8369 |
| Average actual expenditure | 10,214.7521 |
| Average utilization | 69.8787% |
| Median utilization | 71.7569% |
| Minimum utilization | 1.5740% |
| Maximum utilization | 159.5952% |
| Utilization standard deviation | 24.0181 |

### Benchmark classification

| Classification | Ministry count | Share |
|---|---:|---:|
| Above budget | 3 | 4.84% |
| Above average utilization | 31 | 50.00% |
| Below average utilization | 28 | 45.16% |
| Total | 62 | 100.00% |

### Notable observations

- Financial Institutions Division recorded 159.5952% utilization.
- Ministry of Food recorded 122.6408%.
- Ministry of Water Resources recorded 109.4687%.
- Planning Division recorded the lowest utilization at 1.5740%.

### Validation

- Total records: 62
- Distinct ministries: 62
- Missing values: 0
- Invalid budget records: 0
- Invalid utilization records: 0
- Status: PASS

**Interpretation:** Above-average utilization does not automatically mean better performance. These are analytical comparisons, not official government performance ratings.

## 4. Step 19.2 — Ministry Ranking & Percentile Analysis

### Objective

Rank ministries using budget, expenditure, utilization and variance, and compare their relative positions.

### Budget ranking — Top 10

| Rank | Ministry | Budget (BDT Crore) |
|---:|---|---:|
| 1 | Finance Division | 248,203.2713 |
| 2 | Local Government Division | 45,205.5500 |
| 3 | Secondary and Higher Education Division | 44,108.3400 |
| 4 | Ministry of Defence | 42,314.9149 |
| 5 | Ministry of Primary and Mass Education | 38,819.2700 |
| 6 | Road Transport and Highways Division | 38,143.2850 |
| 7 | Health Services Division | 30,125.1895 |
| 8 | Power Division | 29,229.9250 |
| 9 | Ministry of Agriculture | 27,214.3100 |
| 10 | Public Security Division | 26,876.6994 |

### Utilization ranking observations

| Ministry | Utilization |
|---|---:|
| Financial Institutions Division | 159.5952% |
| Ministry of Food | 122.6408% |
| Ministry of Water Resources | 109.4687% |
| Planning Division | 1.5740% |

### Utilization quartiles

| Quartile | Ministry count | Average utilization | Minimum | Maximum |
|---|---:|---:|---:|---:|
| Top | 16 | 97.2084% | 86.5967% | 159.5952% |
| Upper-middle | 16 | 78.0749% | 71.3063% | 85.5401% |
| Lower-middle | 15 | 61.5223% | 54.0229% | 70.4095% |
| Bottom | 15 | 40.3408% | 1.5740% | 51.1702% |

### SQL concepts applied

- RANK()
- DENSE_RANK()
- ROW_NUMBER()
- PERCENT_RANK()
- CUME_DIST()
- NTILE(4)

### Validation

- Total records: 62
- Distinct ministries: 62
- Missing ranking values: 0
- Quartiles generated: 4
- Status: PASS

**Interpretation:** RANK can leave gaps after tied values; DENSE_RANK does not. ROW_NUMBER provides a unique sequence. Quartiles show relative distribution, not official performance categories.

## 5. Step 19.3 — Budget Allocation vs Expenditure Relationship Analysis

### Objective

Measure the relationship between budget allocation and actual expenditure and compare budget and expenditure shares.

### Correlation results

| Analysis | Ministries | Correlation |
|---|---:|---:|
| Pearson correlation | 62 | 0.9932 |
| Spearman rank correlation | 62 | 0.9541 |
| Pearson excluding Finance Division | 61 | 0.9627 |

The results indicate a strong positive relationship between budget allocation and actual expenditure.

The relationship remains strong even after excluding Finance Division.

### Budget quartile analysis

| Quartile | Ministries | Budget | Actual expenditure | Variance | Utilization |
|---|---:|---:|---:|---:|---:|
| Top | 16 | 659,128.9067 | 536,155.3297 | 122,973.5770 | 81.3430% |
| Upper-middle | 16 | 104,392.0203 | 75,856.4758 | 28,535.5445 | 72.6650% |
| Lower-middle | 15 | 28,386.8367 | 18,096.0121 | 10,290.8246 | 63.7479% |
| Bottom | 15 | 5,092.1270 | 3,206.8103 | 1,885.3167 | 62.9759% |

### Budget share vs expenditure share

| Ministry | Budget share | Expenditure share | Difference |
|---|---:|---:|---:|
| Finance Division | 31.1422% | 37.4523% | +6.3101 pp |
| Road Transport and Highways Division | 4.7859% | 2.8277% | -1.9581 pp |
| Health Services Division | 3.7798% | 2.3249% | -1.4550 pp |
| Ministry of Railways | 2.2675% | 1.0824% | -1.1851 pp |
| Planning Division | 0.8146% | 0.0161% | -0.7985 pp |

### Validation

- Total records: 62
- Distinct ministries: 62
- Missing ministry IDs: 0
- Missing budget: 0
- Missing actual expenditure: 0
- Invalid budget: 0
- Negative actual expenditure: 0
- Variance mismatch: 0
- Status: PASS

**Interpretation:** Correlation does not establish causation. Differences between budget share and expenditure share are descriptive indicators and require further financial context.

## 6. Step 19.4 — Window Function Comparative Analysis

### Objective

Use SQL window functions to analyze rankings, cumulative financial values, contribution percentages and expenditure composition.

### Analysis performed

1. Budget ranking and cumulative budget share.
2. Actual expenditure ranking and cumulative expenditure share.
3. Positive budget variance contribution and cumulative contribution.
4. Operating versus development expenditure composition.
5. Ministry utilization ranking.
6. Final data quality validation.

### Key findings

- Total ministries: 62.
- Finance Division's actual expenditure: 237,190.7793 Crore.
- Finance Division's expenditure share: 37.4523%.
- Top 10 ministries account for 75.7960% of cumulative actual expenditure.
- Top 10 positive-variance contributors account for 64.0809% of total positive variance.
- Financial Institutions Division recorded the highest utilization at 159.5952%.
- Planning Division recorded the lowest utilization at 1.5740%.

### Negative operating component exception

Power Division has:

| Component | Amount (BDT Crore) |
|---|---:|
| Operating expenditure | -16.9959 |
| Development expenditure | 22,494.9584 |
| Actual expenditure | 22,477.9625 |

The negative operating value is preserved. It requires source-level investigation and must not be automatically changed to zero.

### Validation

- Total records: 62
- Distinct ministries: 62
- Missing budget: 0
- Missing actual expenditure: 0
- Missing operating expenditure: 0
- Missing development expenditure: 0
- Non-positive budget: 0
- Negative actual expenditure: 0
- Variance mismatch: 0
- Status: PASS

## 7. Step 19.5 — Advanced CTE & Conditional Aggregation

### Objective

Combine multiple analytical stages using Common Table Expressions (CTEs), CASE expressions and conditional aggregation.

### Analysis performed

- Ministry financial profiles.
- Utilization category summaries.
- Variance direction versus utilization categories.
- Operating versus development expenditure classification.
- Financial review exception identification.
- Consolidated validation.

### Utilization category summary

| Category | Ministries | Budget | Actual expenditure | Net variance |
|---|---:|---:|---:|---:|
| Over 100% | 3 | 21,367.9636 | 25,994.4327 | -4,626.4691 |
| 90–100% | 5 | 262,451.4318 | 250,084.0959 | 12,367.3359 |
| 75–89.99% | 20 | 277,589.4771 | 232,986.4743 | 44,603.0028 |
| 50–74.99% | 21 | 112,303.9947 | 71,916.3329 | 40,387.6618 |
| Below 50% | 13 | 123,287.0235 | 52,333.2921 | 70,953.7314 |

### Variance direction summary

- Overspending ministries: 3.
- Ministries with unspent budget: 59.
- Total overspending net variance: -4,626.4691 Crore.
- Total positive variance: 168,311.7319 Crore.

### Expenditure composition classification

| Classification | Ministries |
|---|---:|
| Development-dominant | 20 |
| Operating-dominant | 41 |
| Negative component review | 1 |

Power Division is classified separately because of its negative operating component.

### Validation

- Total records: 62
- Distinct ministries: 62
- Missing financial values: 0
- Variance mismatch: 0
- Component mismatch above tolerance: 0
- Negative operating component count: 1
- Negative development component count: 0
- Status: PASS

## 8. Step 19.6 — Advanced SQL Data Validation

### Objective

Perform consolidated validation of dimension integrity, relationships, financial calculations, expenditure components and analytical exceptions.

### Validation results

| Validation check | Result |
|---|---:|
| Total records | 62 |
| Distinct ministries | 62 |
| Orphan ministry references | 0 |
| Orphan fiscal year references | 0 |
| Missing financial values | 0 |
| Invalid budgets | 0 |
| Negative actual expenditure | 0 |
| Variance mismatches | 0 |
| Component mismatches | 0 |
| Negative operating components | 1 |
| Negative development components | 0 |
| Duplicate ministry-year groups | 0 |
| Final validation | PASS |

### Financial exceptions identified

| Ministry | Exception |
|---|---|
| Power Division | Negative operating component; unspent budget review |
| Financial Institutions Division | Overspending review |
| Ministry of Food | Overspending review |
| Ministry of Water Resources | Overspending review |

These exceptions are analytical review flags. They are not audit findings or evidence of fraud.

## 9. Consolidated Findings

The Advanced SQL analysis identified the following major observations:

1. The analysis covers 62 ministries for fiscal year 2024–2025.
2. Pearson correlation between budget and actual expenditure is 0.9932.
3. Spearman rank correlation is 0.9541.
4. Finance Division accounts for 37.4523% of total ministry-level actual expenditure.
5. The top 10 ministries account for 75.7960% of cumulative actual expenditure.
6. Three ministries recorded expenditure above their budget.
7. Fifty-nine ministries recorded positive budget variance.
8. Planning Division recorded 1.5740% utilization.
9. Power Division contains a negative operating expenditure component of -16.9959 Crore.
10. All final validation checks in Step 19.1–19.6 passed.

## 10. Important Data Limitations and Interpretation Rules

### Draft source data

The source documents are Draft. Findings should not be presented as final audited government expenditure figures.

### One-year coverage

Only fiscal year 2024–2025 is available. Year-over-year growth and multi-year trends cannot be calculated.

Do not replace unavailable historical values with zero or fabricated values.

### Correlation

A strong correlation does not prove that budget allocation caused expenditure.

### Utilization

Utilization above or below an analytical threshold does not independently establish good or poor performance.

### Variance

Positive variance means actual expenditure is below the compared budget amount. Negative variance indicates actual expenditure exceeds that budget amount.

These values require context such as fund release timing, procurement, commitments, project progress and revised allocations.

### Negative component

Power Division's negative operating expenditure is preserved and requires source-level review.

### Government and ministry reconciliation

Previously identified government-level and ministry-level differences remain preserved. No values have been artificially adjusted to force reconciliation.

### Review classifications

Risk scores, outlier labels, utilization categories and review flags are analytical tools, not official government ratings, audit conclusions or findings of misconduct.

## 11. SQL Skills Demonstrated

The project applied the following advanced PostgreSQL capabilities:

- Multi-table joins.
- Common Table Expressions (CTEs).
- Conditional aggregation.
- CASE expressions.
- Aggregate functions.
- Window functions.
- RANK, DENSE_RANK and ROW_NUMBER.
- PERCENT_RANK and CUME_DIST.
- NTILE.
- LAG.
- CORR and statistical calculations.
- Percentile and quartile analysis.
- Cumulative sums and contribution analysis.
- Data quality and financial reconciliation checks.
- Views and temporary tables.

## 12. Final Step 19 Status

| Substep | Description | Status |
|---|---|---|
| 19.1 | Ministry Financial Performance Benchmarking | COMPLETED |
| 19.2 | Ministry Ranking & Percentile Analysis | COMPLETED |
| 19.3 | Budget Allocation vs Expenditure Relationship Analysis | COMPLETED |
| 19.4 | Window Function Comparative Analysis | COMPLETED |
| 19.5 | Advanced CTE & Conditional Aggregation | COMPLETED |
| 19.6 | Advanced SQL Data Validation | COMPLETED |
| 19.7 | Consolidated Advanced SQL Analytics Report | REPORT CREATED |

**Phase 4 — Step 19: COMPLETED**

---

**Next Phase:** Phase 5 — Power BI Dashboard Development.

**Project note:** All findings in this report should be interpreted within the scope, coverage and limitations of the source data.