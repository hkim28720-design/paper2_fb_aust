/*==============================================================
  09_process_panel.do
  Project : Local Authority Austerity and Food Bank Demand
  Author  : Kevin Kim
  Date    : 26 March 2026

  Purpose : Post-merge processing of the harmonized LAD panel.
            1. Label all variables consistently.
            2. Convert nominal spending to real (2023 = 100).
            3. Compute per-capita real measures.

  Inputs  : $inter/PANEL_2007_2023_harmonized.dta
            $raw/gdpdeflator/gdpdeflator.dta  (fallback re-merge)
  Outputs : $proc/PANEL_2007_2023_harmonized_processed_v2.dta
===============================================================*/
version 18
clear all
set more off

use "$inter/PANEL_2007_2023_harmonized.dta", clear

/*****************************************************************
 Purpose: Process the harmonized panel for analysis
 1. Label variables
 2. Convert to real spending figures (GDP deflator, 2023 = 100)
 3. Compute real per-capita measures
******************************************************************/


*======================================================
* 1. Variable labels and formats
*======================================================

* --- Keys and IDs
label var year              "Financial Year"
label var onscode           "ONS Code"

* --- Names (clarify provenance)
capture label var ladname_2014plus "LAD Name (2014+ Reference)"
capture label var ladnm            "LAD Name (Foodbank Source)"
capture label var lau121nm         "LAU121 Name"

* --- ITL/NUTS geography
capture label var itl321cd "ITL3 Code"
capture label var itl321nm "ITL3 Name"
capture label var itl221cd "ITL2 Code"
capture label var itl221nm "ITL2 Name"
capture label var itl121cd "ITL1 Code"
capture label var itl121nm "ITL1 Name"

* --- Mapping file artifact
capture label var objectid  "Record ID (Mapping Source)"

* --- Foodbank outcomes
capture label var countparcels "Food Parcels Issued"
capture label var vouchercount "Vouchers Redeemed"
format %12.0fc countparcels vouchercount

* --- Population
capture label var population "Population (Mid-Year, Persons)"
format %12.0fc population
capture label var ladname_pop "LAD Name (Population Source)"

* --- GDP deflator
capture label var gdpdeflator_n "GDP Deflator (UK, 2023=100)"
* Keep the string variable labeled clearly if present
capture label var gdpdeflator   "GDP Deflator (String; Not for Analysis)"

* --- RS/RA fiscal aggregates (Nominal levels; units per source)
foreach pre in rs_ ra_ {
    capture label var `pre'education       "Education (Nominal)"
    capture label var `pre'transportation  "Transport (Nominal)"
    capture label var `pre'childSC         "Child Social Care (Nominal)"
    capture label var `pre'adultSC         "Adult Social Care (Nominal)"
    capture label var `pre'health          "Public Health (Nominal)"
    capture label var `pre'housing         "Housing (Nominal)"
    capture label var `pre'culture         "Culture (Nominal)"
    capture label var `pre'environment     "Environment (Nominal)"
    capture label var `pre'planning        "Planning (Nominal)"
    capture label var `pre'police          "Police (Nominal)"
    capture label var `pre'fire            "Fire & Rescue (Nominal)"
    capture label var `pre'central         "Central Services (Nominal)"
    capture label var `pre'other           "Other Services (Nominal)"
    capture label var `pre'tse             "Total Service Expenditure (Nominal)"
    capture label var `pre'nce             "Net Current Service Expenditure (Nominal)"
    capture label var `pre'reserveapr      "Unallocated Reserve at April 1st (Nominal)"
    capture label var `pre'socialcare      "Social Care, Total (Nominal)"
    capture label var `pre'grant_outaef "Specific and special grants outside AEF"
    capture label var `pre'grant_lssg   "Local Services Support Grant (LSSG)"
    capture label var `pre'grant_inaef  "Specific and special grants inside AEF"
    capture label var `pre'grant_rsg    "Revenue Support Grant"
    capture label var `pre'ctr          "Council Tax Requirement"
}

* --- Apply numeric formats to all fiscal variables
quietly ds rs_* ra_*
foreach v of varlist `r(varlist)' {
    capture format %15.2fc `v'
}

* --- Ensure sort key visible in tables
order onscode year, first



*==========================================
* 2. Convert to real spending and real per capita
*==========================================

* 0) Diagnose years
tab year, missing
list onscode year if year<1955 | year>2023 | missing(year), noobs sepby(year)

* 1) Harmonize sample
keep if inrange(year,2007,2023)

* 2) Ensure numeric deflator exists and fill missings
capture confirm variable gdpdeflator_n
if _rc gen double gdpdeflator_n = .

* Try to recover from string column
capture confirm variable gdpdeflator
if !_rc {
    replace gdpdeflator = trim(gdpdeflator)
    replace gdpdeflator = subinstr(gdpdeflator, ",", "", .)
    destring gdpdeflator, gen(__def_from_str) force
    replace gdpdeflator_n = __def_from_str if missing(gdpdeflator_n) & !missing(__def_from_str)
    drop __def_from_str
}

* If still missing anywhere, re-merge fresh deflator by year
quietly count if missing(gdpdeflator_n)
if r(N) {
    preserve
        keep year
        duplicates drop
        tempfile yrs
        save `yrs'
    restore

    preserve
        use "$raw/gdpdeflator/gdpdeflator.dta", clear
        replace gdpdeflator = trim(gdpdeflator)
        replace gdpdeflator = subinstr(gdpdeflator, ",", "", .)
        capture confirm variable gdpdeflator_n
        if _rc destring gdpdeflator, gen(gdpdeflator_n) force
        keep year gdpdeflator_n
        tempfile DEF
        save `DEF'
    restore

    merge m:1 year using `DEF', nogen update replace
}

* Final sanity
assert !missing(gdpdeflator_n)
assert gdpdeflator_n>0

* 3) Deflation factor (2023=100)
capture drop defl_factor_2023
gen double defl_factor_2023 = 100/gdpdeflator_n
label var defl_factor_2023 "Deflation Factor (x Nominal -> Real, 2023=100)"
format %9.4f defl_factor_2023

* 4) Build nominal varlist (levels only; skip derived)
capture noisily ds rs_* ra_*, has(type numeric)
local _all `r(varlist)'
local lev
foreach v of local _all {
    if regexm("`v'","(_pc|_p1000|_real)$") continue
    local lev `lev' `v'
}

* 5) Create real levels and real per-capita
foreach v of local lev {
    capture drop `v'_real
    gen double `v'_real = `v' * defl_factor_2023 if !missing(defl_factor_2023)
    format %15.2fc `v'_real

    local L : variable label `v'
    if "`L'" == "" local L "`v'"
    local Lr : subinstr local L "(Nominal)" "(Real, 2023=100)", all
    label var `v'_real "`Lr'"

    capture confirm variable population
    if !_rc {
        capture drop `v'_real_pc
        gen double `v'_real_pc = `v'_real / population if !missing(population)
        format %15.4fc `v'_real_pc
        label var `v'_real_pc "`Lr' per Capita"
    }
}

order onscode year, first

save "$proc/PANEL_2007_2023_harmonized_processed_v2.dta", replace

* end of do file
