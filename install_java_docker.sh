#!/bin/bash
# Script to install Java/GraalVM and Docker
# Usage: ./install_java_docker.sh [--skip-java] [--skip-docker] [--help]
#   --skip-java: Skip Java/GraalVM installation
#   --skip-docker: Skip Docker installation
#   --help: Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_JAVA=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [--skip-java] [--skip-docker] [--help]"
            echo ""
            echo "This script installs:"
            echo "  - Java/GraalVM (with native-image support)"
            echo "  - Docker (optional, for containerized benchmarks)"
            echo ""
            echo "Options:"
            echo "  --skip-java    Skip Java/GraalVM installation"
            echo "  --skip-docker  Skip Docker installation"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        --skip-java)
            SKIP_JAVA=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
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
echo "JAVA/GRAALVM AND DOCKER INSTALLER"
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

# Function to detect architecture
detect_arch() {
    uname -m
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# JAVA/GRAALVM
# ============================================================================
if [ "$SKIP_JAVA" = false ]; then
    print_status "Installing Java/GraalVM..."
    
    # Check if already installed
    if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/java" ]; then
        JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
        print_success "Java/GraalVM already installed: $JAVA_HOME"
        print_success "Java version: ${JAVA_VERSION}"
        
        # Check for native-image
        if [ -f "$JAVA_HOME/bin/native-image" ]; then
            NATIVE_IMAGE_VERSION=$("$JAVA_HOME/bin/native-image" --version 2>&1 | head -1)
            print_success "native-image tool found: ${NATIVE_IMAGE_VERSION}"
        else
            print_warning "native-image tool not found (will be included in installation)"
        fi
    elif command_exists java; then
        JAVA_PATH=$(which java)
        JAVA_HOME_CANDIDATE=$(readlink -f "$JAVA_PATH" | sed "s:bin/java::")
        print_warning "Java found but JAVA_HOME not set. Installing GraalVM anyway..."
    else
        print_status "Java not found. Installing GraalVM..."
    fi
    
    # Install GraalVM
    GRAALVM_VERSION="21.0.1"
    GRAALVM_DIR="/opt/graalvm"
    ARCH=$(detect_arch)
    
    # Map architecture
    case "$ARCH" in
        x86_64)
            GRAALVM_ARCH="x64"
            ;;
        aarch64|arm64)
            GRAALVM_ARCH="aarch64"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    if [ -d "$GRAALVM_DIR" ] && [ -f "$GRAALVM_DIR/bin/java" ]; then
        print_success "GraalVM already installed at $GRAALVM_DIR"
    else
        print_status "Downloading GraalVM Community Edition ${GRAALVM_VERSION}..."
        GRAALVM_URL="https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-${GRAALVM_ARCH}_bin.tar.gz"
        TEMP_DIR=$(mktemp -d)
        TEMP_FILE="${TEMP_DIR}/graalvm.tar.gz"
        
        if ! curl -fsSL -o "$TEMP_FILE" "$GRAALVM_URL"; then
            print_error "Failed to download GraalVM"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        print_status "Extracting GraalVM to $GRAALVM_DIR..."
        sudo mkdir -p "$GRAALVM_DIR"
        sudo tar -xzf "$TEMP_FILE" -C "$GRAALVM_DIR" --strip-components=1
        rm -rf "$TEMP_DIR"
        print_success "GraalVM extracted to $GRAALVM_DIR"
    fi
    
    # Verify installation
    if [ -f "$GRAALVM_DIR/bin/java" ]; then
        JAVA_VERSION=$("$GRAALVM_DIR/bin/java" -version 2>&1 | head -1)
        print_success "GraalVM installed: ${JAVA_VERSION}"
        
        # Check native-image
        if [ -f "$GRAALVM_DIR/bin/native-image" ]; then
            NATIVE_IMAGE_VERSION=$("$GRAALVM_DIR/bin/native-image" --version 2>&1 | head -1)
            print_success "native-image tool available: ${NATIVE_IMAGE_VERSION}"
        else
            print_warning "native-image tool not found (it should be included in GraalVM)"
        fi
    else
        print_error "GraalVM installation failed"
        exit 1
    fi
    
    # Set JAVA_HOME in ~/.bashrc
    print_status "Setting JAVA_HOME in ~/.bashrc..."
    if ! grep -q "JAVA_HOME.*graalvm" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# GraalVM configuration" >> ~/.bashrc
        echo "export JAVA_HOME=$GRAALVM_DIR" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        print_success "JAVA_HOME added to ~/.bashrc"
    else
        print_warning "JAVA_HOME already configured in ~/.bashrc"
    fi
    
    # Export for current session
    export JAVA_HOME="$GRAALVM_DIR"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    print_success "Java/GraalVM installation complete!"
    print_status "Note: Run 'source ~/.bashrc' or start a new shell to use JAVA_HOME"
else
    print_status "Skipping Java/GraalVM installation (--skip-java)"
fi

# ============================================================================
# DOCKER
# ============================================================================
if [ "$SKIP_DOCKER" = false ]; then
    print_status "Installing Docker..."
    
    # Check if already installed
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>&1)
        print_success "Docker already installed: ${DOCKER_VERSION}"
    else
        DISTRO=$(detect_distro)
        
        case "$DISTRO" in
            ubuntu|debian)
                print_status "Installing Docker for Debian/Ubuntu..."
                
                # Install prerequisites
                print_status "Installing prerequisites..."
                sudo apt-get update -qq
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                
                # Add Docker's official GPG key
                print_status "Adding Docker's official GPG key..."
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                
                # Add Docker repository
                print_status "Adding Docker repository..."
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                
                # Install Docker
                print_status "Installing Docker Engine..."
                sudo apt-get update -qq
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                
                # Start Docker service
                print_status "Starting Docker service..."
                sudo systemctl start docker
                sudo systemctl enable docker
                
                # Add user to docker group
                print_status "Adding user to docker group..."
                sudo usermod -aG docker "$USER"
                
                print_success "Docker installed successfully!"
                print_warning "Note: You need to log out and log back in (or run 'newgrp docker') to use Docker without sudo"
                ;;
            fedora|rhel|centos)
                print_status "Installing Docker for Fedora/RHEL/CentOS..."
                
                # Install prerequisites
                print_status "Installing prerequisites..."
                sudo dnf install -y dnf-plugins-core || sudo yum install -y yum-utils
                
                # Add Docker repository
                print_status "Adding Docker repository..."
                if command_exists dnf; then
                    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                else
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                fi
                
                # Install Docker
                print_status "Installing Docker Engine..."
                if command_exists dnf; then
                    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                else
                    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                fi
                
                # Start Docker service
                print_status "Starting Docker service..."
                sudo systemctl start docker
                sudo systemctl enable docker
                
                # Add user to docker group
                print_status "Adding user to docker group..."
                sudo usermod -aG docker "$USER"
                
                print_success "Docker installed successfully!"
                print_warning "Note: You need to log out and log back in (or run 'newgrp docker') to use Docker without sudo"
                ;;
            arch|manjaro)
                print_status "Installing Docker for Arch Linux..."
                sudo pacman -S --noconfirm docker docker-compose
                
                # Start Docker service
                print_status "Starting Docker service..."
                sudo systemctl start docker
                sudo systemctl enable docker
                
                # Add user to docker group
                print_status "Adding user to docker group..."
                sudo usermod -aG docker "$USER"
                
                print_success "Docker installed successfully!"
                print_warning "Note: You need to log out and log back in (or run 'newgrp docker') to use Docker without sudo"
                ;;
            *)
                print_error "Unsupported distribution: $DISTRO"
                print_status "Please install Docker manually from: https://docs.docker.com/get-docker/"
                exit 1
                ;;
        esac
    fi
    
    # Verify Docker installation
    if sudo docker info >/dev/null 2>&1; then
        DOCKER_VERSION=$(sudo docker --version 2>&1)
        print_success "Docker is running: ${DOCKER_VERSION}"
    else
        print_warning "Docker installed but service may not be running"
    fi
else
    print_status "Skipping Docker installation (--skip-docker)"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "================================================================================"
echo "INSTALLATION SUMMARY"
echo "================================================================================"

if [ "$SKIP_JAVA" = false ]; then
    if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/java" ]; then
        JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
        print_success "Java/GraalVM: INSTALLED at $JAVA_HOME"
        print_success "  Version: ${JAVA_VERSION}"
        
        if [ -f "$JAVA_HOME/bin/native-image" ]; then
            print_success "  native-image: AVAILABLE"
        else
            print_warning "  native-image: NOT FOUND"
        fi
    else
        print_error "Java/GraalVM: INSTALLATION FAILED"
    fi
fi

if [ "$SKIP_DOCKER" = false ]; then
    if command_exists docker; then
        DOCKER_VERSION=$(sudo docker --version 2>&1)
        print_success "Docker: INSTALLED"
        print_success "  Version: ${DOCKER_VERSION}"
    else
        print_error "Docker: INSTALLATION FAILED"
    fi
fi

echo ""
print_status "Next steps:"
if [ "$SKIP_JAVA" = false ]; then
    echo "  1. Run 'source ~/.bashrc' or start a new shell to use JAVA_HOME"
fi
if [ "$SKIP_DOCKER" = false ]; then
    echo "  2. Log out and log back in (or run 'newgrp docker') to use Docker without sudo"
fi
echo ""
print_success "Installation complete!"

echo "================================================================================"

