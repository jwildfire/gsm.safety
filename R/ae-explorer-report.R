#' Prepare AE Explorer data for safetyCharts
#'
#' @param lData A named list containing mapped GSM safety data frames.
#' @param lMeta Workflow metadata containing `domains` mappings.
#'
#' @return A named list with `dm` and `aes` data frames for safetyCharts.
#' @export
MakeAeExplorerData <- function(lData, lMeta = list()) {
  domains <- lMeta$domains %||% list(dm = "Mapped_SUBJ", aes = "Mapped_AE")
  missing_domains <- setdiff(unlist(domains, use.names = FALSE), names(lData))
  if (length(missing_domains) > 0) {
    stop(
      "AE Explorer missing required domain(s): ",
      paste(missing_domains, collapse = ", "),
      call. = FALSE
    )
  }

  list(
    dm = lData[[domains$dm]],
    aes = lData[[domains$aes]]
  )
}

#' Save an initialized AE Explorer widget as standalone HTML
#'
#' @param lInitialized A list returned by [safetyCharts::init_aeExplorer()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when absent.
#'
#' @return A list with the report path and htmlwidget.
#' @export
RenderAeExplorerWidget <- function(lInitialized,
                                   strOutputDir = getwd(),
                                   strOutputFile = "ae_explorer") {
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(strOutputDir, strOutputFile)

  widget <- safetyCharts::render_widget(
    "aeExplorer",
    lInitialized$data,
    lInitialized$settings
  )
  htmlwidgets::saveWidget(widget, file = strOutputPath, selfcontained = TRUE)

  list(
    path = normalizePath(strOutputPath, winslash = "/", mustWork = FALSE),
    widget = widget,
    initialized = lInitialized
  )
}

#' Create AE Explorer report settings from a workr spec
#'
#' @param lSpec A `workr` workflow spec for the AE Explorer report.
#'
#' @return A list of domain mappings, widget settings, and known gaps for AE Explorer.
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
        treatment_col = "sex"
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
      aeout = "No current Mapped_AE outcome field identified."
    )
  )
}

#' Render an interactive AE Explorer report
#'
#' This report artifact validates mapped AE inputs, initializes AE Explorer
#' settings with [safetyCharts::init_aeExplorer()], renders the interactive
#' widget with [safetyCharts::render_widget()], and writes a standalone HTML
#' file that can be attached to a workflow run or shown in pkgdown examples.
#'
#' @param lData A named list containing `Mapped_SUBJ` and `Mapped_AE` data frames.
#' @param lSettings AE Explorer settings from [MakeAeExplorerSettings()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when
#'   absent.
#'
#' @return A list with the report path, htmlwidget, and summary tables.
#' @export
Report_AE_Explorer <- function(lData,
                               lSettings,
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

  initialized <- safetyCharts::init_aeExplorer(
    data = list(
      dm = df_dm,
      aes = df_ae
    ),
    settings = lSettings$settings
  )
  report <- RenderAeExplorerWidget(
    lInitialized = initialized,
    strOutputDir = strOutputDir,
    strOutputFile = strOutputFile
  )

  c(
    report,
    list(
      summaries = list(
        terms = term_summary,
        body_systems = body_system_summary
      )
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
      sex = c("F", "M", "F", "M", "F", "M"),
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
