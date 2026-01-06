#!/usr/bin/env python3
"""
Export graphs and generate PDF for thesis.
Run this script to:
1. Export all graphs from the notebook to separate image files
2. Generate a PDF version of the notebook

Note: Graphs are automatically saved when you run the notebook.
This script only generates the PDF/HTML export.
"""

import subprocess
import sys
from pathlib import Path
import os

BASE_DIR = Path(__file__).parent
EXPORT_DIR = BASE_DIR / 'thesis_exports'
GRAPHS_DIR = EXPORT_DIR / 'graphs'
PDF_DIR = EXPORT_DIR / 'pdf'

# Create directories
EXPORT_DIR.mkdir(exist_ok=True)
GRAPHS_DIR.mkdir(exist_ok=True)
PDF_DIR.mkdir(exist_ok=True)

# Try to use venv's python if available
python_cmd = sys.executable
venv_python = BASE_DIR / 'venv' / 'bin' / 'python3'
if venv_python.exists():
    python_cmd = str(venv_python)
    print(f"Using virtual environment: {python_cmd}")

print("=" * 80)
print("EXPORTING NOTEBOOK FOR THESIS")
print("=" * 80)

# Step 1: Generate PDF from notebook
print("\n1. Generating PDF from notebook...")
try:
    result = subprocess.run([
        python_cmd, '-m', 'jupyter', 'nbconvert',
        '--to', 'pdf',
        '--output-dir', str(PDF_DIR),
        'analysis.ipynb'
    ], check=True, capture_output=True, text=True, timeout=300, cwd=str(BASE_DIR))
    print(f"✓ PDF generated: {PDF_DIR / 'analysis.pdf'}")
except subprocess.TimeoutExpired:
    print("✗ PDF generation timed out (this can take several minutes)")
except subprocess.CalledProcessError as e:
    print(f"✗ Error generating PDF")
    if e.stderr:
        stderr_lower = e.stderr.lower()
        if 'pandoc' in stderr_lower or 'pandocmissing' in stderr_lower:
            print("\n  ❌ Missing dependency: Pandoc")
            print("  Install Pandoc:")
            print("    Ubuntu/Debian: sudo apt-get install pandoc")
            print("    macOS: brew install pandoc")
            print("    Or download from: https://pandoc.org/installing.html")
            print("\n  Or run the installation script:")
            print("    sudo bash install_pdf_dependencies.sh")
        elif 'xelatex' in stderr_lower or 'latex' in stderr_lower:
            print("\n  ❌ Missing dependency: LaTeX")
            print("  Install LaTeX:")
            print("    Ubuntu/Debian: sudo apt-get install texlive-xetex texlive-fonts-recommended texlive-latex-extra")
            print("    macOS: brew install --cask mactex")
            print("\n  Or run the installation script:")
            print("    sudo bash install_pdf_dependencies.sh")
        else:
            print(f"  Error details: {e.stderr[:800]}")
    print("\n  💡 Alternative: Use HTML export (no dependencies needed)")
except FileNotFoundError:
    print("✗ jupyter-nbconvert not found")
    print("  Install with: pip install nbconvert")
    print(f"  Or activate venv and install: source venv/bin/activate && pip install nbconvert")
except Exception as e:
    print(f"✗ Unexpected error: {e}")

# Step 2: Export as HTML (backup option)
print("\n2. Generating HTML export (backup)...")
try:
    result = subprocess.run([
        python_cmd, '-m', 'jupyter', 'nbconvert',
        '--to', 'html',
        '--output-dir', str(EXPORT_DIR),
        'analysis.ipynb'
    ], check=True, capture_output=True, text=True, timeout=120, cwd=str(BASE_DIR))
    print(f"✓ HTML generated: {EXPORT_DIR / 'analysis.html'}")
except subprocess.TimeoutExpired:
    print("✗ HTML generation timed out")
except Exception as e:
    print(f"✗ Error generating HTML: {e}")
    print(f"  Try manually: {python_cmd} -m jupyter nbconvert --to html analysis.ipynb")

print("\n" + "=" * 80)
print("EXPORT COMPLETE")
print("=" * 80)
print(f"\nExports saved to: {EXPORT_DIR}")
print(f"  - PDF: {PDF_DIR}")
print(f"  - HTML: {EXPORT_DIR}")
print(f"  - Graphs: {GRAPHS_DIR} (run notebook cell to export graphs)")

