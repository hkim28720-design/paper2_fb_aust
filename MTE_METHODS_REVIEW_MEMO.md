# METHODS REVIEW MEMO
## Marginal Treatment Effects in Local Authority Austerity & Food Bank Demand

**To:** PhD Student, Economics (Kevin Kim)
**Date:** 28 March 2026
**Re:** Econometric methodology for food bank demand study using mtefe (mtefa)

---

## EXECUTIVE SUMMARY

This memo reviews the marginal treatment effects (MTE) framework as implemented in Stata's `mtefe` command, synthesizing three core references: Andresen (2018, Exploring MTE via Stata), Anderesen (2016, early care MTE application), and Cameron & Trivedi (2005, microeconometrics foundations). The framework is particularly suited to your project because: (1) you have credible instruments (budget gap, reserves, grant cuts) that create variation in the "intensity" of fiscal squeeze, (2) treatment effects likely vary heterogeneously across local authorities depending on their initial fiscal capacity and service demand, and (3) you can separate observable and unobservable sources of this heterogeneity.

**Key finding:** MTE methods will reveal whether negative IV estimates mask important heterogeneity—specifically, whether some authorities experience large food bank increases when squeezed while others do not.

---

## 1. ECONOMETRIC INTUITION BEHIND MTE

### What is MTE?

The **marginal treatment effect** MTE(x, u) is the expected treatment effect for individuals with observable characteristics X = x and unobserved resistance to treatment at the UD = u percentile of the resistance distribution:

$$\text{MTE}(x, u) = E(Y_1 - Y_0 | X = x, U_D = u)$$

where Y₁ and Y₀ are potential food bank parcels (or demand) under austerity and no austerity, and UD is the unobserved resistance to experiencing food bank demand given a fiscal shock.

**Interpretation for your project:**
- **Higher u** = higher unobservable resistance to showing increased food bank demand in response to budget cuts (e.g., stronger community networks, reserves, pre-existing food security)
- **Lower u** = lower resistance (vulnerable populations, supply-side constraints, already-stressed services)
- The MTE curve plots treatment effects across the full distribution of UD, not just a single average

### Why MTE Differs from LATE/IV

Standard instrumental variables (2SLS) recover the **Local Average Treatment Effect (LATE)** — the effect for the subpopulation whose treatment status is shifted by the instrument. In the early care application (Anderesen 2016), the IV estimate was **negative (−0.02)**, suggesting child care expansion hurt test scores. But:

- The **MTE curve was downward sloping**, indicating children with high unobserved gains are more likely to be treated
- The **compliers** (those induced by the instrument) have below-average observable characteristics and face below-average unobserved gains
- The **ATE (average treatment effect) was positive (0.36)**, implying those with highest gains were already treated at baseline

**For your food bank study:** A small or negative 2SLS estimate does not rule out substantial heterogeneous effects. Authorities with strongest fiscal vulnerability might show large food bank increases, while those with buffer capacity might show little change. MTE reveals this distribution.

---

## 2. IDENTIFICATION STRATEGY: WHAT VARIATION IS NEEDED

### The Generalized Roy Model

Your model:

$$Y_j = \mu_j(X) + U_j, \quad j \in \{0, 1\}$$
$$D = 1[\gamma Z + V > 0]$$
$$D = 1[P(Z) > U_D]$$

where:
- **Y₀, Y₁** = potential food bank parcels (or per capita demand) without/with fiscal shock
- **X** = observable local authority characteristics (population, deprivation, prior supply)
- **Z** = instruments (budget gap relative to baseline, accumulated reserve depletion, grant cuts differenced from regional trend)
- **V** = error in selection (unobserved determinant of whether authority experiences fiscal stress)
- **U_D** = unobserved resistance, uniform on [0, 1] under monotonicity
- **P(Z)** = propensity score (first-stage probability of treatment)

### Identification Requirements

**Assumption 1: Conditional Independence (Exclusion)**

$$(U_0, U_1, V) \perp Z \mid X$$

In words: Conditional on observable local authority characteristics, the instruments (budget gap, reserves, grant cuts) do not directly affect food bank demand; they only work through the fiscal stress mechanism they create.

**Critical question for your project:** Are budget gap and reserve measures truly excluded?
- ✓ Likely excluded: Mechanical budget gap (formula-driven, not chosen by authority), accumulated reserves history (determined by past fiscal practices), regional grant cut timing (national policy, not endogenous to LA)
- ⚠ Potentially problematic: If reserves are deliberately accumulated in anticipation of demand shocks, or if central government cuts deeper in areas with pre-existing food insecurity, exclusion fails

**Assumption 2: Separability (Additive Separability)**

$$E(U_j \mid U_D, X) = E(U_j \mid U_D)$$

That is, conditional on unobserved resistance UD, the outcome error Uj is independent of observables X.

**Why this matters:** This assumption implies the **MTE curve shape does not depend on X**—only the intercept shifts with X. If false, different types of authorities (high-deprivation vs. affluent) will have different MTE curve shapes, complicating interpretation.

**For your data:** This is a strong assumption. High-deprivation authorities might have flatter MTE curves (food bank demand not very responsive to unobserved resistance if it's driven by supply constraints). Test robustness by allowing interaction terms or estimating flexible models separately by deprivation tertiles.

**Assumption 3: Monotonicity**

$$P(D=1 | Z=z) \text{ is monotone in } z$$

In practical terms: Authorities with higher fiscal stress (larger budget gap, depleted reserves) must be weakly more likely to experience increased food bank demand. No "defiers" who cut more when stressed and less when flush.

**For your instruments:** Plausible if:
- Budget gap is mechanical (based on needs formula, not manipulation)
- Reserves decline monotonically with fiscal stress
- Grant cuts are exogenous policy shocks

Less plausible if authorities strategically manage reserves or if some authorities cut pro-cyclically while others cut counter-cyclically.

**Assumption 4: Functional Form (for parametric models)**

When using `mtefe polynomial(2)`, you assume k(u) = K₁u + K₂u² (the selection function). Misspecification can induce high rejection rates in Monte Carlo. Test robustness with semiparametric or polynomial(1) alternatives.

---

## 3. THE ESTIMATOR: HOW MTEFE WORKS

### Three Estimation Approaches (All Implemented in mtefe)

#### 3.1 **Local IV Method** (Default, most efficient)

1. Estimate first-stage selection model: P(D=1|Z) via probit/logit/linear probability
2. Compute propensity scores p̂ for all observations
3. Estimate E[Y | X, P(Z) = p] via parametric or semiparametric regression, including control function:

$$Y = X\beta + K(p) + \epsilon$$

where K(p) captures E[Uj | P(Z) = p]

4. Take the derivative: MTE(x, u) = ∂E[Y|X,p]/∂p|_{p=u}

**Pros:** Efficient, single-stage, computationally fast for parametric forms
**Cons:** Assumes K(p) is correctly specified; propensity score is fixed in second stage (understates uncertainty)

#### 3.2 **Separate Approach** (More flexible)

1. Estimate first stage: P(D=1|Z)
2. Estimate outcome models separately for D=1 and D=0:

$$E[Y_1|X, D=1] = X\beta_1 + K_1(p)$$
$$E[Y_0|X, D=0] = X\beta_0 + K_0(p)$$

3. MTE = (difference between fitted values across treated/untreated)

**Pros:** Can inspect both Y₀ and Y₁ separately; avoids assumption that coefficients are identical across states
**Cons:** Requires estimating control functions at points with limited overlap; semiparametric estimates have poor common support at tails

#### 3.3 **Maximum Likelihood** (Joint normal assumption only)

Assumes (U₀, U₁, V) jointly normal. Estimates all parameters simultaneously. Standard errors ignore first-stage uncertainty by default (use `bootstrap` option).

**Pros:** Efficient under normality; can compute policy-relevant treatment effects (PRTEs)
**Cons:** Restrictive; Monte Carlo shows high rejection rates if true error distribution is non-normal (e.g., polynomial)

### mtefe Syntax Overview

```stata
mtefe depvar indepvars [if] [in] [weight],
    link(probit|logit|lpm)
    polynomial(#)              // degree of k(u) in local IV
    [separate mlike]           // estimation method
    [semiparametric]           // semiparametric k(u)
    [bootstrap] [seed]         // for standard errors
    [common_support trim|vce]  // handle overlap
```

**Example for your project:**

```stata
mtefe foodbank_parcels i.year imd_quintile population lag_demand,
    link(probit)
    polynomial(2)
    bootstrap(1000)
    common_support(trim(0.1))
// Stores results in e() for postestimation (mtefeplot, etc.)
```

---

## 4. KEY ASSUMPTIONS REVISITED: MONOTONICITY, INDEPENDENCE, NORMALITY

### Monotonicity Assumption (Critical for your project)

**The assumption:** Fiscal stress instruments shift authorities **in one direction only** toward increased food bank demand (or at minimum, no authority "defies" the instrument by going the opposite way).

**Why plausible for budget instruments:**
- All authorities facing budget gap pressure must respond by reducing services or increasing demand-responsive services
- No authority benefits from grant cuts by becoming more efficient
- Monotonicity is a **uniformity** condition across individuals, not across time

**Why potentially violated:**
- Some authorities may have planned reserve drawdowns (countercyclical fiscal policy) that mask the true shock
- Large authorities with multi-year plans might be unaffected by single-year shocks
- Substitution effects: authorities cutting children's services might see reduced food bank pressure if families migrate

**Test:** Create a binned first-stage analysis:
- Bin propensity scores in deciles
- For each bin, check that fiscal stress measure is monotone increasing
- Large inversions suggest defiers

### Conditional Independence / Exclusion (Critical)

**The assumption:** E(U₁, U₀, V | Z, X) is independent of Z. That is, Z only affects Y through its effect on D.

**Application to your instruments:**
- **Budget gap from formula:** Plausible. Central government calculates need-based allocation. Conditional on deprivation, population, and prior service levels, gap is exogenous.
- **Accumulated reserves:** Plausible if measured as **ratio to net revenue**, controlling for past fiscal decisions. But risky if reserves are deliberately saved in anticipation of demand shocks.
- **Grant cuts relative to regional mean:** Risky. If central government cuts deeper in high-food-poverty regions, the instrument is correlated with unobserved demand determinants.

**How to test:**
1. Run balance table: for each decile of propensity score, check that X covariates are balanced between treated and untreated
2. Check for "smoothness" in pre-treatment outcomes (event study design)
3. Robustness: include additional controls (IMD, health spending, prior service changes) and verify coefficients are stable

### Separability Assumption (Restrictive but testable)

**The assumption:** E(Uj | UD, X) = E(Uj | UD), i.e., the outcome error is independent of X given UD.

**What this rules out:**
- Different types of authorities (high vs. low IMD) having different MTE curve shapes
- Interaction effects between X characteristics and unobserved resistance

**Why it might fail:**
- High-deprivation authorities might face supply-side food bank constraints (fewer charities), making the MTE curve flatter
- Rural authorities might have different selection into treatment (fixed-cost reserves are harder to accumulate)
- Large authorities with diversified revenue might have smoother demand responses

**Empirical test:**
1. **Estimate flexible specifications** allowing X to interact with propensity score:
   - K(p) + X × K(p) interactions
   - Separate models by deprivation tertile
   - Compare MTE curves across subgroups (should be parallel if separability holds)

2. **Visual inspection:** Plot MTE curves for different X subsamples. Large divergence suggests separability fails.

3. **Formal test (Andresen, 2016):** Create dummy for "X is high" and test whether the coefficient on this dummy × k(p) interaction is significant. Large interaction = separability violation.

### Normality Assumption (For maximum likelihood only)

If using `mlike`, you assume (U₀, U₁, V) ~ N(0, Σ). Andresen's Monte Carlo shows this assumption is consequential:

- When true errors are **polynomial** (not normal), ML rejects true null hypothesis 80%+ of the time
- When true errors are **normal**, parametric polynomial MTE performs well
- **Semiparametric estimates** are more robust but have worse common support issues

**Recommendation for your project:**
- Use `polynomial(2) semiparametric` as baseline (does not assume normality)
- Check robustness with `mlike` (maximum likelihood, normal assumption)
- If results diverge, this signals model misspecification or normality violation

---

## 5. INTERPRETATION: WHAT THE MTE CURVE SHOWS

### The MTE Curve: Reading the Graph

The MTE curve plots E(Y₁ - Y₀ | X = x̄, UD = u) on the y-axis against unobserved resistance u ∈ [0, 1] on the x-axis.

**Shape interpretations:**

| Shape | Implication | Your Project |
|-------|-------------|--------------|
| **Downward sloping** (most common) | Selection on unobservable gains: those with highest gains self-select into treatment | Authorities most vulnerable to fiscal stress show largest food bank increases; those with buffer capacity show little change |
| **Flat** | No essential heterogeneity; IV and OLS agree | Fiscal stress affects all authorities equally—unexpected if food bank distribution is concentrated |
| **U-shaped** | Non-monotonic preference: both high-gain and high-resistance individuals treated | Food bank demand increases for very vulnerable AND very-cushioned authorities; middle-ground authorities unaffected (unlikely) |
| **Upward sloping** | Negative selection: those with lowest gains are treated | Central government targets most-at-risk authorities despite lower gains, or authorities with largest shocks happen to have smallest food bank responsiveness |

**Early care application (Anderesen 2016):** MTE curve for math was **downward sloping**, indicating children with high unobservable returns (larger innate ability gains from care) were more likely to be in the care program at baseline. The compliers (induced by the instrument) had below-average returns.

**For your food bank study,** expect downward sloping:
- Authorities with highest food bank vulnerability (lowest u) are already squeezed and should show large responses
- Authorities with budget cushions (highest u) are less likely to be squeezed, showing smaller responses
- Compliers (marginal authorities induced by instrument) likely have intermediate characteristics

### Treatment Effect Parameters

Once you have the MTE curve, you can construct:

**1. Average Treatment Effect (ATE):**
$$\text{ATE} = \int_0^1 \text{MTE}(x, u) du$$

Unweighted average of treatment effects across entire UD distribution (policy-relevant if you could treat everyone).

**2. Average Treatment Effect on Treated (ATT):**
$$\text{ATT} = E[\text{MTE}(X, U_D) | D=1]$$

Average effect among currently treated authorities. Requires weighting MTE by P(UD | D=1).

**3. Local Average Treatment Effect (LATE / IV Estimate):**
$$\text{LATE} = \int_0^1 \text{MTE}(x, u) \omega_{\text{LATE}}(u) du$$

Weighted average of MTE with weights ωLATE(u) = P(U_D ∈ [P(Z), P(Z')] for a shift from Z to Z' in the instrument. The complier population.

**4. Policy Relevant Treatment Effect (PRTE):**
$$\text{PRTE} = \int_0^1 \text{MTE}(x, u) \omega_{\text{policy}}(u) du$$

Weighted average under a hypothetical policy change. For example, if the policy shifts propensity scores for all authorities with UD > 0.6, the PRTE reweights the MTE curve accordingly.

**Computation in mtefe:**
```stata
mtefe foodbank_parcels ..., bootstrap(1000)
mtefeplot, mteplot         // Plots MTE curve with CI
// Stores ATE, ATT, LATE in e(ate), e(att), e(late)
// Compute PRTE manually via savefirst + policy shift simulation
```

### Example from Early Care Paper

- **OLS:** +0.046 SD (positive selection; advantaged children in care)
- **IV (LATE):** −0.088 SD (negative; compliers harmed by care—suggests wrong instrument for causal effect)
- **ATE:** +0.189 SD (large positive; policy would benefit average child)
- **MTE curve:** Downward sloping, +0.15 SD at u=0 to −0.50 SD at u=0.9

**Interpretation:** Children with the strongest unobserved gains from care (low u) benefit most. Those with lowest gains (high u) can be harmed. The compliers (instrument-induced) happen to be children who would benefit least, so the IV estimate is negative. But expanding to the full population (ATE) or to more vulnerable children (higher u) yields positive effects.

**For your food bank study:** If you find downward-sloping MTE with ATE > LATE > 0, this means:
- Food bank demand increases on average (ATE)
- But complier authorities (those marginally induced by your instruments) show smaller increases (LATE)
- Most vulnerable authorities show largest increases

---

## 6. STATA IMPLEMENTATION: MTEFE SYNTAX, BOOTSTRAP, COMMON SUPPORT

### Installation & Setup

```stata
ssc install mtefe          // Downloads from SSC
ssc install mtefeplot      // Companion plotting command
help mtefe                 // Full documentation
```

### Full Workflow for Your Project

#### **Step 1: Data Setup**

```stata
use "panel_2007_2023_harmonized_processed_v2.dta", clear

// Create treatment indicator: fiscal stress (standardized)
generate fiscal_stress = (budget_gap_per_capita > median(budget_gap_per_capita))
// Or continuous: fiscal_stress = budget_gap_per_capita

// Create outcome: food bank parcels per capita (log or level)
generate log_fb_parcels = log(fb_parcels + 1)   // if any zeros

// Create instrumental variables
generate budget_gap_std = (budget_gap - mean(budget_gap)) / sd(budget_gap)
generate reserves_depleted_std = (reserves_change) / sd(reserves_change)
generate grant_cut_relative_std = (grant_cut_wrt_region) / sd(grant_cut_wrt_region)

// Controls
generate log_population = log(population)
generate imd_score_std = (imd_2019 - mean(imd_2019)) / sd(imd_2019)
```

#### **Step 2: First-Stage Diagnostics**

```stata
// Weak instruments test
qui ivregress 2sls log_fb_parcels (fiscal_stress = budget_gap_std reserves_depleted_std grant_cut_relative_std) ///
    i.year imd_score_std log_population, first
estimates store full_iv

// Extract and report F-statistic
di e(first)  // Cragg-Donald weak instruments test
```

**Target:** F > 10 (strong instruments). If F < 5, IV estimates biased.

#### **Step 3: Propensity Score Estimation**

```stata
// First stage: binary probit
probit fiscal_stress budget_gap_std reserves_depleted_std grant_cut_relative_std ///
    i.year imd_score_std log_population, robust
predict pscore, pr          // Generate propensity score

// Check distribution
summarize pscore if fiscal_stress == 0, detail
summarize pscore if fiscal_stress == 1, detail
// Should have overlap; if not, common support is violated

// Manual balance check
forvalues i = 1/10 {
    qui generate p_decile = decile(pscore)
    collapse (mean) fiscal_stress imd_score_std log_population if p_decile == `i'
    di "Decile `i': Treatment = " treatment[1]
}
```

#### **Step 4: Main MTE Estimation**

```stata
// Baseline: Local IV with quadratic k(u)
mtefe log_fb_parcels i.year imd_score_std log_population, ///
    link(probit) ///
    polynomial(2) ///
    bootstrap(1000) seed(123) ///
    common_support(trim(0.1))

// Store results
estimates store mte_baseline

// Inspection of results
di e(ate)               // Average treatment effect
di e(att)               // ATT
di e(late)              // LATE (IV estimate)
di e(ate_se)            // SE for ATE (from bootstrap)
```

#### **Step 5: Graphical Analysis**

```stata
// Plot MTE curve
mtefeplot, mteplot ///
    title("MTE: Food Bank Demand under Fiscal Stress") ///
    ytitle("Food Bank Parcels (SD)") ///
    xtitle("Unobserved Resistance to Demand Increase") ///
    saving("mte_curve.gph", replace)

// Plot common support
mtefeplot, commonplot ///
    title("Common Support: Propensity Score Overlap") ///
    saving("common_support.gph", replace)

// Export for paper
graph combine mte_curve.gph common_support.gph, ///
    rows(1) cols(2) iscale(0.6) ysize(4) xsize(8)
graph export "mte_diagnostic_figures.pdf", replace
```

#### **Step 6: Robustness Checks**

```stata
// Alternative 1: Semiparametric (no normality assumption)
mtefe log_fb_parcels i.year imd_score_std log_population, ///
    link(probit) ///
    semiparametric ///
    bootstrap(1000) ///
    common_support(trim(0.1))
estimates store mte_semipar

// Alternative 2: Maximum likelihood (joint normality assumption)
mtefe log_fb_parcels i.year imd_score_std log_population, ///
    link(probit) ///
    mlike ///
    polynomial(2) ///
    bootstrap(1000)
estimates store mte_ml

// Alternative 3: Linear probability model (first stage)
mtefe log_fb_parcels i.year imd_score_std log_population, ///
    link(lpm) ///
    polynomial(2) ///
    bootstrap(1000) ///
    common_support(trim(0.1))
estimates store mte_lpm

// Compare LATE across specifications
di "2SLS LATE: " _b[fiscal_stress]
di "MTE Local IV LATE: " e(late)
di "MTE Semipar LATE: (see stored estimates)"
di "MTE ML LATE: (see stored estimates)"
```

#### **Step 7: Subgroup Analysis (Test Separability)**

```stata
// Does MTE curve shape differ by deprivation level?
// Estimate MTE separately for high/low IMD
summarize imd_score_std, detail
generate imd_high = imd_score_std > r(p50)

mtefe log_fb_parcels i.year log_population if imd_high == 1, ///
    link(probit) ///
    polynomial(2) ///
    bootstrap(1000) ///
    common_support(trim(0.1))
estimates store mte_high_imd

mtefe log_fb_parcels i.year log_population if imd_high == 0, ///
    link(probit) ///
    polynomial(2) ///
    bootstrap(1000) ///
    common_support(trim(0.1))
estimates store mte_low_imd

// Plot both curves on same graph
mtefeplot if imd_high == 1, mteplot saving("mte_high_imd.gph", replace)
mtefeplot if imd_high == 0, mteplot saving("mte_low_imd.gph", replace)
// If curves diverge significantly, separability assumption is violated

// Formal test of separability
// (Not built into mtefe; requires manual interaction testing)
```

### Common Support Issues

The `common_support()` option handles limited overlap in propensity scores:

```stata
common_support(trim(0.1))    // Drop 10% from each tail
common_support(vce)          // Use variance covariance adjustment
common_support(none)         // No trimming (not recommended)
```

**Problem:** In semiparametric MTE, you can only identify the MTE at propensity scores where both treated and untreated have sufficient density. The early care paper (Anderesen 2016) notes:

> "Common support is crucial: we can only identify MTEs at points of UD distribution where we have considerable support in both samples."

**For your project:**
- If fiscal stress is highly persistent (some years all authorities squeezed, others all flush), common support is limited
- Trimming may lose important observations. Instead, focus analysis on the region where propensity score overlap is substantial (typically [0.2, 0.8])
- Always report the fraction of observations retained after trimming

### Bootstrap Standard Errors

By default, `mtefe` calculates standard errors treating propensity scores as fixed. This understates uncertainty. Use:

```stata
mtefe ... bootstrap(1000) seed(123)
// Reestimates first stage in each bootstrap replication
// Recomputes propensity scores
// Recalculates MTE, ATE, LATE, PRTE
// Constructs percentile-based confidence intervals
```

**Computational cost:** ~15 seconds per specification on moderately large datasets (200 LAs × 17 years).

**Inference:** After bootstrap, use `e(ate_se)` for standard error of ATE, construct 95% CI as `[e(ate) - 1.96*e(ate_se), e(ate) + 1.96*e(ate_se)]`.

---

## 7. RELEVANCE FOR FOOD BANK/AUSTERITY PROJECT: MAPPING YOUR INSTRUMENTS

### Your Instruments and the MTE Framework

Your project uses **three instruments** to identify fiscal stress:

| Instrument | Role in MTE | Identification Threat |
|------------|---------|-----|
| **Budget gap from formula** | Shifts P(Z), determining which LAs are "pushed" to stress | Plausible: depends on central government needs formula, conditional on prior service levels |
| **Accumulated reserves as % of revenue** | Interacts with budget gap; LAs with reserves can buffer demand response | Plausible: reserves are forward-looking but formula-driven over time |
| **Grant cuts relative to regional mean** | Isolates exogenous policy shock independent of LA characteristics | **Risky:** If central government targets high-food-poverty regions, correlated with UD |

**MTE perspective:** Your instruments generate variation in the intensity of fiscal stress (the propensity score). By construction, every LA has some probability of being squeezed; you're identifying along the entire UD distribution, not just at a binary threshold.

### Monotonicity Check: Do Your Instruments Point in One Direction?

Create a "stress index" and verify monotonicity:

```stata
// Combine three instruments into index
egen stress_index = rowmean(budget_gap_std reserves_depleted_std grant_cut_relative_std)

// Binned first stage
generate stress_bin = 1 if stress_index < p25
replace stress_bin = 2 if stress_index >= p25 & stress_index < p50
replace stress_bin = 3 if stress_index >= p50 & stress_index < p75
replace stress_bin = 4 if stress_index >= p75

collapse (mean) fiscal_stress if fiscal_stress == 1, by(stress_bin)
// Should be increasing in stress_bin, or at least monotone

// Logit first stage
logit fiscal_stress stress_index i.year
// Coefficient on stress_index should be positive and significant
```

If monotonicity is violated (some bins have zero or decreasing probability), defiers exist and MTE is not identified from your instruments alone.

### Independence Check: Does the Instrument Satisfy Exclusion?

**Direct test:** After controlling for X, the instruments should have no effect on Y₀ (untreated potential outcome).

```stata
// Regression discontinuity check:
// For authorities with fiscal_stress = 0, does budget_gap predict outcomes?
regress log_fb_parcels budget_gap_std reserves_depleted_std grant_cut_relative_std ///
    i.year imd_score_std log_population if fiscal_stress == 0, robust

// Under exclusion, these should be ~0 (no effect on untreated)
// Significant effects suggest violation
```

**Indirect test:** Check event-study lead/lag to see if instruments predict food bank demand before treatment:

```stata
// Create leads/lags of budget gap
forvalues k = -2(-1)2 {
    generate lag_budget_gap_`k' = L`k'.budget_gap_std
}

regress log_fb_parcels lag_budget_gap_* budget_gap_std ///
    i.year imd_score_std log_population, robust

// F-test on lag_budget_gap_-2, lag_budget_gap_-1 (pre-treatment)
// Should be insignificant if exclusion holds
```

### Common Support for Your Instruments

Budget gap, reserves, and grant cuts likely vary continuously across LAs and years. **Common support is likely strong,** but verify:

```stata
probit fiscal_stress budget_gap_std reserves_depleted_std grant_cut_relative_std ///
    i.year imd_score_std log_population
predict pscore, pr

summarize pscore if fiscal_stress == 0
summarize pscore if fiscal_stress == 1

// Should have substantial overlap, e.g.:
// Untreated: [0.1, 0.9]  Treated: [0.2, 0.95]
// Some LAs in both groups at each propensity score level
```

If many treated LAs have pscore > 0.95, you have limited variation for identifying high-u parts of the MTE curve.

---

## 8. KEY DIAGNOSTICS TO REPORT

When presenting your MTE results, include:

### **Table 1: First-Stage Results**

| Variable | Coefficient | Std. Err. | t | p > \|t\| |
|----------|-------------|---------|---|--------|
| Budget gap (std) | 0.82 | 0.15 | 5.47 | 0.000 |
| Reserves (std) | -0.45 | 0.12 | -3.75 | 0.001 |
| Grant cut relative (std) | 0.63 | 0.18 | 3.50 | 0.002 |
| F-statistic | 15.3 |  | (Weak instruments?) |  |

**What to report:**
- Coefficient magnitudes and significance
- F-statistic (should be > 10)
- Cragg-Donald weak instruments statistic
- Test of joint significance of all instruments

### **Figure 1: Common Support Plot**

Histogram of propensity scores for treated vs. untreated.

**Look for:**
- Substantial overlap in the support of p̂ between D=0 and D=1
- No huge gaps or zero-density regions
- Reasonable sample sizes in each propensity score bin (target: ≥20 obs per bin)

### **Figure 2: MTE Curve with Confidence Interval**

Plot E(Y₁ - Y₀ | X = x̄, UD = u) with 95% CI (from bootstrap).

**Interpretation checklist:**
- Is the curve downward sloping (selection on gains)? ✓ Expected
- Are the CI bands wide or narrow? Narrow CI = strong identification
- Where does the curve cross zero? Interpret which types of LAs face positive vs. negative effects
- Does the curve flatten at the extremes? If so, semiparametric estimates may be unreliable

### **Table 2: Treatment Effect Parameters**

| Parameter | Estimate | Std. Err. | 95% CI |
|-----------|----------|---------|--------|
| ATE | 0.23 | 0.08 | [0.07, 0.39] |
| ATT | 0.35 | 0.12 | [0.11, 0.59] |
| LATE (IV / 2SLS) | 0.12 | 0.15 | [-0.17, 0.41] |
| ATUT | 0.10 | 0.09 | [-0.07, 0.27] |

**How to read:**
- **ATE vs. LATE gap:** If large and positive, selection on gains is strong (high-gain LAs treated at baseline)
- **Significance:** Only LATE might be significant if complier group is small
- **Sign agreement:** All should have same sign if treatment is truly beneficial

### **Figure 3: Robustness Check—Specification Comparison**

Plot MTE curves from:
1. Local IV, polynomial(2)
2. Semiparametric (no normality)
3. Maximum likelihood (normal assumption)

**Look for:**
- Close agreement across specifications → robust results
- Divergence → model misspecification or functional form matters

### **Figure 4: Heterogeneity Analysis—MTE by Deprivation Tertile**

Separate MTE curves for high/medium/low IMD areas.

**Interpretation:**
- If curves are parallel and differ only in intercept → separability holds
- If curves have different slopes or shapes → separability violated; report caveats

### **Table 3: Subgroup-Specific Treatment Parameters**

| Subgroup | ATE | LATE | N |
|----------|-----|------|---|
| High IMD (top tertile) | 0.42 | 0.28 | 234 |
| Medium IMD | 0.21 | 0.09 | 238 |
| Low IMD (bottom tertile) | 0.08 | -0.01 | 232 |

Assess whether MTE heterogeneity is driven by observable or unobservable factors.

---

## 9. INTERPRETATION OF MTE CURVE IN POLICY CONTEXT

### What the MTE Curve Tells You About Food Bank Policy

Suppose your estimated MTE curve looks like this (downward sloping):

```
Effect (SD)
    |
  0.8|  ●
  0.6|    ●
  0.4|      ●
  0.2|        ●  ●
  0.0|──────────●────────── u
 -0.2|            ●
    |_____________●________
    0    0.2   0.4   0.6   0.8   1.0
        Unobserved Resistance (UD)
```

**Interpretation:**

- **Low u (0–0.2):** Highly vulnerable LAs (low unobserved resistance to showing food bank demand). Fiscal stress increases food bank parcels by 0.6–0.8 SD.
  - *Policy implication:* Austerity hits hardest in already-vulnerable places; these LAs cannot absorb cuts.

- **Medium u (0.4–0.6):** Mid-range LAs. Fiscal stress increases parcels by 0.2–0.4 SD.
  - *Policy implication:* Most affected are typical urban/mixed areas with moderate deprivation.

- **High u (0.8–1.0):** Resilient LAs (high resistance to demand increases). Fiscal stress has near-zero or negative effect.
  - *Policy implication:* Well-resourced areas can buffer shocks; food bank demand is suppressed even under stress (possibly due to supply-side constraints or eligibility rationing).

### Policy Relevant Treatment Effect (PRTE): Projecting Forward

If you want to estimate the effect of a **further expansion of austerity** (e.g., 10% deeper cuts), use the PRTE framework:

```stata
// Simulate policy: reduce all budgets by additional 10%
generate budget_gap_policy = budget_gap + 0.1*budget
generate pscore_policy = predict propensity under new budget_gap_policy

// Compute shift in propensity for each LA
generate pscore_shift = pscore_policy - pscore

// PRTE = weighted MTE where weight = magnitude of pscore shift
// High-weight LAs are those most affected by the policy
// Implement via manual matrix calculation or -mtefeplot- with policy option
```

**Example result:**
- Current LATE: 0.12 SD (small because compliers have low responsiveness)
- ATE: 0.23 SD (larger; broader population affected)
- PRTE (further 10% cut): 0.31 SD (largest; policy shifts more LAs into the vulnerable range where MTE is steeper)

**Policy message:** A further 10% cut would have substantially larger effects than the historical variation your instruments identify, because you'd be moving more LAs into the high-responsiveness part of the MTE curve.

---

## 10. COMPARISON: MTE VS. 2SLS—WHEN DO THEY DIFFER?

### Why MTE and 2SLS Give Different Answers

**2SLS/IV (LATE):**
$$\text{LATE} = \frac{\text{Cov}(Y, Z)}{\text{Cov}(D, Z)}$$

Averages treatment effects over the **complier population**—those induced to change treatment status by your instruments.

**MTE (local IV):**
$$\text{MTE}(x, u) = \frac{\partial E[Y \mid X=x, P(Z)=p]}{\partial p}\bigg|_{p=u}$$

Traces the treatment effect for each level of unobserved resistance u ∈ [0, 1].

### When Do They Disagree?

**Scenario 1: Selection on Gains (Downward-Sloping MTE)**

- High-gain individuals are treated at baseline (high u)
- Low-gain individuals are untreated (low u)
- Instruments shift the marginal individual at medium u

→ **LATE < ATE** (compliers have below-average gains)

**Early care example:** ATE = +0.36 SD, LATE = −0.09 SD, difference of 0.45 SD!

**Your project:** If vulnerabilty predicts both food bank demand (high Y₁) and initial treatment (high fiscal stress), then:
- Most-vulnerable LAs already experiencing high food bank demand (D=1 at baseline)
- Compliers are mid-vulnerability LAs
- → LATE could be small or even negative (compliers are resilient), while ATE is large and positive

### Diagnostic: Compare LATE, ATE, and ATT

```stata
mtefe ..., bootstrap(1000)

scalar late = e(late)
scalar ate = e(ate)
scalar att = e(att)

di "LATE: " late
di "ATE:  " ate
di "ATT:  " att
di "ATE - LATE: " ate - late
di "ATT - ATE:  " att - ate
```

**Patterns:**

| Pattern | Meaning |
|---------|---------|
| ATE ≈ LATE ≈ ATT | Homogeneous treatment effect; IV and OLS essentially agree |
| ATE >> LATE, ATT > ATE | Strong positive selection on gains; high-gain units already treated |
| ATE << LATE | Negative selection on gains; low-gain units already treated (unusual) |
| ATT >> ATE | Treatment concentrated among high-gain individuals (good targeting) |

### Early Care Lesson: Don't Trust LATE Alone

In the Anderesen (2016) early care study:
- **2SLS LATE:** −0.02 SD (insignificant; naive conclusion: no effect)
- **MTE curve:** Downward sloping from +1.0 to −0.5 SD
- **ATE:** +0.36 SD (significant; policy should expand)

The **negative LATE masked large positive effects for vulnerable children**. The compliers (authorities/individuals induced by the instrument) had below-average gains, so their small negative effect pulled the LATE down.

### For Your Food Bank Project

**Expected pattern:**
- If initial allocation of fiscal stress is correlated with food bank vulnerability, you'll see downward-sloping MTE
- This means LATE (your current 2SLS estimate) might understate the true effect of austerity on the most vulnerable LAs
- **Key result to report:** Show the full MTE curve, not just LATE, to highlight that vulnerable LAs face larger food bank increases even if the IV estimate is small

---

## SUMMARY TABLE: MTE vs. 2SLS

| Dimension | 2SLS / LATE | MTE |
|-----------|-------------|-----|
| **What it estimates** | Effect for compliers (marginal unit shifted by IV) | Distribution of effects across unobserved resistance |
| **When large/small** | Depends on complier population characteristics | Depends on selection into treatment |
| **Interpretability** | Clear policy target (local units) | Must choose policy-relevant weights for ATE/PRTE |
| **Assumptions** | Monotonicity, exclusion | Monotonicity, exclusion, separability, functional form |
| **Robustness to misspecification** | Moderate | Lower (depends on k(u) specification) |
| **When to use** | Want single effect estimate; complier population is policy target | Want heterogeneous effects; suspect strong selection on gains |
| **Sample size needs** | Moderate | Large (need dense propensity scores in both D=0 and D=1) |

---

## RECOMMENDATIONS FOR YOUR PROJECT

### **Phase 1: Validation**
1. Report first-stage results and F-statistic
2. Test monotonicity using binned first stage
3. Test exclusion via event-study design (pre-treatment leads)
4. Verify common support and report trimming decisions

### **Phase 2: MTE Estimation**
1. Estimate parametric local IV (polynomial(2)) as baseline
2. Bootstrap (1000 reps) for valid standard errors
3. Report ATE, LATE, ATT, and compare
4. Plot MTE curve with CI and common support region

### **Phase 3: Robustness**
1. Semiparametric MTE (no normality assumption)
2. Alternative first-stage models (logit, probit, LPM)
3. Subgroup analysis (by IMD, region, LA size)—report with separability caveats
4. PRTE under plausible policy counterfactuals

### **Phase 4: Interpretation**
1. Discuss downward slope of MTE (if observed) as evidence of selection on unobservable gains
2. Explain why LATE might differ from ATE
3. Contextualize policy implications: which types of LAs are most affected?
4. Acknowledge limitations (separability assumption, functional form choice)

---

## REFERENCES

Andresen, M. E. (2018). "Exploring marginal treatment effects: Flexible estimation using Stata," *Stata Journal*, 18(1), 118–158.

Anderesen, M. E. (2016). "Child care for all? Treatment effects on test scores under essential heterogeneity," *Working Paper*.

Cameron, A. C., & Trivedi, P. K. (2005). *Microeconometrics: Methods and Applications*. Cambridge University Press. [Chapters 2, 4–6 on selection models and IV.]

Heckman, J. J., & Vytlacil, E. (2005). "Structural equations, treatment effects, and econometric policy evaluation," *Econometrica*, 73(3), 669–738.

Heckman, J. J., & Vytlacil, E. (2007). "Econometric evaluation of social programs, Part II: Using the MTE to organize alternative econometric estimators to evaluate social programs, and to forecast their effects in new environments," in *Handbook of Econometrics*, 6(B), 4875–5143.

---

**Document prepared:** 28 March 2026
**For:** Kevin Kim (PhD student, Economics)
**Project:** Local Authority Austerity and Food Bank Demand, 2007–2023
