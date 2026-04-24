#!/bin/bash

# push-all.sh - 一键推送到Gitee和GitHub两个代码库
# 用法:
#   ./push-all.sh                    # 自动生成commit信息并推送
#   ./push-all.sh "commit message"   # 使用自定义commit信息并推送

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  双远程代码库自动推送脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 获取commit信息
COMMIT_MSG="$1"

if [ -z "$COMMIT_MSG" ]; then
    # 自动生成commit信息
    echo -e "${YELLOW}正在分析代码变更...${NC}"
    
    # 获取变更的文件列表
    CHANGED_FILES=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$CHANGED_FILES" -eq 0 ]; then
        echo -e "${GREEN}✓ 没有需要提交的变更${NC}"
        exit 0
    fi
    
    # 获取主要变更的文件类型统计
    FILE_TYPES=$(git status --short | awk '{print $2}' | sed 's/.*\.//g' | sort | uniq -c | sort -rn | head -3)
    
    # 获取最近3个commit的概要
    RECENT_COMMITS=$(git log --oneline -3 2>/dev/null || echo "无历史记录")
    
    # 生成描述性commit信息
    COMMIT_MSG="自动更新: ${CHANGED_FILES} 个文件变更

主要变更文件类型:
${FILE_TYPES}

近期更新概要:
${RECENT_COMMITS}"
    
    echo -e "${GREEN}✓ 自动生成commit信息${NC}"
    echo -e "${YELLOW}变更文件数: ${CHANGED_FILES}${NC}"
fi

echo ""

# 执行git add和commit
echo -e "${YELLOW}正在提交变更...${NC}"
git add -A

# 检查是否有变更需要提交
if git diff --cached --quiet; then
    echo -e "${GREEN}✓ 没有需要提交的变更${NC}"
    exit 0
fi

git commit -m "$COMMIT_MSG"

echo -e "${GREEN}✓ 提交完成${NC}"
echo ""

# 推送到Gitee (master分支和tags)
echo -e "${YELLOW}正在推送到 Gitee (master)...${NC}"
if git push origin master --tags 2>&1; then
    echo -e "${GREEN}✓ Gitee 推送成功${NC}"  
else
    echo -e "${RED}✗ Gitee 推送失败${NC}"
    GITEE_SUCCESS=false
fi

echo ""

# 推送到GitHub (main分支和tags)
echo -e "${YELLOW}正在推送到 GitHub (main)...${NC}"
if git push github main --tags 2>&1; then
    echo -e "${GREEN}✓ GitHub 推送成功${NC}"  
else
    echo -e "${YELLOW}⚠ GitHub 推送失败（可能需要配置访问令牌）${NC}"
    echo -e "${YELLOW}  尝试使用 github remote 推送...${NC}"
    if git push github main --tags 2>&1; then
        echo -e "${GREEN}✓ GitHub 推送成功（通过github remote）${NC}"  
    else
        echo -e "${RED}✗ GitHub 推送失败${NC}"
        echo -e "${YELLOW}  请检查: ${NC}"
        echo -e "${YELLOW}  1. GitHub访问令牌是否配置正确${NC}"
        echo -e "${YELLOW}  2. 网络连接是否正常${NC}"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ 推送完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Gitee:  https://gitee.com/panwanping/database-benchmark-tools${NC}"
echo -e "${YELLOW}GitHub: https://github.com/77557231/database-tools${NC}"
echo ""
