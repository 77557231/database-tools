# lib/report.sh - 报告生成模块

generate_report() {
    local report_file="$OUTPUT_DIR/report_benchmark_${TIMESTAMP}.txt"
    local combined_file="$OUTPUT_DIR/data_${TIMESTAMP}_all_results.txt"
    
    # Get system info
    local cpu_cores=$(get_cpu_cores 2>/dev/null || echo "N/A")
    local memory_mb=$(get_memory_size_mb 2>/dev/null || echo "N/A")
    
    # Generate report
    cat > "$report_file" << EOF
================================================================================
                    Vastbase System Benchmark Report
================================================================================

Basic Information
-----------------
Test Mode: $MODE
Test Time: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: ${HOSTNAME:-N/A}
CPU Cores: ${cpu_cores}
Memory Size: ${memory_mb} MB

================================================================================
                           Test Configuration
================================================================================

[CPU Test]
  Threads: $(if [ "${CPU_THREADS:-0}" = "0" ]; then echo "auto ($(nproc 2>/dev/null || echo 'N/A'))"; else echo "${CPU_THREADS}"; fi)
  Duration: ${CPU_DURATION:-60}s
  Max Prime: ${CPU_MAX_PRIME:-20000}

[Memory Test]
  Block Size: ${MEMORY_BLOCK_SIZE:-1M}
  Total Size: ${MEMORY_TOTAL_SIZE:-10G}
  Operation: ${MEMORY_OPER:-read}
  Duration: ${MEMORY_DURATION:-60}s

[IO Test]
  Tool: ${IO_TOOL:-sysbench}
  File Size: ${IO_TOTAL_SIZE:-1G}
  Test Mode: ${IO_TEST_MODE:-rndrw}
  File Num: ${IO_FILE_NUM:-1}
  Duration: ${IO_DURATION:-120}s

[Threads Test]
  Threads: ${THREADS_NUM:-1000}
  Duration: ${THREADS_DURATION:-60}s
  Yields: ${THREAD_YIELDS:-100}
  Locks: ${THREAD_LOCKS:-4}

[Mutex Test]
  Threads: ${MUTEX_THREADS:-1000}
  Duration: ${MUTEX_DURATION:-60}s
  Mutex Num: ${MUTEX_NUM:-1024}

[Network Test]
  Enabled: ${NETWORK_ENABLED:-false}
  Tool: ${NETWORK_TOOL:-iperf3}
  Server: ${NETWORK_SERVER_IP:-N/A}
  Port: ${NETWORK_PORT:-5201}
  Duration: ${NETWORK_DURATION:-10}s
  Parallel: ${NETWORK_PARALLEL:-4}

================================================================================
                           Test Results Summary
================================================================================

[CPU Test]
EOF

    # Parse CPU results from combined file
    if [ -f "$combined_file" ]; then
        local cpu_events=$(grep -A1 "CPU speed:" "$combined_file" 2>/dev/null | grep "events per second" | awk '{print $NF}')
        local cpu_avg_lat=$(grep -A30 "CPU TEST RESULTS" "$combined_file" 2>/dev/null | grep -A5 "Latency (ms):" | grep "avg:" | awk '{print $NF}')
        local cpu_p95_lat=$(grep -A30 "CPU TEST RESULTS" "$combined_file" 2>/dev/null | grep "95th percentile" | awk '{print $NF}')
        local cpu_p99_lat=$(grep -A30 "CPU TEST RESULTS" "$combined_file" 2>/dev/null | grep "99th percentile" | awk '{print $NF}')
        local cpu_threads_fairness_events=$(grep -A50 "CPU TEST RESULTS" "$combined_file" 2>/dev/null | grep "Threads fairness:" -A2 | grep "events" | head -1)
        local cpu_threads_fairness_time=$(grep -A50 "CPU TEST RESULTS" "$combined_file" 2>/dev/null | grep "Threads fairness:" -A2 | grep "execution time" | head -1)
        
        if [ -n "$cpu_events" ]; then
            cat >> "$report_file" << EOF
  CPU speed:
    events per second: ${cpu_events}
  Avg Latency:   ${cpu_avg_lat:-0} ms
  P95 Latency:   ${cpu_p95_lat:-0} ms
EOF
            if [ -n "$cpu_p99_lat" ] && [ "$cpu_p99_lat" != "0" ]; then
                echo "  P99 Latency:   ${cpu_p99_lat} ms" >> "$report_file"
            fi
            if [ -n "$cpu_threads_fairness_events" ] || [ -n "$cpu_threads_fairness_time" ]; then
                echo "  Threads fairness:" >> "$report_file"
                if [ -n "$cpu_threads_fairness_events" ]; then
                    echo "    ${cpu_threads_fairness_events}" >> "$report_file"
                fi
                if [ -n "$cpu_threads_fairness_time" ]; then
                    echo "    ${cpu_threads_fairness_time}" >> "$report_file"
                fi
            fi
        else
            echo "  Test not executed" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

[Memory Test]
EOF

    if [ -f "$combined_file" ]; then
        # Extract total operations and per second from the output
        local mem_total_ops_line=$(grep "Total operations:" "$combined_file" 2>/dev/null)
        local mem_total_ops=$(echo "$mem_total_ops_line" | awk '{print $3}')
        local mem_ops_sec=$(echo "$mem_total_ops_line" | awk -F'[()]' '{print $2}' | awk '{print $1}')
        local mem_transferred=$(grep "MiB transferred" "$combined_file" 2>/dev/null | awk '{print $1}')
        local mem_mib_sec=$(grep "MiB transferred" "$combined_file" 2>/dev/null | awk -F'[()]' '{print $2}' | awk '{print $1}')
        local mem_avg_lat=$(grep -A30 "MEMORY TEST RESULTS" "$combined_file" 2>/dev/null | grep -A5 "Latency (ms):" | grep "avg:" | awk '{print $NF}')
        local mem_p95_lat=$(grep -A30 "MEMORY TEST RESULTS" "$combined_file" 2>/dev/null | grep "95th percentile" | awk '{print $NF}')
        
        if [ -n "$mem_total_ops" ]; then
            cat >> "$report_file" << EOF
  Total operations: ${mem_total_ops} (${mem_ops_sec} per second)
  Transferred:      ${mem_transferred} MiB (${mem_mib_sec} MiB/sec)
  Avg Latency:      ${mem_avg_lat:-0} ms
  P95 Latency:      ${mem_p95_lat:-0} ms
EOF
        else
            echo "  Test not executed" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

[IO Test]
EOF

    if [ -f "$combined_file" ]; then
        local io_read_iops=$(grep "reads/s:" "$combined_file" 2>/dev/null | awk '{print $NF}')
        local io_write_iops=$(grep "writes/s:" "$combined_file" 2>/dev/null | awk '{print $NF}')
        local io_read_bw=$(grep "read, MiB/s:" "$combined_file" 2>/dev/null | awk '{print $NF}')
        local io_write_bw=$(grep "written, MiB/s:" "$combined_file" 2>/dev/null | awk '{print $NF}')
        local io_avg_lat=$(grep "avg:" "$combined_file" 2>/dev/null | tail -1 | awk '{print $NF}' | tr -d ',')
        
        if [ -n "$io_read_iops" ]; then
            local io_total_iops=$(awk "BEGIN {printf \"%.2f\", $io_read_iops + $io_write_iops}")
            local io_total_bw=$(awk "BEGIN {printf \"%.2f\", $io_read_bw + $io_write_bw}")
            
            cat >> "$report_file" << EOF
  Read IOPS:        ${io_read_iops}
  Write IOPS:       ${io_write_iops}
  Total IOPS:       ${io_total_iops}
  Read BW:          ${io_read_bw} MB/s
  Write BW:         ${io_write_bw} MB/s
  Total BW:         ${io_total_bw} MB/s
  Avg Latency:      ${io_avg_lat:-0} ms
EOF
        else
            echo "  Test not executed" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

[Threads Test]
EOF

    if [ -f "$combined_file" ]; then
        local threads_events=$(grep -A30 "THREADS TEST RESULTS" "$combined_file" 2>/dev/null | grep "total number of events:" | awk '{print $NF}')
        local threads_time=$(grep -A30 "THREADS TEST RESULTS" "$combined_file" 2>/dev/null | grep "total time:" | awk '{print $NF}' | tr -d 's')
        local threads_avg_lat=$(grep -A30 "THREADS TEST RESULTS" "$combined_file" 2>/dev/null | grep -A5 "Latency (ms):" | grep "avg:" | awk '{print $NF}')
        local threads_p95_lat=$(grep -A30 "THREADS TEST RESULTS" "$combined_file" 2>/dev/null | grep "95th percentile" | awk '{print $NF}')
        
        if [ -n "$threads_events" ]; then
            local threads_eps=$(awk "BEGIN {printf \"%.2f\", $threads_events / ${threads_time:-1}}")
            
            cat >> "$report_file" << EOF
  Events/sec:     ${threads_eps}
  Avg Latency:    ${threads_avg_lat:-0} ms
  P95 Latency:    ${threads_p95_lat:-0} ms
EOF
        else
            echo "  Test not executed" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

[Mutex Test]
EOF

    if [ -f "$combined_file" ]; then
        local mutex_events=$(grep -A30 "MUTEX TEST RESULTS" "$combined_file" 2>/dev/null | grep "total number of events:" | awk '{print $NF}')
        local mutex_time=$(grep -A30 "MUTEX TEST RESULTS" "$combined_file" 2>/dev/null | grep "total time:" | awk '{print $NF}' | tr -d 's')
        local mutex_avg_lat=$(grep -A30 "MUTEX TEST RESULTS" "$combined_file" 2>/dev/null | grep -A5 "Latency (ms):" | grep "avg:" | awk '{print $NF}')
        local mutex_p95_lat=$(grep -A30 "MUTEX TEST RESULTS" "$combined_file" 2>/dev/null | grep "95th percentile" | awk '{print $NF}')
        
        if [ -n "$mutex_events" ]; then
            local mutex_tps=$(awk "BEGIN {printf \"%.2f\", $mutex_events / ${mutex_time:-1}}")
            
            cat >> "$report_file" << EOF
  Transactions:   ${mutex_events}
  TPS:            ${mutex_tps}
  Avg Latency:    ${mutex_avg_lat:-0} ms
  P95 Latency:    ${mutex_p95_lat:-0} ms
EOF
        else
            echo "  Test not executed" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

[Network Test]
EOF

    if [ -f "$combined_file" ]; then
        # Check if network test results exist
        if grep -q "NETWORK TEST RESULTS" "$combined_file" 2>/dev/null; then
            # Extract all network test results for each client
            local found_results=false
            
            # Get the output directory from the combined file path
            local output_dir=$(dirname "$combined_file")
            
            # Get all network test scenarios
            local scenario_count=$(grep -c "NETWORK TEST RESULTS" "$combined_file")
            
            # Process each scenario
            local i=1
            while [ $i -le $scenario_count ]; do
                # Find the corresponding JSON file
                local json_file="$output_dir/data/network_scenario_${i}.json"
                local net_bw="0"
                local client_ip="N/A"
                
                if [ -f "$json_file" ]; then
                    # Check if jq is installed
                    if command -v jq &> /dev/null; then
                        # Extract bandwidth from JSON file
                        local bandwidth_bps=$(jq -r '.end.sum_received.bits_per_second // 0' "$json_file" 2>/dev/null)
                        # Convert bps to MB/s: 1 MB/s = 8,000,000 bps
                        net_bw=$(awk "BEGIN {printf \"%.2f\", $bandwidth_bps / 8000000}" 2>/dev/null || echo "0")
                        
                        # Extract client IP from the JSON file if available
                        local local_ip=$(jq -r '.start.connected[0].local_host // ""' "$json_file" 2>/dev/null)
                        if [ -n "$local_ip" ]; then
                            client_ip="$local_ip"
                        fi
                    fi
                fi
                
                # Display result with client IP
                echo "  Client: ${client_ip}" >> "$report_file"
                echo "  Bandwidth:      ${net_bw} MB/s" >> "$report_file"
                echo "" >> "$report_file"
                
                found_results=true
                i=$((i + 1))
            done
            
            if [ "$found_results" = false ]; then
                echo "  Test executed but no results parsed" >> "$report_file"
            fi
        else
            echo "  Test not executed or failed" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

================================================================================
                           End of Report
================================================================================
Report Generated: $(date)
================================================================================
EOF
}
