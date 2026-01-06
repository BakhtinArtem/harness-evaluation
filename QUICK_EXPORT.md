# Quick Export Guide for Thesis

## Step 1: Export Graphs (Automatic)

1. Open `analysis.ipynb` in Jupyter
2. **Run all cells** (Cell → Run All, or Kernel → Restart & Run All)
3. All graphs will be automatically saved to `thesis_exports/graphs/`

You'll see messages like:
```
Saved: thesis_exports/graphs/01_first_request_time_petclinic.png
Saved: thesis_exports/graphs/02_p50_latency_petclinic.png
...
```

## Step 2: Generate PDF

### If you have nbconvert installed:
```bash
python3 export_for_thesis.py
```

### If nbconvert is not installed:

**Install it first:**
```bash
# Activate your virtual environment if you have one
source venv/bin/activate  # or your venv path

# Install nbconvert
pip install nbconvert

# Then run the export script
python3 export_for_thesis.py
```

**Or install all PDF dependencies:**
```bash
# Ubuntu/Debian
sudo bash install_pdf_dependencies.sh

# Or manually:
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended texlive-latex-extra
```

**Or use HTML export (no LaTeX needed):**
```bash
python3 -m jupyter nbconvert --to html analysis.ipynb
```

## Output

After running, you'll have:
- `thesis_exports/graphs/` - All individual graph images (300 DPI PNG)
- `thesis_exports/pdf/analysis.pdf` - PDF version of notebook (if LaTeX installed)
- `thesis_exports/analysis.html` - HTML version (backup)

## Using in LaTeX

Include graphs in your thesis:
```latex
\includegraphics[width=0.8\textwidth]{thesis_exports/graphs/01_first_request_time_petclinic.png}
```

See `EXPORT_INSTRUCTIONS.md` for detailed instructions.

