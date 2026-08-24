#' Time-to-Event Widget (PROBE: candidate "named data-frame parameters")
#'
#' @param dfEvents `data.frame` ADAE-shaped event records, one row per event.
#' @param dfPopulation `data.frame` ADSL-shaped population extract, one row per
#'   participant, carrying the follow-up-end study day.
#' @param lSettings `list` safety.viz time-to-event settings overrides.
#' @param width,height,elementId,bDebug Standard htmlwidget arguments.
#' @export
Widget_TimeToEvent <- function(
    dfEvents,
    dfPopulation,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildMultiWidgetPayload(
    lData = list(events = dfEvents, population = dfPopulation),
    lSettings = lSettings,
    strModule = "time-to-event",
    bDebug = bDebug
  )
  htmlwidgets::createWidget(
    name = "Widget_TimeToEvent", x = x, width = width, height = height,
    package = "gsm.safety", elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
