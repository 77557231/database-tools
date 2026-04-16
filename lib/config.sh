# lib/config.sh - 配置解析模块

# 加载配置文件
load_config() {
    local mode="$1"
    local config_file="$2"
    
    if [ -n "$config_file" ]; then
        if [ ! -f "$config_file" ]; then
            echo "错误：配置文件不存在：$config_file"
            exit 1
        fi
        source "$config_file"
    else
        # 使用 SCRIPT_DIR 变量（在主脚本中设置）
        local default_config="${SCRIPT_DIR}/config/${mode}.conf"
        if [ ! -f "$default_config" ]; then
            echo "错误：默认配置文件不存在：$default_config"
            exit 1
        fi
        source "$default_config"
    fi
    
    # 设置默认值
    OUTPUT_DIR="${OUTPUT_DIR:-./output}"
    FORMAT="${FORMAT:-txt}"
    CLEANUP="${CLEANUP:-true}"
}

# 解析多服务器配置
# 格式：IP:ROLE:描述，多个服务器用逗号分隔
parse_servers() {
    local servers_str="${SERVERS:-}"
    if [ -z "$servers_str" ]; then
        echo ""
        return
    fi
    
    local IFS=','
    for server in $servers_str; do
        local ip=$(echo "$server" | cut -d: -f1)
        local role=$(echo "$server" | cut -d: -f2)
        local desc=$(echo "$server" | cut -d: -f3)
        echo "$ip|$role|$desc"
    done
}

# 解析测试场景配置
# 格式：CLIENT_IP:SERVER_IP:Duration
parse_test_scenarios() {
    local scenarios_str="${TEST_SCENARIOS:-}"
    if [ -z "$scenarios_str" ]; then
        echo ""
        return
    fi
    
    local IFS=','
    for scenario in $scenarios_str; do
        local client_ip=$(echo "$scenario" | cut -d: -f1)
        local server_ip=$(echo "$scenario" | cut -d: -f2)
        local duration=$(echo "$scenario" | cut -d: -f3)
        echo "$client_ip|$server_ip|$duration"
    done
}
