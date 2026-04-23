# 数据库系统基准测试工具

一个为 Vastbase、openGauss 和 PostgreSQL 数据库设计的系统级性能基准测试工具，支持全面的性能测试，帮助评估服务器硬件性能边界。

## 特性

- ✅ **一键执行**：自动化完成 CPU/内存/IO/网络/线程/锁测试，无需手动配置
- ✅ **最小依赖**：基础模式仅需 sysbench，其他工具（fio、iperf3）为可选
- ✅ **多工具支持**：IO 测试支持 sysbench 和 fio，可根据需要选择
- ✅ **多服务器支持**：网络压测支持多 IP 配置（需 SSH 免密），可测试集群网络性能
- ✅ **详细报告**：生成结构化测试报告，包含系统信息、测试配置和详细指标
- ✅ **远程分发**：自动编译和分发 sysbench 到远程服务器，降低额外安装影响
- ✅ **多种网络模式**：支持串行、并行和矩阵网络测试模式
- ✅ **结果分析**：生成多服务器对比报告，便于性能分析和问题定位

## 项目结构

```
vb_benchmark/
├── vb_benchmark              # 主入口脚本
├── output/                   # 测试结果输出目录
├── tools/
│   └── skill.md              # 开发规范文档
├── README.md                 # 中文文档（默认）
└── README.en.md              # 英文文档
```

## 快速开始

### 1. 安装依赖

#### 基础依赖（必选）

```bash
# CentOS/RHEL
sudo yum install -y sysbench

# Ubuntu/Debian
sudo apt-get install -y sysbench
```

#### 完整依赖（推荐）

```bash
# CentOS/RHEL
sudo yum install -y sysbench fio iperf3 jq

# Ubuntu/Debian
sudo apt-get install -y sysbench fio iperf3 jq
```

### 2. 支持的数据库

- ✅ **Vastbase**：华为企业级数据库
- ✅ **openGauss**：开源关系型数据库
- ✅ **PostgreSQL**：开源对象关系型数据库

### 3. 运行测试

#### 基本用法

```bash
./vb_benchmark
```

#### 命令行参数覆盖

```bash
# 覆盖测试时长
./vb_benchmark DURATION=60

# 覆盖 CPU 最大素数
./vb_benchmark CPU_MAX_PRIME=10000

# 禁用特定测试
./vb_benchmark MEMORY_ENABLED=false NETWORK_ENABLED=false

# 使用 fio 进行 IO 测试
./vb_benchmark IO_TOOL=fio

# 设置 fio 测试时长和目录
```

#### 运行特定测试（子命令）

```bash
# 运行 CPU 测试
./vb_benchmark cpu

# 运行内存测试
./vb_benchmark mem

# 运行 IO 测试
./vb_benchmark io

# 运行网络测试（矩阵模式）
./vb_benchmark network -f servers.txt NETWORK_MODE=matrix

# 运行线程测试
./vb_benchmark thread

# 运行互斥锁测试
./vb_benchmark mutex

# 运行系统检查（依赖项、权限、磁盘空间、网络）
./vb_benchmark check

# 运行所有测试（默认）
./vb_benchmark all
```

#### 子命令与参数组合使用

```bash
# 运行 CPU 测试并指定参数
./vb_benchmark cpu DURATION=20 CPU_MAX_PRIME=10000

# 运行 IO 测试并使用 fio
./vb_benchmark io IO_TOOL=fio FIO_DURATION=30

# 运行网络测试并指定服务器列表
./vb_benchmark network -f "192.168.1.101 192.168.1.102" NETWORK_MODE=parallel

# 矩阵网络测试（全矩阵交叉测试）
./vb_benchmark -f servers.txt NETWORK_MODE=matrix

# 高级用法
# 运行系统检查并指定测试目录
./vb_benchmark -f servers.txt check IO_TEST_PATH='/home/vastbase/vb_test'
# 同时运行多个测试并指定参数
./vb_benchmark cpu mem -f servers.txt DURATION=2 THREADS=4
# 运行 IO 测试并使用 fio 工具和自定义参数
./vb_benchmark io -f servers.txt IO_TOOL=fio IO_TEST_MODE=read IO_TOTAL_SIZE=10G
```

#### 安装 sysbench

本工具支持自动编译和分发 sysbench 到远程服务器，降低最小额外安装影响。

**本机编译拷贝远程服务器方式**：
1. **自动编译**：如果本机没有 `$HOME/sysbench` 目录，会自动下载并编译 sysbench
2. **打包分发**：将编译好的 sysbench 打包并通过 SCP 分发到远程服务器
3. **最小影响**：无需在远程服务器上安装编译依赖，只需 SSH 免密登录即可

**安装命令**：

单机安装：
```bash
./vb_benchmark -i
```

多机器安装（从服务器列表文件）：
```bash
./vb_benchmark -i -f servers.txt
```

多机器安装（直接指定 IP 列表）：
```bash
./vb_benchmark -i -f "192.168.1.101 192.168.1.102 192.168.1.103"
```

**安装逻辑**：

| 场景 | 行为 |
|------|------|
| 本机在 IP 列表中且无 `$HOME/sysbench` | 先编译，再分发 |
| 本机有 `$HOME/sysbench` 目录 | 跳过编译，直接打包分发 |
| 本机不在 IP 列表中 | 所有服务器都需要分发（从本地已有目录） |
| SCP 分发 | 自动排除本机器 IP |

**执行方式**：
- **本地执行**：直接使用当前目录下的 `vb_benchmark` 脚本
- **远程执行**：通过 SSH 调用远程服务器上的 `$HOME/sysbench/vb_benchmark` 脚本

**优势**：
- 无需在远程服务器上安装编译工具和依赖
- 统一的 sysbench 版本，确保测试结果的一致性
- 降低对远程服务器的影响，无需修改系统配置
- 自动配置环境变量，使用方便

**注意事项**：
- `$HOME/sysbench` 目录会自动创建，若已存在则跳过编译过程
- 多机器安装时，若本机在 IP 列表中且没有 `$HOME/sysbench` 目录，会先编译再分发
- SCP 分发时会自动排除本机器 IP
- 目标服务器需要配置 SSH 免密登录
- 安装完成后会自动配置环境变量并生效

#### 干运行模式

```bash
./vb_benchmark -d
```

### 4. 查看报告

```bash
ls -lh output/
cat output/report_benchmark_*.txt
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
- **Latency**：延迟（越低越好）

### 网络测试

- **Bandwidth**：网络带宽 MB/s（越高越好）

### 线程测试

- **events/sec**：每秒线程事件数（越高越好）
- **latency**：线程调度延迟（越低越好）

### 互斥锁测试

- **transactions**：事务数（越高越好）
- **TPS**：每秒事务数（越高越好）
- **latency**：锁等待延迟（越低越好）

### pgbench 测试

- **TPS**：每秒事务数（越高越好）
- **latency average**：平均延迟（越低越好）

## 依赖工具说明

| 工具       | 必选 | 用途               | 安装命令                      |
| -------- | -- | ---------------- | ------------------------- |
| sysbench | 是  | CPU/内存/IO/线程/锁测试 | `yum install -y sysbench` |
| fio      | 可选 | 专业 IO 压测         | `yum install -y fio`      |
| iperf3   | 可选 | 网络吞吐测试           | `yum install -y iperf3`   |
| jq       | 推荐 | JSON 结果解析        | `yum install -y jq`       |

## 常见问题

### Q1: 测试需要 root 权限吗？

**A**: 部分测试（如 direct IO）需要 root 权限，建议使用 `sudo` 运行

### Q2: 测试会删除数据吗？

**A**: 测试文件仅写入指定目录（默认 `/tmp`），测试完成后可自动清理

### Q3: 如何自定义 IO 测试路径？

**A**: 使用 `IO_TEST_PATH` 参数：`./vb_benchmark IO_TEST_PATH=/data`

### Q4: 网络测试如何配置多客户端？

**A**: 创建服务器列表文件 `servers.txt`，包含所有需要测试的 IP 地址，然后使用 `-f` 参数指定：

```bash
./vb_benchmark network -f servers.txt
```

### Q5: NETWORK_MODE 和 NETWORK_PARALLEL 参数的区别是什么？

**A**:
- **NETWORK_MODE**：控制多个客户端测试的执行方式
  - `serial`：逐个执行客户端测试，一个完成后再开始下一个
  - `parallel`：同时执行所有客户端测试
  - `matrix`：执行全矩阵交叉测试（每对服务器之间都进行测试）

- **NETWORK_PARALLEL**：控制每个 iperf3 测试的并行连接数，在所有模式下都生效
  - 例如：`NETWORK_PARALLEL=4` 表示每个测试使用 4 个并行连接

**示例**：
```bash
# 串行执行，每个测试使用 4 个并行连接
./vb_benchmark network -f servers.txt NETWORK_MODE=serial NETWORK_PARALLEL=4

# 并行执行，每个测试使用 4 个并行连接
./vb_benchmark network -f servers.txt NETWORK_MODE=parallel NETWORK_PARALLEL=4
```

## 最佳实践

1. **测试环境**：在独立测试环境运行，避免影响生产业务
2. **测试时长**：生产环境建议使用较长的测试时长（如 60 秒以上）
3. **IO 测试路径**：使用数据库数据目录所在分区，结果更具参考价值
4. **历史对比**：定期运行测试，保存报告用于历史趋势分析
5. **多机测试**：网络压测前配置好 SSH 免密登录
6. **结果解读**：重点关注 P95/P99 延迟，而非仅看平均值
7. **参数调整**：根据服务器配置调整测试参数，如线程数应与 CPU 核心数匹配

## 许可证

本项目采用 GNU General Public License v3.0 许可证。

## 版本历史

| 标签    | 日期         | 变更                                                 |
| ----- | ---------- | -------------------------------------------------- |
| 0.5.0 | 2026-04-21 | 修复远程执行路径问题，添加 SSH 免密登录检查，改进 IO 测试路径管理，支持任意服务器列表文件分发，添加 check 命令支持，优化检查输出详细信息，支持多子命令同时执行，分离检查和压测逻辑，添加 DEBUG 模式 |
| 0.4.0 | 2026-04-21 | 重构命令行参数，添加子命令支持（cpu/mem/io/network/thread/mutex/all），优化帮助信息显示，分类展示测试参数 |
| 0.3.0 | 2026-04-20 | 支持通过 -f 服务器IP列表控制本地机器是否参与压测，若本机器不在IP列表中则不参与压测；支持编译和scp到目标集群服务器列表 |
| 0.2.0 | 2026-04-17 | 重构移除 lib 目录，将所有函数合并到主脚本，添加命令行参数支持及覆盖功能，更新文档为中英文双版本 |
| 0.1.0 | 2026-04-16 | 初始版本，包含基本基准测试功能                                    |

***

**创建日期**: 2026-04-17
**维护团队**: Vastbase 二线团队
