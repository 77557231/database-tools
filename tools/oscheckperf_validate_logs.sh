#!/bin/bash

# tools/oscheckperf_validate_logs.sh - 验证和分析 oscheckperf 测试日志
# 用途：
# 1. 在 original_*.log 日志首行增加执行命令打印
# 2. 根据执行命令解析日志，了解执行意图
# 3. 分析日志内容，判断 oscheckperf 脚本是否有问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  oscheckperf 日志验证工具${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 切换到项目根目录
cd "$(dirname "$0")/.." || exit 1

# 检查是否存在测试输出目录
OUTPUT_DIR="./test_output"
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}  测试输出目录不存在，创建中...${NC}"
    mkdir -p "$OUTPUT_DIR"
    echo -e "${GREEN}  ✓ 测试输出目录创建成功${NC}"
fi

# 查找 original_*.log 文件
echo -e "${YELLOW}1. 查找原始日志文件...${NC}"
ORIGINAL_LOGS=($(find "$OUTPUT_DIR" -name "original_*.log" 2>/dev/null))

if [ ${#ORIGINAL_LOGS[@]} -eq 0 ]; then
    echo -e "${YELLOW}  未找到原始日志文件，运行测试生成...${NC}"
    # 运行一个简单的测试生成日志
    ./oscheckperf io --dry-run DURATION=1 IO_TOTAL_SIZE=10M
    # 再次查找
    ORIGINAL_LOGS=($(find "$OUTPUT_DIR" -name "original_*.log" 2>/dev/null))
    if [ ${#ORIGINAL_LOGS[@]} -eq 0 ]; then
        echo -e "${RED}  ❌ 无法生成日志文件，请先运行测试${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}  ✓ 找到 ${#ORIGINAL_LOGS[@]} 个原始日志文件${NC}"
for log_file in "${ORIGINAL_LOGS[@]}"; do
    echo -e "    - $(basename "$log_file")"
done

# 处理每个日志文件
echo -e "\n${YELLOW}2. 处理日志文件...${NC}"
for log_file in "${ORIGINAL_LOGS[@]}"; do
    echo -e "\n${BLUE}  处理: $(basename "$log_file")${NC}"
    
    # 检查首行是否已经包含执行命令
    FIRST_LINE=$(head -1 "$log_file" 2>/dev/null || echo "")
    if [[ ! "$FIRST_LINE" =~ "执行命令:" && ! "$FIRST_LINE" =~ "Execution Command:" ]]; then
        # 提取执行命令（从日志内容中）
        EXEC_COMMAND=$(grep -E "oscheckperf .*" "$log_file" 2>/dev/null | head -1 || echo "未知命令")
        
        # 如果没找到，从文件名推断
        if [ "$EXEC_COMMAND" = "未知命令" ]; then
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
        
        # 在文件首行插入执行命令
        echo -e "${YELLOW}    增加执行命令到日志首行...${NC}"
        TEMP_FILE="$log_file.tmp"
        echo "# 执行命令: $EXEC_COMMAND" > "$TEMP_FILE"
        cat "$log_file" >> "$TEMP_FILE"
        mv "$TEMP_FILE" "$log_file"
        echo -e "${GREEN}    ✓ 执行命令已添加${NC}"
    else
        echo -e "${YELLOW}    执行命令已存在，跳过${NC}"
        EXEC_COMMAND=$(echo "$FIRST_LINE" | sed 's/^# 执行命令: //')
    fi
    
    # 分析执行意图
    echo -e "${YELLOW}    分析执行意图...${NC}"
    if [[ "$EXEC_COMMAND" =~ "io" ]]; then
        echo -e "    ${GREEN}✓ 执行意图: IO 性能测试${NC}"
        # 检查 IO 测试相关内容
        IO_TESTS=$(grep -E "IO Performance Test|SYSBENCH FILEIO TEST|FIO TEST" "$log_file" 2>/dev/null | wc -l)
        if [ "$IO_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ IO 测试内容存在${NC}"
        else
            echo -e "    ${RED}✗ IO 测试内容缺失${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "cpu" ]]; then
        echo -e "    ${GREEN}✓ 执行意图: CPU 性能测试${NC}"
        # 检查 CPU 测试相关内容
        CPU_TESTS=$(grep -E "CPU Performance Test|sysbench cpu" "$log_file" 2>/dev/null | wc -l)
        if [ "$CPU_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ CPU 测试内容存在${NC}"
        else
            echo -e "    ${RED}✗ CPU 测试内容缺失${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "mem" ]]; then
        echo -e "    ${GREEN}✓ 执行意图: 内存性能测试${NC}"
        # 检查内存测试相关内容
        MEM_TESTS=$(grep -E "Memory Performance Test|sysbench memory" "$log_file" 2>/dev/null | wc -l)
        if [ "$MEM_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ 内存测试内容存在${NC}"
        else
            echo -e "    ${RED}✗ 内存测试内容缺失${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "network" ]]; then
        echo -e "    ${GREEN}✓ 执行意图: 网络性能测试${NC}"
        # 检查网络测试相关内容
        NET_TESTS=$(grep -E "Network Performance Test|iperf3" "$log_file" 2>/dev/null | wc -l)
        if [ "$NET_TESTS" -gt 0 ]; then
            echo -e "    ${GREEN}✓ 网络测试内容存在${NC}"
        else
            echo -e "    ${RED}✗ 网络测试内容缺失${NC}"
        fi
    elif [[ "$EXEC_COMMAND" =~ "all" ]]; then
        echo -e "    ${GREEN}✓ 执行意图: 全项性能测试${NC}"
    else
        echo -e "    ${YELLOW}⚠ 执行意图: 未知${NC}"
    fi
    
    # 检查错误信息
    echo -e "${YELLOW}    检查错误信息...${NC}"
    ERROR_COUNT=$(grep -E "error|Error|ERROR|failed|Failed|FAILED|❌" "$log_file" 2>/dev/null | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "    ${RED}✗ 发现 $ERROR_COUNT 个错误信息${NC}"
        # 显示前3个错误
        grep -E "error|Error|ERROR|failed|Failed|FAILED|❌" "$log_file" 2>/dev/null | head -3
    else
        echo -e "    ${GREEN}✓ 未发现错误信息${NC}"
    fi
    
    # 检查测试完成信息
    echo -e "${YELLOW}    检查测试完成信息...${NC}"
    COMPLETION_COUNT=$(grep -E "completed|完成|✓" "$log_file" 2>/dev/null | wc -l)
    if [ "$COMPLETION_COUNT" -gt 0 ]; then
        echo -e "    ${GREEN}✓ 测试完成信息存在${NC}"
    else
        echo -e "    ${YELLOW}⚠ 测试完成信息缺失${NC}"
    fi
 done

# 分析整体结果
echo -e "\n${YELLOW}3. 整体分析...${NC}"
TOTAL_LOGS=${#ORIGINAL_LOGS[@]}
ERROR_LOGS=0

for log_file in "${ORIGINAL_LOGS[@]}"; do
    ERROR_COUNT=$(grep -E "error|Error|ERROR|failed|Failed|FAILED|❌" "$log_file" 2>/dev/null | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        ERROR_LOGS=$((ERROR_LOGS + 1))
    fi
done

echo -e "${BLUE}  统计结果:${NC}"
echo -e "    总日志文件数: ${TOTAL_LOGS}"
echo -e "    有错误的日志: ${ERROR_LOGS}"
echo -e "    无错误的日志: $((TOTAL_LOGS - ERROR_LOGS))"

if [ "$ERROR_LOGS" -eq 0 ]; then
    echo -e "${GREEN}✓ 所有日志正常，oscheckperf 脚本运行良好${NC}"
elif [ "$ERROR_LOGS" -lt "$TOTAL_LOGS" ]; then
    echo -e "${YELLOW}⚠ 部分日志存在错误，建议检查 oscheckperf 脚本${NC}"
else
    echo -e "${RED}✗ 所有日志都存在错误，oscheckperf 脚本可能有严重问题${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✓ 日志验证完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}建议：${NC}"
echo -e "  1. 查看详细日志: cat test_output/original_*.log"
echo -e "  2. 检查报告文件: cat test_output/report_benchmark_*.log"
echo -e "  3. 运行特定测试: ./oscheckperf io/cpu/mem/network"
echo ""
