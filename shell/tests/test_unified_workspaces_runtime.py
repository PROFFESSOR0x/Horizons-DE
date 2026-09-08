"""Execute production workspace controller functions with mocked compositor IPC.

No windows are moved/closed by these regression tests.
"""
import json
from pathlib import Path
import re
import shutil
import subprocess
import unittest

SHELL = Path(__file__).resolve().parents[1]

@unittest.skipUnless(shutil.which('node'), 'Node required for pure controller tests')
class UnifiedWorkspaces(unittest.TestCase):
    def run_controller(self, scenario):
        source = (SHELL / 'GlobalStates.qml').read_text()
        funcs = re.findall(r'^    function (\w+)\(([^\n]*)\) \{\n(.*?)^    }', source, re.M | re.S)
        code = '''const assert = require('node:assert/strict');
const Config = {options:{workspaceLinking:{unifiedMultiMonitor:true,unifiedSets:[],detachedGroups:[],groups:[]}}};
const HyprlandData = {workspacesReady:true};
const calls=[];
const WM = {compositor:'hyprland',monitors:[{name:'DP-1'},{name:'HDMI-1'}],workspaces:[],windowList:[],
 switchWorkspacesOnMonitors:(...a)=>calls.push(a),switchWorkspaceOnMonitor:(...a)=>calls.push(a),
 closeWindow:id=>calls.push(id), forceCloseWindow:id=>calls.push(id)};
const root={unifiedWorkspacesEnabled:true};
'''
        # QML-typed IPC helpers are irrelevant to this controller harness.
        for name, args, body in funcs:
            if ':' not in args:
                code += f'root.{name}=function({args}){{\n{body}\n}};\n'
        code += scenario
        proc = subprocess.run(['node', '-e', code], capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stderr)

    def test_duplicate_live_and_persisted_ids(self):
        self.run_controller('''WM.workspaces=[{id:1,monitor:'DP-1'},{id:1,monitor:'HDMI-1'}];
Config.options.workspaceLinking.unifiedSets=[['DP-1::1','HDMI-1::1']];
const sets=root.initializeUnifiedWorkspaceSets();
const ids=sets.flat().map(e=>e.workspaceId);
assert.equal(new Set(ids).size,ids.length);
assert.equal(sets[0][0].workspaceId,1);''')

    def test_startup_does_not_allocate_or_persist(self):
        self.run_controller('''HyprlandData.workspacesReady=false;
assert.deepEqual(root.unifiedSetMembers(10,true),[]);
assert.deepEqual(Config.options.workspaceLinking.unifiedSets,[]);
HyprlandData.workspacesReady=true; WM.workspaces=[{id:150,monitor:'DP-1'}];
assert.equal(root.unifiedSetMembers(1,true)[0].workspaceId,150);''')

    def test_peek_is_pure_click_allocates_complete_slot(self):
        self.run_controller('''WM.workspaces=[{id:1,monitor:'DP-1'},{id:101,monitor:'HDMI-1'}];
root.initializeUnifiedWorkspaceSets();
assert.equal(root.peekUnifiedWorkspaceIdForSlot(10,'DP-1'),0);
assert.equal(root.unifiedSets().length,1);
root.activateWorkspaceSlot(10,'DP-1');
assert.equal(root.unifiedSets().length,10);
assert.equal(calls.length,1); assert.equal(calls[0][0].length,2);
assert.ok(root.peekUnifiedWorkspaceIdForSlot(10,'DP-1')>0);''')

    def test_hotplug_preserves_reservations_and_projects_members(self):
        self.run_controller('''WM.workspaces=[{id:1,monitor:'DP-1'},{id:101,monitor:'HDMI-1'}];
root.initializeUnifiedWorkspaceSets();
WM.monitors=[{name:'DP-1'}]; root.initializeUnifiedWorkspaceSets();
assert.equal(root.unifiedWorkspaceMembers(1,'DP-1',false).length,1);
WM.monitors.push({name:'DP-2'}); root.initializeUnifiedWorkspaceSets();
const members=root.unifiedWorkspaceMembers(1,'DP-1',false);
assert.deepEqual(members.map(e=>e.monitorName),['DP-1','DP-2']);
assert.ok(root.workspaceIdsInUse().has(101));
WM.monitors=[{name:'DP-1'},{name:'HDMI-1'}]; root.initializeUnifiedWorkspaceSets();
assert.equal(root.peekUnifiedWorkspaceIdForSlot(1,'HDMI-1'),101);''')

    def test_detach_intent_survives_hotplug(self):
        self.run_controller('''WM.workspaces=[{id:1,monitor:'DP-1'}];
root.initializeUnifiedWorkspaceSets();
Config.options.workspaceLinking.detachedGroups=[root.workspaceGroupSignature(root.unifiedSets()[0])];
WM.monitors.push({name:'DP-2'}); root.initializeUnifiedWorkspaceSets();
assert.equal(Config.options.workspaceLinking.detachedGroups.length,1);
assert.deepEqual(root.unifiedWorkspaceMembers(1,'DP-1',false),[]);''')

    def test_high_ids_and_dock_reservations(self):
        self.run_controller('''WM.workspaces=[{id:150,monitor:'DP-1'}];
root.initializeUnifiedWorkspaceSets();
const id=root.newWorkspaceId('DP-1');
assert.notEqual(id,150);
assert.equal(root.unifiedWorkspaceMembers(id,'DP-1',false).length,2);
const ids=root.unifiedSets().flat().map(e=>e.workspaceId);
assert.equal(new Set(ids).size,ids.length);''')

    def test_close_respects_monitor(self):
        self.run_controller('''WM.windowList=[{id:'a',workspaceId:1,monitorName:'DP-1'},
{id:'b',workspaceId:1,monitorName:'HDMI-1'},{id:'unknown',workspaceId:1,monitorName:''}];
root.closeWorkspaceWindows([{workspaceId:1,monitorName:'DP-1'}],false);
assert.deepEqual(calls,['a']);''')

    def test_late_external_workspaces_are_adopted(self):
        self.run_controller('''WM.workspaces=[{id:1,monitor:'DP-1'}];root.initializeUnifiedWorkspaceSets();
WM.workspaces.push({id:170,monitor:'HDMI-1'});root.initializeUnifiedWorkspaceSets();
assert.equal(root.unifiedWorkspaceMembers(170,'HDMI-1',false).length,2);''')
