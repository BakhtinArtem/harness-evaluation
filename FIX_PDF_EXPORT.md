# Fix PDF Export - Install Pandoc

The PDF export is failing because **Pandoc** is missing. Here's how to fix it:

## Quick Fix

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended texlive-latex-extra
```

### Or use the installation script:
```bash
sudo bash install_pdf_dependencies.sh
```

## After Installation

Once Pandoc is installed, run the export script again:
```bash
python3 export_for_thesis.py
```

## What's Already Working

✅ **HTML export** - Already working! You have `thesis_exports/analysis.html`
✅ **Graph export** - Graphs are automatically saved when you run the notebook

## Current Status

- ✅ HTML export: Working
- ✅ Graph export: Working (when notebook runs)
- ❌ PDF export: Needs Pandoc + LaTeX

## Alternative: Use HTML

If you don't want to install Pandoc/LaTeX, you can:
1. Use the HTML export (`thesis_exports/analysis.html`)
2. Print HTML to PDF from your browser (File → Print → Save as PDF)
3. Use the individual graph images from `thesis_exports/graphs/` in your thesis

## Verify Installation

After installing, verify:
```bash
pandoc --version
xelatex --version
```

Both commands should show version information.

