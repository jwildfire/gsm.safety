# Package index

## Safety widgets

Interactive safety.viz charts as htmlwidgets.

- [`Widget_Histogram()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_Histogram.md)
  : Histogram Widget
- [`Widget_ShiftPlot()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ShiftPlot.md)
  : Shift Plot Widget
- [`Widget_DeltaDelta()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_DeltaDelta.md)
  : Delta-Delta Widget
- [`Widget_ResultsOverTime()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ResultsOverTime.md)
  : Results Over Time Widget
- [`Widget_OutlierExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_OutlierExplorer.md)
  : Outlier Explorer Widget
- [`Widget_AeTimelines()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_AeTimelines.md)
  : AE Timelines Widget
- [`Widget_AeExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_AeExplorer.md)
  : Adverse Event Explorer Widget
- [`Widget_HepExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_HepExplorer.md)
  : Hepatic Safety Explorer (eDISH) Widget
- [`Widget_QtExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_QtExplorer.md)
  : QT Safety Explorer Widget
- [`Widget_HepWaterfall()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_HepWaterfall.md)
  : Hepatic ALT Waterfall Widget
- [`Widget_NepExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_NepExplorer.md)
  : Nephrotoxicity Explorer Widget
- [`Widget_TimeToEvent()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_TimeToEvent.md)
  : Time-to-Event Widget
- [`Widget_ParticipantProfile()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ParticipantProfile.md)
  : Participant Profile Widget

## Data

- [`ExampleData()`](https://jwildfire.github.io/gsm.safety/dev/reference/ExampleData.md)
  : Example safety data

## Metric steps

The steps behind the metric definitions in inst/workflow/2_metrics/.
Input_HysLaw, Input_QtProlongation and Input_SafetyAE feed the three
participant-level flagging metrics; Input_Deaths, Input_Participants and
Input_ParticipantDays feed the descriptive census metrics, which publish
a number, carry no threshold, and call Flag_None where a flagging metric
calls gsm.core::Flag().

- [`Input_HysLaw()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_HysLaw.md)
  : Participant-level Hy's Law candidate tier from liver chemistry
- [`Input_QtProlongation()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_QtProlongation.md)
  : Participant-level QTc prolongation tier from ECG data
- [`Input_SafetyAE()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_SafetyAE.md)
  : Participant-level serious / related / discontinuation AE tier
- [`Input_Deaths()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_Deaths.md)
  : Study-level count of participants who died
- [`Input_Participants()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_Participants.md)
  : Study-level count of the participants a domain names
- [`Input_ParticipantDays()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_ParticipantDays.md)
  : Study-level total of participant-days
- [`Flag_None()`](https://jwildfire.github.io/gsm.safety/dev/reference/Flag_None.md)
  : Publish a metric's rows without a flag

## Study census

The safety overview’s denominators. Being rebuilt on the metric steps
above (obot.roadmap#274); this function is unchanged until step four.

- [`SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/SafetyCensus.md)
  : Study census, exposure and follow-up for a safety overview

## Reports

The steps behind the report definitions in inst/workflow/4_modules/.
SaveWidgetReport writes a widget module; the Report_Census\* helpers and
Report_SafetyCensus assemble and render the safety census, reading the
figures the census metrics published and computing nothing of their own
(obot.roadmap#274).

- [`SaveWidgetReport()`](https://jwildfire.github.io/gsm.safety/dev/reference/SaveWidgetReport.md)
  : Save a safety widget as a standalone HTML report
- [`Report_CensusFigures()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusFigures.md)
  : The census figures, as the report presents them
- [`Report_CensusCoverage()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusCoverage.md)
  : The data-coverage rows, as the report presents them
- [`Report_CensusProvenance()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusProvenance.md)
  : What each census metric published, verbatim
- [`Report_SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_SafetyCensus.md)
  : Render the census report
