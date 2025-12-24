#===============================================================================
#
#  MASTER ANALYSIS SCRIPT: Trade Vulnerability & Conflict Intensity
#
#  Description: Complete research analysis from data loading to final outputs
#               Orchestrates all analysis modules in correct sequence
#
#  Author:      Ali Whatley
#  Created:     2025
#
#  Research Question:
#    Does trade vulnerability between states affect the intensity of
#    militarized conflict when disputes occur?
#
#  Output Structure:
#    - output/tables/      → All statistical tables (HTML + CSV)
#    - output/figures/     → All plots and visualizations (PDF + PNG)
#    - output/analysis_report.html → Complete results document
#
#===============================================================================

# Clear workspace
rm(list = ls())

# Set working directory (adjust as needed)
# setwd("path/to/COW-Methods-Tables")

cat("================================================================================\n")
cat("  TRADE VULNERABILITY & CONFLICT INTENSITY: COMPLETE ANALYSIS\n")
cat("================================================================================\n\n")

#-------------------------------------------------------------------------------
# CONFIGURATION
#-------------------------------------------------------------------------------

# Analysis parameters
START_YEAR <- 1973  # End of Bretton Woods gold convertibility
END_YEAR   <- 2014  # Data availability cutoff

# Output directories
dir.create("output", showWarnings = FALSE)
dir.create("output/tables", showWarnings = FALSE)
dir.create("output/figures", showWarnings = FALSE)
dir.create("scripts", showWarnings = FALSE)

# Check for required packages
required_packages <- c("MASS", "sandwich", "lmtest", "ggplot2")
missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]

if (length(missing_packages) > 0) {
  cat("WARNING: Missing packages detected:\n")
  cat(paste(" -", missing_packages, collapse="\n"), "\n\n")
  cat("Install with: install.packages(c(",
      paste(paste0("'", missing_packages, "'"), collapse=", "), "))\n\n")

  response <- readline("Continue without these packages? (y/n): ")
  if (tolower(response) != "y") {
    stop("Analysis halted. Please install required packages.")
  }
} else {
  # Load packages
  library(MASS)      # For ordered logit (polr function)
  library(sandwich)  # For robust standard errors
  library(lmtest)    # For coefficient tests
  library(ggplot2)   # For visualizations
  cat("All required packages loaded successfully.\n\n")
}

#-------------------------------------------------------------------------------
# MODULE 1: DATA LOADING & POLITICALLY RELEVANT DYADS
#-------------------------------------------------------------------------------

cat("MODULE 1: Loading COW data and constructing politically relevant dyads...\n")

# Check if refactored script exists, otherwise use original
if (file.exists("scripts/01_data_loading.R")) {
  source("scripts/01_data_loading.R")
} else if (file.exists("Trade Conflict Tables R - DSR Analysis README.R")) {
  cat("  Using original script (not yet refactored)\n")
  source("Trade Conflict Tables R - DSR Analysis README.R")

  # Verify required objects exist
  if (!exists("pr_dyads") || !exists("mids_in_pr")) {
    stop("ERROR: Data loading failed. pr_dyads or mids_in_pr not created.")
  }
} else {
  stop("ERROR: No data loading script found. Please ensure data files are available.")
}

cat("  ✓ PR dyads created:", nrow(pr_dyads), "observations\n")
cat("  ✓ MIDs identified:", nrow(mids_in_pr), "disputes in PR dyads\n\n")

#-------------------------------------------------------------------------------
# MODULE 2: TRADE DATA INTEGRATION
#-------------------------------------------------------------------------------

cat("MODULE 2: Integrating bilateral trade data...\n")

if (file.exists("scripts/02_trade_processing.R")) {
  source("scripts/02_trade_processing.R")

  if (exists("pr_dyads_with_trade")) {
    pr_dyads <- pr_dyads_with_trade
    cat("  ✓ Trade variables added:", ncol(pr_dyads_with_trade), "total columns\n")
  } else {
    cat("  ⚠ WARNING: Trade processing script exists but didn't create expected output\n")
    cat("    Continuing without trade variables (analysis will be incomplete)\n")
  }
} else {
  cat("  ⚠ WARNING: Trade processing script not found (scripts/02_trade_processing.R)\n")
  cat("    Creating placeholder trade variables for demonstration...\n")

  # Create placeholder variables (replace with actual data)
  pr_dyads$trade_total <- NA
  pr_dyads$trade_dep_lower <- NA
  pr_dyads$trade_dep_higher <- NA
  pr_dyads$trade_asymmetry <- NA

  cat("    Note: Analysis will run but results are NOT VALID without real trade data\n")
}

cat("\n")

#-------------------------------------------------------------------------------
# MODULE 3: CONTROL VARIABLES
#-------------------------------------------------------------------------------

cat("MODULE 3: Adding control variables (GDP, democracy, capabilities, alliances)...\n")

if (file.exists("scripts/03_control_variables.R")) {
  source("scripts/03_control_variables.R")

  if (exists("pr_dyads_full")) {
    pr_dyads <- pr_dyads_full
    cat("  ✓ Control variables added\n")
  }
} else {
  cat("  ⚠ WARNING: Control variables script not found (scripts/03_control_variables.R)\n")
  cat("    Creating placeholder controls for demonstration...\n")

  # Placeholder controls (replace with actual data)
  pr_dyads$cinc_ratio <- NA
  pr_dyads$gdp_ratio <- NA
  pr_dyads$democracy_min <- NA
  pr_dyads$alliance <- 0
  pr_dyads$prev_mid <- 0

  cat("    Note: Results will be incomplete without proper controls\n")
}

cat("\n")

#-------------------------------------------------------------------------------
# MODULE 4: MERGE WITH MIDS FOR REGRESSION SAMPLE
#-------------------------------------------------------------------------------

cat("MODULE 4: Creating regression sample (merging PR dyads with MID outcomes)...\n")

# Create dyad-year key for merging
pr_dyads$dyad_key <- paste(pr_dyads$ccode1, pr_dyads$ccode2, pr_dyads$year, sep = "_")
mids_in_pr$dyad_key <- paste(mids_in_pr$statea, mids_in_pr$stateb,
                              mids_in_pr$year, sep = "_")

# Merge: keep all PR dyads, add MID info where exists
regression_data <- merge(
  pr_dyads,
  mids_in_pr[, c("dyad_key", "hihost", "disno")],
  by = "dyad_key",
  all.x = TRUE
)

# Create outcome variable: 0 = no MID, 2-5 = hostility level
regression_data$conflict_intensity <- ifelse(
  is.na(regression_data$hihost),
  0,  # No MID occurred
  regression_data$hihost  # MID hostility level
)

# Convert to ordered factor for ordered logit
regression_data$conflict_intensity_ordered <- factor(
  regression_data$conflict_intensity,
  levels = c(0, 2, 3, 4, 5),
  ordered = TRUE,
  labels = c("No MID", "Threat", "Display", "Use of Force", "War")
)

cat("  ✓ Regression sample created:", nrow(regression_data), "dyad-years\n")
cat("    - No MID:", sum(regression_data$conflict_intensity == 0), "\n")
cat("    - Threat (2):", sum(regression_data$conflict_intensity == 2, na.rm=TRUE), "\n")
cat("    - Display (3):", sum(regression_data$conflict_intensity == 3, na.rm=TRUE), "\n")
cat("    - Use of Force (4):", sum(regression_data$conflict_intensity == 4, na.rm=TRUE), "\n")
cat("    - War (5):", sum(regression_data$conflict_intensity == 5, na.rm=TRUE), "\n\n")

#-------------------------------------------------------------------------------
# MODULE 5: DESCRIPTIVE STATISTICS (existing tables 1-5)
#-------------------------------------------------------------------------------

cat("MODULE 5: Generating descriptive statistics tables...\n")

# These are already generated by the original script
# Just confirm they exist
if (file.exists("output/methods_tables.html")) {
  cat("  ✓ Methods tables already generated\n")
} else {
  cat("  → Re-running methods table generation...\n")
  if (file.exists("Trade Conflict Tables R - DSR Analysis README.R")) {
    source("Trade Conflict Tables R - DSR Analysis README.R")
  }
}

cat("\n")

#-------------------------------------------------------------------------------
# MODULE 6: REGRESSION ANALYSIS
#-------------------------------------------------------------------------------

cat("MODULE 6: Running regression models...\n")

if (file.exists("scripts/06_regression_analysis.R")) {
  source("scripts/06_regression_analysis.R")
  cat("  ✓ Regression analysis complete\n")
} else {
  cat("  ⚠ WARNING: Regression script not found (scripts/06_regression_analysis.R)\n")
  cat("    Skipping statistical models\n")
}

cat("\n")

#-------------------------------------------------------------------------------
# MODULE 7: ROBUSTNESS CHECKS
#-------------------------------------------------------------------------------

cat("MODULE 7: Running robustness checks...\n")

if (file.exists("scripts/07_robustness_checks.R")) {
  source("scripts/07_robustness_checks.R")
  cat("  ✓ Robustness checks complete\n")
} else {
  cat("  ⚠ Robustness checks script not found - skipping\n")
}

cat("\n")

#-------------------------------------------------------------------------------
# MODULE 8: VISUALIZATIONS
#-------------------------------------------------------------------------------

cat("MODULE 8: Creating visualizations...\n")

if (file.exists("scripts/08_visualization.R")) {
  source("scripts/08_visualization.R")
  cat("  ✓ Figures generated\n")
} else {
  cat("  ⚠ Visualization script not found - skipping\n")
}

cat("\n")

#-------------------------------------------------------------------------------
# ANALYSIS COMPLETE
#-------------------------------------------------------------------------------

cat("================================================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("================================================================================\n\n")

cat("Output files:\n")
cat("  📁 output/tables/\n")
if (dir.exists("output/tables")) {
  files <- list.files("output/tables", pattern = "\\.(html|csv)$")
  if (length(files) > 0) {
    cat(paste("     -", files), sep = "\n")
  }
}

cat("\n  📁 output/figures/\n")
if (dir.exists("output/figures")) {
  files <- list.files("output/figures", pattern = "\\.(pdf|png)$")
  if (length(files) > 0) {
    cat(paste("     -", files), sep = "\n")
  } else {
    cat("     (no figures generated yet)\n")
  }
}

cat("\n")
cat("Next steps:\n")
cat("  1. Review output/tables/methods_tables.html\n")
cat("  2. If regression tables exist, review output/tables/regression_results.html\n")
cat("  3. Check data integration warnings above\n")
cat("  4. Download missing COW datasets if needed (see RESEARCH_IMPLEMENTATION_PLAN.md)\n")
cat("\n")

cat("================================================================================\n")

#===============================================================================
# END OF MASTER SCRIPT
#===============================================================================
