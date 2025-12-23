#===============================================================================
#
#  TRADE VULNERABILITY & CONFLICT INTENSITY: METHODS TABLES GENERATOR
#
#  Description: This script generates publication-ready academic tables for 
#               analyzing the relationship between trade vulnerability and 
#               interstate conflict intensity using Correlates of War (COW) data.
#
#  Author:      Ali Whatley
#  Created:     2025
#  License:     MIT
#
#  Purpose:     Creates summary statistics tables for politically relevant dyads
#               (1973-2014) examining how economic interdependence affects the
#               escalation of militarized interstate disputes (MIDs).
#
#  Data Sources:
#     - COW Major Powers dataset (majors2024.csv)
#     - COW Direct Contiguity dataset v3.2 (contdird.csv)
#     - Dyadic MID dataset v4.03 (dyadic_mid_4_03.csv)
#
#  Outputs:
#     - methods_tables.html: Formatted HTML tables for web/Word
#     - table1-5_*.csv: Individual tables as CSV files
#
#  Theoretical Framework:
#     Builds on Lemke & Reed (2001) politically relevant dyads concept and
#     examines conflict within the post-Bretton Woods international economic
#     system (1973-2014).
#
#===============================================================================

#-------------------------------------------------------------------------------
# LOAD REQUIRED DATA
#-------------------------------------------------------------------------------

# Load COW datasets
# majors2024.csv: Contains major power status by country-year
# contdird.csv: Direct contiguity between states (land borders, water distance)
# dyadic_mid_4_03.csv: Militarized interstate disputes at dyad level

majors <- read.csv("majors2024.csv")
contiguity <- read.csv("contdird.csv")
mids <- read.csv("dyadic_mid_4_03.csv")

#-------------------------------------------------------------------------------
# SET ANALYSIS PARAMETERS
#-------------------------------------------------------------------------------

# Time bounds: Post-Bretton Woods era
# Rationale: Ensures consistent international economic/monetary system
# 1973 = Nixon ends gold convertibility; 2014 = data availability cutoff

START_YEAR <- 1973
END_YEAR <- 2014

#-------------------------------------------------------------------------------
# PROCESS MAJOR POWERS DATA
#-------------------------------------------------------------------------------

# Expand major power spells into country-year observations
# Each row in majors has styear (start) and endyear (end) of major power status
# We need one row per country-year for merging

major_power_years <- data.frame()

for (i in 1:nrow(majors)) {
  # Generate sequence of years for this major power spell
  years <- majors$styear[i]:majors$endyear[i]
  
  # Create data frame with one row per year
  temp <- data.frame(
    ccode = majors$ccode[i],      # COW country code
    stateabb = majors$stateabb[i], # State abbreviation
    year = years
  )
  
  major_power_years <- rbind(major_power_years, temp)
}

# Remove any duplicate country-years (shouldn't exist, but safety check)
major_power_years <- unique(major_power_years)

# Filter to analysis period only
major_1973 <- major_power_years[
  major_power_years$year >= START_YEAR & 
  major_power_years$year <= END_YEAR, 
]

# Extract unique major power country codes for quick lookup
major_ccodes <- unique(major_1973$ccode)

#-------------------------------------------------------------------------------
# PROCESS CONTIGUITY DATA
#-------------------------------------------------------------------------------

# Select relevant columns from contiguity dataset
# state1no/state2no: COW country codes for dyad members
# conttype: Type of contiguity (1-5 scale, 1=land border, 5=400mi water)

contig <- contiguity[, c("state1no", "state2no", "year", "conttype")]
names(contig) <- c("ccode1", "ccode2", "year", "conttype")

# Filter to analysis period
contig <- contig[contig$year >= START_YEAR & contig$year <= END_YEAR, ]

# Flag contiguous dyads
contig$is_contiguous <- TRUE

# Flag dyads containing at least one major power
# These are "politically relevant" per Lemke & Reed (2001)
contig$has_major <- (contig$ccode1 %in% major_ccodes) | 
                    (contig$ccode2 %in% major_ccodes)

#-------------------------------------------------------------------------------
# CREATE MAJOR POWER DYADS (NON-CONTIGUOUS)
#-------------------------------------------------------------------------------

# Major powers can project force globally, so all major-minor dyads are
# politically relevant regardless of contiguity

# First, get all states present in each year
states_by_year <- unique(rbind(
  data.frame(ccode = contig$ccode1, year = contig$year),
  data.frame(ccode = contig$ccode2, year = contig$year)
))

# Create all major power-other state combinations by year
major_dyads <- data.frame()

for (yr in START_YEAR:END_YEAR) {
  # Get major powers active this year
  majors_yr <- major_1973$ccode[major_1973$year == yr]
  
  # Get all states active this year
  states_yr <- states_by_year$ccode[states_by_year$year == yr]
  
  # Create dyads: each major power paired with every other state
  for (m in majors_yr) {
    others <- states_yr[states_yr != m]  # Exclude self-dyads
    if (length(others) > 0) {
      major_dyads <- rbind(
        major_dyads, 
        data.frame(ccode1 = m, ccode2 = others, year = yr)
      )
    }
  }
}

# Directed dyads: create reverse direction (A-B and B-A)
major_dyads_rev <- data.frame(
  ccode1 = major_dyads$ccode2, 
  ccode2 = major_dyads$ccode1, 
  year = major_dyads$year
)
major_dyads_all <- unique(rbind(major_dyads, major_dyads_rev))

# Add flags for consistency with contiguity data
major_dyads_all$conttype <- 0          # No contiguity
major_dyads_all$is_contiguous <- FALSE
major_dyads_all$has_major <- TRUE      # By definition

#-------------------------------------------------------------------------------
# COMBINE INTO POLITICALLY RELEVANT DYADS
#-------------------------------------------------------------------------------

# Create unique keys for deduplication
contig$key <- paste(contig$ccode1, contig$ccode2, contig$year, sep = "_")
major_dyads_all$key <- paste(major_dyads_all$ccode1, major_dyads_all$ccode2, 
                              major_dyads_all$year, sep = "_")

# Keep only major power dyads not already in contiguity data
# (Avoids double-counting contiguous major power dyads)
major_dyads_new <- major_dyads_all[!major_dyads_all$key %in% contig$key, ]

# Combine: Contiguous dyads + Non-contiguous major power dyads
pr_dyads <- rbind(
  contig[, c("ccode1", "ccode2", "year", "conttype", "is_contiguous", "has_major")],
  major_dyads_new[, c("ccode1", "ccode2", "year", "conttype", "is_contiguous", "has_major")]
)

# Create undirected dyad ID (smaller ccode first)
# Used for counting unique dyads regardless of direction
pr_dyads$dyad_id <- paste(
  pmin(pr_dyads$ccode1, pr_dyads$ccode2), 
  pmax(pr_dyads$ccode1, pr_dyads$ccode2), 
  sep = "_"
)

#-------------------------------------------------------------------------------
# MERGE WITH MILITARIZED INTERSTATE DISPUTES (MIDs)
#-------------------------------------------------------------------------------

# Filter MIDs to analysis period
mids_period <- mids[mids$year >= START_YEAR & mids$year <= END_YEAR, ]

# Create matching keys
mids_period$key <- paste(mids_period$statea, mids_period$stateb, 
                          mids_period$year, sep = "_")
pr_dyads$key <- paste(pr_dyads$ccode1, pr_dyads$ccode2, pr_dyads$year, sep = "_")

# Keep only MIDs occurring in politically relevant dyads
# This is our dependent variable sample
mids_in_pr <- mids_period[mids_period$key %in% pr_dyads$key, ]

cat("Data processing complete.\n")
cat("  PR dyad-years:", nrow(pr_dyads), "\n")
cat("  MIDs in PR dyads:", nrow(mids_in_pr), "\n")

#===============================================================================
# HTML TABLE HELPER FUNCTION
#===============================================================================

#' Create HTML Table with Academic Formatting
#'
#' Generates an HTML table following APA/academic journal conventions with
#' horizontal rules, proper alignment, and footnotes.
#'
#' @param data Data frame to convert to table
#' @param caption Table title (appears above table)
#' @param note Footnote text (appears below table, prefixed with "Note.")
#' @param col_align Vector of alignment strings ("left", "center", "right")
#' @return Character string containing HTML table markup

create_html_table <- function(data, caption, note = "", col_align = NULL) {
  
  # Default: left-align all columns
  if (is.null(col_align)) {
    col_align <- rep("left", ncol(data))
  }
  
  # Start table
  html <- paste0('<table class="academic-table">\n')
  html <- paste0(html, '<caption>', caption, '</caption>\n')
  
  # Table header
  html <- paste0(html, '<thead>\n<tr>\n')
  for (i in 1:ncol(data)) {
    html <- paste0(html, '<th style="text-align:', col_align[i], ';">', 
                   names(data)[i], '</th>\n')
  }
  html <- paste0(html, '</tr>\n</thead>\n')
  
  # Table body
  html <- paste0(html, '<tbody>\n')
  for (r in 1:nrow(data)) {
    # Bold formatting for total rows
    if (r == nrow(data) && grepl("Total", data[r, 1], ignore.case = TRUE)) {
      html <- paste0(html, '<tr class="total-row">\n')
    } else {
      html <- paste0(html, '<tr>\n')
    }
    
    # Add cells
    for (c in 1:ncol(data)) {
      html <- paste0(html, '<td style="text-align:', col_align[c], ';">', 
                     data[r, c], '</td>\n')
    }
    html <- paste0(html, '</tr>\n')
  }
  html <- paste0(html, '</tbody>\n')
  
  # Table footnote
  if (note != "") {
    html <- paste0(html, '<tfoot>\n<tr><td colspan="', ncol(data), 
                   '" class="table-note">')
    html <- paste0(html, '<em>Note.</em> ', note, '</td></tr>\n</tfoot>\n')
  }
  
  html <- paste0(html, '</table>\n')
  return(html)
}

#===============================================================================
# CREATE SUMMARY TABLES
#===============================================================================

#-------------------------------------------------------------------------------
# TABLE 1: Composition of Politically Relevant Dyads
# Shows how dyads qualify for inclusion (contiguity vs major power status)
#-------------------------------------------------------------------------------

# Count dyads by selection criterion
both <- sum(pr_dyads$is_contiguous & pr_dyads$has_major)      # Both criteria
contig_only <- sum(pr_dyads$is_contiguous & !pr_dyads$has_major)  # Contiguous only
major_only <- sum(!pr_dyads$is_contiguous & pr_dyads$has_major)   # Major only
total <- nrow(pr_dyads)

table1 <- data.frame(
  `Selection Criterion` = c(
    "Contiguous and major power", 
    "Contiguous only", 
    "Major power only", 
    "Total"
  ),
  `Dyad-Years` = c(
    format(both, big.mark=","), 
    format(contig_only, big.mark=","),
    format(major_only, big.mark=","), 
    format(total, big.mark=",")
  ),
  `%` = c(
    sprintf("%.1f", both/total*100), 
    sprintf("%.1f", contig_only/total*100),
    sprintf("%.1f", major_only/total*100), 
    "100.0"
  ),
  check.names = FALSE
)

table1_note <- paste0(
  "N = ", format(total, big.mark=","), " directed dyad-years representing ",
  format(length(unique(pr_dyads$dyad_id)), big.mark=","), " unique undirected dyads. ",
  "A dyad is politically relevant if at least one state is a major power or the ",
  "states are directly contiguous (Lemke & Reed, 2001)."
)

#-------------------------------------------------------------------------------
# TABLE 2: Major Powers in Sample
# Lists all major powers and their status periods
#-------------------------------------------------------------------------------

table2 <- data.frame(
  State = c(
    "United States", "United Kingdom", "France", "Russia/USSR", 
    "China", "Germany", "Japan"
  ),
  `COW Code` = c("2", "200", "220", "365", "710", "255", "740"),
  `Full Major Power Period` = c(
    "1898–present", 
    "1816–present", 
    "1816–1940, 1945–present",
    "1816–1917, 1922–present", 
    "1950–present",
    "1816–1918, 1925–1945, 1991–present", 
    "1895–1945, 1991–present"
  ),
  `Years in Sample (1973–2014)` = c(
    "42 (full)", "42 (full)", "42 (full)", "42 (full)",
    "42 (full)", "24 (1991–2014)", "24 (1991–2014)"
  ),
  check.names = FALSE
)

table2_note <- paste0(
  "Major power status per Correlates of War Project (2024). ",
  "Germany and Japan regained major power status in 1991 following ",
  "reunification and post–Cold War economic resurgence."
)

#-------------------------------------------------------------------------------
# TABLE 3: Distribution of Contiguity Types
# Shows breakdown of how states share borders (land vs. water distance)
#-------------------------------------------------------------------------------

# Filter to contiguous dyads only
contig_dyads <- pr_dyads[pr_dyads$is_contiguous, ]

# Count by contiguity type
cont_counts <- table(contig_dyads$conttype)

table3 <- data.frame(
  `Contiguity Type` = c(
    "1: Land or river border", 
    "2: ≤12 miles of water",
    "3: 13–24 miles of water", 
    "4: 25–150 miles of water",
    "5: 151–400 miles of water", 
    "Total"
  ),
  `Dyad-Years` = c(
    format(as.numeric(cont_counts), big.mark=","),
    format(sum(cont_counts), big.mark=",")
  ),
  `%` = c(
    sprintf("%.1f", as.numeric(cont_counts)/sum(cont_counts)*100), 
    "100.0"
  ),
  check.names = FALSE
)

table3_note <- paste0(
  "Contiguity data from COW Direct Contiguity dataset v3.2 (Stinnett et al., 2002). ",
  "Water distances reflect territorial waters (12 mi), contiguous zone (24 mi), ",
  "and EEZ thresholds."
)

#-------------------------------------------------------------------------------
# TABLE 4: Distribution of MID Hostility Levels (Dependent Variable)
# Shows escalation levels for disputes in sample
#-------------------------------------------------------------------------------

# Count MIDs by highest hostility level reached
hihost_counts <- table(mids_in_pr$hihost)

table4 <- data.frame(
  Level = c("2", "3", "4", "5", "Total"),
  Description = c(
    "Threat to use force", 
    "Display of force", 
    "Use of force",
    "Interstate war", 
    ""
  ),
  Examples = c(
    "Verbal threat, ultimatum", 
    "Mobilization, show of force, deployment",
    "Clash, border violation, seizure, blockade", 
    "Sustained combat ≥1,000 deaths", 
    ""
  ),
  N = c(
    format(as.numeric(hihost_counts[c("2","3","4","5")]), big.mark=","),
    format(nrow(mids_in_pr), big.mark=",")
  ),
  `%` = c(
    sprintf("%.1f", as.numeric(hihost_counts[c("2","3","4","5")])/nrow(mids_in_pr)*100),
    "100.0"
  ),
  check.names = FALSE
)

table4_note <- paste0(
  "N = ", format(nrow(mids_in_pr), big.mark=","), " MID observations in PR dyads ",
  "(83.7% of all MIDs 1973–2014). Hostility level 1 excluded by definition. ",
  "MID data from Maoz et al. (2019) Dyadic MID dataset v4.03."
)

#-------------------------------------------------------------------------------
# TABLE 5: Sample Descriptive Statistics
# Overall summary of the analytical sample
#-------------------------------------------------------------------------------

# Calculate summary statistics
n_dyad_years <- nrow(pr_dyads)
n_unique_dyads <- length(unique(pr_dyads$dyad_id))
n_states <- length(unique(c(pr_dyads$ccode1, pr_dyads$ccode2)))
n_years <- length(unique(pr_dyads$year))
n_mids_pr <- nrow(mids_in_pr)
n_mids_total <- nrow(mids_period)
n_unique_disputes <- length(unique(mids_in_pr$disno))

# Aggregate by year for means/ranges
dyads_per_year <- aggregate(
  dyad_id ~ year, 
  data = pr_dyads, 
  FUN = function(x) length(unique(x))
)
mids_per_year <- aggregate(
  disno ~ year, 
  data = mids_in_pr, 
  FUN = function(x) length(unique(x))
)

table5 <- data.frame(
  Statistic = c(
    "Sample period", 
    "Total dyad-years", 
    "Unique undirected dyads",
    "Unique directed dyads", 
    "States in sample", 
    "Years in sample",
    "Mean dyads per year", 
    "Dyads per year range", 
    "",
    "MID observations", 
    "Unique disputes", 
    "Mean MIDs per year",
    "MID capture rate"
  ),
  Value = c(
    "1973–2014", 
    format(n_dyad_years, big.mark=","), 
    format(n_unique_dyads, big.mark=","), 
    format(n_unique_dyads * 2, big.mark=","),
    as.character(n_states), 
    as.character(n_years),
    sprintf("%.0f", mean(dyads_per_year$dyad_id)),
    paste0(min(dyads_per_year$dyad_id), "–", max(dyads_per_year$dyad_id)), 
    "",
    format(n_mids_pr, big.mark=","), 
    format(n_unique_disputes, big.mark=","),
    sprintf("%.1f", mean(mids_per_year$disno)),
    paste0(sprintf("%.1f", n_mids_pr/n_mids_total*100), "%")
  ),
  check.names = FALSE
)

table5_note <- paste0(
  "PR dyads = dyads with ≥1 major power OR direct contiguity. ",
  "MID capture rate = MIDs in PR dyads / total MIDs. ",
  "Post-Bretton Woods era selected to ensure consistent international economic system."
)

#===============================================================================
# GENERATE HTML OUTPUT
#===============================================================================

# CSS styling for academic tables
css <- '
<style>
body { 
  font-family: "Times New Roman", Times, serif; 
  max-width: 900px; 
  margin: 40px auto; 
  padding: 20px;
  line-height: 1.6;
}
h1 { font-size: 24px; margin-bottom: 5px; }
h2 { font-size: 18px; color: #333; margin-top: 40px; }
.subtitle { color: #666; margin-bottom: 30px; }
.academic-table { 
  border-collapse: collapse; 
  width: 100%; 
  margin: 20px 0 10px 0;
  font-size: 12px;
}
.academic-table caption {
  text-align: left;
  font-weight: bold;
  font-size: 12px;
  padding-bottom: 8px;
  caption-side: top;
}
.academic-table thead tr {
  border-top: 2px solid black;
  border-bottom: 1px solid black;
}
.academic-table th {
  padding: 8px 12px;
  font-weight: bold;
  text-align: left;
}
.academic-table td {
  padding: 6px 12px;
}
.academic-table tbody tr:last-child {
  border-bottom: 2px solid black;
}
.academic-table .total-row td {
  font-weight: bold;
}
.table-note {
  font-size: 11px;
  padding-top: 8px;
  text-align: left;
  border: none !important;
}
.section-label {
  font-weight: bold;
  font-style: italic;
  padding-top: 12px !important;
}
hr { margin: 30px 0; border: none; border-top: 1px solid #ccc; }
</style>
'

# Assemble complete HTML document
html_output <- paste0(
  '<!DOCTYPE html>\n<html>\n<head>\n<meta charset="UTF-8">\n',
  '<title>Methods Tables - Trade Vulnerability & Conflict</title>\n',
  css,
  '\n</head>\n<body>\n',
  '<h1>Tables for Methods Section</h1>\n',
  '<p class="subtitle">Trade Vulnerability and Conflict Intensity Study<br>',
  'Sample: Politically Relevant Dyads, 1973–2014</p>\n',
  '<hr>\n\n',
  
  '<h2>Table 1</h2>\n',
  create_html_table(table1, "Composition of Politically Relevant Dyads, 1973–2014", 
                    table1_note, c("left", "right", "right")),
  '\n<hr>\n\n',
  
  '<h2>Table 2</h2>\n',
  create_html_table(table2, "Major Powers in Sample Period", 
                    table2_note, c("left", "center", "left", "center")),
  '\n<hr>\n\n',
  
  '<h2>Table 3</h2>\n',
  create_html_table(table3, "Distribution of Contiguity Types Among Contiguous Dyads, 1973–2014",
                    table3_note, c("left", "right", "right")),
  '\n<hr>\n\n',
  
  '<h2>Table 4</h2>\n',
  create_html_table(table4, "Distribution of MID Hostility Levels (Dependent Variable), 1973–2014",
                    table4_note, c("center", "left", "left", "right", "right")),
  '\n<hr>\n\n',
  
  '<h2>Table 5</h2>\n',
  create_html_table(table5, "Sample Descriptive Statistics",
                    table5_note, c("left", "right")),
  
  '\n</body>\n</html>'
)

# Write HTML file
writeLines(html_output, "methods_tables.html")
cat("Saved: methods_tables.html\n")

#===============================================================================
# EXPORT INDIVIDUAL TABLES AS CSV
#===============================================================================

write.csv(table1, "table1_composition.csv", row.names = FALSE)
write.csv(table2, "table2_major_powers.csv", row.names = FALSE)
write.csv(table3, "table3_contiguity.csv", row.names = FALSE)
write.csv(table4, "table4_hostility.csv", row.names = FALSE)
write.csv(table5, "table5_descriptives.csv", row.names = FALSE)

cat("Saved: table1-5 as CSV files\n")

#===============================================================================
# PRINT TABLES TO CONSOLE
#===============================================================================

cat("\n")
cat("================================================================\n")
cat("TABLE 1: Composition of Politically Relevant Dyads\n")
cat("================================================================\n")
print(table1, row.names = FALSE)
cat("\n")

cat("================================================================\n")
cat("TABLE 2: Major Powers in Sample Period\n")
cat("================================================================\n")
print(table2, row.names = FALSE)
cat("\n")

cat("================================================================\n")
cat("TABLE 3: Contiguity Types\n")
cat("================================================================\n")
print(table3, row.names = FALSE)
cat("\n")

cat("================================================================\n")
cat("TABLE 4: MID Hostility Levels (Your DV)\n")
cat("================================================================\n")
print(table4, row.names = FALSE)
cat("\n")

cat("================================================================\n")
cat("TABLE 5: Sample Descriptive Statistics\n")
cat("================================================================\n")
print(table5, row.names = FALSE)
cat("\n")

cat("================================================================\n")
cat("FILES CREATED:\n")
cat("  methods_tables.html - All tables formatted (open in browser)\n")
cat("  table1-5_*.csv - Individual tables as CSV\n")
cat("\nTO USE IN WORD:\n")
cat("  1. Open methods_tables.html in Chrome/Firefox\n")
cat("  2. Select table → Ctrl+C → Paste in Word\n")
cat("  3. Or: Open CSV in Excel → Format → Copy to Word\n")
cat("================================================================\n")

#===============================================================================
# END OF SCRIPT
#===============================================================================
