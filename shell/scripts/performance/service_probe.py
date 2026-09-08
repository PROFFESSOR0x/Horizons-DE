#!/usr/bin/env python3
"""Compare HEAD and working-tree HyprlandData in isolated, windowless QS roots.

Only reads live compositor state. The deliberately repeated updateAll workload
measures publication/fork overhead, not natural user activity or frame rates.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

SHELL = Path(__file__).resolve().parents[2]
REPO = SHELL.parent


def probe(baseline):
    with tempfile.TemporaryDirectory(prefix='horizons-service-probe-') as directory:
        root = Path(directory)
        services = root / 'services'
        services.mkdir()
        source = subprocess.check_output(['git', 'show', 'HEAD:shell/services/HyprlandData.qml'], cwd=REPO).decode() if baseline else (SHELL / 'services/HyprlandData.qml').read_text()
        (services / 'HyprlandData.qml').write_text(source)
        (services / 'HyprlandSnapshot.qml').write_text((SHELL / 'services/HyprlandSnapshot.qml').read_text())
        (services / 'WM.qml').write_text('pragma Singleton\nimport Quickshell\nSingleton { property string compositor: "hyprland" }\n')
        (root / 'shell.qml').write_text('''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    property int ticks: 0
    property int windows: 0
    property int monitors: 0
    property int workspaces: 0
    property int active: 0
    Connections {
        target: HyprlandData
        function onWindowListChanged() { windows++ }
        function onMonitorsChanged() { monitors++ }
        function onWorkspacesChanged() { workspaces++ }
        function onActiveWorkspaceChanged() { active++ }
    }
    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: {
            ticks++
            if (ticks <= 25) { HyprlandData.updateAll(); return }
            console.log("PROBE_RESULT " + JSON.stringify({ticks: ticks - 1, windows, monitors, workspaces, active}))
            Qt.quit()
        }
    }
}
''')
        env = dict(os.environ, QT_QPA_PLATFORM='wayland')
        start = time.monotonic()
        with subprocess.Popen(['quickshell', '-p', str(root), '--no-color'], env=env,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) as proc:
            rss = []; ticks = []
            while proc.poll() is None and time.monotonic() - start < 15:
                try:
                    stat = Path(f'/proc/{proc.pid}/stat').read_text().rsplit(')', 1)[1].split()
                    ticks.append(int(stat[11]) + int(stat[12]))
                    rss.append(int(stat[21]) * os.sysconf('SC_PAGE_SIZE') / 1024 / 1024)
                except (OSError, IndexError):
                    pass
                time.sleep(.1)
            if proc.poll() is None:
                proc.kill()
            output = proc.communicate()[0]
        result = None
        for line in output.splitlines():
            if 'PROBE_RESULT ' in line:
                result = json.loads(line.split('PROBE_RESULT ', 1)[1])
        if result is None:
            raise RuntimeError(output)
        result.update(peak_rss_mib=max(rss), process_cpu_seconds=(max(ticks) - min(ticks))/os.sysconf('SC_CLK_TCK'),
                      elapsed_seconds=time.monotonic() - start)
        return result


if __name__ == '__main__':
    results = {'notes': '25 explicit full refreshes at 200ms, live compositor; CPU excludes child processes; peak RSS sampled at 100ms.',
               'baseline': probe(True), 'optimized': probe(False)}
    text = json.dumps(results, indent=2)
    (REPO / 'docs/performance/service-probe.json').write_text(text + '\n')
    print(text)
