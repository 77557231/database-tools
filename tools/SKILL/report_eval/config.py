from enum import Enum
from dataclasses import dataclass
from typing import Dict, Any, Optional


class Status(Enum):
    PASS = "pass"
    WARN = "warn"
    FAIL = "fail"
    SKIP = "skip"


@dataclass
class ThresholdConfig:
    cpu_baseline_arm: float = 1250.0
    cpu_baseline_x86: float = 900.0
    cpu_freq_ref_arm: float = 2.6
    cpu_freq_ref_x86: float = 3.0
    cpu_good_threshold: float = 90.0
    cpu_warn_threshold: float = 75.0
    
    mem_vm_read_expect_low: float = 60000.0
    mem_vm_read_expect_high: float = 70000.0
    mem_vm_write_expect_low: float = 5000.0
    mem_vm_write_expect_high: float = 30000.0
    mem_phys_read_efficiency: float = 0.95
    mem_phys_write_efficiency: float = 0.35
    mem_good_threshold: float = 90.0
    mem_warn_threshold: float = 75.0
    
    io_hdd_iops: float = 150.0
    io_ssd_iops: float = 8000.0
    io_nvme_iops: float = 50000.0
    io_hdd_bw_mbps: float = 50.0
    io_ssd_bw_mbps: float = 300.0
    io_nvme_bw_mbps: float = 1500.0
    io_good_threshold: float = 90.0
    io_warn_threshold: float = 75.0
    
    net_good_threshold: float = 90.0
    net_warn_threshold: float = 75.0
    net_retrans_warn: float = 10000.0
    
    threads_baseline_arm_kvm: float = 350.0
    threads_baseline_arm_physical: float = 50.0
    threads_baseline_x86_vmware: float = 350.0
    threads_baseline_x86_physical: float = 50.0
    threads_good_threshold: float = 90.0
    threads_warn_threshold: float = 75.0
    
    mutex_baseline_arm_kvm: float = 20.0
    mutex_baseline_arm_physical: float = 3.0
    mutex_baseline_x86_vmware: float = 15.0
    mutex_baseline_x86_physical: float = 3.0
    mutex_good_threshold: float = 90.0
    mutex_warn_threshold: float = 75.0
    
    report_version: str = ""


class Config:
    STATUS_COLORS = {
        Status.PASS: {"bg": "#e8f5e9", "border": "#2e7d32", "text": "#1b5e20", "emoji": "🟢"},
        Status.WARN: {"bg": "#fff8e1", "border": "#f9a825", "text": "#e65100", "emoji": "🟡"},
        Status.FAIL: {"bg": "#ffebee", "border": "#c62828", "text": "#b71c1c", "emoji": "🔴"},
        Status.SKIP: {"bg": "#f5f5f5", "border": "#9e9e9e", "text": "#616161", "emoji": "⏭️"},
    }
    
    DEFAULT_OUTPUT_DIR = "./output"
    REPORT_PATTERN = "report_benchmark_*.log"
    EVAL_PATTERN = "report_eval_{timestamp}_{version}.html"
    COMPARE_PATTERN = "report_compare_{timestamp}_{version}.html"
    
    @staticmethod
    def get_status_color(status: Status) -> Dict[str, str]:
        return Config.STATUS_COLORS.get(status, Config.STATUS_COLORS[Status.SKIP])
    
    @staticmethod
    def get_status_emoji(status: Status) -> str:
        return Config.get_status_color(status)["emoji"]