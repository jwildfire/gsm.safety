#' Build the htmlwidget payload for a safety.viz module
#'
#' Validates the supplied data and `lSettings` against the module's vendored
#' JSON data contract (`inst/schema/<strModule>.json`): every required settings
#' key must resolve (from `lSettings` or the schema default), and every
#' column-mapping setting (`*_col`) referenced by a required key must name a
#' column of the data.
#'
#' Most contracts name a single dataset (`data`), which arrives as `dfResults`.
#' Some name more than one — `time-to-event` composes its endpoint from
#' `events` plus `population` — and those arrive as `lData`, a named list keyed
#' by the contract's own dataset names. The dataset names are read off the
#' schema rather than assumed, so a module that grows a third frame upstream
#' needs no change here. Where a dataset declares its own `requiredSettings`,
#' those column mappings are checked against *that* frame: naming the
#' population's follow-up column in the events data is an error, not a silent
#' empty chart.
#'
#' @param dfResults `data.frame` Long-format results data, one record per row.
#'   The whole input for a single-dataset contract; unused when `lData` is
#'   supplied.
#' @param lSettings `list` safety.viz settings overrides; merged onto the
#'   module's `DEFAULT_SETTINGS` client-side, so only overrides are needed.
#' @param strModule `character` Module slug matching a schema file, e.g.
#'   `"histogram"` or `"shift-plot"`.
#' @param bDebug `logical` Print debug messages in the browser console?
#'   Default: `FALSE`.
#' @param lData `list` Named list of `data.frame`s for a multi-dataset
#'   contract, keyed by the contract's dataset names (e.g. `events` and
#'   `population`). Default: `NULL`, meaning `dfResults` is the single dataset.
#'
#' @return `list` — the `x` payload for [htmlwidgets::createWidget()]. Carries
#'   `dfResults`, `lSettings` and `bDebug` for a single-dataset contract, and
#'   `lData`, `lSettings` and `bDebug` for a multi-dataset one.
#'
#' @keywords internal
BuildWidgetPayload <- function(
    dfResults,
    lSettings = list(),
    strModule,
    bDebug = FALSE,
    lData = NULL) {
  gsm.core::stop_if(
    cnd = !is.list(lSettings) || is.data.frame(lSettings),
    message = "lSettings must be a list, but not a data.frame"
  )
  gsm.core::stop_if(
    cnd = !(is.character(strModule) && length(strModule) == 1),
    message = "strModule is not a length-1 character"
  )
  gsm.core::stop_if(
    cnd = !is.logical(bDebug),
    message = "bDebug is not a logical"
  )

  strSchemaPath <- system.file(
    "schema",
    paste0(strModule, ".json"),
    package = "gsm.safety"
  )
  gsm.core::stop_if(
    cnd = !nzchar(strSchemaPath),
    message = paste0("No data contract found for module '", strModule, "'")
  )

  lSchema <- jsonlite::fromJSON(strSchemaPath, simplifyVector = FALSE)

  # The contract names its own datasets; `settings` is the only required root
  # member that is not one.
  chrDatasets <- setdiff(unlist(lSchema$required), "settings")

  if (is.null(lData)) {
    gsm.core::stop_if(
      cnd = length(chrDatasets) != 1,
      message = paste0(
        "The '", strModule, "' contract names ", length(chrDatasets),
        " datasets (", paste(chrDatasets, collapse = ", "),
        "); pass them as lData, not dfResults"
      )
    )
    gsm.core::stop_if(
      cnd = !is.data.frame(dfResults),
      message = "dfResults is not a data.frame"
    )
    lData <- stats::setNames(list(dfResults), chrDatasets)
  }

  gsm.core::stop_if(
    cnd = !is.list(lData) || is.data.frame(lData),
    message = "lData must be a named list of data.frames"
  )
  for (strDataset in chrDatasets) {
    gsm.core::stop_if(
      cnd = !is.data.frame(lData[[strDataset]]),
      message = paste0(
        "lData$", strDataset, " is missing or not a data.frame — the '",
        strModule, "' contract requires it"
      )
    )
  }

  lSettingsSchema <- lSchema$properties$settings

  # Settings-level `required` keys are contract-wide: check them against every
  # column the module will see.
  dfColumns <- data.frame()
  for (strDataset in chrDatasets) {
    for (strColumn in names(lData[[strDataset]])) {
      dfColumns[[strColumn]] <- logical(0)
    }
  }
  CheckRequiredSettings(
    lProperties = lSettingsSchema$properties,
    chrRequired = unlist(lSettingsSchema$required),
    lSettings = lSettings,
    dfResults = dfColumns,
    strModule = strModule
  )

  # Per-dataset `requiredSettings` are checked against that dataset alone.
  for (strDataset in chrDatasets) {
    CheckRequiredSettings(
      lProperties = lSettingsSchema$properties,
      chrRequired = unlist(lSchema$properties[[strDataset]]$requiredSettings),
      lSettings = lSettings,
      dfResults = lData[[strDataset]],
      strModule = strModule,
      strData = paste0("lData$", strDataset)
    )
  }

  if (length(lSettings) == 0) {
    lSettings <- stats::setNames(list(), character(0))
  }

  if (length(chrDatasets) == 1) {
    return(list(
      dfResults = lData[[chrDatasets]],
      lSettings = lSettings,
      bDebug = bDebug
    ))
  }

  list(
    lData = lData[chrDatasets],
    lSettings = lSettings,
    bDebug = bDebug
  )
}

#' Check required schema settings against data
#'
#' Walks the required settings keys of a module schema. Object-typed settings
#' (e.g. the ae-timelines `color` mapping) recurse into their own required
#' members; `*_col` keys must resolve to a column of `dfResults`.
#'
#' @param lProperties `list` The schema `properties` for this settings level.
#' @param chrRequired `character` Required keys at this settings level.
#' @param lSettings `list` User-supplied settings at this level.
#' @param dfResults `data.frame` Results data to check column mappings against.
#' @param strModule `character` Module slug, used in error messages.
#' @param strPrefix `character` Setting-name prefix for nested levels.
#' @param strData `character` Name of the frame being checked, used in error
#'   messages so a multi-dataset contract says which frame the column is
#'   missing from.
#'
#' @return `NULL`, invisibly. Called for its errors.
#'
#' @noRd
CheckRequiredSettings <- function(
    lProperties,
    chrRequired,
    lSettings,
    dfResults,
    strModule,
    strPrefix = "",
    strData = "dfResults") {
  for (strKey in chrRequired) {
    lProperty <- lProperties[[strKey]]
    if (is.null(lProperty)) {
      lProperty <- list()
    }
    strSetting <- paste0(strPrefix, strKey)

    if (identical(lProperty$type, "object")) {
      lNested <- lSettings[[strKey]]
      if (is.null(lNested)) {
        lNested <- list()
      }
      CheckRequiredSettings(
        lProperties = lProperty$properties,
        chrRequired = unlist(lProperty$required),
        lSettings = lNested,
        dfResults = dfResults,
        strModule = strModule,
        strPrefix = paste0(strSetting, "$"),
        strData = strData
      )
      next
    }

    vValue <- lSettings[[strKey]]
    if (is.null(vValue)) {
      vValue <- lProperty$default
    }
    gsm.core::stop_if(
      cnd = is.null(vValue),
      message = paste0(
        "Required setting '", strSetting,
        "' has no value and no default in the '", strModule, "' schema"
      )
    )

    if (
      grepl("_col$", strKey) &&
        is.character(vValue) &&
        length(vValue) == 1
    ) {
      gsm.core::stop_if(
        cnd = !(vValue %in% names(dfResults)),
        message = paste0(
          "Column '", vValue, "' (setting '", strSetting,
          "') not found in ", strData
        )
      )
    }
  }

  invisible(NULL)
}

#' Save a safety widget as a standalone HTML report
#'
#' Wraps [htmlwidgets::saveWidget()] to write a self-contained HTML report,
#' creating the output directory when needed and appending `.html` to the file
#' name when absent.
#'
#' @param widget `htmlwidget` The widget to save, e.g. from [Widget_Histogram()].
#' @param strOutputDir `character` Directory where the report is written.
#'   Default: `getwd()`.
#' @param strOutputFile `character` Output file stem or filename.
#'
#' @return The normalized path to the saved report, invisibly.
#'
#' @examples
#' dfResults <- ExampleData("adbds")
#' strReportPath <- SaveWidgetReport(
#'   Widget_Histogram(dfResults[dfResults$TEST == "Albumin", ]),
#'   strOutputDir = tempdir(),
#'   strOutputFile = "histogram"
#' )
#'
#' @export
SaveWidgetReport <- function(
    widget,
    strOutputDir = getwd(),
    strOutputFile) {
  gsm.core::stop_if(
    cnd = !inherits(widget, "htmlwidget"),
    message = "widget is not an htmlwidget"
  )
  gsm.core::stop_if(
    cnd = !(is.character(strOutputDir) && length(strOutputDir) == 1),
    message = "strOutputDir is not a length-1 character"
  )
  gsm.core::stop_if(
    cnd = !(is.character(strOutputFile) && length(strOutputFile) == 1),
    message = "strOutputFile is not a length-1 character"
  )

  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(
    normalizePath(strOutputDir, winslash = "/"),
    strOutputFile
  )

  htmlwidgets::saveWidget(widget, file = strOutputPath, selfcontained = TRUE)

  invisible(normalizePath(strOutputPath, winslash = "/"))
}

#' Default sizing policy for gsm.safety widgets
#'
#' The safety.viz shell lays out as a normal document (sticky sidebar plus
#' full-width charts), so the widgets default to the full container width
#' rather than htmlwidgets' fixed 960px.
#'
#' @return An [htmlwidgets::sizingPolicy()].
#'
#' @keywords internal
WidgetSizingPolicy <- function() {
  htmlwidgets::sizingPolicy(
    defaultWidth = "100%",
    browser.defaultWidth = "100%",
    viewer.defaultWidth = "100%",
    knitr.defaultWidth = "100%"
  )
}
