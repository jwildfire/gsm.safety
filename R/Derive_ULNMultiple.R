#' Express a result as a multiple of its upper limit of normal
#'
#' Adds one numeric column: the result divided by the record's own upper limit
#' of normal. This is the scale the FDA Standard Safety Tables and Figures
#' Integrated Guide (v2.0) draws the DILI screening plots on (Figures 7 and 8,
#' section 2.4.4) and the scale every `x ULN` threshold in its Appendix Tables
#' 56 and 57 is read on. The guide normalises to the *reported* ULN because
#' normal ranges vary between laboratory sites, so the denominator is the
#' record's own, never a study-wide constant. Requirement `FDA-RULE-001` in
#' `requirements/fda-stf.md`.
#'
#' The multiple is `NA` where the result is missing or the ULN is missing,
#' non-numeric or not positive. Nothing is dropped and nothing is aggregated:
#' the input frame comes back with the column added, in its original row
#' order (the design's L1 contract). [Input_HysLaw()] computes the same
#' quantity internally for its peak-per-participant reduction; the two agree
#' record for record.
#'
#' @param dfResults `data.frame` Long-format results, one row per participant
#'   per test per visit, in the shape of `ExampleData("adbds")`.
#' @param strValueCol `character` Numeric result column. Default: `"STRESN"`.
#' @param strULNCol `character` Upper-limit-of-normal column. Default:
#'   `"STNRHI"`.
#' @param strOutCol `character` Name of the column to add. Default:
#'   `"ULNMultiple"`.
#'
#' @return `dfResults` with `strOutCol` appended: `numeric`, the result as a
#'   multiple of ULN, `NA` where it cannot be formed.
#'
#' @examples
#' dfLabs <- ExampleData("adbds")
#' dfLabs <- Derive_ULNMultiple(dfLabs)
#' dfALT <- dfLabs[dfLabs$TEST == "Alanine Aminotransferase", ]
#' head(dfALT[, c("USUBJID", "VISIT", "STRESN", "STNRHI", "ULNMultiple")])
#'
#' @seealso [Derive_AbnormalityLevel()], which grades the multiple against
#'   Tables 56 and 57; [Input_HysLaw()], which reduces it to a peak per
#'   participant.
#' @family FDA derivations
#' @export
Derive_ULNMultiple <- function(
    dfResults,
    strValueCol = "STRESN",
    strULNCol = "STNRHI",
    strOutCol = "ULNMultiple") {
  RequireResultColumns(dfResults, c(strValueCol, strULNCol))

  nValue <- suppressWarnings(as.numeric(dfResults[[strValueCol]]))
  nULN <- suppressWarnings(as.numeric(dfResults[[strULNCol]]))
  bUsable <- is.finite(nValue) & is.finite(nULN) & nULN > 0

  nMultiple <- rep(NA_real_, nrow(dfResults))
  nMultiple[bUsable] <- nValue[bUsable] / nULN[bUsable]

  dfResults[[strOutCol]] <- nMultiple
  dfResults
}
