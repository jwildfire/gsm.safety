# Build the FDA reference-criteria datasets from the hand-checked CSVs.
#
# Source: FDA Standard Safety Tables and Figures: Integrated Guide, version 2.0
# (April 2025), Appendix section 5 — Table 56 and Table 57 (abnormality level
# criteria, section 5.1) and Tables 58 to 60 (extreme values suggestive of
# error, section 5.2). https://www.fda.gov/media/187065/download
#
# The CSVs beside this script are the transcription: one row per printed row,
# with the printed criterion text kept verbatim beside the parsed number, and a
# Note wherever a printed value needed an interpretation. Fix a transcription
# in the CSV, never in data/. Then, from the package root:
#
#   Rscript data-raw/fda-reference.R
#
# The script uses base R only, so it does not add usethis to the dependencies.

strGuideVersion <- "2.0"

ReadTranscription <- function(strFile) {
  utils::read.csv(
    file.path("data-raw", strFile),
    stringsAsFactors = FALSE,
    encoding = "UTF-8",
    na.strings = "",
    check.names = FALSE
  )
}

# ---- Tables 56 and 57: abnormality level criteria -------------------------

dfLevels <- ReadTranscription("fda_abnormality_levels.csv")

FDA_AbnormalityLevels <- data.frame(
  Table = as.integer(dfLevels$Table),
  Panel = dfLevels$Panel,
  Parameter = dfLevels$Parameter,
  Direction = dfLevels$Direction,
  Qualifier = dfLevels$Qualifier,
  Unit = dfLevels$Unit,
  Basis = dfLevels$Basis,
  Operator = dfLevels$Operator,
  Level1 = as.numeric(dfLevels$Level1),
  Level2 = as.numeric(dfLevels$Level2),
  Level3 = as.numeric(dfLevels$Level3),
  Level1Text = dfLevels$Level1Text,
  Level2Text = dfLevels$Level2Text,
  Level3Text = dfLevels$Level3Text,
  GuideVersion = strGuideVersion,
  GuideSection = ifelse(dfLevels$Table == 56, "5.1.1", "5.1.2"),
  GuidePage = as.integer(dfLevels$GuidePage),
  Note = dfLevels$Note,
  stringsAsFactors = FALSE
)

# ---- Tables 58 to 60: extreme values -----------------------------------------
#
# The guide prints each parameter once with a US-conventional and an SI column
# pair. The dataset is long: one row per parameter per unit system, so a
# derivation can join on the unit the data actually carries.

dfExtreme <- ReadTranscription("fda_extreme_values.csv")

OneSystem <- function(strSystem) {
  data.frame(
    Table = as.integer(dfExtreme$Table),
    Panel = dfExtreme$Panel,
    Parameter = dfExtreme$Parameter,
    Specimen = dfExtreme$Specimen,
    UnitSystem = strSystem,
    Unit = dfExtreme[[paste0("Unit", strSystem)]],
    Low = as.numeric(dfExtreme[[paste0("Low", strSystem)]]),
    High = as.numeric(dfExtreme[[paste0("High", strSystem)]]),
    References = as.character(dfExtreme$References),
    GuideVersion = strGuideVersion,
    GuideSection = c("58" = "5.2.1", "59" = "5.2.2", "60" = "5.2.3")[as.character(dfExtreme$Table)],
    GuidePage = as.integer(dfExtreme$GuidePage),
    Note = dfExtreme$Note,
    stringsAsFactors = FALSE
  )
}

FDA_ExtremeValues <- rbind(OneSystem("US"), OneSystem("SI"))
# Printed order: table, then row, with the two unit systems adjacent.
FDA_ExtremeValues <- FDA_ExtremeValues[
  order(FDA_ExtremeValues$Table, match(FDA_ExtremeValues$Parameter, dfExtreme$Parameter),
        match(FDA_ExtremeValues$UnitSystem, c("US", "SI"))), ,
  drop = FALSE
]
rownames(FDA_ExtremeValues) <- NULL

# ---- Write ---------------------------------------------------------------------

stopifnot(
  nrow(FDA_AbnormalityLevels) == 46,
  nrow(FDA_ExtremeValues) == 80,
  !anyNA(FDA_AbnormalityLevels$Operator),
  all(c("US", "SI") %in% FDA_ExtremeValues$UnitSystem)
)

dir.create("data", showWarnings = FALSE)
save(FDA_AbnormalityLevels, file = file.path("data", "FDA_AbnormalityLevels.rda"), compress = "bzip2", version = 2)
save(FDA_ExtremeValues, file = file.path("data", "FDA_ExtremeValues.rda"), compress = "bzip2", version = 2)

cat(
  "FDA_AbnormalityLevels:", nrow(FDA_AbnormalityLevels), "rows;",
  "FDA_ExtremeValues:", nrow(FDA_ExtremeValues), "rows\n"
)
