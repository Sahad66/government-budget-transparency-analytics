# Step 14 — Data Loading & Validation

## 1. Objective
Load cleaned and standardized government budget datasets into PostgreSQL and validate the imported records.

## 2. Source Files
- Statement 1: statement_1_standardized.csv
- Statement 2: statement_2_standardized.csv

## 3. Database
- Database: government_budget_analytics
- Schema: staging
- Schema: analytics
- Database Engine: PostgreSQL

## 4. Loading Strategy
1. Verify source CSV files.
2. Confirm column names and data types.
3. Import source records into staging tables.
4. Validate imported row counts.
5. Check NULL values and duplicates.
6. Validate financial units and amounts.
7. Load verified records into analytics tables.

## 5. Data Validation
- Row count validation
- Missing value validation
- Duplicate validation
- Data type validation
- Foreign key validation
- Financial unit validation
- Source-to-database reconciliation

## 6. Data Integrity
Original source values and reporting units must be preserved. Missing values must not automatically be converted to zero.

## 7. Completion Status
Pending actual database connection, data loading, and validation results.