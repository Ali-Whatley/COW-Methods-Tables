# Usage Guide: Trade Vulnerability & Conflict Intensity Analysis

## Quick Start

### Option 1: Run Complete Analysis (Recommended)

```r
# Navigate to project directory
setwd("path/to/COW-Methods-Tables")

# Run master script (orchestrates all modules)
source("scripts/00_master_analysis.R")
```

This will:
- Load all required data
- Process trade and control variables
- Generate descriptive tables (Tables 1-5)
- Run regression models (ordered logit)
- Create visualizations
- Save all outputs to `output/` directory

### Option 2: Run Individual Modules

```r
# Set parameters
START_YEAR <- 1973
END_YEAR <- 2014

# Load base data (original script)
source("Trade Conflict Tables R - DSR Analysis README.R")

# Add trade variables
source("scripts/02_trade_processing.R")

# Add controls
source("scripts/03_control_variables.R")

# Run regressions
source("scripts/06_regression_analysis.R")

# Create visualizations
source("scripts/08_visualization.R")
```

---

## Required Data Files

### Currently Included in Your Script:
- ✅ `majors2024.csv` - COW Major Powers dataset
- ✅ `contdird.csv` - COW Direct Contiguity v3.2
- ✅ `dyadic_mid_4_03.csv` - Dyadic MID dataset v4.03

### Required for Complete Analysis:

**Place these files in the `data/` directory:**

1. **COW Trade Dataset v4.0**
   - File: `trade_data_cow.csv` or `bilateral_trade_v4.csv`
   - Download: https://correlatesofwar.org/data-sets/bilateral-trade/
   - Variables needed: `ccode1`, `ccode2`, `year`, `flow1`, `flow2`

2. **National Material Capabilities v6.0**
   - File: `nmc_data.csv` or `NMC_v6_0.csv`
   - Download: https://correlatesofwar.org/data-sets/national-material-capabilities/
   - Used for: CINC scores, military capabilities, GDP proxy

3. **Polity V Dataset**
   - File: `polity5.csv`
   - Download: https://www.systemicpeace.org/inscrdata.html
   - Used for: Democracy/autocracy scores

4. **COW Formal Alliances v4.1**
   - File: `alliance_v4_1.csv`
   - Download: https://correlatesofwar.org/data-sets/formal-alliances/
   - Used for: Alliance membership indicator

**Note:** The scripts will run with placeholder data if these files are missing, but results will NOT be valid for publication.

---

## Understanding the Module Structure

### Module 1: Data Loading (Original Script)
**File:** `Trade Conflict Tables R - DSR Analysis README.R`

**What it does:**
- Loads COW major powers, contiguity, and MID data
- Constructs politically relevant dyads (1973-2014)
- Creates Tables 1-5 (descriptive statistics)

**Output:**
- `pr_dyads` - Politically relevant dyad-year dataset
- `mids_in_pr` - MIDs occurring in PR dyads
- `output/methods_tables.html` - Formatted tables

### Module 2: Trade Data Integration
**File:** `scripts/02_trade_processing.R`

**What it does:**
- Loads COW bilateral trade data
- Calculates trade volumes and growth rates
- Computes trade dependence measures (% of GDP)
- Creates asymmetry variables (key independent variable)

**Key Variables Created:**
- `trade_total` - Total bilateral trade (millions USD)
- `trade_dep_lower` - Less vulnerable state's dependence
- `trade_dep_higher` - More vulnerable state's dependence
- `trade_asymmetry` - Absolute difference in dependencies
- `trade_vulnerability` - Ratio of higher/lower dependence

**Output:** `pr_dyads_with_trade`

### Module 3: Control Variables
**File:** `scripts/03_control_variables.R`

**What it does:**
- Adds military capability ratios (CINC)
- Adds democracy scores (Polity)
- Adds alliance indicators
- Creates conflict history variables

**Key Variables Created:**
- `cinc_ratio` - Capability imbalance
- `democracy_min` - Lower polity score in dyad
- `joint_democracy` - Both states democratic
- `alliance` - Formal alliance exists
- `prev_mid` - Previous MID in dyad

**Output:** `pr_dyads_full`

### Module 6: Regression Analysis
**File:** `scripts/06_regression_analysis.R`

**What it does:**
- Estimates ordered logistic regression models
- Tests trade vulnerability hypothesis
- Computes cluster-robust standard errors
- Creates regression results tables

**Models Estimated:**
1. **Model 1:** Baseline (geographic + strategic controls)
2. **Model 2:** + Bilateral trade volume
3. **Model 3:** + Trade asymmetry (**MAIN MODEL**)
4. **Model 4:** + Interaction effects
5. **Model 5:** Full specification with year fixed effects

**Output:**
- `output/regression_models.RData` - Saved model objects
- `output/tables/regression_results.html` - Formatted table
- Console output with coefficient estimates

### Module 8: Visualization
**File:** `scripts/08_visualization.R`

**What it does:**
- Creates publication-quality figures
- Generates predicted probability plots
- Visualizes trade-conflict relationships

**Figures Created:**
- **Figure 1:** Trade asymmetry distribution by conflict status
- **Figure 2:** Predicted probabilities by trade asymmetry
- **Figure 3:** Conflict by dyad type
- **Figure 4:** Trade trends over time
- **Figure 5:** Coefficient plot (Model 3)

**Output:** PDF and PNG files in `output/figures/`

---

## Installing Required R Packages

```r
# Core packages for analysis
install.packages("MASS")       # Ordered logit (polr function)
install.packages("sandwich")   # Robust standard errors
install.packages("lmtest")     # Coefficient tests

# Optional but recommended
install.packages("ggplot2")    # Visualizations
install.packages("stargazer")  # Publication tables

# Alternative table packages
install.packages("texreg")
install.packages("modelsummary")

# For marginal effects (advanced)
install.packages("margins")
install.packages("prediction")
```

---

## Output Files Reference

### Tables (output/tables/)
- `methods_tables.html` - Tables 1-5 (descriptive statistics)
- `table1-5_*.csv` - Individual tables as CSV
- `regression_results.html` - Main regression results (if stargazer available)

### Figures (output/figures/)
- `fig1_trade_asymmetry.pdf/.png` - Trade distribution
- `fig2_predicted_probs.pdf/.png` - **Main substantive figure**
- `fig3_conflict_by_type.pdf/.png` - Descriptive
- `fig4_trade_trends.pdf/.png` - Temporal trends
- `fig5_coefficients.pdf/.png` - Coefficient plot

### Data Objects
- `output/regression_models.RData` - All model objects for post-estimation

---

## Interpreting Results

### Main Hypothesis Test (Model 3)

**Research Question:** Does trade vulnerability affect conflict escalation?

**Key Variable:** `trade_asymmetry`

**Expected Finding:**
- If coefficient is **positive**: Higher asymmetry → greater escalation
  - Interpretation: Vulnerable states are coerced, conflicts intensify
- If coefficient is **negative**: Higher asymmetry → less escalation
  - Interpretation: Interdependence creates peace, or powerful states restrain

**Statistical Significance:**
- p < 0.05: Evidence for relationship
- p < 0.01: Strong evidence
- p < 0.001: Very strong evidence

### Interpreting Ordered Logit Coefficients

**Coefficients represent:**
- Log-odds of moving to a higher conflict intensity category
- Positive coefficient → increases probability of escalation
- Negative coefficient → decreases probability of escalation

**To get substantive effects:**
1. **Odds ratios:** `exp(coefficient)`
   - Example: coef = 0.5 → OR = 1.65 → 65% increase in odds
2. **Predicted probabilities:** Use Figure 2
   - Shows actual probability of each outcome (threat/display/force/war)
3. **Marginal effects:** Change in probability for 1-unit increase in X

---

## Customizing the Analysis

### Change Sample Period

Edit in master script or at top of any module:

```r
START_YEAR <- 1980  # Change from 1973
END_YEAR   <- 2010  # Change from 2014
```

### Add Additional Control Variables

In `scripts/03_control_variables.R`, add:

```r
# Example: Add GDP data from external source
gdp_external <- read.csv("data/world_bank_gdp.csv")
pr_dyads_full <- merge(pr_dyads_full, gdp_external, ...)
```

### Run Subsample Analysis

```r
# Example: Contiguous dyads only
regression_sample_contig <- regression_sample[regression_sample$is_contiguous == TRUE, ]

# Re-run Model 3 on subsample
model3_contig <- polr(
  conflict_intensity_ordered ~ ...,
  data = regression_sample_contig,
  method = "logistic"
)
```

### Alternative Model Specifications

```r
# Binary outcome: War vs. lower levels
regression_sample$war_binary <- ifelse(
  regression_sample$conflict_intensity == 5, 1, 0
)

# Run logistic regression
model_war <- glm(
  war_binary ~ trade_asymmetry + ...,
  data = regression_sample,
  family = binomial(link = "logit")
)
```

---

## Troubleshooting

### Error: "Cannot find data files"

**Solution:** Ensure data files are in correct location:
```r
# Check current working directory
getwd()

# Should show: /path/to/COW-Methods-Tables

# List files in data directory
list.files("data/")
```

### Error: "Package 'MASS' not found"

**Solution:**
```r
install.packages("MASS")
library(MASS)
```

### Error: "Model failed to converge"

**Possible causes:**
1. Insufficient variation in variables
2. Perfect prediction (separation)
3. Too many parameters for sample size

**Solutions:**
- Check variable distributions: `summary(regression_sample)`
- Remove year fixed effects (Model 5)
- Increase sample size (expand time period)
- Check for multicollinearity: `cor(regression_sample[, numeric_vars])`

### Warning: "Using placeholder data"

**Meaning:** Real data file not found, using fake data for testing

**Solution:** Download required COW datasets (see "Required Data Files" above)

---

## Next Steps for Publication

### 1. Verify Data Quality
- [ ] Download all required COW datasets
- [ ] Merge real trade data
- [ ] Check for missing values: `summary(pr_dyads_full)`
- [ ] Verify sample size matches expectations

### 2. Run Robustness Checks
- [ ] Alternative time periods
- [ ] Different model specifications
- [ ] Subsample analyses (contiguous only, major powers only)
- [ ] Alternative dependent variable (binary war, continuous deaths)

### 3. Create Publication Tables
- [ ] Format tables with stargazer or modelsummary
- [ ] Add descriptive statistics table for all variables
- [ ] Create correlation matrix table
- [ ] Add robustness checks table

### 4. Finalize Figures
- [ ] Ensure all figures are publication-quality (300 DPI PNG)
- [ ] Add informative titles and axis labels
- [ ] Check color schemes (colorblind-friendly)
- [ ] Create combined figure panels if needed

### 5. Write Analysis Report
- [ ] Describe sample construction
- [ ] Present descriptive statistics
- [ ] Report main regression results
- [ ] Discuss substantive interpretation
- [ ] Address limitations and future research

---

## Additional Resources

**COW Project:** https://correlatesofwar.org/
- All datasets and codebooks
- Methodological papers

**Polity Project:** https://www.systemicpeace.org/
- Democracy scores and documentation

**Ordered Logit Resources:**
- Long & Freese (2014): *Regression Models for Categorical DVs*
- UCLA Statistical Consulting: https://stats.oarc.ucla.edu/r/dae/ordinal-logistic-regression/

**R Documentation:**
- MASS package: `?polr`
- sandwich package: `?vcovCL`
- ggplot2 documentation: https://ggplot2.tidyverse.org/

---

## Support and Questions

**For issues with this code:**
- Review `RESEARCH_IMPLEMENTATION_PLAN.md` for detailed methodology
- Check console output for specific error messages
- Verify data file locations and formats

**For questions about COW data:**
- Consult COW project website and codebooks
- Check variable definitions and measurement

**For statistical questions:**
- Consult with your advisor/committee
- Review methodological literature on ordered logit
- Consider consulting with a statistician for complex specifications

---

*Last updated: 2025*
*For research implementation plan, see: `RESEARCH_IMPLEMENTATION_PLAN.md`*
