/*==============================================================================
Project:    Local Authority Austerity and Food Bank Demand
Author:     Kevin Kim, PhD student, Economics
Date:       2026-03-26
Purpose:    Import IMD 2019 data from Excel and create LAD-level deprivation measures
Inputs:     $raw/imd2019/File_10_IoD2019_LAD_Summaries_LowerTier.xlsx
Outputs:    $inter/lad_lowertier_imd2019.dta
Notes:      English Indices of Deprivation 2019 (317 LA districts)
            - score vars: higher = more deprived
            - rank  vars: 1 = most deprived, 317 = least deprived
==============================================================================*/

version 18
clear all
set more off

/* ------------------------------------------------------------------
   Import English Indices of Deprivation 2019 (lower-tier LA level)
   ------------------------------------------------------------------ */
import excel "$raw/imd2019/File_10_IoD2019_LAD_Summaries_LowerTier.xlsx", ///
    sheet("IMD") firstrow case(lower) clear

/* Add year identifier and standardize variable names */
gen year = 2019
move year imdaveragerank
rename localauthoritydistrictcode2 onscode
rename localauthoritydistrictname2 la_name

/* Label IMD average rank measures */
label var imdaveragerank ///
    "IMD 2019 average rank score (higher = more deprived)"
label var imdrankofaveragerank ///
    "IMD 2019 rank of average rank (1 = most deprived, 317 = least deprived)"

/* Label IMD average score measures */
label var imdaveragescore ///
    "IMD 2019 average score (higher = more deprived)"
label var imdrankofaveragescore ///
    "IMD 2019 rank of average score (1 = most deprived, 317 = least deprived)"

/* Label LSOA concentration measures */
label var imdproportionoflsoasinmos ///
    "Share of LSOAs in most deprived 10 percent (higher = more deprived)"
label var imdrankofproportionoflsoa ///
    "Rank of share in most deprived 10 percent (1 = most deprived, 317 = least deprived)"

/* Label extent and local concentration measures */
label var imd2019extent ///
    "IMD 2019 extent (population in most deprived 30 percent, higher = more deprived)"
label var imd2019rankofextent ///
    "IMD 2019 rank of extent (1 = most deprived, 317 = least deprived)"
label var imd2019localconcentration ///
    "IMD 2019 local concentration (higher = more deprived)"
label var imd2019rankoflocalconcent ///
    "IMD 2019 rank of local concentration (1 = most deprived, 317 = least deprived)"

/* Label LA identifiers */
label var onscode "ONS local authority code (2019 basis)"
label var la_name "Local authority name (2019 basis)"
label var year "Year of IMD extract (2019)"

/* Save processed IMD data */
save "$inter/lad_lowertier_imd2019.dta", replace

di "IMD 2019 data imported and saved to $inter/lad_lowertier_imd2019.dta"
