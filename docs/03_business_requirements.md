# BUSINESS REQUIREMENTS DOCUMENT (BRD)

## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Document Version:** 1.0  
**Project Type:** Data Analytics & Business Intelligence  
**Status:** Initial Requirements  
**Primary Tools:** Python, PostgreSQL, SQL, Power BI

---

## 1. Project Overview

The Government Budget Transparency & Spending Efficiency Analytics project aims to analyze government budget allocations and actual expenditures across different financial years, ministries, departments, sectors, and programs.

The project will use historical budget and expenditure data to understand government spending patterns, measure budget utilization, identify budget variances, and highlight areas that require further investigation.

The final output will be an interactive Power BI dashboard supported by data cleaning, database development, advanced SQL analysis, and business recommendations.

## 2. Business Problem

Government departments receive budget allocations to execute different public programs and development activities.

However, allocated budgets and actual expenditures may differ significantly.

Some departments may spend less than their allocated budgets, while others may exceed their allocations.

Without proper analysis, decision-makers may face difficulties understanding:

- Where government funds are being allocated.
- How much allocated budget is actually being spent.
- Which departments have significant budget variances.
- How expenditure patterns change over time.
- Which sectors receive the largest budget shares.
- Which departments repeatedly show unusual spending patterns.

**Main Business Problem:**

To analyze government budget allocation and actual expenditure data to evaluate budget utilization, identify spending patterns and financial variances, and support transparent, evidence-based financial decision-making.

## 3. Project Objectives

The main objectives are:

1. Analyze total government budget allocation and actual expenditure.
2. Evaluate department-wise budget utilization.
3. Compare allocated budgets with actual expenditures.
4. Identify under-budget and over-budget expenditure patterns.
5. Analyze sector-wise budget distribution.
6. Measure year-over-year budget and expenditure growth.
7. Identify recurring budget utilization patterns.
8. Develop an interactive Power BI dashboard.
9. Provide data-driven insights and recommendations.

## 4. Stakeholder Requirements

### 4.1 Primary Stakeholders

**Ministry of Finance**
- Monitor overall budget allocation and expenditure.
- Compare budget performance across financial years.
- Identify departments with significant budget variances.

**Government Ministries and Departments**
- Monitor their allocated budgets and actual expenditures.
- Understand department-wise and program-wise spending patterns.
- Review budget utilization performance.

**Auditors and Oversight Committees**
- Identify unusual budget and expenditure differences.
- Review recurring underutilization and overspending patterns.
- Support financial oversight and further investigation.

### 4.2 Secondary Stakeholders

**Senior Policymakers**
- Understand sector-wise spending trends.
- Support future budget planning.
- Identify areas requiring further performance evaluation.

**Citizens and Taxpayers**
- Understand public budget allocation.
- Access summarized government expenditure information.
- Improve public financial transparency.

## 5. Business Questions

The project must answer the following business questions:

1. How has total government budget allocation changed across financial years?
2. How has actual government expenditure changed over time?
3. Which departments have the highest and lowest budget utilization rates?
4. Which departments have the largest positive and negative budget variances?
5. How is the government budget distributed across different sectors?
6. Which sectors have experienced the highest budget growth?
7. Which departments repeatedly show underutilization or overspending?
8. How do budget allocation and actual expenditure compare across financial years?

## 6. KPI Requirements

The dashboard should include the following Key Performance Indicators.

### 6.1 Budget Utilization Rate

Formula:

Budget Utilization Rate = (Actual Expenditure / Allocated Budget) × 100

Purpose: Measure the percentage of allocated budget spent.

### 6.2 Budget Variance

Formula:

Budget Variance = Allocated Budget − Actual Expenditure

Purpose: Measure the difference between allocated budget and actual expenditure.

Interpretation:
- Positive variance: Actual expenditure is below the allocated budget.
- Negative variance: Actual expenditure exceeds the allocated budget.
- Zero variance: Actual expenditure equals the allocated budget.

### 6.3 Budget Growth Rate

Formula:

Budget Growth Rate = ((Current Budget − Previous Budget) / Previous Budget) × 100

Purpose: Measure budget allocation growth across financial years.

### 6.4 Expenditure Growth Rate

Formula:

Expenditure Growth Rate = ((Current Expenditure − Previous Expenditure) / Previous Expenditure) × 100

Purpose: Measure expenditure growth across financial years.

### 6.5 Sector Budget Share

Formula:

Sector Budget Share = (Sector Budget / Total Government Budget) × 100

Purpose: Measure each sector's share of the total government budget.

**Calculation Note:** Handle missing values and zero denominators carefully. Budget and expenditure figures must use consistent financial years, currency, and accounting bases.

## 7. Functional Requirements

The Power BI dashboard should provide the following functionality:

### 7.1 Executive Overview
- Display total allocated budget.
- Display total actual expenditure.
- Show overall budget utilization rate.
- Show total budget variance.
- Display yearly budget and expenditure trends.

### 7.2 Department Analysis
- Compare department-wise allocated budgets.
- Compare department-wise actual expenditures.
- Rank departments by utilization rate.
- Identify departments with significant budget variances.

### 7.3 Sector Analysis
- Show sector-wise budget allocation.
- Compare expenditure across sectors.
- Display sector budget shares.
- Analyze sector-wise growth trends.

### 7.4 Budget Variance Analysis
- Identify positive and negative budget variances.
- Highlight departments with large variances.
- Compare budget utilization across financial years.
- Identify recurring patterns for further investigation.

### 7.5 Interactive Filters
The dashboard should support relevant filters such as:

- Financial Year
- Ministry or Department
- Sector
- Program or Project
- Budget Type or Stage, if available in the dataset
- Location or Region, if available in the dataset

## 8. Non-Functional Requirements

### 8.1 Performance
- Dashboard visuals should load efficiently.
- SQL queries should be optimized.
- Data models should avoid unnecessary complexity.

### 8.2 Usability
- Dashboard should be easy to understand.
- KPI definitions should be clear.
- Visuals should follow a consistent design.

### 8.3 Data Accuracy
- Budget and expenditure values must be validated.
- Duplicate and missing records should be investigated.
- Calculations must be tested against source data.

### 8.4 Reliability
- Data transformations should be documented.
- Data loading processes should be repeatable.
- Known data limitations should be disclosed.

## 9. Project Scope

### 9.1 In Scope

- Historical government budget data analysis.
- Actual expenditure analysis.
- Department-wise and sector-wise comparisons.
- Budget utilization and variance calculations.
- Year-over-year trend analysis.
- Data cleaning and transformation.
- PostgreSQL database development.
- Advanced SQL analysis.
- Power BI dashboard development.
- Business insights and recommendations.
- Project documentation and GitHub portfolio development.

### 9.2 Out of Scope

- Proving fraud or corruption using budget figures alone.
- Making unsupported claims about government performance.
- Automatically reallocating government budgets.
- Establishing causal relationships without suitable evidence.
- Evaluating project outcomes without relevant outcome data.

## 10. Expected Outcomes

At the end of the project, the expected deliverables are:

1. A structured government budget dataset.
2. A documented data dictionary.
3. A data quality assessment report.
4. Cleaned and transformed datasets.
5. A PostgreSQL database.
6. Database schema and ERD.
7. Advanced SQL analysis queries.
8. Budget and expenditure performance analysis.
9. Interactive Power BI dashboards.
10. Business insights and recommendations.
11. GitHub repository with complete documentation.
12. Final project presentation and case study.

## 11. Assumptions and Data Limitations

The analysis depends on the availability and quality of government budget and expenditure data.

The following conditions must be checked:

- Availability of multiple financial years.
- Consistent financial year definitions.
- Consistent currency and measurement units.
- Clear definitions of allocated, revised, released, and actual budgets.
- Availability of department and sector identifiers.
- Missing, duplicated, or inconsistent records.

If a required field is unavailable, the limitation must be documented rather than replacing it with fabricated information.

Low budget utilization or high expenditure does not independently prove inefficiency. Further investigation may require project progress, service delivery, procurement, and outcome data.

## 12. Project Success Criteria

The project will be considered successful when:

- Required source data has been collected and validated.
- Key business questions can be answered using the available data.
- KPI calculations are accurate and documented.
- SQL analysis produces validated results.
- Power BI dashboards provide meaningful interactive analysis.
- Findings are supported by data.
- Limitations and recommendations are clearly documented.

---

**End of Business Requirements Document**

**Project:** Government Budget Transparency & Spending Efficiency Analytics  
**Document:** Business Requirements Document (BRD)  
**Version:** 1.0