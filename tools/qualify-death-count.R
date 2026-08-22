#!/usr/bin/env Rscript
# Qualify the saf0004 death count on the ecosystem's bundled study.
#
#   Rscript tools/qualify-death-count.R
#
# Measures the count twice by two routes that share no code, prints the
# evidence, and exits non-zero if they disagree. The recorded result is
# inst/qualification/death-count-qualification.md; the same two routes run in the test
# suite as tests/testthat/test-qualification-death-count.R.
#
# Route B  the study's death records read directly with base R.
# Route A  the standard gsm.mapping mapping, then the saf0004 workflow.

suppressMessages(library(gsm.core))

Rule <- function(strTitle) cat("\n", strTitle, "\n", strrep("-", nchar(strTitle)), "\n", sep = "")

# ---- Route B: the records, read directly ------------------------------------
lSource <- gsm.core::lSource
dfSubjects <- lSource$Raw_SUBJ
chrEnrolled <- unique(as.character(dfSubjects$subjid[dfSubjects$enrollyn == "Y"]))

dfDeath <- lSource$Raw_Death
chrDeathDomain <- unique(as.character(dfDeath$subjid[!is.na(dfDeath$death_dt)]))

dfComp <- lSource$Raw_STUDCOMP
chrDiscontinuation <- unique(as.character(
  dfComp$subjid[!is.na(dfComp$compreas) & dfComp$compreas == "Death"]
))

chrUnion <- union(chrDeathDomain, chrDiscontinuation)
chrUnionEnrolled <- intersect(chrUnion, chrEnrolled)
chrNotEnrolled <- setdiff(chrUnion, chrEnrolled)

Rule("Route B - the death records, read directly (base R only)")
cat("Participants in Raw_SUBJ:                 ", nrow(dfSubjects), "\n")
cat("Enrolled (enrollyn == 'Y'):               ", length(chrEnrolled), "\n")
cat("Death domain, distinct participants:      ", length(chrDeathDomain), "\n")
cat("Discontinuation reason 'Death':           ", length(chrDiscontinuation),
  " (", paste(chrDiscontinuation, collapse = ", "), ")\n",
  sep = ""
)
cat("Named by both sources:                    ", length(intersect(chrDeathDomain, chrDiscontinuation)), "\n")
cat("UNION, all participants:                  ", length(chrUnion), "\n")
cat("UNION, enrolled participants only:        ", length(chrUnionEnrolled), "\n")
cat("In the union but never enrolled:          ", length(chrNotEnrolled),
  if (length(chrNotEnrolled)) paste0(" (", paste(chrNotEnrolled, collapse = ", "), ")") else "", "\n",
  sep = ""
)

# ---- Route A: the standard mapping, then the metric -------------------------
if (!requireNamespace("gsm.mapping", quietly = TRUE)) {
  cat("\ngsm.mapping is not installed; route A skipped.\n")
  quit(status = 1)
}

lWorkflows <- gsm.core::MakeWorkflowList(
  strNames = c("SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death"),
  strPackage = "gsm.mapping"
)
lMapped <- suppressWarnings(suppressMessages({
  lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
  gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(lSource, lSpec))
}))
dfMappedDeath <- lMapped$Mapped_Death
nMappedDeaths <- length(unique(
  dfMappedDeath$subjid[!is.na(dfMappedDeath$death) & dfMappedDeath$death]
))

lResult <- suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
  yaml::read_yaml(system.file(
    "workflow", "2_metrics", "saf0004.yaml",
    package = "gsm.safety"
  )),
  lData = lMapped
)))
dfSummary <- lResult$Analysis_Summary

Rule("Route A - the standard mapping, then the saf0004 workflow")
cat("Mapped_SUBJ rows (the enrolled population):", nrow(lMapped$Mapped_SUBJ), "\n")
cat("Mapped_Death, participants marked died:    ", nMappedDeaths, "\n")
print(as.data.frame(dfSummary))

Rule("Verdict")
nRouteA <- dfSummary$Numerator
nRouteB <- length(chrUnionEnrolled)
cat("Route A (metric):        ", nRouteA, "\n")
cat("Route B (records):       ", nRouteB, "\n")
cat("Flag published:          ", format(dfSummary$Flag), " (empty = does not flag)\n")
cat("gsm.core / gsm.mapping:  ",
  as.character(utils::packageVersion("gsm.core")), "/",
  as.character(utils::packageVersion("gsm.mapping")), "\n"
)

if (!isTRUE(all.equal(as.numeric(nRouteA), as.numeric(nRouteB))) || nrow(dfSummary) != 1L) {
  cat("\nDISAGREE - the two routes do not land on the same number.\n")
  quit(status = 1)
}
cat("\nAGREE -", nRouteA, "participants, of", dfSummary$Denominator, "enrolled.\n")
