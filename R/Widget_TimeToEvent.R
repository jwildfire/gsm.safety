#' Time-to-Event Widget
#'
#' A widget that renders the safety.viz time-to-event display: Kaplan-Meier
#' curves for an endpoint the reviewer composes live. Multiselect filters over
#' the event records decide which events qualify — every treatment-emergent
#' event by default, or one click away a serious-only endpoint or a body-system
#' basket — and the module takes each participant's first qualifying event by
#' onset day, censors event-free participants at their follow-up-end day, and
#' draws the product-limit estimator with Greenwood log-log pointwise 95%
#' bounds, an at-risk table, and censor marks. Cumulative incidence (1 - KM,
#' rising) is the default orientation.
#'
#' Unlike the other widgets this one takes **two** data frames, because the
#' endpoint is composed rather than pre-derived: there is no ADTTE. `dfResults`
#' says who had an event and when; `dfPopulation` says who was at risk and for
#' how long, and is the analysis denominator. A participant with no qualifying
#' event is not missing from the chart — they are censored, which is why the
#' population frame cannot be inferred from the events.
#'
#' @param dfResults `data.frame` Event records, one row per event (an
#'   ADAE-shaped projection). Carries the participant id and onset-day columns
#'   named in `lSettings`, plus any descriptor columns the event filters use.
#'   Records with a missing, non-numeric or non-positive day, or a participant
#'   absent from `dfPopulation`, are excluded by the module with a counted,
#'   exportable reason rather than dropped silently.
#' @param dfPopulation `data.frame` Population records, one row per participant
#'   (an ADSL-shaped projection): the analysis denominator. Carries the
#'   participant id and follow-up-end day columns named in `lSettings`. The
#'   grouping column is optional — without it the module draws one pooled
#'   curve.
#' @param lSettings `list` safety.viz time-to-event settings overrides; merged
#'   onto the module's `DEFAULT_SETTINGS` client-side, so only overrides are
#'   needed. The defaults expect the ADaM standard (`USUBJID`/`ASTDY` in the
#'   events, `USUBJID`/`EOSDY`/`ARM`/`EOSSTT` in the population — see
#'   `inst/schema/time-to-event.json`), so data using those names needs no
#'   settings at all.
#' @param width `character` Width of the widget as a CSS unit. Default: `NULL`.
#' @param height `character` Height of the widget as a CSS unit. Default:
#'   `NULL`.
#' @param elementId `character` ID of the widget's HTML element. Default:
#'   `NULL`.
#' @param bDebug `logical` Print debug messages in the browser console?
#'   Default: `FALSE`.
#'
#' @examples
#' # The bundled adverse events carry one all-blank placeholder row per
#' # participant with no events, so the AE renderers' denominator covers the
#' # whole safety population. Those rows are not events, and this chart takes
#' # its denominator from the population frame instead, so drop them.
#' dfAE <- ExampleData("adae")
#' dfResults <- dfAE[nzchar(dfAE$AEDECOD), ]
#' dfPopulation <- ExampleData("adsl")
#'
#' # Both frames use the default column names, so the chart initializes with
#' # no settings: time to first treatment-emergent adverse event, by arm.
#' Widget_TimeToEvent(dfResults, dfPopulation)
#'
#' # Name the endpoint and the filters that compose it.
#' Widget_TimeToEvent(
#'   dfResults,
#'   dfPopulation,
#'   lSettings = list(
#'     endpoint_label = "Time to first treatment-emergent adverse event",
#'     event_filters = list(
#'       list(value_col = "AEBODSYS", label = "Body System"),
#'       list(value_col = "AEDECOD", label = "Preferred Term"),
#'       list(value_col = "AESER", label = "Serious"),
#'       list(value_col = "AESEV", label = "Severity")
#'     ),
#'     filters = list(
#'       list(value_col = "ARM", label = "Treatment Group")
#'     )
#'   )
#' )
#'
#' @export
Widget_TimeToEvent <- function(
    dfResults,
    dfPopulation,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    lData = list(events = dfResults, population = dfPopulation),
    lSettings = lSettings,
    strModule = "time-to-event",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_TimeToEvent",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
