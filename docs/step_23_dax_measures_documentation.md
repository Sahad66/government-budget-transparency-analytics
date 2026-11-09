# Project 01 — Government Budget Analytics
## Step 23: Power BI DAX Measures & Data Model Documentation

**Project:** Government Budget Transparency & Spending Efficiency Analytics  
**Database:** `government_budget_analytics`  
**Platform:** Power BI Desktop  
**Phase:** Phase 5 — Power BI Dashboard Development  
**Step:** 23 — DAX Measures Development

---

# 1. Overview

এই ধাপে Government Budget Analytics Dashboard-এর জন্য প্রয়োজনীয় DAX Measures, Calculated Columns এবং একটি dedicated Measures Table তৈরি করা হয়েছে।

মূল উদ্দেশ্য:

- Ministry-level financial KPI analysis
- Budget utilization analysis
- Budget variance analysis
- Ministry performance classification
- Risk prioritization
- Sector-level financial analysis
- Ministry ranking
- Government-level budget analysis
- Year-over-Year (YoY) data availability monitoring

# 2. Created Table

## 2.1 DAX_Measures

**Table Name:** `DAX_Measures`

**Purpose:** সব DAX Measures একটি dedicated table-এর অধীনে সংগঠিত রাখা।

**Table creation DAX:**

```dax
DAX_Measures =
DATATABLE(
    "Measure Group", STRING,
    {
        {"Government Budget Analytics"}
    }
)
```

`Measure Group` column Report View থেকে Hide করা হয়েছে।

**Important:** এই table মূলত Measures সংগঠিত রাখার জন্য। এটি কোনো source financial fact table নয়।

# 3. Source Tables Used

Power BI-তে মোট ১০টি database object import করা হয়েছে।

| No. | Table / View | Purpose |
|---|---|---|
| 1 | `dim_ministry` | Ministry information |
| 2 | `dim_fiscal_year` | Fiscal year information |
| 3 | `dim_sector` | Sector information |
| 4 | `bridge_ministry_sector` | Ministry-sector mapping |
| 5 | `fact_ministry_budget` | Ministry-level financial data |
| 6 | `fact_government_budget_summary` | Government-level financial data |
| 7 | `vw_sector_financial_summary` | Sector-level aggregated analysis |
| 8 | `vw_sector_ministry_financials` | Sector-ministry financial analysis |
| 9 | `vw_ministry_yoy_analysis` | Ministry-level YoY analysis |
| 10 | `vw_government_yoy_analysis` | Government-level YoY analysis |

# 4. Ministry-Level Financial Measures

**Source:** `fact_ministry_budget`

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Total Ministry Budget | Total ministry budget |
| 2 | Total Actual Expenditure | Total actual expenditure |
| 3 | Total Budget Variance | Budget minus actual expenditure |
| 4 | Budget Utilization % | Overall weighted budget utilization |
| 5 | Total Overspending | Total gross overspending |
| 6 | Total Positive Variance | Total positive budget variance |

### Expected Results

| KPI | Expected Value |
|---|---:|
| Total Ministry Budget | 796,999.89 |
| Total Actual Expenditure | 633,314.63 |
| Total Budget Variance | 163,685.26 |
| Budget Utilization | 79.46% |
| Total Overspending | 4,626.47 |
| Total Positive Variance | 168,311.73 |

**Unit:** BDT Crore, except percentages.

# 5. Ministry Count & Performance Measures

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Total Ministry Count | Count of distinct ministries |
| 2 | Overspending Ministry Count | Ministries with actual expenditure above budget |
| 3 | Underutilized Ministry Count | Ministries with actual expenditure below budget |
| 4 | Fully Utilized Ministry Count | Ministries with actual equal to budget |
| 5 | Average Ministry Utilization % | Arithmetic average of individual ministry utilization |

### Expected Results

| KPI | Expected Value |
|---|---:|
| Total Ministry Count | 62 |
| Overspending Ministry Count | 3 |
| Underutilized Ministry Count | 59 |
| Fully Utilized Ministry Count | 0 |
| Average Ministry Utilization | 69.88% |

**Important distinction:**

- Budget Utilization % = Total actual expenditure ÷ Total budget.
- Average Ministry Utilization % = Average of individual ministry utilization percentages.

These are different calculations and should not be treated as identical.

# 6. Ministry Utilization Category Measures

| No. | Measure Name | Expected |
|---|---|---:|
| 1 | High Utilization Ministry Count | 3 |
| 2 | Normal Utilization Ministry Count | 25 |
| 3 | Low Utilization Ministry Count | 21 |
| 4 | Very Low Utilization Ministry Count | 13 |

### Utilization Category Distribution

| Category | Utilization Threshold | Ministries |
|---|---|---:|
| Overspending | Above 100% | 3 |
| High Utilization | 90%–100% | 5 |
| Moderate Utilization | 75%–89.99% | 20 |
| Low Utilization | 50%–74.99% | 21 |
| Very Low Utilization | Below 50% | 13 |
| **Total** | | **62** |

# 7. Calculated Columns

Calculated Columns are created in `fact_ministry_budget`, not in `DAX_Measures`.

## 7.1 Utilization Category

**Column Name:** `Utilization Category`

Purpose:
- Classify each ministry according to its budget utilization.
- Support category-based visuals.
- Support utilization distribution analysis.

Categories:
- Overspending
- High Utilization
- Moderate Utilization
- Low Utilization
- Very Low Utilization

## 7.2 Ministry Risk Classification

**Column Name:** `Ministry Risk Classification`

Purpose:
- Categorize ministries for analytical review.
- Identify ministries requiring further investigation.

Categories:
- Overspending Review
- Very Low Utilization Review
- Low Utilization Review
- Moderate Utilization Review
- Routine Review

These classifications are analytical review indicators, not official audit findings or proof of inefficiency.

# 8. Ministry Risk Count Measures

| No. | Measure Name | Expected |
|---|---|---:|
| 1 | Overspending Review Count | 3 |
| 2 | Very Low Utilization Review Count | 13 |
| 3 | Low Utilization Review Count | 21 |

# 9. Sector-Level Financial Measures

**Source:** `vw_sector_financial_summary`

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Total Sector Budget | Total mapped sector budget |
| 2 | Total Sector Actual Expenditure | Total mapped sector actual expenditure |
| 3 | Sector Budget Variance | Sector budget minus actual expenditure |
| 4 | Sector Utilization % | Overall mapped sector utilization |
| 5 | Sector Count | Number of mapped sectors |
| 6 | Sector Ministry Count | Total mapped ministry count |

### Expected Results

| KPI | Expected |
|---|---:|
| Sector Count | 5 |
| Sector Ministry Count | 13 |
| Total Sector Budget | 308,275.76 |
| Total Sector Actual Expenditure | 216,548.00 |
| Sector Budget Variance | 91,727.76 |
| Sector Utilization | 70.24% |

**Important:** Sector analysis covers only 13 mapped ministries out of 62 ministries. It must not be represented as the full government-wide total.

### Sector Contribution Measures

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Sector Budget Contribution % | Each sector's share of mapped budget |
| 2 | Sector Expenditure Contribution % | Each sector's share of mapped expenditure |
| 3 | Sector Budget Expenditure Difference | Difference between budget and expenditure contribution shares |

The contribution percentages are calculated within the five mapped sectors.

# 10. Ministry Ranking Measures

**Source:** `dim_ministry` and `fact_ministry_budget`

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Ministry Budget Rank | Rank ministries by total budget |
| 2 | Ministry Expenditure Rank | Rank ministries by actual expenditure |
| 3 | Ministry Variance Rank | Rank ministries by positive budget variance |
| 4 | Top Ministry by Budget | Identify the highest-budget ministry |
| 5 | Top Ministry Budget Amount | Display the highest ministry budget amount |

### Expected Results

| KPI | Expected |
|---|---|
| Top Ministry by Budget | Finance Division |
| Top Ministry Budget Amount | 248,203.27 Crore |
| Ministry Count | 62 |

# 11. Government-Level KPI Measures

**Source:** `fact_government_budget_summary`

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Government Original Budget | Government original budget |
| 2 | Government Revised Budget | Government revised budget |
| 3 | Government Actual Expenditure | Government actual expenditure |
| 4 | Government Budget Variance | Original budget minus actual expenditure |
| 5 | Government Operating Expenditure | Operating expenditure |
| 6 | Government Development Expenditure | Development expenditure |
| 7 | Operating Expenditure Contribution % | Operating expenditure share |
| 8 | Development Expenditure Contribution % | Development expenditure share |

### Expected Results

| KPI | Expected Value |
|---|---:|
| Government Original Budget | 797,000.00 |
| Government Revised Budget | 744,000.00 |
| Government Actual Expenditure | 633,314.00 |
| Government Budget Variance | 163,686.00 |
| Government Operating Expenditure | 476,302.00 |
| Government Development Expenditure | 156,729.00 |
| Operating Contribution | 75.21% |
| Development Contribution | 24.75% |

Unit: BDT Crore, except percentages.

# 12. Government Budget Utilization & Revision Measures

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Government Budget Utilization % | Actual expenditure against original budget |
| 2 | Government Revised Budget Variance | Revised budget minus actual expenditure |
| 3 | Government Revised Budget Utilization % | Actual expenditure against revised budget |
| 4 | Government Budget Revision Amount | Revised budget minus original budget |
| 5 | Government Budget Revision % | Percentage change in budget |
| 6 | Government Component Difference | Actual expenditure minus operating and development expenditure |

### Expected Results

| KPI | Expected |
|---|---:|
| Government Budget Utilization | 79.46% |
| Revised Budget Variance | 110,686.00 |
| Revised Budget Utilization | 85.12% |
| Budget Revision Amount | -53,000.00 |
| Budget Revision % | -6.65% |
| Component Difference | 283.00 |

# 13. YoY Data Availability Measures

**Sources:**
- `vw_ministry_yoy_analysis`
- `vw_government_yoy_analysis`
- `dim_fiscal_year`

| No. | Measure Name | Purpose |
|---|---|---|
| 1 | Ministry YoY Data Availability | Check historical ministry data |
| 2 | Government YoY Data Availability | Check historical government data |
| 3 | Ministry YoY Status | Display ministry YoY status |
| 4 | Government YoY Status | Display government YoY status |
| 5 | Historical Fiscal Year Count | Count available fiscal years |

### Expected Results

| KPI | Expected |
|---|---|
| Historical Fiscal Year Count | 1 |
| Ministry YoY Data Availability | Insufficient Historical Data |
| Government YoY Data Availability | Insufficient Historical Data |
| Ministry YoY Status | Insufficient Historical Data |
| Government YoY Status | Insufficient Historical Data |

Only one fiscal year (2024–2025) is currently available. Therefore, YoY growth cannot yet be calculated.

# 14. DAX Measure Inventory

The following groups organize the measures created in this step:

| Group | Number of Measures |
|---|---:|
| Ministry Financial | 6 |
| Ministry Count & Performance | 5 |
| Utilization Category Counts | 4 |
| Ministry Risk Counts | 3 |
| Sector Financial & Contribution | 9 |
| Ministry Ranking | 5 |
| Government Financial | 8 |
| Government Utilization & Revision | 6 |
| YoY Availability & Status | 5 |
| **Total** | **51** |

Additional calculated columns:

1. `Utilization Category`
2. `Ministry Risk Classification`

Note: This inventory records the intended measures from the Step 23 instructions. Final creation and validation status should be confirmed in Power BI's Fields pane; a measure appearing in this documentation does not by itself prove it was successfully created.

# 15. Data Quality & Modeling Notes

1. Ministry-level and government-level fact tables remain separate.
2. Do not add government and ministry totals together.
3. Sector analysis covers 13 mapped ministries, not all 62.
4. Missing YoY values must remain blank; do not replace with zero.
5. Negative source values must be preserved.
6. Government operating and development expenditure total 633,031 Crore, while government actual expenditure is 633,314 Crore.
7. Preserve the 283 Crore component difference.
8. Government and ministry-level totals have small source reconciliation differences; do not force them to match.
9. Utilization categories are analytical classifications, not official government ratings.
10. Risk classifications indicate review priorities, not proven inefficiency or wrongdoing.

# 16. Formatting Standards

| Data Type | Recommended Display |
|---|---|
| Financial amounts | Decimal Number, 2 decimal places |
| Utilization | 2 decimal places with % display |
| Contribution | 2 decimal places with % display |
| Ministry count | Whole Number |
| Sector count | Whole Number |
| Ranking | Whole Number |
| YoY status | Text |

Important: Measures multiplied by 100 should not also be formatted as standard percentage values without adjusting the formula. Otherwise, the displayed percentage will be 100 times too large.

# 17. Step 23 Completion Summary

**Step 23:** DAX Measures Development

Deliverables:
- Dedicated `DAX_Measures` table
- Ministry-level KPI measures
- Ministry performance and utilization analysis
- Ministry risk classification
- Sector-level KPI measures
- Sector contribution analysis
- Ministry ranking measures
- Government-level KPI measures
- Government budget revision and utilization analysis
- YoY data availability measures
- DAX documentation

**Next Step:** Step 24 — Dashboard Layout & Page Design.

The next phase will organize these measures into business-focused Power BI dashboard pages, KPI cards, charts, tables, and slicers.

---

**Project Documentation:** `reports/step_23_dax_measures_documentation.md`

**Status:** Documentation prepared; verify actual measure creation and final validation in Power BI before marking Step 23 fully complete.
