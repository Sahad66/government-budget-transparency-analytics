## 17.2 Variance Severity & Financial Risk Classification

### Objective
Classify ministry-level budget variance into analytical severity categories to identify ministries requiring further financial review.

### Classification Rules
- Negative variance: OVERSPENDING
- Variance percentage >= 50%: VERY HIGH VARIANCE
- Variance percentage >= 25%: HIGH VARIANCE
- Variance percentage >= 10%: MODERATE VARIANCE
- Otherwise: LOW VARIANCE

### Results
A total of 62 ministries were classified:

| Severity | Ministries | Share |
|---|---:|---:|
| HIGH VARIANCE | 21 | 33.87% |
| MODERATE VARIANCE | 20 | 32.26% |
| VERY HIGH VARIANCE | 13 | 20.97% |
| LOW VARIANCE | 5 | 8.06% |
| OVERSPENDING | 3 | 4.84% |

### Key Findings
- Planning Division recorded the highest positive variance percentage at 98.4260%.
- Road Transport and Highways Division had the highest positive variance amount at BDT 20,234.7518 Crore.
- Health Services Division recorded BDT 15,401.5729 Crore positive variance.
- Financial Institutions Division recorded the largest overspending amount at BDT 2,036.8393 Crore.
- Three ministries were classified as overspending.

### Data Quality
- Total records: 62
- Missing variance: 0
- Invalid budget: 0
- Variance calculation mismatches: 0
- Data quality status: PASS

### Interpretation & Limitations
These severity categories are analytical thresholds created for this project, not official government ratings. A positive variance indicates budget remaining relative to actual expenditure. It does not independently establish inefficiency or poor performance. Further investigation should consider fund release timing, commitments, procurement progress and project implementation status.

Overspending is a budget-control review indicator, not evidence of fraud or misconduct.

### Step Status
COMPLETED — all six SQL queries executed successfully and the variance quality check returned PASS.



## 17.3 Variance Contribution & Concentration Analysis

### Objective
Identify which ministries contribute the largest share of positive budget variance and determine whether variance is concentrated among a small number of ministries.

### Key Results

Total positive budget variance: BDT 168,311.7319 Crore.

Top contributing ministries:
- Road Transport and Highways Division: BDT 20,234.7518 Crore (12.0222%).
- Health Services Division: BDT 15,401.5729 Crore (9.1506%).
- Ministry of Primary and Mass Education: BDT 12,930.6914 Crore (7.6826%).
- Ministry of Railways: BDT 11,217.2098 Crore (6.6645%).
- Finance Division: BDT 11,012.4920 Crore (6.5429%).

### Variance Concentration

| Ministry Group | Contribution |
|---|---:|
| Top 5 | 42.0629% |
| Top 10 | 64.0809% |
| Top 20 | 84.4608% |

The results indicate that a substantial share of positive budget variance is concentrated among a relatively small number of ministries.

### Overspending Contribution

Total gross overspending: BDT 4,626.4691 Crore.

| Ministry | Overspending | Contribution |
|---|---:|---:|
| Financial Institutions Division | 2,036.8393 | 44.0258% |
| Ministry of Food | 1,529.7348 | 33.0648% |
| Ministry of Water Resources | 1,059.8950 | 22.9094% |

The three ministries account for 100% of gross overspending.

### Financial Reconciliation

| Metric | BDT Crore |
|---|---:|
| Gross positive variance | 168,311.7319 |
| Gross overspending | 4,626.4691 |
| Net budget variance | 163,685.2628 |
| Calculated net variance | 163,685.2628 |

Reconciliation status: PASS.

### Data Quality
- Total records: 62
- Positive variance records: 59
- Overspending records: 3
- Missing variance: 0
- Invalid budget: 0
- Variance calculation mismatch: 0
- Final data quality status: PASS

### Interpretation & Limitations
Variance concentration identifies where further investigation may be useful. It does not establish the reasons for unspent budget or prove poor financial management.

Gross positive variance and gross overspending are analyzed separately to avoid hiding their respective magnitudes through netting.

### Step Status
COMPLETED — all six SQL queries executed successfully. Financial reconciliation and data quality checks passed.




## 17.5 Consolidated Ministry-wise Financial Risk Prioritization

### Objective
Consolidate the findings from Steps 17.1–17.4 into a ministry-wise analytical review-priority framework.

### Methodology
Four analytical flags were combined:

1. Overspending
2. High budget variance outlier
3. Low utilization outlier
4. High utilization outlier

The scoring framework assigns:
- Overspending: 3 points
- High variance outlier: 2 points
- Low utilization outlier: 2 points
- High utilization outlier: 2 points

Priority categories:
- Score >= 3: HIGH REVIEW PRIORITY
- Score = 2: MEDIUM REVIEW PRIORITY
- Score 0–1: ROUTINE MONITORING

### Results

| Review Priority | Ministry Count | Share |
|---|---:|---:|
| High | 3 | 4.84% |
| Medium | 7 | 11.29% |
| Routine | 52 | 83.87% |
| **Total** | **62** | **100%** |

### High Review Priority Ministries

| Ministry | Score |
|---|---:|
| Financial Institutions Division | 5 |
| Ministry of Food | 3 |
| Ministry of Water Resources | 3 |

### Medium Review Priority Ministries

| Ministry | Score |
|---|---:|
| Road Transport and Highways Division | 2 |
| Health Services Division | 2 |
| Ministry of Primary and Mass Education | 2 |
| Ministry of Railways | 2 |
| Finance Division | 2 |
| Local Government Division | 2 |
| Planning Division | 2 |

### Key Findings

- 3 ministries were classified as high review priority.
- 7 ministries were classified as medium review priority.
- 52 ministries were assigned to routine monitoring.
- Financial Institutions Division received the highest score of 5.
- Planning Division was flagged for exceptionally low utilization.
- Road Transport and Highways Division had the largest positive budget variance among the identified statistical outliers.

### Data Quality Validation

| Validation | Result |
|---|---:|
| Total records | 62 |
| Distinct ministries | 62 |
| Missing ministry identity | 0 |
| Missing financial metrics | 0 |
| Missing risk outputs | 0 |
| Variance calculation mismatch | 0 |
| Score calculation mismatch | 0 |
| Final validation | PASS |

### Limitations

This is an analytical review-priority framework, not an official government risk rating or audit conclusion. Statistical outliers and budget variances do not independently establish inefficiency, fraud, or misconduct. Further investigation should consider budget releases, commitments, procurement schedules, project implementation status, and reporting periods.

### Conclusion

Step 17.5 successfully consolidated ministry-wise budget utilization, variance, and statistical outlier findings into a review-priority framework. All 62 ministry records passed the final validation checks.

**STEP 17.5 COMPLETED SUCCESSFULLY.**


## 17.6 Government-level vs Ministry-level Budget Reconciliation Analysis

### Objective
Compare government-level budget summary figures with aggregated ministry-level financial figures to identify and quantify reconciliation differences.

### Reconciliation Results

All financial values are expressed in BDT Crore.

| Metric | Government | Ministry Aggregate | Difference |
|---|---:|---:|---:|
| Original budget | 797000.0000 | 796999.8907 | -0.1093 |
| Actual expenditure | 633314.0000 | 633314.6279 | 0.6279 |
| Operating expenditure | 476302.0000 | 476585.6274 | 283.6274 |
| Development expenditure | 156729.0000 | 156728.9978 | -0.0022 |

Difference = Ministry aggregate - Government figure.

### Operating and Development Component Reconciliation

| Metric | Government | Ministry Aggregate |
|---|---:|---:|
| Operating + Development | 633031.0000 | 633314.6252 |
| Actual expenditure | 633314.0000 | 633314.6279 |
| Actual vs component difference | 283.0000 | 0.0027 |

### Key Findings

1. Ministry aggregated original budget is 0.1093 Crore lower than the government-level original budget.
2. Ministry aggregated actual expenditure is 0.6279 Crore higher than the government-level actual expenditure.
3. Government operating expenditure differs from ministry aggregated operating expenditure by 283.6274 Crore.
4. Development expenditure differs by -0.0022 Crore.
5. Government-level actual expenditure exceeds the sum of government operating and development components by 283.0000 Crore.
6. Ministry-level actual expenditure exceeds its operating and development component total by 0.0027 Crore.

### Revised Budget Comparison

Government revised budget is 744000.0000 Crore, while the ministry aggregate total budget is 796999.8907 Crore.

The difference is 52999.8907 Crore. This comparison requires confirmation of the underlying budget basis and source definitions before being interpreted as a reconciliation error.

### Data Quality Validation

| Validation | Result |
|---|---:|
| Government records | 1 |
| Ministry records | 62 |
| Distinct ministries | 62 |
| Missing reconciliation values | 0 |
| Missing difference calculations | 0 |
| Final validation | PASS |

### Limitations and Interpretation

The reconciliation differences are preserved without adjustment. The analysis does not force government-level and ministry-level values to match.

Potential explanations may include differences in source scope, classification, reporting basis, rounding, or component coverage. These explanations require further source-level verification.

The 283 Crore government-level component difference is retained as an unresolved reconciliation item.

### Conclusion

Government-level and ministry-level financial records were successfully compared. All 62 ministry records were included, and all reconciliation fields passed the data quality validation.

The identified financial differences remain documented for further investigation.

**STEP 17.6 COMPLETED SUCCESSFULLY.**