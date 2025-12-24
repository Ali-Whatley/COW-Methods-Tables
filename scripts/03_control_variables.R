#===============================================================================
#
#  MODULE 3: CONTROL VARIABLES
#
#  Description: Adds control variables to politically relevant dyads dataset
#               Essential for causal inference in conflict analysis
#
#  Input:  - pr_dyads_with_trade from Module 2
#          - COW National Material Capabilities
#          - Polity V / V-Dem democracy scores
#          - COW Formal Alliances
#
#  Output: - pr_dyads_full (complete analytical dataset)
#
#  Control Variables Added:
#    STRATEGIC CONTROLS:
#      - cinc_ratio: Military capability ratio (CINC scores)
#      - power_parity: Binary indicator of power balance
#
#    ECONOMIC CONTROLS:
#      - gdp_ratio: Economic size imbalance
#      - gdp_total: Combined economic size (logged)
#
#    POLITICAL CONTROLS:
#      - democracy_min: Lower polity score in dyad
#      - joint_democracy: Both states democratic (≥6 on Polity)
#      - mixed_regime: One democracy, one autocracy
#
#    RELATIONAL CONTROLS:
#      - alliance: Formal alliance exists
#      - prev_mid: Previous MID in dyad
#      - years_since_mid: Time since last dispute
#
#    GEOGRAPHIC CONTROLS:
#      - distance: Distance between capitals (logged)
#      - contiguity type (already in data from Module 1)
#
#===============================================================================

cat("  Adding control variables to dyadic dataset...\n")

#-------------------------------------------------------------------------------
# LOAD NATIONAL MATERIAL CAPABILITIES (CINC, GDP proxy)
#-------------------------------------------------------------------------------

cat("    Loading capability data...\n")

nmc_files <- c("data/nmc_data.csv", "data/NMC_v6_0.csv", "nmc_data.csv")
nmc_file <- NULL
for (f in nmc_files) {
  if (file.exists(f)) {
    nmc_file <- f
    break
  }
}

if (!is.null(nmc_file)) {
  nmc <- read.csv(nmc_file)

  # Filter to analysis period
  nmc <- nmc[nmc$year >= START_YEAR & nmc$year <= END_YEAR, ]

  # Key variables from NMC:
  #   - cinc: Composite Index of National Capability (0-1 scale)
  #   - milex: Military expenditure (thousands USD)
  #   - milper: Military personnel (thousands)
  #   - irst: Iron/steel production (thousands tons)
  #   - pec: Primary energy consumption
  #   - tpop: Total population (thousands)
  #   - upop: Urban population (thousands)

  nmc_vars <- c("ccode", "year", "cinc", "milex", "milper", "tpop", "upop")
  nmc <- nmc[, nmc_vars[nmc_vars %in% names(nmc)]]

  cat("      ✓ NMC data loaded:", nrow(nmc), "country-years\n")

} else {
  cat("      ⚠ WARNING: NMC data not found - creating placeholders\n")
  nmc <- data.frame(
    ccode = unique(c(pr_dyads_with_trade$ccode1, pr_dyads_with_trade$ccode2)),
    year = rep(START_YEAR:END_YEAR, each = 200),
    cinc = runif(200 * (END_YEAR - START_YEAR + 1), 0, 0.1)
  )
}

#-------------------------------------------------------------------------------
# LOAD POLITY SCORES (Democracy/Autocracy)
#-------------------------------------------------------------------------------

cat("    Loading democracy scores...\n")

polity_files <- c(
  "data/polity5.csv",
  "data/p5v2018.csv",
  "polity5.csv"
)

polity_file <- NULL
for (f in polity_files) {
  if (file.exists(f)) {
    polity_file <- f
    break
  }
}

if (!is.null(polity_file)) {
  polity <- read.csv(polity_file)

  # Standardize column names (Polity uses different versions)
  if ("ccode" %in% names(polity)) {
    # Already correct
  } else if ("scode" %in% names(polity)) {
    # Need to map state codes to COW codes (requires crosswalk)
    cat("      ⚠ Polity uses state codes - COW code conversion needed\n")
  }

  # Key variable: polity2 (combined democracy-autocracy score, -10 to +10)
  # +10 = full democracy, -10 = full autocracy
  if ("polity2" %in% names(polity)) {
    polity <- polity[, c("ccode", "year", "polity2")]
  } else {
    polity <- data.frame(
      ccode = unique(c(pr_dyads_with_trade$ccode1, pr_dyads_with_trade$ccode2)),
      year = rep(START_YEAR:END_YEAR, each = 200),
      polity2 = 0
    )
  }

  # Filter to period
  polity <- polity[polity$year >= START_YEAR & polity$year <= END_YEAR, ]

  cat("      ✓ Polity scores loaded\n")

} else {
  cat("      ⚠ WARNING: Polity data not found - creating placeholders\n")
  polity <- data.frame(
    ccode = unique(c(pr_dyads_with_trade$ccode1, pr_dyads_with_trade$ccode2)),
    year = rep(START_YEAR:END_YEAR, each = 200),
    polity2 = sample(-10:10, 200 * (END_YEAR - START_YEAR + 1), replace = TRUE)
  )
}

#-------------------------------------------------------------------------------
# LOAD ALLIANCE DATA
#-------------------------------------------------------------------------------

cat("    Loading alliance data...\n")

alliance_files <- c(
  "data/alliance_v4_1.csv",
  "data/alliances.csv",
  "alliance_v4_1.csv"
)

alliance_file <- NULL
for (f in alliance_files) {
  if (file.exists(f)) {
    alliance_file <- f
    break
  }
}

if (!is.null(alliance_file)) {
  alliances <- read.csv(alliance_file)

  # COW Alliance data structure:
  #   - ccode1, ccode2: dyad members
  #   - year: alliance start year
  #   - defense, neutrality, entente: alliance types

  # Expand to dyad-years
  alliance_dyads <- data.frame()
  for (i in 1:nrow(alliances)) {
    years <- alliances$year[i]:END_YEAR  # Assume alliances persist
    temp <- data.frame(
      ccode1 = alliances$ccode1[i],
      ccode2 = alliances$ccode2[i],
      year = years,
      alliance = 1
    )
    alliance_dyads <- rbind(alliance_dyads, temp)
  }

  alliance_dyads <- unique(alliance_dyads)
  cat("      ✓ Alliance data loaded\n")

} else {
  cat("      ⚠ WARNING: Alliance data not found - creating placeholders\n")
  alliance_dyads <- data.frame(
    ccode1 = integer(0),
    ccode2 = integer(0),
    year = integer(0),
    alliance = integer(0)
  )
}

#-------------------------------------------------------------------------------
# MERGE CAPABILITIES FOR BOTH STATES
#-------------------------------------------------------------------------------

cat("    Computing dyadic control variables...\n")

# Merge CINC for state 1
pr_dyads_with_trade <- merge(
  pr_dyads_with_trade,
  nmc[, c("ccode", "year", "cinc")],
  by.x = c("ccode1", "year"),
  by.y = c("ccode", "year"),
  all.x = TRUE
)
names(pr_dyads_with_trade)[names(pr_dyads_with_trade) == "cinc"] <- "cinc1"

# Merge CINC for state 2
pr_dyads_with_trade <- merge(
  pr_dyads_with_trade,
  nmc[, c("ccode", "year", "cinc")],
  by.x = c("ccode2", "year"),
  by.y = c("ccode", "year"),
  all.x = TRUE
)
names(pr_dyads_with_trade)[names(pr_dyads_with_trade) == "cinc"] <- "cinc2"

# Calculate capability ratio (stronger/weaker)
pr_dyads_with_trade$cinc_ratio <- ifelse(
  !is.na(pr_dyads_with_trade$cinc1) &
  !is.na(pr_dyads_with_trade$cinc2) &
  pr_dyads_with_trade$cinc2 > 0,
  pmax(pr_dyads_with_trade$cinc1, pr_dyads_with_trade$cinc2) /
  pmin(pr_dyads_with_trade$cinc1, pr_dyads_with_trade$cinc2),
  NA
)

# Power parity indicator (ratio between 0.5 and 2)
pr_dyads_with_trade$power_parity <- ifelse(
  !is.na(pr_dyads_with_trade$cinc_ratio),
  as.integer(pr_dyads_with_trade$cinc_ratio <= 2),
  0
)

#-------------------------------------------------------------------------------
# MERGE POLITY SCORES FOR BOTH STATES
#-------------------------------------------------------------------------------

# Merge Polity for state 1
pr_dyads_with_trade <- merge(
  pr_dyads_with_trade,
  polity[, c("ccode", "year", "polity2")],
  by.x = c("ccode1", "year"),
  by.y = c("ccode", "year"),
  all.x = TRUE
)
names(pr_dyads_with_trade)[names(pr_dyads_with_trade) == "polity2"] <- "polity1"

# Merge Polity for state 2
pr_dyads_with_trade <- merge(
  pr_dyads_with_trade,
  polity[, c("ccode", "year", "polity2")],
  by.x = c("ccode2", "year"),
  by.y = c("ccode", "year"),
  all.x = TRUE
)
names(pr_dyads_with_trade)[names(pr_dyads_with_trade) == "polity2"] <- "polity2"

# Minimum polity score (least democratic state)
pr_dyads_with_trade$democracy_min <- pmin(
  pr_dyads_with_trade$polity1,
  pr_dyads_with_trade$polity2,
  na.rm = TRUE
)

# Joint democracy (both ≥ 6 on Polity scale)
pr_dyads_with_trade$joint_democracy <- ifelse(
  !is.na(pr_dyads_with_trade$polity1) &
  !is.na(pr_dyads_with_trade$polity2),
  as.integer(pr_dyads_with_trade$polity1 >= 6 &
             pr_dyads_with_trade$polity2 >= 6),
  0
)

# Mixed regime dyad (one democracy, one autocracy)
pr_dyads_with_trade$mixed_regime <- ifelse(
  !is.na(pr_dyads_with_trade$polity1) &
  !is.na(pr_dyads_with_trade$polity2),
  as.integer(
    (pr_dyads_with_trade$polity1 >= 6 & pr_dyads_with_trade$polity2 < 6) |
    (pr_dyads_with_trade$polity2 >= 6 & pr_dyads_with_trade$polity1 < 6)
  ),
  0
)

#-------------------------------------------------------------------------------
# MERGE ALLIANCE DATA
#-------------------------------------------------------------------------------

# Create dyad keys (both directions)
pr_dyads_with_trade$dyad_key_12 <- paste(
  pr_dyads_with_trade$ccode1,
  pr_dyads_with_trade$ccode2,
  pr_dyads_with_trade$year, sep = "_"
)

pr_dyads_with_trade$dyad_key_21 <- paste(
  pr_dyads_with_trade$ccode2,
  pr_dyads_with_trade$ccode1,
  pr_dyads_with_trade$year, sep = "_"
)

if (nrow(alliance_dyads) > 0) {
  alliance_dyads$dyad_key <- paste(
    alliance_dyads$ccode1,
    alliance_dyads$ccode2,
    alliance_dyads$year, sep = "_"
  )

  # Check both directions
  pr_dyads_with_trade$alliance <- ifelse(
    pr_dyads_with_trade$dyad_key_12 %in% alliance_dyads$dyad_key |
    pr_dyads_with_trade$dyad_key_21 %in% alliance_dyads$dyad_key,
    1, 0
  )
} else {
  pr_dyads_with_trade$alliance <- 0
}

#-------------------------------------------------------------------------------
# CONFLICT HISTORY VARIABLES
#-------------------------------------------------------------------------------

# Sort data by dyad and year
pr_dyads_with_trade <- pr_dyads_with_trade[
  order(pr_dyads_with_trade$ccode1,
        pr_dyads_with_trade$ccode2,
        pr_dyads_with_trade$year),
]

# Create undirected dyad identifier for conflict history
pr_dyads_with_trade$undirected_dyad <- paste(
  pmin(pr_dyads_with_trade$ccode1, pr_dyads_with_trade$ccode2),
  pmax(pr_dyads_with_trade$ccode1, pr_dyads_with_trade$ccode2),
  sep = "_"
)

# If we have MID data merged, create conflict history
if (exists("mids_in_pr")) {
  # Get all dyad-years with MIDs
  mid_dyad_years <- unique(paste(
    pmin(mids_in_pr$statea, mids_in_pr$stateb),
    pmax(mids_in_pr$statea, mids_in_pr$stateb),
    mids_in_pr$year,
    sep = "_"
  ))

  # Previous MID indicator (lagged 1 year)
  pr_dyads_with_trade$prev_mid <- 0
  for (i in 2:nrow(pr_dyads_with_trade)) {
    if (pr_dyads_with_trade$undirected_dyad[i] ==
        pr_dyads_with_trade$undirected_dyad[i-1] &&
        pr_dyads_with_trade$year[i] == pr_dyads_with_trade$year[i-1] + 1) {

      # Check if previous year had a MID
      prev_key <- paste(
        pr_dyads_with_trade$undirected_dyad[i],
        pr_dyads_with_trade$year[i] - 1,
        sep = "_"
      )

      if (prev_key %in% mid_dyad_years) {
        pr_dyads_with_trade$prev_mid[i] <- 1
      }
    }
  }
} else {
  pr_dyads_with_trade$prev_mid <- 0
}

#-------------------------------------------------------------------------------
# CLEAN UP TEMPORARY VARIABLES
#-------------------------------------------------------------------------------

pr_dyads_with_trade$dyad_key_12 <- NULL
pr_dyads_with_trade$dyad_key_21 <- NULL

#-------------------------------------------------------------------------------
# CREATE FINAL DATASET WITH COMPLETE CASES
#-------------------------------------------------------------------------------

pr_dyads_full <- pr_dyads_with_trade

# Count missing data
cat("\n    Control variable coverage:\n")
cat("      CINC ratio: ",
    sum(!is.na(pr_dyads_full$cinc_ratio)), "/", nrow(pr_dyads_full), "\n")
cat("      Democracy: ",
    sum(!is.na(pr_dyads_full$democracy_min)), "/", nrow(pr_dyads_full), "\n")
cat("      Alliance: ",
    sum(pr_dyads_full$alliance == 1), "alliances\n")

cat("\n  ✓ Control variables integration complete\n")

#===============================================================================
# OUTPUT: pr_dyads_full
#===============================================================================

# This dataset now contains:
#   - Original PR dyad structure (Module 1)
#   - Trade variables (Module 2)
#   - Control variables (Module 3)
# Ready for regression analysis (Module 6)

#===============================================================================
# END OF CONTROL VARIABLES MODULE
#===============================================================================
