# Exporting Notebook for Thesis

This guide explains how to export the analysis notebook and all graphs for use in a diploma thesis.

## Quick Start

1. **Run the notebook** to generate all graphs (they will be automatically saved)
2. **Generate PDF** by running:
   ```bash
   python3 export_for_thesis.py
   ```

## Manual Steps

### 1. Export Graphs

The notebook has been configured to automatically save all graphs when you run it. Graphs are saved to:
```
thesis_exports/graphs/
```

Each graph is saved with a numbered prefix and descriptive name:
- `01_first_request_time_petclinic.png`
- `02_p50_latency_petclinic.png`
- `03_p75_latency_petclinic.png`
- etc.

### 2. Generate PDF

#### Option A: Using the script (recommended)
```bash
python3 export_for_thesis.py
```

#### Option B: Using jupyter-nbconvert directly
```bash
# PDF (requires LaTeX)
jupyter nbconvert --to pdf --output-dir thesis_exports/pdf analysis.ipynb

# HTML (no dependencies)
jupyter nbconvert --to html --output-dir thesis_exports analysis.ipynb
```

### 3. Install Dependencies for PDF

If PDF generation fails, install LaTeX:

**Ubuntu/Debian:**
```bash
sudo apt-get install texlive-xetex texlive-fonts-recommended texlive-latex-extra
```

**macOS:**
```bash
brew install --cask mactex
```

**Alternative:** Use HTML export which doesn't require LaTeX:
```bash
jupyter nbconvert --to html analysis.ipynb
```

## Output Structure

After running the export, you'll have:

```
thesis_exports/
├── graphs/              # All individual graph images (PNG, 300 DPI)
│   ├── 01_first_request_time_petclinic.png
│   ├── 02_p50_latency_petclinic.png
│   ├── 03_p75_latency_petclinic.png
│   └── ...
├── pdf/                 # PDF version of notebook
│   └── analysis.pdf
└── analysis.html        # HTML version (backup)
```

## Graph Formats

All graphs are exported as:
- **Format:** PNG
- **Resolution:** 300 DPI (publication quality)
- **Size:** Optimized with tight bounding box
- **Font sizes:** Adjusted for readability in thesis

## Using in LaTeX

To include graphs in your LaTeX thesis:

```latex
\begin{figure}[h]
    \centering
    \includegraphics[width=0.8\textwidth]{thesis_exports/graphs/01_first_request_time_petclinic.png}
    \caption{First Request Time Comparison - Petclinic}
    \label{fig:first_request_petclinic}
\end{figure}
```

## Troubleshooting

### PDF generation fails
- Install LaTeX dependencies (see above)
- Use HTML export instead: `jupyter nbconvert --to html analysis.ipynb`
- Check that all notebook cells executed successfully

### Graphs not saving
- Make sure you run the first cell (export configuration)
- Check that `thesis_exports/graphs/` directory exists
- Verify matplotlib backend is working

### Low quality graphs
- Graphs are exported at 300 DPI by default
- To change, modify `plt.rcParams['savefig.dpi']` in the first cell

