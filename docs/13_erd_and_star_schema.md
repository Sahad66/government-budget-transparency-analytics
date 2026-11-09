# Step 13 — ERD & Star Schema Development

## 1. Objective
Design a relational database structure for Government Budget Transparency & Spending Efficiency Analytics.

## 2. Main Database Tables

### Dimension / Metadata Tables
- dim_fiscal_year
- dim_ministry
- source_documents

### Fact Tables
- fact_government_budget_summary
- fact_ministry_budget

## 3. Relationships
- Fiscal Year to Government Budget Summary: One-to-Many
- Fiscal Year to Ministry Budget: One-to-Many
- Ministry to Ministry Budget: One-to-Many
- Source Documents to Government Budget Summary: One-to-Many
- Source Documents to Ministry Budget: One-to-Many

## 4. Star Schema
Two separate analytical fact tables are maintained:

1. Government Budget Summary
2. Ministry Budget

Government-level and ministry-level figures are kept separate to prevent double counting.

## 5. Design Considerations
- Primary keys uniquely identify records.
- Foreign keys maintain referential integrity.
- Financial values use NUMERIC data types.
- Original source units and document status must be preserved.
- Draft source documents must not be represented as final data.
- Actual table grain and relationships must be validated against source files.

## 6. Validation Status
Logical schema design documented. Actual PostgreSQL relationships and source-data compatibility are pending database verification.

## 7. Next Step
Step 14 — Data Loading & Validation.