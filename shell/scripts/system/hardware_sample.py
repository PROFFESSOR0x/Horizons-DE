#!/usr/bin/env python3
"""One bounded hardware sample, using kernel interfaces before vendor tools.

No shell pipelines; absent sensors remain absent. Kept separate from the GUI
thread because filesystem/driver calls can stall. All sizes are KiB.
"""
import glob
import json
from pathlib import Path
import shutil
import subprocess
import sys


def number(path):
    try:
        return float(Path(path).read_text().strip())
    except (OSError, ValueError):
        return None


def sample():
    result = {}
    for directory in sorted(glob.glob('/sys/class/hwmon/hwmon*')):
        base = Path(directory)
        try:
            driver = (base / 'name').read_text().strip()
        except OSError:
            continue
        if driver not in ('coretemp', 'k10temp', 'zenpower', 'cpu_thermal'):
            continue
        candidates = []
        for sensor in base.glob('temp*_input'):
            value = number(sensor)
            if value is not None:
                candidates.append(value / 1000)
        if candidates:
            result['cpuTemp'] = max(candidates)
            break
    for directory in sorted(glob.glob('/sys/class/drm/card[0-9]*/device')):
        busy = number(Path(directory) / 'gpu_busy_percent')
        if busy is None:
            continue
        result['gpuUsage'] = max(0, min(1, busy / 100))
        for path in sorted(glob.glob(directory + '/hwmon/hwmon*/temp1_input')):
            temp = number(path)
            if temp is not None:
                result['gpuTemp'] = temp / 1000
                break
        break
    if 'gpuUsage' not in result and shutil.which('nvidia-smi'):
        try:
            proc = subprocess.run(['nvidia-smi', '--query-gpu=utilization.gpu,temperature.gpu',
                                   '--format=csv,noheader,nounits'],
                                  capture_output=True, text=True, timeout=1.5, check=True)
            usage, temp = map(float, proc.stdout.splitlines()[0].split(','))
            result.update(gpuUsage=max(0, min(1, usage / 100)), gpuTemp=temp)
        except (OSError, ValueError, IndexError, subprocess.SubprocessError):
            pass
    return result


if __name__ == '__main__':
    if '--serve' in sys.argv:
        # One response per request. EOF exits with the owning Quickshell process.
        for line in sys.stdin:
            if line.strip() == 'sample':
                print(json.dumps(sample(), allow_nan=False), flush=True)
    else:
        print(json.dumps(sample(), allow_nan=False))
