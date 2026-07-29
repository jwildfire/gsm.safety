#' Participant-level Hy's Law candidate tier from liver chemistry
#'
#' Scores every participant with liver chemistry against the eDISH quadrants the
#' `hep_explorer` chart already draws, using that chart's own cut-points from
#' `inst/schema/hep-explorer.json` (`cuts.defaults.relative_uln` = 3 for the
#' aminotransferases, `cuts.TB.relative_uln` = 2 for total bilirubin). Each
#' participant is reduced to their **peak** ×ULN value per measure — the same
#' one-point-per-participant reduction the chart performs — so a flag and the
#' point a reviewer sees on the chart are the same observation.
#'
#' The tier ladder, ordered by how much review the participant warrants:
#'
#' | Tier | eDISH region | Rule |
#' |---|---|---|
#' | 0 | normal | neither axis at its cut |
#' | 1 | Temple's Corollary *or* hyperbilirubinaemia | exactly one axis at its cut |
#' | 2 | both axes, cholestatic pattern | both axes at their cut, peak ALP at or above the cholestatic cut |
#' | 3 | **potential Hy's Law** | both axes at their cut, peak ALP below the cholestatic cut |
#'
#' Tier 3 is a *candidate*, not an adjudicated Hy's Law case. Two standard
#' criteria are deliberately out of scope here and belong to case review: the
#' requirement that the aminotransferase and bilirubin elevations be temporally
#' associated (peaks are taken independently, exactly as eDISH does), and the
#' exclusion of other causes of liver injury.
#'
#' @param dfLabs `data.frame` Long-format lab results, one row per participant
#'   per measure per visit.
#' @param strIDCol `character` Participant ID column. Default: `"subjid"`.
#' @param strMeasureCol `character` Column holding the measure name.
#'   Default: `"lbtstnam"`.
#' @param strValueCol `character` Numeric result column. Default: `"lbstresn"`.
#' @param strULNCol `character` Upper-limit-of-normal column, the denominator of
#'   the ×ULN standardisation. Default: `"lbstnrhi"`.
#' @param lMeasureValues `list` Map of the measure keys `ALT`, `AST`, `TB` and
#'   `ALP` to the measure strings in the data — the same mapping the chart's
#'   `measure_values` setting takes.
#' @param nAminotransferaseCut `numeric` ×ULN cut for ALT / AST. Default: `3`.
#' @param nBilirubinCut `numeric` ×ULN cut for total bilirubin. Default: `2`.
#' @param nCholestaticCut `numeric` ×ULN cut at or above which the pattern is
#'   read as cholestatic, holding the participant at tier 2. Default: `2`.
#' @param strGroupLevel `character` Group level to record. Default: `"Subject"`.
#'
#' @return `data.frame` conforming to `analyticsInput`, one row per participant
#'   with at least one usable liver result, carrying the peak ×ULN of each
#'   measure and the R ratio as evidence columns.
#'
#' @examples
#' dfLabs <- data.frame(
#'   subjid = rep(c("S1", "S2"), each = 4),
#'   lbtstnam = rep(c("ALT", "AST", "TB", "ALP"), 2),
#'   lbstresn = c(150, 120, 60, 90, 20, 25, 8, 80),
#'   lbstnrhi = c(40, 40, 20, 120, 40, 40, 20, 120)
#' )
#' Input_HysLaw(
#'   dfLabs,
#'   lMeasureValues = list(ALT = "ALT", AST = "AST", TB = "TB", ALP = "ALP")
#' )
#'
#' @export
Input_HysLaw <- function(
    dfLabs,
    strIDCol = "subjid",
    strMeasureCol = "lbtstnam",
    strValueCol = "lbstresn",
    strULNCol = "lbstnrhi",
    lMeasureValues = list(
      ALT = "Alanine Aminotransferase",
      AST = "Aspartate Aminotransferase",
      TB = "Bilirubin",
      ALP = "Alkaline Phosphatase"
    ),
    nAminotransferaseCut = 3,
    nBilirubinCut = 2,
    nCholestaticCut = 2,
    strGroupLevel = "Subject") {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfLabs),
    message = "dfLabs is not a data.frame"
  )
  for (strCol in c(strIDCol, strMeasureCol, strValueCol, strULNCol)) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(dfLabs)),
      message = paste0("Column '", strCol, "' not found in dfLabs")
    )
  }
  gsm.core::stop_if(
    cnd = !all(c("ALT", "AST", "TB", "ALP") %in% names(lMeasureValues)),
    message = "lMeasureValues must name ALT, AST, TB and ALP"
  )

  # Standardise to xULN, the scale the cut-points are expressed in.
  nULN <- suppressWarnings(as.numeric(dfLabs[[strULNCol]]))
  nValue <- suppressWarnings(as.numeric(dfLabs[[strValueCol]]))
  dfLabs$.xULN <- ifelse(is.finite(nULN) & nULN > 0, nValue / nULN, NA_real_)

  PeakFor <- function(strKey) {
    bRow <- as.character(dfLabs[[strMeasureCol]]) %in% lMeasureValues[[strKey]]
    PeakByParticipant(dfLabs[bRow, , drop = FALSE], strIDCol, ".xULN")
  }
  vALT <- PeakFor("ALT")
  vAST <- PeakFor("AST")
  vTB <- PeakFor("TB")
  vALP <- PeakFor("ALP")

  # Assessed = has at least one usable aminotransferase AND bilirubin result.
  # Either alone cannot place a participant in a quadrant.
  chrIDs <- sort(intersect(union(names(vALT), names(vAST)), names(vTB)))
  if (length(chrIDs) == 0) {
    return(MakeParticipantInput(
      data.frame(
        subjid = character(0), Numerator = numeric(0),
        stringsAsFactors = FALSE
      ),
      strIDCol = "subjid", strGroupLevel = strGroupLevel
    ))
  }

  nALT <- AlignToParticipants(vALT, chrIDs)
  nAST <- AlignToParticipants(vAST, chrIDs)
  nTB <- AlignToParticipants(vTB, chrIDs)
  nALP <- AlignToParticipants(vALP, chrIDs)
  nAT <- pmax(nALT, nAST, na.rm = TRUE)

  bHighAT <- !is.na(nAT) & nAT >= nAminotransferaseCut
  bHighTB <- !is.na(nTB) & nTB >= nBilirubinCut
  # ALP is the exclusion, so a missing ALP must not manufacture a tier 3:
  # without it the cholestatic pattern cannot be ruled out.
  bCholestatic <- is.na(nALP) | nALP >= nCholestaticCut

  nTier <- HighestTier(
    list(
      "1" = xor(bHighAT, bHighTB),
      "2" = bHighAT & bHighTB & bCholestatic,
      "3" = bHighAT & bHighTB & !bCholestatic
    ),
    length(chrIDs)
  )

  MakeParticipantInput(
    data.frame(
      subjid = chrIDs,
      Numerator = nTier,
      PeakALT_xULN = round(nALT, 3),
      PeakAST_xULN = round(nAST, 3),
      PeakTB_xULN = round(nTB, 3),
      PeakALP_xULN = round(nALP, 3),
      RRatio = round(nAT / nALP, 3),
      Quadrant = c(
        "Normal", "Single axis", "Both axes (cholestatic)",
        "Potential Hy's Law"
      )[nTier + 1],
      stringsAsFactors = FALSE
    ),
    strIDCol = "subjid",
    strGroupLevel = strGroupLevel
  )
}
