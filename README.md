# 数据库系统基准测试工具

一个为 Vastbase、openGauss 和 PostgreSQL 数据库设计的系统级性能基准测试工具，支持全面的性能测试，帮助评估服务器硬件性能边界。

## 特性

- ✅ **统一配置**：通过单一配置文件控制所有测试参数
- ✅ **一键执行**：自动化完成 CPU/内存/IO/网络/线程/锁测试
- ✅ **灵活扩展**：支持命令行参数覆盖配置文件设置
- ✅ **最小依赖**：基础模式仅需 sysbench
- ✅ **多工具支持**：IO 测试支持 sysbench 和 fio
- ✅ **多服务器支持**：网络压测支持多 IP 配置（需 SSH 免密）
- ✅ **详细报告**：生成结构化测试报告

## 项目结构

```
vb_benchmark/
├── vb_benchmark              # 主入口脚本
├── parameter.conf            # 统一参数配置文件
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

#### 使用配置文件

```bash
./vb_benchmark -c parameter.conf
# 或使用完整路径
./vb_benchmark -c path/parameter.conf
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
./vb_benchmark IO_TOOL=fio IO_TEST_PATH=/data FIO_DURATION=30

# 网络测试
./vb_benchmark NETWORK_ENABLED=true NETWORK_SERVER_IP=192.168.1.1
```

#### 干运行模式

```bash
./vb_benchmark -d
```

### 4. 查看报告

```bash
ls -lh output/
cat output/report_benchmark_*.txt
```

## 配置说明

### 统一配置文件

项目使用单一配置文件 `config/parameter.conf` 控制所有测试参数。配置文件包含详细的英文注释。

### 详细参数说明

#### 核心参数

| 参数          | 说明        | 默认值      | 示例           |
| ----------- | --------- | -------- | ------------ |
| DURATION    | 统一测试时长（秒） | 10       | 60           |
| OUTPUT\_DIR | 输出目录路径    | ./output | /var/results |
| CLEANUP     | 测试后清理临时文件 | true     | true/false   |

#### CPU 测试参数

| 参数              | 说明              | 默认值   | 示例         |
| --------------- | --------------- | ----- | ---------- |
| CPU\_ENABLED    | 是否启用 CPU 测试     | true  | true/false |
| CPU\_THREADS    | CPU 测试线程数（0=自动） | 0     | 8          |
| CPU\_MAX\_PRIME | CPU 测试最大素数      | 20000 | 10000      |

#### 内存测试参数

| 参数                  | 说明            | 默认值  | 示例         |
| ------------------- | ------------- | ---- | ---------- |
| MEMORY\_ENABLED     | 是否启用内存测试      | true | true/false |
| MEMORY\_THREADS     | 内存测试线程数（0=自动） | 0    | 8          |
| MEMORY\_BLOCK\_SIZE | 块大小           | 8K   | 4K/8K/16K  |
| MEMORY\_TOTAL\_SIZE | 总测试大小         | 20G  | 10G/20G    |
| MEMORY\_OPER        | 内存操作类型        | read | read/write |

#### IO 测试参数

| 参数              | 说明          | 默认值        | 示例               |
| --------------- | ----------- | ---------- | ---------------- |
| IO\_ENABLED     | 是否启用 IO 测试  | true       | true/false       |
| IO\_TOOL        | IO 测试工具     | sysbench   | sysbench/fio     |
| IO\_TOTAL\_SIZE | IO 测试文件总大小  | 1G         | 1G/10G           |
| IO\_TEST\_MODE  | 测试模式        | rndrw      | rndrw/read/write |
| IO\_FILE\_NUM   | 测试文件数量      | 1          | 4                |
| IO\_TEST\_PATH  | 测试目录路径      | /tmp       | /data            |
| FIO\_DURATION   | fio 测试时长（秒） | 同 DURATION | 30               |

#### 网络测试参数

| 参数                  | 说明                   | 默认值   | 示例                            |
| ------------------- | -------------------- | ----- | ----------------------------- |
| NETWORK\_ENABLED    | 是否启用网络测试             | false | true/false                    |
| NETWORK\_SERVER\_IP | 服务器 IP（空值自动检测）       | ""    | "192.168.1.100"               |
| NETWORK\_CLIENT\_IP | 客户端 IP（支持多个 IP 空格分隔） | ""    | "192.168.1.101 192.168.1.102" |
| NETWORK\_PORT       | 测试端口                 | 25201 | 5201                          |
| NETWORK\_PARALLEL   | 并行连接数                | 1     | 4                             |

#### 线程测试参数

| 参数               | 说明           | 默认值  | 示例         |
| ---------------- | ------------ | ---- | ---------- |
| THREADS\_ENABLED | 是否启用线程测试     | true | true/false |
| THREADS\_NUM     | 线程数          | 1000 | 1000       |
| THREADS\_YIELDS  | 每线程 yield 次数 | 100  | 100        |
| THREADS\_LOCKS   | 锁数量          | 4    | 4          |

#### 互斥锁测试参数

| 参数             | 说明             | 默认值  | 示例         |
| -------------- | -------------- | ---- | ---------- |
| MUTEX\_ENABLED | 是否启用互斥锁测试      | true | true/false |
| MUTEX\_THREADS | 互斥锁测试线程数（0=自动） | 0    | 8          |
| MUTEX\_NUM     | 互斥锁数量          | 1024 | 1024       |

#### pgbench 测试参数

| 参数                | 说明                | 默认值         | 示例         |
| ----------------- | ----------------- | ----------- | ---------- |
| PGBENCH\_ENABLED  | 是否启用 pgbench 测试   | false       | true/false |
| PGBENCH\_DB       | pgbench 数据库名      | pgbench\_db | mydb       |
| PGBENCH\_THREADS  | pgbench 线程数（0=自动） | 0           | 8          |
| PGBENCH\_DURATION | pgbench 测试时长（秒）   | 300         | 300        |

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

**A**: 使用 `NETWORK_CLIENT_IP` 参数：`NETWORK_CLIENT_IP="192.168.1.101 192.168.1.102"`

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
| 0.2.0 | 2026-04-17 | 重构移除 lib 目录，将所有函数合并到主脚本，添加命令行参数支持及覆盖功能，更新文档为中英文双版本 |
| 0.1.0 | 2026-04-16 | 初始版本，包含基本基准测试功能                                    |

***

**版本**: v2.0.0
**创建日期**: 2026-04-17
**维护团队**: Vastbase 二线团队
