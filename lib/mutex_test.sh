# lib/mutex_test.sh - Mutex test module

run_mutex_test() {
    echo "=== Mutex Performance Test ==="
    
    local temp_output_file="/tmp/vb_mutex_${TIMESTAMP}.txt"
    local threads="${MUTEX_THREADS:-1000}"
    
    echo "Starting mutex test..."
    echo "  Threads: $threads, Duration: ${MUTEX_DURATION:-60}s, mutex num: ${MUTEX_NUM:-1024}"
    
    sysbench mutex \
        --mutex-num="${MUTEX_NUM:-1024}" \
        --threads="$threads" \
        --time="${MUTEX_DURATION:-60}" \
        run > "$temp_output_file" 2>&1
    
    # Parse result and display detailed output
    parse_mutex_result "$temp_output_file"
    
    # Append to combined results file
    append_to_combined_result "MUTEX TEST RESULTS" "$temp_output_file"
    
    # Cleanup temp file
    rm -f "$temp_output_file"
    
    echo "✓ Mutex test completed"
}

parse_mutex_result() {
    local result_file="$1"
    
    # Extract metrics (sysbench 1.0.20 format)
    local transactions=$(grep "total number of events:" "$result_file" 2>/dev/null | awk '{print $NF}' || echo "0")
    local total_time=$(grep "total time:" "$result_file" 2>/dev/null | awk '{print $NF}' | tr -d 's' || echo "1")
    local tps=$(awk "BEGIN {printf \"%.2f\", $transactions / $total_time}" 2>/dev/null || echo "0")
    local avg_latency=$(grep "avg:" "$result_file" 2>/dev/null | head -1 | awk '{print $NF}' | tr -d ',' || echo "0")
    local p95_latency=$(grep "95th percentile" "$result_file" 2>/dev/null | awk '{print $NF}' || echo "0")
    
    # Display detailed summary
    echo ""
    echo "Mutex test summary:"
    echo "  Transactions: $transactions"
    echo "  TPS: $tps"
    echo "  Avg Latency: ${avg_latency}ms"
    echo "  P95 Latency: ${p95_latency}ms"
}
