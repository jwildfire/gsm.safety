# Shared internals of the census report

The census report reads. Every helper in this file resolves a metric ID
to the row that metric published and hands it on unchanged; none of them
counts anything, and none of them takes a study domain as an argument,
so none of them could. That is the property step three of the
SafetyCensus rebuild exists to preserve — a number is validated once, in
its metric, and read everywhere else.
