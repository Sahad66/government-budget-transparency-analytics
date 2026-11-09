# DATASET COLLECTION LOG

## Project 01: Government Budget Transparency & Spending Efficiency Analytics

**Collection Date:** 31 October 2026  
**Collection Phase:** Phase 02 — Data Acquisition  
**Step:** 06 — Dataset Collection & Download

## 1. Dataset 01

**File Name:** FY2024-25_Statement_1_Budget_and_Accounts.pdf

- Financial Year: 2024–25
- Source: Ministry of Finance, Bangladesh
- Format: PDF
- Pages: 2
- Unit: Taka in Crore
- Document Status: Draft

### Identified Fields

- Revised Budget
- Actual Expenditure
- Budget Balance
- Actual / Budget (%)
- Operating Expenditure
- Development Expenditure

Official PDF:
https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/n/axvjbnqprylg/b/V2Ministry/o/office-mof/2024/12/1ab818d125f4490b9df56731aa0d432b.pdf

## 2. Dataset 02

**File Name:** FY2024-25_Statement_2_Ministry_Wise_Expenditure.pdf

- Financial Year: 2024–25
- Source: Ministry of Finance, Bangladesh
- Format: PDF
- Pages: 3
- Unit: Taka in Thousands
- Document Status: Draft Version

### Identified Fields

- Ministry/Division Code
- Ministry/Division Description
- Targeted Revenue
- Actual Revenue
- Total Budget
- Total Actual Expenditure
- Operating Expenditure
- Development Expenditure

Official PDF:
https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/n/axvjbnqprylg/b/V2Ministry/o/office-mof/2026/5/2740ed25-4207-4d57-a9e0-d7b7652066fe.pdf

## 3. Storage Location

data/raw/

The original PDF files will be stored in the raw data directory without modification.

## 4. Data Collection Notes

1. Both documents are from the official Ministry of Finance website.
2. Both documents are marked Draft.
3. Statement 1 uses Taka in Crore.
4. Statement 2 uses Taka in Thousands.
5. Unit conversion will be required before combining monetary values.
6. Historical reports are required for multi-year trend analysis.
7. The original source files must be preserved.

## 5. Collection Status

- [ ] Statement 1 downloaded
- [ ] Statement 2 downloaded
- [ ] Both files saved in data/raw/
- [ ] File names verified
- [ ] Source and document status recorded

**End of Dataset Collection Log**