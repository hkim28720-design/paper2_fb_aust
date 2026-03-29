/*==============================================================
  01_import_rs_outturn.do
  Project : Local Authority Austerity and Food Bank Demand
  Author  : Kevin Kim
  Date    : 26 March 2026

  Purpose : Import raw Revenue Outturn (RS) Excel files for
            fiscal years 2007-08 through 2023-24, standardize
            variable names, and save year-specific processed
            Stata datasets.

  Inputs  : $raw/revenue_outturn/rs2007_08.xls through
            rs2023_24.xlsx (17 files)
  Outputs : $inter/rs2007_08_processed.dta through
            rs2023_24_processed.dta (17 files)

  Notes   : - Year variable = first calendar year of fiscal year
            - 2007-10: socialcare (combined); 2011+: childSC, adultSC
            - 2013+: public health introduced
            - 2022-23 and 2023-24 require destring
            - Variable names standardized: rs_education, rs_transportation,
              rs_childSC, rs_adultSC, rs_health, rs_housing, rs_culture,
              rs_environment, rs_planning, rs_police, rs_fire, rs_central,
              rs_other, rs_tse, rs_nce, rs_reserveapr, rs_grant_outaef,
              rs_grant_inaef, rs_grant_rsg, rs_grant_lssg, rs_ctr
===============================================================*/
version 18
clear all
set more off
pause off

*** import datasets

** rs2007_08
clear
import excel "$raw/revenue_outturn/rs2007_08.xls", sheet("Net current expenditure (col 1)") cellrange(A6:CO485) firstrow case(lower) clear
gen year = 2007
save "$inter/rs2007_08.dta", replace

* keep only variables of interest
use "$inter/rs2007_08.dta", clear
keep ecode localauthority region class educationservices highwaysroadsandtransportser socialcare housingservicesgfraonly culturalandrelatedservices environmentalservices planninganddevelopmentservice policeservices fireandrescueservices courtservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo unallocatedfinancialreservesl year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysroadsandtransportser          rs_transportation
rename socialcare                            rs_socialcare
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalservices                 rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename courtservices                         rs_court
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalo           rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename counciltaxrequirementtotalo			 rs_ctr

save "$inter/rs2007_08_processed.dta", replace

*---------------------------------------------------------
** rs2008_09
clear
import excel "$raw/revenue_outturn/rs2008_09.xls", sheet("Net current expenditure (col 1)") cellrange(A6:CV485) firstrow case(lower)
gen year = 2008
save "$inter/rs2008_09.dta", replace

* keep only variables of interest
use "$inter/rs2008_09.dta", clear
keep ecode localauthority region class educationservices highwaysandtransportservices socialcare housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices courtservices centralservices otherservices totalserviceexpenditure netcurrentexpenditure unallocatedfinancialreservesl year specificandspecialrevenuegra bb revenuesupportgrant counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename socialcare                             rs_socialcare
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename courtservices                         rs_court
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpenditure               rs_tse
rename netcurrentexpenditure                 rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename bb									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename counciltaxrequirementtotalo			 rs_ctr

save "$inter/rs2008_09_processed.dta", replace

*---------------------------------------------------------
** rs2009_10
clear
import excel "$raw/revenue_outturn/rs2009_10.xls", sheet("RS LA Data 2009-10 (1)") cellrange(A6:CW450) firstrow case(lower)
gen year = 2009
save "$inter/rs2009_10.dta", replace

* keep only variables of interest
use "$inter/rs2009_10.dta", clear
keep ecode localauthority region class educationservices highwaysandtransportservices socialcare housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo unallocatedfinancialreservesl year specificandspecialrevenuegra bb revenuesupportgrant counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename socialcare                             rs_socialcare
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpenditure                 rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename bb									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename counciltaxrequirementtotalo			 rs_ctr



* note courtservices is omitted from the dataset
save "$inter/rs2009_10_processed.dta", replace

*---------------------------------------------------------
** rs2010_11
clear
import excel "$raw/revenue_outturn/rs2010_11.xlsx", sheet("RS LA Data 2010-11 (1)") cellrange(A6:CW451) firstrow case(lower) clear
gen year = 2010
save "$inter/rs2010_11.dta", replace

* keep only variables of interest
use "$inter/rs2010_11.dta", clear
keep ecode localauthority class educationservices highwaysandtransportservices socialcare housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo unallocatedfinancialreservesl year specificandspecialrevenuegra ba revenuesupportgrant counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename socialcare                             rs_socialcare
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpenditure               rs_tse
rename netcurrentexpenditure                 rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename ba									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename counciltaxrequirementtotalo			 rs_ctr



* note courtservices is omitted from the dataset
save "$inter/rs2010_11_processed.dta", replace

*---------------------------------------------------------
** rs2011_12
clear
import excel "$raw/revenue_outturn/rs2011_12.xls", sheet("RS LA Data 2011-12 (1)") cellrange(A6:CG451) firstrow case(lower) clear
gen year = 2011
save "$inter/rs2011_12.dta", replace

* keep only variables of interest
use "$inter/rs2011_12.dta", clear
keep ecode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo unallocatedfinancialreservesl year specificandspecialrevenuegra be revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpenditure               rs_tse
rename netcurrentexpenditure                 rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename be									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



* socalcare is omitted
* childSC and adultSC introduced here
* rs_grant_lssg introduced
save "$inter/rs2011_12_processed.dta", replace

*---------------------------------------------------------
** rs2012_13
clear
import excel "$raw/revenue_outturn/rs2012_13.xls", sheet("RS LA Data 2012-13 (1)") cellrange(A6:CK451) firstrow case(lower)
gen year = 2012
save "$inter/rs2012_13.dta", replace

* keep only variables of interest
use "$inter/rs2012_13.dta", clear
keep ecode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalof unallocatedfinancialreservesl year specificandspecialrevenuegra be revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalof          rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename be									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



save "$inter/rs2012_13_processed.dta", replace

*---------------------------------------------------------
** rs2013_14
clear
import excel "$raw/revenue_outturn/rs2013_14.xls", sheet("RS LA Data 2013-14 (1)") cellrange(A6:CR451) firstrow case(lower)
gen year = 2013
save "$inter/rs2013_14.dta", replace

* keep only variables of interest
use "$inter/rs2013_14.dta", clear
keep ecode localauthority educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalof unallocatedfinancialreservesl year specificandspecialrevenuegra be revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo


rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalof          rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename be									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr


save "$inter/rs2013_14_processed.dta", replace

*---------------------------------------------------------
** rs2014_15
clear
import excel "$raw/revenue_outturn/rs2014_15.xls", sheet("RS LA Data 2014-15 (1)") cellrange(A6:CM451) firstrow case(lower)
gen year = 2014
save "$inter/rs2014_15.dta", replace

* keep only variables of interest
use "$inter/rs2014_15.dta", clear
keep ecode onscode localauthority region class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalof unallocatedfinancialreservesl year specificandspecialrevenuegra bf revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalof          rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialrevenuegra			 rs_grant_outaef
rename bf									 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr


* public health introduced
save "$inter/rs2014_15_processed.dta", replace

*---------------------------------------------------------
** rs2015_16
clear
import excel "$raw/revenue_outturn/rs2015_16.xlsx", sheet("RS LA Data 2015-16") cellrange(A7:CU451) firstrow case(lower) clear
gen year = 2015
save "$inter/rs2015_16.dta", replace

* keep only variables of interest
use "$inter/rs2015_16.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpenditure estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpenditure                 rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr


* reserve variable name changed
save "$inter/rs2015_16_processed.dta", replace

*---------------------------------------------------------
** rs2016_17
clear
import excel "$raw/revenue_outturn/rs2016_17.xlsx", sheet("RS LA Data 2016-17") cellrange(A7:CV453) firstrow case(lower) clear
gen year = 2016
save "$inter/rs2016_17.dta", replace

* keep only variables of interest
use "$inter/rs2016_17.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpenditure unallocatedfinancialreservesl year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirement


destring educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpenditure unallocatedfinancialreservesl specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirement, replace force

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpenditure                 rs_nce
rename unallocatedfinancialreservesl         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirement			 	 rs_ctr



save "$inter/rs2016_17_processed.dta", replace

*---------------------------------------------------------
** rs2017_18
clear
import excel "$raw/revenue_outturn/rs2017_18.xls", sheet("RS_LA_Data_2017-18") cellrange(A5:CV450) firstrow case(lower) clear
gen year = 2017
save "$inter/rs2017_18.dta", replace

* keep only variables of interest
use "$inter/rs2017_18.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpenditure estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpenditure                 rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



save "$inter/rs2017_18_processed.dta", replace

*---------------------------------------------------------
** rs2018_19
clear
import excel "$raw/revenue_outturn/rs2018_19.xls", sheet("RS_LA_Data_2018-19") cellrange(A7:CY451) firstrow case(lower)
gen year = 2018
save "$inter/rs2018_19.dta", replace

* keep only variables of interest
use "$inter/rs2018_19.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpenditure estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpenditure                 rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



save "$inter/rs2018_19_processed.dta", replace

*---------------------------------------------------------
** rs2019_20
clear
import excel "$raw/revenue_outturn/rs2019_20.xls", sheet("RS_LA_Data_2019-20") firstrow cellrange(A7:DA443) case(lower)
gen year = 2019
save "$inter/rs2019_20.dta", replace

* keep only variables of interest
use "$inter/rs2019_20.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpenditure estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpenditure                 rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



save "$inter/rs2019_20_processed.dta", replace

*---------------------------------------------------------
** rs2020_21
clear
import excel "$raw/revenue_outturn/rs2020_21.xlsx", sheet("RS_LA_Data_2020-21") cellrange(A7:ES439) firstrow case(lower) clear
gen year = 2020
save "$inter/rs2020_21.dta", replace

* keep only variables of interest
use "$inter/rs2020_21.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalo           rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



save "$inter/rs2020_21_processed.dta", replace

*---------------------------------------------------------
** rs2021_22
clear
import excel "$raw/revenue_outturn/rs2021_22.xlsx", sheet("RS_LA_Data_2021-22") cellrange(A12:FN439) firstrow case(lower)
gen year = 2021
save "$inter/rs2021_22.dta", replace

* keep only variables of interest
use "$inter/rs2021_22.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

destring estimatedunallocatedfinancial, replace force

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalo           rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr

* Drop England total row by content rather than position
drop if strtrim(upper(ecode)) == "E92000001" | regexm(lower(localauthority), "^total|^england")

save "$inter/rs2021_22_processed.dta", replace

*---------------------------------------------------------
** rs2022_23
clear
import excel "$raw/revenue_outturn/rs2022_23.xlsx", sheet("RS_LA_Data_2022-23") cellrange(A13:FJ439) firstrow case(lower)
gen year = 2022
save "$inter/rs2022_23.dta", replace

* keep only variables of interest
use "$inter/rs2022_23.dta", clear
keep ecode onscode localauthority class educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

destring educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo estimatedunallocatedfinancial specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo, replace force

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalo           rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr




save "$inter/rs2022_23_processed.dta", replace

*---------------------------------------------------------
** rs2023_24
clear
import excel "$raw/revenue_outturn/rs2023_24.xlsx", sheet("RS_LA_Data_2023-24") cellrange(A13:FJ424) firstrow case(lower)
gen year = 2023
save "$inter/rs2023_24.dta", replace

* keep only variables of interest
use "$inter/rs2023_24.dta", clear
keep ecode onscode localauthority educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo estimatedunallocatedfinancial year specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo

destring educationservices highwaysandtransportservices childrensocialcare adultsocialcare publichealth housingservicesgfraonly culturalandrelatedservices environmentalandregulatoryser planninganddevelopmentservice policeservices fireandrescueservices centralservices otherservices totalserviceexpendituretotal netcurrentexpendituretotalo estimatedunallocatedfinancial specificandspecialgrantsouts specificandspecialgrantsinsi revenuesupportgrant localservicessupportgrantls counciltaxrequirementtotalo, replace force

rename educationservices                     rs_education
rename highwaysandtransportservices          rs_transportation
rename childrensocialcare                    rs_childSC
rename adultsocialcare                       rs_adultSC
rename publichealth                          rs_health
rename housingservicesgfraonly               rs_housing
rename culturalandrelatedservices            rs_culture
rename environmentalandregulatoryser         rs_environment
rename planninganddevelopmentservice         rs_planning
rename policeservices                        rs_police
rename fireandrescueservices                 rs_fire
rename centralservices                       rs_central
rename otherservices                         rs_other
rename totalserviceexpendituretotal          rs_tse
rename netcurrentexpendituretotalo           rs_nce
rename estimatedunallocatedfinancial         rs_reserveapr
rename specificandspecialgrantsouts			 rs_grant_outaef
rename specificandspecialgrantsinsi			 rs_grant_inaef
rename revenuesupportgrant					 rs_grant_rsg
rename localservicessupportgrantls			 rs_grant_lssg
rename counciltaxrequirementtotalo			 rs_ctr



save "$inter/rs2023_24_processed.dta", replace

*---------------------------------------------------------

* end of do file
