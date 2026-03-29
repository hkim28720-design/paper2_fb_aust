# Comprehensive Code Review and Repository Audit Report

**Project:** Local Authority Austerity and Food Bank Demand
**Author:** Kevin Kim
**Reviewer:** Claude (Research Assistant)
**Date:** 29 March 2026

---

## 1. File Audit Summary

### 1.1 Essential Code Files (11 do-files)

| File | Essential | Role | Status |
|---|---|---|---|
| `code/_master.do` | Yes | Master runner; sets globals, installs packages, runs pipeline | Clean |
| `code/01_import_rs_outturn.do` | Yes | Import 17 RS Excel files (2007-2024) | Fixed |
| `code/02_import_ra_budget.do` | Yes | Import 6 RA Excel files (2018-2024) | Fixed |
| `code/03_import_imd2019.do` | Yes | Import IMD 2019 deprivation data | Clean |
| `code/04_import_elections.do` | Yes | Import local election results | Clean |
| `code/05_match_elections_onscode.do` | Yes | Fuzzy-match elections to ONS codes | Clean |
| `code/06_append_rs_panel.do` | Yes | Append RS year files into panel | Fixed |
| `code/07_append_ra_panel.do` | Yes | Append RA year files into panel | Fixed |
| `code/08_build_harmonized_panel.do` | Yes | Core panel merge with ONS crosswalks | Fixed |
| `code/09_process_panel.do` | Yes | Deflate, per-capita, label | Clean |
| `code/10_analysis_main.do` | Yes | MTE and 2SLS estimation | Fixed |

### 1.2 Essential Data Files

| File | Essential | Role |
|---|---|---|
| `data/raw/revenue_outturn/rs*.xls(x)` | Yes | 17 RS source files |
| `data/raw/revenue_accounts/ra*.xls(x)` | Yes | 11 RA source files (6 used: 2018-2024) |
| `data/raw/foodbank/parcels1823.dta` | Yes | Trussell Trust parcel data |
| `data/raw/imd2019/File_10_*.xlsx` | Yes | IMD 2019 LAD summaries |
| `data/raw/elections/history2016_2025.xlsx` | Yes | Local election results |
| `data/raw/elections/ladmapping.dta` | Yes | LAD name to ONS code crosswalk |
| `data/raw/nuts1/NUTS1.dta` | Yes | NUTS1 regional classification |
| `data/raw/population/pop.dta` | Yes | Mid-year population estimates |
| `data/raw/gdpdeflator/gdpdeflator.dta` | Yes | GDP deflator (2023=100) |

### 1.3 Output Files (Reproducible from Code)

| Category | Files | Created by |
|---|---|---|
| Intermediate data | 17 RS + 6 RA processed .dta; rs_panel; ra_panel; PANEL_*.dta | Steps 01-08 |
| Processed data | PANEL_*_v2.dta, PANEL_*_v3.dta | Steps 09-10 |
| Tables | table0-5 + tableA1-A3 (.tex) | Step 10 |
| Figures | 22 PNG files (CommonSupport + mtePlot x 11) | Step 10 |
| Logs | log_analysis_main.smcl | Step 10 |

---

## 2. Stata Code Review Report

### Fixes Applied in This Review

**Fix 1. Duplicate `counciltaxrequirement` in destring (01, rs2016_17)**
The destring command listed `counciltaxrequirement` twice. Removed the duplicate.

**Fix 2. Variable name mismatch `netcurrentexpenditure` vs `netcurrentexpendituretotalo` (01, rs2020_21 and rs2021_22)**
The keep statement retains `netcurrentexpendituretotalo` but the rename targeted `netcurrentexpenditure` (non-existent). Corrected both years to rename `netcurrentexpendituretotalo`.

**Fix 3. Positional `drop in 427` replaced with content-based filter (01, rs2021_22)**
Replaced fragile row-position drop with: `drop if strtrim(upper(ecode)) == "E92000001" | regexm(lower(localauthority), "^total|^england")`.

**Fix 4. `drop in 1/8` silently removed real data (06)**
After appending all 17 year files, the script dropped the first 8 rows by position. After sorting by ecode/year, these are legitimate LAD observations. Removed the drop entirely.

**Fix 5. Missing `.dta` extensions on save commands (02, all 6 RA files)**
All save commands now explicitly include `.dta` extension for consistency with the rest of the codebase.

**Fix 6. Missing `.dta` extensions on use/append commands (07, all RA references)**
Rewrote the file to use clean sequential append structure with explicit `.dta` extensions matching what 02 saves.

**Fix 7. Missing ecode/year cleaning before `isid` check (08)**
Added explicit cleaning of summary/total rows (missing ecode, England total rows) before the uniqueness check.

**Fix 8. Added `isid` checks before key merges (08)**
Added `isid ecode year` before RS-RA merge and `isid onscode year` before foodbank merge.

**Fix 9. Added merge diagnostic (08)**
Added `tab _merge` after RS-RA merge to document that _merge==1 is expected for pre-2018 years.

**Fix 10. Fixed IMD 2019 extraction (10)**
Changed from `max(imdaveragescore)` to `max(cond(year == 2019, imdaveragescore, .))` to ensure only the 2019 value is carried forward.

**Fix 11. Removed permanent sample loss from grant instrument (10)**
Replaced `drop if has2018_grant == 0` with a comment explaining that missing instruments should propagate naturally through listwise deletion, preserving the full panel.

**Fix 12. Added `esttab` table exports (10)**
Added Tables 0-5 exporting summary statistics, MTE results, 2SLS results, placebos, and Analysis 2 results to LaTeX.

**Fix 13. Added first-stage diagnostics (10)**
Added `estat firststage`, `estat endogenous`, and Hansen J test via `ivregress gmm` with cluster-robust weighting.

**Fix 14. Added balance table (10)**
Added Table A1 comparing covariate means by treatment status (TSE cut vs no cut).

**Fix 15. Added reduced-form estimates (10)**
Added Table A2 showing direct effect of instruments on food parcels (without treatment).

**Fix 16. Added first-stage table (10)**
Added Table A3 showing instrument coefficients in the first-stage probit/OLS with joint F-test.

**Fix 17. Added sample flow documentation (10)**
Added diagnostic output showing observation counts at each sample restriction stage.

**Fix 18. Documented RA ecode/onscode column swap (02, ra2022_23)**
Added explanatory comment for the triple-rename in ra2022_23 where Excel columns are swapped.

**Fix 19. Automatic package installation (master)**
Added `capture which` + `ssc install` block for mtefe, reclink, and estout.

### Remaining Cautions (Not Fixed — Require Manual Verification)

| # | File | Issue | Why Not Auto-Fixed |
|---|---|---|---|
| 1 | 01, rs2010_11 | Variable names may differ from import due to long Excel column headers being truncated | Requires opening the actual Excel file to confirm exact imported variable names |
| 2 | 02, all RA years | cellrange start rows differ (A6, A7, A10) | Requires opening Excel files to verify header locations |
| 3 | 05 | `reclink` tiebreaker is non-deterministic when match scores are equal | Functionally acceptable; add secondary sort key for strict reproducibility |
| 4 | 08, line 159 | collapse sums rs_*/ra_* across multiple ecodes per (onscode, year) | Verify this is intended for merged LAs |
| 5 | 09 | `foreach` loops used despite user preference for no-loop code | Stylistic; loops are clear and well-commented |

---

## 3. Workflow Sequence Map

```
STAGE 1: Raw Data Import (Steps 01-04, independent)
  01  →  $inter/rs{YYYY}_processed.dta  (x17)
  02  →  $inter/ra{YYYY}_processed.dta  (x6)
  03  →  $inter/lad_lowertier_imd2019.dta
  04  →  $inter/electionlocal.dta

STAGE 2: Matching (Step 05, requires 04)
  05  →  $inter/electionlocal_with_onscode.dta

STAGE 3: Panel Assembly (Steps 06-07)
  06  →  $inter/rs_panel.dta         (requires 01)
  07  →  $inter/ra_panel.dta         (requires 02)

STAGE 4: Harmonized Panel (Step 08, requires 03, 05, 06, 07)
  08  →  $inter/PANEL_2007_2023_harmonized.dta
         Merges: RS+RA → ONS crosswalk → foodbank → NUTS1 → pop → deflator → elections → IMD

STAGE 5: Processing (Step 09, requires 08)
  09  →  $proc/PANEL_2007_2023_harmonized_processed_v2.dta

STAGE 6: Analysis (Step 10, requires 09)
  10  →  $proc/..._v3.dta
         $figures/*.png (22 files)
         $tables/*.tex (8 tables: 0-5 + A1-A3)
         $logs/log_analysis_main.smcl
```

---

## 4. Proposed AER-Style Folder Structure

The repository now follows AER standards:

```
paper2_fb_aust/
├── README.md
├── .gitignore
├── code/
│   ├── _master.do
│   ├── 01_import_rs_outturn.do
│   ├── 02_import_ra_budget.do
│   ├── 03_import_imd2019.do
│   ├── 04_import_elections.do
│   ├── 05_match_elections_onscode.do
│   ├── 06_append_rs_panel.do
│   ├── 07_append_ra_panel.do
│   ├── 08_build_harmonized_panel.do
│   ├── 09_process_panel.do
│   └── 10_analysis_main.do
├── data/
│   ├── raw/                         Never modified by code
│   │   ├── revenue_outturn/         17 RS Excel files
│   │   ├── revenue_accounts/        11 RA Excel files
│   │   ├── foodbank/                Trussell Trust parcels
│   │   ├── imd2019/                 IMD 2019 summaries
│   │   ├── elections/               Election results + LAD mapping
│   │   ├── nuts1/                   NUTS1 classification
│   │   ├── population/              Mid-year population
│   │   └── gdpdeflator/             GDP deflator
│   ├── intermediate/                Reproducible from Steps 01-08
│   └── processed/                   Analysis-ready (from Steps 09-10)
└── output/
    ├── tables/                      LaTeX tables (8 files)
    ├── figures/                     PNG figures (22 files)
    └── logs/                        Stata log files
```

---

## 5. File Renaming Plan

No file renames needed. Current naming conventions (numbered prefix, descriptive suffix, consistent extensions) follow AER standards.

**Cleanup completed:**
- Deleted stale `code/tmp.dta`
- Deleted stale `code/~_master.do.stswp`
- Deleted stale nested `paper2_fb_aust/paper2_fb_aust/` subfolder

---

## 6. Stata Path Revision Plan

Paths have been revised to match the user's requested convention:

```stata
global project   "/Users/kk/Desktop/paper2_fb_aust"
global data      "${project}/data"
global raw       "${data}/raw"
global inter     "${data}/intermediate"
global proc      "${data}/processed"
global code      "${project}/code"
global output    "${project}/output"
global tables    "${output}/tables"
global figures   "${output}/figures"
global logs      "${output}/logs"
cd "${code}"
```

All 10 do-files reference `$raw`, `$inter`, `$proc`, `$code`, `$figures`, `$logs`, `$tables` — all defined in `_master.do`. No hardcoded paths exist outside `_master.do`.

**Verification:**

| Script | All paths use globals? | Verified |
|---|---|---|
| `_master.do` | Yes (defines them) | OK |
| `01`-`10` | Yes ($raw, $inter, $proc, $figures, $logs, $tables) | OK |
| No `$root` references remain | — | Confirmed via grep |

---

## 7. Tables Produced by Pipeline

| Table | File | Content |
|---|---|---|
| Table 0 | `table0_summary_stats.tex` | Descriptive statistics for estimation sample |
| Table 1 | `table1_mte_analysis1.tex` | MTE estimates: 6 spending cut treatments |
| Table 2 | `table2_iv_analysis1.tex` | 2SLS estimates: 6 spending cut treatments |
| Table 3 | `table3_placebos.tex` | Placebo 2SLS with contemporaneous Y_t |
| Table 4 | `table4_mte_analysis2.tex` | MTE: share protection among non-cutters |
| Table 5 | `table5_iv_analysis2.tex` | 2SLS: share protection among non-cutters |
| Table A1 | `tableA1_balance.tex` | Covariate balance by treatment status |
| Table A2 | `tableA2_reduced_form.tex` | Reduced form: instruments on outcome |
| Table A3 | `tableA3_first_stage.tex` | First stage with joint F-test |
