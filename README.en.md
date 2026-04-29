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
$HOME/oscheckperf/
├── oscheckperf              # Main entry script
├── output/                   # Test results output directory (in current directory)
│   ├── original_data_*_all_results.log  # Raw test data summary
│   ├── data_*_all_results.log           # Parsed test results
│   └── report_benchmark_*.log           # Final performance report
├── tmp/                      # Temporary files directory
│   ├── vb_fileio_*.txt       # sysbench fileio test output
│   ├── fio_*.fio             # fio configuration files
│   ├── fio_*_result_*.json   # fio JSON test results
│   └── network_*.json        # Network test JSON results
├── io_test/                  # IO test data directory
│   ├── test_file.*           # Test files created by sysbench (auto cleaned)
│   └── fio_test_file.*       # Test files created by fio (retained)
├── tools/
│   └── skill.md              # Development documentation
├── README.md                 # Documentation (Chinese)
└── README.en.md              # Documentation (English)
```

### Directory Structure Description

| Directory | Purpose | Default Path |
|-----------|---------|--------------|
| `output/` | Final reports and logs (original_data*, data*, report_benchmark*) | `./output` (current directory) |
| `tmp/` | Temporary files (network test results, fio JSON, sysbench output) | `$HOME/oscheckperf/tmp` |
| `io_test/` | IO test data files (test files created by sysbench/fio) | `$HOME/oscheckperf/io_test` |

### File Type Description

| File Type | Location | Description |
|-----------|----------|-------------|
| **Raw test data** | `./output/original_data_*` | Summary of all raw test outputs |
| **Parsed results** | `./output/data_*` | Parsed structured test results |
| **Final report** | `./output/report_benchmark_*` | Formatted performance report |
| **sysbench output** | `$HOME/oscheckperf/tmp/vb_fileio_*.txt` | sysbench text output (temporary) |
| **fio config** | `$HOME/oscheckperf/tmp/fio_*.fio` | fio configuration files (temporary) |
| **fio JSON** | `$HOME/oscheckperf/tmp/fio_*_result_*.json` | fio JSON results (temporary) |
| **Network JSON** | `$HOME/oscheckperf/tmp/network_*.json` | Network test results (temporary) |
| **IO test files** | `$HOME/oscheckperf/io_test/` | Test files created by sysbench/fio |

### Path Configuration

You can modify the base directory using the `BASE_DIR` environment variable:

```bash
# Modify the base directory for all paths
export BASE_DIR=/custom/path/to/oscheckperf
./oscheckperf
```

**Environment Variable Priority**:
- `BASE_DIR` > Default `$HOME/oscheckperf`
- `IO_PATH` > Default `$BASE_DIR/io_test`  
- `OUTPUT_DIR` > Default `./output`

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
./oscheckperf
```



#### Command line parameter override

```bash
# Override test duration
./oscheckperf DURATION=60

# Override CPU max prime
./oscheckperf CPU_MAX_PRIME=10000

# Disable specific tests
./oscheckperf MEMORY_ENABLED=false NETWORK_ENABLED=false

# Use fio for IO test
./oscheckperf IO_TOOL=fio

# Set fio test duration and directory
```

#### Run specific test (subcommand)

```bash
# Run CPU test
./oscheckperf cpu

# Run memory test
./oscheckperf mem

# Run IO test
./oscheckperf io

# Run network test (matrix mode)
./oscheckperf network -f servers.txt NETWORK_MODE=matrix

# Run threads test
./oscheckperf thread

# Run mutex test
./oscheckperf mutex

# Run system checks (dependencies, permissions, disk space, network)
./oscheckperf check

# Run all tests (default)
./oscheckperf all
```

#### Combine subcommand with parameters

```bash
# Run CPU test with specific parameters
./oscheckperf cpu DURATION=20 CPU_MAX_PRIME=10000

# Run IO test with fio
./oscheckperf io IO_TOOL=fio FIO_DURATION=30

# Run network test with server list
./oscheckperf network -f "192.168.1.101 192.168.1.102" NETWORK_MODE=parallel

# Matrix network test (all-to-all cross testing)
./oscheckperf -f servers.txt NETWORK_MODE=matrix

# Advanced usage
# Run system checks with custom test directory
./oscheckperf -f servers.txt check IO_TEST_PATH='/home/vastbase/vb_test'
# Run multiple tests with custom parameters
./oscheckperf cpu mem -f servers.txt DURATION=2 THREADS=4
# Run IO test with fio and custom parameters
./oscheckperf io -f servers.txt IO_TOOL=fio IO_TEST_MODE=read IO_TOTAL_SIZE=10G
```

#### Install sysbench

Single machine installation:
```bash
./oscheckperf -i
```

Multi-machine installation (from server list file):
```bash
./oscheckperf -i -f servers.txt
```

Multi-machine installation (direct IP list):
```bash
./oscheckperf -i -f "192.168.1.101 192.168.1.102 192.168.1.103"
```

**Installation Logic**:

| Scenario | Behavior |
|----------|----------|
| Local machine in IP list and no `$HOME/oscheckperf` | Compile first, then distribute |
| Local machine has `$HOME/oscheckperf` directory | Skip compilation, directly package and distribute |
| Local machine not in IP list | All servers need distribution (from local existing directory) |
| SCP distribution | Automatically exclude local machine IP |

**Execution Method**:
- **Local Execution**: Directly use the `oscheckperf` script in the current directory
- **Remote Execution**: Call the `$HOME/oscheckperf/oscheckperf` script on remote servers via SSH

**Notes**:
- `$HOME/oscheckperf` directory will be created automatically, skip compilation if it already exists
- For multi-machine installation, if local machine is in the IP list and no `$HOME/oscheckperf` directory exists, it will compile first then distribute
- SCP distribution will automatically exclude the local machine IP
- Target servers need SSH passwordless login configured
- Environment variables will be automatically configured and take effect after installation

#### Dry Run Mode
```bash
./oscheckperf -d
```
### 4. View Reports
```bash
ls -lh output/
cat output/report_benchmark_*.log
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

### IO Benchmark Details

#### Sysbench fileio Workflow

Sysbench fileio testing consists of three phases:

1. **prepare phase**: Create test files
   - Creates test files in the directory specified by `IO_TEST_PATH`
   - Default file size is 1G (adjustable via `IO_TOTAL_SIZE`)
   - Default number of files is 1 (adjustable via `IO_FILE_NUM`)

2. **run phase**: Execute actual benchmark
   - The `DURATION` parameter only controls the execution time of this phase
   - Performs random read/write operations on files created in prepare phase
   - Default test mode is `rndrw` (random read/write), adjustable via `IO_TEST_MODE`

3. **cleanup phase**: Automatically clean up test files
   - Deletes all test files created in prepare phase
   - The test directory itself is not deleted

#### FIO Workflow

FIO testing works differently:

1. **Configuration generation**: Generates `.fio` configuration file based on parameters
2. **Execute test**: FIO automatically creates test files during runtime
3. **File handling**: FIO does not automatically delete files after testing; the script retains result files

#### Important Notes

**IO_TEST_PATH Parameter**:

- Default test path is `$HOME/oscheckperf/io_test`
- **Do NOT use `/tmp` directory**: On some servers, `/tmp` is tmpfs (memory filesystem), which leads to inaccurate test results (testing memory instead of disk)
- It is recommended to use the disk partition where the database data directory is located for more reference value
- Ensure the target partition has enough available space (at least larger than `IO_TOTAL_SIZE`)

**Common Parameters**:

### sysbench Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SYSBENCH_PROFILES` | `rndrw` | sysbench test modes, space-separated (seqwr/seqrewr/seqrd/rndrd/rndwr/rndrw) |
| `SYSBENCH_FILE_NUM` | `4` | Number of sysbench test files |
| `SYSBENCH_BLOCK_SIZE` | `16K` | sysbench block size |
| `SYSBENCH_IO_MODE` | `sync` | sysbench IO mode (sync/async) |
| `SYSBENCH_EXTRA_FLAGS` | `direct` | sysbench extra flags (direct/sync) |
| `SYSBENCH_THREADS` | `4` | sysbench threads count |
| `SYSBENCH_DURATION` | `DURATION` | sysbench IO test duration |

### fio Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FIO_PROFILES` | `randrw` | fio test modes, space-separated (read/write/randread/randwrite/rw/randrw/trim/randtrim/trimwrite) |
| `FIO_BS` | `16K` | fio block size (optimized for database workloads) |
| `FIO_IODEPTH` | `32` | fio I/O depth |
| `FIO_NUMJOBS` | `4` | fio job threads count |
| `FIO_DIRECT` | `1` | fio direct I/O mode |
| `FIO_FILE_NUM` | `4` | Number of fio test files (simulates multi-datafile scenario) |
| `FIO_IOENGINE` | `libaio` | fio IO engine (libaio/sync/posixaio) |
| `FIO_DURATION` | `DURATION` | fio test duration |

### General Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `IO_PATH` | `$HOME/oscheckperf/io_test` | Test file directory |
| `IO_TOTAL_SIZE` | `1G` | Total test file size (shared by sysbench and fio) |
| `IO_TOOL` | `sysbench` | IO testing tool (sysbench/fio) |

### Parameter Notes

**FIO_FILE_NUM Note**:
- Sets the number of test files, default is 4
- When `FIO_FILE_NUM` is configured, each file size = `IO_TOTAL_SIZE / FIO_FILE_NUM`
- Example: `IO_TOTAL_SIZE=1G`, `FIO_FILE_NUM=4` → 256M per file

**Examples**:

```bash
# Random read/write test with sysbench
./oscheckperf io DURATION=60 IO_TOTAL_SIZE=2G

# Sequential read test with fio
./oscheckperf io IO_TOOL=fio FIO_PROFILES=read FIO_DURATION=60

# Specify test path to database data directory
./oscheckperf io IO_PATH=/data/vastbase/pg_xlog
```

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
**A**: Use `IO_TEST_PATH` parameter: `./oscheckperf IO_TEST_PATH=/data`

### Q4: How to configure multi-client for network testing?

**A**: Create a server list file `servers.txt` containing all IP addresses to test, then specify it with the `-f` parameter:

```bash
./oscheckperf network -f servers.txt
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
./oscheckperf network -f servers.txt NETWORK_MODE=serial NETWORK_PARALLEL=4

# Parallel execution, each test uses 4 parallel connections
./oscheckperf network -f servers.txt NETWORK_MODE=parallel NETWORK_PARALLEL=4
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

