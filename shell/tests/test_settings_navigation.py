"""Routing contracts exercise the actual catalogue and registry JavaScript."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import unittest

SHELL = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SHELL / 'scripts/settings'))
from qml_catalog import mask, parse, direct


def catalogue():
    return json.loads((SHELL / 'modules/ii/settings/SettingsCatalog.js').read_text().split('var entries = ', 1)[1].rstrip(';\n'))


class SettingsNavigationTests(unittest.TestCase):
    def test_every_catalogue_entry_has_an_existing_unique_target(self):
        entries = catalogue()
        self.assertEqual(len(entries), len({entry['id'] for entry in entries}))
        texts = {entry['source']: (SHELL / 'modules/ii/settings/pages' / (entry['source'] + '.qml')).read_text() for entry in entries}
        for entry in entries:
            self.assertEqual(texts[entry['source']].count('objectName: "' + entry['id'] + '"'), 1, entry['id'])
            self.assertIn(entry['route'], entry['routes'])

    def test_registry_search_and_legacy_navigation_before_loading_any_pages(self):
        if not shutil.which('node'):
            self.skipTest('Node.js is needed to exercise the QML JavaScript registry')
        text = (SHELL / 'modules/ii/settings/SettingsRegistry.qml').read_text()
        clean = mask(text)
        functions = []
        for match in re.finditer(r'\bfunction\s+\w+\s*\([^)]*\)\s*\{', clean):
            depth = 1
            end = match.end()
            while depth:
                depth += (clean[end] == '{') - (clean[end] == '}')
                end += 1
            functions.append(text[match.start():end])
        pages = text.split('readonly property var pages: ', 1)[1].split('    readonly property var sources:', 1)[0].strip()
        index = text.split('readonly property var searchIndex: ', 1)[1].split('    function resolveLegacy', 1)[0].strip()
        script = '''const assert = require('node:assert/strict');
let WM = {compositor: 'hyprland'};
const Translation = {tr: value => value};
''' + 'const Catalog = {entries:' + json.dumps(catalogue()) + '};\n'
        script += '\n'.join(functions) + '\nconst pages = ' + pages + ';\nlet searchIndex = ' + index + ';\n'
        script += '''
assert.equal(pages.filter(p => !p.advanced && p.id !== 'about').length, 10);
assert.equal(pages.filter(p => p.advanced).length, 11);
for (const entry of Catalog.entries) for (const route of entry.routes)
    assert(pages.some(page => page.id === route), `${entry.id}: ${route}`);
assert(!searchIndex.some(entry => entry.source === 'NiriSettings'));
assert(searchIndex.some(entry => entry.source === 'HyprlandSettings'));
assert.equal(resolveLegacy('Interface:Lock screen').route, 'session');
assert.equal(resolveLegacy('General:Clock String Format').route, 'system');
assert.equal(resolveLegacy('Services:Polling interval (m)').route, 'integrations');
assert.equal(resolveLegacy('Desktop').route, 'widgets');
assert.equal(resolveLegacy('About').route, 'about');
assert.equal(resolveLegacy('Keybinds').route, 'devices');
assert(searchIndex.find(entry => entry.label === 'Noise gate').advanced);
assert(contributes('GeneralConfig','capture'));
assert(contributes('ServicesConfig','capture'));
assert(!contributes('GeneralConfig','widgets'));
WM.compositor = 'niri';
searchIndex = ''' + index + ''';
assert(!searchIndex.some(entry => entry.source === 'HyprlandSettings'));
assert(!searchIndex.some(entry => entry.source === 'KeybindsConfig'));
assert(searchIndex.some(entry => entry.source === 'NiriSettings'));
WM.compositor = 'i3';
searchIndex = ''' + index + ''';
assert(!searchIndex.some(entry => ['HyprlandSettings','NiriSettings','KeybindsConfig'].includes(entry.source)));
'''
        result = subprocess.run(['node', '-'], input=script, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_settings_controls_commit_only_user_edits(self):
        for path in (SHELL / 'modules/ii/settings/pages').glob('*.qml'):
            text = path.read_text()
            for node in parse(text):
                if node.kind in ['ConfigSwitch', 'ConfigSpinBox', 'ConfigSlider', 'ConfigTextArea']:
                    self.assertNotRegex(direct(text,node), r'\bon(?:Checked|Value)Changed\s*:', path.name)
        hypr = (SHELL / 'modules/ii/settings/pages/HyprlandSettings.qml').read_text()
        root = parse(hypr)[0]
        self.assertNotIn('Component.onCompleted:', direct(hypr, root))
        self.assertNotIn('bindsDebounce', hypr)
        self.assertNotIn('rulesDebounce', hypr)

    def test_duplicate_controls_have_one_owner(self):
        background = (SHELL / 'modules/ii/settings/pages/BackgroundConfig.qml').read_text()
        interface = (SHELL / 'modules/ii/settings/pages/InterfaceConfig.qml').read_text()
        experience = (SHELL / 'modules/ii/settings/pages/ExperienceConfig.qml').read_text()
        quick = (SHELL / 'modules/ii/settings/pages/QuickConfig.qml').read_text()
        self.assertIn('WidgetsSubmenu', background)
        self.assertNotIn('GridLayout {', background[background.index('title: Translation.tr("Widgets")'):])
        self.assertNotIn('title: Translation.tr("Widgets shown when locked")', interface)
        self.assertNotIn('text: Translation.tr("Wallpaper change interval (min)")', interface)
        self.assertNotIn('text: Translation.tr("Show preview on hover over workspaces in bar")', interface)
        self.assertNotIn('text: Translation.tr("Focused window opacity (%)")', experience)
        self.assertNotIn('title: Translation.tr("Bar & Screen")', quick)


if __name__ == '__main__':
    unittest.main()
