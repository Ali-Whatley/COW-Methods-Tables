#===============================================================================
#
#  MODULE 8: DATA VISUALIZATION
#
#  Description: Creates publication-quality figures for research paper
#
#  Input:  - regression_sample (dyad-year data with all variables)
#          - model objects from Module 6
#
#  Output: - Figures saved to output/figures/ (PDF and PNG)
#
#  Figures Created:
#    Figure 1: Distribution of trade asymmetry by conflict status
#    Figure 2: Predicted probabilities by trade asymmetry level
#    Figure 3: Marginal effects of key variables
#    Figure 4: Conflict intensity by dyad type (contiguous vs major power)
#
#===============================================================================

cat("  Creating visualizations...\n")

# Ensure output directory exists
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# Load ggplot2 if available
if (!require(ggplot2, quietly = TRUE)) {
  cat("  ⚠ WARNING: ggplot2 not installed. Skipping advanced visualizations.\n")
  cat("    Install with: install.packages('ggplot2')\n\n")
  return()
}

#-------------------------------------------------------------------------------
# FIGURE 1: Trade Asymmetry Distribution by Conflict Status
#-------------------------------------------------------------------------------

cat("    Creating Figure 1: Trade asymmetry distribution...\n")

# Prepare data
plot_data <- regression_sample[
  !is.na(regression_sample$trade_asymmetry) &
  regression_sample$trade_asymmetry > 0,
]

plot_data$has_mid <- ifelse(
  plot_data$conflict_intensity > 0,
  "MID Occurred",
  "No MID"
)

# Create plot
fig1 <- ggplot(plot_data, aes(x = trade_asymmetry, fill = has_mid)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("No MID" = "#2166ac", "MID Occurred" = "#b2182b")) +
  labs(
    title = "Distribution of Trade Asymmetry by Conflict Status",
    x = "Trade Asymmetry (% GDP difference)",
    y = "Density",
    fill = "Conflict Status"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Save
ggsave("output/figures/fig1_trade_asymmetry.pdf", fig1, width = 8, height = 5)
ggsave("output/figures/fig1_trade_asymmetry.png", fig1, width = 8, height = 5, dpi = 300)

cat("      ✓ Saved fig1_trade_asymmetry.pdf/.png\n")

#-------------------------------------------------------------------------------
# FIGURE 2: Predicted Probabilities by Trade Asymmetry
#-------------------------------------------------------------------------------

cat("    Creating Figure 2: Predicted probabilities...\n")

# This requires Model 3 to be estimated
if (exists("model3") && !is.null(model3)) {

  # Create prediction grid
  pred_data <- expand.grid(
    trade_asymmetry = seq(0, quantile(plot_data$trade_asymmetry, 0.95, na.rm=TRUE), length.out = 50),
    trade_dep_lower = median(model3_data$trade_dep_lower, na.rm = TRUE),
    trade_dep_higher = median(model3_data$trade_dep_higher, na.rm = TRUE),
    is_contiguous = TRUE,
    has_major = FALSE,
    cinc_ratio = median(model3_data$cinc_ratio, na.rm = TRUE),
    alliance = 0
  )

  # Predict probabilities for each outcome category
  preds <- predict(model3, newdata = pred_data, type = "probs")

  # Combine predictions with predictor values
  pred_df <- data.frame(
    trade_asymmetry = rep(pred_data$trade_asymmetry, ncol(preds)),
    outcome = rep(colnames(preds), each = nrow(preds)),
    probability = as.vector(preds)
  )

  # Plot
  fig2 <- ggplot(pred_df, aes(x = trade_asymmetry, y = probability, color = outcome)) +
    geom_line(size = 1) +
    scale_color_brewer(palette = "Set1") +
    labs(
      title = "Predicted Probabilities of Conflict Escalation by Trade Asymmetry",
      subtitle = "Holding other variables at median/modal values",
      x = "Trade Asymmetry (% GDP difference)",
      y = "Predicted Probability",
      color = "Conflict Intensity"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 10, color = "gray40"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )

  ggsave("output/figures/fig2_predicted_probs.pdf", fig2, width = 8, height = 6)
  ggsave("output/figures/fig2_predicted_probs.png", fig2, width = 8, height = 6, dpi = 300)

  cat("      ✓ Saved fig2_predicted_probs.pdf/.png\n")

} else {
  cat("      ⚠ Model 3 not available, skipping predicted probabilities plot\n")
}

#-------------------------------------------------------------------------------
# FIGURE 3: Conflict Intensity by Dyad Type
#-------------------------------------------------------------------------------

cat("    Creating Figure 3: Conflict by dyad type...\n")

# Aggregate conflict intensity by dyad characteristics
# Using base R (no dplyr dependency)
dyad_summary <- aggregate(
  conflict_intensity ~ is_contiguous + has_major,
  data = regression_sample,
  FUN = function(x) c(
    mean_intensity = mean(x, na.rm = TRUE),
    prop_mid = mean(x > 0, na.rm = TRUE),
    n = length(x)
  )
)
dyad_summary <- do.call(data.frame, dyad_summary)
names(dyad_summary)[3:5] <- c("mean_intensity", "prop_mid", "n")

# Create dyad type labels
dyad_summary$dyad_type <- paste0(
  ifelse(dyad_summary$is_contiguous, "Contiguous", "Non-Contiguous"),
  ifelse(dyad_summary$has_major, "\n+ Major Power", "\n(Minor Only)")
)

# Plot proportion with MIDs
fig3 <- ggplot(dyad_summary, aes(x = dyad_type, y = prop_mid, fill = dyad_type)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.1f%%", prop_mid * 100)),
            vjust = -0.5, size = 4) +
  scale_fill_brewer(palette = "Pastel1") +
  labs(
    title = "Proportion of Dyad-Years with MIDs by Political Relevance Type",
    x = "Dyad Type",
    y = "Proportion with MID"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    panel.grid.major.x = element_blank()
  )

ggsave("output/figures/fig3_conflict_by_type.pdf", fig3, width = 7, height = 5)
ggsave("output/figures/fig3_conflict_by_type.png", fig3, width = 7, height = 5, dpi = 300)

cat("      ✓ Saved fig3_conflict_by_type.pdf/.png\n")

#-------------------------------------------------------------------------------
# FIGURE 4: Trade Volume Over Time
#-------------------------------------------------------------------------------

cat("    Creating Figure 4: Trade trends over time...\n")

# Calculate mean trade volume by year (base R)
trade_data_year <- regression_sample[regression_sample$trade_total > 0, ]
trade_trends <- aggregate(
  trade_total ~ year,
  data = trade_data_year,
  FUN = function(x) c(mean_trade = mean(x, na.rm = TRUE), median_trade = median(x, na.rm = TRUE))
)
trade_trends <- do.call(data.frame, trade_trends)
names(trade_trends)[2:3] <- c("mean_trade", "median_trade")

fig4 <- ggplot(trade_trends, aes(x = year)) +
  geom_line(aes(y = mean_trade, color = "Mean"), size = 1) +
  geom_line(aes(y = median_trade, color = "Median"), size = 1, linetype = "dashed") +
  scale_color_manual(values = c("Mean" = "#d95f02", "Median" = "#7570b3")) +
  labs(
    title = "Bilateral Trade Volume in Politically Relevant Dyads, 1973-2014",
    x = "Year",
    y = "Trade Volume (millions USD)",
    color = "Statistic"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    legend.position = "bottom"
  )

ggsave("output/figures/fig4_trade_trends.pdf", fig4, width = 8, height = 5)
ggsave("output/figures/fig4_trade_trends.png", fig4, width = 8, height = 5, dpi = 300)

cat("      ✓ Saved fig4_trade_trends.pdf/.png\n")

#-------------------------------------------------------------------------------
# FIGURE 5: Coefficient Plot (if Model 3 exists)
#-------------------------------------------------------------------------------

cat("    Creating Figure 5: Coefficient plot...\n")

if (exists("model3") && !is.null(model3)) {

  # Extract coefficients and confidence intervals
  coefs <- coef(model3)
  ses <- summary(model3)$coefficients[, "Std. Error"]

  # Calculate 95% CIs
  ci_lower <- coefs - 1.96 * ses
  ci_upper <- coefs + 1.96 * ses

  # Create data frame
  coef_df <- data.frame(
    variable = names(coefs),
    estimate = coefs,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    row.names = NULL
  )

  # Nicer variable labels
  coef_df$variable_label <- c(
    "Contiguous", "Major Power", "Capability Ratio",
    "Alliance", "Trade Dep. (Lower)", "Trade Dep. (Higher)",
    "Trade Asymmetry"
  )[1:nrow(coef_df)]

  # Plot
  fig5 <- ggplot(coef_df, aes(x = estimate, y = reorder(variable_label, estimate))) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper),
                   height = 0.2, size = 1, color = "#1b9e77") +
    geom_point(size = 3, color = "#d95f02") +
    labs(
      title = "Ordered Logit Coefficients: Model 3",
      subtitle = "Effect on conflict escalation intensity (95% CI)",
      x = "Coefficient Estimate",
      y = ""
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 10, color = "gray40"),
      panel.grid.major.y = element_blank()
    )

  ggsave("output/figures/fig5_coefficients.pdf", fig5, width = 7, height = 5)
  ggsave("output/figures/fig5_coefficients.png", fig5, width = 7, height = 5, dpi = 300)

  cat("      ✓ Saved fig5_coefficients.pdf/.png\n")

} else {
  cat("      ⚠ Model 3 not available, skipping coefficient plot\n")
}

#-------------------------------------------------------------------------------
# SUMMARY
#-------------------------------------------------------------------------------

cat("\n  ✓ Visualization module complete\n")
cat("    Figures saved to output/figures/\n\n")

#===============================================================================
# END OF VISUALIZATION MODULE
#===============================================================================
