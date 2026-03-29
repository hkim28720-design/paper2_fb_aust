/*==============================================================================
* 08_build_harmonized_panel.do
*
* Title:       Build harmonized LAD-year panel 2007-2023
* Purpose:     Build LAD-year panel 2007-2023 by merging RS and RA data,
*              applying ONS crosswalks and structural reorganizations, and
*              linking foodbank, NUTS1, population, GDP deflator, election,
*              and IMD data. Post-process to ensure RA variables are missing
*              for pre-2018 years.
* Author:      Kevin Kim
* Date:        2026-03-26
*
* Inputs:      $inter/rs_panel.dta
*              $inter/ra_panel.dta
*              $raw/foodbank/parcels1823.dta
*              $raw/nuts1/NUTS1.dta
*              $raw/population/pop.dta
*              $raw/gdpdeflator/gdpdeflator.dta
*              $inter/electionlocal_with_onscode.dta
*              $inter/lad_lowertier_imd2019.dta
*
* Outputs:     $inter/PANEL_2007_2023_harmonized.dta
*
* Notes:       AER-style replication package structure.
*              IDs kept & ordered: onscode year ecode
*              Missing values (.) preserved throughout.
*              ONS codes harmonized BEFORE merges.
*==============================================================================*/

version 18
clear all
set more off

*========================================================
* 1) ONS crosswalk (old -> new). Using-side is UNIQUE.
*========================================================
tempfile XMAP
preserve
clear
input str9 oldcode str9 newcode
// 2012
"E07000100" "E07000240"
"E07000104" "E07000241"
// 2013
"E06000048" "E06000057"
"E07000097" "E07000242"
"E07000101" "E07000243"
"E08000020" "E08000037"
// 2019 (Suffolk, BCP, Dorset)
"E07000201" "E07000245"
"E07000204" "E07000245"
"E07000205" "E07000244"
"E07000206" "E07000244"
"E06000028" "E06000058"
"E06000029" "E06000058"
"E07000048" "E06000058"
"E07000049" "E06000059"
"E07000050" "E06000059"
"E07000051" "E06000059"
"E07000052" "E06000059"
"E07000053" "E06000059"
// 2020 Buckinghamshire UA
"E07000004" "E06000060"
"E07000005" "E06000060"
"E07000006" "E06000060"
"E07000007" "E06000060"
"E10000002" "E06000060"
// 2021 Northamptonshire split
"E07000150" "E06000061"
"E07000152" "E06000061"
"E07000153" "E06000061"
"E07000156" "E06000061"
"E07000151" "E06000062"
"E07000154" "E06000062"
"E07000155" "E06000062"
end
rename oldcode onscode
rename newcode onscode_new
isid onscode
save `XMAP'
restore

*========================================================
* 2) RS ⨝ RA (ecode×year) → core panel; then fill onscode
*========================================================
use "$inter/rs_panel.dta", clear
replace ecode = strtrim(itrim(ecode))
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/")
keep if inrange(year,2007,2023)

* Drop summary/total rows imported from Excel (missing ecode or year)
drop if missing(ecode) | strtrim(ecode) == ""
drop if missing(year)

* Drop England-level total rows if present in any year
drop if strtrim(upper(ecode)) == "E92000001"
drop if regexm(lower(localauthority), "^total|^england")

* Verify unique key before merge
isid ecode year

merge 1:1 ecode year using "$inter/ra_panel.dta"
* RS covers 2007-2023; RA only 2018-2023.
* _merge==1 (RS only) expected for 2007-2017 observations.
tab _merge
drop _merge

* onscode hygiene + old->new (if exists)
capture confirm variable onscode
if !_rc {
    replace onscode = upper(strtrim(onscode))
    merge m:1 onscode using `XMAP', keep(master match) nogen
    replace onscode = onscode_new if !missing(onscode_new)
    capture drop onscode_new
}

* ecode->onscode backfill for missing pre-2014 RS
preserve
    keep if !missing(onscode)
    gsort ecode -year
    by ecode: keep if _n==1
    keep ecode onscode
    duplicates drop
    rename onscode onscode_map
    tempfile XWALK
    save `XWALK'
restore

capture confirm variable onscode
if _rc gen str9 onscode = ""
merge m:1 ecode using `XWALK', nogen
replace onscode = onscode_map if missing(onscode) & !missing(onscode_map)
drop onscode_map

* final harmonization
replace onscode = upper(strtrim(onscode))
merge m:1 onscode using `XMAP', keep(master match) nogen
replace onscode = onscode_new if !missing(onscode_new)
capture drop onscode_new

* exclude non-LAD bodies
gen long _enum = real(substr(ecode,2,.))
drop if inrange(_enum,6002,6073)
drop if inrange(_enum,6101,6147) | _enum==6161
drop if inrange(_enum,6201,6207)
drop if inrange(_enum,6342,6347)
drop if _enum==6803
drop if inrange(_enum,7002,7055)
drop _enum

* Key identifier completeness check: missing onscode or year breaks subsequent
* collapse/merge logic, so remove proactively.
count if missing(onscode) | missing(year)
drop if missing(onscode) | missing(year)

* collapse to LAD-year
capture noisily ds rs_* ra_*, has(type numeric)
local sumvars `r(varlist)'
gen str10 ecode_ref = ecode
if "`sumvars'" != "" {
    collapse (sum) `sumvars' (firstnm) ecode_ref, by(onscode year)
}
else {
    collapse (firstnm) ecode_ref, by(onscode year)
}
rename ecode_ref ecode
order onscode year ecode, first
save "$inter/LADPANEL_core_2007_2023.dta", replace

*========================================================
* 3) Foodbank (onscode×year)
*========================================================
use "$raw/foodbank/parcels1823.dta", clear
* Foodbank source uses ladcd/ladnm; rename to project standard
capture confirm variable ladcd
if !_rc {
    rename ladcd  onscode
    rename ladnm  localauthority
}
replace onscode = upper(strtrim(onscode))
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/")
keep if inrange(year,2007,2023)
drop if missing(onscode) | missing(year)
merge m:1 onscode using `XMAP', keep(master match) nogen
replace onscode = onscode_new if !missing(onscode_new)
capture drop onscode_new

capture noisily ds parcels* count* total* fb_*, has(type numeric)
local fbvars `r(varlist)'
if "`fbvars'" != "" {
    collapse (sum) `fbvars', by(onscode year)
}
else {
    capture isid onscode year
    if _rc {
        duplicates tag onscode year, gen(_dup)
        by onscode year: keep if _n==1
        drop _dup
    }
}
tempfile FB
save `FB'

use "$inter/LADPANEL_core_2007_2023.dta", clear
* Verify unique key before merge
isid onscode year
merge 1:1 onscode year using `FB', keep(master match) nogen
save "$inter/PANEL_FB.dta", replace

*========================================================
* 4) NUTS1 (m:1 onscode)
*========================================================
use "$raw/nuts1/NUTS1.dta", clear
replace onscode = upper(strtrim(onscode))
drop if missing(onscode)
merge m:1 onscode using `XMAP', keep(master match) nogen
replace onscode = onscode_new if !missing(onscode_new)
capture drop onscode_new
duplicates drop onscode, force
isid onscode
tempfile NUTS
save `NUTS'

use "$inter/PANEL_FB.dta", clear
merge m:1 onscode using `NUTS', keep(master match) nogen
save "$inter/PANEL_FB_NUTS.dta", replace

*========================================================
* 5) Population (m:1 onscode year)
*========================================================
use "$raw/population/pop.dta", clear
replace onscode = upper(strtrim(onscode))
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/")
keep if inrange(year,2007,2023)
drop if missing(onscode) | missing(year)
merge m:1 onscode using `XMAP', keep(master match) nogen
replace onscode = onscode_new if !missing(onscode_new)
capture drop onscode_new
capture isid onscode year
if _rc {
    duplicates tag onscode year, gen(_dup)
    by onscode year: keep if _n==1
    drop _dup
}
tempfile POP
save `POP'

use "$inter/PANEL_FB_NUTS.dta", clear
merge m:1 onscode year using `POP', keep(master match) nogen
save "$inter/PANEL_FB_NUTS_POP.dta", replace

*========================================================
* 6) GDP Deflator (m:1 year)
*========================================================
use "$raw/gdpdeflator/gdpdeflator.dta", clear
capture confirm numeric variable gdpdeflator
if _rc destring gdpdeflator, replace ignore(", ")
drop if missing(year) | missing(gdpdeflator)
isid year
tempfile DEF
save `DEF'

use "$inter/PANEL_FB_NUTS_POP.dta", clear
merge m:1 year using `DEF', keep(master match) nogen
save "$inter/PANEL_FB_NUTS_POP_DEF.dta", replace

*========================================================
* 7) Election (1:1 onscode year)
*========================================================
use "$inter/electionlocal_with_onscode.dta", clear
replace onscode = upper(strtrim(onscode))
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/")
keep if inrange(year,2007,2023)
drop if missing(onscode) | missing(year)
merge m:1 onscode using `XMAP', keep(master match) nogen
replace onscode = onscode_new if !missing(onscode_new)
capture drop onscode_new

capture confirm variable mscore
if !_rc {
    gsort onscode year -mscore
    by onscode year: keep if _n==1
}
else {
    egen __nonmiss = rownonmiss(_all)
    gsort onscode year -__nonmiss
    by onscode year: keep if _n==1
    drop __nonmiss
}
isid onscode year
tempfile ELEC
save `ELEC'

use "$inter/PANEL_FB_NUTS_POP_DEF.dta", clear
merge 1:1 onscode year using `ELEC', keep(master match) nogen
save "$inter/PANEL_FB_NUTS_POP_DEF_ELECT.dta", replace

*========================================================
* 8) IMD2019 Local Authority District lower-tier
*    (1:1 onscode year)
*========================================================
use "$inter/PANEL_FB_NUTS_POP_DEF_ELECT.dta", clear
merge 1:1 onscode year using "$inter/lad_lowertier_imd2019.dta", ///
  keep(master match) nogen

* Final key identifier completeness check: remove any missing onscode or year
* to prevent isid failures at final stage.
drop if missing(onscode) | missing(year)
capture isid onscode year
if _rc {
    duplicates tag onscode year, gen(_dup2)
    by onscode year: keep if _n==1
    drop _dup2
}

*========================================================
* 9) Post-processing: Set RA variables to missing for
*    years 2007–2017 (RA data unavailable pre-2018)
*========================================================
keep if inrange(year,2007,2023)

capture confirm variable ra_education
if !_rc replace ra_education = . if inrange(year,2007,2017)

capture confirm variable ra_transportation
if !_rc replace ra_transportation = . if inrange(year,2007,2017)

capture confirm variable ra_childSC
if !_rc replace ra_childSC = . if inrange(year,2007,2017)

capture confirm variable ra_adultSC
if !_rc replace ra_adultSC = . if inrange(year,2007,2017)

capture confirm variable ra_health
if !_rc replace ra_health = . if inrange(year,2007,2017)

capture confirm variable ra_housing
if !_rc replace ra_housing = . if inrange(year,2007,2017)

capture confirm variable ra_culture
if !_rc replace ra_culture = . if inrange(year,2007,2017)

capture confirm variable ra_environment
if !_rc replace ra_environment = . if inrange(year,2007,2017)

capture confirm variable ra_planning
if !_rc replace ra_planning = . if inrange(year,2007,2017)

capture confirm variable ra_police
if !_rc replace ra_police = . if inrange(year,2007,2017)

capture confirm variable ra_fire
if !_rc replace ra_fire = . if inrange(year,2007,2017)

capture confirm variable ra_central
if !_rc replace ra_central = . if inrange(year,2007,2017)

capture confirm variable ra_other
if !_rc replace ra_other = . if inrange(year,2007,2017)

capture confirm variable ra_tse
if !_rc replace ra_tse = . if inrange(year,2007,2017)

capture confirm variable ra_nce
if !_rc replace ra_nce = . if inrange(year,2007,2017)

* Validation: Confirm no zeros remain in RA variables for 2007–2017
* (all should be missing now).
capture noisily count if inrange(year,2007,2017) & ///
(ra_education==0 | ra_transportation==0 | ra_childSC==0 | ra_adultSC==0 | ///
 ra_health==0 | ra_housing==0 | ra_culture==0 | ra_environment==0 | ///
 ra_planning==0 | ra_police==0 | ra_fire==0 | ra_central==0 | ///
 ra_other==0 | ra_tse==0 | ra_nce==0)

*========================================================
* 10) Final save
*========================================================
order onscode year ecode, first
compress
save "$inter/PANEL_2007_2023_harmonized.dta", replace

di as txt "OK: PANEL_2007_2023_harmonized.dta saved (IDs: onscode year ecode; missing kept as '.')."

*==============================================================================
* End of do file
*==============================================================================
