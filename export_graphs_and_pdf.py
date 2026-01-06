#!/usr/bin/env python3
"""
Script to export all graphs from the analysis notebook and generate a PDF.
This script should be run from within the Jupyter notebook or as a standalone script.
"""

import os
import sys
from pathlib import Path
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import json
import re

# Set up paths
BASE_DIR = Path(__file__).parent
EXPORT_DIR = BASE_DIR / 'thesis_exports'
GRAPHS_DIR = EXPORT_DIR / 'graphs'
GRAPHS_DIR.mkdir(parents=True, exist_ok=True)

# Set high DPI for publication-quality figures
plt.rcParams['figure.dpi'] = 300
plt.rcParams['savefig.dpi'] = 300
plt.rcParams['savefig.bbox'] = 'tight'
plt.rcParams['savefig.pad_inches'] = 0.1
plt.rcParams['font.size'] = 10
plt.rcParams['axes.labelsize'] = 11
plt.rcParams['axes.titlesize'] = 12
plt.rcParams['xtick.labelsize'] = 9
plt.rcParams['ytick.labelsize'] = 9
plt.rcParams['legend.fontsize'] = 9

print(f"Export directory: {EXPORT_DIR}")
print(f"Graphs directory: {GRAPHS_DIR}")

def export_graphs_from_notebook():
    """Export all graphs by re-running the notebook analysis code"""
    # This function will be called from within the notebook
    # The actual graph export will happen in the notebook cells
    pass

if __name__ == "__main__":
    print("This script should be run from within the Jupyter notebook.")
    print("Use the notebook cell to export graphs.")

