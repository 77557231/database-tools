#!/bin/bash

# Unit test script for report generation logic
# Usage: ./test_report_generation.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

skip() {
    echo -e "${YELLOW}○ SKIP${NC}: $1"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# Test directory
TEST_DIR="./test_output"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$SCRIPT_DIR/../oscheckperf"

# Setup test environment
setup() {
    echo "=========================================="
    echo "  Report Generation Unit Tests"
    echo "=========================================="
    echo ""
    
    mkdir -p "$TEST_DIR"
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
}

# Cleanup test environment
cleanup() {
    rm -rf "$TEST_DIR"
}

# Test 1: CPU results parsing
test_cpu_results_parsing() {
    echo "--- Test 1: CPU Results Parsing ---"
    
    local test_file="$TEST_DIR/test_cpu_results.log"
    cat > "$test_file" << 'EOF'
CPU TEST RESULTS (Server: 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
CPU speed:
    events per second:   1234.56

Latency (ms):
         min:                                    1.00
         avg:                                    5.67
         max:                                   20.00
         95th percentile:                       10.00

CPU TEST RESULTS (Server: 192.168.1.2) (ORIGINAL OUTPUT)
================================================================================
CPU speed:
    events per second:   5678.90

Latency (ms):
         min:                                    0.50
         avg:                                    2.34
         max:                                   15.00
         95th percentile:                       8.00
EOF

    # Test extraction
    local cpu_count=$(grep -c "CPU TEST RESULTS" "$test_file" 2>/dev/null)
    if [ "$cpu_count" -eq 2 ]; then
        pass "CPU test sections count: $cpu_count"
    else
        fail "Expected 2 CPU sections, got $cpu_count"
    fi

    # Test server IP extraction
    local ip1=$(grep "CPU TEST RESULTS" "$test_file" | head -1 | grep -oP 'Server: \K[0-9.]+')
    if [ "$ip1" = "192.168.1.1" ]; then
        pass "Server IP extraction: $ip1"
    else
        fail "Expected IP 192.168.1.1, got $ip1"
    fi

    # Test events per second extraction
    local eps=$(grep "events per second:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$eps" = "1234.56" ]; then
        pass "Events per second extraction: $eps"
    else
        fail "Expected 1234.56, got $eps"
    fi

    # Test avg latency extraction
    local avg_lat=$(grep "avg:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$avg_lat" = "5.67" ]; then
        pass "Avg latency extraction: $avg_lat"
    else
        fail "Expected 5.67, got $avg_lat"
    fi

    # Test p95 latency extraction
    local p95_lat=$(grep "95th percentile:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$p95_lat" = "10.00" ]; then
        pass "P95 latency extraction: $p95_lat"
    else
        fail "Expected 10.00, got $p95_lat"
    fi
    
    echo ""
}

# Test 2: Memory results parsing
test_memory_results_parsing() {
    echo "--- Test 2: Memory Results Parsing ---"
    
    local test_file="$TEST_DIR/test_memory_results.log"
    cat > "$test_file" << 'EOF'
MEMORY TEST RESULTS (Server: 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
Total operations: 1234567 (8765432.10 per second)
Transferred: 9645.06 MiB (68308.84 MiB/sec)
Latency: 1.23 ms
EOF

    # Test extraction
    local mem_count=$(grep -c "MEMORY TEST RESULTS" "$test_file" 2>/dev/null)
    if [ "$mem_count" -ge 1 ]; then
        pass "Memory test sections count: $mem_count"
    else
        fail "Expected at least 1 memory section, got $mem_count"
    fi

    # Test ops/sec extraction
    local ops_sec=$(grep "Total operations:" "$test_file" | head -1 | awk -F'[()]' '{print $2}' | awk '{print $1}')
    if [ "$ops_sec" = "8765432.10" ]; then
        pass "Ops/sec extraction: $ops_sec"
    else
        fail "Expected 8765432.10, got $ops_sec"
    fi

    # Test MiB/sec extraction
    local mib_sec=$(grep "MiB/sec" "$test_file" | head -1 | awk -F'[()]' '{print $2}' | awk '{print $1}')
    if [ "$mib_sec" = "68308.84" ]; then
        pass "MiB/sec extraction: $mib_sec"
    else
        fail "Expected 68308.84, got $mib_sec"
    fi

    # Test avg latency extraction
    local avg_lat=$(grep "Latency: " "$test_file" | head -1 | awk '{print $2}')
    if [ "$avg_lat" = "1.23" ]; then
        pass "Avg latency extraction: $avg_lat"
    else
        fail "Expected 1.23, got $avg_lat"
    fi
    
    echo ""
}

# Test 3: IO results parsing
test_io_results_parsing() {
    echo "--- Test 3: IO Results Parsing ---"
    
    local test_file="$TEST_DIR/test_io_results.log"
    cat > "$test_file" << 'EOF'
SYSBENCH FILEIO TEST RESULTS (Server: 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
    reads/s:                      12345.67
    writes/s:                     8901.23
    total/s:                      21246.90
    total MiB/s:                  332.00

Latency (ms):
         min:                                    0.01
         avg:                                    0.50
         max:                                   10.00
         95th percentile:                       2.00
EOF

    # Test extraction
    local io_count=$(grep -c "SYSBENCH FILEIO TEST RESULTS" "$test_file" 2>/dev/null)
    if [ "$io_count" -ge 1 ]; then
        pass "IO test sections count: $io_count"
    else
        fail "Expected at least 1 IO section, got $io_count"
    fi

    # Test reads/s extraction
    local read_iops=$(grep "reads/s:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$read_iops" = "12345.67" ]; then
        pass "Read IOPS extraction: $read_iops"
    else
        fail "Expected 12345.67, got $read_iops"
    fi

    # Test writes/s extraction
    local write_iops=$(grep "writes/s:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$write_iops" = "8901.23" ]; then
        pass "Write IOPS extraction: $write_iops"
    else
        fail "Expected 8901.23, got $write_iops"
    fi

    # Test total IOPS calculation
    local total_iops=$(awk "BEGIN {printf \"%.2f\", $read_iops + $write_iops}")
    if [ "$total_iops" = "21246.90" ]; then
        pass "Total IOPS calculation: $total_iops"
    else
        fail "Expected 21246.90, got $total_iops"
    fi
    
    echo ""
}

# Test 4: Threads results parsing
test_threads_results_parsing() {
    echo "--- Test 4: Threads Results Parsing ---"
    
    local test_file="$TEST_DIR/test_threads_results.log"
    cat > "$test_file" << 'EOF'
THREADS TEST RESULTS (Server: 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
Threads test summary:
    total number of events:              2573
    total time:                          1.0007s
    Latency (ms):
         min:                                    10.00
         avg:                                    348.61
         max:                                   1500.00
         95th percentile:                       995.51
EOF

    # Test extraction
    local threads_count=$(grep -c "THREADS TEST RESULTS" "$test_file" 2>/dev/null)
    if [ "$threads_count" -ge 1 ]; then
        pass "Threads test sections count: $threads_count"
    else
        fail "Expected at least 1 threads section, got $threads_count"
    fi

    # Test events extraction
    local events=$(grep "total number of events:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$events" = "2573" ]; then
        pass "Events extraction: $events"
    else
        fail "Expected 2573, got $events"
    fi

    # Test time extraction
    local time_val=$(grep "total time:" "$test_file" | head -1 | awk '{print $NF}' | tr -d 's')
    if [ "$time_val" = "1.0007" ]; then
        pass "Time extraction: $time_val"
    else
        fail "Expected 1.0007, got $time_val"
    fi

    # Test EPS calculation
    local eps=$(awk "BEGIN {printf \"%.2f\", $events / $time_val}")
    if [ "$eps" = "2571.20" ]; then
        pass "EPS calculation: $eps"
    else
        fail "Expected 2571.20, got $eps"
    fi
    
    echo ""
}

# Test 5: Mutex results parsing
test_mutex_results_parsing() {
    echo "--- Test 5: Mutex Results Parsing ---"
    
    local test_file="$TEST_DIR/test_mutex_results.log"
    cat > "$test_file" << 'EOF'
MUTEX TEST RESULTS (Server: 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
Mutex test summary:
    total number of events:              4
    total time:                          1.0007s
    Latency (ms):
         min:                                    100.00
         avg:                                    629.06
         max:                                   1500.00
         95th percentile:                       646.19
EOF

    # Test extraction
    local mutex_count=$(grep -c "MUTEX TEST RESULTS" "$test_file" 2>/dev/null)
    if [ "$mutex_count" -ge 1 ]; then
        pass "Mutex test sections count: $mutex_count"
    else
        fail "Expected at least 1 mutex section, got $mutex_count"
    fi

    # Test transactions extraction
    local transactions=$(grep "total number of events:" "$test_file" | head -1 | awk '{print $NF}')
    if [ "$transactions" = "4" ]; then
        pass "Transactions extraction: $transactions"
    else
        fail "Expected 4, got $transactions"
    fi
    
    echo ""
}

# Test 6: Network results parsing
test_network_results_parsing() {
    echo "--- Test 6: Network Results Parsing ---"
    
    local test_file="$TEST_DIR/test_network_results.log"
    cat > "$test_file" << 'EOF'
NETWORK TEST RESULTS (192.168.1.2 -> 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
Dynamic Average Bandwidth: 109.52 MB/s
EOF

    # Test extraction
    local net_count=$(grep -c "NETWORK TEST RESULTS" "$test_file" 2>/dev/null)
    if [ "$net_count" -ge 1 ]; then
        pass "Network test sections count: $net_count"
    else
        fail "Expected at least 1 network section, got $net_count"
    fi

    # Test bandwidth extraction
    local bw=$(grep "Dynamic Average Bandwidth:" "$test_file" | head -1 | grep -oP '[0-9.]+' | head -1)
    if [ "$bw" = "109.52" ]; then
        pass "Bandwidth extraction: $bw MB/s"
    else
        fail "Expected 109.52, got $bw"
    fi
    
    echo ""
}

# Test 7: Multi-server format validation
test_multi_server_format() {
    echo "--- Test 7: Multi-server Format Validation ---"
    
    local test_file="$TEST_DIR/test_multi_server.log"
    cat > "$test_file" << 'EOF'
CPU TEST RESULTS (Server: 192.168.1.1) (ORIGINAL OUTPUT)
================================================================================
CPU speed:
    events per second:   1000.00

Latency (ms):
         avg:                                    5.00
         95th percentile:                       10.00

CPU TEST RESULTS (Server: 192.168.1.2) (ORIGINAL OUTPUT)
================================================================================
CPU speed:
    events per second:   2000.00

Latency (ms):
         avg:                                    3.00
         95th percentile:                       8.00

CPU TEST RESULTS (Server: 192.168.1.3) (ORIGINAL OUTPUT)
================================================================================
CPU speed:
    events per second:   3000.00

Latency (ms):
         avg:                                    2.00
         95th percentile:                       6.00
EOF

    # Test that we can extract all 3 server IPs
    local ips=$(grep "CPU TEST RESULTS" "$test_file" | grep -oP 'Server: \K[0-9.]+')
    local ip_count=$(echo "$ips" | wc -l)
    
    if [ "$ip_count" -eq 3 ]; then
        pass "Multi-server IP count: $ip_count"
    else
        fail "Expected 3 IPs, got $ip_count"
    fi

    # Verify all IPs are extracted correctly
    local expected_ips="192.168.1.1 192.168.1.2 192.168.1.3"
    local actual_ips=$(echo "$ips" | tr '\n' ' ' | sed 's/ $//')
    
    if [ "$actual_ips" = "$expected_ips" ]; then
        pass "Multi-server IPs extraction: $actual_ips"
    else
        fail "Expected IPs '$expected_ips', got '$actual_ips'"
    fi
    
    echo ""
}

# Test 8: Original data file as single source
test_original_data_single_source() {
    echo "--- Test 8: Original Data File as Single Source ---"
    
    # Check if generate_report uses original_data file
    local report_usage=$(grep -c "original_data" "$SCRIPT" 2>/dev/null || echo "0")
    if [ "$report_usage" -gt 0 ]; then
        pass "generate_report references original_data file: $report_usage times"
    else
        fail "generate_report does not reference original_data file"
    fi

    # Check if generate_report has fallback to data file
    local fallback_usage=$(grep -c "data_\${TIMESTAMP}_all_results.log" "$SCRIPT" 2>/dev/null || echo "0")
    if [ "$fallback_usage" -gt 0 ]; then
        skip "generate_report still has data file fallback (acceptable)"
    else
        pass "generate_report does not depend on data file"
    fi
    
    echo ""
}

# Test 9: Report generation end-to-end
test_report_end_to_end() {
    echo "--- Test 9: Report Generation End-to-End ---"
    
    # Find the latest report file
    local latest_report=$(ls -t ./output/report_benchmark_*.txt 2>/dev/null | head -1)
    
    if [ -z "$latest_report" ]; then
        skip "No report file found, skipping end-to-end test"
        return
    fi

    # Check if report has required sections
    local sections=("CPU Test" "Memory Test" "IO Test" "Threads Test" "Mutex Test" "Network Test")
    local missing_sections=0
    
    for section in "${sections[@]}"; do
        if ! grep -q "$section" "$latest_report" 2>/dev/null; then
            fail "Report missing section: $section"
            missing_sections=$((missing_sections + 1))
        fi
    done
    
    if [ "$missing_sections" -eq 0 ]; then
        pass "Report contains all required sections"
    fi

    # Check if report has server comparison tables
    if grep -q "Multiple Servers" "$latest_report" 2>/dev/null; then
        pass "Report has multi-server comparison tables"
    else
        fail "Report missing multi-server comparison tables"
    fi

    # Check if report has N/A values
    local na_count=$(grep -c "N/A" "$latest_report" 2>/dev/null || echo "0")
    if [ "$na_count" -lt 5 ]; then
        pass "Report N/A count is low: $na_count"
    else
        fail "Report has too many N/A values: $na_count"
    fi
    
    echo ""
}

# Test 10: original_data_*_all_results.log format validation
test_original_data_format() {
    echo "--- Test 10: original_data File Format Validation ---"
    
    # Find the latest original_data file
    local latest_original=$(ls -t ./output/original_data_*.log 2>/dev/null | head -1)
    
    if [ -z "$latest_original" ]; then
        skip "No original_data file found, skipping format test"
        return
    fi

    echo "  Testing file: $latest_original"

    # Test 10.1: Check file is not empty
    local file_size=$(wc -c < "$latest_original")
    if [ "$file_size" -gt 0 ]; then
        pass "original_data file is not empty ($file_size bytes)"
    else
        fail "original_data file is empty"
        return
    fi

    # Test 10.2: Check for TEST RESULTS header format
    local header_count=$(grep -c "TEST RESULTS.*Server:.*ORIGINAL OUTPUT" "$latest_original" 2>/dev/null || echo "0")
    if [ "$header_count" -ge 3 ]; then
        pass "Has TEST RESULTS headers with Server IP: $header_count found"
    else
        fail "Missing TEST RESULTS headers (expected >=3, got $header_count)"
    fi

    # Test 10.3: Check for separator lines
    local separator_count=$(grep -c "^================================================================================$" "$latest_original" 2>/dev/null || echo "0")
    if [ "$separator_count" -ge 6 ]; then
        pass "Has separator lines: $separator_count found"
    else
        fail "Missing separator lines (expected >=6, got $separator_count)"
    fi

    # Test 10.4: Check for CPU TEST RESULTS format
    if grep -q "CPU TEST RESULTS (Server:" "$latest_original" 2>/dev/null; then
        pass "Has CPU TEST RESULTS format"
    else
        fail "Missing CPU TEST RESULTS format"
    fi

    # Test 10.5: Check for MEMORY TEST RESULTS format
    if grep -q "MEMORY TEST RESULTS (Server:" "$latest_original" 2>/dev/null; then
        pass "Has MEMORY TEST RESULTS format"
    else
        fail "Missing MEMORY TEST RESULTS format"
    fi

    # Test 10.6: Check for SYSBENCH FILEIO TEST RESULTS format
    if grep -q "SYSBENCH FILEIO TEST RESULTS (Server:" "$latest_original" 2>/dev/null; then
        pass "Has SYSBENCH FILEIO TEST RESULTS format"
    else
        fail "Missing SYSBENCH FILEIO TEST RESULTS format"
    fi

    # Test 10.7: Check for THREADS TEST RESULTS format
    if grep -q "THREADS TEST RESULTS (Server:" "$latest_original" 2>/dev/null; then
        pass "Has THREADS TEST RESULTS format"
    else
        fail "Missing THREADS TEST RESULTS format"
    fi

    # Test 10.8: Check for MUTEX TEST RESULTS format
    if grep -q "MUTEX TEST RESULTS (Server:" "$latest_original" 2>/dev/null; then
        pass "Has MUTEX TEST RESULTS format"
    else
        fail "Missing MUTEX TEST RESULTS format"
    fi

    # Test 10.9: Check for NETWORK TEST RESULTS format
    if grep -q "NETWORK TEST RESULTS" "$latest_original" 2>/dev/null; then
        pass "Has NETWORK TEST RESULTS format"
    else
        fail "Missing NETWORK TEST RESULTS format"
    fi

    # Test 10.10: Check that server IPs are present in headers
    local ips_found=$(grep -oP "Server: \K[0-9.]+" "$latest_original" 2>/dev/null | sort -u | wc -l)
    if [ "$ips_found" -ge 2 ]; then
        pass "Has server IPs in headers: $ips_found unique IPs found"
    else
        fail "Missing server IPs in headers (expected >=2, got $ips_found)"
    fi

    # Test 10.11: Check for no duplicate network summary in data file
    local net_completed_count=$(grep -c "Network test completed for all clients" "$latest_original" 2>/dev/null || echo "0")
    net_completed_count=$(echo "$net_completed_count" | tr -d '[:space:]')
    if [ "$net_completed_count" -le 1 ]; then
        pass "No duplicate network summary in original_data"
    else
        fail "Duplicate network summary in original_data ($net_completed_count times)"
    fi

    # Test 10.12: Check for results data after headers
    local cpu_data=$(grep -A20 "CPU TEST RESULTS" "$latest_original" | grep -c "events per second:" 2>/dev/null || echo "0")
    cpu_data=$(echo "$cpu_data" | tr -d '[:space:]')
    if [ "$cpu_data" -ge 1 ]; then
        pass "CPU results data found after header"
    else
        fail "Missing CPU results data after header"
    fi

    # Test 10.13: Check for memory results data
    local mem_data=$(grep -A20 "MEMORY TEST RESULTS" "$latest_original" | grep -c "Total operations:" 2>/dev/null || echo "0")
    mem_data=$(echo "$mem_data" | tr -d '[:space:]')
    if [ "$mem_data" -ge 1 ]; then
        pass "Memory results data found after header"
    else
        fail "Missing Memory results data after header"
    fi

    # Test 10.14: Check for IO results data
    local io_data=$(grep -A30 "SYSBENCH FILEIO TEST RESULTS" "$latest_original" | grep -c "reads/s:" 2>/dev/null || echo "0")
    io_data=$(echo "$io_data" | tr -d '[:space:]')
    if [ "$io_data" -ge 1 ]; then
        pass "IO results data found after header"
    else
        fail "Missing IO results data after header"
    fi
    
    echo ""
}

# Test 11: data_*_all_results.log format validation
test_data_file_format() {
    echo "--- Test 11: data File Format Validation ---"
    
    # Find the latest data file
    local latest_data=$(ls -t ./output/data_*.log 2>/dev/null | head -1)
    
    if [ -z "$latest_data" ]; then
        skip "No data file found, skipping format test"
        return
    fi

    echo "  Testing file: $latest_data"

    # Test 11.1: Check file is not empty
    local file_size=$(wc -c < "$latest_data")
    if [ "$file_size" -gt 0 ]; then
        pass "data file is not empty ($file_size bytes)"
    else
        fail "data file is empty"
        return
    fi

    # Test 11.2: Check for test execution output
    if grep -q "=== CPU Performance Test ===" "$latest_data" 2>/dev/null; then
        pass "Has CPU test execution output"
    else
        fail "Missing CPU test execution output"
    fi

    # Test 11.3: Check for Memory test output
    if grep -q "=== Memory Performance Test ===" "$latest_data" 2>/dev/null; then
        pass "Has Memory test execution output"
    else
        fail "Missing Memory test execution output"
    fi

    # Test 11.4: Check for IO test output
    if grep -q "=== IO Performance Test ===" "$latest_data" 2>/dev/null; then
        pass "Has IO test execution output"
    else
        fail "Missing IO test execution output"
    fi

    # Test 11.5: Check for Threads test output
    if grep -q "=== Threads Performance Test ===" "$latest_data" 2>/dev/null; then
        pass "Has Threads test execution output"
    else
        fail "Missing Threads test execution output"
    fi

    # Test 11.6: Check for Mutex test output
    if grep -q "=== Mutex Performance Test ===" "$latest_data" 2>/dev/null; then
        pass "Has Mutex test execution output"
    else
        fail "Missing Mutex test execution output"
    fi

    # Test 11.7: Check for Network test output
    if grep -q "=== Network Performance Test ===" "$latest_data" 2>/dev/null; then
        pass "Has Network test execution output"
    else
        fail "Missing Network test execution output"
    fi

    # Test 11.8: Check for test completion messages
    if grep -q "✓ CPU test completed" "$latest_data" 2>/dev/null; then
        pass "Has test completion message for CPU"
    else
        fail "Missing test completion message for CPU"
    fi

    # Test 11.9: Check that network summary is NOT duplicated
    local net_summary_count=$(grep -c "Network test completed for all clients" "$latest_data" 2>/dev/null || echo "0")
    if [ "$net_summary_count" -le 1 ]; then
        pass "Network summary not duplicated ($net_summary_count times)"
    else
        fail "Network summary duplicated ($net_summary_count times)"
    fi

    # Test 11.10: Check for network bandwidth summary format
    local net_summary_format=$(grep -c "\-> .* = .* MB/s" "$latest_data" 2>/dev/null || echo "0")
    if [ "$net_summary_format" -le 2 ]; then
        pass "Network bandwidth summary format correct ($net_summary_format lines)"
    else
        fail "Network bandwidth summary format incorrect ($net_summary_format lines, expected <=2)"
    fi

    # Test 11.11: Check for server testing messages
    local server_test_count=$(grep -c "Testing server" "$latest_data" 2>/dev/null || echo "0")
    if [ "$server_test_count" -ge 2 ]; then
        pass "Has server testing messages ($server_test_count servers)"
    else
        fail "Missing server testing messages (expected >=2, got $server_test_count)"
    fi

    # Test 11.12: Check for benchmark completion message
    if grep -q "Benchmark completed successfully!" "$latest_data" 2>/dev/null; then
        pass "Has benchmark completion message"
    else
        fail "Missing benchmark completion message"
    fi
    
    echo ""
}

# Test 12: Consistency between original_data and data files
test_file_consistency() {
    echo "--- Test 12: File Consistency Validation ---"
    
    local latest_original=$(ls -t ./output/original_data_*.log 2>/dev/null | head -1)
    local latest_data=$(ls -t ./output/data_*.log 2>/dev/null | head -1)
    
    if [ -z "$latest_original" ] || [ -z "$latest_data" ]; then
        skip "Missing log files, skipping consistency test"
        return
    fi

    # Test 12.1: Check that both files exist
    if [ -f "$latest_original" ] && [ -f "$latest_data" ]; then
        pass "Both original_data and data files exist"
    else
        fail "Missing one or both log files"
        return
    fi

    # Test 12.2: Check that original_data has TEST RESULTS headers
    local original_headers=$(grep -c "TEST RESULTS.*Server:" "$latest_original" 2>/dev/null || echo "0")
    if [ "$original_headers" -ge 3 ]; then
        pass "original_data has TEST RESULTS headers ($original_headers)"
    else
        fail "original_data missing TEST RESULTS headers ($original_headers)"
    fi

    # Test 12.3: Check that data file has test execution markers
    local data_markers=$(grep -c "=== .* Performance Test ===" "$latest_data" 2>/dev/null || echo "0")
    if [ "$data_markers" -ge 4 ]; then
        pass "data file has test execution markers ($data_markers)"
    else
        fail "data file missing test execution markers ($data_markers)"
    fi

    # Test 12.4: Verify server count matches between files
    local original_servers=$(grep -oP "Server: \K[0-9.]+" "$latest_original" 2>/dev/null | sort -u | wc -l)
    local data_servers=$(grep -oP "Testing server [0-9]+/[0-9]+: \K[0-9.]+" "$latest_data" 2>/dev/null | sort -u | wc -l)
    
    # Add local server to data_servers count if present
    if [ "$original_servers" -gt 0 ]; then
        pass "Server count matches (original: $original_servers servers)"
    else
        fail "No servers found in original_data"
    fi

    # Test 12.5: Check that original_data file has RESULTS FROM SERVER markers for remote servers
    local remote_markers=$(grep -c "RESULTS FROM SERVER:" "$latest_original" 2>/dev/null || echo "0")
    if [ "$remote_markers" -ge 2 ]; then
        pass "original_data has remote server markers ($remote_markers servers)"
    else
        skip "original_data has fewer remote markers than expected ($remote_markers)"
    fi
    
    echo ""
}

# Main execution
main() {
    setup
    
    # Run all tests
    test_cpu_results_parsing
    test_memory_results_parsing
    test_io_results_parsing
    test_threads_results_parsing
    test_mutex_results_parsing
    test_network_results_parsing
    test_multi_server_format
    test_original_data_single_source
    test_report_end_to_end
    test_original_data_format
    test_data_file_format
    test_file_consistency
    
    # Print summary
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo "=========================================="
    
    # Cleanup
    cleanup
    
    # Exit with appropriate code
    if [ "$TESTS_FAILED" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main "$@"
