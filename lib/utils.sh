# lib/utils.sh - 通用工具函数

# 检查命令是否存在
check_command() {
    local cmd="$1"
    local install_hint="$2"
    
    if command -v "$cmd" &> /dev/null; then
        return 0
    else
        if [ -n "$install_hint" ]; then
            echo "警告：命令 '$cmd' 未安装。$install_hint"
        else
            echo "警告：命令 '$cmd' 未安装"
        fi
        return 1
    fi
}

# 获取 CPU 核心数
get_cpu_cores() {
    nproc
}

# 获取内存大小（MB）
get_memory_size_mb() {
    free -m | awk '/^Mem:/ {print $2}'
}

# 获取磁盘可用空间（KB）
get_disk_available_kb() {
    local path="${1:-/tmp}"
    df -P "$path" | awk 'NR==2 {print $4}'
}

# 日志输出函数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 清理测试文件
cleanup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        rm -f "$file"
    fi
}

# 清理测试目录
cleanup_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
}

# 等待命令执行完成（带超时）
wait_with_timeout() {
    local pid="$1"
    local timeout="$2"
    local start_time=$(date +%s)
    
    while kill -0 "$pid" 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -ge "$timeout" ]; then
            kill -9 "$pid" 2>/dev/null
            return 1
        fi
        
        sleep 1
    done
    
    return 0
}
