# Vastbase 系统基准测试工具 - 开发规范

## 1. 项目概述

Vastbase 系统基准测试工具是一个为 Vastbase、openGauss 和 PostgreSQL 数据库设计的系统级性能基准测试工具，支持全面的性能测试，帮助评估服务器硬件性能边界。

## 2. 项目结构

```
vb_benchmark/
├── vb_benchmark              # 主入口脚本
├── config/
│   └── parameter.conf       # 统一参数配置文件
├── output/                   # 测试结果输出目录
├── tools/
│   └── skill.md             # 开发规范文档
├── README.md                # 中文文档（默认）
└── README.en.md             # 英文文档
```

## 3. 开发规范

### 3.1 代码结构规范
- 所有功能集成在单一的 `vb_benchmark` 脚本中
- 避免使用 lib 目录，保持代码简洁
- 使用函数模块化设计，提高代码可维护性
- 函数命名使用下划线分隔的小写字母（如 `run_cpu_test`）

### 3.2 命令行参数规范
- 支持短选项（如 `-c`、`-o`、`-d`、`-h`）
- 支持 `KEY=VALUE` 格式的参数覆盖
- 命令行参数优先级高于配置文件
- 参数名使用大写字母和下划线（如 `DURATION`、`CPU_MAX_PRIME`）

### 3.3 配置文件规范
- 使用统一的 `config/parameter.conf` 配置文件
- 包含详细的英文注释
- 支持通过命令行参数覆盖配置
- 参数值使用小写或特定格式（如 `true/false`、`sysbench/fio`）

### 3.4 文档更新规范（重要）
**每次代码更新必须同步更新以下文档：**

1. **中文 README.md**
   - 同步更新所有变更内容
   - 保持与英文版本内容一致
   - 文档结构保持统一

2. **英文 README.en.md**
   - 同步更新所有变更内容
   - 保持与中文版本内容一致
   - 文档结构保持统一

3. **更新版本历史**
   - 在版本历史表中添加新条目
   - 包含更新日期和变更说明
   - 版本号按语义化版本规则递增

### 3.5 报告生成规范
- 生成结构化的测试报告
- 包含系统信息、各测试模块结果
- 结果文件存储在 `output` 目录
- 报告格式统一，便于解析和对比

### 3.6 语言规范
- **中文文档**：README.md（默认）和 tools/skill.md 使用中文
- **英文文档**：README.en.md 使用英文
- **代码注释**：所有代码注释使用英文
- **配置文件**：parameter.conf 注释使用英文
- **命令行输出**：支持中英文输出

## 4. 使用方法

### 基本用法
```bash
./vb_benchmark
```

### 使用配置文件
```bash
./vb_benchmark -c path/to/parameter.conf
```

### 命令行参数覆盖
```bash
./vb_benchmark DURATION=60
./vb_benchmark CPU_MAX_PRIME=10000
./vb_benchmark MEMORY_ENABLED=false
./vb_benchmark IO_TOOL=fio IO_TEST_PATH=/data FIO_DURATION=30
```

### 干运行模式
```bash
./vb_benchmark -d
```

## 5. 配置参数说明

### 核心参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| DURATION | 统一测试时长（秒） | 10 | 60 |
| OUTPUT_DIR | 输出目录路径 | ./output | /var/results |
| CLEANUP | 测试后清理临时文件 | true | true/false |

### CPU 测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| CPU_ENABLED | 是否启用 CPU 测试 | true | true/false |
| CPU_THREADS | CPU 测试线程数（0=自动） | 0 | 8 |
| CPU_MAX_PRIME | CPU 测试最大素数 | 20000 | 10000 |

### 内存测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| MEMORY_ENABLED | 是否启用内存测试 | true | true/false |
| MEMORY_THREADS | 内存测试线程数（0=自动） | 0 | 8 |
| MEMORY_BLOCK_SIZE | 块大小 | 8K | 4K/8K/16K |
| MEMORY_TOTAL_SIZE | 总测试大小 | 20G | 10G/20G |
| MEMORY_OPER | 内存操作类型 | read | read/write |

### IO 测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| IO_ENABLED | 是否启用 IO 测试 | true | true/false |
| IO_TOOL | IO 测试工具 | sysbench | sysbench/fio |
| IO_TOTAL_SIZE | IO 测试文件总大小 | 1G | 1G/10G |
| IO_TEST_MODE | 测试模式 | rndrw | rndrw/read/write |
| IO_FILE_NUM | 测试文件数量 | 1 | 4 |
| IO_TEST_PATH | 测试目录路径 | /tmp | /data |
| FIO_DURATION | fio 测试时长（秒） | 同 DURATION | 30 |

### 网络测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| NETWORK_ENABLED | 是否启用网络测试 | false | true/false |
| NETWORK_SERVER_IP | 服务器 IP（空值自动检测） | "" | "192.168.1.100" |
| NETWORK_CLIENT_IP | 客户端 IP（支持多个 IP 空格分隔） | "" | "192.168.1.101 192.168.1.102" |
| NETWORK_PORT | 测试端口 | 25201 | 5201 |
| NETWORK_PARALLEL | 并行连接数 | 1 | 4 |

### 线程测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| THREADS_ENABLED | 是否启用线程测试 | true | true/false |
| THREADS_NUM | 线程数 | 1000 | 1000 |
| THREADS_YIELDS | 每线程 yield 次数 | 100 | 100 |
| THREADS_LOCKS | 锁数量 | 4 | 4 |

### 互斥锁测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| MUTEX_ENABLED | 是否启用互斥锁测试 | true | true/false |
| MUTEX_THREADS | 互斥锁测试线程数（0=自动） | 0 | 8 |
| MUTEX_NUM | 互斥锁数量 | 1024 | 1024 |

### pgbench 测试参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| PGBENCH_ENABLED | 是否启用 pgbench 测试 | false | true/false |
| PGBENCH_DB | pgbench 数据库名 | pgbench_db | mydb |
| PGBENCH_THREADS | pgbench 线程数（0=自动） | 0 | 8 |
| PGBENCH_DURATION | pgbench 测试时长（秒） | 300 | 300 |

## 6. 输出指标

| 测试类型 | 指标 | 说明 |
|----------|------|------|
| CPU | events/sec, avg latency, P95/P99 latency | 越高/低越好 |
| 内存 | operations/sec, throughput, avg latency | 越高/低越好 |
| IO | IOPS, Bandwidth, Latency | 越高/低越好 |
| 网络 | Bandwidth | 越高越好 |
| 线程 | events/sec, latency | 越高/低越好 |
| 互斥锁 | transactions, TPS, latency | 越高/低越好 |
| pgbench | TPS, latency average | 越高/低越好 |

## 7. 版本历史

| 标签 | 日期 | 变更 |
|------|------|------|
| 0.2.0 | 2026-04-17 | 重构移除 lib 目录，将所有函数合并到主脚本，添加命令行参数支持及覆盖功能，更新文档为中英文双版本 |
| 0.1.0 | 2026-04-16 | 初始版本，包含基本基准测试功能 |

## 8. 注意事项

1. **代码提交前**：确保中英文 README 已同步更新
2. **版本发布前**：确保版本历史已正确记录
3. **功能变更**：确保帮助信息与文档一致
4. **参数变更**：确保 parameter.conf 注释与代码同步

---

**版本**: v2.0.0
**创建日期**: 2026-04-17
**维护团队**: Vastbase 性能诊断与自动化运维团队