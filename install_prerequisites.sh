#!/bin/bash
# Script to install prerequisites for barista benchmark scripts
# Usage: ./install_prerequisites.sh [--skip-java] [--skip-wrk] [--skip-wrk2] [--help]
#   --skip-java: Skip Java/GraalVM installation checks and setup
#   --skip-wrk: Skip wrk installation
#   --skip-wrk2: Skip wrk2 installation
#   --help: Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/.prerequisites"
WRK_DIR="${INSTALL_DIR}/wrk"
WRK2_DIR="${INSTALL_DIR}/wrk2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_JAVA=false
SKIP_WRK=false
SKIP_WRK2=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [--skip-java] [--skip-wrk] [--skip-wrk2] [--help]"
            echo ""
            echo "This script installs prerequisites for barista benchmark scripts:"
            echo "  - Python 3"
            echo "  - Java/GraalVM (JAVA_HOME setup)"
            echo "  - wrk (load testing tool)"
            echo "  - wrk2 (latency testing tool)"
            echo ""
            echo "Options:"
            echo "  --skip-java    Skip Java/GraalVM installation checks"
            echo "  --skip-wrk     Skip wrk installation"
            echo "  --skip-wrk2    Skip wrk2 installation"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        --skip-java)
            SKIP_JAVA=true
            shift
            ;;
        --skip-wrk)
            SKIP_WRK=true
            shift
            ;;
        --skip-wrk2)
            SKIP_WRK2=true
            shift
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "================================================================================"
echo "BARISTA BENCHMARK PREREQUISITES INSTALLER"
echo "================================================================================"
echo ""

# Function to print status messages
print_status() {
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

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create install directory
mkdir -p "${INSTALL_DIR}"

# ============================================================================
# PYTHON 3
# ============================================================================
print_status "Checking Python 3..."

if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    print_success "Python 3 found: ${PYTHON_VERSION}"
else
    print_error "Python 3 is not installed"
    DISTRO=$(detect_distro)
    
    case "$DISTRO" in
        ubuntu|debian)
            print_status "Installing Python 3..."
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
            print_success "Python 3 installed"
            ;;
        fedora|rhel|centos)
            print_status "Installing Python 3..."
            sudo dnf install -y python3 python3-pip || sudo yum install -y python3 python3-pip
            print_success "Python 3 installed"
            ;;
        arch|manjaro)
            print_status "Installing Python 3..."
            sudo pacman -S --noconfirm python python-pip
            print_success "Python 3 installed"
            ;;
        *)
            print_warning "Unknown distribution. Please install Python 3 manually."
            print_warning "  Ubuntu/Debian: sudo apt-get install python3 python3-pip"
            print_warning "  Fedora/RHEL: sudo dnf install python3 python3-pip"
            print_warning "  Arch: sudo pacman -S python python-pip"
            ;;
    esac
fi

# Install psutil for non-Linux platforms (optional, but recommended)
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_status "Installing psutil for non-Linux platform..."
    python3 -m pip install --user psutil || print_warning "Failed to install psutil (optional)"
fi

# ============================================================================
# JAVA/GRAALVM
# ============================================================================
if [ "$SKIP_JAVA" = false ]; then
    print_status "Checking Java/GraalVM..."
    
    if [ -n "$JAVA_HOME" ]; then
        if [ -d "$JAVA_HOME" ]; then
            if [ -f "$JAVA_HOME/bin/java" ]; then
                JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
                print_success "JAVA_HOME is set: $JAVA_HOME"
                print_success "Java version: ${JAVA_VERSION}"
                
                # Check for native-image tool
                if [ -f "$JAVA_HOME/bin/native-image" ]; then
                    NATIVE_IMAGE_VERSION=$("$JAVA_HOME/bin/native-image" --version 2>&1 | head -1)
                    print_success "native-image tool found: ${NATIVE_IMAGE_VERSION}"
                else
                    print_warning "native-image tool not found (required for native mode)"
                    print_warning "  Install with: gu install native-image"
                fi
            else
                print_error "JAVA_HOME points to invalid directory (no java executable)"
            fi
        else
            print_error "JAVA_HOME points to non-existent directory: $JAVA_HOME"
        fi
    else
        print_warning "JAVA_HOME is not set"
        print_status "Checking for system Java..."
        
        if command_exists java; then
            JAVA_VERSION=$(java -version 2>&1 | head -1)
            JAVA_PATH=$(which java)
            JAVA_HOME_CANDIDATE=$(readlink -f "$JAVA_PATH" | sed "s:bin/java::")
            
            print_success "Java found: ${JAVA_VERSION}"
            print_warning "JAVA_HOME is not set. Found Java at: ${JAVA_HOME_CANDIDATE}"
            print_status "To set JAVA_HOME, add to your ~/.bashrc or ~/.zshrc:"
            echo "  export JAVA_HOME=\"${JAVA_HOME_CANDIDATE}\""
            echo "  export PATH=\"\$JAVA_HOME/bin:\$PATH\""
        else
            print_error "Java is not installed"
            print_status "Please install Java or GraalVM:"
            print_status "  1. Download GraalVM from: https://www.graalvm.org/downloads/"
            print_status "  2. Extract to a directory (e.g., /opt/graalvm)"
            print_status "  3. Set JAVA_HOME: export JAVA_HOME=/opt/graalvm"
            print_status "  4. Add to PATH: export PATH=\"\$JAVA_HOME/bin:\$PATH\""
            print_status ""
            print_status "Or install OpenJDK:"
            DISTRO=$(detect_distro)
            case "$DISTRO" in
                ubuntu|debian)
                    echo "  sudo apt-get install openjdk-17-jdk"
                    ;;
                fedora|rhel|centos)
                    echo "  sudo dnf install java-17-openjdk-devel"
                    ;;
                arch|manjaro)
                    echo "  sudo pacman -S jdk-openjdk"
                    ;;
            esac
        fi
    fi
else
    print_status "Skipping Java/GraalVM checks (--skip-java)"
fi

# ============================================================================
# WRK
# ============================================================================
if [ "$SKIP_WRK" = false ]; then
    print_status "Checking wrk..."
    
    if command_exists wrk; then
        WRK_VERSION=$(wrk --version 2>&1 | head -1)
        print_success "wrk found: ${WRK_VERSION}"
    else
        print_status "wrk not found. Installing..."
        
        # Check if already built in install directory
        if [ -f "${WRK_DIR}/wrk" ]; then
            print_success "Found existing wrk build in ${WRK_DIR}"
            export PATH="${WRK_DIR}:$PATH"
            WRK_VERSION=$(wrk --version 2>&1 | head -1)
            print_success "wrk found: ${WRK_VERSION}"
        else
            print_status "Building wrk from source..."
            
            # Check for required build tools
            if ! command_exists make; then
                DISTRO=$(detect_distro)
                case "$DISTRO" in
                    ubuntu|debian)
                        sudo apt-get install -y build-essential
                        ;;
                    fedora|rhel|centos)
                        sudo dnf groupinstall -y "Development Tools" || sudo yum groupinstall -y "Development Tools"
                        ;;
                    arch|manjaro)
                        sudo pacman -S --noconfirm base-devel
                        ;;
                esac
            fi
            
            # Clone and build wrk
            if [ ! -d "${WRK_DIR}" ]; then
                print_status "Cloning wrk repository..."
                git clone https://github.com/wg/wrk.git "${WRK_DIR}" || {
                    print_error "Failed to clone wrk repository"
                    exit 1
                }
            fi
            
            cd "${WRK_DIR}"
            print_status "Building wrk..."
            make || {
                print_error "Failed to build wrk"
                exit 1
            }
            
            export PATH="${WRK_DIR}:$PATH"
            WRK_VERSION=$(wrk --version 2>&1 | head -1)
            print_success "wrk built successfully: ${WRK_VERSION}"
            
            print_status "To make wrk available permanently, add to your ~/.bashrc or ~/.zshrc:"
            echo "  export PATH=\"${WRK_DIR}:\$PATH\""
        fi
    fi
else
    print_status "Skipping wrk installation (--skip-wrk)"
fi

# ============================================================================
# WRK2
# ============================================================================
if [ "$SKIP_WRK2" = false ]; then
    print_status "Checking wrk2..."
    
    if command_exists wrk2; then
        WRK2_VERSION=$(wrk2 --version 2>&1 | head -1)
        print_success "wrk2 found: ${WRK2_VERSION}"
    else
        print_status "wrk2 not found. Installing..."
        
        # Check if already built in install directory
        if [ -f "${WRK2_DIR}/wrk2" ]; then
            print_success "Found existing wrk2 build in ${WRK2_DIR}"
            export PATH="${WRK2_DIR}:$PATH"
            WRK2_VERSION=$(wrk2 --version 2>&1 | head -1)
            print_success "wrk2 found: ${WRK2_VERSION}"
        else
            print_status "Building wrk2 from source..."
            
            # Check for required build tools
            if ! command_exists make; then
                DISTRO=$(detect_distro)
                case "$DISTRO" in
                    ubuntu|debian)
                        sudo apt-get install -y build-essential
                        ;;
                    fedora|rhel|centos)
                        sudo dnf groupinstall -y "Development Tools" || sudo yum groupinstall -y "Development Tools"
                        ;;
                    arch|manjaro)
                        sudo pacman -S --noconfirm base-devel
                        ;;
                esac
            fi
            
            # Clone and build wrk2
            if [ ! -d "${WRK2_DIR}" ]; then
                print_status "Cloning wrk2 repository..."
                git clone https://github.com/giltene/wrk2.git "${WRK2_DIR}" || {
                    print_error "Failed to clone wrk2 repository"
                    exit 1
                }
            fi
            
            cd "${WRK2_DIR}"
            print_status "Building wrk2..."
            make || {
                print_error "Failed to build wrk2"
                exit 1
            }
            
            # Rename wrk to wrk2 (required by barista)
            if [ -f "${WRK2_DIR}/wrk" ] && [ ! -f "${WRK2_DIR}/wrk2" ]; then
                mv "${WRK2_DIR}/wrk" "${WRK2_DIR}/wrk2"
                print_status "Renamed wrk executable to wrk2"
            fi
            
            export PATH="${WRK2_DIR}:$PATH"
            if [ -f "${WRK2_DIR}/wrk2" ]; then
                WRK2_VERSION=$(wrk2 --version 2>&1 | head -1)
                print_success "wrk2 built successfully: ${WRK2_VERSION}"
                
                print_status "To make wrk2 available permanently, add to your ~/.bashrc or ~/.zshrc:"
                echo "  export PATH=\"${WRK2_DIR}:\$PATH\""
            else
                print_error "wrk2 executable not found after build"
                exit 1
            fi
        fi
    fi
else
    print_status "Skipping wrk2 installation (--skip-wrk2)"
fi

# ============================================================================
# BARISTA DIRECTORY CHECK
# ============================================================================
print_status "Checking barista directory..."
BARISTA_DIR="${SCRIPT_DIR}/barista"

if [ ! -d "${BARISTA_DIR}" ]; then
    print_error "Barista directory not found: ${BARISTA_DIR}"
    print_error "Please ensure the barista directory exists in the project root"
else
    print_success "Barista directory found: ${BARISTA_DIR}"
    
    if [ ! -f "${BARISTA_DIR}/barista" ]; then
        print_warning "barista script not found: ${BARISTA_DIR}/barista"
    else
        print_success "barista script found"
    fi
    
    if [ ! -f "${BARISTA_DIR}/barista.py" ]; then
        print_warning "barista.py not found: ${BARISTA_DIR}/barista.py"
    else
        print_success "barista.py found"
    fi
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "================================================================================"
echo "INSTALLATION SUMMARY"
echo "================================================================================"

# Check what's available now
MISSING=0

if ! command_exists python3; then
    print_error "Python 3: NOT INSTALLED"
    MISSING=$((MISSING + 1))
else
    print_success "Python 3: INSTALLED"
fi

if [ "$SKIP_JAVA" = false ]; then
    if [ -z "$JAVA_HOME" ] || [ ! -f "$JAVA_HOME/bin/java" ]; then
        if command_exists java; then
            print_warning "Java: FOUND BUT JAVA_HOME NOT SET"
        else
            print_error "Java: NOT INSTALLED"
            MISSING=$((MISSING + 1))
        fi
    else
        print_success "Java: INSTALLED (JAVA_HOME set)"
    fi
fi

if [ "$SKIP_WRK" = false ]; then
    if command_exists wrk || [ -f "${WRK_DIR}/wrk" ]; then
        print_success "wrk: INSTALLED"
    else
        print_error "wrk: NOT INSTALLED"
        MISSING=$((MISSING + 1))
    fi
fi

if [ "$SKIP_WRK2" = false ]; then
    if command_exists wrk2 || [ -f "${WRK2_DIR}/wrk2" ]; then
        print_success "wrk2: INSTALLED"
    else
        print_error "wrk2: NOT INSTALLED"
        MISSING=$((MISSING + 1))
    fi
fi

if [ -d "${BARISTA_DIR}" ]; then
    print_success "Barista directory: FOUND"
else
    print_error "Barista directory: NOT FOUND"
    MISSING=$((MISSING + 1))
fi

echo ""
if [ $MISSING -gt 0 ]; then
    print_warning "Some prerequisites are still missing. Please install them manually."
    echo ""
    print_status "Next steps:"
    echo "  1. If JAVA_HOME is not set, add it to your shell profile (~/.bashrc or ~/.zshrc)"
    echo "  2. If wrk/wrk2 were built, add them to your PATH in your shell profile"
    echo "  3. Reload your shell: source ~/.bashrc (or source ~/.zshrc)"
    echo "  4. Run the benchmark scripts: ./run_petclinic_benchmark.sh"
    exit 1
else
    print_success "All prerequisites are installed!"
    echo ""
    print_status "To use wrk/wrk2 in this session, run:"
    if [ -f "${WRK_DIR}/wrk" ]; then
        echo "  export PATH=\"${WRK_DIR}:\$PATH\""
    fi
    if [ -f "${WRK2_DIR}/wrk2" ]; then
        echo "  export PATH=\"${WRK2_DIR}:\$PATH\""
    fi
    echo ""
    print_status "To make these changes permanent, add the export commands to ~/.bashrc or ~/.zshrc"
    echo ""
    print_success "You can now run the benchmark scripts:"
    echo "  ./run_petclinic_benchmark.sh"
    echo "  ./run_shopcart_benchmark.sh"
    echo "  ./run_tika_benchmark.sh"
fi

echo "================================================================================"

