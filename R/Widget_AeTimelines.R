#' AE Timelines Widget
#'
#' A widget that renders the safety.viz adverse-event timelines: one row per
#' participant, each event drawn from onset to resolution study day, colored by
#' severity (or another stratifier), with optional serious-event highlighting,
#' filters, and a participant detail listing.
#'
#' @param dfResults `data.frame` Adverse-event data, one record per event.
#'   Column names are supplied by `lSettings`; the defaults expect
#'   `USUBJID`/`AESEQ`/`ASTDY`/`AENDY`/`AETERM`/`AESEV` (see
#'   `inst/schema/ae-timelines.json`).
#' @param lSettings `list` safety.viz ae-timelines settings overrides; merged
#'   onto the module's `DEFAULT_SETTINGS` client-side, so only overrides are
#'   needed.
#' @param width `character` Width of the widget as a CSS unit. Default: `NULL`.
#' @param height `character` Height of the widget as a CSS unit. Default:
#'   `NULL`.
#' @param elementId `character` ID of the widget's HTML element. Default:
#'   `NULL`.
#' @param bDebug `logical` Print debug messages in the browser console?
#'   Default: `FALSE`.
#'
#' @examples
#' dfResults <- ExampleData("adae")
#'
#' Widget_AeTimelines(
#'   dfResults,
#'   lSettings = list(
#'     color = list(
#'       value_col = "AESEV",
#'       label = "Severity"
#'     ),
#'     highlight = list(
#'       value_col = "AESER",
#'       label = "Serious Event",
#'       value = "Y"
#'     ),
#'     filters = list(
#'       list(value_col = "AESER", label = "Serious Event"),
#'       list(value_col = "AESEV", label = "Severity"),
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "USUBJID", label = "Participant ID")
#'     ),
#'     details = list(
#'       list(value_col = "AEBODSYS", label = "Body System"),
#'       list(value_col = "AEDECOD", label = "Dictionary-Derived Term")
#'     ),
#'     sort_participants = "earliest"
#'   )
#' )
#'
#' @export
Widget_AeTimelines <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "ae-timelines",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_AeTimelines",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
