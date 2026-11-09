## 16.16 — Sector Financial Reconciliation

### Objective
Validate sector-level financial aggregation against the underlying ministry fact table and ensure that mapped and unmapped financial records reconcile with the overall ministry financial totals.

### Validation Results

| Validation | Result | Status |
|---|---:|---|
| Approved allocation issues | 0 | PASS |
| Sector-level reconciliation | 5 sectors | PASS |
| Mapped budget difference | 0.0000 | PASS |
| Mapped actual difference | 0.0000 | PASS |
| Overall budget difference | 0.0000 | PASS |
| Overall actual difference | 0.0000 | PASS |
| Duplicate ministry-year records | 0 | PASS |

### Sector Reconciliation

All five defined sectors matched their underlying ministry-level financial calculations.

| Sector | Ministries | Budget Difference | Actual Difference | Status |
|---|---:|---:|---:|---|
| Agriculture and Rural Development | 3 | 0.0000 | 0.0000 | PASS |
| Communication Infrastructure | 3 | 0.0000 | 0.0000 | PASS |
| Food and Social Safety | 2 | 0.0000 | 0.0000 | PASS |
| Human Resource | 3 | 0.0000 | 0.0000 | PASS |
| Power and Energy | 2 | 0.0000 | 0.0000 | PASS |

### Overall Financial Reconciliation

| Metric | Amount (BDT Crore) |
|---|---:|
| Overall Ministry Budget | 796999.8907 |
| Mapped Ministry Budget | 308275.7643 |
| Unmapped Ministry Budget | 488724.1264 |
| Budget Difference | 0.0000 |
| Overall Actual Expenditure | 633314.6279 |
| Mapped Actual Expenditure | 216548.0048 |
| Unmapped Actual Expenditure | 416766.6231 |
| Actual Difference | 0.0000 |

### Duplicate Validation

No duplicate ministry-year records were detected in the ministry fact table.

### Conclusion

All reconciliation checks passed successfully. Sector-level budget and expenditure totals match the underlying approved ministry mappings. Mapped and unmapped financial totals also reconcile exactly with the overall ministry financial totals.

**Final Status: PASS**

The sector financial aggregation is reconciled for the currently approved 13 ministry mappings. The remaining 49 unmapped ministries are still outside the defined sector analysis and must not be assigned to sectors without an approved classification source.