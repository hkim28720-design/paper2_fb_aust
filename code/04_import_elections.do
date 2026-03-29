/*==============================================================================
Project:    Local Authority Austerity and Food Bank Demand
Author:     Kevin Kim, PhD student, Economics
Date:       2026-03-26
Purpose:    Import local election data 2016-2025 from Excel
Inputs:     $raw/elections/history2016_2025.xlsx
Outputs:    $inter/electionlocal.dta
Notes:      English Councils 2025 (total 316 councils)
            Party composition by council and year
==============================================================================*/

version 18
clear all
set more off

/* Import election history data */
import excel "$raw/elections/history2016_2025.xlsx", ///
    sheet("history2016-2025") firstrow case(lower)

/* Sort and display for verification */
sort councilid year
describe

/* Standardize variable names */
rename authority la_name

/* Label all party variables */
label var la_name "Local Authority"
label var total "Total Seat"
label var con "Conservative Party"
label var lab "Labour Party"
label var ld "Liberal Democrat Party"
label var green "Green Party"
label var ukip "UK Independence Party"
label var ref "Reform UK Party"
label var pc "Plaid Cymru Party"
label var snp "Scottish National Party"
label var other "Other Parties"

/* Save election dataset */
save "$inter/electionlocal.dta", replace

di "Election data imported and saved to $inter/electionlocal.dta"
