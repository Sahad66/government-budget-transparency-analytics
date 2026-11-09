# Step 16 — Sector-wise Expenditure Analysis

**Project:** Government Budget Transparency & Spending Efficiency Analytics  
**Phase:** Phase 4 — Advanced SQL and Business Analysis  
**Database:** PostgreSQL  
**Step:** 16.1–16.24

---

## 1. Business Objective

The objective of this step is to analyze government budget allocation and actual expenditure across sectors.

The analysis aims to understand:

- How much budget is allocated to each sector.
- How much each sector actually spends.
- Which sectors have the largest budget variances.
- How effectively allocated budgets are utilized.
- How expenditure is distributed between operating and development activities.
- Which sectors contribute most to total mapped expenditure.
- Whether the underlying mapping and financial data are reliable.

The findings will support financial transparency, resource allocation analysis and evidence-based decision-making.

## 2. Existing Database Architecture

| Table | Purpose |
|---|---|
| `analytics.dim_ministry` | Ministry master data |
| `analytics.dim_fiscal_year` | Fiscal year dimension |
| `analytics.fact_ministry_budget` | Ministry financial facts |
| `analytics.fact_government_budget_summary` | Government-level financial summary |
| `analytics.source_documents` | Source document metadata |
| `staging.statement_1_import` | Government budget source data |
| `staging.statement_2_import` | Ministry-level source data |

### Important architecture decision

The existing database does not have a direct Sector classification field.

Therefore, a separate Sector dimension and Ministry-to-Sector mapping are required.

Government-level and Ministry-level financial facts must not be combined indiscriminately.

## 3. New Database Objects

### 3.1 Sector dimension

`analytics.dim_sector`

Stores the sector master list.

### 3.2 Ministry-Sector bridge

`analytics.bridge_ministry_sector`

Stores the Ministry-to-Sector relationship.

Important fields:

- Ministry ID
- Sector ID
- Allocation share
- Mapping status
- Mapping source
- Mapping notes

### 3.3 Reusable analytical views

`analytics.vw_sector_ministry_financials`

Provides validated Ministry-Sector financial records.

`analytics.vw_sector_financial_summary`

Provides aggregated sector-level financial information.

Only approved, evidence-supported mappings with a total allocation share of 100% are included.

## 4. Detailed Work Breakdown

### 16.1 — Source Inspection and Validation

Inspect source tables, record counts, financial columns, units and source documents.

Checks:

- Ministry record count.
- Fact table record count.
- Duplicate Ministry-Fiscal Year combinations.
- Missing financial values.
- Operating and development component comparison.

### 16.2 — Sector Dimension Creation

Create a dedicated Sector master table.

### 16.3 — Ministry-to-Sector Mapping

Create the mapping table and validate:

- Approved mapping status.
- Source evidence.
- Allocation share.
- Ministry mapping completeness.

A Ministry can be assigned to multiple sectors only when a documented allocation methodology supports it.

### 16.4 — Sector Budget Allocation

Calculate budget allocation by sector using approved allocation shares.

### 16.5 — Sector Actual Expenditure

Calculate actual expenditure by sector.

### 16.6 — Budget Variance

Formula:

`Budget Variance = Total Budget - Actual Expenditure`

Positive variance indicates expenditure below budget. Negative variance indicates expenditure above budget.

### 16.7 — Budget Utilization

Formula:

`Utilization % = (Actual Expenditure / Total Budget) × 100`

### 16.8 — Operating vs Development

Analyze operating and development expenditure by sector.

Calculate the share of each expenditure component.

### 16.9 — Top and Bottom Sectors

Rank sectors using actual expenditure.

### 16.10 — Sector Contribution

Calculate each sector's contribution to total mapped expenditure.

This is not automatically the same as its contribution to total government expenditure.

### 16.11 — Consolidated KPI Summary

Prepare a consolidated dataset containing:

- Total budget.
- Actual expenditure.
- Budget variance.
- Utilization percentage.
- Operating expenditure.
- Development expenditure.
- Ministry count.

### 16.12 — Data Quality Validation

Check:

- Missing financial values.
- Component reconciliation.
- Mapping evidence.
- Allocation share validity.

### 16.13 — Analytical Completeness

Review the number of sectors and sector-year records included in the analytical view.

### 16.14 — Mapping Coverage

Calculate the percentage of ministries with complete approved mappings.

Formula:

`Mapping Coverage % = Fully Mapped Ministries / Total Ministries × 100`

### 16.15 — Unmapped Ministry Impact

Calculate budget and actual expenditure associated with ministries that do not have valid approved mappings.

This identifies the financial scope excluded from sector analysis.

### 16.16 — Reconciliation

Compare total Ministry-level financial figures against mapped sector totals.

The difference represents unmapped or excluded financial amounts, subject to the mapping and aggregation rules.

### 16.17 — Operating and Development Shares

Calculate the percentage distribution of operating and development expenditure.

### 16.18 — Multi-Metric Ranking

Rank sectors independently by:

- Budget.
- Actual expenditure.
- Utilization.

### 16.19 — Outlier Analysis

Use the Interquartile Range (IQR) method to flag unusual utilization values.

These are statistical flags requiring investigation, not evidence of errors or misconduct.

### 16.20 — Data Quality Scorecard

Prepare a sector-level financial completeness status.

### 16.21 — SQL Performance Optimization

Create supporting indexes and review query execution plans with:

`EXPLAIN (ANALYZE, BUFFERS)`

Indexes should be retained only when their benefit justifies their storage and write overhead.

### 16.22 — Power BI Dataset Export

Export analytical results to CSV.

### 16.23 — Business Insight Development

Answer questions about:

- Highest budget sectors.
- Highest actual expenditure sectors.
- Largest positive budget variances.
- Expenditure above budget.
- Operating and development composition.

### 16.24 — Final Validation

Review mapping, allocation, evidence, analytical record counts and data quality before signing off the step.

---

## 5. SQL Concepts Used

- JOIN
- CTE
- GROUP BY
- HAVING
- FILTER
- CASE WHEN
- NULLIF
- ROUND
- DENSE_RANK
- Window Functions
- PERCENTILE_CONT
- Views
- Primary Keys
- Foreign Keys
- Composite Keys
- Indexes
- EXPLAIN ANALYZE
- CSV Export

## 6. Expected Deliverables

| File | Description |
|---|---|
| `sector_budget_analysis.csv` | Sector budget allocation |
| `sector_expenditure_analysis.csv` | Actual expenditure |
| `sector_variance_analysis.csv` | Budget variance |
| `sector_utilization_analysis.csv` | Utilization percentage |
| `sector_operating_development.csv` | Operating vs development |
| `sector_ranking.csv` | Sector ranking |
| `sector_outlier_analysis.csv` | Statistical outlier results |
| `sector_reconciliation.csv` | Ministry vs mapped sector reconciliation |
| `sector_kpi_summary.csv` | Consolidated KPIs |

The corresponding queries must be exported individually. The SQL framework includes the core export commands; the additional outlier and reconciliation exports can be added after reviewing the results.

## 7. Business Questions

1. Which sectors receive the largest budget allocation?
2. Which sectors have the highest actual expenditure?
3. Which sectors have the largest positive budget variance?
4. Which sectors have expenditure above budget?
5. How does utilization differ across sectors?
6. What proportion of expenditure is operating versus development?
7. Which sectors contribute most to mapped expenditure?
8. How much Ministry-level expenditure remains unmapped?
9. Are there unusual utilization values?
10. How reliable is the Ministry-to-Sector mapping?

## 8. Data Governance

1. Do not convert missing financial values into zero.
2. Do not invent sector classifications.
3. Preserve source units and standardized units.
4. Keep government and Ministry fact tables separate.
5. Do not force different source totals to match.
6. Preserve Draft source status.
7. Document every allocation share.
8. Treat statistical outliers as review flags.
9. Do not interpret utilization alone as a complete measure of performance.
10. Retain source evidence for mapping decisions.

## 9. Completion Criteria

Step 16 can be marked complete when:

- Sector dimension exists.
- Mapping has documented evidence.
- Approved allocation shares are valid.
- Mapping coverage is calculated.
- Sector financial views are populated.
- Budget, expenditure and variance analyses execute.
- Utilization and composition metrics are calculated.
- Reconciliation is reviewed.
- Data quality checks are reviewed.
- CSV datasets are exported.
- Business findings and limitations are documented.

## 10. Current Status

**Status: Full SQL framework prepared; execution and mapping approval pending.**

The database structure has been inspected and the analytical architecture has been designed.

Actual sector findings must not be published until the mapping evidence and analytical results have been validated.

## 11. Conclusion

Step 16 extends the project from Ministry-level financial analysis to controlled Sector-level analysis.

It introduces a documented mapping architecture, reusable analytical views, financial KPIs, reconciliation, outlier analysis and Power BI-ready datasets.

The design prioritizes data quality, traceability and responsible interpretation of government financial information.