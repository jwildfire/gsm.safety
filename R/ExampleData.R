#' Example safety data
#'
#' Reads one of the example datasets vendored with the package, matching the
#' data used by the safety.viz demos. `adbds`, `adae`, and `adeg` are derived
#' from pharmaverseadam (CDISC Pilot 01 ADaM); `adbds` additionally carries two
#' synthetic cohorts the safety.viz demos append: the `CLD-*`
#' chronic-liver-disease cohort (64 participants with abnormal baseline liver
#' tests, for the hep-explorer's composite view, which the pilot's normal
#' baselines cannot exercise) and the `AKI-*` acute-kidney-injury cohort for the
#' nep-explorer (the pilot population alone puts every participant in the
#' KDIGO no-stage box); `adbds_abnbl` is the purpose-built synthetic
#' abnormal-baseline hepatic cohort for [Widget_HepWaterfall()] (the pilot
#' data cannot form that figure — see the safety.viz demo's data note):
#'
#' - `adbds`: long-format BDS labs and vitals results, one record per
#'   measurement (`USUBJID`, `SITE`, `SITEID`, `SEX`, `RACE`, `ARM`, `VISIT`,
#'   `VISITNUM`, `TEST`, `STRESU`, `STRESN`, `STNRLO`, `STNRHI`, `DY`,
#'   `ABLFL`). `DY` is the ADaM study day of the measurement and `ABLFL` is
#'   `"Y"` on the baseline record, so a chart can plot real days with
#'   `x_axis` and read the baseline with `baseline_col`.
#' - `adae`: adverse events, one record per event (`USUBJID`, `ARM`, `AESEQ`,
#'   `AEBODSYS`, `AEDECOD`, `AETERM`, `AESEV`, `AESER`, `ASTDY`, `AENDY`),
#'   plus one placeholder row per participant with no adverse events. A
#'   placeholder carries a blank `AEBODSYS` and exists so the
#'   [Widget_AeExplorer()] population denominator covers the whole safety
#'   population (254 participants, 217 of them with events) rather than only
#'   participants who reported an event.
#' - `adeg`: long-format ECG results, one record per measurement (`USUBJID`,
#'   `SITE`, `SITEID`, `SEX`, `RACE`, `AGE`, `ARM`, `VISIT`, `VISITNUM`,
#'   `PARAMCD`, `TEST`, `STRESU`, `STRESN`, `BASE`, `CHG`, `ABLFL`, `DY`),
#'   carrying QTcF, QTcB, and Heart Rate for [Widget_QtExplorer()].
#' - `adbds_abnbl`: long-format labs for 80 synthetic abnormal-baseline
#'   participants (`ABL-*`), same columns as `adbds`, for
#'   [Widget_HepWaterfall()].
#' - `adsl`: one row per participant (`USUBJID`, `ARM`, `EOSDY`, `EOSSTT`) —
#'   the analysis population, its treatment arm, and the follow-up-end study
#'   day at which an event-free participant is censored. This is
#'   [Widget_TimeToEvent()]'s denominator: the events frame says who had an
#'   event and when, and this says who was at risk and for how long.
#'
#' @param strDataset `character` Name of the example dataset to read. Default:
#'   `"adbds"`.
#'
#' @return A `data.frame` with numeric result/range/day columns and character
#'   columns otherwise.
#'
#' @examples
#' dfResults <- ExampleData("adbds")
#' head(dfResults)
#'
#' dfAE <- ExampleData("adae")
#' head(dfAE)
#'
#' dfEG <- ExampleData("adeg")
#' head(dfEG)
#'
#' dfSL <- ExampleData("adsl")
#' head(dfSL)
#'
#' @export
ExampleData <- function(strDataset = c("adbds", "adae", "adeg", "adbds_abnbl", "adsl")) {
  strDataset <- match.arg(strDataset)

  strPath <- system.file(
    "extdata",
    paste0(strDataset, ".csv.gz"),
    package = "gsm.safety"
  )
  gsm.core::stop_if(
    cnd = !nzchar(strPath),
    message = paste0("Example dataset '", strDataset, "' not found.")
  )

  dfData <- utils::read.csv(gzfile(strPath), colClasses = "character")

  chrNumericCols <- switch(strDataset,
    adbds = c("VISITNUM", "STRESN", "STNRLO", "STNRHI", "DY"),
    adbds_abnbl = c("VISITNUM", "STRESN", "STNRLO", "STNRHI", "DY"),
    adae = c("AESEQ", "ASTDY", "AENDY"),
    adeg = c("AGE", "VISITNUM", "STRESN", "BASE", "CHG", "DY"),
    adsl = c("EOSDY")
  )
  for (strCol in chrNumericCols) {
    dfData[[strCol]][!nzchar(dfData[[strCol]])] <- NA_character_
    dfData[[strCol]] <- as.numeric(dfData[[strCol]])
  }

  dfData
}
