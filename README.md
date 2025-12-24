# Trade-Conflict-Tables 📊

## 🆕 What's New: Complete Research Implementation

This project now includes a **full research analysis pipeline** examining **how economic interdependence affects the escalation of militarized interstate disputes (MIDs)**. It builds on the politically relevant dyads framework (Lemke & Reed, 2001) using Correlates of War (COW) data from 1973–2014.

**Original:** Descriptive statistics tables (Tables 1-5) ✅
**NEW:** Complete causal analysis with regression models, visualizations, and publication-ready outputs ⚡

### Key Additions:
- ✅ **Trade vulnerability measures** (bilateral dependence, asymmetry)
- ✅ **Ordered logit regression models** (tests main hypothesis)
- ✅ **Control variables** (GDP, democracy, capabilities, alliances)
- ✅ **Predicted probabilities** and marginal effects
- ✅ **Publication-quality figures** (5 figures in PDF/PNG)
- ✅ **Modular code structure** (easy to customize and extend)
- ✅ **Comprehensive documentation** (usage guide + implementation plan)

### Research Question

> Does trade vulnerability between states affect the intensity of militarized conflict when disputes occur?

## 📊 Tables Generated

| Table | Description |
|-------|-------------|
| **Table 1** | Composition of politically relevant dyads (contiguous vs. major power) |
| **Table 2** | Major powers in sample period with COW codes |
| **Table 3** | Distribution of contiguity types (land border, water distance) |
| **Table 4** | MID hostility levels—the dependent variable (threat → war) |
| **Table 5** | Sample descriptive statistics |

## 📁 Repository Structure

```
COW-Methods-Tables/
├── README.md                                    # This file
├── USAGE_GUIDE.md                               # Detailed usage instructions
├── RESEARCH_IMPLEMENTATION_PLAN.md              # Complete research roadmap
├── LICENSE
│
├── Trade Conflict Tables R - DSR Analysis README.R  # Original descriptive tables script
│
├── scripts/                                     # Modular analysis pipeline
│   ├── 00_master_analysis.R                     # Orchestrates all modules
│   ├── 02_trade_processing.R                    # Trade data integration
│   ├── 03_control_variables.R                   # Add GDP, democracy, capabilities
│   ├── 06_regression_analysis.R                 # Ordered logit models
│   └── 08_visualization.R                       # Publication figures
│
├── data/                                        # Input data (download separately)
│   ├── majors2024.csv                           # COW major powers
│   ├── contdird.csv                             # Direct contiguity
│   ├── dyadic_mid_4_03.csv                      # Militarized disputes
│   ├── trade_data_cow.csv                       # (Required) Bilateral trade
│   ├── nmc_data.csv                             # (Required) Capabilities/GDP
│   ├── polity5.csv                              # (Required) Democracy scores
│   └── alliance_v4_1.csv                        # (Required) Alliances
│
└── output/                                      # Generated files
    ├── tables/
    │   ├── methods_tables.html                  # Tables 1-5 (descriptive)
    │   ├── regression_results.html              # Main regression results
    │   └── table1-5_*.csv                       # Individual CSV tables
    ├── figures/
    │   ├── fig1_trade_asymmetry.pdf             # Trade distribution
    │   ├── fig2_predicted_probs.pdf             # Main substantive figure
    │   ├── fig3_conflict_by_type.pdf            # Descriptive
    │   ├── fig4_trade_trends.pdf                # Temporal trends
    │   └── fig5_coefficients.pdf                # Coefficient plot
    └── regression_models.RData                  # Saved models
```

## 📚 Data Sources

| Dataset | Source | Description |
|---------|--------|-------------|
| Major Powers | [COW Project](https://correlatesofwar.org/) | Major power status by country-year |
| Direct Contiguity v3.2 | [COW Project](https://correlatesofwar.org/) | Land/water borders between states |
| Dyadic MID v4.03 | [Maoz et al. (2019)](https://correlatesofwar.org/) | Militarized interstate disputes |

**Note:** Raw COW data files not included. Download from [Correlates of War](https://correlatesofwar.org/data-sets/).

## 🔬 Methodology

### Politically Relevant Dyads

A dyad is included if:
1. **Contiguous**: States share a land border or ≤400 miles of water, OR
2. **Major Power**: At least one state is a major power (can project force globally)

### Sample Period: 1973–2014

- **Start**: 1973 (end of Bretton Woods gold convertibility)
- **End**: 2014 (data availability)
- **Rationale**: Consistent international economic/monetary system

### Dependent Variable

**MID Hostility Level** (1–5 scale):
- 2: Threat to use force
- 3: Display of force
- 4: Use of force
- 5: Interstate war (≥1,000 battle deaths)

## 🛠️ Requirements

**For descriptive tables only (original script):**
- R 4.0+
- Base R only (no external packages required)

**For complete analysis (NEW - regression models + figures):**
- R 4.0+
- Required packages: `MASS`, `sandwich`, `lmtest`, `ggplot2`
- Optional: `stargazer` (for publication tables)

```r
# Install required packages
install.packages(c("MASS", "sandwich", "lmtest", "ggplot2", "stargazer"))
```

## 🚀 Usage

### Complete Analysis (NEW - Full Research Implementation)

```r
# Navigate to project directory
setwd("path/to/COW-Methods-Tables")

# Run complete analysis pipeline
source("scripts/00_master_analysis.R")
```

This runs the **full research analysis** including:
- Descriptive statistics (Tables 1-5)
- Trade vulnerability measures
- Control variables integration
- **Ordered logit regression models**
- Predicted probabilities and marginal effects
- Publication-quality visualizations

**See [`USAGE_GUIDE.md`](USAGE_GUIDE.md) for detailed instructions**

### Descriptive Tables Only (Original)

```r
# Set working directory to folder with data files
setwd("path/to/data")

# Run original descriptive tables script
source("Trade Conflict Tables R - DSR Analysis README.R")
```

### Output Files

| File | Format | Use |
|------|--------|-----|
| `methods_tables.html` | HTML | Descriptive tables (open in browser, copy to Word) |
| `regression_results.html` | HTML | **Main regression results** |
| `table1-5_*.csv` | CSV | Individual tables for Excel |
| `output/figures/*.pdf` | PDF | **Publication-quality figures** |
| `regression_models.RData` | R data | Saved models for post-estimation |

## 📖 Key References

- Lemke, D., & Reed, W. (2001). The relevance of politically relevant dyads. *Journal of Conflict Resolution*, 45(1), 126–144.
- Maoz, Z., et al. (2019). The dyadic militarized interstate disputes (MIDs) dataset. *Journal of Conflict Resolution*, 63(3), 811–835.
- Stinnett, D. M., et al. (2002). The Correlates of War (COW) project direct contiguity data. *Conflict Management and Peace Science*, 19(2), 59–67.

## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

---

*Part of research on trade vulnerability and conflict intensity in the international system.*
