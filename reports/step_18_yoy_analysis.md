# Step 18 — Year-over-Year (YoY) Analysis

## 1. Objective

Develop reusable SQL views for ministry-level and government-level
Year-over-Year (YoY) financial comparisons.

The analysis framework covers:
- Budget growth
- Actual expenditure growth
- Budget variance comparison
- Utilization comparison
- Operating expenditure growth
- Development expenditure growth

## 2. Fiscal Year Coverage

The current database contains one fiscal year:

| Financial Year | Start Year | End Year |
|---|---:|---:|
| 2024-2025 | 2024 | 2025 |

Coverage validation:
- Fiscal year records: 1
- Ministry fact records: 62
- Government fact records: 1
- Coverage validation: PASS

## 3. Step 18.2 — Ministry-level YoY View

View:
`analytics.vw_ministry_yoy_analysis`

Metrics:
- Current budget
- Previous budget
- Budget growth percentage
- Current actual expenditure
- Previous actual expenditure
- Actual expenditure growth percentage
- Current and previous budget variance
- Current and previous utilization
- Utilization change in percentage points

Results:
- Ministry records: 62
- Distinct ministries: 62
- Previous-year data available: 0
- Budget growth available: 0
- Actual growth available: 0
- Insufficient historical data: 62
- Data quality validation: PASS

## 4. Step 18.3 — Government-level YoY View

View:
`analytics.vw_government_yoy_analysis`

Metrics:
- Original budget growth
- Revised budget growth
- Actual expenditure growth
- Operating expenditure growth
- Development expenditure growth

Current-year financial values (BDT Crore):

| Metric | 2024-2025 |
|---|---:|
| Original Budget | 797000.0000 |
| Revised Budget | 744000.0000 |
| Actual Expenditure | 633314.0000 |
| Operating Expenditure | 476302.0000 |
| Development Expenditure | 156729.0000 |

Results:
- Government records: 1
- Distinct fiscal years: 1
- Previous-year data available: 0
- Insufficient historical data: 1
- Data quality validation: PASS

## 5. Step 18.4 — Consistency Validation

| Validation | Result |
|---|---:|
| Ministry records | 62 |
| Ministry previous-year available | 0 |
| Ministry insufficient history | 62 |
| Government records | 1 |
| Government previous-year available | 0 |
| Government insufficient history | 1 |
| Combined validation | PASS |

## 6. Important Analytical Limitation

YoY growth rates cannot be calculated from a single fiscal year.

NULL previous-year values and growth percentages are expected.
They must not be replaced with zero or estimated historical values.

Future YoY comparisons require genuine historical fiscal-year data
with consistent ministry identifiers, fiscal-year definitions,
financial measures, and source documentation.

## 7. Interpretation

The two SQL views provide a reusable analytical framework.
Once additional fiscal years are loaded into the fact tables and
fiscal-year dimension, the LAG() calculations can compare each
ministry and government-level financial measure with its prior year.

The current output does not establish any historical growth or decline.

## 8. SQL Objects Created

1. `analytics.vw_ministry_yoy_analysis`
2. `analytics.vw_government_yoy_analysis`

## 9. Final Status

- Step 18.1 — Fiscal Year Coverage Validation: COMPLETED
- Step 18.2 — Ministry-wise YoY Analysis View: COMPLETED
- Step 18.3 — Government-level YoY Analysis View: COMPLETED
- Step 18.4 — YoY Consistency Validation: COMPLETED
- Step 18.5 — Documentation: PENDING

Overall Step 18 status: READY FOR DOCUMENTATION REVIEW