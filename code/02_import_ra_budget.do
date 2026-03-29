/*==============================================================
  02_import_ra_budget.do
  Project : Local Authority Austerity and Food Bank Demand
  Author  : Kevin Kim
  Date    : 26 March 2026

  Purpose : Import raw Revenue Accounts (RA) Excel files for
            fiscal years 2018-19 through 2023-24, standardize
            variable names, and save year-specific processed
            Stata datasets.

  Inputs  : $raw/revenue_accounts/ra2018_19.xlsx through
            ra2023_24.xlsx (6 files)
  Outputs : $inter/ra2018_19_processed.dta through
            ra2023_24_processed.dta (6 files)

  Notes   : - Only 2018-19 onward are processed (earlier RA
              Excel files exist but are not used in the pipeline)
            - Later years (2022+) require destring
            - Year variable = first calendar year of fiscal year
===============================================================*/
version 18
clear all
set more off
pause off

***import datasets

**ra2018_19
clear
import excel "$raw/revenue_accounts/ra2018_19.xlsx", sheet("RA LA Data 2018-19") cellrange(A7:GQ450) firstrow case(lower)
gen year=2018
save "$inter/ra2018_19.dta", replace


*keep only variables of interest
use "$inter/ra2018_19.dta" ,clear
keep ecode onscode localauthority class totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure year

rename totaleducationservices 			ra_education
rename totalhighwaysandtransportser 	ra_transportation
rename totalchildrenssocialcare 		ra_childSC
rename totaladultsocialcare 			ra_adultSC
rename totalpublichealth	 			ra_health
rename totalhousingservicesgfraonl 		ra_housing
rename totalculturalandrelatedservi 	ra_culture
rename totalenvironmentalandregulato	ra_environment
rename totalplanninganddevelopments 	ra_planning
rename totalpoliceservices 				ra_police
rename totalfireandrescueservices 		ra_fire
rename totalcentralservices 			ra_central
rename totalotherservices 				ra_other
rename totalserviceexpenditure 			ra_tse
rename netcurrentexpenditure 			ra_nce
save "$inter/ra2018_19_processed.dta", replace
*---------------------------------------------------------

**ra2019_20
clear
import excel "$raw/revenue_accounts/ra2019_20.xlsx", sheet("RA LA Data 2019-20") cellrange(A7:FK442) firstrow case(lower) clear
gen year=2019
save "$inter/ra2019_20.dta", replace

*keep only variables of interest
use "$inter/ra2019_20.dta" ,clear
keep ecode onscode localauthority class totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure year

rename totaleducationservices 			ra_education
rename totalhighwaysandtransportser 	ra_transportation
rename totalchildrenssocialcare 		ra_childSC
rename totaladultsocialcare 			ra_adultSC
rename totalpublichealth	 			ra_health
rename totalhousingservicesgfraonl 		ra_housing
rename totalculturalandrelatedservi 	ra_culture
rename totalenvironmentalandregulato	ra_environment
rename totalplanninganddevelopments 	ra_planning
rename totalpoliceservices 				ra_police
rename totalfireandrescueservices 		ra_fire
rename totalcentralservices 			ra_central
rename totalotherservices 				ra_other
rename totalserviceexpenditure 			ra_tse
rename netcurrentexpenditure 			ra_nce

save "$inter/ra2019_20_processed.dta", replace




*---------------------------------------------------------

**ra2020_21
clear
import excel "$raw/revenue_accounts/ra2020_21.xlsx", sheet("RA LA Data 2020-21") cellrange(A7:FP438) firstrow case(lower) clear
gen year=2020
save "$inter/ra2020_21.dta", replace

*keep only variables of interest
use "$inter/ra2020_21.dta" ,clear

keep ecode onscode localauthority class totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure year

destring totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure, replace force
rename totaleducationservices 			ra_education
rename totalhighwaysandtransportser 	ra_transportation
rename totalchildrenssocialcare 		ra_childSC
rename totaladultsocialcare 			ra_adultSC
rename totalpublichealth	 			ra_health
rename totalhousingservicesgfraonl 		ra_housing
rename totalculturalandrelatedservi 	ra_culture
rename totalenvironmentalandregulato	ra_environment
rename totalplanninganddevelopments 	ra_planning
rename totalpoliceservices 				ra_police
rename totalfireandrescueservices 		ra_fire
rename totalcentralservices 			ra_central
rename totalotherservices 				ra_other
rename totalserviceexpenditure 			ra_tse
rename netcurrentexpenditure 			ra_nce
save "$inter/ra2020_21_processed.dta", replace

*---------------------------------------------------------

**ra2021_22
clear
import excel "$raw/revenue_accounts/ra2021_22.xlsx", sheet("RA_LA_Data_2021-22") cellrange(A7:FP432) firstrow case(lower) clear
gen year=2021
save "$inter/ra2021_22.dta", replace


*keep only variables of interest
use "$inter/ra2021_22.dta" ,clear
keep ecode onscode localauthority class totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure year

destring totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure, replace force
rename totaleducationservices 			ra_education
rename totalhighwaysandtransportser 	ra_transportation
rename totalchildrenssocialcare 		ra_childSC
rename totaladultsocialcare 			ra_adultSC
rename totalpublichealth	 			ra_health
rename totalhousingservicesgfraonl 		ra_housing
rename totalculturalandrelatedservi 	ra_culture
rename totalenvironmentalandregulato	ra_environment
rename totalplanninganddevelopments 	ra_planning
rename totalpoliceservices 				ra_police
rename totalfireandrescueservices 		ra_fire
rename totalcentralservices 			ra_central
rename totalotherservices 				ra_other
rename totalserviceexpenditure 			ra_tse
rename netcurrentexpenditure 			ra_nce
save "$inter/ra2021_22_processed.dta", replace

*---------------------------------------------------------

**ra2022_23
clear
import excel "$raw/revenue_accounts/ra2022_23.xlsx", sheet("RA_LA_Data_2022-23") cellrange(A6:FR431) firstrow case(lower) clear
* NOTE: In ra2022_23, the Excel source has ecode and onscode columns swapped
*       relative to all other years. The following renames correct this.
rename ecode onscode1
rename onscode ecode
rename onscode1 onscode
move ecode onscode
sort ecode
gen year=2022
save "$inter/ra2022_23.dta", replace


*keep only variables of interest
use "$inter/ra2022_23.dta" ,clear
keep ecode onscode localauthority class totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure year

destring totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure, replace force
rename totaleducationservices 			ra_education
rename totalhighwaysandtransportser 	ra_transportation
rename totalchildrenssocialcare 		ra_childSC
rename totaladultsocialcare 			ra_adultSC
rename totalpublichealth	 			ra_health
rename totalhousingservicesgfraonl 		ra_housing
rename totalculturalandrelatedservi 	ra_culture
rename totalenvironmentalandregulato	ra_environment
rename totalplanninganddevelopments 	ra_planning
rename totalpoliceservices 				ra_police
rename totalfireandrescueservices 		ra_fire
rename totalcentralservices 			ra_central
rename totalotherservices 				ra_other
rename totalserviceexpenditure 			ra_tse
rename netcurrentexpenditure 			ra_nce
save "$inter/ra2022_23_processed.dta", replace
*---------------------------------------------------------

**ra2023_24
clear
import excel "$raw/revenue_accounts/ra2023_24.xlsx", sheet("RA_LA_Data_2023-24") cellrange(A10:FP420) firstrow case(lower) clear
gen year=2023
save "$inter/ra2023_24.dta", replace


*keep only variables of interest
use "$inter/ra2023_24.dta" ,clear
keep ecode onscode localauthority class totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure year
destring totaleducationservices totalhighwaysandtransportser totalchildrenssocialcare totaladultsocialcare totalpublichealth totalhousingservicesgfraonl totalculturalandrelatedservi totalenvironmentalandregulato totalplanninganddevelopments totalpoliceservices totalfireandrescueservices totalcentralservices totalotherservices totalserviceexpenditure netcurrentexpenditure, replace force
rename totaleducationservices 			ra_education
rename totalhighwaysandtransportser 	ra_transportation
rename totalchildrenssocialcare 		ra_childSC
rename totaladultsocialcare 			ra_adultSC
rename totalpublichealth	 			ra_health
rename totalhousingservicesgfraonl 		ra_housing
rename totalculturalandrelatedservi 	ra_culture
rename totalenvironmentalandregulato	ra_environment
rename totalplanninganddevelopments 	ra_planning
rename totalpoliceservices 				ra_police
rename totalfireandrescueservices 		ra_fire
rename totalcentralservices 			ra_central
rename totalotherservices 				ra_other
rename totalserviceexpenditure 			ra_tse
rename netcurrentexpenditure 			ra_nce
save "$inter/ra2023_24_processed.dta", replace

*---------------------------------------------------------


*end of do file
