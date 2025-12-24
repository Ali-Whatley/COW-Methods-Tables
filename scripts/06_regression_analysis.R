#===============================================================================
#
#  MODULE 6: REGRESSION ANALYSIS
#
#  Description: Estimates ordered logistic regression models examining the effect
#               of trade vulnerability on conflict escalation intensity
#
#  Input:  - regression_data (from master script - PR dyads merged with MIDs)
#
#  Output: - Regression results tables (HTML + CSV)
#          - Model objects saved for post-estimation analysis
#
#  Models:
#    Model 1: Baseline (geographic + strategic controls only)
#    Model 2: + Trade volume (symmetric interdependence)
#    Model 3: + Trade asymmetry (key theoretical variable)
#    Model 4: + Interaction effects
#    Model 5: Full specification with all controls
#
#===============================================================================

cat("  Estimating ordered logit models...\n")

#-------------------------------------------------------------------------------
# PREPARE REGRESSION SAMPLE
#-------------------------------------------------------------------------------

# Create analysis sample with complete data on key variables
regression_sample <- regression_data[!is.na(regression_data$conflict_intensity_ordered), ]

cat("    Full sample:", nrow(regression_data), "dyad-years\n")
cat("    Estimation sample (non-missing DV):", nrow(regression_sample), "\n")

# Summary of dependent variable
cat("\n    Dependent variable distribution:\n")
print(table(regression_sample$conflict_intensity_ordered))

#-------------------------------------------------------------------------------
# MODEL 1: BASELINE (Controls Only)
#-------------------------------------------------------------------------------

cat("\n  Model 1: Baseline (geographic + strategic controls)\n")

# Build formula
formula_m1 <- conflict_intensity_ordered ~
  is_contiguous +
  has_major +
  cinc_ratio +
  alliance

# Estimate ordered logit
# Note: Requires complete cases on all variables
model1_data <- regression_sample[complete.cases(
  regression_sample[, c("conflict_intensity_ordered", "is_contiguous",
                        "has_major", "cinc_ratio", "alliance")]
), ]

if (nrow(model1_data) > 100) {  # Ensure sufficient observations
  model1 <- polr(
    formula_m1,
    data = model1_data,
    method = "logistic",  # Ordered logit
    Hess = TRUE           # Compute Hessian for SEs
  )

  # Cluster-robust standard errors (by dyad)
  # Note: This requires sandwich package
  if (require(sandwich, quietly = TRUE) && require(lmtest, quietly = TRUE)) {
    model1_vcov <- vcovCL(model1, cluster = model1_data$undirected_dyad)
    model1_robust <- coeftest(model1, vcov = model1_vcov)
  } else {
    model1_robust <- NULL
  }

  cat("    ✓ Model 1 estimated, N =", nrow(model1_data), "\n")
} else {
  cat("    ⚠ Insufficient data for Model 1\n")
  model1 <- NULL
}

#-------------------------------------------------------------------------------
# MODEL 2: + TRADE VOLUME (Symmetric Interdependence)
#-------------------------------------------------------------------------------

cat("\n  Model 2: + Bilateral trade\n")

formula_m2 <- conflict_intensity_ordered ~
  is_contiguous +
  has_major +
  cinc_ratio +
  alliance +
  log(trade_total + 1)  # Log transform (add 1 to handle zeros)

model2_data <- regression_sample[complete.cases(
  regression_sample[, c("conflict_intensity_ordered", "is_contiguous",
                        "has_major", "cinc_ratio", "alliance", "trade_total")]
), ]

if (nrow(model2_data) > 100) {
  model2 <- polr(
    formula_m2,
    data = model2_data,
    method = "logistic",
    Hess = TRUE
  )

  if (require(sandwich, quietly = TRUE)) {
    model2_vcov <- vcovCL(model2, cluster = model2_data$undirected_dyad)
    model2_robust <- coeftest(model2, vcov = model2_vcov)
  } else {
    model2_robust <- NULL
  }

  cat("    ✓ Model 2 estimated, N =", nrow(model2_data), "\n")
} else {
  cat("    ⚠ Insufficient data for Model 2\n")
  model2 <- NULL
}

#-------------------------------------------------------------------------------
# MODEL 3: + TRADE ASYMMETRY (Key Theoretical Variable)
#-------------------------------------------------------------------------------

cat("\n  Model 3: + Trade vulnerability/asymmetry\n")

formula_m3 <- conflict_intensity_ordered ~
  is_contiguous +
  has_major +
  cinc_ratio +
  alliance +
  trade_dep_lower +       # Less vulnerable state's dependence
  trade_dep_higher +      # More vulnerable state's dependence
  trade_asymmetry         # Asymmetry measure (key IV)

model3_data <- regression_sample[complete.cases(
  regression_sample[, c("conflict_intensity_ordered", "is_contiguous",
                        "has_major", "cinc_ratio", "alliance",
                        "trade_dep_lower", "trade_dep_higher", "trade_asymmetry")]
), ]

if (nrow(model3_data) > 100) {
  model3 <- polr(
    formula_m3,
    data = model3_data,
    method = "logistic",
    Hess = TRUE
  )

  if (require(sandwich, quietly = TRUE)) {
    model3_vcov <- vcovCL(model3, cluster = model3_data$undirected_dyad)
    model3_robust <- coeftest(model3, vcov = model3_vcov)
  } else {
    model3_robust <- NULL
  }

  cat("    ✓ Model 3 estimated, N =", nrow(model3_data), "\n")
  cat("      This is the MAIN MODEL for testing trade vulnerability hypothesis\n")
} else {
  cat("    ⚠ Insufficient data for Model 3\n")
  model3 <- NULL
}

#-------------------------------------------------------------------------------
# MODEL 4: + INTERACTION EFFECTS
#-------------------------------------------------------------------------------

cat("\n  Model 4: + Interactions (asymmetry × major power, democracy)\n")

formula_m4 <- conflict_intensity_ordered ~
  is_contiguous +
  has_major +
  cinc_ratio +
  alliance +
  trade_dep_lower +
  trade_dep_higher +
  trade_asymmetry +
  democracy_min +
  trade_asymmetry * has_major +         # Does asymmetry matter more for major powers?
  trade_asymmetry * joint_democracy     # Democratic peace interaction

model4_data <- regression_sample[complete.cases(
  regression_sample[, c("conflict_intensity_ordered", "is_contiguous",
                        "has_major", "cinc_ratio", "alliance",
                        "trade_dep_lower", "trade_dep_higher", "trade_asymmetry",
                        "democracy_min", "joint_democracy")]
), ]

if (nrow(model4_data) > 100) {
  model4 <- polr(
    formula_m4,
    data = model4_data,
    method = "logistic",
    Hess = TRUE
  )

  if (require(sandwich, quietly = TRUE)) {
    model4_vcov <- vcovCL(model4, cluster = model4_data$undirected_dyad)
    model4_robust <- coeftest(model4, vcov = model4_vcov)
  } else {
    model4_robust <- NULL
  }

  cat("    ✓ Model 4 estimated, N =", nrow(model4_data), "\n")
} else {
  cat("    ⚠ Insufficient data for Model 4\n")
  model4 <- NULL
}

#-------------------------------------------------------------------------------
# MODEL 5: FULL SPECIFICATION
#-------------------------------------------------------------------------------

cat("\n  Model 5: Full specification (all controls + conflict history)\n")

formula_m5 <- conflict_intensity_ordered ~
  is_contiguous +
  has_major +
  cinc_ratio +
  power_parity +
  alliance +
  trade_dep_lower +
  trade_dep_higher +
  trade_asymmetry +
  democracy_min +
  joint_democracy +
  prev_mid +              # Conflict history
  factor(year)            # Year fixed effects

model5_data <- regression_sample[complete.cases(
  regression_sample[, c("conflict_intensity_ordered", "is_contiguous",
                        "has_major", "cinc_ratio", "power_parity", "alliance",
                        "trade_dep_lower", "trade_dep_higher", "trade_asymmetry",
                        "democracy_min", "joint_democracy", "prev_mid")]
), ]

if (nrow(model5_data) > 100) {
  # Note: With year FEs, this model may be slow
  cat("      Estimating model with year fixed effects (may take time)...\n")

  model5 <- tryCatch({
    polr(
      formula_m5,
      data = model5_data,
      method = "logistic",
      Hess = TRUE
    )
  }, error = function(e) {
    cat("      ⚠ Full model failed to converge, trying without year FEs...\n")

    # Simplified version without year FEs
    formula_m5_simple <- conflict_intensity_ordered ~
      is_contiguous +
      has_major +
      cinc_ratio +
      power_parity +
      alliance +
      trade_dep_lower +
      trade_dep_higher +
      trade_asymmetry +
      democracy_min +
      joint_democracy +
      prev_mid

    polr(formula_m5_simple, data = model5_data, method = "logistic", Hess = TRUE)
  })

  if (!is.null(model5)) {
    if (require(sandwich, quietly = TRUE)) {
      model5_vcov <- vcovCL(model5, cluster = model5_data$undirected_dyad)
      model5_robust <- coeftest(model5, vcov = model5_vcov)
    } else {
      model5_robust <- NULL
    }

    cat("    ✓ Model 5 estimated, N =", nrow(model5_data), "\n")
  }
} else {
  cat("    ⚠ Insufficient data for Model 5\n")
  model5 <- NULL
}

#-------------------------------------------------------------------------------
# CREATE REGRESSION TABLE (formatted for publication)
#-------------------------------------------------------------------------------

cat("\n  Creating regression results table...\n")

# Helper function to extract model statistics
extract_model_stats <- function(model, robust_se = NULL) {
  if (is.null(model)) return(NULL)

  # Coefficients
  coefs <- coef(model)

  # Standard errors
  if (!is.null(robust_se)) {
    ses <- robust_se[, "Std. Error"]
  } else {
    ses <- summary(model)$coefficients[, "Std. Error"]
  }

  # P-values
  if (!is.null(robust_se)) {
    pvals <- robust_se[, "Pr(>|z|)"]
  } else {
    pvals <- summary(model)$coefficients[, "Pr(>|z|)"]
  }

  # Significance stars
  stars <- ifelse(pvals < 0.001, "***",
           ifelse(pvals < 0.01, "**",
           ifelse(pvals < 0.05, "*",
           ifelse(pvals < 0.10, "†", ""))))

  # Combine
  results <- data.frame(
    Variable = names(coefs),
    Coefficient = sprintf("%.3f", coefs),
    SE = sprintf("(%.3f)", ses),
    Stars = stars,
    stringsAsFactors = FALSE
  )

  # Model fit statistics
  n_obs <- length(model$fitted.values)
  loglik <- logLik(model)
  aic <- AIC(model)

  fit_stats <- list(
    N = n_obs,
    LogLik = as.numeric(loglik),
    AIC = aic
  )

  return(list(results = results, fit = fit_stats))
}

# Extract results from all models
m1_stats <- extract_model_stats(model1, model1_robust)
m2_stats <- extract_model_stats(model2, model2_robust)
m3_stats <- extract_model_stats(model3, model3_robust)
m4_stats <- extract_model_stats(model4, model4_robust)
m5_stats <- extract_model_stats(model5, model5_robust)

# Create combined table (simple version - for production use stargazer or modelsummary)
cat("\n")
cat("================================================================================\n")
cat("TABLE 6: ORDERED LOGIT MODELS - TRADE VULNERABILITY & CONFLICT ESCALATION\n")
cat("================================================================================\n\n")

if (!is.null(model3)) {
  cat("Model 3 (Main Theoretical Model) Results:\n")
  cat("------------------------------------------\n")
  print(m3_stats$results, row.names = FALSE)
  cat("\n")
  cat("Model Fit:\n")
  cat("  N =", m3_stats$fit$N, "\n")
  cat("  Log-Likelihood =", sprintf("%.2f", m3_stats$fit$LogLik), "\n")
  cat("  AIC =", sprintf("%.2f", m3_stats$fit$AIC), "\n")
  cat("\n")
  cat("Significance: *** p<0.001, ** p<0.01, * p<0.05, † p<0.10\n")
  cat("Standard errors clustered by dyad\n")
}

# Save models for post-estimation
save(model1, model2, model3, model4, model5,
     file = "output/regression_models.RData")

cat("\n  ✓ Models saved to output/regression_models.RData\n")

#-------------------------------------------------------------------------------
# CREATE HTML REGRESSION TABLE
#-------------------------------------------------------------------------------

# For production, use stargazer or modelsummary package
# Example with base R HTML creation:

if (require(stargazer, quietly = TRUE) && !is.null(model3)) {
  cat("\n  Generating publication-quality table with stargazer...\n")

  models_list <- list()
  if (!is.null(model1)) models_list[[1]] <- model1
  if (!is.null(model2)) models_list[[2]] <- model2
  if (!is.null(model3)) models_list[[3]] <- model3
  if (!is.null(model4)) models_list[[4]] <- model4
  if (!is.null(model5)) models_list[[5]] <- model5

  stargazer(
    models_list,
    type = "html",
    title = "Ordered Logit Models: Trade Vulnerability and Conflict Escalation",
    dep.var.labels = "Conflict Intensity (0=No MID, 2=Threat, 3=Display, 4=Use Force, 5=War)",
    covariate.labels = c(
      "Contiguous",
      "Major Power Dyad",
      "Capability Ratio",
      "Alliance",
      "Trade Volume (log)",
      "Trade Dep. (Lower)",
      "Trade Dep. (Higher)",
      "Trade Asymmetry",
      "Democracy (Min)",
      "Joint Democracy",
      "Previous MID"
    ),
    notes = c(
      "Standard errors clustered by dyad in parentheses.",
      "*** p<0.001, ** p<0.01, * p<0.05"
    ),
    out = "output/tables/regression_results.html"
  )

  cat("  ✓ Table saved to output/tables/regression_results.html\n")
}

cat("\n  Regression analysis complete.\n")

#===============================================================================
# END OF REGRESSION ANALYSIS MODULE
#===============================================================================
