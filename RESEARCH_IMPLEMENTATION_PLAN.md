# Research Implementation Plan: Trade Vulnerability & Conflict Intensity

## Project Overview
**Research Question:** Does trade vulnerability between states affect the intensity of militarized conflict when disputes occur?

**Current Status:** Descriptive tables complete; need full analysis implementation

---

## Phase 1: Data Integration ✓ (Currently Have)
- [x] COW Major Powers dataset
- [x] COW Direct Contiguity dataset
- [x] Dyadic MID dataset v4.03
- [x] Politically relevant dyads construction

---

## Phase 2: Add Trade Data & Key Variables (NEEDED)

### 2A. Trade Data Sources
**Primary Options:**
1. **COW Trade Dataset v4.0** (bilateral trade flows 1870-2014)
   - Variables: `flow1` (imports from partner), `flow2` (exports to partner)
   - Available at: https://correlatesofwar.org/data-sets/bilateral-trade/

2. **IMF Direction of Trade Statistics** (alternative/supplement)
   - More complete recent coverage
   - Available through IMF data portal

### 2B. Trade Vulnerability Measures (Independent Variables)
Create dyad-level trade dependency measures:

1. **Bilateral trade dependence:**
   - `trade_dep_A = (imports_from_B + exports_to_B) / GDP_A`
   - `trade_dep_B = (imports_from_A + exports_to_A) / GDP_B`

2. **Asymmetric dependence (key theoretical variable):**
   - `trade_asymmetry = |trade_dep_A - trade_dep_B|`
   - `vulnerability_ratio = max(trade_dep_A, trade_dep_B) / min(trade_dep_A, trade_dep_B)`

3. **Alternative specifications:**
   - Lower dependence (less vulnerable state)
   - Higher dependence (more vulnerable state)
   - Sum of dependencies (total interdependence)

### 2C. Control Variables (Essential for causal inference)

**Economic Controls:**
- GDP (logged) for both states → COW National Material Capabilities
- GDP per capita (development level)
- Economic growth rates

**Political Controls:**
- Regime type (democracy scores) → Polity IV or V-Dem
- Domestic political instability
- Alliance membership → COW Formal Alliances

**Strategic Controls:**
- Military capabilities → COW CINC scores
- Capability ratio (power imbalance)
- Nuclear weapons status

**Conflict History:**
- Previous MIDs between dyad
- Years since last MID
- Rivalry status

**Geographic Controls:**
- Distance between capitals
- Contiguity type (already have)
- Regional dummies

---

## Phase 3: Statistical Analysis (NEEDED)

### 3A. Dependent Variable Specification
**MID Hostility Level** (ordinal: 2=threat → 5=war)

**Model Choice:** Ordered logistic regression (or ordered probit)
- Accounts for ordinal nature of escalation
- Produces proportional odds ratios

### 3B. Main Regression Models

**Model 1: Baseline (controls only)**
```
Hostility ~ Contiguity + Major_Power + CINC_Ratio + Alliance + Year_FE
```

**Model 2: Trade dependence (symmetric)**
```
+ Trade_Total + Trade_Growth
```

**Model 3: Trade vulnerability (asymmetric - MAIN MODEL)**
```
+ Trade_Asymmetry + Trade_Lower + Trade_Higher
```

**Model 4: Interaction effects**
```
+ Trade_Asymmetry × Major_Power
+ Trade_Asymmetry × Democracy_Min
```

**Model 5: Full specification**
```
All variables + GDP_Ratio + Democracy_Lower + Previous_MIDs
```

### 3C. Estimation Strategy
1. Cluster-robust standard errors (by dyad)
2. Year fixed effects (control for temporal trends)
3. Alternative: Dyad random effects

### 3D. Robustness Checks
- **Alternative DVs:** Binary (war/no war), continuous (battle deaths)
- **Subsample analyses:**
  - Contiguous dyads only
  - Major power dyads only
  - Post-Cold War (1991-2014) vs. Cold War (1973-1990)
  - Democratic dyads vs. mixed dyads
- **Alternative specifications:**
  - Lagged trade variables (t-1)
  - Three-year moving averages
  - Exclude outliers (top 1% trade dependence)

---

## Phase 4: Results Presentation (NEEDED)

### 4A. Regression Tables
**Table 6: Main Results - Trade Vulnerability and Conflict Escalation**
- 5 models (baseline → full specification)
- Coefficients, standard errors, significance stars
- Pseudo R², log-likelihood, N observations
- Formatted for publication (APA style)

**Table 7: Marginal Effects at Representative Values**
- Predicted probabilities of each hostility level
- At low/mean/high trade asymmetry
- With confidence intervals

**Table 8: Robustness Checks**
- Alternative specifications in columns
- Same DV, different samples/controls

### 4B. Data Visualizations
**Figure 1: Sample Composition**
- Map or network graph of politically relevant dyads

**Figure 2: Trade Dependence Distribution**
- Histogram/density plot of trade vulnerability measures
- By conflict vs. non-conflict dyads

**Figure 3: Predicted Probabilities (MAIN FIGURE)**
- X-axis: Trade asymmetry (low → high)
- Y-axis: Predicted probability
- Separate lines for each hostility level
- With 95% confidence intervals

**Figure 4: Marginal Effects**
- Change in predicted probability by key variables
- Horizontal bar chart with confidence intervals

**Figure 5: Subsample Analysis**
- Coefficients across different subsamples
- Forest plot format

---

## Phase 5: Implementation Structure

### File Organization
```
COW-Methods-Tables/
├── scripts/
│   ├── 01_data_loading.R          (current script, refactored)
│   ├── 02_trade_processing.R      (NEW - trade data integration)
│   ├── 03_control_variables.R     (NEW - add GDP, democracy, etc.)
│   ├── 04_variable_construction.R (NEW - create IVs/controls)
│   ├── 05_descriptive_analysis.R  (current tables 1-5)
│   ├── 06_regression_analysis.R   (NEW - main models)
│   ├── 07_robustness_checks.R     (NEW - alternative specs)
│   ├── 08_visualization.R         (NEW - plots/figures)
│   └── 09_master_script.R         (NEW - run all analyses)
│
├── output/
│   ├── tables/
│   │   ├── methods_tables.html    (current)
│   │   ├── regression_results.html (NEW)
│   │   ├── robustness_checks.html  (NEW)
│   │   └── *.csv exports
│   │
│   ├── figures/
│   │   ├── fig1_sample_map.pdf
│   │   ├── fig2_trade_distribution.pdf
│   │   ├── fig3_predicted_probs.pdf   (MAIN FIGURE)
│   │   ├── fig4_marginal_effects.pdf
│   │   └── fig5_subsamples.pdf
│   │
│   └── analysis_report.html       (NEW - complete results)
│
├── data/                           (existing + new)
│   ├── majors2024.csv
│   ├── contdird.csv
│   ├── dyadic_mid_4_03.csv
│   ├── trade_data_cow.csv          (NEW - to download)
│   ├── nmc_data.csv                (NEW - capabilities/GDP)
│   ├── polity5.csv                 (NEW - democracy scores)
│   └── alliances_data.csv          (NEW - COW alliances)
│
└── README.md                       (update with new analyses)
```

### Required R Packages
```r
# For ordered logit/probit models
install.packages("MASS")      # polr() function

# For robust standard errors
install.packages("sandwich")
install.packages("lmtest")

# For marginal effects
install.packages("margins")
install.packages("prediction")

# For visualization
install.packages("ggplot2")
install.packages("ggeffects")

# For publication-quality tables
install.packages("stargazer")  # or "modelsummary"
install.packages("texreg")
```

---

## Phase 6: Data Download Checklist

### Required COW Datasets (not yet integrated)
- [ ] **COW Trade v4.0** - bilateral trade flows
- [ ] **National Material Capabilities v6.0** - CINC scores, military expenditure, GDP estimates
- [ ] **Formal Alliances v4.1** - alliance memberships
- [ ] **Polity V** or **V-Dem** - democracy/regime scores
- [ ] **COW Interstate System** - state system membership dates

**Download from:** https://correlatesofwar.org/data-sets/

---

## Phase 7: Analysis Workflow

### Step-by-step execution:
1. **Download datasets** (see Phase 6)
2. **Run data processing scripts** (01-04)
3. **Generate descriptive statistics** (05 - current tables)
4. **Run regression models** (06 - main analysis)
5. **Robustness checks** (07)
6. **Create visualizations** (08)
7. **Compile final report** (09)

---

## Expected Research Outputs

### Academic Paper Components:
1. ✅ Methods section tables (Tables 1-5) - **COMPLETE**
2. ❌ Results section:
   - Table 6: Main regression results
   - Table 7: Marginal effects
   - Table 8: Robustness checks
3. ❌ Figures (3-5 publication-quality plots)
4. ❌ Online appendix:
   - Additional robustness checks
   - Descriptive statistics by subsample
   - Model diagnostics

### Dissertation/Thesis Components:
- Complete literature review integration
- Theoretical framework chapter
- Extended methodology (sample construction, measurement)
- Full results with all specifications
- Discussion and policy implications

---

## Timeline Estimate

**Quick implementation (minimal):** 2-3 days
- Download data, integrate trade variables, run basic regressions

**Complete implementation (robust):** 1-2 weeks
- Full controls, multiple specifications, publication-ready output

**Publication-ready research:** 2-4 weeks
- Includes robustness checks, visualizations, writing/revision

---

## Next Steps

**Immediate priorities:**
1. Download COW Trade dataset v4.0
2. Download National Material Capabilities (for GDP/CINC)
3. Download Polity V (for democracy scores)
4. Integrate trade data into dyad-year observations
5. Construct trade vulnerability measures
6. Run first regression model (ordered logit)

**Questions to clarify:**
- What is your theory about trade asymmetry? (Higher asymmetry → more/less escalation?)
- Which control variables are most important for your argument?
- Do you have access to Stata/R for ordered logit models?
- Timeline for completion (conference paper, thesis, publication)?
- Any specific robustness checks required by your advisor/committee?

---

## Key References for Methods

**Ordered logit models:**
- Long, J. S., & Freese, J. (2014). *Regression models for categorical dependent variables using Stata* (3rd ed.).

**Trade and conflict:**
- Barbieri, K. (2002). *The liberal illusion: Does trade promote peace?*
- Gartzke, E., Li, Q., & Boehmer, C. (2001). Investing in the peace: Economic interdependence and international conflict. *International Organization*, 55(2), 391-438.

**Political relevance:**
- Lemke, D., & Reed, W. (2001). The relevance of politically relevant dyads. *Journal of Conflict Resolution*, 45(1), 126-144.

---

*This plan provides a complete roadmap for scaling up from descriptive tables to full causal analysis.*
