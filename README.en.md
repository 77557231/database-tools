# Database System Benchmark Tool

A system-level performance benchmarking tool designed for Vastbase, openGauss, and PostgreSQL databases, supporting comprehensive performance testing to help evaluate server hardware performance boundaries.

## Features

- ✅ **One-Click Execution**: Automated CPU/Memory/IO/Network/Threads/Mutex testing
- ✅ **Flexible Parameters**: Control all test parameters through command line arguments
- ✅ **Minimal Dependencies**: Basic mode only requires sysbench
- ✅ **Multi-Tool Support**: IO testing supports both sysbench and fio
- ✅ **Multi-Server Support**: Network testing supports multiple IP configurations (requires SSH passwordless login)
- ✅ **Detailed Reports**: Generate structured test reports

## Project Structure

```
vb_benchmark/
├── vb_benchmark              # Main entry script
├── output/                   # Test results output directory
├── tools/
│   └── skill.md              # Development documentation
├── README.md                 # Documentation (Chinese)
└── README.en.md              # Documentation (English)
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



#### Command line parameter override

```bash
# Override test duration
./vb_benchmark DURATION=60

# Override CPU max prime
./vb_benchmark CPU_MAX_PRIME=10000

# Disable specific tests
./vb_benchmark MEMORY_ENABLED=false NETWORK_ENABLED=false

# Use fio for IO test
./vb_benchmark IO_TOOL=fio

# Set fio test duration and directory
```

#### Run specific test (subcommand)

```bash
# Run CPU test
./vb_benchmark cpu

# Run memory test
./vb_benchmark mem

# Run IO test
./vb_benchmark io

# Run network test (matrix mode)
./vb_benchmark network -f servers.txt NETWORK_MODE=matrix

# Run threads test
./vb_benchmark thread

# Run mutex test
./vb_benchmark mutex

# Run system checks (dependencies, permissions, disk space, network)
./vb_benchmark check

# Run all tests (default)
./vb_benchmark all
```

#### Combine subcommand with parameters

```bash
# Run CPU test with specific parameters
./vb_benchmark cpu DURATION=20 CPU_MAX_PRIME=10000

# Run IO test with fio
./vb_benchmark io IO_TOOL=fio FIO_DURATION=30

# Run network test with server list
./vb_benchmark network -f "192.168.1.101 192.168.1.102" NETWORK_MODE=parallel

# Matrix network test (all-to-all cross testing)
./vb_benchmark -f servers.txt NETWORK_MODE=matrix

# Advanced usage
# Run system checks with custom test directory
./vb_benchmark -f servers.txt check IO_TEST_PATH='/home/vastbase/vb_test'
# Run multiple tests with custom parameters
./vb_benchmark cpu mem -f servers.txt DURATION=2 THREADS=4
# Run IO test with fio and custom parameters
./vb_benchmark io -f servers.txt IO_TOOL=fio IO_TEST_MODE=read IO_TOTAL_SIZE=10G
```

#### Install sysbench

Single machine installation:
```bash
./vb_benchmark -i
```

Multi-machine installation (from server list file):
```bash
./vb_benchmark -i -f servers.txt
```

Multi-machine installation (direct IP list):
```bash
./vb_benchmark -i -f "192.168.1.101 192.168.1.102 192.168.1.103"
```

**Installation Logic**:

| Scenario | Behavior |
|----------|----------|
| Local machine in IP list and no `$HOME/sysbench` | Compile first, then distribute |
| Local machine has `$HOME/sysbench` directory | Skip compilation, directly package and distribute |
| Local machine not in IP list | All servers need distribution (from local existing directory) |
| SCP distribution | Automatically exclude local machine IP |

**Execution Method**:
- **Local Execution**: Directly use the `vb_benchmark` script in the current directory
- **Remote Execution**: Call the `$HOME/sysbench/vb_benchmark` script on remote servers via SSH

**Notes**:
- `$HOME/sysbench` directory will be created automatically, skip compilation if it already exists
- For multi-machine installation, if local machine is in the IP list and no `$HOME/sysbench` directory exists, it will compile first then distribute
- SCP distribution will automatically exclude the local machine IP
- Target servers need SSH passwordless login configured
- Environment variables will be automatically configured and take effect after installation

#### Dry Run Mode
```bash
./vb_benchmark -d
```
### 4. View Reports
```bash
ls -lh output/
cat output/report_benchmark_*.txt
```

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

**A**: Create a server list file `servers.txt` containing all IP addresses to test, then specify it with the `-f` parameter:

```bash
./vb_benchmark network -f servers.txt
```

### Q5: What is the difference between NETWORK_MODE and NETWORK_PARALLEL parameters?

**A**:
- **NETWORK_MODE**: Controls how multiple client tests are executed
  - `serial`: Execute client tests one by one, starting the next after the previous completes
  - `parallel`: Execute all client tests simultaneously
  - `matrix`: Execute full matrix cross-testing (test between every pair of servers)

- **NETWORK_PARALLEL**: Controls the number of parallel connections for each iperf3 test, effective in all modes
  - Example: `NETWORK_PARALLEL=4` means each test uses 4 parallel connections

**Examples**:
```bash
# Serial execution, each test uses 4 parallel connections
./vb_benchmark network -f servers.txt NETWORK_MODE=serial NETWORK_PARALLEL=4

# Parallel execution, each test uses 4 parallel connections
./vb_benchmark network -f servers.txt NETWORK_MODE=parallel NETWORK_PARALLEL=4
```

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
| 0.5.0 | 2026-04-21 | Fixed remote execution path issue, added SSH passwordless login check, improved IO test path management, supported distribution to arbitrary server list files, added check command support, optimized check output with detailed information, supported multiple subcommands execution, separated check and test logic, added DEBUG mode |
| 0.4.0 | 2026-04-21 | Refactored command line parameters, added subcommand support (cpu/mem/io/network/thread/mutex/all), optimized help information display, categorized test parameters |
| 0.3.0 | 2026-04-20 | Added support for controlling whether local machine participates in testing through -f server IP list, local machine will not participate if not in IP list; Added support for compiling and distributing sysbench to target cluster server list |
| 0.2.0 | 2026-04-17 | Refactored to remove lib directory, merged all functions into main script, added command line parameter support with override capability, updated documentation to English |
| 0.1.0 | 2026-04-16 | Initial release with basic benchmarking functionality |

---

**Created**: 2026-04-17
**Maintained by**: Vastbase L2 Support Team
