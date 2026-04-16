# lib/io_test.sh - IO test module (supports sysbench fileio and fio)

run_io_test() {
    echo "=== IO Performance Test ==="
    
    local io_tool="${IO_TOOL:-sysbench}"
    
    if [ "$io_tool" = "fio" ]; then
        run_fio_test
    else
        run_sysbench_fileio
    fi
}

# sysbench fileio test
run_sysbench_fileio() {
    local temp_output_file="/tmp/vb_fileio_${TIMESTAMP}.txt"
    
    echo "Starting fileio test..."
    echo "  File size: ${IO_TOTAL_SIZE:-1G}, Test mode: ${IO_TEST_MODE:-rndrw}"
    
    # Prepare test files first
    sysbench fileio \
        --file-total-size="${IO_TOTAL_SIZE:-1G}" \
        --file-test-mode="${IO_TEST_MODE:-rndrw}" \
        --file-num="${IO_FILE_NUM:-1}" \
        prepare > /dev/null 2>&1
    
    # Run test
    sysbench fileio \
        --file-total-size="${IO_TOTAL_SIZE:-1G}" \
        --file-test-mode="${IO_TEST_MODE:-rndrw}" \
        --time="${IO_DURATION:-120}" \
        --file-num="${IO_FILE_NUM:-1}" \
        run > "$temp_output_file" 2>&1
    
    # Cleanup test files
    sysbench fileio \
        --file-total-size="${IO_TOTAL_SIZE:-1G}" \
        --file-test-mode="${IO_TEST_MODE:-rndrw}" \
        --file-num="${IO_FILE_NUM:-1}" \
        cleanup > /dev/null 2>&1
    
    # Parse result and display detailed output
    parse_sysbench_fileio_result "$temp_output_file"
    
    # Append to combined results file
    append_to_combined_result "SYSBENCH FILEIO TEST RESULTS" "$temp_output_file"
    
    # Cleanup temp file
    rm -f "$temp_output_file"
    
    echo "✓ IO test completed"
}

# fio test
run_fio_test() {
    echo "[fio] Starting test..."
    
    # Check if fio is installed
    if ! command -v fio &> /dev/null; then
        echo "Error: fio not installed, please run: sudo yum install -y fio"
        return 1
    fi
    
    # Iterate through all profiles
    local profiles="${FIO_PROFILES:-randread}"
    
    for profile in $profiles; do
        echo "  Executing profile: $profile"
        
        # Generate fio configuration
        local fio_conf="/tmp/fio_${profile}.fio"
        local rw_type=$(eval echo "\$FIO_${profile^^}_RW")
        local bs=$(eval echo "\$FIO_${profile^^}_BS")
        local iodepth=$(eval echo "\$FIO_${profile^^}_IODEPTH")
        local numjobs=$(eval echo "\$FIO_${profile^^}_NUMJOBS")
        
        # Set default values
        rw_type="${rw_type:-randread}"
        bs="${bs:-8K}"
        iodepth="${iodepth:-64}"
        numjobs="${numjobs:-4}"
        
        cat > "$fio_conf" << EOF
[global]
ioengine=libaio
direct=1
size=${IO_FILE_SIZE:-10G}
runtime=${IO_DURATION:-300}
time_based
group_reporting

[${profile}]
rw=${rw_type}
bs=${bs}
iodepth=${iodepth}
numjobs=${numjobs}
filename=${IO_TEST_PATH:-/tmp}/fio_test_${profile}
EOF
        
        # Run fio test
        local json_output="$OUTPUT_DIR/data/fio_${profile}_result.json"
        fio "$fio_conf" --output="$json_output" --output-format=json 2>/dev/null
        
        # Cleanup temporary files
        rm -f "$fio_conf"
        
        # Parse result
        parse_fio_result "$json_output" "$profile"
    done
    
    echo "✓ fio test completed"
}

# Parse sysbench fileio result
parse_sysbench_fileio_result() {
    local result_file="$1"
    
    # Extract metrics
    local read_iops=$(grep "reads/s:" "$result_file" 2>/dev/null | awk '{print $NF}' || echo "0")
    local write_iops=$(grep "writes/s:" "$result_file" 2>/dev/null | awk '{print $NF}' || echo "0")
    local total_iops=$(awk "BEGIN {printf \"%.2f\", $read_iops + $write_iops}")
    local read_bw=$(grep "read, MiB/s:" "$result_file" 2>/dev/null | awk '{print $NF}' || echo "0")
    local write_bw=$(grep "written, MiB/s:" "$result_file" 2>/dev/null | awk '{print $NF}' || echo "0")
    local total_bw=$(awk "BEGIN {printf \"%.2f\", $read_bw + $write_bw}")
    local avg_latency=$(grep "avg:" "$result_file" 2>/dev/null | head -1 | awk '{print $NF}' | tr -d ',' || echo "0")
    
    # Display summary
    echo ""
    echo "IO test results:"
    echo "  Read IOPS: $read_iops"
    echo "  Write IOPS: $write_iops"
    echo "  Total IOPS: $total_iops"
    echo "  Read BW: ${read_bw}MB/s"
    echo "  Write BW: ${write_bw}MB/s"
    echo "  Total BW: ${total_bw}MB/s"
    echo "  Avg Latency: ${avg_latency}ms"
}

# Parse fio result
parse_fio_result() {
    local json_file="$1"
    local profile="$2"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "  ⚠ jq not installed, skipping detailed parsing"
        return
    fi
    
    if [ ! -f "$json_file" ]; then
        echo "  ⚠ Result file not found: $json_file"
        return
    fi
    
    # Extract metrics
    local read_iops=$(jq -r '.jobs[0].read.iops // 0' "$json_file" 2>/dev/null)
    local write_iops=$(jq -r '.jobs[0].write.iops // 0' "$json_file" 2>/dev/null)
    local read_bw=$(jq -r '.jobs[0].read.bw_bytes // 0' "$json_file" 2>/dev/null)
    local write_bw=$(jq -r '.jobs[0].write.bw_bytes // 0' "$json_file" 2>/dev/null)
    local read_lat_p50=$(jq -r '.jobs[0].read.lat_ns.percentile."50.000000" // 0' "$json_file" 2>/dev/null)
    local read_lat_p95=$(jq -r '.jobs[0].read.lat_ns.percentile."95.000000" // 0' "$json_file" 2>/dev/null)
    local read_lat_p99=$(jq -r '.jobs[0].read.lat_ns.percentile."99.000000" // 0' "$json_file" 2>/dev/null)
    local write_lat_p50=$(jq -r '.jobs[0].write.lat_ns.percentile."50.000000" // 0' "$json_file" 2>/dev/null)
    local write_lat_p95=$(jq -r '.jobs[0].write.lat_ns.percentile."95.000000" // 0' "$json_file" 2>/dev/null)
    local write_lat_p99=$(jq -r '.jobs[0].write.lat_ns.percentile."99.000000" // 0' "$json_file" 2>/dev/null)
    
    # Save metrics (uppercase profile name as prefix)
    local prefix="FIO_${profile^^}"
    echo "${prefix}_READ_IOPS=${read_iops}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_WRITE_IOPS=${write_iops}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_READ_BW_BPS=${read_bw}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_WRITE_BW_BPS=${write_bw}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_READ_LAT_P50_NS=${read_lat_p50}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_READ_LAT_P95_NS=${read_lat_p95}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_READ_LAT_P99_NS=${read_lat_p99}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_WRITE_LAT_P50_NS=${write_lat_p50}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_WRITE_LAT_P95_NS=${write_lat_p95}" >> "$OUTPUT_DIR/data/metrics.env"
    echo "${prefix}_WRITE_LAT_P99_NS=${write_lat_p99}" >> "$OUTPUT_DIR/data/metrics.env"
    
    # Display summary
    echo ""
    echo "  fio [$profile] test results:"
    echo "    Read IOPS: $read_iops"
    echo "    Write IOPS: $write_iops"
    echo "    Read BW: $((read_bw / 1024 / 1024))MB/s"
    echo "    Write BW: $((write_bw / 1024 / 1024))MB/s"
    echo "    Read P95 Latency: ${read_lat_p95}ns"
    echo "    Write P95 Latency: ${write_lat_p95}ns"
}
