/*==============================================================
  _master.do — Master Runner for AER Replication Package
  Project : Local Authority Austerity and Food Bank Demand
  Author  : Kevin Kim
  Date    : 28 March 2026

  Purpose : Set project paths and run the full analysis pipeline
            from raw data to final results.

  Instructions:
    1. Set `project` below to YOUR project folder.
    2. Open this file in Stata and run it.
    3. All scripts execute sequentially.

  Requirements:
    - Stata 18 (or later)
    - User-written packages: mtefe, reclink, estout, ivreg2,
                             reghdfe, ftools, ivreghdfe
      All packages are auto-installed below if not present.

  Runtime : Approximately 10-15 minutes on a modern machine.
            Most time is spent on MTE bootstrap (Step 10).
===============================================================*/

version 18
clear all
set more off
pause off
set seed 20251016

* ==============================================================
* Install required user-written packages if not already present
* ==============================================================
capture which mtefe
if _rc {
    di as txt "Installing mtefe..."
    ssc install mtefe, replace
}
capture which reclink
if _rc {
    di as txt "Installing reclink..."
    ssc install reclink, replace
}
capture which estout
if _rc {
    di as txt "Installing estout..."
    ssc install estout, replace
}
capture which ivreg2
if _rc {
    di as txt "Installing ivreg2..."
    ssc install ivreg2, replace
}

* --- reghdfe dependency chain (order matters) ---
* reghdfe v6+ requires the "require" package for dependency management.
* ftools must be installed BEFORE reghdfe.
* reghdfe must be compiled before ivreghdfe can call it.
capture which require
if _rc {
    di as txt "Installing require (dependency manager for reghdfe)..."
    ssc install require, replace
}
capture which ftools
if _rc {
    di as txt "Installing ftools (dependency for reghdfe)..."
    ssc install ftools, replace
}
capture ftools, compile
capture which reghdfe
if _rc {
    di as txt "Installing reghdfe..."
    ssc install reghdfe, replace
}
* Compile reghdfe's Mata library (safe to run even if already compiled)
capture reghdfe, compile
capture which ivreghdfe
if _rc {
    di as txt "Installing ivreghdfe..."
    ssc install ivreghdfe, replace
}

*===============================================================================
* 0. Paths
*===============================================================================
* USER: Set this to the project root on your machine
global project   "/Users/kk/Desktop/paper2_fb_aust"

* Derived paths (do not edit)
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

* Create output directories if they do not exist
cap mkdir "${data}"
cap mkdir "${raw}"
cap mkdir "${inter}"
cap mkdir "${proc}"
cap mkdir "${output}"
cap mkdir "${tables}"
cap mkdir "${figures}"
cap mkdir "${logs}"

* ==============================================================
* STAGE 1: Import raw data (can run independently)
* ==============================================================

* Import Revenue Outturn (RS) Excel files 2007-2024
do "${code}/01_import_rs_outturn.do"

* Import Revenue Accounts (RA) Excel files 2018-2024
do "${code}/02_import_ra_budget.do"

* Import IMD 2019 deprivation data
do "${code}/03_import_imd2019.do"

* Import local election data 2016-2025
do "${code}/04_import_elections.do"

* Fuzzy-match election data to ONS codes
do "${code}/05_match_elections_onscode.do"

* ==============================================================
* STAGE 2: Append year-specific files into panels
* ==============================================================

* Append RS year files into rs_panel.dta
do "${code}/06_append_rs_panel.do"

* Append RA year files into ra_panel.dta
do "${code}/07_append_ra_panel.do"

* ==============================================================
* STAGE 3: Build harmonized LAD-year panel
* ==============================================================

* Merge RS + RA + foodbank + NUTS1 + pop + deflator + elections + IMD
do "${code}/08_build_harmonized_panel.do"

* ==============================================================
* STAGE 4: Process panel for analysis
* ==============================================================

* Label, deflate to real 2023 prices, compute per-capita measures
do "${code}/09_process_panel.do"

* ==============================================================
* STAGE 5: Main analysis
* ==============================================================

* Continuous austerity: FE and IV estimation, robustness, appendix tables
do "${code}/11_analysis_main.do"

* Legacy MTE and binary-2SLS estimation (retained for reference)
*do "${code}/10_analysis_main.do"


* ==============================================================
di as txt "Pipeline complete. All outputs saved."
di as txt "  Figures: ${figures}"
di as txt "  Tables:  ${tables}"
di as txt "  Logs:    ${logs}"
* ==============================================================
