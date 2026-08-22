#!/usr/bin/env Rscript
# Qualify the eleven census metrics of #58 on the ecosystem's bundled study.
#
#   Rscript tools/qualify-census-metrics.R
#
# Measures every figure twice by two routes that share no code, prints the
# evidence beside what SafetyCensus() reports for the same study today, and
# exits non-zero if any pair disagrees. The recorded result is
# inst/qualification/census-metrics-qualification.md; the same two routes run in the test
# suite as tests/testthat/test-qualification-census-metrics.R.
#
# Route B  the study's records read directly with base R, no mapping package,
#          no metric, no gsm helper.
# Route A  the standard gsm.mapping mapping, then each saf00** workflow.
#
# saf0011 (participants with an ECG) has no second route: gsm.mapping ships no
# EG mapping and the bundled study carries no ECG records. That the metric
# stops rather than publishing a zero is asserted in the suite instead.

suppressMessages(library(gsm.core))

Rule <- function(strTitle) cat("\n", strTitle, "\n", strrep("-", nchar(strTitle)), "\n", sep = "")

# ---- Route B: the records, read directly ------------------------------------
lSource <- gsm.core::lSource
dfSubjects <- lSource$Raw_SUBJ
bEnrolled <- !is.na(dfSubjects$enrollyn) & dfSubjects$enrollyn == "Y"
chrEnrolled <- unique(as.character(dfSubjects$subjid[bEnrolled]))
dfEnrolled <- dfSubjects[bEnrolled & !duplicated(as.character(dfSubjects$subjid)), ]

InDomain <- function(df, strIDCol = "subjid", bKeep = NULL) {
  if (is.null(df)) {
    return(NA_integer_)
  }
  chrID <- as.character(df[[strIDCol]])
  if (!is.null(bKeep)) chrID <- chrID[bKeep]
  length(intersect(unique(chrID), chrEnrolled))
}

dfComp <- lSource$Raw_STUDCOMP
chrCompYN <- toupper(trimws(as.character(dfComp$compyn)))
dfRand <- lSource$Raw_Randomization
bRandomised <- !is.na(dfRand$subjid) &
  (is.na(dfRand$status) | dfRand$status != "Screen Failed")

nDaysOnStudy <- as.numeric(dfEnrolled$timeonstudy)
nDaysOnTreatment <- as.numeric(dfEnrolled$timeontreatment)
Total <- function(nDays) sum(nDays[is.finite(nDays) & nDays >= 0])
Contributing <- function(nDays) sum(is.finite(nDays) & nDays >= 0)

lRouteB <- list(
  saf0005 = c(length(chrEnrolled), length(chrEnrolled)),
  saf0006 = c(InDomain(dfRand, bKeep = bRandomised), length(chrEnrolled)),
  saf0007 = c(
    length(unique(as.character(dfEnrolled$subjid[!is.na(dfEnrolled$firstdosedate)]))),
    length(chrEnrolled)
  ),
  saf0008 = c(Total(nDaysOnStudy), Contributing(nDaysOnStudy)),
  saf0009 = c(Total(nDaysOnTreatment), Contributing(nDaysOnTreatment)),
  saf0010 = c(InDomain(lSource$Raw_LB), length(chrEnrolled)),
  saf0012 = c(InDomain(lSource$Raw_AE), length(chrEnrolled)),
  saf0013 = c(InDomain(dfComp), length(chrEnrolled)),
  saf0014 = c(InDomain(dfComp, bKeep = chrCompYN %in% "Y"), length(chrEnrolled)),
  saf0015 = c(InDomain(dfComp, bKeep = chrCompYN %in% "N"), length(chrEnrolled))
)

chrLabels <- c(
  saf0005 = "Enrolled participants",
  saf0006 = "Randomised participants",
  saf0007 = "Participants dosed",
  saf0008 = "Participant-days on study",
  saf0009 = "Participant-days on treatment",
  saf0010 = "Participants with a lab result",
  saf0012 = "Participants with a reported AE",
  saf0013 = "Participants with a disposition record",
  saf0014 = "Participants who completed",
  saf0015 = "Participants who discontinued"
)

Rule("Route B - the study's records, read directly (base R only)")
cat("Participants in Raw_SUBJ:                 ", nrow(dfSubjects), "\n")
cat("Enrolled (enrollyn == 'Y') - the anchor:  ", length(chrEnrolled), "\n")
cat("Raw_Randomization, distinct participants: ", length(unique(dfRand$subjid)), "\n")
cat("  of them enrolled:                       ", lRouteB$saf0006[1], "\n")
cat("Raw_STUDCOMP rows:                        ", nrow(dfComp), "\n")
cat("  distinct participants:                  ", length(unique(dfComp$subjid)), "\n")
cat("  of them enrolled:                       ", lRouteB$saf0013[1], "\n")
cat("  with no completion flag recorded:       ", sum(is.na(dfComp$compyn) | !nzchar(chrCompYN)), "\n")
cat(
  "Enrolled with timeontreatment > 0:        ", sum(nDaysOnTreatment > 0, na.rm = TRUE),
  "  <- what SafetyCensus() calls dosed\n"
)
cat(
  "Raw_EG (the ECG domain):                  ",
  if (is.null(lSource$Raw_EG)) "absent - no ECG records in this study" else nrow(lSource$Raw_EG), "\n"
)

# ---- Route A: the standard mapping, then each metric ------------------------
if (!requireNamespace("gsm.mapping", quietly = TRUE)) {
  cat("\ngsm.mapping is not installed; route A skipped.\n")
  quit(status = 1)
}

lWorkflows <- gsm.core::MakeWorkflowList(
  strNames = c(
    "SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death", "AE", "LB"
  ),
  strPackage = "gsm.mapping"
)
lMapped <- suppressWarnings(suppressMessages({
  lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
  gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(lSource, lSpec))
}))

RunMetric <- function(strID) {
  suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
    yaml::read_yaml(system.file(
      "workflow", "2_metrics", paste0(strID, ".yaml"),
      package = "gsm.safety"
    )),
    lData = lMapped
  )))$Analysis_Summary
}

Rule("Route A - the standard mapping, then each saf00** workflow")
cat("Mapped_SUBJ rows (the enrolled population):", nrow(lMapped$Mapped_SUBJ), "\n\n")
cat(sprintf(
  "%-9s %-40s %12s %12s %8s\n", "ID", "Figure", "Route A", "Route B", "Flag"
))
bAgree <- TRUE
for (strID in names(lRouteB)) {
  dfSummary <- RunMetric(strID)
  nA <- if (nrow(dfSummary) == 1) dfSummary$Numerator else NA_real_
  nB <- lRouteB[[strID]][1]
  bThis <- isTRUE(all.equal(as.numeric(nA), as.numeric(nB)))
  bAgree <- bAgree && bThis && nrow(dfSummary) == 1L
  cat(sprintf(
    "%-9s %-40s %12s %12s %8s%s\n",
    strID, chrLabels[[strID]], format(nA), format(nB),
    if (nrow(dfSummary) == 1 && is.na(dfSummary$Flag)) "(empty)" else format(dfSummary$Flag),
    if (bThis) "" else "   <- DISAGREE"
  ))
  if (nrow(dfSummary) == 1 && !isTRUE(all.equal(
    as.numeric(dfSummary$Denominator), as.numeric(lRouteB[[strID]][2])
  ))) {
    cat("           denominator disagrees: route A ", dfSummary$Denominator,
      ", route B ", lRouteB[[strID]][2], "\n",
      sep = ""
    )
    bAgree <- FALSE
  }
}

# saf0011 has no domain on this study. The designed behaviour is to stop.
Rule("saf0011 - participants with an ECG")
bStopped <- inherits(try(suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
  yaml::read_yaml(system.file(
    "workflow", "2_metrics", "saf0011.yaml",
    package = "gsm.safety"
  )),
  lData = lMapped
))), silent = TRUE), "try-error")
cat("Mapped_EG on this study:  absent (gsm.mapping ships no EG mapping)\n")
cat("The metric:               ", if (bStopped) "stops" else "PUBLISHED A FIGURE", "\n")
cat("What it must never do:    publish a zero\n")

# ---- What the function reports today ----------------------------------------
Rule("What SafetyCensus() reports for the same study today")
lCensus <- suppressWarnings(suppressMessages(gsm.safety::SafetyCensus(
  dfSubjects = lMapped$Mapped_SUBJ,
  dfLabs = lMapped$Mapped_LB,
  dfECG = NULL,
  dfAE = lMapped$Mapped_AE,
  dfDisposition = lMapped$Mapped_STUDCOMP
)))
print(lCensus$Census)

Rule("Verdict")
cat(
  "gsm.core / gsm.mapping:  ",
  as.character(utils::packageVersion("gsm.core")), "/",
  as.character(utils::packageVersion("gsm.mapping")), "\n"
)
if (!bAgree || !bStopped) {
  cat("\nDISAGREE - at least one figure does not survive its second route.\n")
  quit(status = 1)
}
cat("\nAGREE - every figure measured twice, and saf0011 stops rather than publishing a zero.\n")
