# Results Interpretation and Code Review: 11_analysis_main.do

**Project:** Local Authority Austerity and Food Bank Demand
**Author:** Kevin Kim
**Date:** 29 March 2026
**Reviewed by:** Research Assistant

---

## Part I. Results Interpretation

### 1. Sample

The estimation panel covers 229 English local authorities observed over 2018–2022 (5 years), yielding a main estimation sample of N = 1,106 LAD-year observations (unbalanced; average 4.8 years per LAD). All three instruments (Z1, Z2, Z3) are observed for the full sample. Excluding the COVID years 2020–2021 reduces the sample to N = 672.

The sample loss from the full 2018–2022 window (1,777 LAD-years) to the estimation sample (1,121) reflects missing values in the food-parcel outcome, austerity treatment, budget-gap instrument, or population. This is a 37% attrition rate that should be documented as a potential source of selection.

### 2. Descriptive Statistics (Table 1)

The mean of asinh(food parcels in t+1) is 9.21 (SD = 1.20), with a range of 0.88 to 11.89, indicating substantial cross-sectional dispersion even after the asinh transformation. Mean austerity intensity is approximately zero (−0.004, SD = 0.080), meaning that on average TSE per capita was roughly flat over the sample period, but with considerable cross-sectional variation. The preferred instrument Z1 (change in asinh budget gap) has mean −0.049 (SD = 0.156), indicating that on average budget gaps widened slightly relative to 2018. IMD 2019 scores average 19.8 (SD = 8.2), providing reasonable cross-sectional variation in deprivation.

### 3. Fixed Effects Results (Table 2, Columns 1–2)

Both FE specifications yield a null result for austerity:

| Specification | Coefficient | SE | t | p |
|---|---|---|---|---|
| FE, asinh treatment | −0.033 | 0.162 | −0.20 | 0.838 |
| FE, log treatment | 0.092 | 0.116 | 0.79 | 0.429 |

Within R-squared is approximately 0.307 in both cases. Nearly all the within-unit variation in food parcels is absorbed by year fixed effects: the year dummies for 2019–2022 are all large and highly significant (e.g., the 2022 coefficient is 0.706, SE = 0.058, t = 12.12), indicating a strong common upward trend in food bank usage across all LADs.

**Critical collinearity note.** The controls `d_asinhTSE_2010_2018` (long-run squeeze) and `imd2019_score` (deprivation) are both omitted due to collinearity with the unit fixed effects. This is expected—both variables are time-invariant within a LAD and are therefore perfectly absorbed by the LAD dummies. They should be removed from the FE regressor list (they contribute nothing and clutter the output) but can remain in cross-sectional or pooled specifications if those are ever estimated.

**Interpretation.** The FE estimates are consistent under the assumption of strict exogeneity (E[ε_it | A_i1, ..., A_iT, X_i] = 0). The point estimates are economically small and statistically indistinguishable from zero. However, FE does not address the endogeneity of local spending decisions—reverse causality (rising food insecurity may trigger emergency spending) or omitted time-varying confounders (local economic shocks) could bias the FE estimate in either direction.

### 4. Reduced Form (Table 2, Columns 3–4)

The reduced form—regressing the outcome directly on the instruments—is a critical diagnostic. Under valid instruments, if austerity truly affects food parcels, the instruments should predict the outcome.

| Specification | Z1 coeff | SE | p |
|---|---|---|---|
| RF with Z1 only | −0.006 | 0.082 | 0.947 |
| RF with Z1+Z2+Z3 | −0.014 (Z1), 0.219 (Z2), −0.137 (Z3) | — | all p > 0.7 |

**The reduced form is flat.** None of the instruments has any detectable association with food parcel outcomes. This is an extremely important result because it places an upper bound on the IV-estimable causal effect: even if the instruments were strong, the implied effect would be near zero. A null reduced form combined with a weak first stage implies that the IV strategy simply cannot identify an effect here—the data lack the statistical power, the instrument lacks relevance, or the true effect is zero.

### 5. IV Estimates (Table 3)

| Specification | 2SLS coeff | SE | p | KP F |
|---|---|---|---|---|
| Z1 only (preferred) | −0.050 | 0.742 | 0.946 | 2.61 |
| Z1 + Z2 | −0.149 | 0.615 | 0.809 | 1.63 |
| Z1 + Z2 + Z3 | 0.067 | 0.529 | 0.900 | 1.81 |
| Log treatment, Z1 | −0.066 | 0.778 | 0.932 | 2.69 |

**This is a severe weak-instrument problem.** The Kleibergen-Paap F-statistics range from 1.6 to 2.7, far below the Stock-Yogo 10% maximal IV size critical value of 16.38 (for one instrument) or 19.93/22.30 (for two/three instruments). By conventional standards (Staiger and Stock 1997; Stock and Yogo 2005), an F-statistic below 10 indicates that IV inference is unreliable. Here the F-statistics are below 3.

The second-stage coefficient estimates swing between −0.15 and +0.07 across specifications, with standard errors exceeding 0.5 in all cases. The 95% confidence intervals span from roughly −1.5 to +1.4, which is uninformative. Point estimates are not meaningfully interpretable under weak instruments because the 2SLS estimator is biased toward OLS and confidence intervals based on Wald statistics have severely incorrect coverage.

**Anderson-Rubin (AR) tests.** The weak-instrument-robust AR tests universally fail to reject the null of zero effect (all p > 0.95). The AR test is valid regardless of instrument strength, so this provides credible evidence that the joint hypothesis "β = 0 and instruments are valid" cannot be rejected.

**Hansen J / overidentification.** The overidentification statistic is not reported for any specification due to a degenerate covariance matrix (the warning "estimated covariance matrix of moment conditions not of full rank" appears for every IV model). This arises because the ratio of partialled-out unit dummies (227) to clusters (229) leaves essentially no degrees of freedom. This means overidentification tests are unavailable, so instrument validity cannot be assessed via Hansen J in the current specification.

### 6. Binary Treatment IV (Table A2)

| Specification | 2SLS coeff | SE | p | KP F |
|---|---|---|---|---|
| Binary cut, Z1 | −0.010 | 0.145 | 0.946 | 8.85 |

The binary treatment achieves a substantially higher first-stage F-statistic (8.85 vs. 2.61) because the instrument predicts the direction of spending changes more easily than their continuous magnitude. However, F = 8.85 still falls below the Stock-Yogo 10% threshold of 16.38, and the second-stage estimate remains null.

This finding is informative: Z1 (budget gap) predicts whether a LAD cuts spending (first stage coeff = 0.564, p = 0.003), but the resulting spending cut has no detectable effect on next-year food parcels in the second stage.

### 7. Robustness (Table 4)

| Specification | 2SLS coeff | SE | p | KP F | N |
|---|---|---|---|---|---|
| Placebo Y_t | 1.217 | 0.934 | 0.193 | 2.56 | 1,093 |
| Lead Y_{t+2} | −0.722 | 1.235 | 0.559 | 3.95 | 888 |
| Exclude COVID | −0.239 | 0.713 | 0.737 | 1.64 | 663 |
| ln(1+Y) | −0.042 | 0.741 | 0.955 | 2.61 | 1,106 |

All robustness specifications yield null second-stage estimates with weak first stages. The placebo (contemporaneous Y_t rather than lead Y_{t+1}) produces a positive but statistically insignificant coefficient, which is reassuring—if the timing assumption matters, the placebo should ideally show no effect or a different pattern. The COVID exclusion specification has the weakest first stage (F = 1.64) due to the loss of two years from an already short panel.

### 8. Service-Level FE (Table A3)

None of the five service-share changes (education, children's social care, adult social care, public health, housing) shows a statistically significant association with food parcels in the FE specification (all p > 0.48). Sample sizes range from 506 to 1,071 depending on data availability for each service category. The null findings are consistent with the aggregate result.

### 9. Balance Table (Table A1)

The balance table splits the sample by whether a LAD experienced a spending cut (treat_tse = 1, N = 517) or not (treat_tse = 0, N = 604). Mean differences across covariates are modest: population, IMD scores, and council tax are similar across groups. The instrument Z1 (budget gap change) differs: −0.022 for cut LADs vs. −0.072 for non-cut LADs, confirming that LADs with larger budget gap changes were more likely to maintain spending. Grant cuts (Z3) are also somewhat larger for non-cut LADs (0.028 vs. 0.007). A formal t-test column should be added for AER purposes.

### 10. Summary Assessment

The results tell a coherent but disappointing story from a statistical power perspective:

1. **The FE estimates are null.** Within-unit variation in austerity intensity does not predict food parcel changes, conditional on year FE and controls.

2. **The reduced form is null.** The instruments have no detectable relationship with the outcome.

3. **The IV first stage is weak.** Z1 (budget gap) marginally predicts continuous austerity (p ≈ 0.11) but with a KP F-statistic of 2.6. The instrument works better for binary treatment (F = 8.85).

4. **The IV second stage is null.** Point estimates cluster near zero with very large standard errors. Weak-instrument-robust AR tests also fail to reject zero.

5. **Instrument validity is untestable.** The Hansen J statistic is unavailable due to a degenerate cluster-robust covariance matrix.

**The binding constraint is instrument weakness.** The budget-gap instrument does not generate sufficient first-stage variation in the continuous austerity treatment within the FE framework. This is a design problem, not a coding error. Potential remedies are discussed in Part III below.

---

## Part II. Code Review

### Issues Identified

**Issue 1 (Substantive): Time-invariant controls included under unit FE.** The variables `d_asinhTSE_2010_2018` (long-run squeeze, 2010–2018) and `imd2019_score` are both time-invariant within a LAD. Including them in `xtreg ... fe` and in `ivreg2 ... partial(i.onscode_encode)` causes automatic omission (collinearity). This is not an error per se, but it produces confusing output (omitted notes) and inflates the reported parameter count K. For AER-standard clarity, these controls should be explicitly excluded from the FE and IV-FE regressor lists and reserved for pooled or between-effects specifications, or their role should be explicitly noted in the table notes.

**Issue 2 (Serious): Degenerate cluster-robust covariance matrix.** Every `ivreg2` specification produces the warning "estimated covariance matrix of moment conditions not of full rank." This arises because 227 unit dummies are partialled out of a model estimated with 229 clusters, leaving only 2 effective degrees of freedom for the cluster-robust VCE. Standard errors and test statistics (including KP F) should be interpreted with caution. This is a structural feature of combining many-unit FE with LAD-level clustering in a short panel. Consider (a) clustering at a higher level (e.g., NUTS2 or NUTS1 regions) or (b) using `reghdfe`/`ivreghdfe` which handle high-dimensional FE more efficiently.

**Issue 3 (Cosmetic): Reported N discrepancy.** The FE specifications report N = 1,106 while the sample_main indicator counts 1,121 observations. The difference (15 obs) is due to singleton clusters—LADs observed in only one year that are dropped by the FE estimator. This should be documented in a table note.

**Issue 4 (Minor): `estpost summarize` does not report p50.** The `esttab` call for Table 1 requests `cells("count mean sd min p50 max")` but `estpost summarize` does not compute p50 (the median). This column will appear blank. Either add `estpost summarize ..., detail` to compute percentiles, or remove p50 from the cells list.

**Issue 5 (Minor): `savefirst` on robustness specs.** The `savefirst` option is only used on Section 14 (main IV) but not on Section 15 (robustness). This is fine for table purposes, but for completeness, first-stage results for robustness checks should also be retainable if a referee requests them.

**Issue 6 (Cosmetic): Table notes missing.** AER requires table notes specifying: (a) the dependent variable, (b) sample period, (c) fixed effects included, (d) clustering level, (e) significance stars, (f) instrument details for IV tables. The current `esttab` calls do not include `addnotes()`. Suggested boilerplate:

```stata
addnotes("All specifications include LAD and year FE." ///
         "Standard errors clustered at the LAD level." ///
         "* p<0.10, ** p<0.05, *** p<0.01")
```

**Issue 7 (Recommended): First-stage table.** AER convention requires reporting the first-stage regression as a separate table when the first stage is weak. The current code reports first-stage output to the log via `first` but does not export a formatted first-stage table. Add:

```stata
estimates restore _ivreg2_austerity_tse
esttab using "$tables/tableA_firststage.tex", ...
```

### Code That Is Correct

The following elements are properly implemented and meet AER standards:

- Panel declaration with `xtset` and sample windowing via `keep if inrange(year, 2010, 2023)`
- Asinh transformation applied consistently to outcome, treatment, and instruments
- Forward operator `F.` and `F2.` for lead outcomes (correctly exploiting `xtset` time structure)
- `partial(i.onscode_encode)` for FE absorption in `ivreg2` (numerically equivalent to within-transformation)
- Cluster-robust SEs at the LAD level throughout
- Sample indicators (`sample_main`, `sample_no_covid`) defined once and reused
- Intermediate base-year variables dropped after construction
- Log file captures all output
- Tables exported with `booktabs`, `label`, consistent star conventions

---

## Part III. Recommendations for Strengthening the IV Strategy

The weak-instrument problem is the central methodological challenge. Several paths forward exist:

**A. Reconsider the level of fixed effects.** Unit FE absorb all cross-sectional variation in both the treatment and the instrument. Since Z1 (budget gap change relative to 2018) varies primarily in the cross-section (the base year is fixed at 2018), unit FE remove much of the identifying variation. Consider:

- Replacing LAD FE with NUTS1 region FE (9 regions instead of 229 units). This preserves cross-sectional variation in Z1 while still controlling for broad regional trends. The first-stage F would likely increase substantially.
- Using a between-within decomposition or Mundlak-Chamberlain device to retain cross-sectional instrument variation while controlling for unit-level confounders.

**B. Use a different time-series structure for Z1.** Currently Z1 = asinh(budget_gap_t) − asinh(budget_gap_2018), which changes over time. But with unit FE, only the within-unit deviations of Z1 from its unit mean contribute to identification. If most Z1 variation is between-LAD rather than within-LAD, unit FE will absorb most of it. Consider using lagged Z1 (Z1_{t-1}) or interacting Z1 with year dummies to create year-specific cross-sectional variation.

**C. Pursue the binary treatment strategy.** The binary treatment achieves F = 8.85, which is borderline acceptable. Consider using the binary treatment as the primary specification (with caveats about the extensive-margin interpretation) and reporting the continuous treatment as a secondary analysis. This is defensible: the policy question "does cutting local spending increase food bank usage?" is naturally binary.

**D. Report Anderson-Rubin confidence sets.** Since the AR test is valid under weak instruments, report AR-based confidence intervals for the causal effect. The `weakiv` package in Stata (Finlay and Magnusson) constructs these.

**E. Use `ivreghdfe` instead of `ivreg2` + `partial()`.** The `ivreghdfe` command (Correia 2019) handles high-dimensional FE via iterative demeaning (like `reghdfe`) and avoids the degenerate covariance matrix problem that arises from explicit partialling with many dummies.

```stata
* ssc install ivreghdfe
* ssc install reghdfe
* ssc install ftools
ivreghdfe asinh_f1_countparcels ///
    (austerity_tse = d_asinh_budgetgap) ///
    ln_population c.rs_ctr_real_pc ///
    if sample_main == 1, ///
    absorb(onscode_encode year) cluster(onscode_encode)
```

This should produce valid KP F-statistics and Hansen J without the covariance-matrix warning.

---

## Part IV. Recommended Immediate Code Fixes

| Priority | Fix | Reason |
|---|---|---|
| High | Switch from `ivreg2` + `partial()` to `ivreghdfe` + `absorb()` | Resolves degenerate VCE warning, produces valid diagnostics |
| High | Remove `d_asinhTSE_2010_2018` and `imd2019_score` from FE/IV regressors | Avoids collinearity omission; include only in pooled specs |
| Medium | Add `addnotes()` to all `esttab` calls | AER table-note requirement |
| Medium | Export first-stage table from `savefirst` estimates | AER weak-IV reporting standard |
| Medium | Add t-test column to balance table | AER balance table convention |
| Low | Fix `estpost summarize` to use `, detail` or remove p50 from cells | Avoids blank column |
| Low | Document singleton-drop count (N = 1,106 vs. 1,121) | AER transparency |
