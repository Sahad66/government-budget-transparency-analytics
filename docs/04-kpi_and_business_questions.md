# KPI DEFINITION & BUSINESS QUESTIONS

## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Document Version:** 1.0

### 1. Business Questions

1. What is the total government budget?
2. What is the total actual expenditure?
3. What is the overall budget utilization rate?
4. Which departments have the highest budget allocation?
5. Which departments have the lowest budget utilization?
6. Which sectors receive the largest budget share?
7. Which departments have the largest budget variance?
8. How has budget allocation changed over time?
9. How has actual expenditure changed over time?
10. Which departments repeatedly show underutilization or overspending?

### 2. Core KPIs

| KPI | Formula |
|---|---|
| Total Allocated Budget | SUM(Allocated Budget) |
| Total Actual Expenditure | SUM(Actual Expenditure) |
| Budget Utilization Rate | Actual Expenditure / Allocated Budget × 100 |
| Budget Variance | Allocated Budget − Actual Expenditure |
| Budget Growth Rate | (Current Budget − Previous Budget) / Previous Budget × 100 |
| Expenditure Growth Rate | (Current Expenditure − Previous Expenditure) / Previous Expenditure × 100 |
| Sector Budget Share | Sector Budget / Total Budget × 100 |

### 3. KPI Business Purpose

- Total Budget: Understand total budget allocation.
- Total Expenditure: Measure actual government spending.
- Utilization Rate: Measure budget spending percentage.
- Budget Variance: Identify differences between allocation and expenditure.
- Budget Growth: Understand yearly allocation changes.
- Expenditure Growth: Understand yearly spending changes.
- Sector Budget Share: Understand sector-wise allocation distribution.

### 4. KPI Calculation Rules

- Handle zero denominators using NULLIF or equivalent logic.
- Investigate missing values separately from zero values.
- Validate duplicate records before aggregation.
- Use consistent currency and financial year definitions.
- Identify the exact budget version used in the analysis.
- Do not interpret high utilization as proof of efficiency.
- Do not interpret low utilization as proof of poor performance.

### 5. Dashboard Mapping

**Executive Overview**
- Total Budget
- Total Expenditure
- Utilization Rate
- Budget Variance

**Department Analysis**
- Department Budget
- Department Expenditure
- Department Utilization Rate

**Sector Analysis**
- Sector Budget Share
- Sector Expenditure

**Budget Variance Analysis**
- Budget Variance
- Utilization Rate

**Trend Analysis**
- Budget Growth Rate
- Expenditure Growth Rate

### 6. Expected Analytical Outcomes

- Overall government spending trends.
- Department-wise utilization comparisons.
- Sector-wise budget distribution.
- Significant positive and negative variances.
- Year-over-year budget and expenditure changes.
- Repeated patterns requiring further investigation.

**End of Document**