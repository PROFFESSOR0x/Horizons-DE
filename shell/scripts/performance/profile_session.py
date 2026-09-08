#!/usr/bin/env python3
"""Sample a running shell's /proc counters without attaching a debugger."""
import argparse
import json
import os
from pathlib import Path
import time


def read(pid):
    base = Path('/proc') / str(pid)
    stat = (base / 'stat').read_text().rsplit(')', 1)[1].split()
    status = dict(line.split(':', 1) for line in (base / 'status').read_text().splitlines() if ':' in line)
    return {'cpu_ticks': int(stat[11]) + int(stat[12]), 'start_ticks': int(stat[19]),
            'rss_mib': int(stat[21]) * os.sysconf('SC_PAGE_SIZE') / 1048576,
            'voluntary_switches': int(status['voluntary_ctxt_switches']),
            'involuntary_switches': int(status['nonvoluntary_ctxt_switches'])}


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('pid', type=int)
    p.add_argument('--seconds', type=int, default=20)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    if not 1 <= args.seconds <= 60: p.error('seconds must be 1–60')
    start = time.monotonic(); first = read(args.pid); samples = [first]
    for _ in range(args.seconds):
        time.sleep(1)
        samples.append(read(args.pid))
    elapsed = time.monotonic() - start
    last = samples[-1]
    if last['start_ticks'] != first['start_ticks']: raise RuntimeError('PID was reused')
    result = {'pid': args.pid, 'elapsed_seconds': elapsed,
              'cpu_percent_one_core': (last['cpu_ticks'] - first['cpu_ticks']) / os.sysconf('SC_CLK_TCK') / elapsed * 100,
              'rss_start_mib': first['rss_mib'], 'rss_end_mib': last['rss_mib'],
              'rss_peak_mib': max(s['rss_mib'] for s in samples),
              'main_thread_voluntary_switches': last['voluntary_switches'] - first['voluntary_switches'],
              'notes': 'Single running QS process; excludes children, GPU, compositor and other thread context switches. Uncontrolled live desktop.'}
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
