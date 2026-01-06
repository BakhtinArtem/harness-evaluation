#!/bin/bash
# Script to install all dependencies needed for PDF export from Jupyter notebook

echo "Installing dependencies for PDF export..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo privileges. Please run:"
    echo "  sudo bash install_pdf_dependencies.sh"
    exit 1
fi

# Detect OS
if [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu system"
    echo "Installing Pandoc and LaTeX..."
    apt-get update
    apt-get install -y pandoc texlive-xetex texlive-fonts-recommended texlive-latex-extra
    echo ""
    echo "✓ Dependencies installed!"
    echo ""
    echo "You can now run: python3 export_for_thesis.py"
elif [ "$(uname)" == "Darwin" ]; then
    echo "Detected macOS"
    echo "Installing Pandoc..."
    if command -v brew &> /dev/null; then
        brew install pandoc
        echo "Installing LaTeX (this may take a while)..."
        brew install --cask mactex
        echo ""
        echo "✓ Dependencies installed!"
    else
        echo "Homebrew not found. Please install:"
        echo "  brew install pandoc"
        echo "  brew install --cask mactex"
    fi
else
    echo "Unknown OS. Please install manually:"
    echo "  - Pandoc: https://pandoc.org/installing.html"
    echo "  - LaTeX: https://www.latex-project.org/get/"
fi

