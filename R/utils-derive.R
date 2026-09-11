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
  out <- unname(chrLookup[as.character(chrTest)])
  out[is.na(chrTest)] <- NA_character_
  out
}

#' Normalise a unit string for matching
#'
#' Case, spacing and the micro sign are presentation; a handful of spellings
#' the guide and the example data use for the same unit are folded together.
#' Nothing here converts between units: `mg/dL` never matches `mmol/L`.
#'
#' @param chrUnit `character` Unit strings.
#'
#' @return `character` Normalised keys, `NA` where the input is missing.
#'
#' @keywords internal
NormaliseUnit <- function(chrUnit) {
  x <- tolower(trimws(as.character(chrUnit)))
  x <- gsub("\u00b5|\u03bc", "u", x)
  x <- gsub("\\s+", "", x)
  x <- gsub("^deg|\u00b0", "", x)
  lSame <- list(
    # The monovalent electrolytes: 1 mEq = 1 mmol, and every mEq/L row in the
    # guide is one of them (sodium, potassium, chloride, bicarbonate).
    "mmol/l" = c("meq/l"),
    # Giga per litre: the guide's "x 10^9 cells/L", the example data's GI/L.
    "10^9/l" = c("gi/l", "x10^9/l", "x10^9cells/l", "10^9cells/l", "10e9/l", "g/l_cells"),
    "10^12/l" = c("ti/l", "x10^12/l", "10^12cells/l"),
    "/ul" = c("cells/ul", "platelets/ul", "/mm3", "cells/mm3", "/mcl"),
    "beats/min" = c("bpm", "beats/minute", "/min_beats"),
    "breaths/min" = c("breaths/minute", "/min_breaths"),
    "c" = c("cel", "celsius"),
    "f" = c("fahrenheit", "far"),
    "seconds" = c("sec", "s"),
    "%" = c("percent", "pct")
  )
  for (strKey in names(lSame)) {
    x[x %in% lSame[[strKey]]] <- strKey
  }
  x
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
