#!/usr/bin/env bash
# check-safety-viz-parity.sh — the cross-repo half of the safety.viz parity
# guard (#49; hub requirement jwildfire/obot.roadmap#164).
#
# Every safety.viz renderer gets an R widget (@jwildfire, 2026-08-15). This
# script asserts, against the LATEST safety.viz RELEASE:
#
#   1. the vendored bundle (DESCRIPTION Config/safetyviz/version) is that
#      release — a stale bundle silently reproduces defects the library has
#      since fixed;
#   2. every renderer exported by that release's src/main.js has a matching
#      Widget_*.R, unless it is deferred in .github/parity-allowlist.yaml —
#      and every allowlist entry must cite a filed requirement URL, so
#      "widget follows later" is a tracked commitment, never an intention.
#
# The offline half (declared version == vendored lib == every widget yaml)
# lives in tests/testthat/test-safety-viz-parity.R.
#
# Usage: tools/check-safety-viz-parity.sh
# Needs: curl, and `gh` or GITHUB_TOKEN-less anonymous API access (public repo).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SV_REPO="jwildfire/safety.viz"
ALLOWLIST="$REPO_ROOT/.github/parity-allowlist.yaml"

fail=0

# --- 1. latest safety.viz release vs declared version ---
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  latest_tag="$(gh api "repos/$SV_REPO/releases/latest" -q .tag_name)"
else
  latest_tag="$(curl -fsSL "https://api.github.com/repos/$SV_REPO/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
fi
latest="${latest_tag#v}"
declared="$(sed -n 's/^Config\/safetyviz\/version: *//p' "$REPO_ROOT/DESCRIPTION")"

echo "safety.viz latest release: $latest_tag"
echo "gsm.safety wraps:          ${declared:-<undeclared>}"

if [ -z "$declared" ]; then
  echo "FAIL: DESCRIPTION carries no Config/safetyviz/version field" >&2
  fail=1
elif [ "$declared" != "$latest" ]; then
  echo "FAIL: vendored bundle ($declared) is behind the latest safety.viz release ($latest)." >&2
  echo "      Re-vendor dist/safety.viz-$latest from the release, update the widget yamls," >&2
  echo "      Config/safetyviz/version, and tools/vendor-widget-thumbnails.sh." >&2
  fail=1
fi

# --- 2. every released renderer has a widget (or a cited deferral) ---
mainjs="$(curl -fsSL "https://raw.githubusercontent.com/$SV_REPO/$latest_tag/src/main.js")"
modules="$(printf '%s\n' "$mainjs" | sed -n '/^export {$/,/^};$/p' | sed -e '1d;$d' -e 's/[ ,]//g' | grep -v '^$')"

if [ -z "$modules" ]; then
  echo "FAIL: could not parse renderer exports from src/main.js at $latest_tag" >&2
  exit 1
fi

deferred=""
if [ -f "$ALLOWLIST" ]; then
  # entries: "- module: <name>" followed by "  requirement: <url>"
  deferred="$(sed -n 's/^- module: *//p' "$ALLOWLIST")"
  while IFS= read -r module; do
    [ -z "$module" ] && continue
    req="$(awk -v m="$module" '$0 ~ "^- module: *"m"$" {found=1; next} found && /^  requirement:/ {sub(/^  requirement: */,""); print; exit} found && /^- / {exit}' "$ALLOWLIST")"
    if ! printf '%s' "$req" | grep -qE '^https://github.com/.+/issues/[0-9]+'; then
      echo "FAIL: allowlist entry '$module' cites no filed requirement URL — file the requirement first." >&2
      fail=1
    fi
  done <<< "$deferred"
fi

missing=""
for module in $modules; do
  widget="Widget_$(printf '%s' "$module" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
  if [ -f "$REPO_ROOT/R/$widget.R" ]; then
    echo "  ok        $module -> $widget"
  elif printf '%s\n' "$deferred" | grep -qx "$module"; then
    echo "  deferred  $module (cited in parity-allowlist.yaml)"
  else
    echo "  MISSING   $module -> $widget" >&2
    missing="$missing $module"
    fail=1
  fi
done

if [ -n "$missing" ]; then
  echo "FAIL: unwrapped renderer(s):$missing" >&2
  echo "      Wrap each one, or defer it in .github/parity-allowlist.yaml with its filed requirement URL." >&2
fi

exit $fail
