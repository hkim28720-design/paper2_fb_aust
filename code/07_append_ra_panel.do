/*==============================================================================
* 07_append_ra_panel.do
*
* Title:       Append RA datasets
* Purpose:     Append all year-specific RA processed datasets into ra_panel.dta
* Author:      Kevin Kim
* Date:        2026-03-26
*
* Inputs:      $inter/ra*_processed.dta (year-specific RA processed files)
* Outputs:     $inter/ra_panel.dta
*
* Notes:       AER-style replication package structure.
*              Consolidates RA data from 2018/19 through 2023/24 fiscal years.
*==============================================================================*/

version 18
clear all
set more off

*--- Load first year (2018-19) as base ---
use "$inter/ra2018_19_processed.dta", clear

*--- Append remaining years sequentially ---
append using "$inter/ra2019_20_processed.dta"
append using "$inter/ra2020_21_processed.dta"
append using "$inter/ra2021_22_processed.dta"
append using "$inter/ra2022_23_processed.dta"
append using "$inter/ra2023_24_processed.dta"

*--- Sort and reorder key identifier variables ---
sort ecode year
move year onscode

*--- Final save ---
save "$inter/ra_panel.dta", replace

di as txt "OK: ra_panel.dta created (IDs: onscode year ecode)."

*==============================================================================
* End of do file
*==============================================================================
