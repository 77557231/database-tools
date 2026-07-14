from datetime import datetime
from typing import Dict, List, Optional
from .config import Status, Config
from .threshold_parser import ThresholdParser


class HTMLGenerator:
    def __init__(self, thresholds: ThresholdParser):
        self.thresholds = thresholds
    
    def generate(self, basic_info: Dict, hardware: Dict, hardware_info: Dict,
                 cpu_results: Optional[List], memory_results: Optional[List],
                 io_results: Optional[List], threads_results: Optional[List],
                 mutex_results: Optional[List], network_results: Optional[List],
                 analysis_text: str = "") -> str:
        
        html = self._generate_header(basic_info)
        html += self._generate_banner(analysis_text)
        html += self._generate_env_notice()
        html += "<div class=\"content\">"
        
        html += self._generate_system_section(hardware)
        
        if cpu_results:
            html += self._generate_cpu_section(cpu_results, hardware)
        
        if memory_results:
            html += self._generate_memory_section(memory_results)
        
        if io_results:
            html += self._generate_io_section(io_results, hardware)
        
        if network_results:
            html += self._generate_network_section(network_results, hardware, hardware_info)
        
        if threads_results:
            html += self._generate_threads_section(threads_results, hardware)
        
        html += self._generate_rules_section()
        html += "</div>"
        html += self._generate_footer()
        
        return html
    
    def _generate_header(self, basic_info: Dict) -> str:
        version = self.thresholds.get('report_version', '')
        return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>oscheckperf 压测评估报告 {version} — {basic_info.get('test_time', '')}</title>
<style>
  :root {{
    --pass: #e8f5e9; --pass-b: #2e7d32; --pass-text: #1b5e20;
    --warn: #fff8e1; --warn-b: #f9a825; --warn-text: #e65100;
    --fail: #ffebee; --fail-b: #c62828; --fail-text: #b71c1c;
    --skip: #f5f5f5; --skip-b: #9e9e9e; --skip-text: #616161;
    --bg: #fafafa; --card: #ffffff; --border: #e0e0e0;
    --h1: #1565c0; --h2: #1976d2; --accent: #0d47a1;
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ font-family: -apple-system, 'Segoe UI', 'PingFang SC', sans-serif; font-size: 14px; background: var(--bg); color: #212121; line-height: 1.6; }}
  .report-header {{ background: linear-gradient(135deg, #1565c0, #0d47a1); color: white; padding: 24px 32px; }}
  .report-header h1 {{ font-size: 22px; margin-bottom: 6px; }}
  .report-header .meta {{ display: flex; gap: 32px; font-size: 13px; opacity: 0.9; flex-wrap: wrap; }}
  .report-header .meta span {{ display: flex; align-items: center; gap: 6px; }}
  .banner {{ margin: 20px 32px; border-radius: 8px; padding: 16px 20px; border-left: 5px solid; }}
  .banner.pass {{ background: var(--pass); border-color: var(--pass-b); }}
  .banner.warn {{ background: var(--warn); border-color: var(--warn-b); }}
  .banner.fail {{ background: var(--fail); border-color: var(--fail-b); }}
  .banner h2 {{ font-size: 16px; margin-bottom: 8px; }}
  .banner ul {{ margin-left: 20px; }}
  .banner li {{ font-size: 13px; line-height: 1.8; }}
  .env-notice {{ margin: 0 32px 16px; background: #e3f2fd; border: 1px solid #90caf9; border-radius: 8px; padding: 12px 16px; font-size: 13px; line-height: 1.8; }}
  .env-notice strong {{ color: #1565c0; }}
  .content {{ padding: 0 32px 32px; }}
  .section {{ margin-bottom: 28px; }}
  .section-title {{ font-size: 15px; font-weight: 700; color: var(--h1); border-bottom: 2px solid var(--h2); padding-bottom: 6px; margin-bottom: 14px; }}
  .section-sub {{ font-size: 13px; color: #555; margin-bottom: 10px; }}
  .cmp-table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  .cmp-table th {{ background: #263238; color: white; padding: 8px 10px; text-align: left; white-space: nowrap; }}
  .cmp-table td {{ padding: 7px 10px; border-bottom: 1px solid var(--border); }}
  .cmp-table tr:nth-child(even) td {{ background: #fafafa; }}
  .cmp-table tr.pass td {{ background: var(--pass); }}
  .cmp-table tr.warn td {{ background: var(--warn); }}
  .cmp-table tr.fail td {{ background: var(--fail); }}
  .cmp-table tr.skip td {{ background: var(--skip); color: var(--skip-text); }}
  .net-table {{ width: 100%; border-collapse: collapse; font-size: 12px; }}
  .net-table th {{ background: #004d40; color: white; padding: 7px 10px; text-align: left; white-space: nowrap; }}
  .net-table td {{ padding: 6px 10px; border-bottom: 1px solid var(--border); }}
  .net-table tr.pass td {{ background: #e8f5e9; }}
  .net-table tr.warn td {{ background: #fff8e1; }}
  .net-table tr.fail td {{ background: #ffebee; }}
  .net-table tr.skip td {{ background: var(--skip); }}
  .tag-retrans {{ color: #b71c1c; font-weight: 600; }}
  .rule-table {{ width: 100%; border-collapse: collapse; font-size: 12px; }}
  .rule-table th {{ background: #4a148c; color: white; padding: 7px 10px; white-space: nowrap; }}
  .rule-table td {{ padding: 6px 10px; border-bottom: 1px solid #e8eaf6; vertical-align: top; }}
  .rule-table tr:nth-child(even) td {{ background: #f3e5f5; }}
  .note {{ font-size: 12px; color: #555; font-style: italic; margin-top: 8px; line-height: 1.7; }}
  .note strong {{ font-style: normal; }}
  .footer {{ text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid var(--border); margin-top: 20px; }}
  @media (max-width: 900px) {{
    .content, .banner, .env-notice {{ margin-left: 12px; margin-right: 12px; padding-left: 10px; padding-right: 10px; }}
  }}
</style>
</head>
<body>

<div class="report-header">
  <h1>🗄️ oscheckperf 压测评估报告</h1>
  <div class="meta">
    <span>📅 压测时间：{basic_info.get('test_time', '')}</span>
    <span>🖥️ 集群规模：{basic_info.get('node_count', 1)} 节点</span>
    <span>📋 规则版本：{version}</span>
    <span>⏱️ 测试时长：{basic_info.get('duration', '')}</span>
  </div>
</div>
"""
    
    def _generate_banner(self, analysis_text: str) -> str:
        if not analysis_text:
            return ""
        
        return f"""
<div class="banner pass">
  <h2>📊 综合判定说明</h2>
  <ul>
{self._format_analysis(analysis_text)}
  </ul>
</div>
"""
    
    def _format_analysis(self, text: str) -> str:
        lines = text.split('\n')
        result = []
        for line in lines:
            line = line.strip()
            if line:
                result.append(f'    <li>{line}</li>')
        return '\n'.join(result)
    
    def _generate_env_notice(self) -> str:
        return """
<div class="env-notice">
  <strong>📌 评估说明（达成率方式）：</strong><br>
  · <strong>CPU</strong>：按架构基线(ARM=1250/x86=900 evt/s) × 频率比计算期望单核evt/s<br>
  · <strong>内存</strong>：虚拟机按经验值阈值判断，物理机按JEDEC公式计算<br>
  · <strong>磁盘 IO</strong>：虚拟盘仅展示实测值供参考，不强制评判<br>
  · <strong>网络</strong>：Speed已知按标称Mbps÷8计算期望MB/s；Speed=Unknown仅展示实测<br>
  · <strong>线程</strong>：按架构基线计算单核达成率
</div>
"""
    
    def _generate_system_section(self, hardware: Dict) -> str:
        html = """
  <div class="section">
    <div class="section-title">系统信息汇总</div>
    <div class="section-sub">展示各节点的操作系统、内核版本和运行时间</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>操作系统</th><th>内核版本</th><th>运行时间</th>
        </tr>
      </thead>
      <tbody>
"""
        
        for ip, info in hardware.items():
            system = info.get('system', {})
            os_version = system.get('os_version', system.get('OS Version', 'N/A'))
            kernel_version = system.get('kernel_version', system.get('Kernel Version', 'N/A'))
            uptime = system.get('system_uptime', system.get('System Uptime', 'N/A'))
            
            html += f"""
        <tr>
          <td>{ip}</td><td>{os_version}</td><td>{kernel_version}</td><td>{uptime}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
  </div>
"""
        return html
    
    def _generate_cpu_section(self, results: List[Dict], hardware: Dict) -> str:
        html = """
  <div class="section">
    <div class="section-title">CPU 单核效率对比（全集群）</div>
    <div class="section-sub">公式：单核 evt/s = 总evt/s ÷ 核数；期望 = 基线(ARM=1250 / x86=900) × (实际频率/参考频率)</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>架构/环境</th><th>核数</th><th>频率</th>
          <th>总 evt/s</th><th>单核 evt/s</th><th>单核期望</th>
          <th>达成率</th><th>说明</th>
        </tr>
      </thead>
      <tbody>
"""
        
        for r in results:
            ip = r['ip']
            model = hardware.get(ip, {}).get('cpu', {}).get('model', '')
            arch = hardware.get(ip, {}).get('cpu', {}).get('arch', '')
            freq = hardware.get(ip, {}).get('cpu', {}).get('freq', '')
            
            env_desc = 'ARM' if 'aarch64' in arch.lower() or 'ARM' in model else 'x86'
            
            if 'VMware' in model:
                env_desc += ' VMware'
            elif 'KVM' in model:
                env_desc += ' KVM'
            
            emoji = Config.get_status_emoji(Status(r['status']))
            
            html += f"""
        <tr class="{r['status']}">
          <td>{ip}</td><td>{env_desc}（{model.split('@')[0] if '@' in model else model[:30]}）</td>
          <td>{r['cores']}</td><td>{freq} GHz</td>
          <td>{r['events_sec']:,.1f}</td><td>{r['single_core']:,.1f}</td><td>{r['baseline']:,.0f}</td>
          <td>{r['rate']:.1f}% {emoji}</td>
          <td>{self._get_cpu_note(r)}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
    <p class="note">💡 达成率 ≥ 90% 为良好（🟢），75%-90% 为一般（🟡），< 75% 为需关注（🔴）</p>
  </div>
"""
        return html
    
    def _get_cpu_note(self, r: Dict) -> str:
        if r['status'] == Status.PASS.value:
            return '单核效率接近或超过预期基线' if r['rate'] >= 100 else '单核效率良好'
        elif r['status'] == Status.WARN.value:
            return '单核效率一般，建议关注'
        else:
            return '单核效率偏低，建议排查环境因素'
    
    def _generate_memory_section(self, results: List[Dict]) -> str:
        read_results = [r for r in results if r['mode'] == 'read']
        write_results = [r for r in results if r['mode'] == 'write']
        
        html = """
  <div class="section">
    <div class="section-title">内存带宽横向对比</div>
    <div class="section-sub">虚机内存不适用 JEDEC 公式，按经验阈值评估</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th>
          <th>读实测 (MiB/s)</th><th>读期望</th><th>读达成率</th>
          <th>写实测 (MiB/s)</th><th>写期望</th><th>写达成率</th><th>说明</th>
        </tr>
      </thead>
      <tbody>
"""
        
        ips = set(r['ip'] for r in read_results + write_results)
        for ip in sorted(ips):
            read = next((r for r in read_results if r['ip'] == ip), None)
            write = next((r for r in write_results if r['ip'] == ip), None)
            
            read_emoji = Config.get_status_emoji(Status(read['status'])) if read else ''
            write_emoji = Config.get_status_emoji(Status(write['status'])) if write else ''
            
            status = Status.PASS.value
            if read and read['status'] == Status.FAIL.value or write and write['status'] == Status.FAIL.value:
                status = Status.FAIL.value
            elif read and read['status'] == Status.WARN.value or write and write['status'] == Status.WARN.value:
                status = Status.WARN.value
            
            html += f"""
        <tr class="{status}">
          <td>{ip}</td>
          <td>{read['mib_sec']:,.0f}</td><td>{read['baseline']:,.0f}</td><td>{read['rate']:.1f}% {read_emoji}</td>
          <td>{write['mib_sec']:,.0f}</td><td>{write['baseline']:,.0f}</td><td>{write['rate']:.1f}% {write_emoji}</td>
          <td>{'虚机环境，读写均按经验值评估' if read and read['is_vm'] else '物理机环境，按JEDEC公式评估'}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
    <p class="note">💡 内存带宽达成率反映内存子系统性能，读写差异属正常现象</p>
  </div>
"""
        return html
    
    def _generate_io_section(self, results: List[Dict], hardware: Dict) -> str:
        html = """
  <div class="section">
    <div class="section-title">磁盘 IO 横向对比</div>
    <div class="section-sub">IO 性能取决于存储介质和配置；展示实测值供参考</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>介质</th><th>模式</th><th>读 IOPS</th><th>写 IOPS</th>
          <th>BW (MB/s)</th><th>平均延迟 (ms)</th>
        </tr>
      </thead>
      <tbody>
"""
        
        for r in results:
            disk_type = hardware.get(r['ip'], {}).get('io', {}).get('type', 'Unknown')
            html += f"""
        <tr class="{r['status']}">
          <td>{r['ip']}</td><td>{disk_type}</td><td>{r['mode']}</td>
          <td>{int(r['read_iops']) if r['read_iops'] else 'N/A'}</td>
          <td>{int(r['write_iops']) if r['write_iops'] else 'N/A'}</td>
          <td>{r['total_bw']:,.0f}</td>
          <td>{r['latency']:.2f}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
    <p class="note">💡 虚拟磁盘(Virtual)的性能取决于底层存储，仅供参考；物理磁盘按介质类型区分</p>
  </div>
"""
        return html
    
    def _generate_network_section(self, results: List[Dict], hardware: Dict, hardware_info: Dict) -> str:
        html = """
  <div class="section">
    <div class="section-title">网络带宽矩阵</div>
    <div class="section-sub">Speed=Unknown：不设阈值，仅展示实测；Speed 已知：按标称 Mbps÷8 计算期望 MB/s</div>
    <table class="net-table">
      <thead>
        <tr>
          <th>发起节点</th><th>目标节点</th><th>实测 MB/s</th>
          <th>NIC 类型</th><th>Driver</th><th>标称速率</th><th>期望 MB/s</th>
          <th>达成率</th><th>重传次数</th><th>RTT (ms)</th>
        </tr>
      </thead>
      <tbody>
"""
        
        for r in results:
            retrans_tag = f'<span class="tag-retrans">{r["retrans"]} ⚠</span>' if r['retrans_status'] == Status.WARN.value else r['retrans']
            expected_str = f"{r['expected']:,.0f} MB/s" if r['expected'] else '-'
            rate_str = f"{r['rate']:.1f}%{'*' if r['speed'] and r['rate'] > 100 else ''}" if r['rate'] else '-'
            
            client_driver = hardware_info.get(r['client_ip'], {}).get('network', {}).get('driver', '')
            server_driver = hardware_info.get(r['server_ip'], {}).get('network', {}).get('driver', '')
            driver = client_driver if client_driver else server_driver
            driver = driver if driver else '-'
            
            nic_type = driver if driver and driver != '-' else 'Unknown'
            
            client_speed = hardware.get(r['client_ip'], {}).get('network', {}).get('speed', '')
            server_speed = hardware.get(r['server_ip'], {}).get('network', {}).get('speed', '')
            speed = client_speed if client_speed and client_speed != 'Unknown!' else server_speed
            if speed and speed != 'Unknown!':
                speed_str = speed
            else:
                speed_str = 'Unknown'
            
            html += f"""
        <tr class="{r['status']}">
          <td>{r['client_ip']}</td><td>{r['server_ip']}</td><td><strong>{r['bandwidth']:,.0f}</strong></td>
          <td>{nic_type}</td>
          <td>{driver}</td>
          <td>{speed_str}</td>
          <td>{expected_str}</td>
          <td>{rate_str}</td>
          <td>{retrans_tag}</td><td>{r['rtt']}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
    <p class="note">💡 Speed=Unknown 时不设阈值，仅展示实测带宽；达成率 * 表示实测超过标称值</p>
  </div>
"""
        return html
    
    def _generate_threads_section(self, results: List[Dict], hardware: Dict) -> str:
        arm_kvm = int(self.thresholds.get('threads_baseline_arm_kvm', 350))
        arm_phys = int(self.thresholds.get('threads_baseline_arm_physical', 50))
        x86_vm = int(self.thresholds.get('threads_baseline_x86_vmware', 350))
        x86_phys = int(self.thresholds.get('threads_baseline_x86_physical', 50))
        
        html = f"""
  <div class="section">
    <div class="section-title">线程调度性能对比</div>
    <div class="section-sub">公式：单核 evt/s = 总 evt/s ÷ 核数；期望基线(ARM KVM={arm_kvm}/物理机={arm_phys} / x86 VMware={x86_vm}/物理机={x86_phys})</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>架构/环境</th><th>核数</th>
          <th>总 evt/s</th><th>单核 evt/s</th><th>单核期望</th>
          <th>达成率</th><th>说明</th>
        </tr>
      </thead>
      <tbody>
"""
        
        for r in results:
            emoji = Config.get_status_emoji(Status(r['status']))
            ip = r['ip']
            model = hardware.get(ip, {}).get('cpu', {}).get('model', '')
            arch = hardware.get(ip, {}).get('cpu', {}).get('arch', '')
            is_virtual = r.get('is_virtual', False)
            
            if 'aarch64' in arch.lower() or 'ARM' in model or '鲲鹏' in model:
                env_desc = 'ARM KVM' if is_virtual else 'ARM 物理机'
            elif 'VMware' in model or is_virtual:
                env_desc = 'x86 VMware'
            else:
                env_desc = 'x86 物理机'
            
            html += f"""
        <tr class="{r['status']}">
          <td>{ip}</td><td>{env_desc}</td><td>{r['cores']}</td>
          <td>{r['events_sec']:,.0f}</td><td>{r['single_core']:,.1f}</td><td>{r['baseline']:,.0f}</td>
          <td>{r['rate']:.1f}% {emoji}</td>
          <td>{self._get_threads_note(r)}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
    <p class="note">💡 线程调度性能反映 OS 调度器效率和 CPU 上下文切换能力</p>
  </div>
"""
        return html
    
    def _get_threads_note(self, r: Dict) -> str:
        if r['status'] == Status.PASS.value:
            return '线程调度性能良好'
        elif r['status'] == Status.WARN.value:
            return '线程调度性能一般'
        else:
            return '线程调度性能偏低，建议关注'
    
    def _generate_mutex_section(self, results: List[Dict]) -> str:
        html = """
  <div class="section">
    <div class="section-title">互斥锁性能对比</div>
    <div class="section-sub">公式：TPS/core = 总 TPS ÷ 核数；期望基线(ARM KVM=20 / x86 VMware=15)</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>架构/环境</th><th>核数</th>
          <th>总 TPS</th><th>TPS/core</th><th>期望</th>
          <th>达成率</th><th>说明</th>
        </tr>
      </thead>
      <tbody>
"""
        
        for r in results:
            emoji = Config.get_status_emoji(Status(r['status']))
            
            html += f"""
        <tr class="{r['status']}">
          <td>{r['ip']}</td><td>{'ARM KVM' if r['baseline'] == 20 else 'x86 VMware'}</td><td>{r['cores']}</td>
          <td>{r['tps']:.2f}</td><td>{r['tps_per_core']:.2f}</td><td>{r['baseline']:,.0f}</td>
          <td>{r['rate']:.1f}% {emoji}</td>
          <td>{self._get_mutex_note(r)}</td>
        </tr>
"""
        
        html += """
      </tbody>
    </table>
    <p class="note">💡 互斥锁性能反映多线程并发场景下的锁争用处理能力</p>
  </div>
"""
        return html
    
    def _get_mutex_note(self, r: Dict) -> str:
        if r['status'] == Status.PASS.value:
            return '互斥锁性能良好'
        elif r['status'] == Status.WARN.value:
            return '互斥锁性能一般'
        else:
            return '互斥锁性能偏低，建议关注'
    
    def _generate_rules_section(self) -> str:
        html = """
  <div class="section">
    <div class="section-title">评估规则汇总</div>
    <table class="rule-table">
      <thead>
        <tr><th>指标</th><th>计算公式 / 期望值来源</th><th>良好（≥90%）</th><th>一般（≥75%）</th><th>需关注（&lt;75%）</th><th>跳过条件</th></tr>
      </thead>
      <tbody>
        <tr>
          <td>CPU 单核</td>
          <td>单核evt/s = 总evt/s÷核数<br>期望 = 基线(ARM 1250/x86 900) × 频率比</td>
          <td>达成率 ≥ 90%</td><td>75%-90%</td><td>&lt;75%</td>
          <td>无</td>
        </tr>
        <tr>
          <td>内存读写（虚拟机）</td>
          <td>经验值阈值判断<br>读 60,000-70,000 / 写 5,000-30,000 MiB/s</td>
          <td>达成率 ≥ 90%</td><td>75%-90%</td><td>&lt;75%</td>
          <td>无</td>
        </tr>
        <tr>
          <td>内存读写（物理机）</td>
          <td>JEDEC: 通道数×MT/s×8B × 效率系数<br>读95% / 写35%</td>
          <td>达成率 ≥ 90%</td><td>75%-90%</td><td>&lt;75%</td>
          <td>频率=N/A 时无法计算</td>
        </tr>
        <tr>
          <td>磁盘 IO</td>
          <td>实测 IOPS vs 介质基准</td>
          <td colspan="3" style="text-align:center; color:#666;">— 虚拟盘仅展示 —</td>
          <td>虚拟盘：展示实测，标注参考</td>
        </tr>
        <tr>
          <td>线程调度</td>
          <td>单核evt/s = threads evt/s÷核数；期望(ARM=1500/x86=3000)</td>
          <td>达成率 ≥ 90%</td><td>75%-90%</td><td>&lt;75%</td>
          <td>无</td>
        </tr>
        <tr>
          <td>网络（Speed 已知）</td>
          <td>期望 MB/s = 标称 Mbps÷8</td>
          <td>达成率 ≥ 90%</td><td>75%-90%</td><td>&lt;75%</td>
          <td>无</td>
        </tr>
        <tr>
          <td>网络（Speed=Unknown）</td>
          <td>不设期望值，直接展示实测</td>
          <td colspan="3" style="text-align:center; color:#666;">— 不判定，仅展示 —</td>
          <td>virtio_net / 无法获取 Speed</td>
        </tr>
      </tbody>
    </table>
  </div>
"""
        return html
    
    def _generate_footer(self) -> str:
        version = self.thresholds.get('report_version', '')
        return f"""
<div class="footer">
  oscheckperf 压测评估报告 &nbsp;·&nbsp; 规则版本：{version} &nbsp;·&nbsp; 生成时间：{datetime.now().strftime('%Y-%m-%d')}
</div>

</body>
</html>
"""