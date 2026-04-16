# Vastbase System Benchmark Tool

一款专为 Vastbase 数据库设计的系统层性能压测工具，支持快速验收和生产基线两种模式，帮助评估服务器硬件性能边界。

## 特性

- ✅ **双模式支持**：快速验收（仅 sysbench）/ 生产基线（fio + sysbench + iperf3）
- ✅ **一键执行**：自动化完成 CPU/内存/IO/网络/线程/锁测试
- ✅ **配置灵活**：通过配置文件控制测试项、参数、时长
- ✅ **最小依赖**：快速模式仅需 sysbench
- ✅ **多格式报告**：TXT（快速查看）/ JSON（机器可读）
- ✅ **多服务器支持**：网络压测支持多 IP 配置（需 SSH 免密）

## 快速开始

### 1. 安装依赖

### 方式一：包管理器安装（推荐）

#### 快速模式（最小依赖）
```bash
# CentOS/RHEL
sudo yum install -y sysbench

# Ubuntu/Debian
sudo apt-get install -y sysbench
```

#### 生产模式（完整依赖）
```bash
# CentOS/RHEL
sudo yum install -y sysbench fio iperf3 jq

# Ubuntu/Debian
sudo apt-get install -y sysbench fio iperf3 jq
```

### 方式二：源码编译安装（当包管理器不可用时）

**适用场景**：
- 包管理器中 sysbench 版本过旧
- 系统无法访问外部 YUM/APT 源
- 需要自定义编译选项

**注意事项**：
- 以下步骤需要 root 用户执行（依赖安装）
- vastbase 用户执行编译和安装
- 如果已安装 sysbench，请跳过此步骤

#### 1. 安装编译依赖

**CentOS/RHEL 系列：**
```bash
sudo yum install -y make automake libtool pkgconfig libaio-devel
```

**Ubuntu/Debian 系列：**
```bash
sudo apt install -y make automake libtool pkg-config libaio-dev
```

#### 2. 解压源码包（vastbase 用户）

```bash
# 切换到 vastbase 用户
su - vastbase

# 进入 vb_benchmark 目录
cd /home/vastbase/project/script/vb_benchmark

# 解压 sysbench 源码
tar -zxvf sysbench-1.0.20.tar.gz
cd sysbench-1.0.20
```

#### 3. 编译和安装

```bash
# 配置编译选项
./configure --prefix=/usr/local --with-pgsql --without-mysql

# 编译（使用所有 CPU 核心加速）
make -j$(nproc)

# 安装（需要 sudo 权限）
sudo make install
```

#### 4. 配置环境变量

```bash
# 加载环境变量（sysbench 已安装到系统路径，此步骤可选）
source ~/.bashrc
```

#### 5. 验证安装

```bash
# 检查 sysbench 版本
sysbench --version

# 应该输出：sysbench 1.0.20
```

#### 一键安装脚本

可以将上述步骤整合为一个脚本：

```bash
# root 用户执行（安装依赖）
sudo yum install -y make automake libtool pkgconfig libaio-devel  # CentOS
# 或
sudo apt install -y make automake libtool pkg-config libaio-dev   # Ubuntu

# vastbase 用户执行（编译安装）
su - vastbase << 'EOF'
cd /home/vastbase/project/script/vb_benchmark
tar -zxvf sysbench-1.0.20.tar.gz
cd sysbench-1.0.20
./configure --prefix=/usr/local --with-pgsql --without-mysql
make -j$(nproc)
sudo make install
source ~/.bashrc
sysbench --version
EOF
```

### 2. 运行测试

#### 快速验收模式（默认）
```bash
cd /home/vastbase/project/script/vb_benchmark
./vb_benchmark
```

#### 生产基线模式
```bash
./vb_benchmark -m production
```

#### 深度测试模式
```bash
./vb_benchmark -m deep
```

#### 环境检查（空跑）
```bash
./vb_benchmark --dry-run
```

#### 自定义配置文件
```bash
./vb_benchmark -c ./my_config.conf
```

### 3. 查看报告
```bash
ls -lh output/reports/
cat output/reports/benchmark_*.txt
```

## 测试模式说明

### 快速验收模式（quick）
- **依赖**：仅 sysbench
- **时长**：5-10 分钟
- **场景**：新服务器快速验收、CI/CD 集成
- **测试项**：CPU、内存、IO（sysbench fileio）、线程、互斥锁

### 生产基线模式（production）
- **依赖**：sysbench + fio + iperf3
- **时长**：30-60 分钟
- **场景**：生产环境性能基线、容量规划
- **测试项**：CPU、内存、IO（fio）、网络、线程、互斥锁

### 深度测试模式（deep）
- **依赖**：sysbench + fio + iperf3
- **时长**：2 小时
- **场景**：全面评估硬件性能边界、性能调优
- **测试项**：CPU、内存、IO（完整 fio 测试集）、网络、线程、互斥锁

## 配置说明

### 内置配置文件

| 配置文件 | 模式 | 依赖 | 时长 |
|----------|------|------|------|
| config/quick.conf | quick | sysbench | 5-10 分钟 |
| config/production.conf | production | sysbench+fio+iperf3 | 30-60 分钟 |
| config/deep.conf | deep | sysbench+fio+iperf3 | 2 小时 |

### 详细参数说明

#### CPU 测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| CPU_ENABLED | 是否启用 CPU 测试 | true | true/false |
| CPU_DURATION | 测试时长（秒） | 10 | 60 |
| CPU_MAX_PRIME | 最大素数（越大测试越复杂） | 20000 | 100000 |
| CPU_THREADS | 测试线程数（0 表示自动） | 0 | 4 |

**CPU_MAX_PRIME 含义**：CPU 测试通过计算素数来评估性能，值越大计算越复杂，测试持续时间越长，能更充分测试 CPU 性能。

#### 内存测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| MEMORY_ENABLED | 是否启用内存测试 | true | true/false |
| MEMORY_DURATION | 测试时长（秒） | 10 | 60 |
| MEMORY_BLOCK_SIZE | 内存块大小 | "8K" | "4K", "16K" |
| MEMORY_TOTAL_SIZE | 测试总内存大小 | "20G" | "10G", "50G" |
| MEMORY_OPER | 内存操作类型 | "read" | "read", "write" |
| MEMORY_THREADS | 测试线程数 | 10 | 20 |

**MEMORY_OPER 支持值**：
- `read`：只读测试
- `write`：只写测试

#### IO 测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| IO_ENABLED | 是否启用 IO 测试 | true | true/false |
| IO_TOOL | IO 测试工具 | "sysbench" | "sysbench", "fio" |
| IO_DURATION | 测试时长（秒） | 10 | 600 |
| IO_TOTAL_SIZE | 测试文件总大小 | "100M" | "1G", "10G" |
| IO_TEST_MODE | 测试模式 | "rndrw" | "read", "write", "rndrd", "rndwr", "rndrw" |
| IO_FILE_NUM | 测试文件数量 | 1 | 10 |
| IO_BLOCK_SIZE | 块大小 | "16K" | "4K", "64K" |
| IO_THREADS | 测试线程数 | 4 | 8 |

#### 线程测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| THREADS_ENABLED | 是否启用线程测试 | true | true/false |
| THREADS_DURATION | 测试时长（秒） | 10 | 60 |
| THREADS_NUM | 线程数量 | 100 | 1000 |
| THREAD_YIELDS | 线程让出 CPU 次数（越大上下文切换越多） | 100 | 500 |
| THREAD_LOCKS | 共享锁数量（越大竞争越激烈） | 4 | 8 |

#### 互斥锁测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| MUTEX_ENABLED | 是否启用互斥锁测试 | true | true/false |
| MUTEX_DURATION | 测试时长（秒） | 10 | 60 |
| MUTEX_NUM | 互斥锁数量 | 1024 | 2048 |
| MUTEX_THREADS | 测试线程数 | 100 | 500 |

#### 网络测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| NETWORK_ENABLED | 是否启用网络测试 | true | true/false |
| NETWORK_TOOL | 网络测试工具 | "iperf3" | "iperf3" |
| NETWORK_MODE | 测试模式 | "single" | "single", "multi-server" |
| NETWORK_DURATION | 测试时长（秒） | 20 | 60 |
| NETWORK_PORT | 测试端口 | 25201 | 5201 |
| NETWORK_PROTOCOL | 网络协议 | "tcp" | "tcp", "udp" |
| NETWORK_PARALLEL | 并行连接数 | 1 | 4 |
| NETWORK_SERVER_IP | 服务器 IP（空值自动检测） | "" | "192.168.1.100" |
| NETWORK_CLIENT_IP | 客户端 IP（空值使用服务器 IP，支持多个 IP 空格分隔） | "" | "192.168.1.101 192.168.1.102" |

**NETWORK_MODE 说明**：
- `single`：单服务器模式，支持多客户端 IP（通过 NETWORK_CLIENT_IP 配置）
- `multi-server`：多服务器分布式测试，需要配置 SERVERS 和 TEST_SCENARIOS

### 自定义配置示例

编辑配置文件（如 `config/quick.conf`）：

```bash
# CPU 测试
CPU_ENABLED=true
CPU_DURATION=60
CPU_MAX_PRIME=100000
CPU_THREADS=0  # 自动检测

# 内存测试
MEMORY_ENABLED=true
MEMORY_DURATION=30
MEMORY_OPER="write"  # 测试写性能
MEMORY_THREADS=20

# IO 测试
IO_ENABLED=true
IO_TOOL="fio"
IO_DURATION=600
IO_TOTAL_SIZE="10G"
IO_FILE_NUM=10

# 网络测试
NETWORK_ENABLED=true
NETWORK_CLIENT_IP="192.168.1.101 192.168.1.102"  # 多客户端测试
```

## 输出指标说明

### CPU 测试
- **events/sec**：每秒执行事件数（越高越好）
- **avg latency**：平均延迟（越低越好）
- **P95/P99 latency**：95/99 百分位延迟（越低越好）

### 内存测试
- **operations/sec**：每秒内存操作数（越高越好）
- **throughput**：内存吞吐量 MB/s（越高越好）
- **avg latency**：平均延迟（越低越好）

### IO 测试
- **IOPS**：每秒 IO 操作数（越高越好）
- **Bandwidth**：吞吐量 MB/s（越高越好）
- **Latency P50/P95/P99**：延迟分布（越低越好）

### 网络测试
- **Bandwidth**：网络带宽 Mbps（越高越好）
- **Jitter**：网络抖动 ms（越低越好）
- **Packet Loss**：丢包率 %（越低越好）

### 线程测试
- **events/sec**：每秒线程事件数（越高越好）
- **latency**：线程调度延迟（越低越好）

### 互斥锁测试
- **transactions**：事务数（越高越好）
- **TPS**：每秒事务数（越高越好）
- **latency**：锁等待延迟（越低越好）

## 依赖工具说明

| 工具 | 必选 | 用途 | 安装命令 |
|------|------|------|----------|
| sysbench | 是 | CPU/内存/IO/线程/锁测试 | `yum install -y sysbench` |
| fio | 生产模式 | 专业 IO 压测 | `yum install -y fio` |
| iperf3 | 生产模式 | 网络吞吐测试 | `yum install -y iperf3` |
| jq | 推荐 | JSON 结果解析 | `yum install -y jq` |
| bc | 可选 | 数值计算 | `yum install -y bc` |

## 常见问题

### Q1: 测试需要 root 权限吗？
**A**: 部分测试（如 direct IO）需要 root 权限，建议使用 `sudo` 运行：
```bash
sudo ./vb_benchmark -m production
```

### Q2: 测试会删除数据吗？
**A**: 测试文件仅写入指定目录（默认 `/tmp`），测试完成后可自动清理。建议指定 `IO_TEST_PATH` 到独立测试分区。

### Q3: 如何自定义 IO 测试路径？
**A**: 编辑配置文件，设置 `IO_TEST_PATH`：
```bash
IO_TEST_PATH="/data/vastbase_benchmark"
```

### Q4: 网络测试如何配置服务器 IP？
**A**: 在配置文件中设置 `NETWORK_SERVER_IP`：
```bash
NETWORK_SERVER_IP="192.168.1.100"
```

### Q5: 多服务器网络测试如何使用？
**A**: 配置 SSH 免密登录，然后设置：
```bash
NETWORK_MODE="multi-server"
SERVERS="192.168.1.100:server:db_master,192.168.1.110:client:app_server"
TEST_SCENARIOS="192.168.1.110:192.168.1.100:60"
```

### Q6: 为什么 fio 测试结果与 sysbench fileio 差异很大？
**A**: fio 是专业 IO 压测工具，配置更灵活（direct=1、libaio 引擎），结果更接近数据库真实负载。sysbench fileio 适合快速测试，不建议用于生产环境评估。

### Q7: 如何解读 P95/P99 延迟？
**A**: P95 延迟表示 95% 的请求延迟低于该值，P99 表示 99% 的请求延迟低于该值。对于数据库来说，P99 延迟比平均延迟更重要，因为它反映了长尾延迟问题。

## 报告示例

```
================================================================================
                    Vastbase System Benchmark Report
================================================================================

基本信息
--------
测试模式：production
测试时间：2026-04-14_10:30:00
主机名：db-server-01
CPU 核心数：8
内存大小：32768 MB

================================================================================
                           测试结果汇总
================================================================================

[CPU 测试]
  事件/秒：    15234.56
  平均延迟：   3.2ms
  P95 延迟：   4.5ms
  P99 延迟：   6.8ms

[内存测试]
  操作/秒：    8765.43
  传输量：     10240 MB
  平均延迟：   1.2ms

[IO 测试]
  测试工具：  fio

  [randread]
    读 IOPS:      45000
    写 IOPS:      0
    读带宽：     350 MB/s
    读 P95 延迟：120000 ns

  [randwrite]
    读 IOPS:      0
    写 IOPS:      32000
    读带宽：     0 MB/s
    写 P95 延迟：150000 ns

  [mixed_rw]
    读 IOPS:      38000
    写 IOPS:      16000
    读带宽：     295 MB/s
    读 P95 延迟：135000 ns

[网络测试]
  带宽：       950.5 Mbps
  抖动：       0.15 ms
  丢包率：     0.00%

[线程测试]
  事件/秒：    5678.90
  平均延迟：   2.1ms
  P95 延迟：   3.2ms

[互斥锁测试]
  事务数：     123456
  事务/秒：    2054.32
  平均延迟：   1.8ms
  P95 延迟：   2.5ms

================================================================================
```

## 项目结构

```
vb_benchmark/
├── vb_benchmark              # 主入口脚本
├── lib/                      # 库函数模块
│   ├── config.sh            # 配置解析
│   ├── utils.sh             # 通用工具
│   ├── env_checker.sh       # 环境检测
│   ├── cpu_test.sh          # CPU 测试
│   ├── mem_test.sh          # 内存测试
│   ├── io_test.sh           # IO 测试
│   ├── net_test.sh          # 网络测试
│   ├── threads_test.sh      # 线程测试
│   ├── mutex_test.sh        # 互斥锁测试
│   ├── result_parser.sh     # 结果解析
│   └── report.sh            # 报告生成
├── config/                   # 配置文件
│   ├── quick.conf           # 快速模式
│   ├── production.conf      # 生产模式
│   └── deep.conf            # 深度模式
├── output/                   # 测试结果
│   ├── reports/             # 报告文件
│   ├── logs/                # 日志文件
│   └── data/                # 原始数据
└── README.md                # 使用说明
```

## 最佳实践

1. **测试环境**：在独立测试环境运行，避免影响生产业务
2. **测试时长**：生产环境建议使用 production 模式，至少运行 30 分钟
3. **IO 测试路径**：使用数据库数据目录所在分区，结果更具参考价值
4. **历史对比**：定期运行测试，保存 JSON 报告用于历史趋势分析
5. **多机测试**：网络压测前配置好 SSH 免密登录
6. **结果解读**：重点关注 P95/P99 延迟，而非仅看平均值

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**版本**: v1.0.0  
**创建日期**: 2026-04-14  
**维护团队**: Vastbase 性能诊断与自动化运维团队
