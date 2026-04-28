#!/bin/bash

# tools/oscheckperf_validate_logs.sh - Validate and analyze oscheckperf test logs
# Purpose:
# 1. Add execution command to the first line of original_*.log files
# 2. Parse logs based on execution commands to understand execution intent
# 3. Analyze log content to check for oscheckperf script issues

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  oscheckperf Log Validation Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

# Check if test output directory exists
OUTPUT_DIR="./test_output"
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}  Test output directory does not exist, creating...${NC}"
    mkdir -p "$OUTPUT_DIR"
    echo -e "${GREEN}  ✓ Test output directory created successfully${NC}"
fi

# Find original_*.log files
echo -e "${YELLOW}1. Finding original log files...${NC}"
ORIGINAL_LOGS=($(find "$OUTPUT_DIR" -name "original_*.log" 2>/dev/null))

if [ ${#ORIGINAL_LOGS[@]} -eq 0 ]; then
    echo -e "${YELLOW}  No original log files found, running test to generate...${NC}"
    # Run a simple test to generate logs
    ./oscheckperf io --dry-run DURATION=1 IO_TOTAL_SIZE=10M
    # Find again
    ORIGINAL_LOGS=($(find "$OUTPUT_DIR" -name "original_*.log" 2>/dev/null))
    if [ ${#ORIGINAL_LOGS[@]} -eq 0 ]; then
        echo -e "${RED}  ❌ Cannot generate log files, please run test first${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}  ✓ Found ${#ORIGINAL_LOGS[@]} original log files${NC}"
for log_file in "${ORIGINAL_LOGS[@]}"; do
    echo -e "    - $(basename "$log_file")"
done

# Process each log file
echo -e "\n${YELLOW}2. Processing log files...${NC}"
for log_file in "${ORIGINAL_LOGS[@]}"; do
    echo -e "\n${BLUE}  Processing: $(basename "$log_file")${NC}"
    
    # Check if first line already contains execution command
    FIRST_LINE=$(head -1 "$log_file" 2>/dev/null || echo "")
    if [[ ! "$FIRST_LINE" =~ "执行命令:" && ! "$FIRST_LINE" =~ "Execution Command:" ]]; then
        # Extract execution command from log content
        EXEC_COMMAND=$(grep -E "oscheckperf .*" "$log_file" 2>/dev/null | head -1 || echo "Unknown command")
        
        # If not found, infer from filename
        if [ "$EXEC_COMMAND" = "Unknown command" ]; then
            if [[ "$log_file" =~ "io" ]]; then
                EXEC_COMMAND="./oscheckperf io"
            elif [[ "$log_file" =~ "cpu" ]]; then
                EXEC_COMMAND="./oscheckperf cpu"
            elif [[ "$log_file" =~ "mem" ]]; then
                EXEC_COMMAND="./oscheckperf mem"
            elif [[ "$log_file" =~ "network" ]]; then
                EXEC_COMMAND="./oscheckperf network"
            else
                EXEC_COMMAND="./oscheckperf all"
            fi
        fi
        
        # Add execution command to first line
        echo -e "${YELLOW}    Adding execution command to log file header...${NC}"
        TEMP_FILE="$log_file.tmp"
        echo "# Execution Command: $EXEC_COMMAND" > "$TEMP_FILE"
        cat "$log_file" >> "$TEMP_FILE"
        mv "$TEMP_FILE" "$log_file"
        echo -e "${GREEN}    ✓ Execution command added${NC}"
    else
        echo -e "${GREEN}    Execution command already exists in log header${NC}"
        EXEC_COMMAND=$(echo "$FIRST_LINE" | sed 's/^# 执行命令: //' | sed 's/^# Execution Command: //' | sed 's/^Execution Command: //')
    fi
    
    # Validate execution command format
    echo -e "${YELLOW}    Validating execution command format...${NC}"
    if [[ "$EXEC_COMMAND" =~ "./oscheckperf" ]]; then
        echo -e "    ${GREEN}✓ Execution command format valid: $EXEC_COMMAND${NC}"
    else
        echo -e "    ${RED}✗ Execution command format invalid${NC}"
    fi
    
    # Validate multi-profile tests
    echo -e "${YELLOW}    Validating multi-profile test execution...${NC}"
    if [[ "$EXEC_COMMAND" =~ "FIO_PROFILES" ]]; then
        # Extract FIO_PROFILES value
        FIO_PROFILES_VAL=$(echo "$EXEC_COMMAND" | grep -oP 'FIO_PROFILES="[^"]*"' | cut -d'"' -f2)
        if [ -n "$FIO_PROFILES_VAL" ]; then
            echo -e "    ${GREEN}✓ FIO multi-profile detected: $FIO_PROFILES_VAL${NC}"
            # Validate each profile in the log
            for profile in $FIO_PROFILES_VAL; do
                if grep -q "FIO TEST RESULTS ($profile)" "$log_file"; then
                    echo -e "    ${GREEN}✓ Profile '$profile' results found in log${NC}"
                else
                    echo -e "    ${RED}✗ Profile '$profile' results NOT found in log${NC}"
                fi
            done
        fi
    elif [[ "$EXEC_COMMAND" =~ "SYSBENCH_PROFILES" ]]; then
        # Extract SYSBENCH_PROFILES value
        SYSBENCH_PROFILES_VAL=$(echo "$EXEC_COMMAND" | grep -oP 'SYSBENCH_PROFILES="[^"]*"' | cut -d'"' -f2)
        if [ -n "$SYSBENCH_PROFILES_VAL" ]; then
            echo -e "    ${GREEN}✓ SYSBENCH multi-profile detected: $SYSBENCH_PROFILES_VAL${NC}"
            # Validate each profile in the log
            for profile in $SYSBENCH_PROFILES_VAL; do
                if grep -q "SYSBENCH FILEIO TEST RESULTS ($profile)" "$log_file"; then
                    echo -e "    ${GREEN}✓ Profile '$profile' results found in log${NC}"
                else
                    echo -e "    ${RED}✗ Profile '$profile' results NOT found in log${NC}"
                fi
            done
        fi
    fi
    
    # Analyze execution intent
    echo -e "${YELLOW}    Analyzing execution intent...${NC}"
    if [[ "$EXEC_COMMAND" =~ "io" ]]; then
        echo -e "    ${GREEN}✓ Execution intent: IO performance test${NC}"
        # Check IO test content
        IO_TESTS=$(grep -E "IO Performance Test|SYSBENCH FILEIO TEST|FIO TEST" "$log_file" 2>/dev/null | wc -l)
        if [ "$IO_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ IO test content exists${NC}"
        else
            echo -e "    ${RED}✗ IO test content missing${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "cpu" ]]; then
        echo -e "    ${GREEN}✓ Execution intent: CPU performance test${NC}"
        # Check CPU test content
        CPU_TESTS=$(grep -E "CPU Performance Test|sysbench cpu" "$log_file" 2>/dev/null | wc -l)
        if [ "$CPU_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ CPU test content exists${NC}"
        else
            echo -e "    ${RED}✗ CPU test content missing${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "mem" ]]; then
        echo -e "    ${GREEN}✓ Execution intent: Memory performance test${NC}"
        # Check memory test content
        MEM_TESTS=$(grep -E "Memory Performance Test|sysbench memory" "$log_file" 2>/dev/null | wc -l)
        if [ "$MEM_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ Memory test content exists${NC}"
        else
            echo -e "    ${RED}✗ Memory test content missing${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "network" ]]; then
        echo -e "    ${GREEN}✓ Execution intent: Network performance test${NC}"
        # Check network test content
        NET_TESTS=$(grep -E "Network Performance Test|iperf3" "$log_file" 2>/dev/null | wc -l)
        if [ "$NET_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ Network test content exists${NC}"
        else
            echo -e "    ${RED}✗ Network test content missing${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "all" ]]; then
        echo -e "    ${GREEN}✓ Execution intent: Full performance test${NC}"
    else
        echo -e "    ${YELLOW}⚠ Execution intent: Unknown${NC}"
    fi
    
    # Check for error messages
    echo -e "${YELLOW}    Checking for error messages...${NC}"
    ERROR_COUNT=$(grep -E "error|Error|ERROR|failed|Failed|FAILED|❌" "$log_file" 2>/dev/null | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "    ${RED}✗ Found $ERROR_COUNT error messages${NC}"
        # Show first 3 errors
        grep -E "error|Error|ERROR|failed|Failed|FAILED|❌" "$log_file" 2>/dev/null | head -3
    else
        echo -e "    ${GREEN}✓ No error messages found${NC}"
    fi
    
    # Check test completion information
    echo -e "${YELLOW}    Checking test completion information...${NC}"
    COMPLETION_COUNT=$(grep -E "completed|完成|✓" "$log_file" 2>/dev/null | wc -l)
    if [ "$COMPLETION_COUNT" -gt 0 ]; then
        echo -e "    ${GREEN}✓ Test completion information exists${NC}"
    else
        echo -e "    ${YELLOW}⚠ Test completion information missing${NC}"
    fi
 done

# Analyze overall results
echo -e "\n${YELLOW}3. Overall analysis...${NC}"
TOTAL_LOGS=${#ORIGINAL_LOGS[@]}
ERROR_LOGS=0

for log_file in "${ORIGINAL_LOGS[@]}"; do
    ERROR_COUNT=$(grep -E "error|Error|ERROR|failed|Failed|FAILED|❌" "$log_file" 2>/dev/null | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        ERROR_LOGS=$((ERROR_LOGS + 1))
    fi
done

echo -e "${BLUE}  Statistics:${NC}"
echo -e "    Total log files: ${TOTAL_LOGS}"
echo -e "    Logs with errors: ${ERROR_LOGS}"
echo -e "    Logs without errors: $((TOTAL_LOGS - ERROR_LOGS))"

if [ "$ERROR_LOGS" -eq 0 ]; then
    echo -e "${GREEN}✓ All logs are normal, oscheckperf script is working well${NC}"
elif [ "$ERROR_LOGS" -lt "$TOTAL_LOGS" ]; then
        echo -e "${YELLOW}⚠ Some logs have errors, recommend to check oscheckperf script${NC}"
else
    echo -e "${RED}✗ All logs have errors, oscheckperf script may have serious issues${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Log validation completed${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Recommendations:${NC}"
echo -e "  1. View detailed logs: cat test_output/original_*.log"
echo -e "  2. Check report files: cat test_output/report_benchmark_*.log"
echo -e "  3. Run specific tests: ./oscheckperf io/cpu/mem/network"
echo ""
