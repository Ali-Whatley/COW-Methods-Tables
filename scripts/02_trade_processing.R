#===============================================================================
#
#  MODULE 2: TRADE DATA INTEGRATION & VULNERABILITY MEASURES
#
#  Description: Processes bilateral trade data and constructs trade vulnerability
#               and asymmetric dependence measures for each dyad-year
#
#  Input:  - COW Trade dataset v4.0 (bilateral_trade_v4.csv or trade_data_cow.csv)
#          - pr_dyads dataframe from Module 1
#
#  Output: - pr_dyads_with_trade (original dyads + trade variables)
#
#  Trade Variables Created:
#    1. trade_total          → Total bilateral trade (imports + exports)
#    2. trade_dep_a          → State A's trade dependence on B
#    3. trade_dep_b          → State B's trade dependence on A
#    4. trade_dep_lower      → Lower dependence (less vulnerable state)
#    5. trade_dep_higher     → Higher dependence (more vulnerable state)
#    6. trade_asymmetry      → Absolute difference in dependencies
#    7. trade_vulnerability  → Ratio of higher/lower dependence
#    8. trade_growth         → % change from previous year
#
#===============================================================================

cat("  Loading trade data...\n")

#-------------------------------------------------------------------------------
# LOAD TRADE DATA
#-------------------------------------------------------------------------------

# Try multiple possible file locations/names
trade_files <- c(
  "data/trade_data_cow.csv",
  "data/bilateral_trade_v4.csv",
  "trade_data_cow.csv",
  "bilateral_trade_v4.csv"
)

trade_file <- NULL
for (f in trade_files) {
  if (file.exists(f)) {
    trade_file <- f
    break
  }
}

if (is.null(trade_file)) {
  cat("  ⚠ WARNING: COW Trade dataset not found.\n")
  cat("    Searched for:\n")
  cat(paste("     -", trade_files), sep = "\n")
  cat("\n")
  cat("    Download from: https://correlatesofwar.org/data-sets/bilateral-trade/\n")
  cat("    Expected columns: ccode1, ccode2, year, flow1, flow2\n")
  cat("      - flow1 = imports by ccode1 from ccode2 (millions USD)\n")
  cat("      - flow2 = imports by ccode2 from ccode1 (millions USD)\n")
  cat("\n")
  cat("  Creating placeholder trade data for demonstration...\n\n")

  # Create synthetic placeholder data (NOT FOR REAL ANALYSIS)
  # This allows the script to run for testing purposes
  set.seed(12345)
  trade_data <- data.frame(
    ccode1 = pr_dyads$ccode1,
    ccode2 = pr_dyads$ccode2,
    year = pr_dyads$year,
    flow1 = runif(nrow(pr_dyads), 0, 1000),  # FAKE DATA
    flow2 = runif(nrow(pr_dyads), 0, 1000)   # FAKE DATA
  )

  cat("    ⚠⚠⚠ WARNING: Using FAKE trade data - results are INVALID ⚠⚠⚠\n\n")

} else {
  # Load actual trade data
  trade_data <- read.csv(trade_file)
  cat("  ✓ Trade data loaded:", trade_file, "\n")
  cat("    Observations:", nrow(trade_data), "\n")
  cat("    Years:", min(trade_data$year, na.rm=TRUE), "-",
      max(trade_data$year, na.rm=TRUE), "\n")
}

#-------------------------------------------------------------------------------
# FILTER TRADE DATA TO ANALYSIS PERIOD
#-------------------------------------------------------------------------------

trade_data <- trade_data[
  trade_data$year >= START_YEAR &
  trade_data$year <= END_YEAR,
]

# Ensure consistent column names
# COW Trade uses: importer1, importer2 OR flow1, flow2
if ("importer1" %in% names(trade_data)) {
  names(trade_data)[names(trade_data) == "importer1"] <- "flow1"
}
if ("importer2" %in% names(trade_data)) {
  names(trade_data)[names(trade_data) == "importer2"] <- "flow2"
}

# State codes
if ("state1" %in% names(trade_data)) {
  names(trade_data)[names(trade_data) == "state1"] <- "ccode1"
}
if ("state2" %in% names(trade_data)) {
  names(trade_data)[names(trade_data) == "state2"] <- "ccode2"
}

cat("  Filtered to", START_YEAR, "-", END_YEAR, ":",
    nrow(trade_data), "trade flows\n")

#-------------------------------------------------------------------------------
# LOAD GDP DATA (for calculating trade dependence)
#-------------------------------------------------------------------------------

cat("  Loading GDP data...\n")

# Try to load National Material Capabilities (contains GDP estimates)
nmc_files <- c(
  "data/nmc_data.csv",
  "data/NMC_v6_0.csv",
  "nmc_data.csv"
)

nmc_file <- NULL
for (f in nmc_files) {
  if (file.exists(f)) {
    nmc_file <- f
    break
  }
}

if (is.null(nmc_file)) {
  cat("  ⚠ WARNING: National Material Capabilities data not found.\n")
  cat("    Download from: https://correlatesofwar.org/data-sets/national-material-capabilities/\n")
  cat("    Using rough GDP estimates based on military expenditure...\n\n")

  # Create placeholder GDP (NOT ACCURATE - for demonstration only)
  gdp_data <- data.frame(
    ccode = unique(c(trade_data$ccode1, trade_data$ccode2)),
    year = rep(START_YEAR:END_YEAR, each = length(unique(c(trade_data$ccode1, trade_data$ccode2)))),
    gdp = runif(length(unique(c(trade_data$ccode1, trade_data$ccode2))) * (END_YEAR - START_YEAR + 1),
                10000, 1000000)  # FAKE GDP
  )

} else {
  nmc <- read.csv(nmc_file)
  cat("  ✓ NMC data loaded\n")

  # Extract GDP-related columns
  # NMC v6.0 doesn't have direct GDP, but has:
  #   - milex (military expenditure in thousands USD)
  #   - tpop (total population in thousands)
  # We can create a rough GDP proxy or use external GDP data

  # For now, create GDP proxy from military burden assumption
  # Typical military spending = 2-5% of GDP
  # This is VERY rough - better to merge with World Bank/Maddison GDP data

  gdp_data <- nmc[, c("ccode", "year", "milex", "tpop")]
  gdp_data$gdp <- gdp_data$milex / 0.03  # Assume 3% military burden (ROUGH)

  gdp_data <- gdp_data[
    gdp_data$year >= START_YEAR & gdp_data$year <= END_YEAR,
    c("ccode", "year", "gdp")
  ]

  cat("    ⚠ Using GDP proxy from military expenditure (not ideal)\n")
  cat("    Consider integrating World Bank GDP data for accuracy\n")
}

#-------------------------------------------------------------------------------
# CALCULATE BILATERAL TRADE VOLUMES
#-------------------------------------------------------------------------------

cat("  Calculating bilateral trade measures...\n")

# Total bilateral trade = flow1 + flow2
# (flow1 = A's imports from B = B's exports to A)
# (flow2 = B's imports from A = A's exports to B)
trade_data$trade_total <- trade_data$flow1 + trade_data$flow2

# Replace missing/negative values with 0
trade_data$flow1[is.na(trade_data$flow1) | trade_data$flow1 < 0] <- 0
trade_data$flow2[is.na(trade_data$flow2) | trade_data$flow2 < 0] <- 0
trade_data$trade_total[is.na(trade_data$trade_total)] <- 0

#-------------------------------------------------------------------------------
# MERGE GDP DATA FOR BOTH STATES
#-------------------------------------------------------------------------------

# Merge GDP for state 1
trade_data <- merge(
  trade_data,
  gdp_data,
  by.x = c("ccode1", "year"),
  by.y = c("ccode", "year"),
  all.x = TRUE
)
names(trade_data)[names(trade_data) == "gdp"] <- "gdp1"

# Merge GDP for state 2
trade_data <- merge(
  trade_data,
  gdp_data,
  by.x = c("ccode2", "year"),
  by.y = c("ccode", "year"),
  all.x = TRUE
)
names(trade_data)[names(trade_data) == "gdp"] <- "gdp2"

#-------------------------------------------------------------------------------
# CALCULATE TRADE DEPENDENCE MEASURES
#-------------------------------------------------------------------------------

cat("  Computing trade dependence and asymmetry measures...\n")

# State 1's total trade with State 2
trade_data$trade1 <- trade_data$flow1 + trade_data$flow2

# State 2's total trade with State 1 (same as above)
trade_data$trade2 <- trade_data$trade1

# Trade dependence = (bilateral trade) / GDP
# Represents % of economy tied to this bilateral relationship
trade_data$trade_dep_1 <- ifelse(
  !is.na(trade_data$gdp1) & trade_data$gdp1 > 0,
  (trade_data$trade1 / trade_data$gdp1) * 100,  # As percentage
  NA
)

trade_data$trade_dep_2 <- ifelse(
  !is.na(trade_data$gdp2) & trade_data$gdp2 > 0,
  (trade_data$trade2 / trade_data$gdp2) * 100,
  NA
)

# Asymmetric dependence measures
trade_data$trade_dep_lower <- pmin(trade_data$trade_dep_1, trade_data$trade_dep_2, na.rm = TRUE)
trade_data$trade_dep_higher <- pmax(trade_data$trade_dep_1, trade_data$trade_dep_2, na.rm = TRUE)

# Asymmetry = absolute difference in dependence
trade_data$trade_asymmetry <- abs(trade_data$trade_dep_1 - trade_data$trade_dep_2)

# Vulnerability ratio = higher / lower
# (undefined if lower = 0, set to NA in that case)
trade_data$trade_vulnerability <- ifelse(
  trade_data$trade_dep_lower > 0,
  trade_data$trade_dep_higher / trade_data$trade_dep_lower,
  NA
)

# Symmetric interdependence = sum of dependencies
trade_data$trade_interdependence <- trade_data$trade_dep_1 + trade_data$trade_dep_2

#-------------------------------------------------------------------------------
# CALCULATE TRADE GROWTH (change from previous year)
#-------------------------------------------------------------------------------

# Sort data
trade_data <- trade_data[order(trade_data$ccode1, trade_data$ccode2, trade_data$year), ]

# Calculate lagged trade
trade_data$trade_total_lag <- NA
for (i in 2:nrow(trade_data)) {
  if (trade_data$ccode1[i] == trade_data$ccode1[i-1] &&
      trade_data$ccode2[i] == trade_data$ccode2[i-1] &&
      trade_data$year[i] == trade_data$year[i-1] + 1) {

    trade_data$trade_total_lag[i] <- trade_data$trade_total[i-1]
  }
}

# Growth rate (percentage)
trade_data$trade_growth <- ifelse(
  !is.na(trade_data$trade_total_lag) & trade_data$trade_total_lag > 0,
  ((trade_data$trade_total - trade_data$trade_total_lag) / trade_data$trade_total_lag) * 100,
  NA
)

#-------------------------------------------------------------------------------
# MERGE TRADE VARIABLES INTO PR DYADS
#-------------------------------------------------------------------------------

cat("  Merging trade data into politically relevant dyads...\n")

# Create matching keys
pr_dyads$merge_key <- paste(pr_dyads$ccode1, pr_dyads$ccode2, pr_dyads$year, sep = "_")
trade_data$merge_key <- paste(trade_data$ccode1, trade_data$ccode2, trade_data$year, sep = "_")

# Select trade variables to merge
trade_vars <- c(
  "merge_key",
  "trade_total",
  "trade_dep_1", "trade_dep_2",
  "trade_dep_lower", "trade_dep_higher",
  "trade_asymmetry", "trade_vulnerability",
  "trade_interdependence",
  "trade_growth"
)

# Merge (keep all PR dyads, add trade where available)
pr_dyads_with_trade <- merge(
  pr_dyads,
  trade_data[, trade_vars],
  by = "merge_key",
  all.x = TRUE
)

# For dyads with no trade data, set to 0 (no trade relationship)
trade_cols <- c("trade_total", "trade_dep_lower", "trade_dep_higher",
                "trade_asymmetry", "trade_interdependence")
for (col in trade_cols) {
  pr_dyads_with_trade[[col]][is.na(pr_dyads_with_trade[[col]])] <- 0
}

#-------------------------------------------------------------------------------
# CREATE CATEGORICAL TRADE VARIABLES (for interactions)
#-------------------------------------------------------------------------------

# High/low trade asymmetry (median split)
if (sum(!is.na(pr_dyads_with_trade$trade_asymmetry)) > 0) {
  median_asymm <- median(pr_dyads_with_trade$trade_asymmetry[
    pr_dyads_with_trade$trade_asymmetry > 0
  ], na.rm = TRUE)

  pr_dyads_with_trade$high_asymmetry <- ifelse(
    pr_dyads_with_trade$trade_asymmetry > median_asymm,
    1,
    0
  )
}

#-------------------------------------------------------------------------------
# SUMMARY STATISTICS
#-------------------------------------------------------------------------------

cat("\n  Trade data summary:\n")
cat("    PR dyads with trade data:",
    sum(!is.na(pr_dyads_with_trade$trade_total) &
        pr_dyads_with_trade$trade_total > 0), "\n")
cat("    PR dyads with NO trade:",
    sum(is.na(pr_dyads_with_trade$trade_total) |
        pr_dyads_with_trade$trade_total == 0), "\n")

if (sum(pr_dyads_with_trade$trade_total > 0, na.rm = TRUE) > 0) {
  cat("\n  Trade volume (millions USD):\n")
  cat("    Mean:",
      sprintf("%.2f", mean(pr_dyads_with_trade$trade_total[
        pr_dyads_with_trade$trade_total > 0
      ], na.rm = TRUE)), "\n")
  cat("    Median:",
      sprintf("%.2f", median(pr_dyads_with_trade$trade_total[
        pr_dyads_with_trade$trade_total > 0
      ], na.rm = TRUE)), "\n")

  cat("\n  Trade asymmetry (% GDP difference):\n")
  cat("    Mean:",
      sprintf("%.4f", mean(pr_dyads_with_trade$trade_asymmetry[
        pr_dyads_with_trade$trade_asymmetry > 0
      ], na.rm = TRUE)), "\n")
  cat("    Median:",
      sprintf("%.4f", median(pr_dyads_with_trade$trade_asymmetry[
        pr_dyads_with_trade$trade_asymmetry > 0
      ], na.rm = TRUE)), "\n")
}

cat("\n  ✓ Trade integration complete\n")

#===============================================================================
# OUTPUT: pr_dyads_with_trade
#===============================================================================

# This dataframe is now available for Module 3 (control variables)

#===============================================================================
# END OF TRADE PROCESSING MODULE
#===============================================================================
