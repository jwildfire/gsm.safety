#' Publish a metric's rows without a flag
#'
#' The step a **descriptive** metric calls where a flagging metric calls
#' `gsm.core::Flag()`. It adds the `Flag` column `gsm.core::Summarize()`
#' requires and leaves it empty.
#'
#' Empty, not zero. `0` is a flag value that means *measured and found fine* —
#' a green light. `NA` is the ecosystem's existing way of saying this number
#' does not flag: gsm.kri's `srs0001` site risk score has published its rows
#' that way in production throughout, declaring no threshold and calling no
#' flagging step. Because a metric with no threshold contributes no weights,
#' `gsm.kri`'s risk-score builder skips it automatically, so a descriptive
#' metric cannot move a site's risk score.
#'
#' @param dfAnalyzed `data.frame` Output of an `Analyze_*` step, carrying at
#'   least `Score`.
#'
#' @return `dfAnalyzed` with an integer `Flag` column of `NA`.
#'
#' @examples
#' dfAnalyzed <- data.frame(
#'   GroupID = "AA-AA-000-0000", GroupLevel = "Study",
#'   Numerator = 12, Denominator = 760, Metric = 12 / 760, Score = 12
#' )
#' Flag_None(dfAnalyzed)
#'
#' @export
Flag_None <- function(dfAnalyzed) {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfAnalyzed),
    message = "dfAnalyzed is not a data.frame"
  )
  gsm.core::stop_if(
    cnd = !("Score" %in% names(dfAnalyzed)),
    message = "Column 'Score' not found in dfAnalyzed"
  )
  gsm.core::stop_if(
    cnd = "Flag" %in% names(dfAnalyzed) && !all(is.na(dfAnalyzed$Flag)),
    message = paste0(
      "dfAnalyzed already carries a populated `Flag` column; ",
      "Flag_None() will not erase another step's flag"
    )
  )

  # rep(), not a length-1 constant: a zero-row frame must stay zero-row.
  dfAnalyzed$Flag <- rep(NA_integer_, nrow(dfAnalyzed))
  dfAnalyzed
}
