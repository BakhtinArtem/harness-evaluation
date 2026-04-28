#!/usr/bin/env bash
# Render the figure-*.pdf files produced by evaluation.ipynb into the
# matching figure-*.png images embedded in evaluation-chapter.md.
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

render figure-01-per-operation-latency-distribution.pdf figure-01-per-operation-latency-distribution.png
render figure-02-latency-cdf-comparison.pdf             figure-02-latency-cdf-comparison.png
render figure-03-saturation-curves.pdf                  figure-03-saturation-curves.png
render figure-04-cold-start-penalty.pdf                 figure-04-cold-start-penalty.png
render figure-05-cold-vs-steady-latency.pdf             figure-05-cold-vs-steady-latency.png
render figure-06-first-response-time.pdf                figure-06-first-response-time.png
render figure-07-scenario-sensitivity.pdf               figure-07-scenario-sensitivity.png
render figure-08-operation-overlap.pdf                  figure-08-operation-overlap.png
render figure-09-framework-comparison.pdf               figure-09-framework-comparison.png
render figure-10-cpu-timeseries.pdf                     figure-10-cpu-timeseries.png
