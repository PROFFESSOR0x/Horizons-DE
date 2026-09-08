"""Real Quickshell tests for clipboard decoding and lightweight launcher rows."""
import base64
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

SHELL = Path(__file__).resolve().parents[1]

@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell required')
class LauncherClipboard(unittest.TestCase):
    def test_shared_image_cache_and_entry_replacement(self):
        with tempfile.TemporaryDirectory(prefix='horizons-clipboard-test-') as directory:
            path=Path(directory)
            image_source=(SHELL/'modules/common/widgets/CliphistImage.qml').read_text()
            (path/'CliphistImage.qml').write_text(image_source)
            stub={
                'modules/common/Appearance.qml': 'pragma Singleton\nimport QtQuick\nimport Quickshell\nSingleton { property var colors: ({colLayer1:"black",colLayer0:"black",colOnSurface:"white"}); property var rounding: ({small:4}); property var font: ({pixelSize:({smallie:12})}) }',
                'modules/common/Directories.qml': 'pragma Singleton\nimport Quickshell\nSingleton { property string cliphistDecode: '+json.dumps(str(path/'cache with spaces'))+' }',
                'modules/common/functions/ColorUtils.qml': 'pragma Singleton\nimport Quickshell\nSingleton { function transparentize(c,a) {return c} }',
                'modules/common/widgets/StyledImage.qml':'import QtQuick\nImage {}',
                'modules/common/widgets/StyledText.qml':'import QtQuick\nText {}',
                'modules/common/widgets/MaterialSymbol.qml':'import QtQuick\nText {}',
                'services/Cliphist.qml':'pragma Singleton\nimport Quickshell\nSingleton { property string cliphistBinary: '+json.dumps(str(path/'fake cliphist'))+' }',
            }
            for name,text in stub.items():
                target=path/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text)
            # No access to the user's clipboard DB: the fixture emits one PNG.
            fixture=path/'fake cliphist'
            fixture.write_text('''#!/usr/bin/env python3
import base64,sys,time
assert sys.argv[1:] == ['decode']
assert sys.stdin.read().strip() in ('1','2')
time.sleep(.04)
sys.stdout.buffer.write(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg=='))
''');fixture.chmod(0o700)
            (path/'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot {
    property int stage: 0
    Component { id: imageComponent; CliphistImage { entry: "1\\t[[ binary data 1x1 ]]"; maxWidth:96; maxHeight:64 } }
    property var first
    property var second
    Component.onCompleted: { first=imageComponent.createObject(null); second=imageComponent.createObject(null) }
    property int ticks: 0
    Timer { interval: 100; running:true; repeat:true; onTriggered: {
        ticks++
        if (ticks > 40) { console.log("FAIL decode timeout"); Qt.quit(); return }
        const rendered = second.children.find(c => c.sourceSize !== undefined && c.status !== undefined)
        if (rendered?.status !== Image.Ready) return
        if (stage===0) {
            if (!first.source || !second.source || first.source!==second.source) { console.log("FAIL cache decode"); Qt.quit(); return }
            stage=1; first.destroy(); second.entry="2\\t[[ binary data 1x1 ]]"
        } else if (second.source.endsWith("/2")) {
            if (second.implicitWidth!==1 || !Number.isFinite(second.implicitHeight)) console.log("FAIL replacement")
            else console.log("CLIP_PASS")
            second.destroy(); Qt.quit()
        }
    } }
}
''')
            result=subprocess.run(['quickshell','-p',str(path),'--no-color'],env=dict(os.environ,QT_QPA_PLATFORM='offscreen'),capture_output=True,text=True,timeout=10)
            output=result.stdout+result.stderr
            self.assertIn('CLIP_PASS',output,output)
            for error in ('FAIL','ReferenceError','TypeError','Failed to load','SyntaxError'):
                self.assertNotIn(error,output,output)
            self.assertTrue((path/'cache with spaces/1').is_file())
            self.assertTrue((path/'cache with spaces/2').is_file())

    def test_launcher_factory_uses_real_qml_enum_and_executable_data(self):
        source=(SHELL/'services/LauncherSearch.qml').read_text()
        function=re.search(r'    function makeResult\(properties\) \{.*?\n    }',source,re.S).group()
        with tempfile.TemporaryDirectory(prefix='horizons-launcher-test-') as directory:
            path=Path(directory)
            shutil.copy(SHELL/'modules/common/models/LauncherSearchResult.qml',path)
            (path/'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot {
'''+function+'''
property int invoked:0
ScriptModel { id:model }
Component.onCompleted: {
    const rows=[]; const start=Date.now()
    for(let i=0;i<10000;i++) rows.push(makeResult({name:"row"+i,execute:()=>{invoked++}}))
    model.values=rows.slice(0,10)
    model.values[5].execute()
    if (invoked===1 && model.values.length===10 && rows[0].iconType===LauncherSearchResult.IconType.None)
        console.log("LAUNCH_PASS rows=10000 ms="+(Date.now()-start))
    Qt.callLater(Qt.quit)
}
}
''')
            result=subprocess.run(['quickshell','-p',str(path),'--no-color'],env=dict(os.environ,QT_QPA_PLATFORM='offscreen'),capture_output=True,text=True,timeout=10)
            self.assertIn('LAUNCH_PASS',result.stdout+result.stderr,result.stdout+result.stderr)
