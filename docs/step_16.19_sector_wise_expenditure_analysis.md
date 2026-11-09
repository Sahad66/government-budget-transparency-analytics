## 16.19 — Sector-wise Statistical Analysis

### Objective
Perform descriptive statistical analysis of budget allocation, actual expenditure, utilization rates, and spending gaps across the five defined analytical sectors.

### 1. Budget Statistical Summary

Unit: BDT Crore

| Metric | Result |
|---|---:|
| Sector Count | 5 |
| Mean Budget | 61655.1529 |
| Median Budget | 63533.4865 |
| Minimum Budget | 17759.5070 |
| Maximum Budget | 113052.7995 |
| Q1 | 30316.4750 |
| Q3 | 83613.4963 |
| IQR | 53297.0213 |
| Population Standard Deviation | 34745.8070 |
| Sample Variance | 1509088879.8755 |

### 2. Actual Expenditure Statistical Summary

| Metric | Result |
|---|---:|
| Mean Actual Expenditure | 43309.6010 |
| Median Actual Expenditure | 28879.8630 |
| Minimum Actual Expenditure | 15044.5664 |
| Maximum Actual Expenditure | 77109.9632 |
| Q1 | 23456.4376 |
| Q3 | 72057.1746 |
| IQR | 48600.7370 |
| Population Standard Deviation | 25962.1459 |
| Sample Variance | 842541272.3534 |

### 3. Utilization Statistical Summary

| Metric | Result |
|---|---:|
| Mean Utilization | 72.3853% |
| Median Utilization | 77.3719% |
| Minimum Utilization | 45.4561% |
| Maximum Utilization | 86.1789% |
| Q1 | 68.2070% |
| Q3 | 84.7127% |
| IQR | 16.5057 |
| Population Standard Deviation | 14.8979 |

### 4. Spending Gap Statistical Summary

Unit: BDT Crore

| Metric | Result |
|---|---:|
| Mean Spending Gap | 18345.5519 |
| Median Spending Gap | 11556.3217 |
| Minimum Spending Gap | 2714.9406 |
| Maximum Spending Gap | 35942.8363 |
| Q1 | 6860.0374 |
| Q3 | 34653.6235 |
| IQR | 27793.5861 |
| Population Standard Deviation | 14127.5923 |

### 5. Sector Z-score Analysis

| Sector | Budget Z-score | Actual Z-score | Utilization Z-score |
|---|---:|---:|---:|
| Agriculture and Rural Development | 0.6320 | 1.1073 | 0.9259 |
| Communication Infrastructure | 0.0541 | -0.5558 | -1.8076 |
| Food and Social Safety | -1.2633 | -1.0887 | 0.8275 |
| Human Resource | 1.4792 | 1.3019 | -0.2805 |
| Power and Energy | -0.9019 | -0.7647 | 0.3347 |

Population standard deviation was used for Z-score calculations.

### 6. IQR-based Potential Outlier Analysis

| Metric | Result |
|---|---:|
| Q1 | 68.2070% |
| Q3 | 84.7127% |
| IQR | 16.5057 |
| Lower Bound | 43.4485% |
| Upper Bound | 109.4713% |
| Potential Outliers | 0 |

All five sectors were within the calculated IQR boundaries.

No records were modified during this analysis.

### 7. Key Statistical Findings

1. Mean sector budget was 61655.1529 BDT Crore.
2. Mean actual expenditure was 43309.6010 BDT Crore.
3. Mean utilization was 72.3853%, while median utilization was 77.3719%.
4. Communication Infrastructure recorded the lowest utilization Z-score at -1.8076.
5. No sector was identified as a potential outlier using the 1.5 × IQR rule.

### 8. Statistical Data Quality Validation

| Check | Result |
|---|---:|
| Sector Count | 5 |
| Missing Budget | 0 |
| Missing Actual | 0 |
| Invalid Budget | 0 |
| Invalid Utilization | 0 |

**Statistical Input Status: PASS**

### Methodological Limitation

This analysis covers only five defined sectors representing 13 approved ministry mappings. The results are descriptive and should not be generalized to all 62 ministries or the entire government budget.

Outlier flags and Z-scores indicate statistical differences, not financial misconduct or operational inefficiency.

### Conclusion

All seven statistical SQL analyses executed successfully. Budget, expenditure, utilization, and spending gap distributions were calculated, and the statistical input validation passed.

**Step 16.19 Status: COMPLETED SUCCESSFULLY**