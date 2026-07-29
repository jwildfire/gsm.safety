#' Participant-level QTc prolongation tier from ECG data
#'
#' Scores every participant with a post-baseline QTc against the ICH E14
#' outlier cut-points the `qt_explorer` chart already draws, taken from
#' `inst/schema/qt-explorer.json` (`absolute_thresholds: [450, 480, 500]`,
#' `change_thresholds: [30, 60]`). Both criteria matter: on the demo study the
#' absolute cut alone flags one participant while the change cut flags ten, so a
#' metric built on absolute values alone would have looked healthy and said
#' nothing.
#'
#' The tier ladder:
#'
#' | Tier | Rule |
#' |---|---|
#' | 0 | no post-baseline value at the lowest absolute cut and no change at the lowest change cut |
#' | 1 | max QTc at the first absolute cut (450 ms) *or* max change at the first change cut (30 ms) |
#' | 2 | max QTc at the second absolute cut (480 ms) |
#' | 3 | max QTc at the third absolute cut (500 ms) *or* max change at the second change cut (60 ms) |
#'
#' Tier 3 is the conventional ICH E14 outlier pair (>500 ms or >60 ms change).
#' Only post-baseline records are scored — a baseline value is the reference,
#' not a finding — and a participant with a baseline but no post-baseline ECG
#' gets no row, because an unmeasured interval is not a normal one.
#'
#' @param dfECG `data.frame` Long-format ECG records, one row per participant
#'   per parameter per visit.
#' @param strIDCol `character` Participant ID column. Default: `"subjid"`.
#' @param strMeasureCol `character` Column holding the ECG parameter name.
#'   Default: `"egtstnam"`.
#' @param strValueCol `character` Numeric result column. Default: `"egstresn"`.
#' @param strBaselineCol `character` Column holding the participant's baseline
#'   value. Default: `"egbase"`.
#' @param strChangeCol `character` Column holding change from baseline; when
#'   absent or non-numeric for a row, change is derived as value − baseline.
#'   Default: `"egchg"`.
#' @param strBaselineFlagCol `character` Baseline-record flag column, used to
#'   drop baseline records from scoring. Default: `"egblfl"`.
#' @param strMeasure `character` The corrected-QT parameter to score.
#'   Default: `"QTcF"`.
#' @param vAbsoluteThresholds `numeric` Ascending absolute cut-points in ms.
#'   Default: `c(450, 480, 500)`.
#' @param vChangeThresholds `numeric` Ascending change-from-baseline cut-points
#'   in ms. Default: `c(30, 60)`.
#' @param strGroupLevel `character` Group level to record. Default: `"Subject"`.
#'
#' @return `data.frame` conforming to `analyticsInput`, one row per participant
#'   with at least one post-baseline value, carrying the max absolute value, the
#'   max change and the baseline as evidence columns.
#'
#' @examples
#' dfECG <- data.frame(
#'   subjid = c("S1", "S1", "S2", "S2"),
#'   egtstnam = "QTcF",
#'   egstresn = c(400, 505, 390, 415),
#'   egbase = c(400, 400, 390, 390),
#'   egchg = c(0, 105, 0, 25),
#'   egblfl = c("Y", "", "Y", "")
#' )
#' Input_QtProlongation(dfECG)
#'
#' @export
Input_QtProlongation <- function(
    dfECG,
    strIDCol = "subjid",
    strMeasureCol = "egtstnam",
    strValueCol = "egstresn",
    strBaselineCol = "egbase",
    strChangeCol = "egchg",
    strBaselineFlagCol = "egblfl",
    strMeasure = "QTcF",
    vAbsoluteThresholds = c(450, 480, 500),
    vChangeThresholds = c(30, 60),
    strGroupLevel = "Subject") {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfECG),
    message = "dfECG is not a data.frame"
  )
  for (strCol in c(strIDCol, strMeasureCol, strValueCol)) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(dfECG)),
      message = paste0("Column '", strCol, "' not found in dfECG")
    )
  }
  gsm.core::stop_if(
    cnd = length(vAbsoluteThresholds) != 3,
    message = "vAbsoluteThresholds must hold three ascending cut-points"
  )
  gsm.core::stop_if(
    cnd = length(vChangeThresholds) != 2,
    message = "vChangeThresholds must hold two ascending cut-points"
  )

  dfQT <- dfECG[as.character(dfECG[[strMeasureCol]]) %in% strMeasure, , drop = FALSE]

  # Baseline records are the reference, not a finding. Where the data carries
  # no baseline flag, every record is treated as post-baseline.
  if (strBaselineFlagCol %in% names(dfQT)) {
    chrFlag <- toupper(trimws(as.character(dfQT[[strBaselineFlagCol]])))
    dfQT <- dfQT[!(chrFlag %in% c("Y", "YES", "TRUE", "1")), , drop = FALSE]
  }

  nValue <- suppressWarnings(as.numeric(dfQT[[strValueCol]]))
  nBase <- if (strBaselineCol %in% names(dfQT)) {
    suppressWarnings(as.numeric(dfQT[[strBaselineCol]]))
  } else {
    rep(NA_real_, nrow(dfQT))
  }
  nChange <- if (strChangeCol %in% names(dfQT)) {
    suppressWarnings(as.numeric(dfQT[[strChangeCol]]))
  } else {
    rep(NA_real_, nrow(dfQT))
  }
  dfQT$.value <- nValue
  dfQT$.change <- ifelse(is.finite(nChange), nChange, nValue - nBase)
  dfQT$.base <- nBase

  vMaxValue <- PeakByParticipant(dfQT, strIDCol, ".value")
  chrIDs <- sort(names(vMaxValue))
  if (length(chrIDs) == 0) {
    return(MakeParticipantInput(
      data.frame(
        subjid = character(0), Numerator = numeric(0),
        stringsAsFactors = FALSE
      ),
      strIDCol = "subjid", strGroupLevel = strGroupLevel
    ))
  }
  vMaxChange <- PeakByParticipant(dfQT, strIDCol, ".change")
  vBaseline <- PeakByParticipant(dfQT, strIDCol, ".base")

  nMax <- AlignToParticipants(vMaxValue, chrIDs)
  nMaxChange <- AlignToParticipants(vMaxChange, chrIDs)
  nBaseline <- AlignToParticipants(vBaseline, chrIDs)

  At <- function(nValues, nCut) !is.na(nValues) & nValues >= nCut

  nTier <- HighestTier(
    list(
      "1" = At(nMax, vAbsoluteThresholds[1]) | At(nMaxChange, vChangeThresholds[1]),
      "2" = At(nMax, vAbsoluteThresholds[2]),
      "3" = At(nMax, vAbsoluteThresholds[3]) | At(nMaxChange, vChangeThresholds[2])
    ),
    length(chrIDs)
  )

  MakeParticipantInput(
    data.frame(
      subjid = chrIDs,
      Numerator = nTier,
      Measure = strMeasure,
      MaxValue = round(nMax, 1),
      MaxChange = round(nMaxChange, 1),
      Baseline = round(nBaseline, 1),
      stringsAsFactors = FALSE
    ),
    strIDCol = "subjid",
    strGroupLevel = strGroupLevel
  )
}
