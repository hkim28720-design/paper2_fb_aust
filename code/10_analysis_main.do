/*==============================================================
  10_analysis_main.do
  Project : Local Authority Austerity and Food Bank Demand
  Author  : Kevin Kim
  Date    : 26 March 2026

  Purpose : Main analysis script for the policy brief paper.
            - Analysis 1: Effect of spending cuts on food parcels
              D_it = cut indicator; Y_{i,t+1} = asinh(food parcels)
            - Analysis 2: Among councils with no total cut,
              effect of protecting service shares
            - Estimators: MTE (mtefe) and 2SLS
            - Instruments: budget gap, reserves, grant cut
              (all differenced from 2018 base)

  Inputs  : $proc/PANEL_2007_2023_harmonized_processed_v2.dta
  Outputs : $figures/.png (common support and MTE plots)
            $proc/PANEL_2007_2023_harmonized_processed_v3.dta
            $logs/log_analysis_main.smcl
===============================================================*/

version 18.0
clear all
set more off
pause off
set seed 20251016

*======================================================================================
* 0. Paths (inherited from _master.do)
*======================================================================================
capture log close
log using "$logs/log_analysis_main.log", replace text

*======================================================================================
* 1. Load panel and define IDs
*    Source: 2007–2023 LA finance + Trussell + IMD already merged (v2)
*    Keep finance history 2010–2023 for long horizon squeeze measures
*======================================================================================
use "$proc/PANEL_2007_2023_harmonized_processed_v2.dta", clear

encode onscode,  gen(onscode_encode)
encode itl121nm, gen(itl121nm_encode)

xtset onscode_encode year

keep if inrange(year, 2010, 2023)

*======================================================================================
* 2. Outcomes
*    Main: asinh(Trussell parcels in t+1),  t in 2018–2022
*    Placebo: asinh(Trussell parcels in t),  t in 2018–2022
*             asinh(Trussell parcels in t+2) for a simple lag robustness (2018–2021)
*======================================================================================

* main outcome Y_{i,t+1}
capture drop f1_countparcels
gen f1_countparcels = F.countparcels
replace f1_countparcels = . if !inrange(year, 2018, 2022)

capture drop asinh_f1_countparcels
gen asinh_f1_countparcels = asinh(f1_countparcels)
label var asinh_f1_countparcels "asinh(Trussell parcels, t+1)"

count if !missing(asinh_f1_countparcels)
display "Number of main outcome observations (2019–2023) = " r(N)

* placebo outcome Y_{i,t}
capture drop asinh_countparcels_t
gen asinh_countparcels_t = asinh(countparcels) if inrange(year, 2018, 2022)
label var asinh_countparcels_t "Placebo: asinh(Trussell parcels, t)"

* simple two year lead Y_{i,t+2} for robustness (2018–2021 → 2020–2023)
capture drop f2_countparcels
gen f2_countparcels = F2.countparcels
replace f2_countparcels = . if !inrange(year, 2018, 2021)

capture drop asinh_f2_countparcels
gen asinh_f2_countparcels = asinh(f2_countparcels)
label var asinh_f2_countparcels "asinh(Trussell parcels, t+2)"

*======================================================================================
* 3. Core controls
*======================================================================================

capture drop ln_population
gen double ln_population = ln(population) if population > 0
label var ln_population "log(population)"

* IMD 2019: carry the 2019 level to all years as time invariant deprivation
* Explicitly extract year==2019 value to avoid picking up any stale data
by onscode_encode: egen double imd2019_score = max(cond(year == 2019, imdaveragescore, .))
* Fallback: if no 2019 observation, take best available
replace imd2019_score = imdaveragescore if missing(imd2019_score) & !missing(imdaveragescore)
label var imd2019_score "IMD 2019 average score (higher = more deprived)"

* Council Tax Requirement per capita (already in data as rs_ctr_real_pc)
label var rs_ctr_real_pc "Council Tax Requirement per capita (real pc)"

*======================================================================================
* 4. Instruments (deviations from 2018, dated at t)
*    Z1 = asinh(budget gap pc)_t − asinh(budget gap pc)_2018
*    Z2 = asinh(reserves pc)_t − asinh(reserves pc)_2018
*    Z3 = −[asinh(RSG + inside AEF pc)_t − asinh(RSG + inside AEF pc)_2018]
*======================================================================================

*------------------------------------------------------
* 4.1 Budget gap per capita at t and deviation from 2018
*     gap_t = RA_TSE_pc_t − RS_TSE_pc_t
*------------------------------------------------------
capture drop budgetgap_tse_real_pc
gen double budgetgap_tse_real_pc = .
replace budgetgap_tse_real_pc = ra_tse_real_pc - rs_tse_real_pc ///
    if ra_tse_real_pc < . & rs_tse_real_pc < .
label var budgetgap_tse_real_pc "Budget gap (RA − RS), real per capita"

capture drop asinh_budgetgap_t
gen double asinh_budgetgap_t = asinh(budgetgap_tse_real_pc) if budgetgap_tse_real_pc < .
label var asinh_budgetgap_t "asinh(budget gap, real per capita)"

by onscode_encode: gen double asinh_budgetgap_2018 = asinh_budgetgap_t if year == 2018
by onscode_encode: egen double base2018_asinh_budgetgap = max(asinh_budgetgap_2018)
drop asinh_budgetgap_2018

capture drop d_asinh_budgetgap
gen double d_asinh_budgetgap = asinh_budgetgap_t - base2018_asinh_budgetgap ///
    if asinh_budgetgap_t < . & base2018_asinh_budgetgap < .
label var d_asinh_budgetgap "asinh(budget gap)_t − asinh(budget gap)_2018"

*------------------------------------------------------
* 4.2 Reserves per capita relative to 2018
*     rs_reserveapr_real_pc: start of year reserves per capita (real)
*------------------------------------------------------
by onscode_encode: gen double reserveapr_pc_2018 = rs_reserveapr_real_pc if year == 2018
by onscode_encode: egen double base2018_reserveapr_pc = max(reserveapr_pc_2018)
drop reserveapr_pc_2018

capture drop d_reserveapr_asinh
gen double d_reserveapr_asinh = asinh(rs_reserveapr_real_pc) - asinh(base2018_reserveapr_pc) ///
    if rs_reserveapr_real_pc < . & base2018_reserveapr_pc < .
label var d_reserveapr_asinh "asinh(reserves pc)_t − asinh(reserves pc)_2018"

*------------------------------------------------------
* 4.3 Grant cut since 2018 (RSG + inside AEF), flipped so higher = deeper cut
*     rs_grant_rsg_real_pc and rs_grant_inaef_real_pc are real per capita
*------------------------------------------------------
capture drop totgrant_pc
gen double totgrant_pc = rs_grant_rsg_real_pc + rs_grant_inaef_real_pc ///
    if rs_grant_rsg_real_pc < . & rs_grant_inaef_real_pc < .
label var totgrant_pc "Total central grants per capita (real, 2023=100)"

capture drop asinh_totgrant
gen double asinh_totgrant = asinh(totgrant_pc) if totgrant_pc < .
label var asinh_totgrant "asinh(total grants per capita)"

by onscode_encode (year): gen double asinh_totgrant_2018 = asinh_totgrant if year == 2018

* NOTE: Do NOT drop councils missing 2018 grant data. Let missing instruments
* propagate naturally — affected observations are excluded from regressions
* via listwise deletion, preserving the full panel for other analyses.
by onscode_encode: egen double base2018_asinh_grant = max(asinh_totgrant_2018)
drop asinh_totgrant_2018

capture drop d_asinh_grant
gen double d_asinh_grant = asinh_totgrant - base2018_asinh_grant if asinh_totgrant < .
label var d_asinh_grant "Δ asinh(grants pc) since 2018 (↑ = more generous)"

capture drop grantcut_asinh_flipped
gen double grantcut_asinh_flipped = - d_asinh_grant if d_asinh_grant < .
label var grantcut_asinh_flipped "Grant cut since 2018 (↑ = deeper cut)"

*======================================================================================
* 5. Long horizon squeeze 2010→2018 (controls only, by service)
*    For services that start later, use first non missing year as baseline
*======================================================================================

* total service expenditure: 2010 → 2018
by onscode_encode: egen double TSE2010 = max(cond(year == 2010, rs_tse_real_pc, .))
by onscode_encode: egen double TSE2018 = max(cond(year == 2018, rs_tse_real_pc, .))

capture drop d_asinhTSE_2010_2018
gen double d_asinhTSE_2010_2018 = asinh(TSE2018) - asinh(TSE2010) ///
    if TSE2010 > 0 & TSE2018 > 0
label var d_asinhTSE_2010_2018 "Δ asinh total service pc (2018 − 2010)"

* education: 2010 → 2018
by onscode_encode: egen double educ2010 = max(cond(year == 2010, rs_education_real_pc, .))
by onscode_encode: egen double educ2018 = max(cond(year == 2018, rs_education_real_pc, .))

capture drop d_asinh_educ_2010_2018
gen double d_asinh_educ_2010_2018 = asinh(educ2018) - asinh(educ2010) ///
    if educ2010 > 0 & educ2018 > 0
label var d_asinh_educ_2010_2018 "Δ asinh education pc (2018 − 2010)"

* child social care: 2011 → 2018
by onscode_encode: egen double childsc2011 = max(cond(year == 2011, rs_childSC_real_pc, .))
by onscode_encode: egen double childsc2018 = max(cond(year == 2018, rs_childSC_real_pc, .))

capture drop d_asinh_childsc_2011_2018
gen double d_asinh_childsc_2011_2018 = asinh(childsc2018) - asinh(childsc2011) ///
    if childsc2011 > 0 & childsc2018 > 0
label var d_asinh_childsc_2011_2018 "Δ asinh child SC pc (2018 − 2011)"

* adult social care: 2011 → 2018
by onscode_encode: egen double adultsc2011 = max(cond(year == 2011, rs_adultSC_real_pc, .))
by onscode_encode: egen double adultsc2018 = max(cond(year == 2018, rs_adultSC_real_pc, .))

capture drop d_asinh_adultsc_2011_2018
gen double d_asinh_adultsc_2011_2018 = asinh(adultsc2018) - asinh(adultsc2011) ///
    if adultsc2011 > 0 & adultsc2018 > 0
label var d_asinh_adultsc_2011_2018 "Δ asinh adult SC pc (2018 − 2011)"

* public health: 2013 → 2018
by onscode_encode: egen double health2013 = max(cond(year == 2013, rs_health_real_pc, .))
by onscode_encode: egen double health2018 = max(cond(year == 2018, rs_health_real_pc, .))

capture drop d_asinh_health_2013_2018
gen double d_asinh_health_2013_2018 = asinh(health2018) - asinh(health2013) ///
    if health2013 > 0 & health2018 > 0
label var d_asinh_health_2013_2018 "Δ asinh health pc (2018 − 2013)"

* housing: 2010 → 2018
by onscode_encode: egen double housing2010 = max(cond(year == 2010, rs_housing_real_pc, .))
by onscode_encode: egen double housing2018 = max(cond(year == 2018, rs_housing_real_pc, .))

capture drop d_asinh_housing_2010_2018
gen double d_asinh_housing_2010_2018 = asinh(housing2018) - asinh(housing2010) ///
    if housing2010 > 0 & housing2018 > 0
label var d_asinh_housing_2010_2018 "Δ asinh housing pc (2018 − 2010)"

* (other service specific long squeeze controls are already defined above and can be used
*  later if you extend MTE to discretionary services.)

*======================================================================================
* 6. Annual spending changes and service share treatments (t vs t−1)
*======================================================================================

* total service spending cut: t vs t−1
capture drop tsediff
gen double tsediff = rs_tse_real_pc - L.rs_tse_real_pc ///
    if rs_tse_real_pc < . & L.rs_tse_real_pc < .

capture drop treat_tse
gen byte treat_tse = (tsediff < 0) if tsediff < .
label var treat_tse "Treatment: total service spending cut (t vs t−1)"

* ring fenced services: share cuts

* education
capture drop share_education sharediff_education treat_education
gen double share_education = rs_education_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_tse_real_pc < .
gen double sharediff_education = share_education - L.share_education ///
    if share_education < . & L.share_education < .
gen byte treat_education = (sharediff_education < 0) if sharediff_education < .
label var treat_education "Treatment: education share cut"

* child social care
capture drop share_childsc sharediff_childsc treat_childsc
gen double share_childsc = rs_childSC_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_tse_real_pc < .
gen double sharediff_childsc = share_childsc - L.share_childsc ///
    if share_childsc < . & L.share_childsc < .
gen byte treat_childsc = (sharediff_childsc < 0) if sharediff_childsc < .
label var treat_childsc "Treatment: child SC share cut"

* adult social care
capture drop share_adultsc sharediff_adultsc treat_adultsc
gen double share_adultsc = rs_adultSC_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_tse_real_pc < .
gen double sharediff_adultsc = share_adultsc - L.share_adultsc ///
    if share_adultsc < . & L.share_adultsc < .
gen byte treat_adultsc = (sharediff_adultsc < 0) if sharediff_adultsc < .
label var treat_adultsc "Treatment: adult SC share cut"

* public health
capture drop share_health sharediff_health treat_health
gen double share_health = rs_health_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_tse_real_pc < .
gen double sharediff_health = share_health - L.share_health ///
    if share_health < . & L.share_health < .
gen byte treat_health = (sharediff_health < 0) if sharediff_health < .
label var treat_health "Treatment: public health share cut"

* housing
capture drop share_housing sharediff_housing treat_housing
gen double share_housing = rs_housing_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_tse_real_pc < .
gen double sharediff_housing = share_housing - L.share_housing ///
    if share_housing < . & L.share_housing < .
gen byte treat_housing = (sharediff_housing < 0) if sharediff_housing < .
label var treat_housing "Treatment: housing share cut"

*======================================================================================
* 7. Estimation sample definitions
*======================================================================================

capture drop sample_mte
gen byte sample_mte = inrange(year, 2018, 2022) & !missing(asinh_f1_countparcels)
label var sample_mte "Estimation sample (t = 2018...2022 → y = 2019...2023)"

* Sample with no total TSE cut (for Analysis 2)
capture drop sample_nocut_tse
gen byte sample_nocut_tse = sample_mte == 1 & treat_tse == 0
label var sample_nocut_tse "Sample: no cut in total service spending (t vs t−1)"

*======================================================================================
* 8. ANALYSIS 1: Do cuts in year t raise parcels in year t+1?
*    Outcome: asinh_f1_countparcels
*    Treatments: treat_tse and service specific share cuts
*    Instruments: d_asinh_budgetgap, grantcut_asinh_flipped, d_reserveapr_asinh
*    Estimator: mtefe (normal MTE) + 2SLS robustness
*======================================================================================

*------------------------------------------------------
* 8.1 total service spending cut – MTEFE main
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_tse = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinhTSE_2010_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_mte == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_tse_Z123

cap graph rename CommonSupport CommonSupport_tse, replace
cap graph rename mtePlot       mtePlot_tse,       replace
graph export "$figures/CommonSupport_tse.png", name(CommonSupport_tse) replace width(2400)
graph export "$figures/mtePlot_tse.png",       name(mtePlot_tse)       replace width(2400)

* 8.1.a 2SLS analog for total TSE cut (same instruments and controls)
ivregress 2sls asinh_f1_countparcels ///
    (treat_tse = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_tse_Z123

* Basic placebo: Y_t instead of Y_{t+1}
ivregress 2sls asinh_countparcels_t ///
    (treat_tse = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_tse_placeboYt

* Simple two year lead robustness (Y_{t+2})
ivregress 2sls asinh_f2_countparcels ///
    (treat_tse = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if inrange(year, 2018, 2021) & !missing(asinh_f2_countparcels), ///
    vce(cluster onscode_encode)
estimates store iv_tse_Ytplus2

*------------------------------------------------------
* 8.2 education share cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_education = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_educ_2010_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_mte == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_educ_Z123

cap graph rename CommonSupport CommonSupport_education, replace
cap graph rename mtePlot       mtePlot_education, replace
graph export "$figures/CommonSupport_education.png", name(CommonSupport_education) replace width(2400)
graph export "$figures/mtePlot_education.png",       name(mtePlot_education)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_education = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_educ_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_educ_Z123

* placebo with Y_t
ivregress 2sls asinh_countparcels_t ///
    (treat_education = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_educ_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_educ_placeboYt

*------------------------------------------------------
* 8.3 child social care share cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_childsc = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_childsc_2011_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_mte == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_childsc_Z123

cap graph rename CommonSupport CommonSupport_childsc, replace
cap graph rename mtePlot       mtePlot_childsc, replace
graph export "$figures/CommonSupport_childsc.png", name(CommonSupport_childsc) replace width(2400)
graph export "$figures/mtePlot_childsc.png",       name(mtePlot_childsc)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_childsc = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_childsc_2011_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_childsc_Z123

ivregress 2sls asinh_countparcels_t ///
    (treat_childsc = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_childsc_2011_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_childsc_placeboYt

*------------------------------------------------------
* 8.4 adult social care share cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_adultsc = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_adultsc_2011_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_mte == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_adultsc_Z123

cap graph rename CommonSupport CommonSupport_adultsc, replace
cap graph rename mtePlot       mtePlot_adultsc, replace
graph export "$figures/CommonSupport_adultsc.png", name(CommonSupport_adultsc) replace width(2400)
graph export "$figures/mtePlot_adultsc.png",       name(mtePlot_adultsc)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_adultsc = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_adultsc_2011_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_adultsc_Z123

ivregress 2sls asinh_countparcels_t ///
    (treat_adultsc = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_adultsc_2011_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_adultsc_placeboYt

*------------------------------------------------------
* 8.5 public health share cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_health = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_health_2013_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_mte == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_health_Z123

cap graph rename CommonSupport CommonSupport_health, replace
cap graph rename mtePlot       mtePlot_health, replace
graph export "$figures/CommonSupport_health.png", name(CommonSupport_health) replace width(2400)
graph export "$figures/mtePlot_health.png",       name(mtePlot_health)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_health = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_health_2013_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_health_Z123

ivregress 2sls asinh_countparcels_t ///
    (treat_health = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_health_2013_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_health_placeboYt

*------------------------------------------------------
* 8.6 housing share cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_housing = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_housing_2010_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_mte == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_housing_Z123

cap graph rename CommonSupport CommonSupport_housing, replace
cap graph rename mtePlot       mtePlot_housing, replace
graph export "$figures/CommonSupport_housing.png", name(CommonSupport_housing) replace width(2400)
graph export "$figures/mtePlot_housing.png",       name(mtePlot_housing)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_housing = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_housing_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_housing_Z123

ivregress 2sls asinh_countparcels_t ///
    (treat_housing = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_housing_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store iv_housing_placeboYt

*======================================================================================
* 9. ANALYSIS 2: Among councils with no total cut, does protecting shares matter?
*    Sample: sample_nocut_tse == 1 (no total TSE cut)
*    Treatment: share not cut (Δshare >= 0)
*    Instruments: same as above
*======================================================================================

* Treatment definitions: no cut in share (Δshare >= 0) within no TSE cut sample

capture drop treat_educ_nocut
gen byte treat_educ_nocut = (sharediff_education >= 0) if sharediff_education < .
label var treat_educ_nocut "Treatment: education share not cut (Δshare >= 0)"

capture drop treat_childsc_nocut
gen byte treat_childsc_nocut = (sharediff_childsc >= 0) if sharediff_childsc < .
label var treat_childsc_nocut "Treatment: child SC share not cut (Δshare >= 0)"

capture drop treat_adultsc_nocut
gen byte treat_adultsc_nocut = (sharediff_adultsc >= 0) if sharediff_adultsc < .
label var treat_adultsc_nocut "Treatment: adult SC share not cut (Δshare >= 0)"

capture drop treat_health_nocut
gen byte treat_health_nocut = (sharediff_health >= 0) if sharediff_health < .
label var treat_health_nocut "Treatment: public health share not cut (Δshare >= 0)"

capture drop treat_housing_nocut
gen byte treat_housing_nocut = (sharediff_housing >= 0) if sharediff_housing < .
label var treat_housing_nocut "Treatment: housing share not cut (Δshare >= 0)"

*------------------------------------------------------
* 9.1 education share not cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_educ_nocut = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_educ_2010_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_nocut_tse == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_educnocut_Z123

cap graph rename CommonSupport CommonSupport_educ_nocut, replace
cap graph rename mtePlot       mtePlot_educ_nocut, replace
graph export "$figures/CommonSupport_educ_nocut.png", name(CommonSupport_educ_nocut) replace width(2400)
graph export "$figures/mtePlot_educ_nocut.png",       name(mtePlot_educ_nocut)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_educ_nocut = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_educ_2010_2018 imd2019_score i.year ///
    if sample_nocut_tse == 1, vce(cluster onscode_encode)
estimates store iv_educnocut_Z123

*------------------------------------------------------
* 9.2 child social care share not cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_childsc_nocut = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_childsc_2011_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_nocut_tse == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_childscnocut_Z123

cap graph rename CommonSupport CommonSupport_childsc_nocut, replace
cap graph rename mtePlot       mtePlot_childsc_nocut, replace
graph export "$figures/CommonSupport_childsc_nocut.png", name(CommonSupport_childsc_nocut) replace width(2400)
graph export "$figures/mtePlot_childsc_nocut.png",       name(mtePlot_childsc_nocut)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_childsc_nocut = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_childsc_2011_2018 imd2019_score i.year ///
    if sample_nocut_tse == 1, vce(cluster onscode_encode)
estimates store iv_childscnocut_Z123

*------------------------------------------------------
* 9.3 adult social care share not cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_adultsc_nocut = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_adultsc_2011_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_nocut_tse == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_adultscnocut_Z123

cap graph rename CommonSupport CommonSupport_adultsc_nocut, replace
cap graph rename mtePlot       mtePlot_adultsc_nocut, replace
graph export "$figures/CommonSupport_adultsc_nocut.png", name(CommonSupport_adultsc_nocut) replace width(2400)
graph export "$figures/mtePlot_adultsc_nocut.png",       name(mtePlot_adultsc_nocut)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_adultsc_nocut = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_adultsc_2011_2018 imd2019_score i.year ///
    if sample_nocut_tse == 1, vce(cluster onscode_encode)
estimates store iv_adultscnocut_Z123

*------------------------------------------------------
* 9.4 public health share not cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_health_nocut = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_health_2013_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_nocut_tse == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_healthnocut_Z123

cap graph rename CommonSupport CommonSupport_health_nocut, replace
cap graph rename mtePlot       mtePlot_health_nocut, replace
graph export "$figures/CommonSupport_health_nocut.png", name(CommonSupport_health_nocut) replace width(2400)
graph export "$figures/mtePlot_health_nocut.png",       name(mtePlot_health_nocut)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_health_nocut = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_health_2013_2018 imd2019_score i.year ///
    if sample_nocut_tse == 1, vce(cluster onscode_encode)
estimates store iv_healthnocut_Z123

*------------------------------------------------------
* 9.5 housing share not cut – MTEFE + 2SLS
*------------------------------------------------------
mtefe asinh_f1_countparcels ///
    (treat_housing_nocut = ///
        c.d_asinh_budgetgap ///
        c.grantcut_asinh_flipped ///
        c.d_reserveapr_asinh) ///
    ib3.itl121nm_encode ///
    ln_population ///
    c.rs_ctr_real_pc ///
    c.d_asinh_housing_2010_2018 ///
    c.imd2019_score ///
    i.year ///
    if sample_nocut_tse == 1, ///
    first bootreps(200) vce(cluster onscode_encode)
estimates store mte_housingnocut_Z123

cap graph rename CommonSupport CommonSupport_housing_nocut, replace
cap graph rename mtePlot       mtePlot_housing_nocut, replace
graph export "$figures/CommonSupport_housing_nocut.png", name(CommonSupport_housing_nocut) replace width(2400)
graph export "$figures/mtePlot_housing_nocut.png",       name(mtePlot_housing_nocut)       replace width(2400)

ivregress 2sls asinh_f1_countparcels ///
    (treat_housing_nocut = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinh_housing_2010_2018 imd2019_score i.year ///
    if sample_nocut_tse == 1, vce(cluster onscode_encode)
estimates store iv_housingnocut_Z123

*======================================================================================
* 10. Summary Statistics Table
*======================================================================================

* Table 0: Descriptive statistics for estimation sample
estpost summarize asinh_f1_countparcels treat_tse treat_education ///
    treat_childsc treat_adultsc treat_health treat_housing ///
    d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh ///
    ln_population imd2019_score rs_ctr_real_pc ///
    if sample_mte == 1, detail
esttab using "$tables/table0_summary_stats.tex", ///
    cells("count mean sd min p50 max") replace booktabs label ///
    title("Summary Statistics: Estimation Sample (2018--2022)")

*======================================================================================
* 11. First-stage diagnostics for 2SLS specifications
*======================================================================================

* Re-run baseline 2SLS to extract diagnostics (TSE cut)
quietly ivregress 2sls asinh_f1_countparcels ///
    (treat_tse = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estat firststage
estat endogenous

* Hansen J overidentification test (robust to clustering)
* estat overid is not available with cluster-robust SEs after ivregress;
* use ivregress gmm which natively supports the Hansen J test with clustering.
quietly ivregress gmm asinh_f1_countparcels ///
    (treat_tse = d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, wmatrix(cluster onscode_encode)
estat overid

*======================================================================================
* 12. Export Estimation Tables
*======================================================================================

* Table 1: Analysis 1 – MTE results (6 treatments)
esttab mte_tse_Z123 mte_educ_Z123 mte_childsc_Z123 ///
    mte_adultsc_Z123 mte_health_Z123 mte_housing_Z123 ///
    using "$tables/table1_mte_analysis1.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    title("MTE Estimates: Effect of Spending Cuts on Food Parcels (t+1)") ///
    mtitles("TSE Cut" "Education" "Child SC" "Adult SC" "Health" "Housing")

* Table 2: Analysis 1 – 2SLS results (6 treatments)
esttab iv_tse_Z123 iv_educ_Z123 iv_childsc_Z123 ///
    iv_adultsc_Z123 iv_health_Z123 iv_housing_Z123 ///
    using "$tables/table2_iv_analysis1.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    title("2SLS Estimates: Effect of Spending Cuts on Food Parcels (t+1)") ///
    mtitles("TSE Cut" "Education" "Child SC" "Adult SC" "Health" "Housing")

* Table 3: Placebo tests – Y_t instead of Y_{t+1}
esttab iv_tse_placeboYt iv_educ_placeboYt iv_childsc_placeboYt ///
    iv_adultsc_placeboYt iv_health_placeboYt iv_housing_placeboYt ///
    using "$tables/table3_placebos.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Placebo: 2SLS with Contemporaneous Outcome (Y\$_t\$)") ///
    mtitles("TSE Cut" "Education" "Child SC" "Adult SC" "Health" "Housing")

* Table 4: Analysis 2 – MTE with no-cut sample (5 service shares)
esttab mte_educnocut_Z123 mte_childscnocut_Z123 mte_adultscnocut_Z123 ///
    mte_healthnocut_Z123 mte_housingnocut_Z123 ///
    using "$tables/table4_mte_analysis2.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    title("MTE Estimates: Share Protection Among Non-Cutters") ///
    mtitles("Education" "Child SC" "Adult SC" "Health" "Housing")

* Table 5: Analysis 2 – 2SLS with no-cut sample (5 service shares)
esttab iv_educnocut_Z123 iv_childscnocut_Z123 iv_adultscnocut_Z123 ///
    iv_healthnocut_Z123 iv_housingnocut_Z123 ///
    using "$tables/table5_iv_analysis2.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    title("2SLS Estimates: Share Protection Among Non-Cutters") ///
    mtitles("Education" "Child SC" "Adult SC" "Health" "Housing")

*======================================================================================
* 13. Balance table: covariate means by treatment status
*======================================================================================

* Balance table for TSE cut (main treatment)
preserve
keep if sample_mte == 1

* Treated group means
estpost summarize ln_population imd2019_score rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 d_asinh_budgetgap grantcut_asinh_flipped ///
    d_reserveapr_asinh ///
    if treat_tse == 1
estimates store bal_treated

* Control group means
estpost summarize ln_population imd2019_score rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 d_asinh_budgetgap grantcut_asinh_flipped ///
    d_reserveapr_asinh ///
    if treat_tse == 0
estimates store bal_control

esttab bal_treated bal_control using "$tables/tableA1_balance.tex", ///
    cells("mean(fmt(3)) sd(fmt(3))") replace booktabs label ///
    mtitles("Cut (D=1)" "No Cut (D=0)") ///
    title("Balance Table: Covariates by TSE Cut Status")

restore

*======================================================================================
* 14. Reduced-form estimates: instruments → outcome (no treatment)
*======================================================================================

* Reduced form: direct effect of instruments on food parcels
regress asinh_f1_countparcels ///
    d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store rf_tse

esttab rf_tse using "$tables/tableA2_reduced_form.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    title("Reduced Form: Instruments on asinh(Food Parcels, t+1)")

*======================================================================================
* 15. First-stage estimates table
*======================================================================================

* First stage: instruments → treatment
regress treat_tse ///
    d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh ///
    ib3.itl121nm_encode ln_population c.rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 imd2019_score i.year ///
    if sample_mte == 1, vce(cluster onscode_encode)
estimates store fs_tse

* Joint F-test on excluded instruments
test d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh
local fs_F = r(F)
local fs_p = r(p)
di as txt "First-stage F-statistic = " %6.2f `fs_F' " (p = " %6.4f `fs_p' ")"

esttab fs_tse using "$tables/tableA3_first_stage.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(d_asinh_budgetgap grantcut_asinh_flipped d_reserveapr_asinh) ///
    title("First Stage: Instruments on TSE Cut Indicator") ///
    addnotes("Joint F-statistic on excluded instruments: `=string(`fs_F',"%6.2f")' (p = `=string(`fs_p',"%6.4f")')")

*======================================================================================
* 16. Sample flow documentation
*======================================================================================

di as txt _n "=========================================="
di as txt "SAMPLE FLOW"
di as txt "=========================================="
count
di as txt "Full panel (2010-2023):               " r(N)
count if inrange(year, 2018, 2022)
di as txt "Estimation window (2018-2022):         " r(N)
count if sample_mte == 1
di as txt "Main estimation sample:                " r(N)
count if sample_mte == 1 & !missing(d_asinh_budgetgap) & !missing(grantcut_asinh_flipped) & !missing(d_reserveapr_asinh)
di as txt "With all 3 instruments non-missing:    " r(N)
count if sample_nocut_tse == 1
di as txt "No-cut subsample (Analysis 2):         " r(N)
di as txt "=========================================="

*======================================================================================
* 17. Save updated panel and close log
*======================================================================================

save "$proc/PANEL_2007_2023_harmonized_processed_v3.dta", replace

log close
