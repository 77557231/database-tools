# lib/net_test.sh - Network test module

run_network_test() {
    echo "=== Network Performance Test ==="
    
    local network_tool="${NETWORK_TOOL:-iperf3}"
    local network_mode="${NETWORK_MODE:-single}"
    
    # Check if iperf3 is installed
    if ! command -v iperf3 &> /dev/null; then
        echo "Error: iperf3 not installed, please run: sudo yum install -y iperf3"
        return 1
    fi
    
    if [ "$network_mode" = "multi-server" ]; then
        run_multi_server_network_test
    else
        run_single_network_test
    fi
}

# Get machine's real IP address
get_machine_ip() {
    # Try hostname -I first (returns all IPs), take the first one
    local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi
    
    # Fallback: try ip route
    ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+')
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi
    
    # Last fallback
    echo "127.0.0.1"
}

# Single server network test
run_single_network_test() {
    local port="${NETWORK_PORT:-25201}"
    local duration="${NETWORK_DURATION:-20}"
    local parallel="${NETWORK_PARALLEL:-1}"
    
    # Auto-detect server IP if not set
    local server_ip="${NETWORK_SERVER_IP}"
    if [ -z "$server_ip" ]; then
        server_ip=$(get_machine_ip)
        echo "  Auto-detected server IP: $server_ip"
    fi
    
    # Use server IP as client IP if client IP not set (localhost test)
    local client_ip="${NETWORK_CLIENT_IP:-$server_ip}"
    
    local temp_output_file="/tmp/vb_network_${TIMESTAMP}.txt"
    local temp_text_output="/tmp/vb_network_text_${TIMESTAMP}.txt"
    local iperf3_pid=""
    
    # Check if multiple client IPs are configured (space-separated)
    local client_ips=($client_ip)
    local num_clients=${#client_ips[@]}
    
    echo "Starting iperf3 test..."
    echo "  Server: $server_ip:$port"
    echo "  Client(s): $client_ip"
    echo "  Duration: ${duration}s, Parallel connections: $parallel"
    echo "  Total test scenarios: $num_clients"
    
    # Start iperf3 server in background
    echo "  Starting iperf3 server on port $port..."
    iperf3 -s -p "$port" -D > /dev/null 2>&1
    iperf3_pid=$!
    sleep 2  # Wait for server to start
    
    # Verify server is running using pidof (more reliable than pgrep)
    if ! pidof iperf3 > /dev/null; then
        echo "⚠ Failed to start iperf3 server"
        return 1
    fi
    
    # Execute tests for each client IP sequentially
    local client_idx=0
    for client in "${client_ips[@]}"; do
        client_idx=$((client_idx + 1))
        
        if [ $num_clients -gt 1 ]; then
            echo ""
            echo "  [Test $client_idx/$num_clients] Testing from client: $client"
        fi
        
        # Calculate timeout: duration + 15s buffer for each client
        local client_timeout=$((duration + 15))
        local client_output_file="/tmp/vb_network_${TIMESTAMP}_client${client_idx}.txt"
        local client_text_output="/tmp/vb_network_text_${TIMESTAMP}_client${client_idx}.txt"
        
        # Run iperf3 client with timeout and capture both JSON and text output
        if timeout $client_timeout iperf3 -c "$server_ip" \
            -p "$port" \
            -t "$duration" \
            -P "$parallel" \
            -J > "$client_output_file" 2>&1; then
            
            # Capture text format output for per-second data
            iperf3 -c "$server_ip" -p "$port" -t "$duration" -P "$parallel" 2>&1 | grep -v "^$" > "$client_text_output"
            
            # Parse and display result
            parse_iperf3_result "$client_output_file"
            
            # Display per-second throughput
            display_per_second_throughput "$client_text_output" "$server_ip (from $client)"
            
            # Append to combined results file
            append_to_combined_result "NETWORK TEST RESULTS ($server_ip from $client)" "$client_text_output"
            
            echo "  ✓ Client $client test completed"
        else
            echo "  ⚠ Client $client test failed or timed out"
        fi
        
        # Cleanup individual temp files
        rm -f "$client_output_file" "$client_text_output"
    done
    
    echo ""
    echo "✓ Network test completed for all clients"
    
    # Stop iperf3 server
    echo "  Stopping iperf3 server..."
    kill "$iperf3_pid" 2>/dev/null || true
    pkill -f "iperf3 -s -p $port" 2>/dev/null || true
    sleep 1
    
    return 0
}

# Display per-second throughput
display_per_second_throughput() {
    local text_file="$1"
    local server_ip="$2"
    
    if [ ! -f "$text_file" ]; then
        return
    fi
    
    echo ""
    echo "Per-second throughput for $server_ip:"
    # Extract interval lines showing per-second data (format: [  5] 0.00-1.00 sec XXX MBytes X.XX Gbits/sec)
    grep "sec" "$text_file" | grep "MBytes" | grep "Gbits/sec" | grep -v "sender\|receiver" | while read -r line; do
        echo "  $line"
    done
}

# Multi-server network test
run_multi_server_network_test() {
    echo "Starting multi-server network test..."
    
    # Parse server list
    local servers=$(parse_servers)
    if [ -z "$servers" ]; then
        echo "Error: Server list not configured, please set SERVERS in config file"
        return 1
    fi
    
    # Parse test scenarios
    local scenarios=$(parse_test_scenarios)
    if [ -z "$scenarios" ]; then
        echo "Error: Test scenarios not configured, please set TEST_SCENARIOS in config file"
        return 1
    fi
    
    # Execute each test scenario
    local scenario_idx=0
    while IFS='|' read -r client_ip server_ip duration; do
        scenario_idx=$((scenario_idx + 1))
        echo ""
        echo "Executing scenario $scenario_idx: $client_ip -> $server_ip (${duration}s)"
        
        local output_file="$OUTPUT_DIR/data/network_scenario_${scenario_idx}.json"
        
        # SSH to client to run iperf3
        # Note: SSH passwordless login required for actual use
        echo "  ⚠ SSH connection to $client_ip required to run test"
        echo "  Tip: After configuring SSH passwordless login, use following command:"
        echo "  ssh $client_ip \"iperf3 -c $server_ip -t $duration -J\" > $output_file"
        
    done <<< "$servers"
    
    echo ""
    echo "✓ Multi-server network test configuration completed"
}

# Parse iperf3 JSON result
parse_iperf3_result() {
    local json_file="$1"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "⚠ jq not installed, skipping detailed parsing"
        return
    fi
    
    if [ ! -f "$json_file" ]; then
        echo "⚠ Result file not found: $json_file"
        return
    fi
    
    # Extract metrics
    local bandwidth_bps=$(jq -r '.end.sum_received.bits_per_second // 0' "$json_file" 2>/dev/null)
    local bandwidth_mbps=$(awk "BEGIN {printf \"%.2f\", $bandwidth_bps / 1000000}" 2>/dev/null || echo "0")
    
    # Display summary
    echo ""
    echo "Network test results:"
    echo "  Bandwidth: ${bandwidth_mbps} Mbps"
    
    # Only show jitter and packet loss for UDP tests (not applicable for TCP)
    if [ "${NETWORK_PROTOCOL:-tcp}" = "udp" ]; then
        local jitter_ms=$(jq -r '.end.sum_received.jitter_ms // 0' "$json_file" 2>/dev/null)
        local lost_packets=$(jq -r '.end.sum_received.lost_packets // 0' "$json_file" 2>/dev/null)
        local total_packets=$(jq -r '.end.sum_received.packets // 0' "$json_file" 2>/dev/null)
        
        # Calculate packet loss rate
        local packet_loss="0"
        if [ "$total_packets" -gt 0 ] 2>/dev/null; then
            packet_loss=$(awk "BEGIN {printf \"%.2f\", $lost_packets * 100 / $total_packets}" 2>/dev/null || echo "0")
        fi
        
        echo "  Jitter: ${jitter_ms} ms"
        echo "  Lost Packets: ${lost_packets}"
        echo "  Packet Loss: ${packet_loss}%"
    fi
}
