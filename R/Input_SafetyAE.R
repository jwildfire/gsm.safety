#' Participant-level serious / related / discontinuation AE tier
#'
#' Scores every participant against the seriousness, causality and action-taken
#' fields the `ae_explorer` and `ae_timelines` charts already filter on.
#'
#' Unlike the liver and QT metrics, this one has no published cut-point to
#' inherit — seriousness and relatedness are flags, not scales — so the tier
#' ladder is the design decision, and it is the difference between a review
#' queue and a list of most of the study. Measured on the demo study, "any
#' serious AE" reaches 41.7% of participants and "any related AE" 67.8%: neither
#' triages anything. Severity is what separates them:
#'
#' | Tier | Rule |
#' |---|---|
#' | 0 | no serious, related or discontinuation AE |
#' | 1 | a related AE, not serious |
#' | 2 | a serious AE, or an AE whose action taken was study-drug discontinuation |
#' | 3 | a serious **and** related AE at or above the severity grade cut |
#'
#' Tier 3 defaults to CTCAE grade 4 (life-threatening), the shape of an expedited
#' safety report: serious, related, and severe enough that the reviewer's
#' question is causality rather than triage.
#'
#' The discontinuation leg is only as good as the source column. `strActionCol`
#' names the AE action-taken field; when it is `NULL` or absent from the data,
#' that leg is inactive and the returned frame records `ActionColumnPresent =
#' FALSE`, so a study missing the column reports the gap rather than silently
#' scoring as though no participant ever discontinued.
#'
#' @param dfAE `data.frame` Long-format adverse events, one row per event.
#' @param strIDCol `character` Participant ID column. Default: `"subjid"`.
#' @param strSeriousCol `character` Seriousness flag column. Default: `"aeser"`.
#' @param strRelatedCol `character` Causality / relatedness flag column.
#'   Default: `"aerel"`.
#' @param strGradeCol `character` Numeric severity grade column (CTCAE).
#'   Default: `"aetoxgr"`.
#' @param strActionCol `character` or `NULL` Action-taken column; the
#'   discontinuation leg reads this. Default: `NULL` — inactive.
#' @param chrYesValues `character` Values of the flag columns read as "yes".
#'   Default: `c("Y", "YES", "TRUE", "1")`.
#' @param chrDiscontinuationValues `character` Values of `strActionCol` read as
#'   study-drug discontinuation.
#'   Default: `c("DRUG WITHDRAWN", "DISCONTINUED", "PERMANENTLY DISCONTINUED")`.
#' @param nSeriousRelatedGrade `numeric` Severity grade at or above which a
#'   serious, related AE reaches tier 3. Default: `4`.
#' @param dfSubjects `data.frame` or `NULL` Subject-level domain. When supplied,
#'   every enrolled participant is scored, so a participant with no AE at all is
#'   an explicit tier 0 rather than an absent row — for this metric absence of
#'   events is a real finding, not missing data. Default: `NULL`.
#' @param strSubjectIDCol `character` Participant ID column in `dfSubjects`.
#'   Default: `"subjid"`.
#' @param strGroupLevel `character` Group level to record. Default: `"Subject"`.
#'
#' @return `data.frame` conforming to `analyticsInput`, one row per participant,
#'   carrying the counts behind the tier as evidence columns.
#'
#' @examples
#' dfAE <- data.frame(
#'   subjid = c("S1", "S1", "S2"),
#'   aeser = c("Y", "N", "N"),
#'   aerel = c("Y", "Y", "Y"),
#'   aetoxgr = c(4, 1, 2)
#' )
#' Input_SafetyAE(dfAE)
#'
#' @export
Input_SafetyAE <- function(
    dfAE,
    strIDCol = "subjid",
    strSeriousCol = "aeser",
    strRelatedCol = "aerel",
    strGradeCol = "aetoxgr",
    strActionCol = NULL,
    chrYesValues = c("Y", "YES", "TRUE", "1"),
    chrDiscontinuationValues = c(
      "DRUG WITHDRAWN", "DISCONTINUED", "PERMANENTLY DISCONTINUED"
    ),
    nSeriousRelatedGrade = 4,
    dfSubjects = NULL,
    strSubjectIDCol = "subjid",
    strGroupLevel = "Subject") {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfAE),
    message = "dfAE is not a data.frame"
  )
  for (strCol in c(strIDCol, strSeriousCol, strRelatedCol)) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(dfAE)),
      message = paste0("Column '", strCol, "' not found in dfAE")
    )
  }

  IsYes <- function(x) toupper(trimws(as.character(x))) %in% toupper(chrYesValues)
  bSerious <- IsYes(dfAE[[strSeriousCol]])
  bRelated <- IsYes(dfAE[[strRelatedCol]])
  nGrade <- if (strGradeCol %in% names(dfAE)) {
    suppressWarnings(as.numeric(dfAE[[strGradeCol]]))
  } else {
    rep(NA_real_, nrow(dfAE))
  }

  bActionPresent <- !is.null(strActionCol) && strActionCol %in% names(dfAE)
  bDiscontinued <- if (bActionPresent) {
    toupper(trimws(as.character(dfAE[[strActionCol]]))) %in%
      toupper(chrDiscontinuationValues)
  } else {
    rep(FALSE, nrow(dfAE))
  }

  bTier3 <- bSerious & bRelated & !is.na(nGrade) & nGrade >= nSeriousRelatedGrade

  chrAEID <- as.character(dfAE[[strIDCol]])
  AnyBy <- function(b) tapply(b, chrAEID, any)
  CountBy <- function(b) tapply(b, chrAEID, sum)

  vTier3 <- AnyBy(bTier3)
  vSerious <- AnyBy(bSerious)
  vRelated <- AnyBy(bRelated)
  vDisc <- AnyBy(bDiscontinued)
  vNSerious <- CountBy(bSerious)
  vNRelated <- CountBy(bRelated)
  vNTotal <- CountBy(rep(TRUE, nrow(dfAE)))

  chrIDs <- if (!is.null(dfSubjects) && strSubjectIDCol %in% names(dfSubjects)) {
    sort(unique(as.character(dfSubjects[[strSubjectIDCol]])))
  } else {
    sort(unique(chrAEID))
  }

  Fill <- function(v, default = 0) {
    out <- v[chrIDs]
    out[is.na(out)] <- default
    as.numeric(out)
  }
  bAnyTier3 <- Fill(vTier3) > 0
  bAnySerious <- Fill(vSerious) > 0
  bAnyRelated <- Fill(vRelated) > 0
  bAnyDisc <- Fill(vDisc) > 0

  nTier <- HighestTier(
    list(
      "1" = bAnyRelated,
      "2" = bAnySerious | bAnyDisc,
      "3" = bAnyTier3
    ),
    length(chrIDs)
  )

  MakeParticipantInput(
    data.frame(
      subjid = chrIDs,
      Numerator = nTier,
      AECount = Fill(vNTotal),
      SeriousCount = Fill(vNSerious),
      RelatedCount = Fill(vNRelated),
      SeriousAndRelated = bAnyTier3,
      Discontinuation = bAnyDisc,
      ActionColumnPresent = bActionPresent,
      stringsAsFactors = FALSE
    ),
    strIDCol = "subjid",
    strGroupLevel = strGroupLevel
  )
}
