# Data Cleaning Documentation

## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Financial Year:** FY 2024–25  
**Source Status:** Draft Government Reports  
**Tool:** Python, Pandas, NumPy

## 1. Objective

The objective is to clean and standardize the extracted government budget datasets while preserving original source data and maintaining data traceability.

## 2. Source Datasets

| Dataset | Original Unit | Status |
|---|---|---|
| Statement 1 | Taka in Crore | Draft |
| Statement 2 | Taka in Thousands | Draft |

## 3. Cleaning Operations

| Operation | Description | Status |
|---|---|---|
| Column Standardization | Standardized column names | Pending execution |
| Text Cleaning | Trimmed whitespace and identified blank strings | Pending execution |
| Numeric Conversion | Converted financial fields to numeric | Pending execution |
| Missing Value Handling | Identified and investigated missing values | Pending execution |
| Duplicate Investigation | Identified potential duplicate records | Pending execution |
| Financial Validation | Investigated negative and unusual values | Pending execution |
| Export | Saved cleaned datasets separately | Pending execution |

## 4. Missing Value Policy

- Missing financial values will not automatically be replaced with zero.
- Missing values will be verified against original reports.
- Any imputation must have a documented business justification.

## 5. Duplicate Handling Policy

Potential duplicates will be investigated before removal. Repeated ministry codes may represent different reporting lines and must not be removed automatically.

## 6. Numeric Conversion Policy

Financial values containing thousands separators will be standardized before numeric conversion.

Invalid values converted to missing values will be logged and investigated.

## 7. Unit Management

| Source | Original Unit |
|---|---|
| Statement 1 | Taka in Crore |
| Statement 2 | Taka in Thousands |

Original units will be preserved. Unit conversion will be documented separately before combining or comparing financial amounts.

## 8. Output Files

- data/processed/statement_1_cleaned.csv
- data/processed/statement_2_cleaned.csv

## 9. Quality Assurance

Raw and cleaned datasets will be compared using:

- Row and column counts
- Missing value counts
- Duplicate counts
- Data type checks
- Numeric validation
- Source PDF verification

## 10. Conclusion

The cleaned datasets will be considered ready for database engineering only after all significant data quality issues have been investigated and documented.

**Documentation Status:** Initial Draft — Pending Execution