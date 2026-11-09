# Data Quality Assessment Report

## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Financial Year:** FY 2024–25  
**Source Status:** Draft Government Reports  
**Assessment Status:** Pending Actual Dataset Validation

## 1. Objective

The objective of this assessment is to identify data quality issues before performing data cleaning, database loading, SQL analysis, and Power BI dashboard development.

## 2. Datasets

| Dataset |           |Source |                     |Unit |
|---|---|---|
| Statement 1 | Budget and Accounts at a Glance | Taka in Crore |
| Statement 2 | Ministry/Division Wise Expenditure | Taka in Thousands |

## 3. Quality Dimensions

- Completeness
- Uniqueness
- Validity
- Consistency
- Accuracy
- Integrity
- Unit Consistency
- Referential Integrity

## 4. Assessment Results

### Statement 1

| Check | Result |
|---|---|
| Total Rows     | Pending |
| Total Columns  | Pending |
| Missing Values | Pending |
| Duplicate Rows | Pending |
| Invalid Data Types | Pending |
| Negative Financial Values | Pending |
| Extraction Accuracy | Pending |

### Statement 2

| Check | Result |
|---|---|
| Total Rows     | Pending |
| Total Columns  | Pending |
| Missing Values | Pending |
| Duplicate Rows | Pending |
| Invalid Data Types | Pending |
| Negative Financial Values | Pending |
| Extraction Accuracy | Pending |

## 5. Data Quality Issue Log

| Issue ID | Description | Severity | Status | Proposed Action |
|---|---|---|---|---|
| DQ-001 | Missing values | To be assessed | Pending | Verify against source |
| DQ-002 | Duplicate records | To be assessed | Pending | Investigate |
| DQ-003 | Unit mismatch | Identified from source metadata | Open | Standardize units |
| DQ-004 | Invalid numeric values | To be assessed | Pending | Validate and parse |
| DQ-005 | PDF extraction mismatch | To be assessed | Pending | Compare with PDF |

## 6. Important Data Handling Rules

1. Do not automatically delete duplicate records.
2. Do not replace missing values with zero without justification.
3. Preserve original source values.
4. Record all unit conversions.
5. Verify suspicious values against the original PDF.
6. Keep Draft source status visible in project outputs.
7. Do not interpret budget utilization as a standalone measure of efficiency.

## 7. Conclusion

The dataset must pass the required quality checks before being used for final analysis. All detected issues, evidence, and corrective actions will be documented.

**Report Status:** Pending actual execution and validation.