# Step 15: Department-wise Budget Analysis

## Project Information

| Field | Details |
|---|---|
| Project Name | Government Budget Transparency & Spending Efficiency Analytics |
| Phase | Phase 4 — Advanced SQL & Business Analysis |
| Step | Step 15 |
| Step Title | Department-wise Budget Analysis |
| Database | PostgreSQL |
| Database Name | government_budget_analytics |
| Schema | analytics |
| Primary Fact Table | analytics.fact_ministry_budget |
| Dimension Table | analytics.dim_ministry |
| Financial Year | 2024-2025 |
| Currency Unit | BDT Crore |
| Source Data Status | Draft |

---

## 1. Business Objective

The objective of this step is to analyze the budget allocation and actual expenditure of 62 Ministries and Divisions of Bangladesh.

The analysis focuses on understanding how government budget resources are distributed, how much expenditure has been recorded, how much budget remains unspent, and which ministries have exceeded their allocated budgets.

This analysis will help identify budget distribution patterns, expenditure concentration, utilization differences, and areas requiring further investigation.

### Key Business Questions

1. Which ministries receive the highest budget allocations?
2. Which ministries receive the lowest budget allocations?
3. Which ministries record the highest actual expenditure?
4. Which ministries have the highest and lowest budget utilization?
5. Which ministries have the largest unspent budgets?
6. Which ministries have exceeded their allocated budgets?
7. How is expenditure distributed between operating and development activities?
8. What percentage of the total ministry budget is allocated to the top 10 ministries?
9. What is the overall budget utilization rate across all ministries?

---

## 2. Database Tables Used

### 2.1 Fact Table

`analytics.fact_ministry_budget`

This table contains ministry-level financial information and calculated KPIs.

Important columns:

| Column | Description |
|---|---|
| ministry_id | Ministry dimension reference |
| fiscal_year_id | Fiscal year reference |
| source_document_id | Source document reference |
| total_budget | Total budget allocation |
| actual_expenditure | Actual recorded expenditure |
| operating_expenditure | Operating expenditure |
| development_expenditure | Development expenditure |
| budget_variance | Budget minus actual expenditure |
| budget_utilization_rate | Budget utilization percentage |
| standard_unit | Standard financial unit |

### 2.2 Dimension Table

`analytics.dim_ministry`

This table contains ministry identification information.

Important columns:

| Column | Description |
|---|---|
| ministry_id | Primary key |
| ministry_code | Ministry identification code |
| ministry_name | Ministry or division name |

### 2.3 Table Relationship

The two tables are connected through `ministry_id`.

```sql
SELECT
    d.ministry_code,
    d.ministry_name,
    f.total_budget,
    f.actual_expenditure
FROM analytics.fact_ministry_budget f
INNER JOIN analytics.dim_ministry d
    ON f.ministry_id = d.ministry_id;
```

---

## 3. Analysis Performed

### 3.1 Ministry-wise Budget Overview

**Objective:** Generate a complete financial overview of all 62 ministries.

Metrics included:

- Ministry Code
- Ministry Name
- Total Budget
- Actual Expenditure
- Budget Variance
- Budget Utilization Rate
- Operating Expenditure
- Development Expenditure
- Standard Unit

SQL concepts:

- INNER JOIN
- ORDER BY
- Table Aliases

Expected output: 62 ministry records.

### 3.2 Top 10 Ministries by Budget Allocation

**Objective:** Identify the ten ministries receiving the highest budget allocations.

SQL concepts:

- ORDER BY DESC
- LIMIT
- ROW_NUMBER()

Business purpose:

Identify the ministries receiving the largest share of government budget allocations.

### 3.3 Bottom 10 Ministries by Budget Allocation

**Objective:** Identify the ten ministries with the lowest budget allocations.

SQL concepts:

- ORDER BY ASC
- LIMIT

Business purpose:

Understand the lower end of the ministry budget distribution.

A lower allocation does not automatically indicate lower importance.

### 3.4 Top 10 Ministries by Actual Expenditure

**Objective:** Identify the ten ministries with the highest actual expenditure.

SQL concepts:

- DENSE_RANK()
- Window Functions
- ORDER BY DESC

Business purpose:

Compare expenditure rankings with budget allocation rankings.

### 3.5 Budget Utilization Ranking

**Objective:** Analyze the percentage of allocated budget spent by each ministry.

Formula:

Budget Utilization Rate = (Actual Expenditure / Total Budget) × 100

Classification:

| Condition | Classification |
|---|---|
| Above 100% | Above Budget |
| Equal to 100% | Fully Utilized |
| Below 100% | Below Budget |

Business purpose:

Identify differences in budget utilization across ministries.

### 3.6 Unspent Budget Analysis

**Objective:** Identify ministries with the largest positive budget variance.

Formula:

Budget Variance = Total Budget - Actual Expenditure

A positive variance indicates that recorded actual expenditure is below the allocated budget.

SQL filtering:

```sql
WHERE budget_variance > 0
```

Business purpose:

Identify ministries with the largest remaining budget balances for further investigation.

### 3.7 Budget Overrun Analysis

**Objective:** Identify ministries whose recorded actual expenditure exceeds their allocated budget.

SQL filtering:

```sql
WHERE budget_variance < 0
```

Overrun amount:

```sql
ABS(budget_variance)
```

Previously validated ministries with negative budget variance:

1. Financial Institutions Division
2. Ministry of Water Resources
3. Ministry of Food

Previously validated count: 3 ministries.

Business purpose:

Identify budget overruns requiring further financial review.

A negative variance alone does not establish fraud, misuse, or financial misconduct.

### 3.8 Operating vs Development Expenditure

**Objective:** Compare operating and development expenditure across ministries.

Operating Share Formula:

Operating Expenditure / Actual Expenditure × 100

Development Share Formula:

Development Expenditure / Actual Expenditure × 100

SQL concepts:

- Calculated Columns
- ROUND()
- NULLIF()

Business purpose:

Understand the composition of recorded ministry expenditure.

### 3.9 Overall Ministry Budget KPIs

**Objective:** Calculate aggregate financial KPIs for all ministries.

Metrics:

- Total Ministries
- Total Budget
- Total Actual Expenditure
- Total Budget Variance
- Overall Budget Utilization
- Average Ministry Utilization
- Number of Overspending Ministries
- Number of Underspending Ministries

SQL concepts:

- COUNT()
- SUM()
- AVG()
- FILTER
- ROUND()
- NULLIF()

Previously validated aggregate values:

| KPI | Value |
|---|---:|
| Total Ministries | 62 |
| Total Budget | 796,999.8907 |
| Actual Expenditure | 633,314.6279 |
| Budget Variance | 163,685.2628 |
| Overall Utilization | 79.4623% |
| Overspending Ministries | 3 |

Financial unit: BDT Crore.

### 3.10 Top 10 Budget Concentration Analysis

**Objective:** Calculate the percentage of total ministry budget allocated to the ten largest-budget ministries.

Formula:

Top 10 Budget Share = (Top 10 Budget / Overall Ministry Budget) × 100

SQL concepts:

- Common Table Expressions (CTEs)
- ROW_NUMBER()
- SUM()
- CROSS JOIN

Business purpose:

Measure budget concentration among the ten largest-budget ministries.

### 3.11 Ministry Budget Performance Classification

**Objective:** Categorize ministries according to budget utilization and variance.

Classification rules:

| Condition | Category |
|---|---|
| Negative budget variance | Budget Overrun |
| Utilization >= 90% | High Utilization |
| Utilization >= 70% | Moderate Utilization |
| Otherwise | Low Utilization |

SQL concept:

- CASE WHEN

Business purpose:

Create a structured classification for reporting and future Power BI visualization.

These categories are analytical labels, not definitive measures of ministry efficiency.

---

## 4. Advanced SQL Concepts Applied

| SQL Concept | Application |
|---|---|
| INNER JOIN | Combine fact and dimension tables |
| ORDER BY | Sort financial records |
| LIMIT | Retrieve top and bottom records |
| ROW_NUMBER() | Create unique rankings |
| DENSE_RANK() | Create rankings with tie handling |
| CASE WHEN | Classify ministry performance |
| CTE | Organize multi-stage analysis |
| SUM() | Calculate total financial values |
| AVG() | Calculate average utilization |
| COUNT() | Count ministries |
| FILTER | Conditional aggregation |
| ROUND() | Format numerical results |
| NULLIF() | Prevent division-by-zero errors |
| ABS() | Calculate positive overrun amounts |
| CROSS JOIN | Combine aggregate budget values |

---

## 5. Previously Verified Financial Results

The following results were verified during Step 14 database validation.

| Metric | Verified Value |
|---|---:|
| Ministry Records | 62 |
| Total Budget | 796,999.8907 |
| Total Actual Expenditure | 633,314.6279 |
| Total Budget Variance | 163,685.2628 |
| Overall Utilization | 79.4623% |
| Negative Variance Ministries | 3 |

Unit: BDT Crore.

These figures represent the ministry-level fact table and should not be forcibly reconciled with the separate government summary fact table.

---

## 6. Data Quality and Analytical Considerations

The following considerations must be maintained during analysis:

1. Original source values must remain unchanged.
2. Negative budget variances must be preserved.
3. Missing values must not automatically be treated as zero.
4. Government-level and ministry-level fact tables must remain separate.
5. The ministry-level total and government-level summary may have small source discrepancies.
6. Source documents are marked Draft and should not be presented as final official figures.
7. High utilization does not necessarily mean high efficiency.
8. Low utilization does not necessarily mean poor performance.
9. Budget overruns require additional investigation before drawing conclusions.
10. All financial figures must retain their documented units.

---

## 7. Expected Project Deliverables

The complete Step 15 analysis is designed to produce:

1. Ministry-wise Budget Overview Report
2. Top 10 Budget Allocation Report
3. Bottom 10 Budget Allocation Report
4. Top 10 Actual Expenditure Report
5. Budget Utilization Ranking Report
6. Unspent Budget Analysis Report
7. Budget Overrun Analysis Report
8. Operating vs Development Expenditure Report
9. Overall Ministry KPI Summary
10. Top 10 Budget Concentration Report
11. Ministry Budget Performance Classification
12. Final Business Insights Report

---

## 8. Current Completion Status

| Component | Status |
|---|---|
| Step 15 business objectives | Prepared |
| Database tables identified | Completed |
| SQL analysis script | Prepared |
| Ministry overview query | Prepared; initial validation passed |
| Remaining analytical queries | Execution and validation pending |
| Business interpretation | Pending |
| Final analytical report | Pending |

**Important:** SQL preparation and successful query execution are separate milestones. Step 15 should only be marked fully completed after all analytical queries have been executed, their results validated, and the final business insights documented.

---

## 9. Conclusion

Step 15 establishes the ministry-level analytical foundation of the Government Budget Transparency & Spending Efficiency Analytics project.

Through PostgreSQL and advanced SQL techniques, this step examines budget allocation, actual expenditure, utilization, variance, operating and development spending, and budget concentration.

The resulting analytical outputs will provide a foundation for subsequent sector-wise expenditure analysis, utilization and variance analysis, advanced SQL reporting, and Power BI dashboard development.

**Project Status:** Phase 4 — Step 15  
**Step Title:** Department-wise Budget Analysis  
**Next Step:** Step 16 — Sector-wise Expenditure Analysis
