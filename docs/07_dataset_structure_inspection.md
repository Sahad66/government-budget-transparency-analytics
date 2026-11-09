# DATASET STRUCTURE INSPECTION REPORT

## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Phase:** 02 — Data Acquisition & Understanding  
**Step:** 07 — Dataset Structure Inspection  
**Tools:** Python, Pandas, pdfplumber

## 1. Inspection Objectives

The objective is to inspect the structure and readability of the collected government budget PDF documents before data extraction and cleaning.

## 2. Dataset Information

### Dataset 01

File: FY2024-25_Statement_1_Budget_and_Accounts.pdf

- Financial Year: 2024–25
- Format: PDF
- Expected Pages: 2
- Unit: Taka in Crore
- Status: Draft

### Dataset 02

File: FY2024-25_Statement_2_Ministry_Wise_Expenditure.pdf

- Financial Year: 2024–25
- Format: PDF
- Expected Pages: 3
- Unit: Taka in Thousands
- Status: Draft Version

## 3. Inspection Checklist

- [ ] PDF file existence verified.
- [ ] Total pages inspected.
- [ ] Text extraction tested.
- [ ] Tables identified.
- [ ] Rows and columns counted.
- [ ] Column names inspected.
- [ ] Data types investigated.
- [ ] Empty and missing values investigated.
- [ ] Table extraction quality evaluated.

## 4. Inspection Results

### Dataset 01

- Actual Pages:
- Tables Found:
- Total Rows:
- Total Columns:
- Extraction Quality:
- Observed Issues:

### Dataset 02

- Actual Pages:
- Tables Found:
- Total Rows:
- Total Columns:
- Extraction Quality:
- Observed Issues:

## 5. Potential Data Structure Issues

The following issues will be investigated:

1. Repeated table headers.
2. Merged cells.
3. Missing or empty cells.
4. Numeric values stored as text.
5. Tables split across multiple PDF pages.
6. Inconsistent column alignment.
7. Differences in monetary units.

## 6. Inspection Conclusion

The structure inspection will determine whether the source PDF tables can be extracted directly using Python or require additional PDF processing.

No cleaning or transformation will be performed during this step.

**End of Inspection Report**