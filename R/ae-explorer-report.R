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

  aes_settings <- lSettings$settings$aes
  missing_columns <- required_columns(
    lData[[lSettings$domains$aes]],
    c(aes_settings$id_col, aes_settings$term_col, aes_settings$bodsys_col),
    lSettings$domains$aes
  )
  if (length(missing_columns) > 0) {
    stop(paste(missing_columns, collapse = "\n"), call. = FALSE)
  }

  list(
    report_id = lMeta$ID %||% "ae_explorer",
    report_type = lMeta$Type %||% "Report",
    output = lMeta$Output %||% "html",
    domains = lSettings$domains,
    settings = lSettings$settings,
    optional_filters = lSettings$optional_filters,
    gaps = lSettings$gaps,
    status = "ready"
  )
}

#' Render an interactive AE Explorer report
#'
#' This report artifact validates mapped AE inputs, calls
#' [safetyCharts::aeExplorer()] to create the interactive AE Explorer widget,
#' and writes a standalone HTML file that can be attached to a workflow run or
#' shown in pkgdown examples.
#'
#' @param lData A named list containing `Mapped_SUBJ` and `Mapped_AE` data frames.
#' @param lSettings AE Explorer settings from [MakeAeExplorerSettings()].
#' @param lManifest AE Explorer manifest from [MakeAeExplorerManifest()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when
#'   absent.
#'
#' @return A list with the report path, htmlwidget, manifest, and summary tables.
#' @export
Report_AE_Explorer <- function(lData,
                               lSettings,
                               lManifest,
                               strOutputDir = getwd(),
                               strOutputFile = "ae_explorer") {
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }

  aes_domain <- lSettings$domains$aes
  dm_domain <- lSettings$domains$dm
  df_ae <- lData[[aes_domain]]
  df_dm <- lData[[dm_domain]]

  aes_settings <- lSettings$settings$aes
  dm_settings <- lSettings$settings$dm

  missing_columns <- c(
    required_columns(df_dm, dm_settings$id_col, dm_domain),
    required_columns(df_ae, c(aes_settings$id_col, aes_settings$term_col, aes_settings$bodsys_col), aes_domain)
  )
  if (length(missing_columns) > 0) {
    stop(paste(missing_columns, collapse = "\n"), call. = FALSE)
  }

  term_summary <- count_values(df_ae, aes_settings$term_col)
  body_system_summary <- count_values(df_ae, aes_settings$bodsys_col)

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(strOutputDir, strOutputFile)

  widget <- safetyCharts::aeExplorer(
    data = list(
      dm = df_dm,
      aes = df_ae
    ),
    mapping = lSettings$settings
  )
  htmlwidgets::saveWidget(widget, file = strOutputPath, selfcontained = TRUE)

  list(
    path = normalizePath(strOutputPath, winslash = "/", mustWork = FALSE),
    widget = widget,
    manifest = lManifest,
    summaries = list(
      terms = term_summary,
      body_systems = body_system_summary
    )
  )
}

#' Create small example data for the AE Explorer report
#'
#' @return A named list containing `Mapped_SUBJ` and `Mapped_AE` example data.
#' @export
MakeAeExplorerExampleData <- function() {
  list(
    Mapped_SUBJ = data.frame(
      subjid = sprintf("SUBJ-%03d", 1:6),
      stringsAsFactors = FALSE
    ),
    Mapped_AE = data.frame(
      subjid = c("SUBJ-001", "SUBJ-001", "SUBJ-002", "SUBJ-003", "SUBJ-004", "SUBJ-006"),
      mdrpt_nsv = c("Headache", "Nausea", "Headache", "Fatigue", "Nausea", "Dizziness"),
      mdrsoc_nsv = c(
        "Nervous system disorders",
        "Gastrointestinal disorders",
        "Nervous system disorders",
        "General disorders",
        "Gastrointestinal disorders",
        "Nervous system disorders"
      ),
      aeser = c("N", "N", "N", "N", "Y", "N"),
      aetoxgr = c(1L, 1L, 2L, 1L, 3L, 1L),
      aerel = c("Possible", "Possible", "Unrelated", "Possible", "Probable", "Unrelated"),
      stringsAsFactors = FALSE
    )
  )
}

required_columns <- function(df, columns, domain) {
  columns <- columns[!is.na(columns) & nzchar(columns)]
  missing <- setdiff(columns, names(df))
  if (length(missing) == 0) {
    character()
  } else {
    paste0(domain, " is missing required column: ", missing)
  }
}

count_values <- function(df, column) {
  values <- df[[column]]
  values[is.na(values) | !nzchar(as.character(values))] <- "<Missing>"
  counts <- sort(table(values), decreasing = TRUE)
  data.frame(
    value = names(counts),
    n = as.integer(counts),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
