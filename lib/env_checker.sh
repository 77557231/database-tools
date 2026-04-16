# lib/env_checker.sh - Environment check module

# Check all dependencies
check_all() {
    echo "=== Checking Dependencies ==="
    check_dependencies
    
    echo ""
    echo "=== Checking Permissions ==="
    check_permissions
    
    echo ""
    echo "=== Checking Disk Space ==="
    check_disk_space
    
    echo ""
    echo "=== Checking Network Connectivity ==="
    check_network
}

# Check dependencies
check_dependencies() {
    local has_error=false
    
    # sysbench is required
    if check_command "sysbench" "Please run: sudo yum install -y sysbench"; then
        echo "✓ sysbench installed"
    else
        has_error=true
    fi
    
    # Additional tools required for production mode
    if [ "$MODE" = "production" ] || [ "$MODE" = "deep" ]; then
        if check_command "fio" "Please run: sudo yum install -y fio"; then
            echo "✓ fio installed"
        else
            has_error=true
        fi
        
        if check_command "iperf3" "Please run: sudo yum install -y iperf3"; then
            echo "✓ iperf3 installed"
        else
            has_error=true
        fi
        
        if check_command "jq" "Please run: sudo yum install -y jq"; then
            echo "✓ jq installed"
        else
            echo "⚠ jq not installed (recommended for JSON parsing)"
        fi
    fi
    
    if [ "$has_error" = true ]; then
        echo ""
        echo "Error: Missing required dependencies, please install before running"
        return 1
    fi
    
    return 0
}

# Check permissions
check_permissions() {
    # Check root permission
    if [ "$EUID" -ne 0 ]; then
        echo "⚠ Running as non-root user, some tests may fail"
        echo "  Suggestion: Run with 'sudo vb_benchmark ...'"
    else
        echo "✓ Root permission check passed"
    fi
    
    # Check test directory write permission
    local test_path="${IO_TEST_PATH:-/tmp}"
    if [ ! -w "$test_path" ]; then
        echo "✗ No write permission for test directory: $test_path"
        return 1
    else
        echo "✓ Test directory write permission check passed: $test_path"
    fi
}

# Check disk space
check_disk_space() {
    local test_path="${IO_TEST_PATH:-/tmp}"
    local available_kb=$(get_disk_available_kb "$test_path")
    local available_gb=$((available_kb / 1024 / 1024))
    
    # Calculate required space based on mode
    local required_gb=0
    case $MODE in
        quick)
            required_gb=2
            ;;
        production)
            required_gb=10
            ;;
        deep)
            required_gb=50
            ;;
    esac
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        echo "✗ Insufficient disk space"
        echo "  Available: ${available_gb}GB"
        echo "  Required: ${required_gb}GB"
        return 1
    else
        echo "✓ Disk space check passed: ${available_gb}GB available, ${required_gb}GB required"
    fi
}

# Check network connectivity
check_network() {
    # If can ping localhost, consider network OK
    if ping -c 1 127.0.0.1 &> /dev/null; then
        echo "✓ Network connectivity check passed"
    else
        echo "⚠ Network connectivity check failed"
    fi
}
