#!/usr/bin/env bash
# Render the chart_*.pdf files produced by evaluation.ipynb into the
# figure-*.png images embedded in evaluation-chapter.md.
#
# Usage: ./render-figures.sh [DPI]
#   DPI defaults to 200 (good balance of size / readability).
#
# Requires: pdftoppm (Poppler) and optionally pngcrush for size reduction.

set -euo pipefail

DPI="${1:-200}"
cd "$(dirname "$0")"

render() {
    local pdf="$1"
    local png="$2"
    if [[ ! -f "$pdf" ]]; then
        echo "[skip] $pdf not found"
        return
    fi
    # pdftoppm writes "<prefix>-<page>.png" for multi-page PDFs; our charts
    # are single-page, so -singlefile drops the page suffix.
    pdftoppm -png -r "$DPI" -singlefile "$pdf" "${png%.png}"
    echo "[ok]   $pdf -> $png"
}

render chart_a1_violin.pdf              figure-1-per-operation-violin.png
render chart_a3_cdf.pdf                 figure-2-latency-cdf.png
render chart_a2_saturation.pdf          figure-3-saturation-curves.png
render chart_b1_cold_penalty.pdf        figure-4-cold-penalty.png
render chart_b1b_cold_steady_absolute.pdf figure-5-cold-vs-steady.png
render chart_b2_first_response.pdf      figure-6-first-response.png
render chart_c1_scenario_sensitivity.pdf figure-7-scenario-sensitivity.png
render chart_c2_operation_overlap.pdf   figure-8-operation-overlap.png
render chart_d3_framework_comparison.pdf figure-9-framework-comparison.png
render chart_d4_cpu_timeseries.pdf      figure-10-cpu-timeseries.png
