#!/usr/bin/env bash
# vendor-widget-thumbnails.sh — refresh the widget gallery thumbnails (#28).
#
# The gallery on the pkgdown home page leads with one image per widget. Those
# images are the *canonical renderer captures* published by safety.viz itself:
# `site/assets/<module>-hero.png`, produced by that repo's
# scripts/capture-heroes.mjs, which loads each built demo page in headless
# Chromium and screenshots the rendered chart at 2x once it has settled.
#
# We vendor them byte-identical rather than re-capturing here, because:
#   * they show the same renderer on the same demo data this package ships, so
#     a second capture pipeline would only add a way for the two to disagree;
#   * it keeps node/Playwright out of an R package's toolchain;
#   * provenance stays exact — each file is traceable to a safety.viz release.
#
# Usage:
#   tools/vendor-widget-thumbnails.sh [path-to-safety.viz-checkout]
#
# Defaults to ../safety.viz, matching the sibling-repo workspace layout. Run it
# whenever the vendored bundle is bumped to a new safety.viz release, then
# commit the refreshed PNGs alongside the bundle.

set -euo pipefail

SRC_REPO="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/safety.viz}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/man/figures/widgets"

# module slug -> thumbnail name. One entry per Widget_* binding; keep in sync
# with the gallery table in README.md and the coverage test in
# tests/testthat/test-widget-gallery.R.
MODULES=(
  histogram
  shift-plot
  delta-delta
  results-over-time
  outlier-explorer
  ae-timelines
  ae-explorer
  hep-explorer
  qt-explorer
)

if [ ! -d "$SRC_REPO/site/assets" ]; then
  echo "error: no safety.viz assets at $SRC_REPO/site/assets" >&2
  echo "       pass the path to a safety.viz checkout as the first argument" >&2
  exit 1
fi

mkdir -p "$DEST"

version="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$SRC_REPO/package.json" | head -1)"
echo "Vendoring widget thumbnails from safety.viz ${version:-unknown} ($SRC_REPO)"

missing=0
for module in "${MODULES[@]}"; do
  src="$SRC_REPO/site/assets/${module}-hero.png"
  if [ ! -f "$src" ]; then
    echo "  MISSING  ${module}-hero.png" >&2
    missing=$((missing + 1))
    continue
  fi
  cp "$src" "$DEST/${module}.png"
  echo "  ok       ${module}.png"
done

if [ "$missing" -gt 0 ]; then
  echo "error: $missing thumbnail(s) missing from the safety.viz checkout" >&2
  exit 1
fi

echo "Vendored ${#MODULES[@]} thumbnails to man/figures/widgets/"
