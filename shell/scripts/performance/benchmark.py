#!/usr/bin/env python3
"""Read-only, rate-limited IPC and hardware microbenchmarks; no window actions."""
import argparse
import json
import os
from pathlib import Path
import statistics
import socket
import subprocess
import time

SHELL = Path(__file__).resolve().parents[2]


def measure(action, count):
    durations = []
    for _ in range(count):
        start = time.perf_counter_ns()
        action()
        durations.append((time.perf_counter_ns() - start) / 1e6)
        time.sleep(.03)
    return {'n': count, 'median_ms': statistics.median(durations),
            'p95_ms': sorted(durations)[min(count - 1, int(count * .95))],
            'min_ms': min(durations), 'max_ms': max(durations)}


def run(command):
    return subprocess.run(command, capture_output=True, timeout=4, check=True).stdout


def direct_clients():
    path = Path(os.environ['XDG_RUNTIME_DIR']) / 'hypr' / os.environ['HYPRLAND_INSTANCE_SIGNATURE'] / '.socket.sock'
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(2)
        connection.connect(str(path))
        connection.sendall(b'j/clients')
        chunks = []
        while True:
            chunk = connection.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
    return json.loads(b''.join(chunks))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--samples', type=int, default=30)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if not 1 <= args.samples <= 100:
        parser.error('samples must be 1–100')
    old_hardware = "sensors 2>/dev/null | grep -E 'Package id 0|Tctl|Tdie' | grep -oP '\\+\\K[0-9.]+(?=°C)' | head -1"
    old_gpu = '''if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1; else busy=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1); traw=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1); [ -n "$busy" ] && echo "$busy, $(( ${traw:-0} / 1000 ))"; fi'''
    def old_sample():
        # Baseline ran these concurrently; preserve that instead of summing latency.
        children = [subprocess.Popen(['bash', '-c', cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    for cmd in (old_hardware, old_gpu, "df -k / | awk 'NR==2{print $2,$3,$4}'")]
        for child in children:
            child.communicate(timeout=4)
    results = {'timestamp': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
               'quickshell': run(['quickshell', '--version']).decode().strip(),
               'hyprland': run(['hyprctl', 'version']).decode().splitlines()[0],
               'notes': 'Warm microbenchmarks in an active desktop; not FPS or whole-shell CPU savings.'}
    for name, action in [
        ('hyprctl_clients', lambda: json.loads(run(['hyprctl', 'clients', '-j']))),
        ('direct_socket_clients', direct_clients),
        ('old_hardware_pipelines', old_sample),
        ('new_hardware_python', lambda: json.loads(run(['python3', str(SHELL / 'scripts/system/hardware_sample.py')]))),
    ]:
        results[name] = measure(action, args.samples)
    with subprocess.Popen(['python3', str(SHELL / 'scripts/system/hardware_sample.py'), '--serve'],
                          stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True) as worker:
        def steady_sample():
            worker.stdin.write('sample\n')
            worker.stdin.flush()
            return json.loads(worker.stdout.readline())
        results['persistent_hardware_startup'] = measure(steady_sample, 1)
        results['persistent_hardware_steady'] = measure(steady_sample, args.samples)
        worker.stdin.close()
        worker.wait(timeout=4)
    results['hardware_sample'] = json.loads(run(['python3', str(SHELL / 'scripts/system/hardware_sample.py')]))
    text = json.dumps(results, indent=2)
    if args.output:
        args.output.write_text(text + '\n')
    print(text)


if __name__ == '__main__':
    main()
