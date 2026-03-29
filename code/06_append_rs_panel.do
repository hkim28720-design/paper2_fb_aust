/*==============================================================================
Project:    Local Authority Austerity and Food Bank Demand
Author:     Kevin Kim, PhD student, Economics
Date:       2026-03-26
Purpose:    Append all year-specific RS processed datasets into rs_panel.dta
Inputs:     $inter/rs*_processed.dta (17 files: 2007-08 through 2023-24)
Outputs:    $inter/rs_panel.dta
Notes:      Sequential append of Revenue Outturn data across fiscal years
==============================================================================*/

version 18
clear all
set more off

/*------------------------------------------------------
   Load first year (2007-08) as base
   -------------------------------------------------------*/
use "$inter/rs2007_08_processed.dta", clear

/*------------------------------------------------------
   Append 2008-09 through 2023-24
   -------------------------------------------------------*/
append using "$inter/rs2008_09_processed.dta"
append using "$inter/rs2009_10_processed.dta"
append using "$inter/rs2010_11_processed.dta"
append using "$inter/rs2011_12_processed.dta"
append using "$inter/rs2012_13_processed.dta"
append using "$inter/rs2013_14_processed.dta"
append using "$inter/rs2014_15_processed.dta"
append using "$inter/rs2015_16_processed.dta"
append using "$inter/rs2016_17_processed.dta"
append using "$inter/rs2017_18_processed.dta"
append using "$inter/rs2018_19_processed.dta"
append using "$inter/rs2019_20_processed.dta"
append using "$inter/rs2020_21_processed.dta"
append using "$inter/rs2021_22_processed.dta"
append using "$inter/rs2022_23_processed.dta"
append using "$inter/rs2023_24_processed.dta"

/*------------------------------------------------------
   Sort and reorganize variables
   -------------------------------------------------------*/
sort ecode year
move year onscode

/* Save final panel */
save "$inter/rs_panel.dta", replace

di "RS panel appended: $inter/rs_panel.dta"
