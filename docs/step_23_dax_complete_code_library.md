# Step 23 — Complete DAX Code Library
## Government Budget Analytics | Power BI

**Measures Table:** `DAX_Measures`

**Source Tables:**
- `fact_ministry_budget`
- `fact_government_budget_summary`
- `vw_sector_financial_summary`
- `vw_ministry_yoy_analysis`
- `vw_government_yoy_analysis`
- `dim_ministry`
- `dim_fiscal_year`

**Important:** প্রতিটি Measure তৈরি করবে `DAX_Measures` → Modeling → New measure থেকে। Calculated Columns-এর জন্য সংশ্লিষ্ট source table select করে New column ব্যবহার করবে।

---

# 1. Ministry-Level Financial Measures

### 1.1 Total Ministry Budget

```dax
Total Ministry Budget =
SUM(
    fact_ministry_budget[total_budget]
)
```

### 1.2 Total Actual Expenditure

```dax
Total Actual Expenditure =
SUM(
    fact_ministry_budget[actual_expenditure]
)
```

### 1.3 Total Budget Variance

```dax
Total Budget Variance =
[Total Ministry Budget]
    - [Total Actual Expenditure]
```

### 1.4 Budget Utilization %

```dax
Budget Utilization % =
DIVIDE(
    [Total Actual Expenditure],
    [Total Ministry Budget],
    BLANK()
) * 100
```

### 1.5 Total Overspending

```dax
Total Overspending =
CALCULATE(
    SUM(fact_ministry_budget[actual_expenditure])
        - SUM(fact_ministry_budget[total_budget]),
    fact_ministry_budget[actual_expenditure]
        > fact_ministry_budget[total_budget]
)
```

### 1.6 Total Positive Variance

```dax
Total Positive Variance =
CALCULATE(
    SUM(fact_ministry_budget[total_budget])
        - SUM(fact_ministry_budget[actual_expenditure]),
    fact_ministry_budget[total_budget]
        > fact_ministry_budget[actual_expenditure]
)
```

---

# 2. Ministry Count & Performance Measures

### 2.1 Total Ministry Count

```dax
Total Ministry Count =
DISTINCTCOUNT(
    fact_ministry_budget[ministry_id]
)
```

### 2.2 Overspending Ministry Count

```dax
Overspending Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        fact_ministry_budget[actual_expenditure]
            > fact_ministry_budget[total_budget]
    )
)
```

### 2.3 Underutilized Ministry Count

```dax
Underutilized Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        fact_ministry_budget[actual_expenditure]
            < fact_ministry_budget[total_budget]
    )
)
```

### 2.4 Fully Utilized Ministry Count

```dax
Fully Utilized Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        fact_ministry_budget[actual_expenditure]
            = fact_ministry_budget[total_budget]
    )
)
```

### 2.5 Average Ministry Utilization %

```dax
Average Ministry Utilization % =
AVERAGEX(
    fact_ministry_budget,
    DIVIDE(
        fact_ministry_budget[actual_expenditure],
        fact_ministry_budget[total_budget]
    ) * 100
)
```

---

# 3. Ministry Utilization Category Measures

### 3.1 High Utilization Ministry Count

```dax
High Utilization Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        DIVIDE(
            fact_ministry_budget[actual_expenditure],
            fact_ministry_budget[total_budget]
        ) > 1
    )
)
```

### 3.2 Normal Utilization Ministry Count

```dax
Normal Utilization Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        VAR Utilization =
            DIVIDE(
                fact_ministry_budget[actual_expenditure],
                fact_ministry_budget[total_budget]
            ) * 100
        RETURN
            Utilization >= 75
                && Utilization <= 100
    )
)
```

### 3.3 Low Utilization Ministry Count

```dax
Low Utilization Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        VAR Utilization =
            DIVIDE(
                fact_ministry_budget[actual_expenditure],
                fact_ministry_budget[total_budget]
            ) * 100
        RETURN
            Utilization >= 50
                && Utilization < 75
    )
)
```

### 3.4 Very Low Utilization Ministry Count

```dax
Very Low Utilization Ministry Count =
COUNTROWS(
    FILTER(
        fact_ministry_budget,
        DIVIDE(
            fact_ministry_budget[actual_expenditure],
            fact_ministry_budget[total_budget]
        ) < 0.5
    )
)
```

---

# 4. Calculated Columns

**Table:** `fact_ministry_budget`

এগুলো Measure নয়। সংশ্লিষ্ট table select করে Modeling → New column ব্যবহার করবে।

### 4.1 Utilization Category

```dax
Utilization Category =
VAR Utilization =
    DIVIDE(
        fact_ministry_budget[actual_expenditure],
        fact_ministry_budget[total_budget]
    ) * 100
RETURN
    SWITCH(
        TRUE(),
        Utilization > 100, "Overspending",
        Utilization >= 90, "High Utilization",
        Utilization >= 75, "Moderate Utilization",
        Utilization >= 50, "Low Utilization",
        "Very Low Utilization"
    )
```

### 4.2 Ministry Risk Classification

```dax
Ministry Risk Classification =
VAR Utilization =
    DIVIDE(
        fact_ministry_budget[actual_expenditure],
        fact_ministry_budget[total_budget]
    ) * 100
VAR Variance =
    fact_ministry_budget[total_budget]
        - fact_ministry_budget[actual_expenditure]
RETURN
    SWITCH(
        TRUE(),
        Variance < 0, "Overspending Review",
        Utilization < 50, "Very Low Utilization Review",
        Utilization < 75, "Low Utilization Review",
        Utilization < 90, "Moderate Utilization Review",
        "Routine Review"
    )
```

---

# 5. Ministry Risk Count Measures

### 5.1 Overspending Review Count

```dax
Overspending Review Count =
CALCULATE(
    COUNTROWS(fact_ministry_budget),
    fact_ministry_budget[Ministry Risk Classification]
        = "Overspending Review"
)
```

### 5.2 Very Low Utilization Review Count

```dax
Very Low Utilization Review Count =
CALCULATE(
    COUNTROWS(fact_ministry_budget),
    fact_ministry_budget[Ministry Risk Classification]
        = "Very Low Utilization Review"
)
```

### 5.3 Low Utilization Review Count

```dax
Low Utilization Review Count =
CALCULATE(
    COUNTROWS(fact_ministry_budget),
    fact_ministry_budget[Ministry Risk Classification]
        = "Low Utilization Review"
)
```

---

# 6. Sector-Level Financial Measures

**Source:** `vw_sector_financial_summary`

### 6.1 Total Sector Budget

```dax
Total Sector Budget =
SUM(
    vw_sector_financial_summary[total_budget]
)
```

### 6.2 Total Sector Actual Expenditure

```dax
Total Sector Actual Expenditure =
SUM(
    vw_sector_financial_summary[actual_expenditure]
)
```

### 6.3 Sector Budget Variance

```dax
Sector Budget Variance =
[Total Sector Budget]
    - [Total Sector Actual Expenditure]
```

### 6.4 Sector Utilization %

```dax
Sector Utilization % =
DIVIDE(
    [Total Sector Actual Expenditure],
    [Total Sector Budget],
    BLANK()
) * 100
```

### 6.5 Sector Count

```dax
Sector Count =
DISTINCTCOUNT(
    vw_sector_financial_summary[sector_name]
)
```

### 6.6 Sector Ministry Count

```dax
Sector Ministry Count =
SUM(
    vw_sector_financial_summary[ministry_count]
)
```

### 6.7 Sector Budget Contribution %

```dax
Sector Budget Contribution % =
DIVIDE(
    [Total Sector Budget],
    CALCULATE(
        [Total Sector Budget],
        ALL(
            vw_sector_financial_summary[sector_name]
        )
    ),
    BLANK()
) * 100
```

### 6.8 Sector Expenditure Contribution %

```dax
Sector Expenditure Contribution % =
DIVIDE(
    [Total Sector Actual Expenditure],
    CALCULATE(
        [Total Sector Actual Expenditure],
        ALL(
            vw_sector_financial_summary[sector_name]
        )
    ),
    BLANK()
) * 100
```

### 6.9 Sector Budget Expenditure Difference

```dax
Sector Budget Expenditure Difference =
[Sector Budget Contribution %]
    - [Sector Expenditure Contribution %]
```

---

# 7. Ministry Ranking Measures

**Source:** `dim_ministry` and `fact_ministry_budget`

### 7.1 Ministry Budget Rank

```dax
Ministry Budget Rank =
RANKX(
    ALLSELECTED(
        dim_ministry[ministry_name]
    ),
    [Total Ministry Budget],
    ,
    DESC,
    DENSE
)
```

### 7.2 Ministry Expenditure Rank

```dax
Ministry Expenditure Rank =
RANKX(
    ALLSELECTED(
        dim_ministry[ministry_name]
    ),
    [Total Actual Expenditure],
    ,
    DESC,
    DENSE
)
```

### 7.3 Ministry Variance Rank

```dax
Ministry Variance Rank =
RANKX(
    ALLSELECTED(
        dim_ministry[ministry_name]
    ),
    [Total Budget Variance],
    ,
    DESC,
    DENSE
)
```

### 7.4 Top Ministry by Budget

```dax
Top Ministry by Budget =
VAR TopMinistry =
    TOPN(
        1,
        ALLSELECTED(
            dim_ministry[ministry_name]
        ),
        [Total Ministry Budget],
        DESC
    )
RETURN
    CONCATENATEX(
        TopMinistry,
        dim_ministry[ministry_name],
        ", "
    )
```

### 7.5 Top Ministry Budget Amount

```dax
Top Ministry Budget Amount =
MAXX(
    ALLSELECTED(
        dim_ministry[ministry_name]
    ),
    [Total Ministry Budget]
)
```

---

# 8. Government-Level Financial Measures

**Source:** `fact_government_budget_summary`

### 8.1 Government Original Budget

```dax
Government Original Budget =
SUM(
    fact_government_budget_summary[original_budget]
)
```

### 8.2 Government Revised Budget

```dax
Government Revised Budget =
SUM(
    fact_government_budget_summary[revised_budget]
)
```

### 8.3 Government Actual Expenditure

```dax
Government Actual Expenditure =
SUM(
    fact_government_budget_summary[actual_expenditure]
)
```

### 8.4 Government Budget Variance

```dax
Government Budget Variance =
[Government Original Budget]
    - [Government Actual Expenditure]
```

### 8.5 Government Operating Expenditure

```dax
Government Operating Expenditure =
SUM(
    fact_government_budget_summary[operating_expenditure]
)
```

### 8.6 Government Development Expenditure

```dax
Government Development Expenditure =
SUM(
    fact_government_budget_summary[development_expenditure]
)
```

### 8.7 Operating Expenditure Contribution %

```dax
Operating Expenditure Contribution % =
DIVIDE(
    [Government Operating Expenditure],
    [Government Actual Expenditure],
    BLANK()
) * 100
```

### 8.8 Development Expenditure Contribution %

```dax
Development Expenditure Contribution % =
DIVIDE(
    [Government Development Expenditure],
    [Government Actual Expenditure],
    BLANK()
) * 100
```

---

# 9. Government Utilization & Budget Revision Measures

### 9.1 Government Budget Utilization %

```dax
Government Budget Utilization % =
DIVIDE(
    [Government Actual Expenditure],
    [Government Original Budget],
    BLANK()
) * 100
```

### 9.2 Government Revised Budget Variance

```dax
Government Revised Budget Variance =
[Government Revised Budget]
    - [Government Actual Expenditure]
```

### 9.3 Government Revised Budget Utilization %

```dax
Government Revised Budget Utilization % =
DIVIDE(
    [Government Actual Expenditure],
    [Government Revised Budget],
    BLANK()
) * 100
```

### 9.4 Government Budget Revision Amount

```dax
Government Budget Revision Amount =
[Government Revised Budget]
    - [Government Original Budget]
```

### 9.5 Government Budget Revision %

```dax
Government Budget Revision % =
DIVIDE(
    [Government Budget Revision Amount],
    [Government Original Budget],
    BLANK()
) * 100
```

### 9.6 Government Component Difference

```dax
Government Component Difference =
[Government Actual Expenditure]
    - [Government Operating Expenditure]
    - [Government Development Expenditure]
```

---

# 10. YoY Data Availability & Status Measures

**Sources:**
- `vw_ministry_yoy_analysis`
- `vw_government_yoy_analysis`
- `dim_fiscal_year`

### 10.1 Ministry YoY Data Availability

```dax
Ministry YoY Data Availability =
VAR PreviousYearCount =
    CALCULATE(
        COUNTROWS(vw_ministry_yoy_analysis),
        NOT ISBLANK(
            vw_ministry_yoy_analysis[previous_fiscal_year]
        )
    )
RETURN
    IF(
        PreviousYearCount > 0,
        "Available",
        "Insufficient Historical Data"
    )
```

### 10.2 Government YoY Data Availability

```dax
Government YoY Data Availability =
VAR PreviousYearCount =
    CALCULATE(
        COUNTROWS(vw_government_yoy_analysis),
        NOT ISBLANK(
            vw_government_yoy_analysis[previous_fiscal_year]
        )
    )
RETURN
    IF(
        PreviousYearCount > 0,
        "Available",
        "Insufficient Historical Data"
    )
```

### 10.3 Ministry YoY Status

```dax
Ministry YoY Status =
SELECTEDVALUE(
    vw_ministry_yoy_analysis[yoy_status],
    "Insufficient Historical Data"
)
```

### 10.4 Government YoY Status

```dax
Government YoY Status =
SELECTEDVALUE(
    vw_government_yoy_analysis[yoy_status],
    "Insufficient Historical Data"
)
```

### 10.5 Historical Fiscal Year Count

```dax
Historical Fiscal Year Count =
DISTINCTCOUNT(
    dim_fiscal_year[financial_year]
)
```

---

# 11. Expected Validation Results

## Ministry-Level

| KPI | Expected |
|---|---:|
| Total Ministry Budget | 796,999.89 |
| Total Actual Expenditure | 633,314.63 |
| Total Budget Variance | 163,685.26 |
| Budget Utilization | 79.46% |
| Total Ministries | 62 |
| Overspending Ministries | 3 |
| Underutilized Ministries | 59 |
| Fully Utilized Ministries | 0 |
| Gross Overspending | 4,626.47 |
| Positive Variance | 168,311.73 |

## Sector-Level

| KPI | Expected |
|---|---:|
| Sector Count | 5 |
| Mapped Ministry Count | 13 |
| Sector Budget | 308,275.76 |
| Sector Actual | 216,548.00 |
| Sector Variance | 91,727.76 |
| Sector Utilization | 70.24% |

## Government-Level

| KPI | Expected |
|---|---:|
| Original Budget | 797,000 |
| Revised Budget | 744,000 |
| Actual Expenditure | 633,314 |
| Budget Variance | 163,686 |
| Operating Expenditure | 476,302 |
| Development Expenditure | 156,729 |
| Component Difference | 283 |

## YoY

| KPI | Expected |
|---|---|
| Fiscal Year Count | 1 |
| Ministry YoY | Insufficient Historical Data |
| Government YoY | Insufficient Historical Data |

---

# 12. Important Implementation Notes

1. All 51 Measures should be stored under `DAX_Measures`.
2. The two Calculated Columns belong in `fact_ministry_budget`.
3. Do not use New measure for Calculated Columns.
4. Do not use New column for Measures.
5. Government and ministry financial totals must remain separate.
6. Sector analysis covers 13 mapped ministries only.
7. Preserve null values in YoY analysis.
8. Preserve the 283 Crore government component difference.
9. Do not change original financial source data.
10. All expected values must be validated in Power BI before marking the step complete.

**Next Project Step:** Step 24 — Dashboard Layout & Page Design.
