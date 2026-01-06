#!/bin/bash
# Script to set up Python virtual environment and install dependencies for Jupyter notebook analysis
# Usage: ./setup_jupyter.sh [--skip-venv] [--help]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv"
REQUIREMENTS_FILE="${SCRIPT_DIR}/requirements.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_VENV=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [--skip-venv] [--help]"
            echo ""
            echo "This script sets up the Python environment for running the Jupyter analysis notebook:"
            echo "  - Creates Python virtual environment (venv/)"
            echo "  - Installs required packages from requirements.txt"
            echo "  - Verifies installation"
            echo ""
            echo "Options:"
            echo "  --skip-venv    Skip virtual environment creation (use system Python)"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        --skip-venv)
            SKIP_VENV=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for Python 3
print_info "Checking for Python 3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Found Python ${PYTHON_VERSION}"
else
    print_error "Python 3 is not installed or not in PATH"
    echo "Please install Python 3.8 or higher:"
    echo "  - Debian/Ubuntu: sudo apt-get install python3 python3-venv python3-pip"
    echo "  - macOS: brew install python3"
    echo "  - Or download from https://www.python.org/downloads/"
    exit 1
fi

# Check Python version (3.8+)
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    print_error "Python 3.8 or higher is required. Found Python ${PYTHON_MAJOR}.${PYTHON_MINOR}"
    exit 1
fi

# Check if venv module is available
if [ "$SKIP_VENV" = false ]; then
    print_info "Checking for venv module..."
    if ! python3 -m venv --help &> /dev/null; then
        print_error "python3-venv package is not installed"
        echo ""
        echo "To install python3-venv, run:"
        echo "  sudo apt-get install python3.11-venv"
        echo ""
        echo "Or for other Python versions:"
        echo "  sudo apt-get install python3-venv"
        echo ""
        echo "Alternatively, you can skip virtual environment creation:"
        echo "  ./setup_jupyter.sh --skip-venv"
        exit 1
    fi
    print_success "venv module is available"
fi

# Create virtual environment
if [ "$SKIP_VENV" = false ]; then
    if [ -d "$VENV_DIR" ]; then
        print_warning "Virtual environment already exists at ${VENV_DIR}"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Removing existing virtual environment..."
            rm -rf "$VENV_DIR"
            print_success "Removed existing virtual environment"
        else
            print_info "Using existing virtual environment"
        fi
    fi

    if [ ! -d "$VENV_DIR" ]; then
        print_info "Creating Python virtual environment..."
        if python3 -m venv "$VENV_DIR" 2>&1; then
            print_success "Virtual environment created at ${VENV_DIR}"
        else
            print_error "Failed to create virtual environment"
            echo ""
            echo "This usually means python3-venv is not installed."
            echo "Install it with:"
            echo "  sudo apt-get install python3.11-venv"
            echo ""
            echo "Or use system Python instead:"
            echo "  ./setup_jupyter.sh --skip-venv"
            exit 1
        fi
    fi

    # Activate virtual environment
    print_info "Activating virtual environment..."
    source "${VENV_DIR}/bin/activate"
    print_success "Virtual environment activated"
else
    print_warning "Skipping virtual environment creation (using system Python)"
    if [ -n "$VIRTUAL_ENV" ]; then
        print_info "Already in a virtual environment: $VIRTUAL_ENV"
    fi
fi

# Upgrade pip
print_info "Upgrading pip..."
python3 -m pip install --upgrade pip --quiet
print_success "pip upgraded"

# Check if requirements.txt exists
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    print_error "requirements.txt not found at ${REQUIREMENTS_FILE}"
    print_info "Creating requirements.txt with default packages..."
    cat > "$REQUIREMENTS_FILE" << EOF
jupyter>=1.0.0
pandas>=1.5.0
numpy>=1.23.0
matplotlib>=3.6.0
seaborn>=0.12.0
EOF
    print_success "Created requirements.txt"
fi

# Install dependencies
print_info "Installing dependencies from requirements.txt..."
if python3 -m pip install -r "$REQUIREMENTS_FILE"; then
    print_success "All dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

# Verify installation
print_info "Verifying installation..."
MISSING_PACKAGES=()

for package in jupyter pandas numpy matplotlib seaborn; do
    if python3 -c "import ${package}" 2>/dev/null; then
        VERSION=$(python3 -c "import ${package}; print(getattr(${package}, '__version__', 'unknown'))" 2>/dev/null || echo "installed")
        print_success "${package} ${VERSION} is installed"
    else
        print_error "${package} is not installed"
        MISSING_PACKAGES+=("${package}")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    print_error "Some packages failed to install: ${MISSING_PACKAGES[*]}"
    exit 1
fi

# Print summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$SKIP_VENV" = false ]; then
    echo -e "${BLUE}To activate the virtual environment, run:${NC}"
    echo "  source venv/bin/activate"
    echo ""
    echo -e "${BLUE}To start Jupyter notebook, run:${NC}"
    echo "  source venv/bin/activate"
    echo "  jupyter notebook"
    echo ""
    echo -e "${BLUE}Or use JupyterLab:${NC}"
    echo "  source venv/bin/activate"
    echo "  jupyter lab"
    echo ""
    echo -e "${BLUE}To deactivate the virtual environment when done:${NC}"
    echo "  deactivate"
else
    echo -e "${BLUE}To start Jupyter notebook, run:${NC}"
    echo "  jupyter notebook"
    echo ""
    echo -e "${BLUE}Or use JupyterLab:${NC}"
    echo "  jupyter lab"
fi

echo ""
print_info "The analysis notebook is located at: analysis.ipynb"
print_info "Make sure the data/ directory contains benchmark results before running the notebook"

