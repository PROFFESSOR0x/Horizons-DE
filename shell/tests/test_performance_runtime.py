"""Execute the real scheduler and sampling code in Quickshell's QML engine."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import socket
import threading
import time
import unittest

SHELL = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell required')
class RuntimeTests(unittest.TestCase):
    def run_qml(self, body, files=None, imports=""):
        with tempfile.TemporaryDirectory(prefix='horizons-perf-test-') as directory:
            root = Path(directory)
            shutil.copy(SHELL / 'services/HyprlandSnapshot.qml', root)
            for name, contents in (files or {}).items():
                (root / name).parent.mkdir(parents=True, exist_ok=True)
                (root / name).write_text(contents)
            (root / 'shell.qml').write_text('import QtQuick\nimport Quickshell\n' + imports + '\nShellRoot {\n' + body + '\n}')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen')
            env.pop('WAYLAND_DISPLAY', None)
            result = subprocess.run(['quickshell', '-p', str(root), '--no-color'],
                                    env=env, capture_output=True, text=True, timeout=15)
            output = result.stdout + result.stderr
            self.assertIn('PERF_PASS', output, output)
            self.assertNotIn('FAIL:', output, output)
            for error in ('TypeError:', 'ReferenceError:', 'Failed to load configuration'):
                self.assertNotIn(error, output, output)
            return output

    def test_burst_dedup_failure_and_recovery(self):
        self.run_qml('''
    property int stage: 0
    property int received: 0
    HyprlandSnapshot {
        id: request
        query: "fixture"
        command: ["python3", Quickshell.shellPath("fixture.py")]
        onSnapshot: value => { received++ }
    }
    Component.onCompleted: { for (let i = 0; i < 100; ++i) request.request() }
    Timer {
        interval: 250; running: true; repeat: true
        onTriggered: {
            stage++
            if (stage <= 3) { request.request(); return }
            if (request.requests !== 4 || received !== 2 || request.failures !== 1)
                console.log("FAIL: " + JSON.stringify([request.requests, received, request.failures]))
            else console.log("PERF_PASS")
            Qt.quit()
        }
    }
''', {'fixture.py': '''from pathlib import Path
p = Path(__file__).with_suffix('.count')
n = int(p.read_text()) + 1 if p.exists() else 1
p.write_text(str(n))
print('broken' if n == 3 else ('[1]' if n < 3 else '[2]'))
'''})

    def test_continuous_events_do_not_starve(self):
        self.run_qml('''
    property int ticks: 0
    HyprlandSnapshot {
        id: request; query: "fixture"
        command: ["python3", "-c", "import time; time.sleep(.04); print('[]')"]
    }
    Timer {
        interval: 5; running: true; repeat: true
        onTriggered: {
            ticks++; request.request()
            if (ticks === 60) {
                if (request.requests < 2 || request.publications !== 1)
                    console.log("FAIL: continuous events starved scheduler")
                else console.log("PERF_PASS")
                Qt.quit()
            }
        }
    }
''')

    def test_timeout_releases_inflight_slot(self):
        self.run_qml('''
    HyprlandSnapshot {
        id: request; query: "fixture"; timeoutMs: 80
        command: ["python3", "-c", "import time; time.sleep(3); print('[]')"]
    }
    Component.onCompleted: request.request()
    Timer {
        interval: 250; running: true
        onTriggered: {
            if (request.failures !== 1) console.log("FAIL: timeout did not finish")
            request.command = ["printf", "[]"]
            request.request()
        }
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            if (request.publications !== 1 || request.requests !== 2)
                console.log("FAIL: request slot stayed busy")
            else console.log("PERF_PASS")
            Qt.quit()
        }
    }
''')

    def test_socket_fragmentation_reconnect_and_invalid_json(self):
        with tempfile.TemporaryDirectory(prefix='horizons-ipc-') as directory:
            path = str(Path(directory) / 'request.sock')
            server = socket.socket(socket.AF_UNIX)
            server.bind(path)
            server.listen(4)
            server.settimeout(5)
            errors = []
            def serve():
                try:
                    for payload in ('[{"id":1,"title":"آفاق 🖥"}]'.encode(), b'broken', b'[{"id":2}]'):
                        connection, _ = server.accept()
                        with connection:
                            self.assertEqual(connection.recv(1024), b'j/fixture')
                            for chunk in (bytes([value]) for value in payload):
                                connection.sendall(chunk)
                                time.sleep(.001)
                except Exception as error:
                    errors.append(error)
                finally:
                    server.close()
            worker = threading.Thread(target=serve, daemon=True)
            worker.start()
            self.run_qml('''
    property int stage: 0
    property int lastId: 0
    HyprlandSnapshot {
        id: request; query: "fixture"
        socketPath: ''' + json.dumps(path) + '''
        onSnapshot: value => {
            lastId = value[0].id
            if (lastId === 1 && value[0].title !== "آفاق 🖥") console.log("FAIL: split UTF-8")
        }
    }
    Component.onCompleted: request.request()
    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: {
            stage++
            if (stage === 2 && lastId !== 1) console.log("FAIL: erased last valid data")
            if (stage < 3) { request.request(); return }
            if (lastId !== 2 || request.failures !== 1 || request.publications !== 2)
                console.log("FAIL: socket framing/recovery " + JSON.stringify([lastId, request.failures, request.publications]))
            else console.log("PERF_PASS")
            Qt.quit()
        }
    }
''')
            worker.join(timeout=6)
            self.assertFalse(errors, errors)
            self.assertFalse(worker.is_alive())

    @unittest.skipUnless(os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'), 'Hyprland session required')
    def test_live_hyprland_readonly_socket(self):
        path = str(Path(os.environ['XDG_RUNTIME_DIR']) / 'hypr' /
                   os.environ['HYPRLAND_INSTANCE_SIGNATURE'] / '.socket.sock')
        self.run_qml('''
    HyprlandSnapshot {
        id: request; query: "clients"
        socketPath: ''' + json.dumps(path) + '''
        onSnapshot: value => { console.log("PERF_PASS"); Qt.quit() }
    }
    Component.onCompleted: request.request()
    Timer { interval: 3000; running: true; onTriggered: { console.log("FAIL: no live snapshot"); Qt.quit() } }
''')

    def test_resource_service_live_readings_and_pause(self):
        self.run_qml('''
    property int stage: 0
    property int samples: 0
    property int pausedSamples: 0
    Connections { target: ResourceUsage; function onCpuUsageHistoryChanged() { samples++ } }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            stage++
            if (stage === 3) {
                if (ResourceUsage.memoryTotal <= 1 || ResourceUsage.diskTotal <= 1
                    || samples < 1 || !Number.isFinite(ResourceUsage.cpuTemp)) console.log("FAIL: live samples missing")
                ResourceUsage.release()
                if (ResourceUsage.activeConsumers !== 1) console.log("FAIL: shared ownership")
            } else if (stage === 4) ResourceUsage.release()
            else if (stage === 5) pausedSamples = samples
            else if (stage === 6) {
                if (samples !== pausedSamples || ResourceUsage.activeConsumers !== 0) console.log("FAIL: polling while hidden")
                ResourceUsage.acquire()
            } else if (stage === 8) {
                if (samples <= pausedSamples) console.log("FAIL: no samples after resume")
                else console.log("PERF_PASS")
                ResourceUsage.release()
                Qt.quit()
            }
        }
    }
    Component.onCompleted: { ResourceUsage.acquire(); ResourceUsage.acquire() }
''', {
            'services/ResourceUsage.qml': (SHELL / 'services/ResourceUsage.qml').read_text(),
            'modules/common/Config.qml': 'pragma Singleton\nimport Quickshell\nSingleton { property var options: ({resources: {updateInterval: 1000, historyLength: 4}}) }',
            'modules/common/Directories.qml': 'pragma Singleton\nimport Quickshell\nSingleton { property string scriptPath: ' + json.dumps(str(SHELL / 'scripts')) + ' }',
        }, imports='import qs.services')

    def test_socket_connection_failure_releases_slot(self):
        self.run_qml('''
    HyprlandSnapshot { id: request; query: "fixture"; socketPath: Quickshell.shellPath("missing.sock") }
    Component.onCompleted: request.request()
    Timer {
        interval: 200; running: true
        onTriggered: {
            if (request.busy || request.failures !== 1) console.log("FAIL: connect failure stuck")
            request.socketPath = ""
            request.command = ["printf", "[]"]
            request.request()
        }
    }
    Timer {
        interval: 400; running: true
        onTriggered: {
            if (request.publications !== 1) console.log("FAIL: recovery missing")
            else console.log("PERF_PASS")
            Qt.quit()
        }
    }
''')

    def test_sidebar_pages_load_once_when_visited(self):
        stubs = {
            'SidebarLeftContent.qml': (SHELL / 'modules/ii/sidebarLeft/SidebarLeftContent.qml').read_text(),
            'modules/common/Config.qml': 'pragma Singleton\nimport Quickshell\nSingleton { property var options: ({policies:{ai:1,weeb:0},sidebar:{translator:{enable:true},media:{enable:true}}}) }',
            'modules/common/Appearance.qml': 'pragma Singleton\nimport Quickshell\nSingleton { property var colors: ({colLayer1:"black", colSubtext:"white"}); property var rounding: ({normal:5,small:3}) }',
            'services/Translation.qml': 'pragma Singleton\nimport Quickshell\nSingleton { function tr(s) { return s } }',
            'modules/common/widgets/VerticalTabBar.qml': 'import QtQuick\nItem { property var tabButtonList: []; property int currentIndex: 0; property bool expanded: false }',
            'modules/common/widgets/StyledText.qml': 'import QtQuick\nText {}',
        }
        for name in ('AiChat', 'Translator', 'SidebarPlayerControl', 'Anime'):
            stubs[name + '.qml'] = 'import QtQuick\nItem { Component.onCompleted: console.log("PAGE_CREATED ' + name + '") }'
        output = self.run_qml('''
    property int stage: 0
    SidebarLeftContent { id: content; scopeRoot: null; width: 400; height: 600 }
    function findView(item) {
        if (item.currentItem !== undefined && item.incrementCurrentIndex !== undefined) return item
        for (const child of item.children ?? []) { const found = findView(child); if (found) return found }
        return null
    }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            const view = findView(content)
            if (!view) { console.log("FAIL: no swipe view"); Qt.quit(); return }
            stage++
            if (stage === 1) view.setCurrentIndex(1)
            else if (stage === 2) view.setCurrentIndex(0)
            else { console.log("PERF_PASS"); Qt.quit() }
        }
    }
''', stubs)
        self.assertEqual(output.count('PAGE_CREATED AiChat'), 1, output)
        self.assertEqual(output.count('PAGE_CREATED Translator'), 1, output)
        self.assertNotIn('PAGE_CREATED SidebarPlayerControl', output)

    def test_visibility_lease_balances_destruction_and_reactivation(self):
        self.run_qml('''
    property int stage: 0
    Loader { id: first; sourceComponent: ResourceUsageLease { active: true } }
    ResourceUsageLease { id: second; active: true }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            stage++
            if (stage === 1) {
                if (ResourceUsage.count !== 2) console.log("FAIL: initial leases")
                first.active = false
            } else if (stage === 2) {
                if (ResourceUsage.count !== 1) console.log("FAIL: destroyed lease")
                second.active = false
            } else if (stage === 3) {
                if (ResourceUsage.count !== 0) console.log("FAIL: hidden lease")
                second.active = true
            } else {
                if (ResourceUsage.count !== 1) console.log("FAIL: reactivated lease")
                else console.log("PERF_PASS")
                Qt.quit()
            }
        }
    }
''', {
            'services/ResourceUsageLease.qml': (SHELL / 'services/ResourceUsageLease.qml').read_text(),
            'services/ResourceUsage.qml': 'pragma Singleton\nimport Quickshell\nSingleton { property int count: 0; function acquire() { count++ } function release() { count-- } }',
        }, imports='import qs.services')

    def test_resource_parsing_in_qml(self):
        # Extract production functions unchanged; no shell services are started.
        source = (SHELL / 'services/ResourceUsage.qml').read_text()
        start = source.index('    function acceptMemory(')
        end = source.index('    Timer {', start)
        self.run_qml('''
    property real memoryTotal: 1
    property real memoryFree: 0
    property real swapTotal: 0
    property real swapFree: 0
    property real cpuUsage: 0
    property var previousCpuStats
    property int samples: 0
    function updateMemoryUsageHistory() {}
    function updateSwapUsageHistory() {}
    function updateCpuUsageHistory() { samples++ }
''' + source[start:end] + '''
    Component.onCompleted: {
        acceptCpu("cpu 100 0 0 100 0 0 0 0 0 0")
        acceptCpu("cpu 110 0 0 110 20 0 0 0 0 0")
        if (cpuUsage !== .25 || samples !== 1) console.log("FAIL: CPU iowait")
        acceptCpu("garbage")
        if (samples !== 1) console.log("FAIL: invalid CPU")
        acceptMemory("MemTotal: 1000\\nMemAvailable: 400\\nSwapTotal: 0\\nSwapFree: 0")
        acceptMemory("broken")
        if (memoryTotal !== 1000 || memoryFree !== 400) console.log("FAIL: memory preservation")
        console.log("PERF_PASS")
        Qt.callLater(Qt.quit)
    }
''')


if __name__ == '__main__':
    unittest.main()
