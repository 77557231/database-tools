# Database System Benchmark Tool

A system-level performance benchmarking tool designed for Vastbase, openGauss, and PostgreSQL databases, supporting comprehensive performance testing to help evaluate server hardware performance boundaries.

## Features

- ✅ **Unified Configuration**: Control all test parameters through a single configuration file
- ✅ **One-Click Execution**: Automated CPU/Memory/IO/Network/Threads/Mutex testing
- ✅ **Flexible Override**: Support command line parameters to override configuration file settings
- ✅ **Minimal Dependencies**: Basic mode only requires sysbench
- ✅ **Multi-Tool Support**: IO testing supports both sysbench and fio
- ✅ **Multi-Server Support**: Network testing supports multiple IP configurations (requires SSH passwordless login)
- ✅ **Detailed Reports**: Generate structured test reports

## Project Structure

```
vb_benchmark/
├── vb_benchmark              # Main entry script
├── config/
│   └── parameter.conf       # Unified parameter configuration
├── output/                   # Test results output directory
├── tools/
│   └── skill.md             # Development documentation
├── README.md                 # Documentation (Chinese)
└── README.en.md             # Documentation (English)
```

## Quick Start

### 1. Install Dependencies

#### Basic Dependencies (Required)
```bash
# CentOS/RHEL
sudo yum install -y sysbench

# Ubuntu/Debian
sudo apt-get install -y sysbench
```

#### Full Dependencies (Recommended)
```bash
# CentOS/RHEL
sudo yum install -y sysbench fio iperf3 jq

# Ubuntu/Debian
sudo apt-get install -y sysbench fio iperf3 jq
```

### 2. Supported Databases

- ✅ **Vastbase**: Huawei enterprise-grade database
- ✅ **openGauss**: Open source relational database
- ✅ **PostgreSQL**: Open source object-relational database

### 3. Run Tests

#### Basic Usage
```bash
./vb_benchmark
```

#### Using Configuration File
```bash
./vb_benchmark -c parameter.conf
# Or use full path
./vb_benchmark -c path/parameter.conf
```

#### Command Line Parameter Override
```bash
# Override test duration
./vb_benchmark DURATION=60

# Override CPU max prime
./vb_benchmark CPU_MAX_PRIME=10000

# Disable specific tests
./vb_benchmark MEMORY_ENABLED=false NETWORK_ENABLED=false

# Use fio for IO testing
./vb_benchmark IO_TOOL=fio

# Set fio test duration and path
./vb_benchmark IO_TOOL=fio IO_TEST_PATH=/data FIO_DURATION=30

# Network testing
./vb_benchmark NETWORK_ENABLED=true NETWORK_SERVER_IP=192.168.1.1
```

#### Dry Run Mode
```bash
./vb_benchmark -d
```

### 4. View Reports
```bash
ls -lh output/
cat output/report_benchmark_*.txt
```

## Configuration

### Unified Configuration File

The project uses a single configuration file `config/parameter.conf` to control all test parameters. The configuration file contains detailed English comments.

### Detailed Parameter Description

#### Core Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| DURATION | Unified test duration (seconds) | 10 | 60 |
| OUTPUT_DIR | Output directory path | ./output | /var/results |
| CLEANUP | Cleanup temp files after test | true | true/false |

#### CPU Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| CPU_ENABLED | Enable CPU test | true | true/false |
| CPU_THREADS | CPU test threads, 0=auto | 0 | 8 |
| CPU_MAX_PRIME | Max prime number for CPU test | 20000 | 10000 |

#### Memory Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| MEMORY_ENABLED | Enable Memory test | true | true/false |
| MEMORY_THREADS | Memory test threads, 0=auto | 0 | 8 |
| MEMORY_BLOCK_SIZE | Block size | 8K | 4K/8K/16K |
| MEMORY_TOTAL_SIZE | Total test size | 20G | 10G/20G |
| MEMORY_OPER | Memory operation type | read | read/write |

#### IO Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| IO_ENABLED | Enable IO test | true | true/false |
| IO_TOOL | IO test tool | sysbench | sysbench/fio |
| IO_TOTAL_SIZE | IO test file total size | 1G | 1G/10G |
| IO_TEST_MODE | Test mode | rndrw | rndrw/read/write |
| IO_FILE_NUM | Number of test files | 1 | 4 |
| IO_TEST_PATH | Test directory path | /tmp | /data |
| FIO_DURATION | fio test duration (seconds) | same as DURATION | 30 |

#### Network Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| NETWORK_ENABLED | Enable Network test | false | true/false |
| NETWORK_SERVER_IP | Server IP (auto-detect if empty) | "" | "192.168.1.100" |
| NETWORK_CLIENT_IP | Client IPs (space-separated for multiple) | "" | "192.168.1.101 192.168.1.102" |
| NETWORK_PORT | Test port | 25201 | 5201 |
| NETWORK_PARALLEL | Parallel connections | 1 | 4 |

#### Threads Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| THREADS_ENABLED | Enable Threads test | true | true/false |
| THREADS_NUM | Number of threads | 1000 | 1000 |
| THREADS_YIELDS | Yield count per thread | 100 | 100 |
| THREADS_LOCKS | Number of locks | 4 | 4 |

#### Mutex Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| MUTEX_ENABLED | Enable Mutex test | true | true/false |
| MUTEX_THREADS | Mutex test threads, 0=auto | 0 | 8 |
| MUTEX_NUM | Number of mutexes | 1024 | 1024 |

#### pgbench Test Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| PGBENCH_ENABLED | Enable pgbench test | false | true/false |
| PGBENCH_DB | pgbench database name | pgbench_db | mydb |
| PGBENCH_THREADS | pgbench threads, 0=auto | 0 | 8 |
| PGBENCH_DURATION | pgbench test duration (seconds) | 300 | 300 |

## Output Metrics

### CPU Test
- **events/sec**: Events per second (higher is better)
- **avg latency**: Average latency (lower is better)
- **P95/P99 latency**: 95th/99th percentile latency (lower is better)

### Memory Test
- **operations/sec**: Memory operations per second (higher is better)
- **throughput**: Memory throughput in MB/s (higher is better)
- **avg latency**: Average latency (lower is better)

### IO Test
- **IOPS**: IO operations per second (higher is better)
- **Bandwidth**: Throughput in MB/s (higher is better)
- **Latency**: Latency (lower is better)

### Network Test
- **Bandwidth**: Network bandwidth in MB/s (higher is better)

### Threads Test
- **events/sec**: Thread events per second (higher is better)
- **latency**: Thread scheduling latency (lower is better)

### Mutex Test
- **transactions**: Number of transactions (higher is better)
- **TPS**: Transactions per second (higher is better)
- **latency**: Lock wait latency (lower is better)

### pgbench Test
- **TPS**: Transactions per second (higher is better)
- **latency average**: Average latency (lower is better)

## Dependencies

| Tool | Required | Purpose | Install Command |
|------|----------|---------|-----------------|
| sysbench | Yes | CPU/Memory/IO/Threads/Mutex testing | `yum install -y sysbench` |
| fio | Optional | Professional IO testing | `yum install -y fio` |
| iperf3 | Optional | Network throughput testing | `yum install -y iperf3` |
| jq | Recommended | JSON result parsing | `yum install -y jq` |

## FAQ

### Q1: Do tests require root privileges?
**A**: Some tests (e.g., direct IO) require root privileges. It is recommended to run with `sudo`

### Q2: Will tests delete data?
**A**: Test files are only written to the specified directory (default `/tmp`) and can be automatically cleaned up after testing

### Q3: How to customize IO test path?
**A**: Use `IO_TEST_PATH` parameter: `./vb_benchmark IO_TEST_PATH=/data`

### Q4: How to configure multi-client for network testing?
**A**: Use `NETWORK_CLIENT_IP` parameter: `NETWORK_CLIENT_IP="192.168.1.101 192.168.1.102"`

## Best Practices

1. **Test Environment**: Run in an isolated test environment to avoid impacting production business
2. **Test Duration**: For production environments, use longer test durations (e.g., 60 seconds or more)
3. **IO Test Path**: Use the partition where the database data directory is located for more reference value
4. **Historical Comparison**: Run tests regularly and save reports for historical trend analysis
5. **Multi-Machine Testing**: Configure SSH passwordless login before network stress testing
6. **Result Interpretation**: Focus on P95/P99 latency, not just average values
7. **Parameter Adjustment**: Adjust test parameters according to server configuration, such as matching thread count to CPU core count

## License

This project is licensed under the GNU General Public License v3.0.

## Version History

| Tag | Date | Changes |
|-----|------|---------|
| 0.2.0 | 2026-04-17 | Refactored to remove lib directory, merged all functions into main script, added command line parameter support with override capability, updated documentation to English |
| 0.1.0 | 2026-04-16 | Initial release with basic benchmarking functionality |

---

**Version**: v2.0.0
**Created**: 2026-04-17
**Maintained by**: Vastbase Performance Diagnosis and Automation Operations Team