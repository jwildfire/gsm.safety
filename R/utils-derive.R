# Shared internals of the Derive_* functions: the guide's normative rules
# applied once, in R, over long-format results (obot.roadmap#9, phase 0).

#' Require a data frame with the named columns
#'
#' @param df The object to check.
#' @param chrCols `character` Column names that must be present.
#' @param strName `character` Name of the argument, for the message.
#'
#' @keywords internal
RequireResultColumns <- function(df, chrCols, strName = "dfResults") {
  gsm.core::stop_if(
    cnd = !is.data.frame(df),
    message = paste0(strName, " is not a data.frame")
  )
  for (strCol in chrCols) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(df)),
      message = paste0("Column '", strCol, "' not found in ", strName)
    )
  }
  invisible(df)
}

#' Resolve each record's test name to a reference-table parameter
#'
#' `lParameterValues` maps a reference-table `Parameter` to the test name (or
#' names) the data use for it, the way `lMeasureValues` does in
#' [Input_HysLaw()]. A test name that no entry names resolves to `NA`.
#'
#' @param chrTest `character` Test names, one per record.
#' @param lParameterValues Named `list` of `character`: names are reference
#'   parameters, values the data's test names.
#'
#' @return `character` of `length(chrTest)`: the parameter, or `NA`.
#'
#' @keywords internal
ResolveParameters <- function(chrTest, lParameterValues) {
  gsm.core::stop_if(
    cnd = !is.list(lParameterValues) || is.null(names(lParameterValues)) ||
      any(!nzchar(names(lParameterValues))),
    message = "lParameterValues must be a named list mapping parameters to test names"
  )
  chrLookup <- unlist(lapply(names(lParameterValues), function(strParam) {
    chrValues <- as.character(lParameterValues[[strParam]])
    stats::setNames(rep(strParam, length(chrValues)), chrValues)
  }))
  chrParameter <- unname(chrLookup[as.character(chrTest)])
  chrParameter[is.na(chrTest)] <- NA_character_
  chrParameter
}

#' Normalise a unit string for matching
#'
#' Case, spacing and the micro sign are presentation; a handful of spellings
#' the guide, CDISC and the example data use for the same unit are folded
#' together. Nothing here converts between units: `mg/dL` never matches
#' `mmol/L`, and mEq/L is folded onto mmol/L only per parameter, in
#' [UnitMatches()].
#'
#' @param chrUnit `character` Unit strings.
#'
#' @return `character` Normalised keys, `NA` where the input is missing.
#'
#' @keywords internal
NormaliseUnit <- function(chrUnit) {
  chrKey <- tolower(trimws(as.character(chrUnit)))
  chrKey <- gsub("\u00b5|\u03bc", "u", chrKey)
  chrKey <- gsub("\\s+", "", chrKey)
  chrKey <- gsub("^deg|\u00b0", "", chrKey)
  lSame <- list(
    # Giga per litre: the guide's "x 10^9 cells/L", the example data's GI/L,
    # CDISC's "10*9/L".
    "10^9/l" = c("gi/l", "x10^9/l", "x10^9cells/l", "10^9cells/l", "10e9/l", "10*9/l", "x10*9/l", "10*9cells/l"),
    "10^12/l" = c("ti/l", "x10^12/l", "10^12cells/l", "10*12/l", "x10*12/l"),
    "/ul" = c("cells/ul", "platelets/ul", "/mm3", "cells/mm3", "/mcl", "cells/mcl"),
    "beats/min" = c("bpm", "beats/minute", "/min_beats"),
    "breaths/min" = c("breaths/minute", "/min_breaths"),
    "c" = c("cel", "celsius"),
    "f" = c("fahrenheit", "far"),
    "seconds" = c("sec", "s"),
    "%" = c("percent", "pct")
  )
  for (strKey in names(lSame)) {
    chrKey[chrKey %in% lSame[[strKey]]] <- strKey
  }
  chrKey
}

#' Parameters for which one milliequivalent is one millimole
#'
#' The guide prints mEq/L for exactly these; for a divalent ion (calcium,
#' magnesium) the two units differ by a factor of two, so the fold is applied
#' per parameter, never globally.
#' @keywords internal
CHR_MONOVALENT <- c("Sodium", "Potassium", "Chloride", "Bicarbonate")

#' Does a record's unit match a criteria row's unit?
#'
#' Spellings are folded by [NormaliseUnit()]; mEq/L and mmol/L are treated as
#' the same unit only for the monovalent parameters in [CHR_MONOVALENT].
#' Nothing is converted.
#'
#' @param chrDataUnit `character` The records' units, already normalised.
#' @param strCriteriaUnit `character` The criteria row's unit, as printed.
#' @param strParameter `character` The criteria row's parameter.
#'
#' @return `logical` of `length(chrDataUnit)`; `FALSE` where the data unit is `NA`.
#'
#' @keywords internal
UnitMatches <- function(chrDataUnit, strCriteriaUnit, strParameter) {
  strCriteria <- NormaliseUnit(strCriteriaUnit)
  bMatch <- !is.na(chrDataUnit) & chrDataUnit == strCriteria
  if (strParameter %in% CHR_MONOVALENT) {
    chrEquivalent <- c("meq/l", "mmol/l")
    bMatch <- bMatch | (!is.na(chrDataUnit) & strCriteria %in% chrEquivalent & chrDataUnit %in% chrEquivalent)
  }
  bMatch
}

#' The result as a multiple of its own upper limit of normal
#'
#' The one rule behind [Derive_ULNMultiple()] and the ULN-multiple rows of
#' [Derive_AbnormalityLevel()]: value over ULN, `NA` where either is missing
#' or the ULN is not positive.
#'
#' @param nValue `numeric` Results.
#' @param nULN `numeric` Upper limits of normal, same length.
#'
#' @return `numeric` of `length(nValue)`.
#'
#' @keywords internal
ULNMultiple <- function(nValue, nULN) {
  nValue <- suppressWarnings(as.numeric(nValue))
  nULN <- suppressWarnings(as.numeric(nULN))
  bUsable <- is.finite(nValue) & is.finite(nULN) & nULN > 0
  nMultiple <- rep(NA_real_, length(nValue))
  nMultiple[bUsable] <- nValue[bUsable] / nULN[bUsable]
  nMultiple
}

#' Require that an output column name carries the token its siblings are derived from
#'
#' `Derive_AbnormalityLevel()` names its direction and criterion columns by
#' replacing `Level` in `strOutCol`; `Derive_ExtremeValueFlag()` replaces
#' `Flag`. A name without the token would collapse the outputs onto one column.
#'
#' @param strOutCol `character` The requested output column name.
#' @param strToken `character` The token it must contain.
#'
#' @keywords internal
RequireOutColToken <- function(strOutCol, strToken) {
  gsm.core::stop_if(
    cnd = !is.character(strOutCol) || length(strOutCol) != 1 || !grepl(strToken, strOutCol, fixed = TRUE),
    message = paste0("strOutCol must be a single name containing '", strToken, "' (its sibling columns are named from it)")
  )
  invisible(strOutCol)
}

#' Require that a derivation's output columns are new
#'
#' The `Derive_*` functions return the input frame with their columns
#' appended, dropping and replacing nothing. An output name that already
#' exists in the frame would be overwritten silently, so it is refused.
#'
#' @param df `data.frame` The input frame.
#' @param chrOutCols `character` The names the derivation is about to add.
#' @param strName `character` Name of the argument, for the message.
#'
#' @keywords internal
RequireNewColumns <- function(df, chrOutCols, strName = "dfResults") {
  chrExisting <- intersect(chrOutCols, names(df))
  gsm.core::stop_if(
    cnd = length(chrExisting) > 0,
    message = paste0(
      "Output column '", chrExisting[1], "' already exists in ", strName,
      "; the Derive_* functions append, they do not overwrite. ",
      "Choose another strOutCol or drop the column first"
    )
  )
  invisible(chrOutCols)
}

#' Say how many records a derivation could not evaluate, and why
#'
#' @param strWhat `character` What was being derived.
#' @param lSkipped Named `list` of `character` vectors: reason -> parameters.
#'
#' @keywords internal
ReportSkipped <- function(strWhat, lSkipped) {
  lSkipped <- lSkipped[vapply(lSkipped, length, integer(1)) > 0]
  if (length(lSkipped) == 0) {
    return(invisible(NULL))
  }
  chrLines <- vapply(names(lSkipped), function(strReason) {
    paste0("  ", strReason, ": ", paste(sort(unique(lSkipped[[strReason]])), collapse = ", "))
  }, character(1))
  message(paste0(strWhat, " left NA for records it could not evaluate:\n", paste(chrLines, collapse = "\n")))
  invisible(NULL)
}
