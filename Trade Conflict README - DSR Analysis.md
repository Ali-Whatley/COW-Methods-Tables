# Trade-Conflict-Tables 📊

R script for generating publication-ready academic tables analyzing trade vulnerability and interstate conflict intensity.

## 📌 Overview

This project creates summary statistics tables for a study examining **how economic interdependence affects the escalation of militarized interstate disputes (MIDs)**. It builds on the politically relevant dyads framework (Lemke & Reed, 2001) using Correlates of War (COW) data from 1973–2014.

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
Trade-Conflict-Tables/
├── trade_conflict_tables.R    # Main analysis script
├── README.md
├── LICENSE
├── data/                      # Input data (not included—see Data Sources)
│   ├── majors2024.csv
│   ├── contdird.csv
│   └── dyadic_mid_4_03.csv
└── output/                    # Generated files
    ├── methods_tables.html
    └── table1-5_*.csv
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

- R 4.0+
- Base R only (no external packages required)

## 🚀 Usage

```r
# Set working directory to folder with data files
setwd("path/to/data")

# Run script
source("trade_conflict_tables.R")
```

### Output Files

| File | Format | Use |
|------|--------|-----|
| `methods_tables.html` | HTML | Open in browser, copy-paste to Word |
| `table1-5_*.csv` | CSV | Import to Excel for formatting |

## 📖 Key References

- Lemke, D., & Reed, W. (2001). The relevance of politically relevant dyads. *Journal of Conflict Resolution*, 45(1), 126–144.
- Maoz, Z., et al. (2019). The dyadic militarized interstate disputes (MIDs) dataset. *Journal of Conflict Resolution*, 63(3), 811–835.
- Stinnett, D. M., et al. (2002). The Correlates of War (COW) project direct contiguity data. *Conflict Management and Peace Science*, 19(2), 59–67.

## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

---

*Part of research on trade vulnerability and conflict intensity in the international system.*
