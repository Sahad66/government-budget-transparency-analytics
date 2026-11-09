# Step 16 — Sector-wise Expenditure Analysis

## Project
Government Budget Transparency & Spending Efficiency Analytics

## Phase
Phase 4 — Advanced SQL and Business Analysis

## 1. Business Objective

The objective of Step 16 is to analyze government budget allocation and actual expenditure across different sectors.

The analysis aims to identify:

- Sector-wise budget allocation.
- Sector-wise actual expenditure.
- Budget variance.
- Budget utilization percentage.
- Operating and development expenditure composition.
- Highest and lowest expenditure sectors.
- Each sector's contribution to total expenditure.

The results can help policymakers, financial analysts, auditors and other stakeholders understand how public financial resources are distributed and utilized.

## 2. Existing Database Structure

### Source tables

| Table | Purpose |
|---|---|
| `analytics.dim_ministry` | Ministry information |
| `analytics.dim_fiscal_year` | Financial year dimension |
| `analytics.fact_ministry_budget` | Ministry-wise budget and expenditure |
| `analytics.fact_government_budget_summary` | Government-level budget summary |
| `analytics.source_documents` | Source documentation |
| `staging.statement_1_import` | Government budget source data |
| `staging.statement_2_import` | Ministry-wise source data |

## 3. Important Data Limitation

The existing database does not contain a direct Sector classification column.

Therefore, Ministry-wise data cannot automatically be considered Sector-wise data.

A validated Ministry-to-Sector mapping is required before sector-level aggregation.

Government-level Statement 1 categories and Ministry-level Statement 2 records must remain separate unless a documented classification methodology establishes a valid relationship.

## 4. New Database Tables

### 4.1 `analytics.dim_sector`

Purpose: Store the approved Sector master list.

Important fields:

- `sector_id`
- `sector_name`
- `sector_description`
- `created_at`

### 4.2 `analytics.bridge_ministry_sector`

Purpose: Store the relationship between ministries and sectors.

Important fields:

- `ministry_id`
- `sector_id`
- `allocation_share`
- `mapping_status`
- `mapping_source`
- `mapping_notes`

The mapping table supports multiple sector assignments when an approved allocation methodology exists.

The total approved allocation share for each ministry must equal 100%.

## 5. Analysis Components

### 16.1 — Source Data Inspection

Inspect the source tables, columns, financial values, units and existing Ministry records.

Validation includes:

- Total Ministry count.
- Fact table record count.
- Duplicate Ministry-year records.
- Missing budget values.
- Missing actual expenditure.
- Operating and development expenditure availability.

### 16.2 — Sector Classification

Identify the official or documented Sector classification.

Do not create sector labels based only on assumptions about Ministry names.

### 16.3 — Ministry-to-Sector Mapping

Create and validate the mapping between Ministry and Sector.

Mapping must have:

- A documented source.
- A clear classification rationale.
- Approved status.
- A valid allocation share.

### 16.4 — Sector-wise Budget Allocation

Calculate the total budget allocated to each sector using approved mapping shares.

### 16.5 — Sector-wise Actual Expenditure

Calculate actual expenditure by sector.

### 16.6 — Budget Variance Analysis

Formula:

`Budget Variance = Total Budget - Actual Expenditure`

Interpretation:

- Positive variance: expenditure is below budget.
- Negative variance: expenditure is above budget.
- Zero variance: budget and actual expenditure are equal.

Variance alone does not establish inefficiency or misconduct.

### 16.7 — Budget Utilization

Formula:

`Utilization % = (Actual Expenditure / Total Budget) × 100`

The analysis classifies utilization into descriptive categories.

These categories are analytical labels, not official performance ratings.

### 16.8 — Operating vs Development Expenditure

Compare the operating and development components of sector expenditure.

### 16.9 — Top Sectors

Identify sectors with the highest actual expenditure.

### 16.10 — Sector Contribution

Calculate each sector's contribution to the total mapped expenditure.

The denominator represents mapped expenditure, not necessarily the entire government expenditure.

### 16.11 — Sector KPI Summary

Produce a consolidated summary containing:

- Total budget.
- Actual expenditure.
- Budget variance.
- Utilization percentage.
- Operating expenditure.
- Development expenditure.

### 16.12 — Data Quality Validation

Validate:

- Mapping completeness.
- Allocation share totals.
- Approved mapping evidence.
- Invalid allocation shares.
- Missing source references.

### 16.13 — Final Summary

Prepare the consolidated analytical output and documentation.

## 6. SQL Concepts Used

- JOIN
- CTE
- GROUP BY
- HAVING
- SUM
- COUNT
- FILTER
- CASE WHEN
- NULLIF
- ROUND
- DENSE_RANK
- Window Functions
- Foreign Keys
- Composite Primary Keys
- Data Validation

## 7. Expected Outputs

| Output | Description |
|---|---|
| `sector_budget_analysis.csv` | Sector budget |
| `sector_expenditure_analysis.csv` | Actual expenditure |
| `sector_variance_analysis.csv` | Budget variance |
| `sector_utilization_analysis.csv` | Utilization percentage |
| `sector_kpi_summary.csv` | Consolidated KPIs |

These outputs should be exported after mapping validation and successful query execution.

## 8. Data Governance Rules

1. Do not treat missing values as zero.
2. Preserve original source values.
3. Keep government-level and ministry-level facts separate.
4. Do not invent sector classifications.
5. Do not force government and ministry totals to match.
6. Retain the original source units and standardized units.
7. Document any allocation share methodology.
8. Preserve Draft source status.
9. Do not interpret low utilization as proof of inefficiency.
10. Do not interpret overspending as proof of fraud.

## 9. Business Questions

The completed analysis should answer:

1. Which sectors receive the largest budget allocations?
2. Which sectors have the highest actual expenditure?
3. Which sectors have the largest positive budget variance?
4. Which sectors have expenditure above their allocated budget?
5. How does utilization differ across sectors?
6. How are operating and development expenditures distributed?
7. Which sectors contribute most to mapped expenditure?
8. How complete and reliable is the Ministry-to-Sector mapping?

## 10. Completion Criteria

Step 16 can be marked complete when:

- Sector dimension is created.
- Mapping is supported by documented evidence.
- Approved mapping coverage is validated.
- Allocation shares are valid.
- Sector analysis queries execute successfully.
- KPI outputs are reviewed.
- Data quality checks pass.
- Business findings and limitations are documented.

## 11. Current Status

**Status: SQL framework prepared — mapping and analytical execution pending.**

The existing database structure has been inspected. The SQL framework has been designed around the actual tables and columns.

Sector-wise results must remain pending until a reliable Sector classification is available.

## 12. Conclusion

Step 16 extends the project from Ministry-level analysis to Sector-level financial analysis.

The main contribution is the introduction of a controlled Sector dimension and a documented Ministry-to-Sector mapping model.

This provides a foundation for reliable sector-wise budget allocation, expenditure, variance and utilization analysis without introducing unsupported classifications or double counting.