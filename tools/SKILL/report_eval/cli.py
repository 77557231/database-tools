import os
import sys
import glob
import argparse
from datetime import datetime
from typing import List, Optional

from .threshold_parser import ThresholdParser
from .report_parser import ReportParser
from .evaluator import AchievementEvaluator
from .html_generator import HTMLGenerator
from .comparator import ReportComparator
from .analyzer import ReportAnalyzer

def _get_version() -> str:
    skill_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    conf_path = os.path.join(skill_dir, 'thresholds.conf')
    if os.path.exists(conf_path):
        with open(conf_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line.startswith('REPORT_VERSION='):
                    return line.split('=', 1)[1].strip()
    return "unknown"


def find_latest_report(output_dir: str = "./output") -> Optional[str]:
    pattern = os.path.join(output_dir, "report_benchmark_*.log")
    files = glob.glob(pattern)
    if not files:
        return None
    return max(files, key=os.path.getmtime)


def parse_args(args: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="oscheckperf Report Evaluation Tool - Generate HTML evaluation report",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Auto find latest report
  python3 report_eval.py
  
  # Specify report file
  python3 report_eval.py output/report_benchmark_20260607_094937.log
  
  # Specify output directory
  python3 report_eval.py output/report_benchmark_20260607_094937.log -o /tmp/output
  
  # Compare multiple reports
  python3 report_eval.py output/report_benchmark_*.log
  
  # Compare specific report files
  python3 report_eval.py output/report1.log output/report2.log
"""
    )
    
    parser.add_argument(
        'report_files',
        nargs='*',
        help='Report file paths, supports multiple files for comparison, supports wildcards'
    )
    
    parser.add_argument(
        '-o', '--output-dir',
        default='./output',
        help='Output directory (default: ./output)'
    )
    
    parser.add_argument(
        '-v', '--version',
        action='version',
        version=f"oscheckperf Report Eval {_get_version()}"
    )
    
    parser.add_argument(
        '--auto-find',
        action='store_true',
        help='Automatically find the latest report file'
    )
    
    return parser.parse_args(args)


def expand_wildcards(files: List[str]) -> List[str]:
    expanded = []
    for f in files:
        if '*' in f or '?' in f:
            expanded.extend(glob.glob(f))
        else:
            expanded.append(f)
    return expanded


def validate_files(files: List[str]) -> List[str]:
    valid = []
    for f in files:
        if os.path.exists(f):
            valid.append(f)
        else:
            print(f"Warning: File not found, skipped: {f}", file=sys.stderr)
    return valid


def run_single_report(report_file: str, output_dir: str, thresholds: ThresholdParser):
    parser = ReportParser(report_file)
    evaluator = AchievementEvaluator(thresholds)
    
    basic_info = parser.parse_basic_info()
    hardware = parser.parse_hardware_summary()
    hardware_info = parser.parse_hardware_info()
    test_results = parser.parse_test_results()
    
    cpu_eval = None
    memory_eval = None
    io_eval = None
    threads_eval = None
    network_eval = None
    
    if test_results.get('cpu') and test_results['cpu'] is not None:
        cpu_eval = evaluator.evaluate_cpu(test_results['cpu'], hardware)
    
    if test_results.get('memory') and test_results['memory'] is not None:
        memory_eval = evaluator.evaluate_memory(test_results['memory'], hardware)
    
    if test_results.get('io') and test_results['io'] is not None:
        io_eval = evaluator.evaluate_io(test_results['io'], hardware)
    
    if test_results.get('threads') and test_results['threads'] is not None:
        threads_eval = evaluator.evaluate_threads(test_results['threads'], hardware)
    
    if test_results.get('network') and test_results['network'] is not None:
        network_eval = evaluator.evaluate_network(test_results['network'], hardware)
    
    analyzer = ReportAnalyzer(thresholds)
    analysis_text = analyzer.analyze_single_report(
        basic_info, hardware,
        cpu_eval or [], memory_eval or [],
        io_eval or [], threads_eval or [],
        network_eval or []
    )
    
    generator = HTMLGenerator(thresholds)
    html_content = generator.generate(
        basic_info, hardware, hardware_info,
        cpu_eval, memory_eval, io_eval,
        threads_eval, None, network_eval,
        analysis_text=analysis_text
    )
    
    import re
    match = re.search(r'report_benchmark_(\d{8}_\d{6})\.log', report_file)
    if match:
        timestamp = match.group(1)
    else:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = os.path.join(output_dir, f'report_eval_{timestamp}.html')
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"HTML: {output_file}")
    return output_file


def run_multi_report(report_files: List[str], output_dir: str, thresholds: ThresholdParser):
    comparator = ReportComparator(thresholds)
    comparison = comparator.compare_reports(report_files)
    
    analyzer = ReportAnalyzer(thresholds)
    analysis_text = analyzer.analyze_multi_report(comparison)
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = os.path.join(output_dir, f'report_compare_{timestamp}.html')
    
    html_content = generate_compare_html(comparison, thresholds, analysis_text)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"HTML: {output_file}")
    return output_file


def generate_compare_html(comparison: dict, thresholds: ThresholdParser, analysis_text: str = "") -> str:
    version = thresholds.get('report_version', '')
    reports = comparison['reports']
    merged = comparison['merged']
    summary = comparison['summary']
    
    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>oscheckperf 压测合并报告 {version}</title>
<style>
  :root {{
    --pass: #e8f5e9; --pass-b: #2e7d32; --pass-text: #1b5e20;
    --warn: #fff8e1; --warn-b: #f9a825; --warn-text: #e65100;
    --fail: #ffebee; --fail-b: #c62828; --fail-text: #b71c1c;
    --skip: #f5f5f5; --skip-b: #9e9e9e; --skip-text: #616161;
    --bg: #fafafa; --card: #ffffff; --border: #e0e0e0;
    --h1: #4527a0; --h2: #7c4dff; --accent: #311b92;
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ font-family: -apple-system, 'Segoe UI', 'PingFang SC', sans-serif; font-size: 13px; background: var(--bg); color: #212121; line-height: 1.6; }}
  .header {{ background: linear-gradient(135deg, #4527a0, #283593); color: white; padding: 24px 32px; }}
  .header h1 {{ font-size: 22px; margin-bottom: 6px; }}
  .header .meta {{ display: flex; gap: 32px; font-size: 13px; opacity: 0.9; flex-wrap: wrap; }}
  .summary {{ margin: 20px 32px; padding: 16px 20px; background: #e8eaf6; border-radius: 8px; }}
  .summary h2 {{ font-size: 16px; margin-bottom: 8px; color: #4527a0; }}
  .analysis-banner {{ margin: 16px 32px; padding: 20px; background: linear-gradient(135deg, #e8f5e9, #e3f2fd); border-radius: 10px; border-left: 4px solid #2e7d32; }}
  .analysis-banner h2 {{ font-size: 16px; margin-bottom: 10px; color: #1b5e20; }}
  .analysis-banner ul {{ margin: 0; padding-left: 20px; }}
  .analysis-banner li {{ margin-bottom: 6px; font-size: 13px; color: #333; }}
  .content {{ padding: 0 32px 32px; }}
  .section {{ margin-bottom: 28px; }}
  .section-title {{ font-size: 15px; font-weight: 700; color: var(--h1); border-bottom: 2px solid var(--h2); padding-bottom: 6px; margin-bottom: 14px; }}
  .section-sub {{ font-size: 13px; color: #555; margin-bottom: 10px; }}
  .cmp-table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  .cmp-table th {{ background: #311b92; color: white; padding: 8px 10px; text-align: left; white-space: nowrap; }}
  .cmp-table td {{ padding: 7px 10px; border-bottom: 1px solid var(--border); }}
  .cmp-table tr:nth-child(even) td {{ background: #fafafa; }}
  .cmp-table tr.pass td {{ background: var(--pass); }}
  .cmp-table tr.warn td {{ background: var(--warn); }}
  .cmp-table tr.fail td {{ background: var(--fail); }}
  .net-table {{ width: 100%; border-collapse: collapse; font-size: 12px; }}
  .net-table th {{ background: #004d40; color: white; padding: 7px 10px; text-align: left; white-space: nowrap; }}
  .net-table td {{ padding: 6px 10px; border-bottom: 1px solid var(--border); }}
  .source-tag {{ font-size: 11px; color: #666; background: #e0e0e0; padding: 2px 6px; border-radius: 3px; }}
  .footer {{ text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid var(--border); margin-top: 20px; }}
  @media (max-width: 900px) {{
    .content, .summary, .analysis-banner {{ margin-left: 12px; margin-right: 12px; padding-left: 10px; padding-right: 10px; }}
  }}
</style>
</head>
<body>
<div class="header">
  <h1>🗄️ oscheckperf 压测合并报告</h1>
  <div class="meta">
    <span>📅 生成时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</span>
    <span>📁 报告数量：{summary['total_reports']} 个</span>
    <span>🖥️ 总节点数：{summary['total_nodes']} 个</span>
    <span>📋 规则版本：{version}</span>
  </div>
</div>
"""
    
    html += """<div class="summary">
  <h2>📌 报告列表</h2>
  <ul style="margin-left: 20px;">
"""
    for i, report in enumerate(reports, 1):
        html += f"    <li><strong>报告 {i}</strong>: {report['file']} - 压测时间: {report['basic_info'].get('test_time', '')}</li>\n"
    html += """  </ul>
</div>
"""
    
    if analysis_text:
        analysis_lines = analysis_text.split('\n')
        html += """<div class="analysis-banner">
  <h2>🧠 智能分析报告</h2>
  <ul>
"""
        for line in analysis_lines:
            if line.strip():
                html += f"    <li>{line.strip()}</li>\n"
        html += """  </ul>
</div>
"""
    
    html += "<div class=\"content\">"
    
    if merged.get('cpu'):
        html += """
  <div class="section">
    <div class="section-title">CPU 单核效率对比（全集群）</div>
    <div class="section-sub">公式：单核 evt/s = 总evt/s ÷ 核数；期望 = 基线(ARM=1250 / x86=900) × (实际频率/参考频率)</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>来源</th><th>架构/环境</th><th>核数</th><th>频率</th>
          <th>总 evt/s</th><th>单核 evt/s</th><th>单核期望</th>
          <th>达成率</th><th>说明</th>
        </tr>
      </thead>
      <tbody>
"""
        for r in merged['cpu']:
            ip = r['ip']
            source = r.get('source', '')
            model = merged['hardware'].get(ip, {}).get('cpu', {}).get('model', '')
            arch = merged['hardware'].get(ip, {}).get('cpu', {}).get('arch', '')
            freq = merged['hardware'].get(ip, {}).get('cpu', {}).get('freq', '')
            
            env_desc = 'ARM' if 'aarch64' in arch.lower() or 'ARM' in model else 'x86'
            if 'VMware' in model:
                env_desc += ' VMware'
            elif 'KVM' in model:
                env_desc += ' KVM'
            
            emoji = '🟢' if r['rate'] >= 90 else '🟡' if r['rate'] >= 75 else '🔴'
            
            html += f"""
        <tr class="{r['status']}">
          <td>{ip}</td><td><span class="source-tag">{source}</span></td><td>{env_desc}（{model.split('@')[0] if '@' in model else model[:30]}）</td>
          <td>{r['cores']}</td><td>{freq} GHz</td>
          <td>{r['events_sec']:,.1f}</td><td>{r['single_core']:,.1f}</td><td>{r['baseline']:,.0f}</td>
          <td>{r['rate']:.1f}% {emoji}</td>
          <td>{'单核效率良好' if r['rate'] >= 90 else '单核效率一般，建议关注' if r['rate'] >= 75 else '单核效率偏低，建议排查'}</td>
        </tr>
"""
        html += """
      </tbody>
    </table>
  </div>
"""
    
    if merged.get('memory'):
        read_results = [r for r in merged['memory'] if r['mode'] == 'read']
        write_results = [r for r in merged['memory'] if r['mode'] == 'write']
        
        html += """
  <div class="section">
    <div class="section-title">内存带宽横向对比</div>
    <div class="section-sub">虚机内存不适用 JEDEC 公式，按经验阈值评估</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>来源</th>
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
            source = read.get('source', '') if read else (write.get('source', '') if write else '')
            
            read_emoji = '🟢' if read and read['rate'] >= 90 else '🟡' if read and read['rate'] >= 75 else '🔴' if read else ''
            write_emoji = '🟢' if write and write['rate'] >= 90 else '🟡' if write and write['rate'] >= 75 else '🔴' if write else ''
            
            status = 'pass'
            if read and read['status'] == 'fail' or write and write['status'] == 'fail':
                status = 'fail'
            elif read and read['status'] == 'warn' or write and write['status'] == 'warn':
                status = 'warn'
            
            html += f"""
        <tr class="{status}">
          <td>{ip}</td><td><span class="source-tag">{source}</span></td>
          <td>{read['mib_sec']:,.0f}</td><td>{read['baseline']:,.0f}</td><td>{read['rate']:.1f}% {read_emoji}</td>
          <td>{write['mib_sec']:,.0f}</td><td>{write['baseline']:,.0f}</td><td>{write['rate']:.1f}% {write_emoji}</td>
          <td>{'虚机环境，读写均按经验值评估' if read and read['is_vm'] else '物理机环境，按JEDEC公式评估'}</td>
        </tr>
"""
        html += """
      </tbody>
    </table>
  </div>
"""
    
    if merged.get('io'):
        html += """
  <div class="section">
    <div class="section-title">磁盘 IO 横向对比</div>
    <div class="section-sub">IO 性能取决于存储介质和配置；展示实测值供参考</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>来源</th><th>介质</th><th>模式</th><th>读 IOPS</th><th>写 IOPS</th>
          <th>BW (MB/s)</th><th>平均延迟 (ms)</th>
        </tr>
      </thead>
      <tbody>
"""
        for r in merged['io']:
            disk_type = merged['hardware'].get(r['ip'], {}).get('io', {}).get('type', 'Unknown')
            source = r.get('source', '')
            html += f"""
        <tr class="{r['status']}">
          <td>{r['ip']}</td><td><span class="source-tag">{source}</span></td><td>{disk_type}</td><td>{r['mode']}</td>
          <td>{int(r['read_iops']) if r['read_iops'] else 'N/A'}</td>
          <td>{int(r['write_iops']) if r['write_iops'] else 'N/A'}</td>
          <td>{r['total_bw']:,.0f}</td>
          <td>{r['latency']:.2f}</td>
        </tr>
"""
        html += """
      </tbody>
    </table>
  </div>
"""
    
    if merged.get('threads'):
        html += """
  <div class="section">
    <div class="section-title">线程调度性能对比</div>
    <div class="section-sub">公式：单核 evt/s = 总 evt/s ÷ 核数；期望基线(ARM KVM=350/物理机=50 / x86 VMware=350/物理机=50)</div>
    <table class="cmp-table">
      <thead>
        <tr>
          <th>IP 地址</th><th>来源</th><th>架构/环境</th><th>核数</th>
          <th>总 evt/s</th><th>单核 evt/s</th><th>单核期望</th>
          <th>达成率</th><th>说明</th>
        </tr>
      </thead>
      <tbody>
"""
        for r in merged['threads']:
            source = r.get('source', '')
            ip = r['ip']
            model = merged['hardware'].get(ip, {}).get('cpu', {}).get('model', '')
            arch = merged['hardware'].get(ip, {}).get('cpu', {}).get('arch', '')
            is_virtual = r.get('is_virtual', False)
            
            if 'aarch64' in arch.lower() or 'ARM' in model or '鲲鹏' in model:
                env_desc = 'ARM KVM' if is_virtual else 'ARM 物理机'
            elif 'VMware' in model or is_virtual:
                env_desc = 'x86 VMware'
            else:
                env_desc = 'x86 物理机'
            
            emoji = '🟢' if r['rate'] >= 90 else '🟡' if r['rate'] >= 75 else '🔴'
            
            html += f"""
        <tr class="{r['status']}">
          <td>{ip}</td><td><span class="source-tag">{source}</span></td><td>{env_desc}</td><td>{r['cores']}</td>
          <td>{r['events_sec']:,.0f}</td><td>{r['single_core']:,.1f}</td><td>{r['baseline']:,.0f}</td>
          <td>{r['rate']:.1f}% {emoji}</td>
          <td>{'线程调度性能良好' if r['rate'] >= 90 else '线程调度性能一般' if r['rate'] >= 75 else '线程调度性能偏低'}</td>
        </tr>
"""
    
    if merged.get('network'):
        html += """
  <div class="section">
    <div class="section-title">网络带宽矩阵</div>
    <div class="section-sub">Speed=Unknown：不设阈值，仅展示实测；Speed 已知：按标称 Mbps÷8 计算期望 MB/s</div>
    <table class="net-table">
      <thead>
        <tr>
          <th>来源</th><th>发起节点</th><th>目标节点</th><th>实测 MB/s</th>
          <th>标称速率</th><th>期望 MB/s</th><th>达成率</th>
          <th>重传次数</th><th>RTT (ms)</th>
        </tr>
      </thead>
      <tbody>
"""
        for r in merged['network']:
            source = r.get('source', '')
            retrans_tag = f'{r["retrans"]} ⚠' if r.get('retrans_status') == 'warn' else r['retrans']
            expected_str = f"{r['expected']:,.0f} MB/s" if r['expected'] else '-'
            rate_str = f"{r['rate']:.1f}%" if r['rate'] else '-'
            
            html += f"""
        <tr class="{r['status']}">
          <td><span class="source-tag">{source}</span></td><td>{r['client_ip']}</td><td>{r['server_ip']}</td><td><strong>{r['bandwidth']:,.0f}</strong></td>
          <td>{r.get('speed', 'Unknown')}</td>
          <td>{expected_str}</td>
          <td>{rate_str}</td>
          <td>{retrans_tag}</td><td>{r['rtt']}</td>
        </tr>
"""
        html += """
      </tbody>
    </table>
  </div>
"""
    
    html += "</div>"
    html += f"""
<div class="footer">
  oscheckperf 压测合并报告 &nbsp;·&nbsp; 规则版本：{version} &nbsp;·&nbsp; 生成时间：{datetime.now().strftime('%Y-%m-%d')}
</div>
</body>
</html>
"""
    
    return html


def main():
    args = parse_args(sys.argv[1:])
    
    skill_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    thresholds = ThresholdParser(skill_dir)
    
    report_files = args.report_files
    
    if not report_files or args.auto_find:
        latest = find_latest_report()
        if latest:
            report_files = [latest]
            print(f"Auto found latest report: {latest}")
        else:
            print("Error: No report file found, please specify report file path", file=sys.stderr)
            sys.exit(1)
    
    report_files = expand_wildcards(report_files)
    report_files = validate_files(report_files)
    
    if not report_files:
        print("Error: No valid report files", file=sys.stderr)
        sys.exit(1)
    
    os.makedirs(args.output_dir, exist_ok=True)
    
    if len(report_files) == 1:
        run_single_report(report_files[0], args.output_dir, thresholds)
    else:
        run_multi_report(report_files, args.output_dir, thresholds)