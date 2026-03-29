# Local Authority Austerity and Food Bank Demand

**Author:** Kevin Kim
**Date:** March 2026

## Overview

This repository contains the data and code for the paper "Local Authority Austerity and Food Bank Demand." The project examines whether cuts in local authority spending drive food bank usage in England, using a unique panel dataset combining Revenue Outturn and Revenue Accounts data with Trussell Trust food parcel distributions at the local authority district (LAD) level for 2007–2023.

The main estimators are fixed effects (FE) and two-stage least squares (2SLS) via `ivreghdfe` (Correia 2019), with fiscal shock instruments differenced from a 2018 base year. A legacy Marginal Treatment Effects (MTE) specification via `mtefe` is retained for reference.

## How to Replicate

1. **Requirements:**
   - Stata 18 (or later)
   - User-written packages: `mtefe`, `reclink`, `estout`, `ivreg2`, `reghdfe`, `ftools`, `ivreghdfe`
   - All packages are auto-installed by `_master.do` if not already present.

2. **Set the project root:**
   Open `code/_master.do` and edit the line:
   ```stata
   global project "/Users/kk/Desktop/paper2_fb_aust"
   ```
   to match the location of this repository on your machine.

3. **Run the pipeline:**
   ```stata
   do "code/_master.do"
   ```
   This executes all scripts sequentially, from raw data import through final analysis.

4. **Runtime:** Approximately 10–15 minutes. Most time is spent on MTE bootstrap replications in Step 10 (if enabled).

## Repository Structure

```
paper2_fb_aust/
├── README.md
├── .gitignore
├── code/
│   ├── _master.do                     Master script (sets paths, runs all)
│   ├── 01_import_rs_outturn.do        Import Revenue Outturn Excel files
│   ├── 02_import_ra_budget.do         Import Revenue Accounts Excel files
│   ├── 03_import_imd2019.do           Import IMD 2019 deprivation data
│   ├── 04_import_elections.do         Import local election data
│   ├── 05_match_elections_onscode.do  Fuzzy-match elections to ONS codes
│   ├── 06_append_rs_panel.do          Append RS year files into panel
│   ├── 07_append_ra_panel.do          Append RA year files into panel
│   ├── 08_build_harmonized_panel.do   Merge all sources into LAD-year panel
│   ├── 09_process_panel.do            Deflate to real prices, per-capita
│   ├── 10_analysis_main.do            Legacy MTE and binary-2SLS (reference)
│   └── 11_analysis_main.do            Main analysis: FE and IV (ivreghdfe)
├── data/
│   ├── raw/                           Raw inputs (never modified by code)
│   ├── intermediate/                  Reproducible from code
│   └── processed/                     Analysis-ready datasets
└── output/
    ├── tables/                        LaTeX tables
    ├── figures/                       PNG/PDF figures
    └── logs/                          Stata log files
```

## Data Sources

| Domain | Source | Years |
|---|---|---|
| Revenue Outturn (RS) | DLUHC Local Authority Revenue Expenditure and Financing | 2007–2024 |
| Revenue Accounts (RA) | DLUHC Local Authority Revenue Account Budget | 2013–2024 |
| Food bank parcels | Trussell Trust administrative data | 2018–2023 |
| Deprivation | English Indices of Multiple Deprivation 2019 | 2019 |
| Elections | Local council election results | 2016–2025 |
| Population | ONS mid-year population estimates | 2010–2023 |
| GDP Deflator | HM Treasury GDP Deflator (2023 = 100) | 2007–2023 |

## Pipeline Summary

| Step | Script | Purpose |
|---|---|---|
| 1 | `01_import_rs_outturn.do` | Import 17 RS Excel files, standardize variable names |
| 2 | `02_import_ra_budget.do` | Import 6 RA Excel files (2018–2024), standardize names |
| 3 | `03_import_imd2019.do` | Import IMD 2019 LAD-level deprivation scores |
| 4 | `04_import_elections.do` | Import local election results from Excel |
| 5 | `05_match_elections_onscode.do` | Fuzzy-match election LAs to ONS codes via `reclink` |
| 6 | `06_append_rs_panel.do` | Append year-specific RS files into `rs_panel.dta` |
| 7 | `07_append_ra_panel.do` | Append year-specific RA files into `ra_panel.dta` |
| 8 | `08_build_harmonized_panel.do` | Merge RS + RA + foodbank + NUTS1 + pop + deflator + elections + IMD; apply ONS crosswalks and structural reorganization mappings |
| 9 | `09_process_panel.do` | Label variables, deflate to real 2023 prices, compute per-capita measures |
| 10 | `10_analysis_main.do` | Legacy MTE and binary-2SLS estimation (retained for reference) |
| 11 | `11_analysis_main.do` | Main analysis: continuous austerity, FE and IV estimation, robustness, appendix tables |

## Output Tables

| Table | File | Description |
|---|---|---|
| Table 1 | `table1_summary_stats_main.tex` | Summary statistics for main estimation sample |
| Table 2 | `table2_fe_reducedform_main.tex` | Fixed effects and reduced form estimates |
| Table 3 | `table3_iv_main.tex` | IV estimates for aggregate austerity |
| Table 4 | `table4_robustness_main.tex` | Robustness checks (placebo, lead, COVID, functional form) |
| Table A1 | `tableA1_balance.tex` | Balance table by spending cut status |
| Table A2 | `tableA2_binary_iv.tex` | Binary-cut IV comparison |
| Table A3 | `tableA3_servicelevel_fe.tex` | Service-share changes and food parcels |
| Table A4 | `tableA4_firststage.tex` | First-stage regressions |

## Notes

- All paths are set centrally in `_master.do` using hierarchical globals (`${project}` → `${data}` → `${raw}`, etc.).
- The `_master.do` script automatically installs all required user-written packages if not already present.
- Data files (`.dta`) and output files (tables, figures, logs) are included in the repository for completeness.
- The main analysis (`11_analysis_main.do`) uses `ivreghdfe` (Correia 2019) for 2SLS estimation with high-dimensional fixed effects, absorbed via iterative demeaning.
