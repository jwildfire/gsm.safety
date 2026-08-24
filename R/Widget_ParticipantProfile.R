#' Participant Profile Widget (PROBE: candidate "named data-frame parameters")
#'
#' @param dfResults `data.frame` Long-format lab records.
#' @param dfEvents `data.frame` Optional ADAE-shaped event records for the AE
#'   tracks. Default: `NULL` (the v1 lab-only profile).
#' @param chrParticipants `character` Optional initial cohort. The standalone
#'   mount otherwise waits for a `participantsSelected` event that no R page
#'   dispatches.
#' @param lSettings `list` safety.viz participant-profile settings overrides.
#' @param width,height,elementId,bDebug Standard htmlwidget arguments.
#' @export
Widget_ParticipantProfile <- function(
    dfResults,
    dfEvents = NULL,
    chrParticipants = NULL,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "participant-profile",
    bDebug = bDebug
  )
  if (!is.null(dfEvents)) {
    gsm.core::stop_if(
      cnd = !is.data.frame(dfEvents),
      message = "dfEvents is not a data.frame"
    )
    x$dfEvents <- dfEvents
  }
  x$chrParticipants <- chrParticipants

  htmlwidgets::createWidget(
    name = "Widget_ParticipantProfile", x = x, width = width, height = height,
    package = "gsm.safety", elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
