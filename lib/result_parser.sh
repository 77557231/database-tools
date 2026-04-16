# lib/result_parser.sh - Result parsing module

# Get CPU cores
get_cpu_cores() {
    nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "unknown"
}

# Get memory size (MB)
get_memory_size_mb() {
    if [ -f /proc/meminfo ]; then
        awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null
    else
        echo "unknown"
    fi
}

# Parse CPU result
parse_cpu_result() {
    local result_file="$1"
    
    local events_per_sec=$(grep "events per second" "$result_file" 2>/dev/null | awk -F: '{print $2}' | tr -d ' ')
    local avg_latency=$(grep "avg:" "$result_file" 2>/dev/null | head -1 | awk '{print $NF}' | tr -d ',')
    local p95_latency=$(grep "95th percentile" "$result_file" 2>/dev/null | awk '{print $NF}')
    local p99_latency=$(grep "99th percentile" "$result_file" 2>/dev/null | awk '{print $NF}')
    
    # Extract Threads fairness metrics
    local threads_fairness_events=$(grep -A2 "Threads fairness:" "$result_file" 2>/dev/null | grep "events" | head -1)
    local threads_fairness_time=$(grep -A2 "Threads fairness:" "$result_file" 2>/dev/null | grep "execution time" | head -1)
    
    # Display detailed summary
    echo ""
    echo "CPU test summary:"
    echo "  CPU speed:"
    echo "    events per second: $events_per_sec"
    echo "  Avg Latency: ${avg_latency}ms"
    echo "  P95 Latency: ${p95_latency}ms"
    if [ -n "$p99_latency" ] && [ "$p99_latency" != "0" ]; then
        echo "  P99 Latency: ${p99_latency}ms"
    fi
    echo "  Threads fairness:"
    if [ -n "$threads_fairness_events" ]; then
        echo "    $threads_fairness_events"
    fi
    if [ -n "$threads_fairness_time" ]; then
        echo "    $threads_fairness_time"
    fi
}

# Parse memory result
parse_memory_result() {
    local result_file="$1"
    
    # Extract Total operations and operations per second
    local total_ops_line=$(grep "Total operations:" "$result_file" 2>/dev/null)
    local total_ops=$(echo "$total_ops_line" | awk '{print $3}')
    local ops_per_sec=$(echo "$total_ops_line" | awk -F'[()]' '{print $2}' | awk '{print $1}')
    
    # Extract transferred data and MiB/sec
    local transferred_line=$(grep "MiB transferred" "$result_file" 2>/dev/null)
    local transferred=$(echo "$transferred_line" | awk '{print $1}')
    local mib_per_sec=$(echo "$transferred_line" | awk -F'[()]' '{print $2}' | awk '{print $1}')
    
    local avg_latency=$(grep "avg:" "$result_file" 2>/dev/null | head -1 | awk '{print $NF}' | tr -d ',')
    
    # Extract p95 latency
    local p95_latency=$(grep "95th percentile" "$result_file" 2>/dev/null | awk '{print $NF}')
    
    # Display detailed summary
    echo ""
    echo "Memory test summary:"
    echo "  Total operations: ${total_ops} (${ops_per_sec} per second)"
    echo "  Transferred: ${transferred} MiB (${mib_per_sec} MiB/sec)"
    echo "  Avg Latency: ${avg_latency}ms"
    echo "  P95 Latency: ${p95_latency:-0}ms"
}

# Append result to combined results file
append_to_combined_result() {
    local section_title="$1"
    local result_file="$2"
    local combined_file="$OUTPUT_DIR/data_${TIMESTAMP}_all_results.txt"
    
    echo "" >> "$combined_file"
    echo "================================================================================" >> "$combined_file"
    echo "$section_title" >> "$combined_file"
    echo "================================================================================" >> "$combined_file"
    if [ -f "$result_file" ]; then
        cat "$result_file" >> "$combined_file"
    fi
    echo "" >> "$combined_file"
}

# Parse all results (summary call)
parse_all_results() {
    echo "Parsing test results..."
    
    # Parsing functions for each test are called in corresponding modules
    # Additional summary processing can be done here
    
    echo "✓ Result parsing completed"
}
