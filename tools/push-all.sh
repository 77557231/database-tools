#!/bin/bash

# push-all.sh - 一键推送到Gitee和GitHub两个代码库
# 用法:
#   ./push-all.sh                    # 自动生成commit信息并推送
#   ./push-all.sh "commit message"   # 使用自定义commit信息并推送
#   ./push-all.sh "msg" "v1.2.3"    # 使用自定义commit信息和版本号

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

# 获取commit信息和自定义版本号
COMMIT_MSG="$1"
CUSTOM_VERSION="$2"

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

# 更新版本记录
echo -e "${YELLOW}正在更新版本记录...${NC}"
VERSION_FILE="tools/VERSION.md"

if [ -n "$CUSTOM_VERSION" ]; then
    # 使用自定义版本号
    NEW_VERSION="$CUSTOM_VERSION"
    echo -e "${YELLOW}使用自定义版本号: $NEW_VERSION${NC}"
else
    # 自动递增版本号
    if [ -f "$VERSION_FILE" ]; then
        # 读取最新版本号（第一行数据）
        CURRENT_VERSION=$(grep -E '^\| [v0-9]' "$VERSION_FILE" | head -1 | awk -F '|' '{print $2}' | tr -d ' ')
    else
        CURRENT_VERSION="v0.0.0"
    fi

    # 移除 v 前缀用于计算
    VER="${CURRENT_VERSION#v}"

    # 递增第三位版本号 (0.5.6 -> 0.5.7)
    IFS='.' read -r major minor patch <<< "$VER"
    patch=$((patch + 1))
    if [ $patch -ge 10 ]; then
        patch=0
        minor=$((minor + 1))
        if [ $minor -ge 10 ]; then
            minor=0
            major=$((major + 1))
        fi
    fi

    # 保持原版本号格式（是否有 v 前缀）
    if [[ "$CURRENT_VERSION" == v* ]]; then
        NEW_VERSION="v$major.$minor.$patch"
    else
        NEW_VERSION="$major.$minor.$patch"
    fi
fi

# 生成版本记录（使用单行摘要）
COMMIT_SUMMARY=$(echo "$COMMIT_MSG" | head -1)
VERSION_ENTRY="| $NEW_VERSION | $(date +"%Y-%m-%d") | $COMMIT_SUMMARY |"

# 添加到版本记录文件
if [ -f "$VERSION_FILE" ]; then
    # 读取文件内容
    HEADER=$(head -6 "$VERSION_FILE")
    BODY=$(tail -n +7 "$VERSION_FILE")

    # 重新构建文件
    echo "$HEADER" > "$VERSION_FILE"
    echo "$VERSION_ENTRY" >> "$VERSION_FILE"
    echo "$BODY" >> "$VERSION_FILE"
else
    # 创建版本记录文件
    cat > "$VERSION_FILE" << EOF
# 版本更新记录

## 版本历史

| 版本号 | 更新日期 | 更新内容 |
|--------|----------|----------|
$VERSION_ENTRY
EOF
fi

echo -e "${GREEN}✓ 版本记录更新完成: $NEW_VERSION${NC}"

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

# 推送到GitHub (master分支和tags)
echo -e "${YELLOW}正在推送到 GitHub (master)...${NC}"
if git push github master --tags 2>&1; then
    echo -e "${GREEN}✓ GitHub 推送成功${NC}"
else
    echo -e "${YELLOW}⚠ GitHub 推送失败（可能需要配置访问令牌）${NC}"
    echo -e "${YELLOW}  尝试使用 github remote 推送...${NC}"
    if git push github master --tags 2>&1; then
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
