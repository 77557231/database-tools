#!/bin/bash

# validate_logs.sh - 验证测试日志解析内容
# 用法: ./validate_logs.sh [duration] [io_test_mode]
# 示例: ./validate_logs.sh 1 rndrd

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  测试日志解析验证工具${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 获取参数
DURATION=${1:-1}
IO_TEST_MODE=${2:-rndrw}

# 清理旧的输出文件
echo -e "${YELLOW}清理旧的输出文件...${NC}" 
rm -rf ./output/*

# 运行测试
echo -e "${YELLOW}运行测试...${NC}"
echo -e "${BLUE}命令: ./oscheckperf all -f servers.txt DURATION=$DURATION IO_TEST_MODE=$IO_TEST_MODE${NC}"
echo ""

# 运行测试
./oscheckperf all -f servers.txt DURATION=$DURATION IO_TEST_MODE=$IO_TEST_MODE

# 检查输出目录
echo -e "${YELLOW}\n检查输出文件...${NC}"

# 获取生成的文件
DATA_FILE=$(find ./output -name "data_*_all_results.log" | head -1)
REPORT_FILE=$(find ./output -name "report_benchmark_*.log" | head -1)
ORIGINAL_FILE=$(find ./output -name "original_data_*_all_results.log" | head -1)

# 检查文件是否生成
if [ -z "$DATA_FILE" ]; then
    echo -e "${RED}❌ 未生成 data_*_all_results.log 文件${NC}"
    exit 1
fi

if [ -z "$REPORT_FILE" ]; then
    echo -e "${RED}❌ 未生成 report_benchmark_*.log 文件${NC}"
    exit 1
fi

if [ -z "$ORIGINAL_FILE" ]; then
    echo -e "${RED}❌ 未生成 original_data_*_all_results.log 文件${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 所有日志文件已生成${NC}"
echo -e "${BLUE}  Data file: $DATA_FILE${NC}"
echo -e "${BLUE}  Report file: $REPORT_FILE${NC}"
echo -e "${BLUE}  Original file: $ORIGINAL_FILE${NC}"

# 验证data文件
echo -e "${YELLOW}\n验证 data 文件内容...${NC}"
if grep -q "IO test results:" "$DATA_FILE"; then
    echo -e "${GREEN}✓ IO test results 存在${NC}"
else
    echo -e "${RED}❌ IO test results 不存在${NC}"
    exit 1
fi

if grep -q "Read IOPS:" "$DATA_FILE"; then
    echo -e "${GREEN}✓ Read IOPS 存在${NC}"
else
    echo -e "${RED}❌ Read IOPS 不存在${NC}"
    exit 1
fi

if grep -q "Write IOPS:" "$DATA_FILE"; then
    echo -e "${GREEN}✓ Write IOPS 存在${NC}"
else
    echo -e "${RED}❌ Write IOPS 不存在${NC}"
    exit 1
fi

# 验证report文件
echo -e "${YELLOW}\n验证 report 文件内容...${NC}"
if grep -q "IO Test Comparison" "$REPORT_FILE"; then
    echo -e "${GREEN}✓ IO Test Comparison 存在${NC}"
else
    echo -e "${RED}❌ IO Test Comparison 不存在${NC}"
    exit 1
fi

if grep -q "Read IOPS" "$REPORT_FILE"; then
    echo -e "${GREEN}✓ Read IOPS 列存在${NC}"
else
    echo -e "${RED}❌ Read IOPS 列不存在${NC}"
    exit 1
fi

if grep -q "Mode" "$REPORT_FILE"; then
    echo -e "${GREEN}✓ Mode 列存在${NC}"
else
    echo -e "${RED}❌ Mode 列不存在${NC}"
    exit 1
fi

if grep -q "$IO_TEST_MODE" "$REPORT_FILE"; then
    echo -e "${GREEN}✓ IO_TEST_MODE ($IO_TEST_MODE) 正确显示${NC}"
else
    echo -e "${RED}❌ IO_TEST_MODE ($IO_TEST_MODE) 未正确显示${NC}"
    exit 1
fi

# 验证original文件
echo -e "${YELLOW}\n验证 original 文件内容...${NC}"
if grep -q "SYSBENCH FILEIO TEST RESULTS" "$ORIGINAL_FILE"; then
    echo -e "${GREEN}✓ SYSBENCH FILEIO TEST RESULTS 存在${NC}"
else
    echo -e "${RED}❌ SYSBENCH FILEIO TEST RESULTS 不存在${NC}"
    exit 1
fi

if grep -q "reads/s:" "$ORIGINAL_FILE"; then
    echo -e "${GREEN}✓ reads/s 存在${NC}"
else
    echo -e "${RED}❌ reads/s 不存在${NC}"
    exit 1
fi

if grep -q "writes/s:" "$ORIGINAL_FILE"; then
    echo -e "${GREEN}✓ writes/s 存在${NC}"
else
    echo -e "${RED}❌ writes/s 不存在${NC}"
    exit 1
fi

# 验证网络测试输出
echo -e "${YELLOW}\n验证网络测试输出...${NC}"
if grep -q "Network Performance Test" "$DATA_FILE"; then
    echo -e "${GREEN}✓ 网络测试部分存在${NC}"
else
    echo -e "${RED}❌ 网络测试部分不存在${NC}"
    exit 1
fi

if grep -q "Client.*test completed" "$DATA_FILE"; then
    echo -e "${GREEN}✓ 客户端测试完成信息存在${NC}"
else
    echo -e "${RED}❌ 客户端测试完成信息不存在${NC}"
    exit 1
fi

if grep -q "Protocol: TCP" "$DATA_FILE"; then
    echo -e "${GREEN}✓ 网络测试详细信息存在${NC}"
else
    echo -e "${RED}❌ 网络测试详细信息不存在${NC}"
    exit 1
fi

echo -e "${GREEN}\n========================================${NC}"
echo -e "${GREEN}✓ 所有日志文件解析验证通过${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}测试结果文件:${NC}"
echo -e "  Data: $DATA_FILE"
echo -e "  Report: $REPORT_FILE"
echo -e "  Original: $ORIGINAL_FILE"
echo ""
