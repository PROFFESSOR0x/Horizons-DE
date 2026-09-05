# دراسة عميقة: دعم i3 وتكامل Quickshell معه

**تاريخ الدراسة:** 2026-09-05
**المصادر:** الكود الفعلي في هذا الـ repo + التوثيق الرسمي لـ Quickshell (quickshell.org, DeepWiki, Forgejo mirror) + i3wm.org + picom.

هذا المستند بحث تقني (مش تنفيذ) بهدف معرفة: (1) وضع دعم i3 الحالي في الكود، (2) قدرات Quickshell الحقيقية على X11/i3 حسب توثيقها الرسمي ومصدرها، (3) مقابل كل خاصية في إعدادات Hyprland (لوا/conf) الموجودة، إيه المكافئ في i3 (لو موجود)، و(4) الفجوات الحقيقية المتبقية.

---

## 1. الوضع الحالي في الكود (Baseline)

### 1.1 طبقة التجريد: `WM.qml`
[shell/services/WM.qml](../shell/services/WM.qml) بيكتشف الـ compositor (`hyprland`/`niri`/`i3`/`unknown`) من `XDG_CURRENT_DESKTOP`/`XDG_SESSION_DESKTOP`/`I3SOCK`/`WINDOWMANAGER`/`DISPLAY`، وبيبني `backend` مناسب:
- `hyprland` → `HyprlandBackend.qml`
- `i3` → [I3Backend.qml](../shell/services/I3Backend.qml)
- غير كده → `NullBackend.qml` (شكل فاضي بنفس الـ interface، عشان أي widget عام يفضل شغال من غير ما يحاول يبني type خاص بـ Hyprland).

كل الواجهات (workspaces/windows/monitors) بتتوحّد خلف `WM.*` — ده تصميم سليم ومهم، وهو اللي خلّى إصلاحات هذه الجلسة (WlrLayershell gating) ممكنة أصلاً.

### 1.2 `I3Backend.qml` — تنفيذ يدوي 100%
بيعتمد بالكامل على spawn processes:
- `i3-msg -t get_tree` (يبني شجرة النوافذ يدويًا عن طريق `collectWindows()` recursion)
- `i3-msg -t get_workspaces`
- `i3-msg -t get_outputs`
- `i3-msg -t subscribe -m '["workspace","window","output"]'` → عند أي سطر جديد يعمل debounce (80ms) ثم يعيد الـ 3 استعلامات من الأول كل مرة.
- أي أمر (`focusWindow`, `switchWorkspace`, ...) بيعمل `Process { command: ["i3-msg", cmd] }` منفصل.

يعني: **كل تفاعل = عملية فرعية جديدة** (لا يوجد اتصال دائم/socket واحد). شغال، لكن أثقل وأبطأ من الممكن — وأهم حاجة: **بيعيد اختراع حاجة Quickshell نفسها بتوفرها جاهزة** (البند 2.2 تحت).

### 1.3 ملف i3 نفسه ضئيل جدًا
[i3/horizons.conf](../i3/horizons.conf) المُولَّد بواسطة الـ installer فيه سطرين bindsym بس:
```
bindsym $mod+Escape exec --no-startup-id quickshell ipc -c horizons call settings toggle
bindsym $mod+d exec --no-startup-id quickshell ipc -c horizons call search toggle
```
بينما [keybinds.lua](../dotfiles/dots/.config/hypr/hyprland/keybinds.lua) بتاع Hyprland فيه **أكثر من 100 ربط** (workspaces 1-10, focus/move اتجاهات، screenshot/OCR/تسجيل، media keys، sidebar/notification toggles، إلخ). الفجوة هنا حقيقية وكبيرة — مش تقصير في القابلية التقنية، لكن ببساطة محدش قعد يحوّل كل سطر.

### 1.4 `CompositorGlobalShortcut.qml` — مقفول على Hyprland فقط
```qml
active: WM.compositor === "hyprland"
sourceComponent: GlobalShortcut { name: root.name; ... }
```
كل الـ ~45 اسم اختصار (`barToggle`, `sidebarLeftToggle`, `regionScreenshot`, `overlayToggle`, ...) **معطّلة بالكامل على i3** لأن `GlobalShortcut` (بروتوكول الـ portal) Wayland-only أصلاً. الطريقة الوحيدة إن أي حاجة تتفعّل على i3 هي عن طريق IPC مباشر (`quickshell ipc -c horizons call <target> <function>`) من داخل i3 config نفسه — وده بالظبط اللي بيحصل في الـ 2 bindsym الموجودين. باقي الأهداف موجودة وجاهزة (32 `IpcHandler` target في الكود، راجع القسم 4)، لكن محدش وصّلهم في `i3/horizons.conf`.

### 1.5 `HyprlandKeybinds.qml` + صفحة Settings > Keybinds — Hyprland-only بلا أي gating
```qml
import Quickshell.Hyprland
...
Connections { target: Hyprland; function onRawEvent(event) {...} }
```
الصفحة دي (المحرر، كشف التعارضات، إنشاء/حذف ربط، Super+/ cheat-sheet) بتقرأ/تكتب في `keybinds.lua` وتراقب `Hyprland.rawEvent` بلا أي شرط `WM.compositor`. على i3 مش هتعمل crash (الـ `Hyprland` singleton موجود كـ type دايمًا، بس مفيش socket يتصل بيه فعليًا)، لكنها هتفضل فاضية وعديمة الفائدة تمامًا لمستخدم i3.

### 1.6 `exclusiveZone` على X11 — نقطة إيجابية مُتحقق منها رسميًا
تعليق موجود في [Bar.qml:87-89](../shell/modules/ii/bar/Bar.qml) بيقول إن `exclusionMode`/`exclusiveZone`/`anchors`/`margins`/`above` بتشتغل على X11 "via Quickshell's own X11 backend" — تم التأكد من التوثيق الرسمي (قسم 2.1 تحت) إن ده **صحيح 100%**.

---

## 2. توثيق Quickshell الرسمي لـ X11/i3 (المصدر الأساسي للبحث)

### 2.1 `PanelWindow` على X11 = `XPanelWindow`
من [quickshell.org/docs/v0.1.0/types/Quickshell/PanelWindow](https://quickshell.org/docs/v0.1.0/types/Quickshell/PanelWindow/) و [DeepWiki: X11 Support and Panel System](https://deepwiki.com/quickshell-mirror/quickshell/6.4-x11-support-and-panel-system):

- بدل بروتوكول `wlr-layer-shell` (Wayland)، الـ X11 backend بيستخدم **EWMH** — تحديدًا `_NET_WM_STRUT_PARTIAL` — عشان يحجز مساحة على الشاشة (نفس فكرة `exclusiveZone`، بس بآلية مختلفة تمامًا تحت السطح).
- فيه `XPanelStack` (singleton) بيدير أكثر من panel على نفس الحافة (bar + dock + sidebar كلهم على نفس الجانب مثلاً) ويخلي مناطق الحجز تتجمع (additive) بدل ما تتداخل.
- `exclusiveZone` عنده 3 أوضاع: `Ignore` (صفر)، `Normal` (القيمة اللي انت حاططها بنفسك — زي الكود الحالي)، `Auto` (بيحسبها من implicitWidth/Height + margins).
- **النتيجة:** i3 (بما إنه EWMH-compliant زي أي WM محترم) بيحترم الـ strut ده تلقائيًا — يعني الـ bar/dock هيحجزوا مساحتهم صح وموش هيتغطوا بالنوافذ العادية، **من غير أي كود إضافي مطلوب في هذا الـ repo**. ده تأكيد رسمي لحاجة كانت مجرد تعليق/افتراض في الكود.

### 2.2 اكتشاف كبير: `Quickshell.I3` — موديول رسمي جاهز لـ i3/Sway IPC
البحث كشف إن Quickshell بيوفر موديول اسمه **`Quickshell.I3`** (منفصل عن `Quickshell.Hyprland`)، مبني بنفس فلسفة التكامل مع Hyprland بالظبط. المصدر: commit فعلي في مستودع Quickshell (`31adcaac76`, نوفمبر 2024, "i3/sway: add support for the I3 and Sway IPC") + [DeepWiki](https://deepwiki.com/quickshell-mirror/quickshell/6.4-x11-support-and-panel-system).

**بناء الموديول (`src/x11/i3/ipc/*`):**

| Class | الوظيفة |
|---|---|
| `I3Ipc` (singleton, معروض في QML كـ `I3`) | اتصال Unix socket واحد دائم بـ `$I3SOCK` أو `$SWAYSOCK` |
| `I3Monitor` | مونيتور: `id`, `name`, `power`, `x/y/width/height`, `scale`, `focused`, `focusedWorkspace`, `lastIpcObject` |
| `I3Workspace` | مساحة عمل: `id`, `name`, `num`, `urgent`, `focused`, `monitor` (مؤشر لـ `I3Monitor`)، `lastIpcObject` |
| `I3IpcEvent` | حدث خام (نفس فكرة `Hyprland.rawEvent`) |

**الـ API المتاح على singleton `I3`:**
```qml
I3.dispatch(request: string)       // = i3-msg <request>, لكن عبر socket دائم لا process جديد
I3.monitors                        // ObjectModel<I3Monitor>
I3.workspaces                      // ObjectModel<I3Workspace>
I3.focusedWorkspace / focusedMonitor
I3.findWorkspaceByName(name) / findMonitorByName(name)
I3.monitorFor(screen: ShellScreen)
I3.refreshMonitors() / refreshWorkspaces()
I3.socketPath
signal I3.rawEvent(I3IpcEvent event)
signal I3.connected()
```

**مهم — حدود الموديول:** هو بيغطي الـ **workspaces والـ monitors بس** (تمامًا زي `Hyprland.workspaces`/`Hyprland.monitors`). **لا يوجد فيه أي تمثيل لشجرة النوافذ (windows/containers)** — لا `I3Window` ولا حتى إشارة لـ `get_tree`. يعني:
- ✅ ممكن نستبدل بيه: قراءة/متابعة الـ workspaces والـ outputs في `I3Backend.qml` (بدل 2 `Process` منفصلين + subscribe + إعادة تحليل JSON يدوي).
- ✅ ممكن نستبدل بيه `runI3()` الحالية (`Process` جديدة لكل أمر) بـ `I3.dispatch()` مباشرة — بدون spawn.
- ❌ **لازم نفضل نعتمد على `i3-msg -t get_tree` اليدوي لأي حاجة متعلقة بالنوافذ نفسها** (العنوان، الـ class، fullscreen، حجم النافذة، البحث عن أكبر نافذة...) — الموديول مبيوفرش البديل ده أصلاً، فمفيش طريقة نلغي `collectWindows()`/`get_tree` بالكامل.

**تحذير هندسي مهم قبل أي تنفيذ:** الموديول ده اتضاف خلف CMake option اسمه `I3_IPC` (بيعتمد على `I3` option) — **الاتنين بـ default = `ON`** في مصدر Quickshell (أكدت ده من `CMakeLists.txt` نفسه)، ومن غير أي `-DI3=OFF` في الـ PKGBUILD المستخدم هنا (`illogical-impulse-quickshell-git`)، فالبناء الحالي في الـ repo غالبًا بيشمله فعلاً. **لكن**: `import Quickshell.I3` لو الموديول مش موجود فعلاً (نسخة قديمة جدًا، أو توزيعة تانية عطّلته) بيكون **فشل تحميل كامل للملف وقت الـ parse** — مش استثناء ممكن نمسكه بـ try/catch عادي. لازم أي تنفيذ مستقبلي يتأكد إما (أ) بفحص إصدار Quickshell قبل الاستيراد، أو (ب) بعزل الاستيراد في ملف منفصل يتحمّل عبر `Loader { source: ... }` مع `onStatusChanged` بيرصد `Loader.Error` كـ fallback آمن لنفس الطريقة الحالية (i3-msg يدوي) — **مينفعش نبدّل الكود القديم بالكامل من غير الحماية دي**، خصوصًا بعد التوجيه الصريح من المستخدم إن أي تعديل في i3 لازم يكون حذر جدًا.

### 2.3 لا يوجد بديل رسمي لتأثيرات الكمبوزيتور (blur/shadow/rounding/animations)
Quickshell **مش كمبوزيتور** — هو toolkit لبناء شل فوق أي WM/compositor. أي blur/shadow/rounding/animation في Hyprland (`decoration.*`, `animations.*` في general.lua) هو تأثير الكمبوزيتور بيطبّقه على *كل النوافذ*. i3 نفسه **بلا أي compositing على الإطلاق** — مفيش حتى شفافية أو ظل لأي نافذة. البديل الوحيد المعروف والمستخدم فعليًا هو **picom** (خليفة compton)، تم التأكد منه من توثيقه ومناقشات المجتمع:
- `corner-radius = N;` + تشغيل بـ backend حديث (`glx`) → rounded corners.
- `blur: { method = "dual_kawase"; strength = N; }` → بلور خلفي.
- `shadow = true; shadow-radius/opacity/offset-x/y` → ظلال.
- لازم يتشغّل كـ `exec_always --no-startup-id picom` في i3 config، وده **process منفصل تمامًا عن i3 وعن Quickshell**، بملف إعدادات خاص بيه (`~/.config/picom/picom.conf`) بصيغة مختلفة كليًا عن `general.lua`.

**ملاحظة مهمة:** لوحات/بارات/sidebar الشل نفسها (اللي Quickshell بيرسمها) أصلاً بترسم الـ rounding/blur/shadow بتاعتها *client-side* عن طريق QML (`Rectangle.radius`, shaders, drop shadows) — دي مش محتاجة picom خالص، شغالة صح على i3 زي ما هي على Wayland. الفجوة الحقيقية هي بس على *نوافذ التطبيقات العادية* (المتصفح، المحرر، إلخ) اللي مفيش حد يرسملها تأثيرات غير الكمبوزيتور.

---

## 3. جدول المطابقة الكامل: Hyprland lua/conf ⇄ i3 config

| ملف Hyprland | الخاصية | مكافئ i3 | الحالة |
|---|---|---|---|
| `general.lua` | `general.gaps_in` / `gaps_out` | `gaps inner Npx` / `gaps outer Npx` (i3 ≥ **4.22**, i3-gaps اتدمج رسميًا في i3 نفسه) — قابل للتغيير وقت التشغيل عبر `i3-msg gaps inner all set N` أيضًا | ✅ مكافئ كامل، غير مطبّق في `i3/horizons.conf` |
| `general.lua` | `general.border_size` | `default_border pixel N` / `for_window [...] border pixel N` | ✅ مكافئ كامل |
| `general.lua` | `general.col.active_border`/`inactive_border` | `client.focused`/`client.unfocused` (ألوان border/background/text/indicator) | ✅ مكافئ (شكل مختلف: كل حالة لازم تتحدد كاملة، مش لون واحد بس) |
| `general.lua` | `decoration.rounding`, `blur.*`, `shadow.*` | **مفيش داخل i3 نفسه** — يحتاج **picom** خارجي (قسم 2.3) | ⚠️ ممكن جزئيًا، خارج نطاق i3/Quickshell |
| `general.lua` | `animations.enabled` + كل الـ `hl.animation({...})` | **لا يوجد** — i3 بيبدّل/يحرّك النوافذ فورًا بلا أي حركة | ❌ مستحيل native (picom بيقدر يعمل fade بس، مش window-move/resize animation حقيقي) |
| `general.lua` | `input.kb_layout`, `touchpad.*`, إلخ | `~/.config/X11/xorg.conf.d/*.conf` (`libinput` Xorg driver) أو `setxkbmap`/`xset` جوه `exec` | ✅ مكافئ (بس مش داخل i3 config نفسه — على مستوى Xorg/X11) |
| `general.lua` | `hl.monitor({output, mode, position, scale})` | **لا يوجد داخل i3** — i3 مش بيدير resolution/position/scale؛ لازم `xrandr` (أو `autorandr`/`nwg-displays`) في سكربت `exec` منفصل. الـ scale لكل شاشة (HiDPI) خصوصًا **مش مدعوم بشكل صحيح على X11 أصلاً** (`xrandr --scale` بيعمل blur، مش scale حقيقي زي Wayland) | ❌ فجوة حقيقية وبنيوية في X11 نفسه، مش في i3 أو Quickshell |
| `rules.lua` | `hl.window_rule({match, float/center/size/move/...})` | `for_window [class="..." title="..."] floating enable; move ...; border ...` | ✅ مكافئ كامل تقريبًا (تركيبة مختلفة، القدرات نفسها) |
| `rules.lua` | `hl.workspace_rule({workspace, gaps_out})` | `workspace "name" gaps outer N` | ✅ مكافئ |
| `rules.lua` | `hl.layer_rule({namespace, blur/animation/...})` | **لا يوجد مفهوم "layer" في X11 أصلاً** (ده بروتوكول Wayland). البارات/الـ popups دي عادي نوافذ X11 عادية بـ struts، مفيش "layer rule" منفصل | ❌ غير قابل للتطبيق مباشرة؛ أي تخصيص لازم يبقى من جوه Quickshell/QML نفسه مش من كونفيج الـ WM |
| `execs.lua` | `hl.on("hyprland.start", function() ... end)` | `exec --no-startup-id CMD` (مرة واحدة أول ما i3 يبدأ) / `exec_always` (كل reload) | ✅ مكافئ كامل، والـ `i3/horizons.conf` الحالي بيستخدمه صح لتشغيل quickshell نفسه |
| `env.lua` | `hl.env("VAR", "value")` | `exec --no-startup-id sh -lc 'export VAR=value; ...'` أو ملف `~/.xprofile`/`~/.pam_environment` بيتحمل قبل بدء الجلسة | ⚠️ مكافئ لكن **مش على نفس المستوى**: `hl.env()` بيظبط الـ compositor process env نفسه، إعادة تشغيل quickshell جواه هترث منه؛ على X11 لازم `~/.xprofile` (أو تصدير المتغيرات قبل `exec i3` في `~/.xinitrc`/الـ display manager) عشان تتوارث صح لكل حاجة بعدين، مش مجرد سطر جوه i3 config |
| `variables.lua` | `hl.env("qsConfig", "horizons")` + `terminal =`, `browser =`, ... | `set $var value` (نطاق ملف الكونفيج بس، parse-time substitution، **مش environment variable حقيقي** - فرق جوهري) | ✅ مكافئ لغرض bindsym exec بس (مش لتصدير env حقيقي لعمليات تانية) |
| `keybinds.lua` | ~100+ `hl.bind(...)` (معظمها `hl.dsp.global("quickshell:X")`) | `bindsym $mod+X exec --no-startup-id quickshell ipc -c horizons call <target> <function>` — **موجودة أهداف الـ IPC جاهزة بالفعل (32 target)**، الناقص هو الربط في `i3/horizons.conf` بس | ✅ قابل للتطبيق 100%، **لسه معمول منه سطرين بس من ~100** |
| `keybinds.lua` | `hl.dsp.window.cycle_next()` (Alt+Tab بدون UI) | **لا يوجد dispatcher واحد جاهز في i3** — لازم سكربت خارجي (`i3-msg -t get_tree` لإيجاد "التالي" ثم `focus`) أو استخدام `WindowSwitcher` الموجود في الشل أصلاً (شغال على i3 فعلاً عبر `WM.focusWindow`) | ⚠️ ممكن، لكن يحتاج سكربت صغير أو استخدام نافذة الـ WindowSwitcher بدل الدوران الصامت |
| `keybinds.lua` | submap (`hl.define_submap("virtual-machine", ...)`) | `mode "name" { bindsym ... ; bindsym Escape mode "default" }` | ✅ مكافئ كامل |
| `keybinds.lua` | `bindsym --release` (`SUPER_L` ... `release = true`) | `bindsym --release ...` (i3 بيدعمه أصلاً) | ✅ مكافئ كامل |
| `colors.lua` | `hl.window_rule({match={pin=1}, border_color=...})` | `for_window [floating] border ...` + `client.focused_inactive` وغيرها (i3 مالوش مفهوم "pin" منفصل بالضبط، بس فيه `sticky enable`) | ⚠️ قريب لكن مش تطابق 1:1 |

---

## 4. خريطة IPC targets الجاهزة في هذا الـ repo (لسه معظمها مش متربطة بـ i3 bindsym)

استخراج مباشر من كل `IpcHandler { target: "..." }` في الكود (32 ملف)، مع أهم الـ functions:

| target | functions | يقابل أي `CompositorGlobalShortcut` |
|---|---|---|
| `settings` | toggle/open/close | `settingsToggle` |
| `search` | toggle/open/close/toggleReleaseInterrupt/clipboardToggle | `searchToggle`, `searchToggleRelease`, `overviewClipboardToggle` |
| `windowSwitcher` | toggle/open/close | `overviewWorkspacesToggle` |
| `sidebarLeft` | toggle/open/close | `sidebarLeftToggle` |
| `sidebarRight` | toggle/open/close | `sidebarRightToggle` |
| `bar` (Bar.qml + VerticalBar.qml) | toggle/open/close | `barToggle`, `barOpen`, `barClose` |
| `mesoBar` | toggle/open/close | `barToggle` (وضع mesoBar) |
| `overlay` | toggle | `overlayToggle` |
| `osk` | toggle/open/close | `oskToggle` |
| `mediaControls` | toggle/open/close | `mediaControlsToggle` |
| `session` | toggle/open/close | `sessionToggle` |
| `region` | screenshot/search/ocr/record/recordWithSound | `regionScreenshot`, `regionSearch`, `regionOcr`, `regionRecord` |
| `osdVolume` | trigger/hide/toggle | `osdVolumeTrigger`, `osdVolumeHide` |
| `wallpaperSelector` | toggle/random | `wallpaperSelectorToggle`, `wallpaperSelectorRandom` |
| `brightness` | increment/decrement | `brightnessIncrease`, `brightnessDecrease` |
| `keybindsOverlay` | toggle/open/close | `cheatsheetToggle` |
| `screenTranslator` | translate | `screenTranslate` |
| `m3Island` | toggle/expand/collapse/toggleExpand/dismissNotification | (خاص بوضع m3Island) |
| `lock` | activate | `lock`/`lockFocus` |
| `background` | toggleCenteredWallpaper | `centeredWallpaperToggle` |
| `wallpapers`, `cliphistService`, `mpris`, `reloadControl`, `captureEditor`, `aiChat`, `infoStrip`, `quickActionsBar`, `sysmonitorBar`, `tasklistBar` | — | (أدوات مساعدة/تكاملات، معظمها مش محتاج bindsym مباشر) |

**الخلاصة:** كل اختصار في `keybinds.lua` بيستخدم `hl.dsp.global("quickshell:X")` **له مكافئ IPC جاهز فعليًا في الكود** — الشغل الناقص هو *كتابة سطر bindsym واحد لكل واحد فيهم* في `i3/horizons.conf`، مش تطوير ميزة جديدة.

---

## 5. الخلاصة والفجوات الحقيقية (Priority Order)

1. **الأكبر أثرًا وأسهل تنفيذًا:** توسيع `i3/horizons.conf` ليغطي أكبر عدد ممكن من الـ ~100 keybind (عبر جدول القسم 4)، + إضافة `gaps`/`default_border`/`client.focused` ألوان تقابل `general.lua`، + `for_window`/`assign` تقابل أهم قواعد `rules.lua` (الأهم: نوافذ الحوار float+center، pavucontrol/nm-connection-editor float+size، PiP float+pin).
2. **صفحة Settings > Keybinds** ([HyprlandKeybinds.qml](../shell/services/HyprlandKeybinds.qml) + `KeybindsConfig.qml`) لازم تتحول لتصميم مزدوج المصدر (Hyprland lua parser + i3 conf parser)، أو على الأقل تتخفي/تتقفل برسالة واضحة على i3 بدل ما تفضل فاضية بلا تفسير.
3. **تجربة خفيفة:** كتابة سكربت `exec_always` بسيط لتشغيل `picom` (مع كونفيج جاهز فيه rounding/blur/shadow) كخيار في الـ installer لمستخدمي i3 اللي عايزين شكل أقرب لـ Hyprland — يتسجل كـ optional dependency واضح إنه تأثير بصري خارجي مش جزء من i3/Quickshell.
4. **تحديث معماري (مش عاجل، ومربوط بخطر حقيقي لازم يتضبط قبل التنفيذ):** استبدال أجزاء من `I3Backend.qml` (الـ workspaces/monitors بس، مش شجرة النوافذ) باستخدام `Quickshell.I3` الرسمي بدل الـ subprocess الحالي — أداء وموثوقية أفضل (اتصال دائم بدل عمليات متكررة)، بس **لازم يتحمّل بحماية ضد فشل الاستيراد** (Loader + status check) عشان ميكسرش الجلسة على أي بناء Quickshell أقدم من نوفمبر 2024 أو معطّل فيه الـ flag يدويًا.
5. **فجوة بنيوية معروفة ومقبولة:** الأنيميشن (windows move/resize/open/close) والـ per-monitor HiDPI scale **مش قابلين للحل على X11/i3 بشكل صحيح أصلاً** — دي حدود X11 نفسه، مش حاجة ينفع "نصلحها" في الكود.

---

## المصادر

- [Quickshell — PanelWindow](https://quickshell.org/docs/v0.1.0/types/Quickshell/PanelWindow/)
- [Quickshell — X11 Support and Panel System (DeepWiki)](https://deepwiki.com/quickshell-mirror/quickshell/6.4-x11-support-and-panel-system)
- [Quickshell — Hyprland IPC Integration (DeepWiki)](https://deepwiki.com/quickshell-mirror/quickshell/6.3-hyprland-integration)
- [Quickshell.I3 module — Forgejo commit adding I3/Sway IPC support](https://git.outfoxxed.me/quickshell/quickshell/commit/31adcaac7662d6c7fbbc901ba11e0d95f0c7fc56)
- [i3 User's Guide (i3wm.org)](https://i3wm.org/docs/userguide.html)
- [i3-gaps merged into i3 upstream](https://github.com/Airblader/i3)
- [picom blur/rounded-corners discussion](https://github.com/yshui/picom/discussions/751)
