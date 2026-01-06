# Exporting Notebook for Thesis - Instructions

## Quick Start

1. **Run the notebook** - Execute all cells. Graphs will be automatically saved to `thesis_exports/graphs/`

2. **Generate PDF** - Run:
   ```bash
   python3 export_for_thesis.py
   ```

## Detailed Steps

### Step 1: Export Graphs (Automatic)

The notebook has been configured to automatically save all graphs when you run it. 

1. Open `analysis.ipynb` in Jupyter
2. Run all cells (Cell → Run All)
3. All graphs will be saved to `thesis_exports/graphs/` with numbered filenames:
   - `01_first_request_time_petclinic.png`
   - `02_p50_latency_petclinic.png`
   - `03_p75_latency_petclinic.png`
   - etc.

**Note:** Make sure the first cell (export configuration) runs successfully before running other cells.

### Step 2: Generate PDF

#### Option A: Using the script (recommended)
```bash
python3 export_for_thesis.py
```

#### Option B: Manual command
```bash
# PDF (requires LaTeX)
python3 -m jupyter nbconvert --to pdf --output-dir thesis_exports/pdf analysis.ipynb

# HTML (no dependencies, easier)
python3 -m jupyter nbconvert --to html --output-dir thesis_exports analysis.ipynb
```

### Step 3: Install Dependencies (if needed)

If PDF generation fails, install LaTeX:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install texlive-xetex texlive-fonts-recommended texlive-latex-extra
```

**macOS:**
```bash
brew install --cask mactex
```

**Alternative:** Use HTML export which doesn't require LaTeX:
```bash
python3 -m jupyter nbconvert --to html analysis.ipynb
```

## Output Structure

After running the export, you'll have:

```
thesis_exports/
├── graphs/              # All individual graph images (PNG, 300 DPI)
│   ├── 01_first_request_time_petclinic.png
│   ├── 02_p50_latency_petclinic.png
│   ├── 03_p75_latency_petclinic.png
│   ├── 04_p90_latency_petclinic.png
│   ├── 05_p99_latency_petclinic.png
│   ├── 06_throughput_petclinic.png
│   ├── 07_avg_rss_petclinic.png
│   ├── 08_avg_cpu_petclinic.png
│   ├── 09_max_rss_petclinic.png
│   └── ... (similar for shopcart and media)
├── pdf/                 # PDF version of notebook
│   └── analysis.pdf
└── analysis.html        # HTML version (backup)
```

## Graph Specifications

All graphs are exported with:
- **Format:** PNG
- **Resolution:** 300 DPI (publication quality)
- **Size:** Optimized with tight bounding box
- **Font sizes:** 
  - Title: 12pt
  - Axis labels: 11pt
  - Tick labels: 9pt
  - Legend: 9pt

## Using Graphs in LaTeX

To include graphs in your LaTeX thesis:

```latex
\begin{figure}[h]
    \centering
    \includegraphics[width=0.8\textwidth]{thesis_exports/graphs/01_first_request_time_petclinic.png}
    \caption{First Request Time Comparison - Petclinic}
    \label{fig:first_request_petclinic}
\end{figure}
```

For full-width figures:
```latex
\begin{figure*}[t]
    \centering
    \includegraphics[width=\textwidth]{thesis_exports/graphs/02_p50_latency_petclinic.png}
    \caption{P50 Latency Comparison - Petclinic}
    \label{fig:p50_latency_petclinic}
\end{figure*}
```

## Troubleshooting

### Graphs not saving
- Make sure you run the first cell (export configuration) before other cells
- Check that `thesis_exports/graphs/` directory exists and is writable
- Verify matplotlib is working: `import matplotlib.pyplot as plt; plt.plot([1,2,3]); plt.show()`

### PDF generation fails
- Install LaTeX dependencies (see Step 3 above)
- Use HTML export instead (no dependencies needed)
- Check notebook for errors: all cells should execute successfully
- Try: `python3 -m jupyter nbconvert --to pdf analysis.ipynb` directly

### Low quality graphs
- Graphs are exported at 300 DPI by default
- To change resolution, modify `plt.rcParams['savefig.dpi']` in the first cell
- For vector graphics, change format to 'pdf' or 'svg' in `save_figure()` calls

### Missing graphs
- Run all notebook cells in order
- Check the console output for "Saved: ..." messages
- Verify the graph counter is incrementing

## Tips for Thesis

1. **Organize graphs by section**: Create subdirectories in `graphs/` for different thesis chapters
2. **Rename graphs**: Use descriptive names like `latency_comparison_petclinic.png`
3. **Create figure list**: Maintain a list of all figures with captions for easy reference
4. **Check resolution**: All graphs are 300 DPI, suitable for print quality
5. **Consistent styling**: All graphs use the same style settings for consistency

