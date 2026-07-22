#' Example safety data
#'
#' Reads one of the example datasets vendored with the package. All three are
#' derived from pharmaverseadam (CDISC Pilot 01 ADaM) and match the data used
#' by the safety.viz demos:
#'
#' - `adbds`: long-format BDS labs and vitals results, one record per
#'   measurement (`USUBJID`, `SITE`, `SITEID`, `SEX`, `RACE`, `ARM`, `VISIT`,
#'   `VISITNUM`, `TEST`, `STRESU`, `STRESN`, `STNRLO`, `STNRHI`).
#' - `adae`: adverse events, one record per event (`USUBJID`, `ARM`, `AESEQ`,
#'   `AEBODSYS`, `AEDECOD`, `AETERM`, `AESEV`, `AESER`, `ASTDY`, `AENDY`),
#'   plus one placeholder row per participant with no adverse events. A
#'   placeholder carries a blank `AEBODSYS` and exists so the
#'   [Widget_AeExplorer()] population denominator covers the whole safety
#'   population (254 participants, 217 of them with events) rather than only
#'   participants who reported an event.
#' - `adeg`: long-format ECG results, one record per measurement (`USUBJID`,
#'   `SITE`, `SITEID`, `SEX`, `RACE`, `AGE`, `ARM`, `VISIT`, `VISITNUM`,
#'   `PARAMCD`, `TEST`, `STRESU`, `STRESN`, `BASE`, `CHG`, `ABLFL`), carrying
#'   QTcF, QTcB, and Heart Rate for [Widget_QtExplorer()].
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
#' @export
ExampleData <- function(strDataset = c("adbds", "adae", "adeg")) {
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
    adbds = c("VISITNUM", "STRESN", "STNRLO", "STNRHI"),
    adae = c("AESEQ", "ASTDY", "AENDY"),
    adeg = c("AGE", "VISITNUM", "STRESN", "BASE", "CHG")
  )
  for (strCol in chrNumericCols) {
    dfData[[strCol]][!nzchar(dfData[[strCol]])] <- NA_character_
    dfData[[strCol]] <- as.numeric(dfData[[strCol]])
  }

  dfData
}
