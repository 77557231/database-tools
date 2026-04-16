# lib/threads_test.sh - Threads test module

run_threads_test() {
    echo "=== Threads Performance Test ==="
    
    local temp_output_file="/tmp/vb_threads_${TIMESTAMP}.txt"
    local threads="${THREADS_NUM:-1000}"
    
    echo "Starting threads test..."
    echo "  Threads: $threads, Duration: ${THREADS_DURATION:-60}s, yields: ${THREAD_YIELDS:-100}, locks: ${THREAD_LOCKS:-4}"
    
    sysbench threads \
        --threads="$threads" \
        --thread-yields="${THREAD_YIELDS:-100}" \
        --thread-locks="${THREAD_LOCKS:-4}" \
        --time="${THREADS_DURATION:-60}" \
        run > "$temp_output_file" 2>&1
    
    # Parse result and display detailed output
    parse_threads_result "$temp_output_file"
    
    # Append to combined results file
    append_to_combined_result "THREADS TEST RESULTS" "$temp_output_file"
    
    # Cleanup temp file
    rm -f "$temp_output_file"
    
    echo "✓ Threads test completed"
}

parse_threads_result() {
    local result_file="$1"
    
    # Calculate events per second
    local total_events=$(grep "total number of events:" "$result_file" | awk '{print $NF}')
    local total_time=$(grep "total time:" "$result_file" | awk '{print $NF}' | tr -d 's')
    local events_per_sec=$(awk "BEGIN {printf \"%.2f\", $total_events / $total_time}")
    
    # Extract latency metrics
    local avg_latency=$(grep "avg:" "$result_file" | head -1 | awk '{print $NF}' | tr -d ',')
    local p95_latency=$(grep "95th percentile" "$result_file" | awk '{print $NF}')
    
    # Display detailed summary
    echo ""
    echo "Threads test summary:"
    echo "  Events/sec: $events_per_sec"
    echo "  Avg Latency: ${avg_latency}ms"
    echo "  P95 Latency: ${p95_latency}ms"
}
