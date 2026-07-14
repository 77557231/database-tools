# oscheckperf - 系统性能基准测试工具

**oscheckperf** 是一款专为数据库场景设计的系统级性能基准测试工具，支持 **CPU、内存、磁盘 IO、网络、线程、互斥锁** 六大核心维度的一键压测。适用于性能分析、POC 选型、上线前系统规格检查、性能回归验证等场景，支持单机和多机部署，提供快速、统一的硬件性能评估能力。

## 快速开始

### 1. 安装依赖

**方式一：工具自动编译安装（推荐）**

**编译安装说明**：

编译安装仅需在\*\*编译机（脚本所在服务器）上安装编译依赖，其它远程服务器无需安装编译工具，工具会自动推送到多机。

> **重要**：必须先手动安装编译依赖库：
>
> - CentOS/RHEL: `yum install -y automake autoconf libtool gcc make libaio-devel pkg-config`
> - Ubuntu/Debian: `apt-get install -y automake autoconf libtool libtool-bin gcc make libaio-dev pkg-config`

**编译安装组件**

```bash
# 单机时使用 -i 参数编译安装（使用本地离线安装包，无需联网）
# -i all: 删除旧目录并重新编译所有组件
./oscheckperf -i all

# -i oscheckperf: 仅更新 oscheckperf 脚本
./oscheckperf -i oscheckperf

# 多机时自动编译并分发到远程服务器（无需 root 权限）
./oscheckperf -i all -f server_list
./oscheckperf -i oscheckperf -f server_list
```

**编译包推送时发行版兼容策略**

默认情况下，工具采用宽松模式进行发行版兼容性检查，**直接检测包管理系统**：

- **RPM 系**：自动检测 `rpm`/`yum`/`dnf` 包管理器
- **DEB 系**：自动检测 `dpkg`/`apt` 包管理器

严格模式：要求远程服务器发行版与本地完全匹配，STRICT\_DISTRO\_CHECK=true

| 模式       | 参数值     | Centos→Kylin | CentOS→Ubuntu | Ubuntu→Debian |
| -------- | ------- | ------------ | ------------- | ------------- |
| 宽松模式（默认） | `false` | ✅ 允许         | ❌ 拒绝          | ✅ 允许          |
| 严格模式     | `true`  | ❌ 拒绝         | ❌ 拒绝          | ❌ 拒绝          |

**方式二：直接安装依赖包**

#### CentOS 系统为例

```bash
# 基础安装包
yum install -y sysbench iperf3 fio jq

# 非免密环境需额外安装
yum install -y sshpass

# 扩展查看更多硬件资源安装
yum install ethtool numactl
```

### 2. 运行测试

```bash
#命令行必须指定测试类型参数
#单机运行
# 单机运行，例如：
./oscheckperf cpu           # 仅 CPU 测试
./oscheckperf cpu mem io    #  MEM和IO 测试
./oscheckperf network       # 仅网络测试
# 参数和配置文件同时配置时，参数优先级大于配置文件
./oscheckperf -p parameter.conf cpu

#多机运行
# 检查模式配合调试
./oscheckperf check -f server_list 
# 指定子命令和参数
./oscheckperf io IO_PATH=/data/io_test -f server_list
# 网络测试指定服务器列表(相同选项中参数优先级大于配置文件)
./oscheckperf network -f server_list -p parameter.conf
```

### 3. 服务器认证方式

#### 方式一：SSH 免密登陆

**服务器列表文件格式**：

```bash
# server_list 文件内容
192.168.1.101
192.168.1.102
192.168.1.103
```

#### 方式二：密码认证

**服务器列表文件格式**：

```bash
# server_list 文件内容（格式：IP username password，支持多空格或 tab 分隔）
# 密码可以包含任意特殊字符（包括冒号）
192.168.1.101 username secret123 
192.168.1.102 username secret123 
192.168.1.103 username secret123
```

**运行测试**：

```bash
./oscheckperf network -f server_list
```

### 4. 自定义 SSH 端口

```bash
# 方法一：配置文件里设置SSH_PORT=2222
./oscheckperf network -f server_list -p parameter.conf

# 方法二：直接使用参数
./oscheckperf network -f server_list SSH_PORT=2222
```

### 5. 干运行模式（预览底层运行的原始命令，不实际执行）

```bash
# 预览指定测试命令
./oscheckperf io --dry-run

# 预览网络测试命令
./oscheckperf network -f server_list --dry-run
```

### 6. 输出与报告

#### 查看测试结果

测试完成后，`output` 目录下生成三类文件：

| 文件类型       | 路径                              | 说明          | 用途        |
| :--------- | :------------------------------ | :---------- | :-------- |
| **原始测试数据** | `output/original_data_*.log`    | 所有测试的完整原始输出 | 问题排查、追溯   |
| **命令输出结果** | `output/data_*.log`             | 结构化的测试结果    | 数据处理、二次分析 |
| **最终报告**   | `output/report_benchmark_*.log` | 格式化的性能报告    | 直接查看、分享   |

#### 生成 HTML 评估报告

```bash
# 执行测试后自动生成 HTML 报告
./oscheckperf -f server_list IO_PATH=/data/io_test all --report

```

#### 多报告对比

```bash
# 比较两个报告文件
python3 tools/SKILL/report_eval.py \
  output/report_benchmark_xxx.log \
  output/report_benchmark_yyy.log \
  -o output
```

#### 报告说明

| 报告类型    | 文件位置                                     | 说明           |
| ------- | ---------------------------------------- | ------------ |
| HTML 报告 | `output/report_eval_<timestamp>.html`    | 单报告评估（含智能分析） |
| 对比报告    | `output/report_compare_<timestamp>.html` | 多报告对比（含智能分析） |

- HTML 报告包含：CPU、内存、磁盘 IO、线程、网络性能评估，智能分析报告
- 阈值判断：基于预定义的基线值进行达成率评估

## 常用参数

#### sysbench 参数

| 参数                     | 默认值                       | 说明                                                        |
| ---------------------- | ------------------------- | --------------------------------------------------------- |
| `SYSBENCH_PROFILES`    | `seqrd seqwr rndrd rndwr` | sysbench 测试模式，空格分隔（seqwr/seqrewr/seqrd/rndrd/rndwr/rndrw） |
| `SYSBENCH_FILE_NUM`    | `4`                       | sysbench 测试文件数量                                           |
| `SYSBENCH_BLOCK_SIZE`  | `16K`                     | sysbench 块大小                                              |
| `SYSBENCH_IO_MODE`     | `sync`                    | sysbench IO 模式（sync/async）                                |
| `SYSBENCH_EXTRA_FLAGS` | `direct`                  | sysbench 额外标志（direct/sync）                                |
| `SYSBENCH_THREADS`     | `4`                       | sysbench 线程数（设置为0时自动使用CPU核心数）                             |
| `SYSBENCH_DURATION`    | `DURATION`                | sysbench IO 测试时长                                          |

#### fio 参数

| 参数             | 默认值                             | 说明                                                                             |
| -------------- | ------------------------------- | ------------------------------------------------------------------------------ |
| `FIO_PROFILES` | `read write randread randwrite` | fio 测试模式，空格分隔（read/write/randread/randwrite/rw/randrw/trim/randtrim/trimwrite） |
| `FIO_BS`       | `128K 128K 4K 4K`               | fio 块大小，支持多值配置（与FIO\_PROFILES一一对应）；单值时应用于所有profile（参考阿里云块存储测试规范）               |
| `FIO_IODEPTH`  | `128 128 32 32`                 | fio I/O 深度，支持多值配置（与FIO\_PROFILES一一对应）；单值时应用于所有profile（参考阿里云块存储测试规范）            |
| `FIO_NUMJOBS`  | `1 1 4 4`                       | fio 工作线程数，支持多值配置（与FIO\_PROFILES一一对应）；单值时应用于所有profile；设置为0时自动使用CPU核心数           |
| `FIO_DIRECT`   | `1`                             | fio 直接 I/O 模式                                                                  |
| `FIO_NRFILES`  | `1`                             | fio 测试文件数量（模拟多数据文件场景）                                                          |
| `FIO_IOENGINE` | `libaio`                        | fio IO 引擎（libaio/sync/posixaio）                                                |
| `FIO_DURATION` | `DURATION`                      | fio 测试时长                                                                       |

**多值参数映射说明**：`FIO_BS`、`FIO_IODEPTH`、`FIO_NUMJOBS` 支持空格分隔的多值配置，按索引与 `FIO_PROFILES` 一一对应。例如默认配置：

- `FIO_PROFILES="read write randread randwrite"`
- `FIO_BS="128K 128K 4K 4K"` → read用128K，write用128K，randread用4K，randwrite用4K
- 如果参数值数量少于profile数量，不足部分使用第一个值

#### Threads 参数

| 参数               | 默认值              | 说明                                  |
| ---------------- | ---------------- | ----------------------------------- |
| `THREADS_NUM`    | `auto (cores*4)` | 线程数（未设置时自动根据 CPU 核心数计算，公式：cores\*4） |
| `THREADS_YIELDS` | `1000`           | 每个线程的 yield 次数                      |
| `THREADS_LOCKS`  | `8`              | 锁数量                                 |

#### Memory 参数

| 参数                  | 默认值          | 说明                               |
| ------------------- | ------------ | -------------------------------- |
| `MEMORY_THREADS`    | `0`          | 内存测试线程数，0=自动（与CPU核心数一致）          |
| `MEMORY_BLOCK_SIZE` | `8K`         | 内存测试块大小                          |
| `MEMORY_TOTAL_SIZE` | `0`          | 内存测试总大小（测试数据量），0=自动（使用系统总内存的60%） |
| `MEMORY_OPER`       | `read write` | 内存操作类型                           |

#### Mutex 参数

| 参数              | 默认值    | 说明            |
| --------------- | ------ | ------------- |
| `MUTEX_THREADS` | `0`    | 互斥锁测试线程数，0=自动 |
| `MUTEX_NUM`     | `1024` | 互斥锁数量         |

#### CPU 参数

| 参数              | 默认值     | 说明                        |
| --------------- | ------- | ------------------------- |
| `CPU_THREADS`   | `0`     | CPU 测试线程数，0=自动（与CPU核心数一致） |
| `CPU_MAX_PRIME` | `20000` | CPU 测试最大质数（越大测试越耗时）       |

#### 通用参数

| 参数                     | 默认值                         | 说明                                                                      |
| ---------------------- | --------------------------- | ----------------------------------------------------------------------- |
| `DURATION`             | `90`                        | 统一测试时长（秒）                                                               |
| `OUTPUT_DIR`           | `./output`                  | 测试结果输出目录                                                                |
| `SSH_PORT`             | `22`                        | 远程服务器 SSH 端口                                                            |
| `REPORT_HARDWARE_INFO` | `true`                      | 报告中是否包含硬件信息（true/false）                                                 |
| `IO_PATH`              | `$HOME/oscheckperf/io_test` | 测试文件目录，默认`$HOME/oscheckperf/io_test`                                    |
| `IO_TOTAL_SIZE`        | 动态计算（剩余空间的70%，最小1G，最大100G）  | 测试文件总大小（sysbench 和 fio 通用），默认根据 IO\_PATH 对应文件系统剩余空间的70%动态计算，最小1G，最大100G |
| `IO_TOOL`              | `fio`                       | IO 测试工具（sysbench/fio）                                                   |

#### 网络测试参数

| 参数                 | 默认值        | 说明                         |
| ------------------ | ---------- | -------------------------- |
| `NETWORK_PARALLEL` | `4`        | 网络测试并行连接数（iperf3 的 -P 参数）  |
| `NETWORK_PORT`     | `25201`    | 网络测试端口，支持单端口或端口范围（如 25201-25210） |
| `NETWORK_MODE`     | `matrix`   | 网络测试模式（serial/matrix）      |
| `NETWORK_DURATION` | `DURATION` | 网络测试时长（秒），未设置时使用全局DURATION |

**NETWORK_PORT 端口格式说明**：

- **单端口模式**（默认）：`NETWORK_PORT=25201`
  - 网络矩阵模式下，每个batch自动递增端口：Batch 1 → 25201, Batch 2 → 25202, Batch 3 → 25203, ...
  - 适用于端口资源充足的环境

- **端口范围模式**：`NETWORK_PORT=25201-25210`
  - 端口在指定范围内循环复用：Batch 1 → 25201, ..., Batch 10 → 25210, Batch 11 → 25201 (循环)
  - 适用于端口资源受限或需要严格控制防火墙规则的环境
  - 建议端口范围数量 ≥ batch数量，以避免TIME_WAIT导致的端口冲突

#### 参数说明

**FIO\_FILE\_NUM 说明**：

- 设置测试文件数量，默认为 4
- 当配置 `FIO_FILE_NUM` 时，每个文件大小 = `IO_TOTAL_SIZE / FIO_FILE_NUM`
- 例如：`IO_TOTAL_SIZE=1G`，`FIO_FILE_NUM=4` → 每个文件 256M

## 输出指标说明

### CPU 测试

- **events/sec**：每秒执行事件数（越高越好）
- **Avg Latency**：平均延迟（越低越好）
- **Min Latency**：最小延迟（越低越好）
- **P95 Latency**：95 百分位延迟（越低越好）
- **P99 Latency**：99 百分位延迟（越低越好）
- **Max Latency**：最大延迟（越低越好）
- **Sum Latency**：累计延迟（越低越好）
- **Threads fairness (events)**：线程事件公平性（格式为 avg/stddev，stddev 越小表示分布越均匀）
- **Threads fairness (execution time)**：线程执行时间公平性

### 内存测试

- **Total operations**：总操作数
- **operations/sec**：每秒内存操作数（越高越好）
- **Transferred**：实际传输数据量（MiB）
- **throughput**：内存吞吐量 MiB/s（越高越好）
- **Avg Latency**：平均延迟（越低越好）
- **Min Latency**：最小延迟（越低越好）
- **Max Latency**：最大延迟（越低越好）
- **P95 Latency**：95 百分位延迟（越低越好）
- **Sum Latency**：累计延迟（越低越好）

### IO 测试（sysbench）

- **Read IOPS**：每秒读操作数（越高越好）
- **Write IOPS**：每秒写操作数（越高越好）
- **Total IOPS**：每秒总 IO 操作数（越高越好）
- **fsyncs/s**：每秒 fsync 操作数（衡量同步写入性能）
- **Read BW**：读吞吐量 MB/s（越高越好）
- **Write BW**：写吞吐量 MB/s（越高越好）
- **Total BW**：总吞吐量 MB/s（越高越好）
- **Avg Latency**：平均延迟（越低越好）
- **Min/Max Latency**：最小/最大延迟（越低越好）
- **P95/P99 Latency**：95/99 百分位延迟（越低越好）
- **Threads fairness**：线程公平性（events/execution time）

### IO 测试（fio）

- **Read/Write IOPS**：每秒读/写操作数（越高越好）
- **Read/Write BW**：读/写吞吐量 MB/s（越高越好）
- **Avg Latency**：平均延迟（越低越好）
- **Min/Max/P95/P99 Latency**：最小/最大/95/99 百分位延迟（越低越好）
- **Device utilization**：设备利用率（%）
- **CPU user/system**：CPU 用户态/系统态利用率（%）
- **bw\_min/bw\_max**：最小/最大带宽（反映带宽稳定性）
- **slat/clat**：提交延迟/完成延迟（slat 指 IO 提交到设备的时间，clat 指设备处理完成的时间）
- **ctx/majf/minf**：上下文切换/主要页错误/次要页错误（反映系统资源使用情况）
- **iodepth\_level**：IO 队列深度级别（反映 IO 并发程度）

### 网络测试

- **Bandwidth (MB/s)**：网络带宽（越高越好）
- **Retrans**：TCP 重传次数（越少越好）
- **RTT(ms)**：往返时间（格式：平均值 (Min: 最小值, Max: 最大值)）
- **CPU(%)**：发送端/接收端 CPU 利用率（格式：senderCPU%/receiverCPU%）

### 线程测试

- **total number of events**：总事件数
- **total time**：总耗时（秒）
- **Events/sec**：每秒线程事件数（越高越好）
- **Avg Latency**：平均延迟（越低越好）
- **Min Latency**：最小延迟（越低越好）
- **Max Latency**：最大延迟（越低越好）
- **P95 Latency**：95 百分位延迟（越低越好）
- **Sum Latency**：累计延迟（越低越好）
- **Threads fairness (events)**：线程事件公平性（格式 avg/stddev）

### 互斥锁测试

- **total number of events**：总事件数
- **total time**：总耗时（秒）
- **Transactions**：事务数（越高越好）
- **TPS**：每秒事务数（越高越好）
- **Avg Latency**：平均延迟（越低越好）
- **Min Latency**：最小延迟（越低越好）
- **Max Latency**：最大延迟（越低越好）
- **P95 Latency**：95 百分位延迟（越低越好）
- **Sum Latency**：累计延迟（越低越好）

## 场景示例

### IO场景测试

```bash
# 使用默认配置一键压测四个核心指标（参考阿里云官方测试规范）
# read/write: bs=128K, iodepth=128, numjobs=1（测试吞吐量）
# randread/randwrite: bs=4K, iodepth=32, numjobs=4（测试IOPS）
./oscheckperf io 

# 自定义多值参数（与profile一一对应）
./oscheckperf io IO_TOOL=fio FIO_PROFILES="randread read" FIO_BS="4K 256K" FIO_IODEPTH="64 256"

# 自定义测试参数（部分参数多值，部分参数单值）
./oscheckperf io IO_TOOL=fio FIO_PROFILES="randread read" FIO_BS="4K 128K" FIO_NUMJOBS=8
```

### 多服务器网络测试

- `serial`：串行模式，使用server\_list文件IP列表中第一个主机作为服务器，其余主机作为客户端依次测试
  - 支持本地和远程服务器（自动检测）
  - 第一个主机为本机时直接执行，无需SSH开销
- `matrix`：执行全矩阵交叉测试（每对服务器之间都进行测试）
  - **自动分批并行**：当主机数 > 3 时，自动启用分批并行执行
  - **并行度**：自动计算为 `floor(主机数 / 2)`，无需手动配置
  - **批次内**：多个主机对同时测试，使用相同端口
  - **批次间**：顺序执行，每个batch使用不同端口（防止TIME_WAIT冲突）
  - **端口分配**：默认单端口模式下，端口自动递增（25201, 25202, 25203...）；端口范围模式下，端口循环复用

| 主机数 | batch并行度 | 总测试对 | 总批次数 | 所需端口数 |
| --- | -------- | ---- | ---- | ----- |
| 2   | 1        | 1    | 1    | 1     |
| 3   | 1        | 3    | 3    | 3     |
| 4   | 2        | 6    | 3    | 3     |
| 6   | 3        | 15   | 5    | 5     |
| 8   | 4        | 28   | 7    | 7     |

```shellscript
# 仅测试网络信息（多机）
./oscheckperf network -f server_list DURATION=300
```

### 硬件信息及检查

```bash
# 仅查看多机硬件信息
./oscheckperf hardware -f server_list

# 检查多机系统环境（依赖、权限、磁盘、网络）
./oscheckperf check -f server_list

```

## 常见问题

### Q1: 测试需要 root 权限吗？

**A**: 非 root 用户运行时，硬件信息可能显示不完整（主要集中在dmidecode ），不影响测试功能。

### Q2: IO测试文件会自动清理吗？如何自定义测试路径？

IO压测写入指定 `IO_PATH` 参数目录（默认 `$HOME/oscheckperf/io_test`），测试完成后会自动清理。可通过参数自定义路径：`./oscheckperf io IO_PATH=/data`

### Q3: 需要哪些端口？

| 端口类型   | 参数名            | 默认值   | 用途         |
| ------ | -------------- | ----- | ---------- |
| SSH端口  | `SSH_PORT`     | 22    | 远程服务器SSH连接 |
| 网络测试端口 | `NETWORK_PORT` | 25201 | iperf3网络测试 |

**串行模式**：只需要25201端口

**矩阵模式**：

- 单端口模式（默认）：自动递增使用端口，如 25201, 25202, 25203, ...
- 端口范围模式：在指定范围内循环复用，如 `NETWORK_PORT=25201-25210`

矩阵模式下，为避免TCP TIME_WAIT导致的端口冲突，不同batch使用不同端口。所需端口数取决于batch数量（通常为 `num_hosts - 1`）。建议防火墙放行连续的端口范围（如 25201-25220）。

### Q4: 执行工具的用户（协调机）与 server\_list 中的用户必须一致吗？

需要保证一致性，路径等参数传递时依赖类似$HOME等参数

### Q5: IO 压测文件大小如何计算？

sysbench 和 fio 的文件大小计算方式不同：

#### sysbench 文件大小

```
每个文件大小 = IO_TOTAL_SIZE / SYSBENCH_FILE_NUM
```

例如：`IO_TOTAL_SIZE=1G`，`SYSBENCH_FILE_NUM=4` → 每个文件 256M

#### fio 文件大小

```
每个job的大小 = IO_TOTAL_SIZE / FIO_NUMJOBS
文件大小 = 每个 job 的大小（每个 job 拥有独立文件）
```

例如：`IO_TOTAL_SIZE=1G`，`FIO_NUMJOBS=4` → 文件大小 256M，总写入量 1G

### Q6: IO\_TOTAL\_SIZE 和 DURATION 的关系？RAID 缓存有影响吗？

- `IO_TOTAL_SIZE` 是测试文件总大小，`DURATION` 是测试持续时间，两者独立配置，当`IO_TOTAL_SIZE`较小时，`DURATION`内工具会反复读或写`IO_PATH`文件
- `direct=1` 只绕过操作系统缓存，**无法绕过 RAID 卡缓存，**`IO_TOTAL_SIZE`和`DURATION`应合理设置大小，否则结果偏高。
- `IO_TOTAL_SIZE` 已支持动态计算压测文件大小，详见前面参数说明

