#!/bin/bash
# Script to run barista shopcart benchmark with mixed requests multiple times
# Usage: ./run_shopcart_benchmark.sh [number_of_runs] [--mode jvm|native] [--no-output]
#   number_of_runs: Number of times to run the benchmark (default: 1)
#   --mode jvm|native: Execution mode - JVM or native (default: jvm)
#   --no-output: Skip outputting raw results to stdout (only save to files)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BARISTA_DIR="${SCRIPT_DIR}/barista"
# RESULTS_BASE_DIR will be set after MODE is determined

# Parse arguments
NUM_RUNS=1
OUTPUT_RESULTS=true
MODE="jvm"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [number_of_runs] [--mode jvm|native] [--no-output]"
            echo ""
            echo "Arguments:"
            echo "  number_of_runs    Number of times to run the benchmark (default: 1)"
            echo "  --mode jvm|native Execution mode - JVM or native (default: jvm)"
            echo "  --no-output       Skip outputting raw results to stdout (only save to files)"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Run once in JVM mode"
            echo "  $0 3                         # Run 3 times in JVM mode"
            echo "  $0 5 --mode native           # Run 5 times in native mode"
            echo "  $0 2 --mode jvm --no-output  # Run 2 times in JVM mode without stdout output"
            exit 0
            ;;
        --mode)
            if [[ "$2" == "jvm" ]] || [[ "$2" == "native" ]]; then
                MODE="$2"
                shift 2
            else
                echo "Error: Invalid mode '$2'. Must be 'jvm' or 'native'"
                exit 1
            fi
            ;;
        --no-output)
            OUTPUT_RESULTS=false
            shift
            ;;
        --*)
            echo "Error: Unknown option '$1'"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                NUM_RUNS=$1
                shift
            else
                echo "Error: Invalid argument '$1'"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
done

# Set results directory based on mode
RESULTS_BASE_DIR="${SCRIPT_DIR}/results-shopcart-${MODE}"

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

echo "Checking prerequisites..."
ERRORS=0
WARNINGS=0

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ ERROR: python3 is not installed or not in PATH"
    ERRORS=$((ERRORS + 1))
else
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "✓ Python 3 found: ${PYTHON_VERSION}"
fi

# Check Java/JVM
if [ -z "$JAVA_HOME" ]; then
    echo "❌ ERROR: JAVA_HOME environment variable is not set"
    ERRORS=$((ERRORS + 1))
else
    if [ ! -d "$JAVA_HOME" ]; then
        echo "❌ ERROR: JAVA_HOME points to non-existent directory: $JAVA_HOME"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ JAVA_HOME is set: $JAVA_HOME"
        if [ -f "$JAVA_HOME/bin/java" ]; then
            JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
            echo "  Java version: ${JAVA_VERSION}"
        else
            echo "⚠ WARNING: java executable not found in $JAVA_HOME/bin/"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# Check wrk
WRK_FOUND=false
if command -v wrk &> /dev/null; then
    WRK_VERSION=$(wrk --version 2>&1 | head -1)
    echo "✓ wrk found: ${WRK_VERSION}"
    WRK_FOUND=true
else
    # Check in common locations
    if [ -f "/tmp/wrk/wrk" ]; then
        export PATH="/tmp/wrk:$PATH"
        WRK_VERSION=$(wrk --version 2>&1 | head -1)
        echo "✓ wrk found in /tmp/wrk: ${WRK_VERSION}"
        WRK_FOUND=true
    else
        echo "❌ ERROR: wrk is not installed or not in PATH"
        echo "   Install from: https://github.com/wg/wrk"
        echo "   Or add to PATH: export PATH=\"\$PATH:/path/to/wrk\""
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check wrk2
WRK2_FOUND=false
if command -v wrk2 &> /dev/null; then
    WRK2_VERSION=$(wrk2 --version 2>&1 | head -1)
    echo "✓ wrk2 found: ${WRK2_VERSION}"
    WRK2_FOUND=true
else
    # Check in common locations
    if [ -f "/usr/local/bin/wrk2" ]; then
        export PATH="/usr/local/bin:$PATH"
        WRK2_VERSION=$(wrk2 --version 2>&1 | head -1)
        echo "✓ wrk2 found in /usr/local/bin: ${WRK2_VERSION}"
        WRK2_FOUND=true
    else
        echo "❌ ERROR: wrk2 is not installed or not in PATH"
        echo "   Install from: https://github.com/giltene/wrk2"
        echo "   Note: wrk2 executable must be renamed from 'wrk' to 'wrk2'"
        echo "   Or add to PATH: export PATH=\"\$PATH:/path/to/wrk2\""
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check if barista directory exists
if [ ! -d "${BARISTA_DIR}" ]; then
    echo "❌ ERROR: Barista directory not found: ${BARISTA_DIR}"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Barista directory found: ${BARISTA_DIR}"
    
    # Check if barista script exists
    if [ ! -f "${BARISTA_DIR}/barista" ]; then
        echo "❌ ERROR: barista script not found: ${BARISTA_DIR}/barista"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ barista script found"
    fi
    
    # Check if barista.py exists
    if [ ! -f "${BARISTA_DIR}/barista.py" ]; then
        echo "❌ ERROR: barista.py not found: ${BARISTA_DIR}/barista.py"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ barista.py found"
    fi
fi

# Check if micronaut-shopcart benchmark exists
SHOPCART_DIR="${BARISTA_DIR}/benchmarks/micronaut-shopcart"
if [ ! -d "${SHOPCART_DIR}" ]; then
    echo "❌ ERROR: micronaut-shopcart benchmark not found: ${SHOPCART_DIR}"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ micronaut-shopcart benchmark directory found"
    
    # Check if application is built (depends on mode)
    if [ "$MODE" == "jvm" ]; then
        JAR_FILE=$(find "${SHOPCART_DIR}/target" -name "shopcart-*.jar" 2>/dev/null | head -1)
        if [ -z "$JAR_FILE" ]; then
            echo "⚠ WARNING: Application JAR not found. It will be built automatically."
            echo "   Expected location: ${SHOPCART_DIR}/target/shopcart-*.jar"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "✓ Application JAR found: $(basename "$JAR_FILE")"
        fi
    elif [ "$MODE" == "native" ]; then
        # Check for native image or NIB
        NATIVE_IMAGE=$(find "${SHOPCART_DIR}/target" -name "shopcart-*" -type f ! -name "*.jar" ! -name "*.nib" 2>/dev/null | head -1)
        NIB_FILE=$(find "${SHOPCART_DIR}/target" -name "shopcart-*.nib" 2>/dev/null | head -1)
        if [ -z "$NATIVE_IMAGE" ] && [ -z "$NIB_FILE" ]; then
            echo "⚠ WARNING: Native image or NIB not found. It will be built automatically."
            echo "   Expected: ${SHOPCART_DIR}/target/shopcart-* (native executable) or *.nib file"
            WARNINGS=$((WARNINGS + 1))
        else
            if [ -n "$NATIVE_IMAGE" ]; then
                echo "✓ Native image found: $(basename "$NATIVE_IMAGE")"
            fi
            if [ -n "$NIB_FILE" ]; then
                echo "✓ NIB file found: $(basename "$NIB_FILE")"
            fi
        fi
        
        # Check for native-image tool if building
        if [ -z "$NATIVE_IMAGE" ] && [ -z "$NIB_FILE" ]; then
            if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/native-image" ]; then
                NATIVE_IMAGE_VERSION=$("$JAVA_HOME/bin/native-image" --version 2>&1 | head -1)
                echo "✓ native-image tool found: ${NATIVE_IMAGE_VERSION}"
            else
                echo "❌ ERROR: native-image tool not found in $JAVA_HOME/bin/"
                echo "   Native mode requires GraalVM with native-image tool"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    fi
    
    # Check if mixed-requests.lua exists
    if [ ! -f "${SHOPCART_DIR}/workloads/mixed-requests.lua" ]; then
        echo "❌ ERROR: mixed-requests.lua not found: ${SHOPCART_DIR}/workloads/mixed-requests.lua"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ mixed-requests.lua workload found"
    fi
fi

# Check disk space (at least 1GB free recommended)
AVAILABLE_SPACE=$(df -BG "${RESULTS_BASE_DIR}" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//')
if [ -n "$AVAILABLE_SPACE" ] && [ "$AVAILABLE_SPACE" -lt 1 ]; then
    echo "⚠ WARNING: Low disk space: ${AVAILABLE_SPACE}GB available (recommended: at least 1GB)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✓ Sufficient disk space available"
fi

echo ""
if [ $ERRORS -gt 0 ]; then
    echo "================================================================================"
    echo "❌ PREREQUISITE CHECK FAILED"
    echo "================================================================================"
    echo "Found $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    echo "Please fix the errors above before running the benchmark."
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo "================================================================================"
    echo "⚠ PREREQUISITE CHECK PASSED WITH WARNINGS"
    echo "================================================================================"
    echo "Found $WARNINGS warning(s). The benchmark will continue, but some issues may occur."
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    echo ""
else
    echo "================================================================================"
    echo "✓ ALL PREREQUISITES CHECKED SUCCESSFULLY"
    echo "================================================================================"
    echo ""
fi

# Ensure wrk is in PATH (final check)
if [ "$WRK_FOUND" = false ]; then
    export PATH="/tmp/wrk:$PATH"
fi

# Create base results directory
mkdir -p "${RESULTS_BASE_DIR}"

echo "================================================================================"
echo "BARISTA SHOPCART BENCHMARK - MULTIPLE RUNS"
echo "================================================================================"
echo "Number of runs: ${NUM_RUNS}"
echo "Execution mode: ${MODE}"
echo "Results base directory: ${RESULTS_BASE_DIR}"
echo "Output results to stdout: ${OUTPUT_RESULTS}"
echo "================================================================================"
echo ""

# Array to store all run directories
declare -a RUN_DIRS

# Run the benchmark multiple times
for ((run=1; run<=NUM_RUNS; run++)); do
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    RUN_DIR="${RESULTS_BASE_DIR}/run_${run}_${TIMESTAMP}"
    
    echo "================================================================================"
    echo "RUN ${run}/${NUM_RUNS} - Starting at ${TIMESTAMP}"
    echo "================================================================================"
    
    # Create timestamped directory for this run
    mkdir -p "${RUN_DIR}"
    RUN_DIRS+=("${RUN_DIR}")
    
    # Run the benchmark
    cd "${BARISTA_DIR}"
    
    # For native mode, check if we can reuse an existing native image
    APP_EXECUTABLE_ARG=""
    if [ "$MODE" == "native" ]; then
        # Check for NIB file to determine where native image would be built
        NIB_FILE=$(find "${SHOPCART_DIR}/target" -name "shopcart-*.nib" 2>/dev/null | head -1)
        if [ -n "$NIB_FILE" ]; then
            # Native image is built in {nib_file}.output/default/{bench_name}
            # The bench_name is "micronaut-shopcart"
            NIB_BASENAME=$(basename "$NIB_FILE" .nib)
            NIB_DIR=$(dirname "$NIB_FILE")
            EXPECTED_NATIVE_IMAGE="${NIB_DIR}/${NIB_BASENAME}.output/default/micronaut-shopcart"
            
            # Check if native image exists and is newer than NIB
            if [ -f "$EXPECTED_NATIVE_IMAGE" ]; then
                IMAGE_MTIME=$(stat -c %Y "$EXPECTED_NATIVE_IMAGE" 2>/dev/null || stat -f %m "$EXPECTED_NATIVE_IMAGE" 2>/dev/null)
                NIB_MTIME=$(stat -c %Y "$NIB_FILE" 2>/dev/null || stat -f %m "$NIB_FILE" 2>/dev/null)
                if [ -n "$IMAGE_MTIME" ] && [ -n "$NIB_MTIME" ] && [ "$IMAGE_MTIME" -gt "$NIB_MTIME" ]; then
                    echo "Reusing existing native image: $EXPECTED_NATIVE_IMAGE"
                    APP_EXECUTABLE_ARG="--app-executable ${EXPECTED_NATIVE_IMAGE}"
                else
                    echo "Native image exists but is older than NIB, will rebuild"
                fi
            else
                echo "Native image not found at: $EXPECTED_NATIVE_IMAGE (will be built)"
            fi
        fi
    fi
    
    ./barista micronaut-shopcart --mode "${MODE}" --resource-usage-polling-interval 0.02 \
        --startup-iteration-count 0 --warmup-iteration-count 0 ${APP_EXECUTABLE_ARG}
    
    # Find the latest results directory from barista
    LATEST_RESULT=$(find "${BARISTA_DIR}/logs" -type d -name "*bench-*" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    
    if [ -z "$LATEST_RESULT" ] || [ ! -d "$LATEST_RESULT" ]; then
        echo "Error: Could not find results directory for run ${run}"
        continue
    fi
    
    echo "Found results directory: ${LATEST_RESULT}"
    echo "Copying results to: ${RUN_DIR}"
    
    # Copy all result files to timestamped directory
    cp -r "${LATEST_RESULT}"/* "${RUN_DIR}/" 2>/dev/null || true
    
    # Create a summary file for this run
    cat > "${RUN_DIR}/run_info.txt" << EOF
Run Number: ${run}/${NUM_RUNS}
Timestamp: ${TIMESTAMP}
Execution Mode: ${MODE}
Source Directory: ${LATEST_RESULT}
Destination Directory: ${RUN_DIR}
EOF
    
    echo "Run ${run} completed. Results saved to: ${RUN_DIR}"
    echo ""
    
    # Small delay between runs to ensure clean separation
    if [ $run -lt $NUM_RUNS ]; then
        sleep 2
    fi
done

# Output summary
echo "================================================================================"
echo "ALL RUNS COMPLETED"
echo "================================================================================"
echo "Total runs: ${NUM_RUNS}"
echo "Results directories:"
for dir in "${RUN_DIRS[@]}"; do
    echo "  - ${dir}"
done
echo ""

# Output all results if requested
if [ "$OUTPUT_RESULTS" = true ]; then
    for ((run=1; run<=NUM_RUNS; run++)); do
        RUN_DIR="${RUN_DIRS[$((run-1))]}"
        
        echo "================================================================================"
        echo "RAW RESULTS - RUN ${run}/${NUM_RUNS} (${RUN_DIR})"
        echo "================================================================================"
        
        # Output JSON
        echo ""
        echo "--- JSON (barista-results.json) ---"
        cat "${RUN_DIR}/barista-results.json" 2>/dev/null || echo "File not found"
        
        # Output CSV files
        echo ""
        echo "--- STARTUP (barista_startup_results.csv) ---"
        cat "${RUN_DIR}/barista_startup_results.csv" 2>/dev/null || echo "File not found"
        
        echo ""
        echo "--- WARMUP (barista_warmup_results.csv) ---"
        cat "${RUN_DIR}/barista_warmup_results.csv" 2>/dev/null || echo "File not found"
        
        echo ""
        echo "--- THROUGHPUT (barista_throughput_results.csv) ---"
        cat "${RUN_DIR}/barista_throughput_results.csv" 2>/dev/null || echo "File not found"
        
        echo ""
        echo "--- LATENCY (final_measurements-barista_latency_results.csv) ---"
        cat "${RUN_DIR}/final_measurements-barista_latency_results.csv" 2>/dev/null || echo "File not found"
        
        # Output resource usage (first 50 lines)
        echo ""
        echo "--- RESOURCE USAGE (barista_resource_usage.csv - first 50 lines) ---"
        head -50 "${RUN_DIR}/barista_resource_usage.csv" 2>/dev/null || echo "File not found"
        echo "... (total lines: $(wc -l < "${RUN_DIR}/barista_resource_usage.csv" 2>/dev/null || echo 0))"
        
        # Output application dump
        echo ""
        echo "--- APPLICATION OUTPUT (app-dump.txt) ---"
        cat "${RUN_DIR}/app-dump.txt" 2>/dev/null || echo "File not found"
        
        # Output wrk/wrk2 dumps
        echo ""
        echo "--- WRK/WRK2 DUMPS ---"
        for file in "${RUN_DIR}"/warmup-*.txt "${RUN_DIR}"/throughput-*.txt "${RUN_DIR}"/*-latency-*.txt; do
            if [ -f "$file" ]; then
                echo ""
                echo "--- $(basename "$file") ---"
                cat "$file"
            fi
        done
        
        echo ""
        echo "================================================================================"
    done
fi

echo ""
echo "================================================================================"
echo "BENCHMARK COMPLETE"
echo "================================================================================"
echo "Execution mode: ${MODE}"
echo "Total runs: ${NUM_RUNS}"
echo "All results have been saved to separate timestamped directories:"
for dir in "${RUN_DIRS[@]}"; do
    echo "  ${dir}"
done
echo ""
echo "To run again with different options:"
echo "  $0 ${NUM_RUNS} --mode ${MODE} --no-output"
echo "================================================================================"
