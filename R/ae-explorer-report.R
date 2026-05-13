#' Create AE Explorer report settings from a workr spec
#'
#' @param lSpec A `workr` workflow spec for the AE Explorer report.
#'
#' @return A list of domain mappings and known gaps for AE Explorer.
#' @export
MakeAeExplorerSettings <- function(lSpec) {
  if (is.null(lSpec$Mapped_SUBJ) || is.null(lSpec$Mapped_AE)) {
    stop("AE Explorer requires Mapped_SUBJ and Mapped_AE specs.", call. = FALSE)
  }

  list(
    domains = list(
      dm = "Mapped_SUBJ",
      aes = "Mapped_AE"
    ),
    settings = list(
      dm = list(
        id_col = "subjid",
        treatment_col = NULL
      ),
      aes = list(
        id_col = "subjid",
        term_col = "mdrpt_nsv",
        bodsys_col = "mdrsoc_nsv"
      )
    ),
    optional_filters = list(
      seriousness = "aeser",
      severity = "aetoxgr",
      relationship = "aerel"
    ),
    gaps = c(
      treatment_col = "No clear treatment/group field identified in current Mapped_SUBJ.",
      aeout = "No current Mapped_AE outcome field identified."
    )
  )
}

#' Create an AE Explorer report manifest
#'
#' This is the first workr-compatible output for the AE Explorer report. It does
#' not render the SafetyCharts widget yet; it records the report inputs,
#' mappings, and open data gaps that downstream rendering work will use.
#'
#' @param lData A named list of workflow data frames.
#' @param lSettings AE Explorer settings from [MakeAeExplorerSettings()].
#' @param lMeta Workflow metadata.
#'
#' @return A manifest list describing the AE Explorer report configuration.
#' @export
MakeAeExplorerManifest <- function(lData, lSettings, lMeta = list()) {
  required_domains <- unlist(lSettings$domains, use.names = FALSE)
  missing_domains <- setdiff(required_domains, names(lData))
  if (length(missing_domains) > 0) {
    stop(
      "AE Explorer missing required domain(s): ",
      paste(missing_domains, collapse = ", "),
      call. = FALSE
    )
  }

  list(
    report_id = lMeta$ID %||% "ae_explorer",
    report_type = lMeta$Type %||% "Report",
    output = lMeta$Output %||% "html",
    domains = lSettings$domains,
    settings = lSettings$settings,
    optional_filters = lSettings$optional_filters,
    gaps = lSettings$gaps,
    status = "scaffold"
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
