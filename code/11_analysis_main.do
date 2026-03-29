/*******************************************************************************
 11_analysis_main.do
 Project : Local Authority Austerity and Food Bank Demand
 Author  : Kevin Kim
 Purpose : AER-style main analysis — continuous austerity, FE and IV

 Main design
   - Treatment: continuous aggregate austerity
       A_it = -[asinh(TSE_pc_it) - asinh(TSE_pc_i,t-1)]
   - Outcome:
       Y_i,t+1 = asinh(Trussell parcels_i,t+1)
   - Main estimators: FE (xtreg) and 2SLS (ivreghdfe)
   - Preferred instrument:
       Z1 = change in asinh budget gap since 2018
   - Additional instruments (robustness only):
       Z2 = change in asinh reserves since 2018
       Z3 = grant cut since 2018

 Notes
   - Main text: FE + IV with Z1
   - Z1+Z2 and Z1+Z2+Z3 are robustness checks
   - Binary treatment and service-level analyses are appendix material
   - Unit FE absorbed via absorb() in ivreghdfe (Correia 2019)
   - Time-invariant controls (imd2019_score, d_asinhTSE_2010_2018)
     excluded from FE/IV specs; retained for pooled and balance table

 Revision log
   - 29 Mar 2026: Switched from ivreg2+partial() to ivreghdfe+absorb()
                   to resolve degenerate cluster-robust VCE.
                   Removed time-invariant controls from FE/IV regressors.
                   Added AER table notes. Added first-stage table export.
                   Added t-test to balance table. Fixed p50 in summary stats.
                   Documented singleton cluster drops.
*******************************************************************************/

version 18.0
clear all
set more off
pause off
set seed 20251016

*===============================================================================
* 0. Log file (paths inherited from _master.do)
*===============================================================================
capture log close
log using "$logs/log_analysis_main.log", replace text

*===============================================================================
* 1. Load source panel and declare panel structure
*===============================================================================
use "$proc/PANEL_2007_2023_harmonized_processed_v2.dta", clear

capture drop onscode_encode
capture drop itl121nm_encode
encode onscode,  gen(onscode_encode)
encode itl121nm, gen(itl121nm_encode)

xtset onscode_encode year
keep if inrange(year, 2010, 2023)

*===============================================================================
* 2. Outcomes
*===============================================================================

* Main outcome: next-year parcels
capture drop f1_countparcels
gen double f1_countparcels = F.countparcels
replace f1_countparcels = . if !inrange(year, 2018, 2022)

capture drop asinh_f1_countparcels
gen double asinh_f1_countparcels = asinh(f1_countparcels)
label var asinh_f1_countparcels "asinh food parcels in t+1"

* Placebo: contemporaneous outcome
capture drop asinh_countparcels_t
gen double asinh_countparcels_t = asinh(countparcels) if inrange(year, 2018, 2022)
label var asinh_countparcels_t "asinh food parcels in t"

* Timing robustness: two-year lead
capture drop f2_countparcels
gen double f2_countparcels = F2.countparcels
replace f2_countparcels = . if !inrange(year, 2018, 2021)

capture drop asinh_f2_countparcels
gen double asinh_f2_countparcels = asinh(f2_countparcels)
label var asinh_f2_countparcels "asinh food parcels in t+2"

* Functional form robustness: ln(1 + Y)
capture drop ln1_f1_countparcels
gen double ln1_f1_countparcels = ln(f1_countparcels + 1) if f1_countparcels < .
label var ln1_f1_countparcels "ln(1 + food parcels in t+1)"

*===============================================================================
* 3. Core controls
*===============================================================================
capture drop ln_population
gen double ln_population = ln(population) if population > 0
label var ln_population "log population"

capture drop imd2019_score
bysort onscode_encode: egen double imd2019_score = max(cond(year == 2019, imdaveragescore, .))

capture drop imd_any
bysort onscode_encode: egen double imd_any = max(imdaveragescore)
replace imd2019_score = imd_any if missing(imd2019_score)
drop imd_any
label var imd2019_score "IMD 2019 average score"

label var rs_ctr_real_pc "Council tax requirement per capita, real"

*===============================================================================
* 4. Main treatment: continuous aggregate austerity
*    A_it = -[asinh(TSE_pc_it) - asinh(TSE_pc_i,t-1)]
*===============================================================================
capture drop asinh_tse_pc
gen double asinh_tse_pc = asinh(rs_tse_real_pc) if rs_tse_real_pc < .
label var asinh_tse_pc "asinh total service expenditure per capita"

capture drop d_asinh_tse_pc
gen double d_asinh_tse_pc = asinh_tse_pc - L.asinh_tse_pc ///
    if asinh_tse_pc < . & L.asinh_tse_pc < .
label var d_asinh_tse_pc "Change in asinh TSE per capita"

capture drop austerity_tse
gen double austerity_tse = -d_asinh_tse_pc if d_asinh_tse_pc < .
label var austerity_tse "Aggregate austerity intensity"

* Log version for functional form robustness
capture drop ln_tse_pc
gen double ln_tse_pc = ln(rs_tse_real_pc) if rs_tse_real_pc > 0

capture drop d_ln_tse_pc
gen double d_ln_tse_pc = ln_tse_pc - L.ln_tse_pc ///
    if ln_tse_pc < . & L.ln_tse_pc < .

capture drop austerity_tse_ln
gen double austerity_tse_ln = -d_ln_tse_pc if d_ln_tse_pc < .
label var austerity_tse_ln "Aggregate austerity intensity, log version"

* Binary cut indicator (appendix comparison only)
capture drop treat_tse
gen byte treat_tse = (d_asinh_tse_pc < 0) if d_asinh_tse_pc < .
label var treat_tse "Indicator for total spending cut"

*===============================================================================
* 5. Instruments
*===============================================================================

* Z1: budget gap relative to 2018
capture drop budgetgap_tse_real_pc
gen double budgetgap_tse_real_pc = ra_tse_real_pc - rs_tse_real_pc ///
    if ra_tse_real_pc < . & rs_tse_real_pc < .
label var budgetgap_tse_real_pc "Budget gap per capita, RA minus RS"

capture drop asinh_budgetgap_t
gen double asinh_budgetgap_t = asinh(budgetgap_tse_real_pc) if budgetgap_tse_real_pc < .

capture drop asinh_budgetgap_2018
gen double asinh_budgetgap_2018 = asinh_budgetgap_t if year == 2018

capture drop base2018_asinh_budgetgap
bysort onscode_encode: egen double base2018_asinh_budgetgap = max(asinh_budgetgap_2018)

capture drop d_asinh_budgetgap
gen double d_asinh_budgetgap = asinh_budgetgap_t - base2018_asinh_budgetgap ///
    if asinh_budgetgap_t < . & base2018_asinh_budgetgap < .
label var d_asinh_budgetgap "Change in asinh budget gap since 2018 (Z1)"

drop asinh_budgetgap_2018                             /* intermediate; no longer needed */

* Z2: reserves relative to 2018
capture drop reserveapr_pc_2018
gen double reserveapr_pc_2018 = rs_reserveapr_real_pc if year == 2018

capture drop base2018_reserveapr_pc
bysort onscode_encode: egen double base2018_reserveapr_pc = max(reserveapr_pc_2018)

capture drop d_reserveapr_asinh
gen double d_reserveapr_asinh = asinh(rs_reserveapr_real_pc) - asinh(base2018_reserveapr_pc) ///
    if rs_reserveapr_real_pc < . & base2018_reserveapr_pc < .
label var d_reserveapr_asinh "Change in asinh reserves since 2018 (Z2)"

drop reserveapr_pc_2018                               /* intermediate; no longer needed */

* Z3: grant cut since 2018
capture drop totgrant_pc
gen double totgrant_pc = rs_grant_rsg_real_pc + rs_grant_inaef_real_pc ///
    if rs_grant_rsg_real_pc < . & rs_grant_inaef_real_pc < .
label var totgrant_pc "Total grants per capita, real"

capture drop asinh_totgrant
gen double asinh_totgrant = asinh(totgrant_pc) if totgrant_pc < .

capture drop asinh_totgrant_2018
gen double asinh_totgrant_2018 = asinh_totgrant if year == 2018

capture drop base2018_asinh_grant
bysort onscode_encode: egen double base2018_asinh_grant = max(asinh_totgrant_2018)

capture drop d_asinh_grant
gen double d_asinh_grant = asinh_totgrant - base2018_asinh_grant ///
    if asinh_totgrant < . & base2018_asinh_grant < .

capture drop grantcut_asinh_flipped
gen double grantcut_asinh_flipped = -d_asinh_grant if d_asinh_grant < .
label var grantcut_asinh_flipped "Grant cut since 2018, flipped (Z3)"

drop asinh_totgrant_2018                              /* intermediate; no longer needed */

*===============================================================================
* 6. Pre-2018 long-run squeeze control
*    NOTE: This variable is TIME-INVARIANT within a LAD.
*    It is used only in the balance table and descriptive stats.
*    It is excluded from FE and IV-FE specifications to avoid
*    automatic omission due to collinearity with unit FE.
*===============================================================================
capture drop TSE2010
capture drop TSE2018
bysort onscode_encode: egen double TSE2010 = max(cond(year == 2010, rs_tse_real_pc, .))
bysort onscode_encode: egen double TSE2018 = max(cond(year == 2018, rs_tse_real_pc, .))

capture drop d_asinhTSE_2010_2018
gen double d_asinhTSE_2010_2018 = asinh(TSE2018) - asinh(TSE2010) ///
    if TSE2018 > 0 & TSE2010 > 0
label var d_asinhTSE_2010_2018 "Change in asinh TSE per capita, 2010 to 2018"

drop TSE2010 TSE2018                                  /* intermediate; no longer needed */

*===============================================================================
* 7. Service-share variables (appendix only)
*===============================================================================

capture drop share_education d_share_education
gen double share_education = rs_education_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_education_real_pc < .
gen double d_share_education = share_education - L.share_education ///
    if share_education < . & L.share_education < .

capture drop share_childsc d_share_childsc
gen double share_childsc = rs_childSC_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_childSC_real_pc < .
gen double d_share_childsc = share_childsc - L.share_childsc ///
    if share_childsc < . & L.share_childsc < .

capture drop share_adultsc d_share_adultsc
gen double share_adultsc = rs_adultSC_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_adultSC_real_pc < .
gen double d_share_adultsc = share_adultsc - L.share_adultsc ///
    if share_adultsc < . & L.share_adultsc < .

capture drop share_health d_share_health
gen double share_health = rs_health_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_health_real_pc < .
gen double d_share_health = share_health - L.share_health ///
    if share_health < . & L.share_health < .

capture drop share_housing d_share_housing
gen double share_housing = rs_housing_real_pc / rs_tse_real_pc ///
    if rs_tse_real_pc > 0 & rs_housing_real_pc < .
gen double d_share_housing = share_housing - L.share_housing ///
    if share_housing < . & L.share_housing < .

*===============================================================================
* 8. Estimation samples
*===============================================================================
capture drop sample_main
gen byte sample_main = inrange(year, 2018, 2022) ///
    & !missing(asinh_f1_countparcels, austerity_tse, d_asinh_budgetgap, ln_population)
label var sample_main "Main estimation sample"

capture drop sample_no_covid
gen byte sample_no_covid = sample_main == 1 & !inlist(year, 2020, 2021)
label var sample_no_covid "Main sample excluding 2020 and 2021"

*===============================================================================
* 9. Sample flow and singleton documentation
*===============================================================================
di as txt _n "=========================================="
di as txt "SAMPLE FLOW"
di as txt "=========================================="
count
di as txt "Full panel, 2010 to 2023:              " r(N)
count if inrange(year, 2018, 2022)
di as txt "Years 2018 to 2022:                    " r(N)
count if sample_main == 1
di as txt "Main estimation sample:                " r(N)

* Document singleton clusters for AER transparency
* Singletons = LADs observed in only 1 year within estimation window
* These are automatically dropped by FE estimators (xtreg, reghdfe, ivreghdfe)
tempvar nyears
bysort onscode_encode: egen `nyears' = total(sample_main) if sample_main == 1
count if sample_main == 1 & `nyears' == 1
local n_singleton = r(N)
count if sample_main == 1 & `nyears' > 1
local n_effective = r(N)
di as txt "Singleton cluster observations:         " `n_singleton'
di as txt "Effective N after singleton drops:      " `n_effective'

count if sample_main == 1 & !missing(d_asinh_budgetgap)
di as txt "Main sample with Z1 observed:          " r(N)
count if sample_main == 1 & !missing(d_asinh_budgetgap, d_reserveapr_asinh)
di as txt "Main sample with Z1 and Z2 observed:   " r(N)
count if sample_main == 1 & !missing(d_asinh_budgetgap, d_reserveapr_asinh, grantcut_asinh_flipped)
di as txt "Main sample with Z1, Z2, Z3 observed:  " r(N)
count if sample_no_covid == 1
di as txt "Main sample excluding 2020 and 2021:   " r(N)
di as txt "=========================================="

*===============================================================================
* 10. Descriptive statistics (Table 1)
*===============================================================================

* Use estpost summarize with ,detail to compute percentiles
estpost summarize ///
    asinh_f1_countparcels ///
    austerity_tse ///
    austerity_tse_ln ///
    d_asinh_budgetgap ///
    d_reserveapr_asinh ///
    grantcut_asinh_flipped ///
    ln_population ///
    imd2019_score ///
    rs_ctr_real_pc ///
    if sample_main == 1, detail

esttab using "$tables/table1_summary_stats_main.tex", ///
    replace booktabs label ///
    cells("count mean sd min p50 max") ///
    title("Summary Statistics for Main Estimation Sample") ///
    addnotes( ///
        "Sample: 229 English local authorities, 2018--2022." ///
        "Austerity intensity: $A_{it} = -[\text{asinh}(\text{TSE}_{it}) - \text{asinh}(\text{TSE}_{i,t-1})]$." ///
        "Positive values indicate spending cuts." ///
    )

*===============================================================================
* 11. Figures
*===============================================================================

* Figure 1. Time-series of food parcels and austerity
preserve
    keep if inrange(year, 2018, 2022)
    collapse ///
        (mean) mean_parcels = countparcels ///
        (mean) mean_austerity = austerity_tse ///
        (mean) mean_gap = d_asinh_budgetgap, by(year)

    twoway ///
        (line mean_parcels year, yaxis(1)) ///
        (line mean_austerity year, yaxis(2)), ///
        title("Food Parcels and Aggregate Austerity Over Time") ///
        xtitle("Year") ///
        ytitle("Mean food parcels", axis(1)) ///
        ytitle("Mean aggregate austerity", axis(2)) ///
        legend(order(1 "Food parcels" 2 "Aggregate austerity"))
    graph export "$figures/fig1_parcels_austerity_timeseries.png", replace
restore

* Figure 2. First-stage scatter: Z1 vs treatment
preserve
    keep if sample_main == 1
    twoway ///
        (scatter austerity_tse d_asinh_budgetgap, msize(vsmall)) ///
        (lfit austerity_tse d_asinh_budgetgap), ///
        title("Budget Gap and Aggregate Austerity") ///
        xtitle("Change in asinh budget gap since 2018") ///
        ytitle("Aggregate austerity intensity")
    graph export "$figures/fig2_firststage_scatter.png", replace
restore

* Figure 3. Outcome distribution
preserve
    keep if sample_main == 1
    histogram asinh_f1_countparcels, fraction ///
        title("Distribution of Main Outcome") ///
        xtitle("asinh food parcels in t+1") ///
        ytitle("Fraction")
    graph export "$figures/fig3_hist_outcome.png", replace
restore

*===============================================================================
* 12. Main text analysis: Fixed Effects (Table 2, cols 1-2)
*     NOTE: Time-invariant controls (imd2019_score, d_asinhTSE_2010_2018)
*     are excluded because they are perfectly collinear with unit FE.
*===============================================================================

* FE with asinh treatment
xtreg asinh_f1_countparcels ///
    austerity_tse ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_main_asinh

* FE with log treatment
xtreg asinh_f1_countparcels ///
    austerity_tse_ln ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_main_log

*===============================================================================
* 13. Main text analysis: Reduced Form (Table 2, cols 3-4)
*===============================================================================

* Reduced form with Z1 only
xtreg asinh_f1_countparcels ///
    d_asinh_budgetgap ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store rf_z1

* Reduced form with all three instruments
xtreg asinh_f1_countparcels ///
    d_asinh_budgetgap ///
    d_reserveapr_asinh ///
    grantcut_asinh_flipped ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store rf_z123

*===============================================================================
* 14. Main text analysis: IV (Table 3)
*     Using ivreghdfe (Correia 2019) with absorb() for unit and year FE.
*     This avoids the degenerate cluster-robust VCE that arises when
*     ivreg2+partial() demeans out ~227 unit dummies with only 229 clusters.
*     Time-invariant controls excluded (absorbed by unit FE).
*===============================================================================

* Preferred specification: Z1 only (just identified)
ivreghdfe asinh_f1_countparcels ///
    (austerity_tse = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store iv_main_z1

* Robustness: Z1 + Z2 (overidentified — Hansen J available)
ivreghdfe asinh_f1_countparcels ///
    (austerity_tse = d_asinh_budgetgap d_reserveapr_asinh) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store iv_main_z12

* Robustness: Z1 + Z2 + Z3 (overidentified — Hansen J available)
ivreghdfe asinh_f1_countparcels ///
    (austerity_tse = d_asinh_budgetgap d_reserveapr_asinh grantcut_asinh_flipped) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store iv_main_z123

* Functional form robustness: log treatment with Z1
ivreghdfe asinh_f1_countparcels ///
    (austerity_tse_ln = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store iv_main_log_z1

* Appendix comparison: binary cut with Z1
ivreghdfe asinh_f1_countparcels ///
    (treat_tse = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store iv_binary_z1

*===============================================================================
* 14b. First-stage regressions (Table A4)
*      Explicit first-stage estimation for export.
*      These replicate the first stage of the preferred IV spec and
*      each instrument set, using reghdfe for consistency with ivreghdfe.
*===============================================================================

* First stage: Z1 only (preferred)
reghdfe austerity_tse ///
    d_asinh_budgetgap ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode)
estimates store fs_z1

* First stage: Z1 + Z2
reghdfe austerity_tse ///
    d_asinh_budgetgap ///
    d_reserveapr_asinh ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode)
estimates store fs_z12

* First stage: Z1 + Z2 + Z3
reghdfe austerity_tse ///
    d_asinh_budgetgap ///
    d_reserveapr_asinh ///
    grantcut_asinh_flipped ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode)
estimates store fs_z123

* First stage for binary treatment
reghdfe treat_tse ///
    d_asinh_budgetgap ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode)
estimates store fs_binary_z1

*===============================================================================
* 15. Robustness checks (Table 4)
*===============================================================================

* Placebo: contemporaneous outcome (Y_t, not Y_{t+1})
ivreghdfe asinh_countparcels_t ///
    (austerity_tse = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store placebo_y_t

* Two-year lead (Y_{t+2})
ivreghdfe asinh_f2_countparcels ///
    (austerity_tse = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if inrange(year, 2018, 2021) ///
    & !missing(asinh_f2_countparcels, austerity_tse, d_asinh_budgetgap, ln_population), ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store lead2_y

* Excluding COVID years (2020-2021)
ivreghdfe asinh_f1_countparcels ///
    (austerity_tse = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_no_covid == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store nocovid_iv

* ln(1+Y) outcome transformation
ivreghdfe ln1_f1_countparcels ///
    (austerity_tse = d_asinh_budgetgap) ///
    ln_population ///
    c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode) first savefirst
estimates store ln1_outcome_iv

*===============================================================================
* 16. Appendix: Service-level FE (Table A3)
*     NOTE: Time-invariant long-run service controls and imd2019_score
*     are excluded (collinear with unit FE).
*===============================================================================

xtreg asinh_f1_countparcels ///
    d_share_education ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_educ

xtreg asinh_f1_countparcels ///
    d_share_childsc ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_childsc

xtreg asinh_f1_countparcels ///
    d_share_adultsc ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_adultsc

xtreg asinh_f1_countparcels ///
    d_share_health ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_health

xtreg asinh_f1_countparcels ///
    d_share_housing ///
    ln_population ///
    c.rs_ctr_real_pc ///
    i.year ///
    if sample_main == 1, fe vce(cluster onscode_encode)
estimates store fe_housing

*===============================================================================
* 17. Balance table (Table A1)
*     Using estpost ttest to produce mean differences and t-statistics.
*===============================================================================

* Panel A: Separate group means (for display)
estpost summarize ///
    ln_population imd2019_score rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 d_asinh_budgetgap d_reserveapr_asinh ///
    grantcut_asinh_flipped ///
    if sample_main == 1 & treat_tse == 1, detail
estimates store bal_treated

estpost summarize ///
    ln_population imd2019_score rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 d_asinh_budgetgap d_reserveapr_asinh ///
    grantcut_asinh_flipped ///
    if sample_main == 1 & treat_tse == 0, detail
estimates store bal_control

* Panel B: Formal two-sample t-tests
estpost ttest ///
    ln_population imd2019_score rs_ctr_real_pc ///
    d_asinhTSE_2010_2018 d_asinh_budgetgap d_reserveapr_asinh ///
    grantcut_asinh_flipped ///
    if sample_main == 1, by(treat_tse)
estimates store bal_ttest

* Export balance table with group means and t-test
esttab bal_treated bal_control bal_ttest ///
    using "$tables/tableA1_balance.tex", ///
    replace booktabs label ///
    cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0) fmt(3)) b(pattern(0 0 1) fmt(3)) t(pattern(0 0 1) fmt(2))") ///
    mtitles("Cut" "No cut" "Difference") ///
    title("Balance Table by Total Spending Cut Status") ///
    addnotes( ///
        "Cut: LADs with $\Delta\text{asinh}(\text{TSE}_{pc}) < 0$ in a given year." ///
        "Difference column reports mean(Cut) $-$ mean(No cut) with t-statistics." ///
        "Standard errors not adjusted for clustering." ///
    )

*===============================================================================
* 18. Export tables
*===============================================================================

* --- Table 2: FE and Reduced Form ---
esttab fe_main_asinh fe_main_log rf_z1 rf_z123 ///
    using "$tables/table2_fe_reducedform_main.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(austerity_tse austerity_tse_ln d_asinh_budgetgap d_reserveapr_asinh grantcut_asinh_flipped) ///
    order(austerity_tse austerity_tse_ln d_asinh_budgetgap d_reserveapr_asinh grantcut_asinh_flipped) ///
    stats(N r2_w, fmt(0 3) labels("Observations" "Within R-squared")) ///
    mtitles("FE (asinh)" "FE (log)" "RF: Z1" "RF: Z1+Z2+Z3") ///
    title("Fixed Effects and Reduced Form Estimates") ///
    addnotes( ///
        "Dependent variable: asinh(food parcels in $t+1$)." ///
        "Sample: English LADs, 2018--2022." ///
        "All specifications include LAD and year fixed effects." ///
        "Standard errors clustered at the LAD level in parentheses." ///
        "Singleton clusters (LADs observed in only one year) are dropped." ///
        "* p$<$0.10, ** p$<$0.05, *** p$<$0.01." ///
    )

* --- Table 3: IV ---
esttab iv_main_z1 iv_main_z12 iv_main_z123 iv_main_log_z1 ///
    using "$tables/table3_iv_main.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(austerity_tse austerity_tse_ln) ///
    order(austerity_tse austerity_tse_ln) ///
    stats(N widstat jp, fmt(0 2 3) labels("Observations" "Kleibergen-Paap F" "Hansen J p-value")) ///
    mtitles("Z1 only" "Z1+Z2" "Z1+Z2+Z3" "Log treatment, Z1") ///
    title("IV Estimates for Aggregate Austerity") ///
    addnotes( ///
        "Dependent variable: asinh(food parcels in $t+1$)." ///
        "Estimated by 2SLS using \texttt{ivreghdfe} (Correia 2019)." ///
        "LAD and year fixed effects absorbed via iterative demeaning." ///
        "Standard errors clustered at the LAD level in parentheses." ///
        "Z1: change in asinh budget gap since 2018." ///
        "Z2: change in asinh reserves since 2018." ///
        "Z3: grant cut since 2018 (sign-flipped)." ///
        "Stock-Yogo 10\% critical value: 16.38 (1 inst.), 19.93 (2 inst.), 22.30 (3 inst.)." ///
        "* p$<$0.10, ** p$<$0.05, *** p$<$0.01." ///
    )

* --- Table 4: Robustness ---
esttab placebo_y_t lead2_y nocovid_iv ln1_outcome_iv ///
    using "$tables/table4_robustness_main.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(austerity_tse) ///
    stats(N widstat, fmt(0 2) labels("Observations" "Kleibergen-Paap F")) ///
    mtitles("Placebo Y_t" "Lead Y_{t+2}" "Exclude 2020-21" "ln(1+Y)") ///
    title("Robustness Checks") ///
    addnotes( ///
        "All specifications estimated by 2SLS with Z1 (budget gap) as instrument." ///
        "LAD and year fixed effects absorbed via \texttt{ivreghdfe}." ///
        "Standard errors clustered at the LAD level in parentheses." ///
        "Col 1: placebo with contemporaneous $Y_t$. Col 2: two-year lead $Y_{t+2}$." ///
        "Col 3: excludes 2020--2021 (COVID years). Col 4: $\ln(1 + Y_{t+1})$ outcome." ///
        "* p$<$0.10, ** p$<$0.05, *** p$<$0.01." ///
    )

* --- Table A2: Binary IV comparison ---
esttab iv_binary_z1 using "$tables/tableA2_binary_iv.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat_tse) ///
    stats(N widstat, fmt(0 2) labels("Observations" "Kleibergen-Paap F")) ///
    title("Appendix: Binary-Cut IV Comparison") ///
    addnotes( ///
        "Dependent variable: asinh(food parcels in $t+1$)." ///
        "Treatment: indicator for total spending cut ($\Delta\text{asinh}(\text{TSE}_{pc}) < 0$)." ///
        "Instrument: Z1 (change in asinh budget gap since 2018)." ///
        "LAD and year fixed effects absorbed via \texttt{ivreghdfe}." ///
        "Standard errors clustered at the LAD level in parentheses." ///
        "* p$<$0.10, ** p$<$0.05, *** p$<$0.01." ///
    )

* --- Table A3: Service-level FE ---
esttab fe_educ fe_childsc fe_adultsc fe_health fe_housing ///
    using "$tables/tableA3_servicelevel_fe.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(d_share_education d_share_childsc d_share_adultsc d_share_health d_share_housing) ///
    stats(N r2_w, fmt(0 3) labels("Observations" "Within R-squared")) ///
    mtitles("Education" "Child SC" "Adult SC" "Public Health" "Housing") ///
    title("Appendix: Service-Share Changes and Next-Year Food Parcels") ///
    addnotes( ///
        "Dependent variable: asinh(food parcels in $t+1$)." ///
        "Treatment: year-on-year change in service share of TSE." ///
        "All specifications include LAD and year fixed effects." ///
        "Standard errors clustered at the LAD level in parentheses." ///
        "* p$<$0.10, ** p$<$0.05, *** p$<$0.01." ///
    )

* --- Table A4: First-stage regressions ---
esttab fs_z1 fs_z12 fs_z123 fs_binary_z1 ///
    using "$tables/tableA4_firststage.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(d_asinh_budgetgap d_reserveapr_asinh grantcut_asinh_flipped) ///
    order(d_asinh_budgetgap d_reserveapr_asinh grantcut_asinh_flipped) ///
    stats(N r2_a F, fmt(0 3 2) labels("Observations" "Adjusted R-squared" "F-statistic")) ///
    mtitles("Continuous: Z1" "Continuous: Z1+Z2" "Continuous: Z1+Z2+Z3" "Binary: Z1") ///
    title("Appendix: First-Stage Regressions") ///
    addnotes( ///
        "Dependent variable: austerity intensity (cols 1--3) or spending-cut indicator (col 4)." ///
        "LAD and year fixed effects absorbed via \texttt{reghdfe}." ///
        "Standard errors clustered at the LAD level in parentheses." ///
        "Z1: change in asinh budget gap since 2018." ///
        "Z2: change in asinh reserves since 2018." ///
        "Z3: grant cut since 2018 (sign-flipped)." ///
        "* p$<$0.10, ** p$<$0.05, *** p$<$0.01." ///
    )

*===============================================================================
* 19. Save analysis-ready panel
*===============================================================================
save "$proc/PANEL_2007_2023_harmonized_processed_v3_clean.dta", replace

log close
