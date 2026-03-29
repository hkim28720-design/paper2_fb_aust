# Repository Audit and AER-Style Reorganization Report

**Project:** Local Authority Austerity and Food Bank Demand
**Author:** Kevin Kim
**Date:** 26 March 2026
**Standard:** American Economic Review (AER) Replication Package

---

## A. File Audit Summary

### A.1 Stata Do-Files (Scripts)

| # | Current Location | Essential? | Purpose | Workflow Stage |
|---|---|---|---|---|
| 1 | `raw/RS copy/panelconstruction_rsoutturn.do` | **Yes** | Imports raw Revenue Outturn (RS) Excel files 2007–2024, standardizes variable names across years, saves year-specific `.dta` files | Stage 1: Raw import |
| 2 | `raw/RS copy/Append RS datasets.do` | **Yes** | Appends all year-specific RS `.dta` files into `rs_panel.dta` | Stage 2: Panel append |
| 3 | `raw/RA/panelconstruction_rabudget.do` | **Yes** | Imports raw Revenue Accounts (RA) Excel files 2018–2024, standardizes variable names, saves year-specific `.dta` files | Stage 1: Raw import |
| 4 | `raw/RA/Append RA datasets.do` | **Yes** | Appends all year-specific RA `.dta` files into `ra_panel.dta` | Stage 2: Panel append |
| 5 | `raw/IMD/lad_lowertier_imd2019.do` | **Yes** | Imports IMD 2019 from Excel, creates LAD-level deprivation measures, saves `lad_lowertier_imd2019.dta` | Stage 1: Raw import |
| 6 | `raw/electionlocal/engelect.do` | **Yes** | Imports local election data from Excel, saves `electionlocal.dta` | Stage 1: Raw import |
| 7 | `raw/electionlocal/electionlocal_with_onscode.do` | **Yes** | Fuzzy-matches election data to ONS codes via `reclink`, saves `electionlocal_with_onscode.dta` | Stage 1: Raw import |
| 8 | `raw/panelconstruction/Link rs_panel + ra_panel + foodbank + NUTS1 + POP + gdpdeflator.do` | **Legacy** | Earlier version of the panel merge workflow; superseded by `PANEL_2007_2023_harmonized.do` | Superseded |
| 9 | `raw/panelconstruction/PANEL_2007_2023_harmonized.do` | **Yes** | Master panel construction: merges RS+RA cores, applies ONS crosswalks, adds foodbank/NUTS1/population/deflator/election/IMD data, produces `PANEL_2007_2023_harmonized.dta` | Stage 3: Panel merge |
| 10 | `raw/panelconstruction/PANEL_2007_2023_harmonized_processed.do` | **Yes** | Post-processing: ensures RA variables are missing for pre-2018 years | Stage 3: Panel merge |
| 11 | `intermediate/PANEL_2007_2023_harmonized_processed copy.do` | **Yes** | Labels variables, deflates nominal spending to real 2023 prices, computes per-capita measures, saves `_v2.dta` | Stage 4: Processing |
| 12 | `processed/Replication script for policy brief paper copy.do` | **Yes** | Main analysis script: MTE and 2SLS estimation, produces all tables and figures | Stage 5: Analysis |

### A.2 Raw Data Files

| Domain | Key Files | Essential? | Notes |
|---|---|---|---|
| **Revenue Outturn (RS)** | `raw/RS copy/rs2007_08.xls` through `rs2023_24.xlsx` (17 year-files) | **Yes** | Primary raw spending data; `.xls` for early years, `.xlsx` for later |
| **Revenue Accounts (RA)** | `raw/RA/ra2013_14.xls` through `ra2023_24.xlsx` (11 year-files) | **Yes** | Budget data; raw Excel exists for 2013–2024 but only 2018–2024 are imported and processed into `.dta` by the pipeline |
| **IMD 2019** | `raw/IMD/File_10 - IoD2019_Local_Authority_District_Summaries__lower-tier__.xlsx` | **Yes** | Source for LAD-level deprivation scores |
| **IMD 2019** | `raw/IMD/File_1` through `File_9`, `File_11`–`File_14`, CSV, PDF | No | Reference/documentation; not directly used in pipeline |
| **Elections** | `raw/electionlocal/history2016-2025.xlsx` | **Yes** | Source for local election results |
| **Elections** | `raw/electionlocal/ladmapping.dta` | **Yes** | ONS code lookup for fuzzy matching |
| **Food bank** | `raw/foodbank/parcels1823.dta` | **Yes** | Trussell Trust parcel distribution 2018–2023 |
| **NUTS1** | `raw/nuts1/NUTS1.dta` | **Yes** | Regional classification crosswalk |
| **Population** | `raw/population/pop.dta` | **Yes** | Mid-year population estimates 2010–2023 |
| **GDP Deflator** | `raw/gdpdeflator/gdpdeflator.dta` | **Yes** | UK GDP deflator index (2023=100) |
| **Claimant counts** | `raw/claimant counts/series-071125.xls` | No | Not used in current pipeline |

### A.3 Intermediate and Processed Data Files

| File | Essential? | Role |
|---|---|---|
| All `raw/RS copy/rs*_processed.dta` | **Derived** | Year-specific cleaned RS files; reproducible from scripts |
| All `raw/RA/ra*_processed.dta` | **Derived** | Year-specific cleaned RA files; reproducible from scripts |
| `raw/RS copy/rs_panel.dta` | **Derived** | Appended RS panel; reproducible |
| `raw/RA/ra_panel.dta` | **Derived** | Appended RA panel; reproducible |
| `raw/panelconstruction/LADPANEL_core_2007_2023.dta` | **Derived** | Core LAD panel; reproducible |
| `raw/panelconstruction/PANEL_FB*.dta` (5 incremental files) | **Derived** | Intermediate merge outputs; reproducible |
| `raw/panelconstruction/PANEL_2007_2023_harmonized.dta` | **Derived** | Final harmonized panel; reproducible |
| `intermediate/PANEL_2007_2023_harmonized_processed copy.dta` | **Derived** | Intermediate processed panel |
| `intermediate/PANEL_2007_2023_harmonized_processed_v2 copy.dta` | **Derived** | Analysis-ready panel with real values |
| `processed/PANEL_2007_2023_harmonized_processed_v2 copy.dta` | **Derived** | Duplicate of intermediate v2 |
| `processed/PANEL_2007_2023_harmonized_processed_v3 copy.dta` | **Derived** | Final panel with analysis variables appended |

### A.4 Files to Remove or Archive

| File | Reason |
|---|---|
| `raw/panelconstruction/Link rs_panel + ra_panel + foodbank + NUTS1 + POP + gdpdeflator.do` | Superseded by `PANEL_2007_2023_harmonized.do` |
| `raw/RS copy/rs_panel_processed copy.dta` | Redundant copy |
| `raw/claimant counts/series-071125.xls` | Not used in pipeline |
| All `.DS_Store` files (14 found) | macOS metadata; should be in `.gitignore` |
| `raw/electionlocal/reclink_onscode_link.log` | Log file from one-off matching run |
| `raw/RS copy/ra2019_20_processed.dta` | Misplaced RA file inside RS folder; duplicate of `raw/RA/ra2019_20_processed.dta` |
| All `raw/panelconstruction/*.dta` (intermediate merge files) | Reproducible from code; only final panel needed in `data/processed/`. Includes duplicates of `NUTS1.dta`, `foodbank.dta`, `gdpdeflator.dta`, `lad_lowertier_imd2019.dta`, `electionlocal_with_onscode.dta`, `rs_panel.dta`, `ra_panel.dta`, and `pop.dta` already present in their source folders |
| All `*copy*` file variants | Naming artifacts; should be renamed to clean versions |

---

## B. Workflow Sequence Map

The pipeline has five stages with clear dependencies:

```
STAGE 1: RAW IMPORT (can run in parallel within stage)
  ├── 01_import_rs_outturn.do      → rs2007_08_processed.dta ... rs2023_24_processed.dta
  ├── 02_import_ra_budget.do       → ra2018_19_processed.dta ... ra2023_24_processed.dta
  ├── 03_import_imd2019.do         → lad_lowertier_imd2019.dta
  ├── 04_import_elections.do       → electionlocal.dta
  └── 05_match_elections_onscode.do → electionlocal_with_onscode.dta

STAGE 2: PANEL APPEND (depends on Stage 1)
  ├── 06_append_rs_panel.do        → rs_panel.dta
  └── 07_append_ra_panel.do        → ra_panel.dta

STAGE 3: PANEL MERGE (depends on Stage 2)
  └── 08_build_harmonized_panel.do → PANEL_2007_2023_harmonized.dta
      (merges rs_panel + ra_panel + foodbank + NUTS1 + pop + deflator + elections + IMD)
      (applies ONS code crosswalks for 2012–2021 boundary changes)
      (handles 2007–08 district-to-unitary structural reorganizations)

STAGE 4: PROCESSING (depends on Stage 3)
  └── 09_process_panel.do          → PANEL_2007_2023_harmonized_processed_v2.dta
      (labels, deflation to real 2023 prices, per-capita calculations)

STAGE 5: ANALYSIS (depends on Stage 4)
  └── 10_analysis_main.do          → tables, figures, PANEL_..._v3.dta
      (MTE and 2SLS estimation, placebos, robustness)
```

### Dependency Chain (Sequential)

```
rs raw Excel files ─┐
                    ├─→ rs_panel.dta ──┐
ra raw Excel files ─┤                  │
                    ├─→ ra_panel.dta ──┤
IMD Excel ──────────→ imd2019.dta ─────┤
Election Excel ─────→ elect_onscode.dta┤
                                       ├─→ PANEL_harmonized.dta
foodbank.dta ──────────────────────────┤     │
NUTS1.dta ─────────────────────────────┤     ▼
pop.dta ───────────────────────────────┤  PANEL_processed_v2.dta
gdpdeflator.dta ───────────────────────┘     │
                                             ▼
                                       Analysis outputs
                                       (tables, figures)
```

---

## C. Proposed Repository Structure

```
paper2_fb_aust/
│
├── README.md                          # Project overview, how to replicate
├── LICENSE                            # Data use terms
├── .gitignore                         # .DS_Store, *.log, etc.
│
├── data/
│   ├── raw/                           # NEVER modified by code
│   │   ├── revenue_outturn/           # RS Excel files (2007–2024)
│   │   │   ├── rs2007_08.xls
│   │   │   ├── rs2008_09.xls
│   │   │   └── ... (through rs2023_24.xlsx)
│   │   ├── revenue_accounts/          # RA Excel files (2013–2024)
│   │   │   ├── ra2013_14.xls
│   │   │   └── ... (through ra2023_24.xlsx)
│   │   ├── imd2019/                   # Index of Multiple Deprivation
│   │   │   ├── File_10_IoD2019_LAD_Summaries_LowerTier.xlsx
│   │   │   └── IoD2019_Statistical_Release.pdf
│   │   ├── elections/                 # Local election data
│   │   │   ├── history2016_2025.xlsx
│   │   │   └── ladmapping.dta
│   │   ├── foodbank/                  # Trussell Trust data
│   │   │   └── parcels1823.dta
│   │   ├── nuts1/                     # Regional classification
│   │   │   └── NUTS1.dta
│   │   ├── population/                # Mid-year estimates
│   │   │   └── pop.dta
│   │   └── gdpdeflator/               # Price index
│   │       └── gdpdeflator.dta
│   │
│   ├── intermediate/                  # Reproducible from code; .gitignore option
│   │   ├── rs_panel.dta
│   │   ├── ra_panel.dta
│   │   └── PANEL_2007_2023_harmonized.dta
│   │
│   └── processed/                     # Analysis-ready datasets
│       └── PANEL_2007_2023_harmonized_processed_v2.dta
│
├── code/
│   ├── _master.do                     # Master script: sets paths, runs all
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
│
├── output/
│   ├── tables/                        # LaTeX or CSV table files
│   ├── figures/                       # PNG/PDF figure exports
│   └── logs/                          # Stata .smcl log files
│
└── docs/                              # Manuscript, notes
    └── (paper drafts, codebook, etc.)
```

### Key Design Principles

1. **`data/raw/` is read-only.** No script ever modifies files here.
2. **`data/intermediate/` and `data/processed/`** contain only files produced by code. They can optionally be excluded from Git (with a note in README that they are reproducible).
3. **`code/`** contains all do-files, numbered sequentially, with a master script at the top.
4. **`output/`** holds all results: tables, figures, and logs. Nothing in `output/` is an input to any other script.
5. **Folder names** use lowercase, no spaces, no special characters.

---

## D. File Renaming Plan

### D.1 Do-Files

| Current Name | Proposed Name | Justification |
|---|---|---|
| `raw/RS copy/panelconstruction_rsoutturn.do` | `code/01_import_rs_outturn.do` | Sequential numbering; clear purpose |
| `raw/RS copy/Append RS datasets.do` | `code/06_append_rs_panel.do` | Remove spaces; sequential |
| `raw/RA/panelconstruction_rabudget.do` | `code/02_import_ra_budget.do` | Sequential numbering; clear purpose |
| `raw/RA/Append RA datasets.do` | `code/07_append_ra_panel.do` | Remove spaces; sequential |
| `raw/IMD/lad_lowertier_imd2019.do` | `code/03_import_imd2019.do` | Simplified name |
| `raw/electionlocal/engelect.do` | `code/04_import_elections.do` | Descriptive name |
| `raw/electionlocal/electionlocal_with_onscode.do` | `code/05_match_elections_onscode.do` | Describes fuzzy matching step |
| `raw/panelconstruction/PANEL_2007_2023_harmonized.do` | `code/08_build_harmonized_panel.do` | Sequential; descriptive |
| `raw/panelconstruction/PANEL_2007_2023_harmonized_processed.do` | (merge into `code/08_build_harmonized_panel.do`) | Short script; logically part of panel build |
| `intermediate/PANEL_2007_2023_harmonized_processed copy.do` | `code/09_process_panel.do` | Remove "copy"; sequential |
| `processed/Replication script for policy brief paper copy.do` | `code/10_analysis_main.do` | AER-standard naming; remove "copy" |
| (new) | `code/_master.do` | Master runner script (to be created) |

### D.2 Data Folders

| Current Name | Proposed Name | Justification |
|---|---|---|
| `raw/RS copy/` | `data/raw/revenue_outturn/` | Descriptive; remove "copy" |
| `raw/RA/` | `data/raw/revenue_accounts/` | Full name for clarity |
| `raw/IMD/` | `data/raw/imd2019/` | Lowercase; specific |
| `raw/electionlocal/` | `data/raw/elections/` | Simplified |
| `raw/foodbank/` | `data/raw/foodbank/` | No change needed |
| `raw/nuts1/` | `data/raw/nuts1/` | No change needed |
| `raw/population/` | `data/raw/population/` | No change needed |
| `raw/gdpdeflator/` | `data/raw/gdpdeflator/` | No change needed |
| `raw/claimant counts/` | (remove or archive) | Not used in pipeline |
| `raw/panelconstruction/` | (remove; scripts move to `code/`, data to `data/intermediate/`) | Mixed content folder; violates separation |

### D.3 Raw Data Files (Selected Renamings)

| Current Name | Proposed Name | Justification |
|---|---|---|
| `history2016-2025.xlsx` | `history2016_2025.xlsx` | Replace hyphen with underscore |
| `File_10 - IoD2019_Local_Authority_District_Summaries__lower-tier__.xlsx` | `File_10_IoD2019_LAD_Summaries_LowerTier.xlsx` | Remove spaces and special characters |
| `parcels1823.dta` | `parcels1823.dta` | Acceptable as-is |

---

## E. Stata Path Revision Plan

### E.1 Current Path Problems

All do-files currently use **hardcoded absolute paths** such as:

```stata
cd "/Users/kk/Desktop/1-replication-package/data/raw/panelconstruction"
```

This creates three problems: (1) paths will break on any other machine, (2) paths reference a different directory (`1-replication-package`) that does not match the current project folder, and (3) intermediate outputs land in scattered locations.

### E.2 Proposed Solution: Master Script with Global Macros

Create `code/_master.do` that defines a single project root and all subdirectory paths as global macros. Every other do-file references these globals instead of hardcoded paths.

```stata
/*==============================================================
  _master.do — Master runner for AER replication package
  Project: Local Authority Austerity and Food Bank Demand
  Author:  Kevin Kim

  Instructions:
    1. Set `root` below to YOUR project folder.
    2. Run this file. It executes the full pipeline.
===============================================================*/
version 18
clear all
set more off

* ---- USER: Set this to the project root on your machine ----
global root "/Users/kk/Desktop/paper2_fb_aust"

* ---- Derived paths (do not edit) ----
global raw      "$root/data/raw"
global inter    "$root/data/intermediate"
global proc     "$root/data/processed"
global code     "$root/code"
global output   "$root/output"
global tables   "$root/output/tables"
global figures  "$root/output/figures"
global logs     "$root/output/logs"

* ---- Create output directories if needed ----
cap mkdir "$output"
cap mkdir "$tables"
cap mkdir "$figures"
cap mkdir "$logs"
cap mkdir "$inter"
cap mkdir "$proc"

* ---- Run pipeline ----
do "$code/01_import_rs_outturn.do"
do "$code/02_import_ra_budget.do"
do "$code/03_import_imd2019.do"
do "$code/04_import_elections.do"
do "$code/05_match_elections_onscode.do"
do "$code/06_append_rs_panel.do"
do "$code/07_append_ra_panel.do"
do "$code/08_build_harmonized_panel.do"
do "$code/09_process_panel.do"
do "$code/10_analysis_main.do"
```

### E.3 Path Substitution Rules

Every do-file must be revised to replace hardcoded paths with globals. The pattern is:

| Current Pattern | Replacement |
|---|---|
| `cd "/Users/kk/Desktop/1-replication-package/data/raw/panelconstruction"` | Remove; use `"$inter"` for saves |
| `cd "/Users/kk/Desktop/1-replication-package/data/processed"` | Remove; use `"$proc"` for saves |
| `use "rs_panel.dta", clear` | `use "$inter/rs_panel.dta", clear` |
| `use "ra_panel.dta", clear` | `use "$inter/ra_panel.dta", clear` |
| `use "foodbank.dta", clear` | `use "$raw/foodbank/parcels1823.dta", clear` |
| `use "NUTS1.dta", clear` | `use "$raw/nuts1/NUTS1.dta", clear` |
| `use "pop.dta", clear` | `use "$raw/population/pop.dta", clear` |
| `use "gdpdeflator.dta", clear` | `use "$raw/gdpdeflator/gdpdeflator.dta", clear` |
| `use "lad_lowertier_imd2019.dta", clear` | `use "$inter/lad_lowertier_imd2019.dta", clear` |
| `use "electionlocal_with_onscode.dta", clear` | `use "$inter/electionlocal_with_onscode.dta", clear` |
| `save "PANEL_2007_2023_harmonized.dta", replace` | `save "$inter/PANEL_2007_2023_harmonized.dta", replace` |
| `save "PANEL_2007_2023_harmonized_processed_v2.dta", replace` | `save "$proc/PANEL_2007_2023_harmonized_processed_v2.dta", replace` |
| `graph export "..."` | `graph export "$figures/filename.png", replace width(2400)` |
| `log using "..."` | `log using "$logs/log_analysis_main.smcl", replace` |

### E.4 Per-Script Revision Summary

| Script | Key Changes |
|---|---|
| `01_import_rs_outturn.do` | Replace all `cd` and hardcoded paths; read from `$raw/revenue_outturn/`; save processed year-files to `$inter/` |
| `02_import_ra_budget.do` | Read from `$raw/revenue_accounts/`; save to `$inter/` |
| `03_import_imd2019.do` | Read from `$raw/imd2019/`; save to `$inter/` |
| `04_import_elections.do` | Read from `$raw/elections/`; save to `$inter/` |
| `05_match_elections_onscode.do` | Read from `$inter/` and `$raw/elections/`; save to `$inter/` |
| `06_append_rs_panel.do` | Read year-files from `$inter/`; save `rs_panel.dta` to `$inter/` |
| `07_append_ra_panel.do` | Read year-files from `$inter/`; save `ra_panel.dta` to `$inter/` |
| `08_build_harmonized_panel.do` | Read panels from `$inter/`, ancillary data from `$raw/` and `$inter/`; save harmonized panel to `$inter/` |
| `09_process_panel.do` | Read from `$inter/`; save analysis-ready file to `$proc/` |
| `10_analysis_main.do` | Read from `$proc/`; export figures to `$figures/`, logs to `$logs/`, save final panel to `$proc/` |

### E.5 Additional Stata Style Improvements

1. **Remove all `cd` commands** from individual do-files. Only `_master.do` sets the working directory (if needed).
2. **Add a header block** to every do-file with: title, author, date, purpose, inputs, outputs.
3. **Use `version 18`** at the top of each script for reproducibility.
4. **Replace `capture` with explicit error handling** where possible (though `capture confirm variable` is acceptable for conditional logic).
5. **Remove Korean-language comments** or translate to English for an international audience.

---

## F. Summary of Issues Found

1. **Scripts scattered across data folders.** Do-files live inside `raw/RS copy/`, `raw/RA/`, `raw/panelconstruction/`, `intermediate/`, and `processed/` rather than a dedicated `code/` folder.

2. **"copy" suffix on critical files.** Several essential files have " copy" appended (e.g., `PANEL_2007_2023_harmonized_processed copy.do`), suggesting they were duplicated manually rather than version-controlled.

3. **Superseded script still present.** `Link rs_panel + ra_panel + foodbank + NUTS1 + POP + gdpdeflator.do` is an earlier, longer version of the merge workflow. It produces different intermediate filenames (e.g., `LADPANEL_clean_LADyear.dta`) than the current production script.

4. **Hardcoded paths to a different directory.** All scripts reference `/Users/kk/Desktop/1-replication-package/` which is not the current project directory (`paper2_fb_aust`).

5. **Intermediate data files in `raw/`.** The `raw/panelconstruction/` folder contains both scripts and derived `.dta` files (PANEL_FB.dta, etc.), violating the raw-data-is-read-only principle.

6. **Duplicate data files across directories.** `PANEL_2007_2023_harmonized_processed_v2` exists in both `intermediate/` and `processed/` as "copy" variants.

7. **Unused raw data.** `raw/claimant counts/` is not referenced by any script.

8. **No master script.** There is no single entry point that documents the execution order.

9. **No `.gitignore`.** `.DS_Store` files and derived data would be committed to version control.

10. **Folder named "RS copy".** The space and "copy" suggest this was duplicated from elsewhere; should be renamed.

---

## G. Implementation Checklist

- [ ] Create `code/` directory and move/rename all do-files per Section D.1
- [ ] Create `data/` directory hierarchy per Section C
- [ ] Move raw data files to appropriate `data/raw/` subdirectories per Section D.2
- [ ] Delete or archive superseded and redundant files per Section A.4
- [ ] Create `code/_master.do` per Section E.2
- [ ] Revise all do-file paths per Section E.3–E.4
- [ ] Translate Korean comments to English in all do-files
- [ ] Add standardized header blocks to all do-files
- [ ] Create `output/tables/`, `output/figures/`, `output/logs/` directories
- [ ] Create `.gitignore` (exclude `.DS_Store`, `*.log`, `data/intermediate/`, `data/processed/`)
- [ ] Write `README.md` with replication instructions
- [ ] Test full pipeline execution from `_master.do`
- [ ] Verify all outputs reproduce correctly
