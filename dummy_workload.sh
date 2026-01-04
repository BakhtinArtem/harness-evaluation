#!/bin/bash
# Dummy workload script that simulates background work on the container
# This process will consume CPU and memory to simulate other work happening

# Configuration
CPU_INTENSITY=${DUMMY_CPU_INTENSITY:-0.1}  # 0.0 to 1.0, default 10% CPU usage
MEMORY_MB=${DUMMY_MEMORY_MB:-100}          # Memory to allocate in MB
INTERVAL=${DUMMY_INTERVAL:-1}              # Sleep interval in seconds

echo "Starting dummy workload process (PID: $$)"
echo "CPU intensity: ${CPU_INTENSITY}"
echo "Memory allocation: ${MEMORY_MB}MB"
echo "Interval: ${INTERVAL}s"

# Create a temporary file to hold memory
MEMORY_FILE="/tmp/dummy_workload_memory.dat"

# Allocate memory by creating a file
if [ ! -f "$MEMORY_FILE" ]; then
    echo "Allocating ${MEMORY_MB}MB of memory..."
    dd if=/dev/zero of="$MEMORY_FILE" bs=1M count=${MEMORY_MB} 2>/dev/null
fi

# Function to simulate CPU work
cpu_work() {
    # Calculate iterations based on CPU intensity (0.0 to 1.0)
    # Simple approach: multiply by 100000 for base iterations
    # Handle decimal by converting to integer (e.g., 0.1 -> 10000 iterations)
    local intensity_str="${CPU_INTENSITY}"
    # If it's a decimal like 0.1, convert to 10000 iterations
    if [[ "$intensity_str" == 0.* ]]; then
        # Extract decimal part (e.g., 0.1 -> 1, then multiply by 10000)
        local decimal_part="${intensity_str#0.}"
        local iterations=$((decimal_part * 10000))
    else
        # If it's >= 1.0, use full iterations
        local iterations=$((intensity_str * 100000))
    fi
    # Ensure minimum iterations
    [ $iterations -lt 1000 ] && iterations=1000
    
    # Perform CPU-intensive operations
    local i=0
    local result=0
    while [ $i -lt $iterations ]; do
        # Simple mathematical operations
        result=$((result + i * 2))
        result=$((result % 1000000))  # Prevent overflow
        i=$((i + 1))
    done
}

# Function to simulate I/O work (reading/writing memory)
io_work() {
    # Read from memory file periodically
    if [ -f "$MEMORY_FILE" ]; then
        # Read a small chunk to simulate I/O
        dd if="$MEMORY_FILE" of=/dev/null bs=1M count=1 2>/dev/null
    fi
}

# Main loop
while true; do
    # Perform CPU work
    cpu_work
    
    # Perform I/O work occasionally
    if [ $((RANDOM % 10)) -eq 0 ]; then
        io_work
    fi
    
    # Sleep to control CPU usage
    sleep ${INTERVAL}
done

