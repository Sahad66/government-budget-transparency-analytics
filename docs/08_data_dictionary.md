# Data Dictionary
## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Project:** Government Budget Transparency & Spending Efficiency Analytics  
**Financial Year:** FY 2024–25  
**Data Status:** Draft Government Reports  
**Documentation Status:** Initial Draft — Pending Dataset Structure Verification

## 1. Purpose

This document defines the meaning, standard names, data types, measurement units, sources, and validation rules of the dataset fields used in this project.

## 2. Source Datasets

| Dataset | Source Document | Original Unit |
|---|---|---|
| Dataset A | Statement 1 — Budget and Accounts at a Glance | Taka in Crore |
| Dataset B | Statement 2 — Ministry/Division Wise Expenditure | Taka in Thousands |

Both documents are marked Draft. Their status must be retained in all project reporting.

## 3. Dataset A — Statement 1

| Original Field | Standard Name | Description | Data Type | Unit |
|---|---|---|---|---|
| Revised Budget | revised_budget | Revised government budget | DECIMAL | Taka in Crore |
| Actual Expenditure | actual_expenditure | Reported actual expenditure | DECIMAL | Taka in Crore |
| Budget Balance | budget_balance | Reported budget balance | DECIMAL | Taka in Crore |
| Actual/Budget % | actual_budget_percentage | Actual expenditure as a percentage of budget | DECIMAL | Percentage |
| Operating Expenditure | operating_expenditure | Operating expenditure | DECIMAL | Taka in Crore |
| Development Expenditure | development_expenditure | Development expenditure | DECIMAL | Taka in Crore |

**Verification required:** Confirm exact source headings, definitions, and whether each field represents the same reporting scope.

## 4. Dataset B — Statement 2

| Original Field | Standard Name | Description | Data Type | Unit |
|---|---|---|---|---|
| Ministry Code | ministry_code | Ministry or division identifier | TEXT | N/A |
| Ministry Name | ministry_name | Ministry or division name | TEXT | N/A |
| Targeted Revenue | targeted_revenue | Targeted revenue | DECIMAL | Taka in Thousands |
| Actual Revenue | actual_revenue | Actual revenue | DECIMAL | Taka in Thousands |
| Total Budget | total_budget | Total budget allocation | DECIMAL | Taka in Thousands |
| Actual Expenditure | actual_expenditure | Actual expenditure | DECIMAL | Taka in Thousands |
| Operating Expenditure | operating_expenditure | Operating expenditure | DECIMAL | Taka in Thousands |
| Development Expenditure | development_expenditure | Development expenditure | DECIMAL | Taka in Thousands |

**Verification required:** Confirm exact headings and definitions against the original PDF.

## 5. Naming Convention

- Use lowercase column names.
- Replace spaces with underscores.
- Avoid unnecessary special characters.
- Preserve original source headings in the documentation.

## 6. Data Type Guidelines

- Ministry identifiers: TEXT
- Ministry names: TEXT
- Financial amounts: DECIMAL
- Percentages: DECIMAL
- Financial year: TEXT or a suitable year representation, depending on the final model.

## 7. Data Quality and Validation Rules

1. Check missing and blank values.
2. Check numeric conversion errors.
3. Check duplicate ministry identifiers.
4. Verify financial amounts against source documents.
5. Confirm that the reporting period is consistent.
6. Preserve the original unit and convert to a common unit only through a documented transformation.
7. Distinguish missing values from actual zero values.
8. Do not assume that budget utilization alone measures spending efficiency.

## 8. Known Limitations

- Source reports are Draft documents.
- Statement 1 and Statement 2 use different financial units.
- Exact definitions and reporting scope must be checked before combining the datasets.
- Sector-level and program-level fields have not yet been confirmed.

## 9. Documentation Status

**Status:** Initial Draft

This data dictionary will be updated after completing dataset structure inspection and validating the extracted PDF tables.
