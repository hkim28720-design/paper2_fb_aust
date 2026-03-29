/*==============================================================================
Project:    Local Authority Austerity and Food Bank Demand
Author:     Kevin Kim, PhD student, Economics
Date:       2026-03-26
Purpose:    Fuzzy-match election data to ONS codes via reclink
Inputs:     $inter/electionlocal.dta, $raw/elections/ladmapping.dta
Outputs:    $inter/electionlocal_with_onscode.dta
Notes:      AER-style reproducible fuzzy merge using reclink (not reclink2)
            Stata 18, no loops, line-by-line explanations
==============================================================================*/

version 18
clear all
set more off

log using "$inter/reclink_onscode_link.log", replace text

/*------------------------------------------------------
   0) Dependencies: reclink installation check
   -------------------------------------------------------*/
capture which reclink
if _rc != 0 ssc install reclink

/*------------------------------------------------------
   1) Master dataset: electionlocal.dta (no ONS codes)
      - Auto-detect LA name variable (candidate approach)
      - Create normalized key (name_key) for fuzzy matching
   -------------------------------------------------------*/
use "$inter/electionlocal.dta", clear

/* Auto-detect LA name variable from candidates */
local master_name ""
capture confirm variable la_name
if _rc == 0 local master_name la_name
capture confirm variable ladname
if _rc == 0 & "`master_name'" == "" local master_name ladname
capture confirm variable lad19nm
if _rc == 0 & "`master_name'" == "" local master_name lad19nm
capture confirm variable authority_name
if _rc == 0 & "`master_name'" == "" local master_name authority_name

if "`master_name'" == "" {
    di as error "electionlocal.dta missing LA name variable (la_name/ladname/lad19nm/authority_name)"
    exit 198
}

/* Create unique row identifier and standardize names */
gen long id_master = _n
gen strL name_clean = lower(`master_name')

/* Remove punctuation and standardize common prefixes/suffixes */
replace name_clean = subinstr(name_clean, "&", " and ", .)
replace name_clean = subinstr(name_clean, "-", " ", .)
replace name_clean = ustrregexra(name_clean, "[^a-z0-9 ]", " ")

/* Remove common title prefixes */
replace name_clean = subinstr(name_clean, "london borough of ", "", .)
replace name_clean = subinstr(name_clean, "royal borough of ", "", .)
replace name_clean = subinstr(name_clean, "city of ", "", .)
replace name_clean = subinstr(name_clean, "metropolitan borough of ", "", .)
replace name_clean = subinstr(name_clean, "county of ", "", .)

/* Remove common title suffixes */
replace name_clean = subinstr(name_clean, " unitary authority", "", .)
replace name_clean = subinstr(name_clean, " district", "", .)
replace name_clean = subinstr(name_clean, " borough", "", .)
replace name_clean = subinstr(name_clean, " county", "", .)
replace name_clean = subinstr(name_clean, " city", "", .)
replace name_clean = subinstr(name_clean, " council", "", .)

/* Trim whitespace */
replace name_clean = itrim(strtrim(name_clean))

/* Standardize St. abbreviations to Saint */
replace name_clean = "saint " + substr(name_clean, 4, .) ///
    if substr(name_clean, 1, 3) == "st "
replace name_clean = subinstr(name_clean, " st. ", " saint ", .)
replace name_clean = subinstr(name_clean, " st ", " saint ", .)

/* Create fixed-width name key for stability */
gen str80 name_key = substr(name_clean, 1, 80)
tempfile master_clean
save `master_clean', replace

/*------------------------------------------------------
   2) Using dataset: ladmapping.dta (with ONS codes)
      - Auto-detect ONS code and name variables
      - Apply identical standardization
   -------------------------------------------------------*/
use "$raw/elections/ladmapping.dta", clear

/* Auto-detect ONS code variable */
local codevar ""
capture confirm variable onscode
if _rc == 0 local codevar onscode
capture confirm variable lad19cd
if _rc == 0 & "`codevar'" == "" {
    rename lad19cd onscode
    local codevar onscode
}
if "`codevar'" == "" {
    di as error "ladmapping.dta missing ONS code (onscode/lad19cd)"
    exit 198
}

/* Auto-detect LA name variable */
local using_name ""
capture confirm variable la_name
if _rc == 0 local using_name la_name
capture confirm variable ladname
if _rc == 0 & "`using_name'" == "" local using_name ladname
capture confirm variable lad19nm
if _rc == 0 & "`using_name'" == "" local using_name lad19nm
capture confirm variable authority_name
if _rc == 0 & "`using_name'" == "" local using_name authority_name
if "`using_name'" == "" {
    di as error "ladmapping.dta missing LA name variable (la_name/ladname/lad19nm/authority_name)"
    exit 198
}

/* Keep only ONS code and name; drop duplicates */
keep onscode `using_name'
duplicates drop

/* Create reference dataset identifier */
gen long id_using = _n
gen strL name_clean = lower(`using_name')

/* Apply identical standardization */
replace name_clean = subinstr(name_clean, "&", " and ", .)
replace name_clean = subinstr(name_clean, "-", " ", .)
replace name_clean = ustrregexra(name_clean, "[^a-z0-9 ]", " ")
replace name_clean = subinstr(name_clean, "london borough of ", "", .)
replace name_clean = subinstr(name_clean, "royal borough of ", "", .)
replace name_clean = subinstr(name_clean, "city of ", "", .)
replace name_clean = subinstr(name_clean, "metropolitan borough of ", "", .)
replace name_clean = subinstr(name_clean, "county of ", "", .)
replace name_clean = subinstr(name_clean, " unitary authority", "", .)
replace name_clean = subinstr(name_clean, " district", "", .)
replace name_clean = subinstr(name_clean, " borough", "", .)
replace name_clean = subinstr(name_clean, " county", "", .)
replace name_clean = subinstr(name_clean, " city", "", .)
replace name_clean = subinstr(name_clean, " council", "", .)
replace name_clean = itrim(strtrim(name_clean))
replace name_clean = "saint " + substr(name_clean, 4, .) ///
    if substr(name_clean, 1, 3) == "st "
replace name_clean = subinstr(name_clean, " st. ", " saint ", .)
replace name_clean = subinstr(name_clean, " st ", " saint ", .)

/* Create fixed-width key and deduplicate within key */
gen str80 name_key = substr(name_clean, 1, 80)
bysort name_key (onscode): keep if _n == 1

tempfile using_clean
save `using_clean', replace

/*------------------------------------------------------
   3) Reclink fuzzy matching (core step)
      - Calculate similarity scores (minimum 0.85)
      - Keep highest score per master record
      - Use m:1 merge to avoid r(459) error
   -------------------------------------------------------*/
use `master_clean', clear

reclink name_key using `using_clean', ///
    idmaster(id_master) idusing(id_using) ///
    gen(mscore) minscore(0.85)

/* Sort by master ID and score, then keep best match per master */
gsort id_master -mscore
by id_master: gen byte best = (_n == 1)
keep if best == 1
drop best

/* Merge reference data on best match using m:1 */
merge m:1 id_using using `using_clean', keep(match) nogen

/* Create flag for low-confidence matches requiring manual review */
gen byte flag_review = (mscore < 0.92)
label var flag_review "1 if mscore<0.92 (manual review suggested)"
label var mscore "reclink similarity score (0~1)"

/* Keep essential variables */
keep id_master onscode mscore flag_review
tempfile matches
save `matches', replace

/*------------------------------------------------------
   4) Add ONS codes to original election data
   -------------------------------------------------------*/
use "$inter/electionlocal.dta", clear
gen long id_master = _n
merge 1:1 id_master using `matches', nogen

/* Reorder and label */
order onscode, after(id_master)
label var onscode "ONS Local Authority code (via reclink from ladmapping)"

/* Optimize storage and save */
compress
save "$inter/electionlocal_with_onscode.dta", replace

/*------------------------------------------------------
   5) Diagnostics: review low-score matches
   -------------------------------------------------------*/
di ""
di "Match quality summary:"
di "====================="
tabulate flag_review
summarize mscore if !missing(onscode)

log close

di ""
di "Election fuzzy-matching complete: $inter/electionlocal_with_onscode.dta"
