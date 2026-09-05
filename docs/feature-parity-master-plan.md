# الخطة الشاملة: نقل الميزات من Ax-Shell / Ambxst / caelestia-shell إلى Horizons-DE

**تاريخ:** 2026-09-05
**طريقة الإعداد:** هذا المستند نتيجة 5 أبحاث متوازية (subagents منفصلة، كل واحد مركّز على مجال واحد بعمق) بناءً على قراءة مباشرة لكود:
- `Ax-Shell` (Python/GTK3/Fabric، متوقف رسميًا)
- `Ambxst` (خليفته، QML/Quickshell)
- `caelestia-shell` (QML + C++ plugin أصلي)
- `axctl` (daemon Go مستقل بيستخدمه Ambxst)
- `hyprland-plugins` (المستودع الرسمي)
- + كود Horizons-DE الحالي كامل + المستندات السابقة (`quickshell-competitor-audit.md`, `dots-integration-audit.md`, `i3-quickshell-research.md`)

**المبدأ الحاكم لكل الخطة:** لا حرمان المستخدم من أي شيء — كل ميزة/تقنية/plugin موجود في أي مصدر خارجي يتحول لـ **خيار** في Horizons-DE (Settings toggle أو installer component)، مش مفروض على أي حد، ومتكامل مع أنظمة موجودة بالفعل (Performance Profiles، Config.qml schema، matugen/M3) بدل ما يبنيلها نظام موازي منفصل.

---

## ⚠️ القرار الأهم اللي لازم يُتَّخذ قبل أي تنفيذ: ترخيص axctl

بحث قسم axctl (القسم 3 تحت) اكتشف حاجة **حرِجة قانونيًا**:
- `axctl` مرخّص **GNU AGPL-3.0** بالكامل (ترخيص copyleft قوي، بند 13 منه بيغطي حتى "الاستخدام عبر الشبكة" وممكن يُفسَّر بشكل واسع حتى لسيناريوهات محلية عبر Unix socket).
- **Horizons-DE نفسه مفيهوش أي ملف `LICENSE` حاليًا** — يعني قرار الترخيص العام للمشروع كله لسه معلَّق أصلًا، حتى قبل ما نفكر في axctl.
- لو حصل فورك فعلي لـ axctl جوه الـ repo، أي binary مبني منه **هيفضل AGPL-3.0 بغض النظر عن ترخيص باقي الـ repo** (نقل الكود لمكان تاني مبيغيّرش ترخيصه).

**التوصية:** اقرا القسم 3 كامل (خصوصًا الجدول الأخير فيه) **قبل** أي التزام بفورك axctl، وحدد ترخيص Horizons-DE نفسه أولاً (أو على الأقل قرار واعٍ بمعاملة `tools/axctl/` كوحدة مرخّصة بشكل منفصل، شفافة، غير مدمجة مباشرة في أي binary موحّد).

---

## فهرس الأقسام

1. **[البار والويدجتس](#1-البار-والويدجتس--خطة-نقل-الميزات)** — 14 ميزة محلَّلة بالتفصيل (audio mixer, clipboard tab, tmux, kanban, toast system, WindowInfo popup, إلخ)
2. **[نظام الأنيميشن الشامل](#2-نظام-الأنيميشن-الشامل--خطة-التوحيد-والتخصيص)** — توحيد tokens + الأنيميشن الثقيل كخيار في Performance Profiles
3. **[فورك axctl المحلي](#3-فورك-axctl-المحلي--خطة-التكامل-والتطوير)** — ⚠️ يحتوي القرار القانوني أعلاه
4. **[نظام الثيمات والهوية البصرية](#4-نظام-الثيمات-والهوية-البصرية--خطة-الـ-presets)** — توسعة نظام presets الموجود فعلاً (`ExperienceConfig.qml`)
5. **[الإضافات الرسمية (hyprland-plugins) كخيارات](#5-الإضافات-الرسمية-hyprland-plugins-وأنظمة-البناء--خطة-الخيارات-الاختيارية)** — كل الـ8 plugins كـ Settings toggles

## ملاحظات منهجية عابرة للأقسام (مهم تقراها قبل التنفيذ)

- **القسم 1** اكتشف إن Horizons-DE أعمق مما كان متوقّع في حاجات كتير (audio mixer per-app، Bluetooth/WiFi panels، video wallpaper، Overview، Session Screen أعمق حتى من caelestia) — الخطة ركّزت على الفجوات الحقيقية بس، مش تكرار حاجات موجودة.
- **القسم 2** اكتشف إن Horizons-DE عنده `FadeLoader.qml` (show/hide) لكن مفيهوش مكوّن cross-fade حقيقي زي `AnimLoader` بتاعة caelestia — فجوة صغيرة وسهلة السد.
- **القسم 4** اكتشف إن Horizons-DE عنده فعلاً نواة preset system شغالة (`builtInTheme` + `applyTheme()` في `ExperienceConfig.qml`) — الخطة توسّع، مش تبني من الصفر.
- **القسم 5** بيربط بأنماط موجودة فعلاً في `installer.sh` (`install_launchers()`, `cleanup_hyprglass()`) كسوابق مباشرة لآلية تفعيل/إلغاء plugin.

كل الأقسام كتبها subagent منفصل مستقل عن التاني، فممكن يكون فيه تكرار بسيط في المراجع المشتركة (زي `PerformanceProfiles.qml` كنموذج معماري) — ده مقصود ومفيد لفهم كل قسم لوحده.

---


---

# 1. البار والويدجتس — خطة نقل الميزات

**تاريخ:** 2026-09-05
**النطاق:** البار (Bar) والويدجتس فقط — بحث وتخطيط، بدون أي تعديل كود.
**لا يتكرر هنا:** التدقيق المعماري العام (نوافذ موحّدة مقابل منفصلة، PAM، axctl، hyprland-plugins) موجود بالفعل في `docs/quickshell-competitor-audit.md` و`docs/dots-integration-audit.md` — راجعهم أولاً. هذا المستند يركّز **حصرًا** على الفجوات الفعلية في البار/الويدجتس بعد فحص الكود الحالي لـ Horizons-DE.

## ملاحظة منهجية مهمة: Horizons-DE أعمق بكتير مما توقعنا

قبل الغوص في الفجوات، لازم يتسجّل بوضوح: فحص `shell/modules/ii/bar/`, `shell/modules/ii/sidebarRight/`, `shell/modules/ii/sidebarLeft/`, `shell/modules/ii/background/widgets/`, `shell/modules/ii/dock/`, `shell/modules/ii/overview/`, و`shell/modules/ii/sessionScreen/` بيّن إن معظم الميزات المطلوب فحصها في البرومبت **موجودة بالفعل وبعمق مماثل أو أعلى**:

- **Audio Mixer per-app**: موجود فعلاً (`shell/modules/ii/sidebarRight/volumeMixer/VolumeMixerEntry.qml` + `VolumeDialogContent.qml`) — يستخدم `Quickshell.Services.Pipewire` (`PwNode`, `PwObjectTracker`) مباشرة، مع قائمة تطبيقات صوتية individually + اختيار جهاز افتراضي (input/output) — مكافئ تقنيًا لـ Ambxst's `AudioMixerPanel.qml`.
- **Bluetooth/WiFi panels**: موجودة (`sidebarRight/bluetoothDevices/BluetoothDialog.qml`, `sidebarRight/wifiNetworks/WifiDialog.qml`).
- **EasyEffects toggle**: موجود لكن كـ toggle بسيط بس، مش panel كامل (تفصيل تحت، فجوة حقيقية جزئية).
- **Emoji picker**: موجود كخدمة (`shell/services/Emojis.qml`) مدمجة في بحث الـ launcher (`fuzzyQuery`)، مش تاب مستقل في dashboard، لكن الوظيفة الأساسية (البحث عن إيموجي ولصقه) متحققة.
- **Notes**: موجودة (`background/widgets/notes/NotesWidget.qml` + `overlay/notes/NotesContent.qml`).
- **Wallpapers tab مع فيديو**: موجود فعلاً — `Wallpapers.qml` بيدعم امتدادات الفيديو (`mp4/webm/mkv/avi/mov`) وبيشغّلها عبر mpvpaper، بالظبط زي Ambxst.
- **Cava integration**: موجود فعلاً بشكل مباشر — `MediaControls.qml` بيشغّل `cava -p raw_output_config.txt` كـ `Process` ويقرأ الإخراج بـ `SplitParser`، تكامل أعمق من مجرد "شغّل وخمن".
- **Overview**: موجود (`overview/Overview.qml`, `overview/NiriOverview.qml`, `overview/WindowSwitcher.qml`).
- **Session/Power screen**: موجود فعلاً وبتفاصيل متقدمة (`sessionScreen/SessionScreen.qml`) — قفل/نوم/تسجيل خروج/hibernate/إعادة تشغيل/BIOS، مع **حماية بكلمة سر للإجراءات المدمّرة** (`requirePasswordToPower`) و"اضغط مرة تانية للتأكيد" — أعمق من أي حاجة شوفناها في caelestia's `session/Content.qml`.
- **OSD**: موجود (`onScreenDisplay/OnScreenDisplay.qml` + مؤشرات صوت/سطوع).
- **Settings Crawler**: مُغطّى بالفعل في `quickshell-competitor-audit.md` §3 (مكافئ تم بناؤه هذه الجلسة).

**يعني إيه ده؟** التركيز الحقيقي للفجوات المتبقية بقى أضيق وأدق مما توحي به قائمة البرومبت الأصلية. الأقسام تحت بتغطي **الفجوات الفعلية** (سواء غياب كامل أو نقص عمق حقيقي)، ثم قسم أخير قصير يوثّق "التكافؤ المؤكَّد" للي الفحص أثبت وجوده فعلاً.

---

## 2. الفجوات ذات الأولوية العالية

### 2.1 WindowInfo — نافذة معلومات وإجراءات للنافذة النشطة

**المصدر:** caelestia-shell، `modules/windowinfo/{WindowInfo,Details,Preview,Buttons}.qml`، مُستدعاة من `modules/bar/popouts/Wrapper.qml` (popout بيتفتح من الضغط على منطقة النافذة النشطة في البار).

**الوصف التقني:** popup بيتفتح من البار فيه:
- `Preview.qml`: صورة حية مصغّرة (thumbnail) للنافذة النشطة (على الأغلب عبر `ScreencopyView`/`Quickshell.Wayland` أو مكوّن مماثل).
- `Details.qml`: قائمة معلومات كاملة مقروءة مباشرة من `HyprlandToplevel.lastIpcObject` — العنوان، الـ class، العنوان الابتدائي (initialTitle/initialClass)، PID، الموضع/الحجم، workspace، monitor، floating/pinned/fullscreen/xwayland state — كل قيمة معروضة بأيقونة Material مخصصة.
- `Buttons.qml`: أزرار إجراء فعلية — **Move to workspace** (grid تفاعلي 1-10 قابل للتوسّع)، **Float/Tile toggle**، **Pin/Unpin** (يظهر بس لو floating)، **Kill** — كلها بتنفّذ عبر `Hypr.dispatch(...)` (سلاسل أوامر Hyprland كلاسيكية أو Lua dispatchers).

**خطة النقل لـ Horizons-DE:**
- ملف جديد: `shell/modules/ii/bar/ActiveWindowPopup.qml` (بنفس نمط `BatteryPopup.qml`/`ResourcesPopup.qml`/`NetworkSpeedPopup.qml` الموجودين بالفعل في نفس المجلد — النمط التصميمي جاهز، بس محتاج تطبيقه على `ActiveWindow.qml`).
- `ActiveWindow.qml` الحالي (مجرد `StyledText` بلا أي تفاعل) يحتاج `MouseArea` بتفتح الـ popup الجديد، بنفس نمط `BatteryIndicator.qml`.
- **الفرق الجوهري عن caelestia:** بدل الاعتماد المباشر على `HyprlandToplevel`، لازم البناء فوق `WM.qml` (طبقة التجريد الموجودة بالفعل في Horizons-DE، تدعم Hyprland/Niri/i3) عشان الميزة تشتغل عبر التلات compositors بدل Hyprland بس. تفاصيل زي PID/floating/pinned متاحة جزئيًا بس عبر `Toplevel`/`ToplevelManager` (Quickshell القياسي، Wayland-agnostic)، والباقي (move-to-workspace, kill, float, pin) لازم يتحول لأوامر `WM.dispatch()` أو مكافئها بدل `Hypr.dispatch()` مباشرة.
- إضافات `Config.qml`: `Config.options.bar.activeWindow.showPopup: true`, `Config.options.bar.activeWindow.showPreview: true` (تعطيل المعاينة المصغّرة لو التقاط الشاشة مكلف).
- IPC: مش لازم IPC جديد — تفعيل الـ popup محلي بالكامل.

**الأولوية: عالية.** فجوة واضحة (الـ widget الحالي معلومة سلبية بس)، والبنية التحتية (`WM.qml`, نمط الـ popups) جاهزة بالفعل، فالتكلفة منخفضة نسبيًا مقارنة بالقيمة (تفاعل مباشر مع النوافذة من البار، مفيد جدًا لمستخدمي tiling).

**ملاحظة توافق:** المعلومات الأساسية (عنوان/class/workspace) تشتغل على أي backend عبر `WM.qml`. أزرار **kill/float** ممكنة على i3 (عبر `i3-msg kill`/`floating toggle`) والـ**move-to-workspace** كمان (`i3-msg move to workspace`). **Pin** مفهوم Hyprland/Niri specific (مفيهوش مكافئ مباشر في i3 — لازم يتخفى الزرار لو `WM.compositor === "i3"`). المعاينة المصغّرة (thumbnail) تعتمد على بروتوكول screencopy وهو **Wayland-only** (Hyprland/Niri فقط، مش i3/X11) — لازم `Loader { active: WM.isWayland }` حوالها زي النمط المتّبع في `Dock.qml`/`SessionScreen.qml` بالفعل.

---

### 2.2 نظام Toast موحّد (رسائل نظام عابرة)

**المصدر:** caelestia-shell، `modules/utilities/toasts/{Toasts,ToastItem}.qml`.

**الوصف التقني:** مكوّن عام لعرض رسائل نظام مؤقتة (Success/Warning/Error) مكدّسة فوق بعض في زاوية الشاشة، منفصل تمامًا عن نظام إشعارات التطبيقات (`Notifs`). كل toast عنده `type`/`title`/`message`/`icon`، وبيُدار عبر `Toaster.toasts` (قائمة مركزية) مع:
- حد أقصى لعدد الرسائل الظاهرة (`Config.utilities.maxToasts`) — الباقي بيتخبى (`previewHidden`) لكن يفضل موجود في الطابور.
- سياسة إخفاء وقت العروض الكاملة (fullscreen apps): `Config.utilities.toasts.fullscreen` بقيم `"all"`/`"important"`/غيرها، عبر `Notifs.hasFullscreen()`.
- `lock()`/`unlock()` على كل toast عشان الأنيميشن (fade+scale) يخلّص قبل ما يتشال فعليًا من القائمة.
- ألوان/أيقونات مشتقة من `type` (Success=أخضر، Warning=ثانوي، Error=أحمر) عبر M3 color roles جاهزة.

**مقارنة بـ Horizons-DE الحالي:** مفيش مكوّن عام مشابه. رسائل النظام الداخلية (زي "فيه تحميل شغال" و"مدير الحزم شغال" في `SessionScreen.qml`) بتتعمل حاليًا كـ `component DescriptionLabel` مخصص **محلي لملف SessionScreen فقط** — مش قابل لإعادة الاستخدام من أي widget تاني في الشل. أي feature جديدة محتاجة تعرض رسالة عابرة (زي "تم نسخ اللون"، "فشل حفظ الويدجت"، "تم تفعيل/تعطيل EasyEffects") لازم تخترع حل خاص بيها من الصفر.

**خطة النقل:**
- خدمة جديدة: `shell/services/Toaster.qml` (singleton، قائمة `toasts: []`، دالة `Toaster.show(type, title, message, icon)`).
- مكوّن عرض جديد: `shell/modules/ii/toasts/Toasts.qml` + `ToastItem.qml` (نافذة `PanelWindow` صغيرة `exclusionMode: Ignore` في زاوية الشاشة، شبيهة بموقع `onScreenDisplay`).
- إضافة `Config.options.toasts.maxVisible`, `Config.options.toasts.position` ("top-right"/"bottom-right"/...), `Config.options.toasts.fullscreenPolicy`.
- استبدال الاستخدامات الحالية المرتجلة (SessionScreen warnings) لاستخدام `Toaster.show(...)` تدريجيًا كأول تطبيق حقيقي، بدون ما يتكسر أي حاجة فيها الآن.
- IPC: `IpcHandler { target: "toast" function show(type, title, message) }` — مفيد لو سكربتات bash خارجية (زي `switchwall.sh`) حابة تبلّغ المستخدم بنجاح/فشل عملية.

**الأولوية: عالية.** ده مش "ويدجت" بمعنى تجميلي — ده بنية تحتية بتحل مشكلة تتكرر (كل ميزة جديدة بتحتاج تبليغ المستخدم بحاجة عابرة، حاليًا كل واحدة بتخترع حل بديل زي `notify-send` خارجي أو label محلي). أي ميزة من القائمة دي (clipboard alias confirm، tmux kill confirm، إلخ) هتستفيد منه فورًا.

**ملاحظة توافق:** compositor-agnostic بالكامل — QML/JS خالص، بلا أي API خاص بـ Wayland. يشتغل على Hyprland/Niri/i3 بلا أي فرق.

---

### 2.3 وضع Freeze في أداة اختيار المنطقة (Screenshot)

**المصدر:** caelestia-shell، `modules/areapicker/AreaPicker.qml` — أربعة IPC targets منفصلة: `open`, `openFreeze`, `openClip`, `openFreezeClip`.

**الوصف التقني:** `root.freeze` property بيتفعّل قبل فتح نافذة اختيار المنطقة. في وضع الـ freeze، الأداة بتاخد screenshot ثابت للشاشة الأول (عبر أداة خارجية زي `grim`) وتعرضه كخلفية للنافذة، بحيث المستخدم بيرسم مربع الاختيار فوق **صورة ثابتة** مش الشاشة الحية — يعني أي نافذة تتقفل أو محتوى يتحرك (فيديو/أنيميشن) وقت الاختيار مبيأثرش على القص النهائي. النافذة نفسها `WlrLayershell.exclusionMode: Ignore` + `layer: Overlay` + `keyboardFocus` شرطي (`None` وقت الإغلاق، `Exclusive` غير كده) — نمط قياسي لأي أداة تقاط شاشة.

**مقارنة بـ Horizons-DE:** `shell/modules/ii/regionSelector/RegionSelector.qml` الحالي بيستخدم `grim -g "$(slurp)"` مباشرة على الشاشة الحية — بحث في `RegionSelection.qml`/`OptionsToolbar.qml` مفيهوش أي إشارة لـ freeze mode. يعني لو المستخدم فتح الأداة وبعدين قرر ياخد سكرين شوت لنافذة بتتحرك (فيديو، لعبة)، ممكن المحتوى يتغيّر وقت السحب.

**خطة النقل:**
- تعديل `shell/modules/ii/regionSelector/RegionSelector.qml`: إضافة `property bool freeze: false`، ولما يتفعّل، ياخد screenshot كامل للشاشة الأول (`grim` بلا `-g`) ويحطه كخلفية `Image` تملأ نافذة الاختيار قبل ما `slurp`/اختيار المنطقة يبدأ.
- إضافة IPC handlers جداد: `screenshotFreeze`, `screenshotFreezeClip` جنب الموجودين بالفعل (نفس نمط الأربع targets في caelestia).
- `Config.options.screenshot.defaultFreeze: false` (اختياري: خلي الوضع الافتراضي freeze لو المستخدم حابب).

**الأولوية: عالية-متوسطة.** فجوة وظيفية واضحة ومحدودة النطاق (تعديل على ملف موجود بالفعل، مش ميزة جديدة من الصفر)، وقيمتها واضحة لأي مستخدم بياخد screenshots لمحتوى متحرك.

**ملاحظة توافق: Wayland/Hyprland+Niri فقط.** `grim`/`slurp` أدوات Wayland screenshot خالصة، **ملهاش مكافئ على i3/X11** (زي ما هو موثّق في `docs/i3-quickshell-research.md` §2 بخصوص أدوات مشابهة) — على i3 لازم أداة بديلة تمامًا (`maim`/`scrot`/`import` من ImageMagick) لو الميزة دي (أو حتى `RegionSelector` الحالي نفسه) هتتفعّل هناك مستقبلاً. هذا قيد موجود بالفعل في `RegionSelector.qml` الحالي، مش قيد جديد بيضيفه الـ freeze mode.

---

### 2.4 Integrated Dock — الدوك كعنصر جوه البار نفسه

**المصدر:** Ambxst، `modules/bar/IntegratedDock.qml` + `IntegratedDockAppButton.qml`.

**الوصف التقني:** الدوك مش نافذة منفصلة — عنصر `StyledRect` بيتحط كعنصر عادي جوه تخطيط البار (`RowLayout`/`ColumnLayout`)، مربوط بـ `Config.dock.theme === "integrated"` (مقابل `"default"` = دوك منفصل). بيدعم أفقي وعمودي (`orientation`)، وبياخد قائمة التطبيقات من `TaskbarApps.apps` (خدمة تطبيقات مفتوحة موحّدة). كل زرار (`IntegratedDockAppButton`) بحجم مصغّر (`iconSize: 18`) عشان يتناسب مع ارتفاع البار العادي، جوه `Flickable` قابل للتمرير لو التطبيقات كتير عن مساحة البار.

**مقارنة بـ Horizons-DE:** `Dock.qml` الحالي دايمًا نافذة `PanelWindow` منفصلة (زي `Bar.qml`) — مفيش خيار "ادمج الدوك جوه البار" خالص. ده قرار تصميمي معقول (فصل الاهتمامات)، لكن بعض المستخدمين بيفضّلوا شريط واحد موحّد بدل شريطين منفصلين يتصادموا بصريًا.

**خطة النقل:**
- ملف جديد: `shell/modules/ii/bar/IntegratedDock.qml` — يعيد استخدام منطق `Dock.qml` الموجود (قائمة التطبيقات عبر `WM`/`ToplevelManager`) لكن بحجم مصغّر مناسب لارتفاع البار، بدل ما يتكرر من الصفر.
- تسجيله كعنصر تخطيط بار جديد باسم `"dock"` قابل للإضافة في `Config.options.bar.layouts.{left,middle,right}Layout` (النمط ده جاهز بالفعل — البار الحالي مبني على قوائم string زي `["launcherButton", "workspaces", "activeWindow"]`، فإضافة عنصر جديد أمر معتاد في هذه البنية).
- إضافة `Config.options.bar.integratedDock.enable: false` (افتراضيًا معطّل، عشان الدوك المنفصل الحالي يفضل السلوك الافتراضي) + `Config.options.bar.integratedDock.maxVisibleApps`.
- لما `integratedDock.enable === true`، منطقي تعطيل `Dock.qml` المنفصل تلقائيًا عشان مايتكررش نفس التطبيقات مرتين.

**الأولوية: متوسطة.** تحسين UX حقيقي لفئة من المستخدمين (شاشات صغيرة، تفضيل التوحيد البصري)، لكن مش فجوة وظيفية (الدوك نفسه شغال بالفعل كنافذة منفصلة) — تكلفة التنفيذ منخفضة لأن كل المنطق (قائمة التطبيقات) موجود ومُختبر بالفعل في `Dock.qml`.

**ملاحظة توافق:** نفس قيود `Dock.qml` الحالي بالظبط — قائمة التطبيقات المفتوحة عبر `ToplevelManager` بروتوكول **Wayland-only** (`wlr-foreign-toplevel-management`)، فمش هيشتغل على i3/X11 بلا بديل (على i3 ممكن استبداله بقائمة `i3-msg get_tree` الموجودة أصلاً في `I3Backend.qml`، لكن ده تنفيذ إضافي منفصل). قيد موروث، مش جديد.

---

### 2.5 لوحة Kanban كويدجت مستقل

**المصدر:** Ax-Shell (متوقف)، `modules/kanban.py`.

**الوصف التقني:** لوحة Kanban كاملة (أعمدة + بطاقات) مكتوبة GTK3 بايثون خالص — `InlineEditor` (مكوّن `Gtk.TextView` قابل لإدخال متعدد الأسطر مع دعم Shift+Enter لسطر جديد مقابل Enter للتأكيد)، البطاقات قابلة للسحب بين الأعمدة (drag & drop GTK)، والتخزين محلي بصيغة JSON (`json`/`pathlib`). لا يوجد أي مكافئ له في Ambxst (أُسقط بالكامل وقت إعادة الكتابة لـ QML) ولا caelestia ولا Horizons-DE.

**خطة النقل:**
- ويدجت جديد على غرار `background/widgets/todo/TodoWidget.qml` الموجود بالفعل (نفس فئة "ويدجت سطح مكتب قابل للسحب/التحجيم")، مسار مقترح: `shell/modules/ii/background/widgets/kanban/KanbanWidget.qml` + `KanbanColumn.qml` + `KanbanCard.qml`.
- التخزين: ملف JSON محلي (`~/.local/state/quickshell/ii/kanban.json` أو مكافئ `Directories.qml` الحالي) — نفس نمط `TodoWidget`/`NotesWidget` الموجودين بالفعل (لازم فحص إزاي هما بيخزّنوا حاليًا، الأرجح `FileView`/`Quickshell.Io`).
- السحب والإفلات: QML `Drag`/`DropArea` (مش GTK زي الأصل) — الأعمدة `ListView`/`Repeater` جوه `RowLayout`، البطاقات `MouseArea` مع `Drag.active`.
- إضافة `Config.options.background.widgets.kanban.{enable,x,y,placementStrategy,columns}` بنفس نمط باقي background widgets (`todo`, `notes`).
- IPC: مش ضروري، الويدجت تفاعلي محلي.

**الأولوية: متوسطة.** ميزة مفيدة فعليًا (إدارة مهام بصرية) لكن Horizons-DE عنده بالفعل `TodoWidget` يغطي جزء من نفس الاحتياج (قائمة مهام بسيطة) — Kanban إضافة تكميلية مش بديل، فالأولوية أقل من الفجوات اللي معندهاش أي بديل حاليًا (WindowInfo، Toast).

**ملاحظة توافق:** compositor-agnostic بالكامل (QML+JSON محلي، بلا أي API خاص بـ Wayland/Hyprland) — هيشتغل بنفس الجودة على i3/X11 و Hyprland/Niri.

---

## 3. الفجوات ذات الأولوية المتوسطة

### 3.1 EasyEffects — من Toggle بسيط لـ Panel كامل

**المصدر:** Ambxst، `modules/widgets/dashboard/controls/EasyEffectsPanel.qml` + خدمة `EasyEffectsService`.

**الوصف التقني:** بدل toggle تشغيل/إيقاف بس، الـ panel بيعرض قوائم presets فعلية (Output/Input presets) كأزرار قابلة للنقر مباشرة (`EasyEffectsService.outputPresets` — الأرجح بتُقرأ من ملفات presets الـ JSON بتاعة EasyEffects نفسها في `~/.config/easyeffects/`)، زرار "Bypass" منفصل عن التفعيل الكامل، وزرار فتح التطبيق الأصلي/تحديث القائمة.

**مقارنة بـ Horizons-DE:** `EasyEffectsToggle.qml` الحالي (`sidebarRight/quickToggles/classicStyle/`) بس toggle تشغيل/إيقاف (`EasyEffects.toggle()`) + right-click لفتح التطبيق الخارجي (flatpak/native) — مفيش أي وصول لقوائم presets من جوه الشل نفسه.

**خطة النقل:**
- توسيع خدمة `EasyEffects` الموجودة (`shell/services/` — لازم فحص الملف الفعلي، مش واضح اسمه بالظبط من نتائج البحث) بإضافة قراءة presets (`Quickshell.Io.FileView` على `~/.config/easyeffects/output/*.json` و`input/*.json`، أو عبر D-Bus لو EasyEffects بيعرّض presets list في الـ interface بتاعه).
- ملف جديد: `shell/modules/ii/sidebarRight/easyeffects/EasyEffectsPanel.qml` كـ dialog إضافي مشابه لـ `VolumeDialogContent.qml`/`BluetoothDialog.qml` المفتوحة من `SystemButtonRow.qml`.
- `Config.options.audio.easyEffects.showPresetsPanel: true`.

**الأولوية: متوسطة.** تحسين عمق حقيقي، لكن الوظيفة الأساسية (تفعيل/تعطيل EasyEffects) موجودة بالفعل ومغطّاة — ده "أعمق" مش "غائب".

**ملاحظة توافق:** compositor-agnostic (EasyEffects نفسه تطبيق صوت مستقل عن الـ compositor، D-Bus/PipeWire) — يشتغل بنفس الشكل على Hyprland/Niri/i3.

---

### 3.2 Clipboard كـ Dashboard Tab بعمق أكبر (Pin/Alias/Reorder/Link Preview)

**المصدر:** Ambxst، `modules/widgets/dashboard/clipboard/ClipboardTab.qml` (~3600 سطر — أضخم ملف واحد اتفحص في التدقيق كله).

**الوصف التقني:** واجهة بحث+قائمة كاملة فوق `ClipboardService`، بميزات مش موجودة في تكامل clipboard البسيط:
- **Pin/Unpin** عناصر معيّنة تفضل فوق القائمة دايمًا.
- **Alias** — تسمية مخصصة لأي عنصر (بدل النص الخام الطويل)، معدّل عبر "alias mode" (Ctrl+R يفتحه، Enter يأكّده).
- **إعادة ترتيب يدوي** (`moveItemUp`/`moveItemDown`) عبر سحب رأسي أو Ctrl+Up/Down.
- **حذف بتأكيد مزدوج** (سحب أفقي أو زرار، مع مرحلة "اضغط تاني للتأكيد" شبيهة بالضبط بنمط `SessionScreen.qml`'s `runDestructiveAction` الموجود بالفعل في Horizons-DE).
- **معاينة روابط (Link Preview)**: لو العنصر URL، بيعمل fetch لمعلومات الصفحة (عنوان/favicon) ويكاشها (`linkPreviewCache`) — تكامل شبكة إضافي مش موجود في نسخة clipboard البسيطة.
- كل ده مبني فوق قاعدة بيانات SQLite محلية (`sqlite3` CLI مباشر عبر `Process`، مش مكتبة QML SQL) لقراءة/تحديث المحتوى الكامل.

**مقارنة بـ Horizons-DE:** `services/Cliphist.qml` + `common/widgets/CliphistImage.qml` موجودين، غالبًا مربوطين بـ launcher/popup بسيط (زي أي cliphist-picker تقليدي) — بس مفيش pin/alias/reorder/link-preview من الفحص اللي اتعمل (يحتاج فحص أعمق لملف `Cliphist.qml` نفسه للتأكيد الكامل، لم يُقرأ بالكامل في هذه الجولة).

**خطة النقل:**
- توسيع `shell/services/Cliphist.qml`: إضافة `pinnedIds`, `aliases` (تخزين محلي JSON منفصل عن قاعدة بيانات cliphist نفسها، لأن `cliphist` الأداة الخارجية مالهاش مفهوم pin/alias أصلاً — الميزة دي طبقة فوق الأداة مش منها).
- تحسين واجهة العرض الحالية (أيًا كانت) بإضافة أزرار Pin/Alias/Delete مع تأكيد مزدوج (نفس نمط `SessionScreen`'s confirm-destructive الموجود، إعادة استخدام الفكرة).
- Link preview: خدمة `Process`/`XMLHttpRequest` لجلب `<title>`/favicon من الرابط — يحتاج قرار خصوصية (fetch تلقائي لأي رابط منسوخ = تسريب IP/نشاط للمواقع الخارجية، يستاهل يبقى Config option معطّل افتراضيًا: `Config.options.clipboard.fetchLinkPreviews: false`).

**الأولوية: متوسطة.** الوظيفة الأساسية (تاريخ الحافظة + بحث) موجودة، فهذه تحسينات عمق مش سد فجوة كاملة — لكن pin/alias فايدتهم عملية يومية واضحة لمستخدمي clipboard managers.

**ملاحظة توافق:** compositor-agnostic في المنطق (SQLite/JSON)، لكن الأداة الأساسية (`cliphist` + `wl-copy`/`wl-paste`) **Wayland-only** — على i3/X11 محتاج `xclip`/`xsel` + أداة history مكافئة (`clipmenu` مثلاً)، وهو قيد موروث من `Cliphist.qml` الحالي نفسه، مش جديد.

---

### 3.3 Tmux Tab — إدارة جلسات tmux من داخل الشل

**المصدر:** Ambxst، `modules/widgets/dashboard/tmux/TmuxTab.qml`.

**الوصف التقني:** تاب بحث+قائمة (نفس هيكل `ClipboardTab.qml` تقريبًا) فوق جلسات `tmux` — قراءة `tmux list-sessions`/`list-windows`/`list-panes` (عبر `Process`)، مع إجراءات: فتح جلسة (فتح terminal جديد ملحق بيها `tmux attach -t <name>`)، إعادة تسمية (`tmux rename-session`)، إنهاء (`tmux kill-session`)، ومعاينة نوافذ/panes الجلسة قبل الفتح (`sessionWindows`/`sessionPanes` properties).

**مقارنة بـ Horizons-DE:** لا يوجد أي تكامل tmux خالص — تأكّد بالـ grep (صفر نتائج فعلية غير `material_symbols_rounded.json`).

**خطة النقل:**
- خدمة جديدة: `shell/services/Tmux.qml` (singleton، `Process` calls لـ `tmux list-sessions -F "..."` بصيغة parseable، تحديث دوري أو عبر `tmux control mode` لو حابين حل أكثر حيّة).
- واجهة: تاب جديد جوه `SidebarLeft`/`SidebarRight` أو نافذة popup منفصلة — مسار مقترح: `shell/modules/ii/sidebarLeft/tmux/TmuxPanel.qml` (بما إن `sidebarLeft` عنده بالفعل `AiChat`/`Translator`/`Anime` كتابات متعددة الأغراض، فالنمط التصميمي لإضافة تاب جديد موجود).
- `Config.options.tmux.enable: false` (افتراضيًا معطّل، لأن الميزة مشروطة بوجود `tmux` مثبّت — Terminal-heavy users بس).
- **Dependency جديد:** `tmux` مش معلن في أي PKGBUILD حاليًا (تأكّد بالبحث في `dotfiles/sdata/dist-arch/`) — لازم يتضاف كـ optional dependency في `illogical-impulse-widgets/PKGBUILD` (أو حزمة جديدة `illogical-impulse-tmux` لو حابين يبقى فصل اختياري تمامًا بدل إجباري).

**الأولوية: متوسطة-منخفضة.** فايدة حقيقية لكن لفئة ضيقة من المستخدمين (مستخدمي tmux تحديدًا)، على عكس clipboard/EasyEffects اللي كل مستخدم بيستفاد منهم.

**ملاحظة توافق:** compositor-agnostic بالكامل (tmux أداة terminal مستقلة تمامًا عن الـ compositor) — تشتغل بنفس الشكل على Hyprland/Niri/i3.

---

### 3.4 Pomodoro مربوط بـ Spotify (إيقاف/تشغيل تلقائي)

**المصدر:** Ambxst، `modules/bar/clock/Pomodoro.qml`.

**الوصف التقني:** لما جلسة العمل (work session) تبدأ، الكود بيدوّر على أي MPRIS player اسمه فيه "spotify" (`MprisController.filteredPlayers`) ولو لقاه ومش شغال، بيشغّله تلقائيًا (`spotify.play()`)؛ ولما الجلسة توقف أو تبقى استراحة، بيوقّفه (`spotify.pause()`) — مربوط بـ `Config.system.pomodoro.syncSpotify` (قابل للتعطيل). فيه IPC target كمان (`pomodoro.check()`, `pomodoro.stop()`) لفتح/إيقاف من سطر أوامر خارجي.

**مقارنة بـ Horizons-DE:** `PomodoroTimer.qml`/`PomodoroWidget.qml` (`sidebarRight/pomodoro/`) و`PomodoroBar.qml` (`bar/`) موجودين بعمق مماثل في المنطق الأساسي (عمل/استراحة/دورات)، لكن بلا أي ربط بمشغّل الوسائط.

**خطة النقل:**
- إضافة بسيطة في `PomodoroTimer.qml` الموجود: استخدام `MprisController` (خدمة موجودة بالفعل ومستخدمة في `Media.qml`/`SidebarPlayerControl.qml`) لتشغيل/إيقاف أي player نشط وقت بداية/نهاية جلسة العمل — مش لازم يتقيّد بـ Spotify تحديدًا، ممكن يبقى "أوقف/شغّل المشغل النشط حاليًا" (أعمّ وأفيد).
- `Config.options.sidebar.pomodoro.syncMediaPlayback: false`.

**الأولوية: منخفضة.** لمسة UX لطيفة، تعديل صغير على ملف موجود، بس مش فجوة وظيفية جوهرية.

**ملاحظة توافق:** compositor-agnostic (MPRIS بروتوكول D-Bus مستقل عن الـ compositor).

---

### 3.5 Gradient Stops Editor — محرر تدرّجات لسطوح الثيم

**المصدر:** Ambxst، `modules/widgets/dashboard/controls/GradientStopsEditor.qml` (تصحيح مهم عن وصف البرومبت: هذا **مش** محرر تدرّج لصورة الخلفية/الـ wallpaper، لكنه محرر تدرّجات الألوان (multi-stop gradients) لكل "سطح" في نظام الثيم بتاع Ambxst نفسه — bg/pane/primary/secondary/... إلخ، كل واحد منهم عنده تدرّج قابل للتخصيص بدل لون واحد ثابت).

**الوصف التقني:** شريط تدرّج (`Canvas` بيرسم `createLinearGradient`) مع "مقابض" (handles) قابلة للسحب لكل نقطة توقف (stop) — كل نقطة عندها لون (مُختار عبر `ColorButton`/`ColorPickerView` منفصل) وموضع (0.0-1.0). دعم لغاية 8 نقاط توقف، إضافة بضغطتين (double-click على الشريط)، حذف بكليك يمين/أوسط، وزرار "Reset" يرجّع التدرّج الافتراضي المُعرَّف في `theme.js`.

**مقارنة بـ Horizons-DE:** نظام الألوان الحالي (`Appearance.qml`, M3 color roles) بيستخدم **ألوان مصمتة (solid colors)** لكل سطح، مش تدرّجات. إضافة تدرّجات فعلية بتحتاج تغيير جوهري في طبقة الرسم نفسها (كل مكان بيستخدم `color: Appearance.colors.colLayerX` هيحتاج يتحول لـ `gradient:` أو `Rectangle` مع `LinearGradient`)، مش بس إضافة محرر.

**خطة النقل (طويلة المدى، مش سريعة):**
- ده مش "ويدجت يتضاف" — ده تغيير في نظام الثيم نفسه. لو اتقرر المتابعة، أول خطوة فحص حجم التأثير على `Appearance.qml`/`SystemTheming.qml`/`MaterialThemeLoader.qml` قبل أي التزام.
- لو اتقرر التنفيذ: إضافة `Config.options.appearance.surfaceGradients: {}` (خريطة surface→stops)، ومحرر QML شبيه (`Canvas` + draggable handles) في صفحة إعدادات المظهر الحالية (`InterfaceConfig.qml`/`BackgroundConfig.qml`).

**الأولوية: منخفضة.** قيمة بصرية حقيقية بس تكلفة تنفيذ عالية غير متناسبة (تغيير جوهري في نظام الألوان بالكامل)، ومش "ويدجت" منفصل بالمعنى الدقيق — أقرب لتغيير معماري في نظام المظهر يستاهل مستند منفصل خاص بيه لو قُرِّر المتابعة.

**ملاحظة توافق:** compositor-agnostic بالكامل (رسم QML خالص).

---

### 3.6 Nexus — نمط "لوحة تحكم موحّدة" (Nav Pane) بدل تجزئة الإعدادات

**المصدر:** caelestia-shell، `modules/nexus/**` (~35 ملف: `NavPane.qml`, `PageRegistry.qml`, صفحات `Apps/Audio/Bluetooth/Network/Panels/Services/WallpaperAndStyle/About/LanguageAndRegion`).

**الوصف التقني:** Nexus **مش ويدجت واحد** — هو نافذة تطبيق كاملة شبه "GNOME Settings" جوه الشل نفسه: عمود تنقّل جانبي (`NavPane.qml`) + منطقة محتوى تتغيّر حسب الصفحة المختارة (`PageCompRegistry.qml`/`Pages.qml` نظام تسجيل صفحات ديناميكي). فيه صفحات بتتحكم في تخصيص أجزاء الشل نفسه (`pages/panels/{DashboardPanel,LauncherPanel,SidebarPanel,TaskbarPanel,UtilitiesPanel}.qml` — كل واحدة فيها إعدادات مفصّلة لعنصر واجهة معيّن، زي `taskbar/{BarActiveWindow,BarClock,BarStatusIcons,BarTray,BarWorkspaces}.qml` يعني حتى **تفعيل/تعطيل/ترتيب عناصر البار نفسه بيتحكم فيه من جوه Nexus**)، وصفحات نظام (`AppsPage`, `AudioPage`/`AppVolumes`, `BluetoothPage`/`BluetoothPairing`, `NetworkPage` بكل تفاصيله من `AddNetworkPage` لـ `EthernetDetailPage`).

**مقارنة بـ Horizons-DE:** الإعدادات موزّعة على مسارين منفصلين حاليًا — `shell/modules/ii/settings/pages/*.qml` (صفحات إعدادات تقليدية: `BarConfig`, `BackgroundConfig`, `HyprlandConfig`, `NiriConfig`, ...) في نافذة `Settings.qml` منفصلة، والتحكمات السريعة (Bluetooth/WiFi/Audio) في `sidebarRight` كـ dialogs منبثقة منفصلة. الفرق الجوهري: Nexus بيوحّد الاتنين في تجربة واحدة (نفس النافذة، نفس نمط التنقل)، بينما Horizons-DE عنده تجربتين متوازيتين (إعدادات = نافذة كاملة، تحكم سريع = popups صغيرة).

**خطة النقل:** **مش موصى بيها كنقل مباشر الآن.** ده قرار بنية معلومات (information architecture) على مستوى الشل كله، مش ميزة منفردة تُضاف. النقاش المناسب: هل توحيد `Settings.qml` + كل الـ quick-toggle dialogs في نافذة واحدة بنمط nav-pane يستاهل، مقابل الحفاظ على الفصل الحالي (إعدادات دائمة في نافذة، تحكم سريع في popups خفيفة)؟ ده قرار UX استراتيجي يحتاج نقاشه في مستند تخطيط منفصل (خارج نطاق البار/الويدجتس الضيق)، مش تنفيذ مباشر هنا.

**الأولوية: منخفضة (كنقل مباشر) / تستاهل نقاش منفصل (كقرار معماري).** أدرجناها بالتفصيل لأن البرومبت طلب صراحة فحص "إيه هو نيكسس بالظبط" — الإجابة: نمط IA لدمج الإعدادات والتحكم السريع، مش widget قابل للنقل مباشر.

**ملاحظة توافق:** compositor-agnostic في الغالب (واجهة تنقّل + صفحات إعدادات)، لكن بعض الصفحات الفرعية (زي `panels/TaskbarPanel.qml`) بتفترض بار caelestia الأفقي البسيط — أي نقل حقيقي محتاج تكييف مع تعدد أوضاع البار في Horizons-DE (`classic`/`mesoBar`/`tasklistBar`/`sysmonitorBar`/...).

---

### 3.7 قراءة Cava عبر FIFO ثنائي بدل نص stdout

**المصدر:** Ax-Shell (متوقف)، `modules/cavalcade.py`.

**الوصف التقني:** بدل تشغيل `cava` وقراءة إخراجه كنص عبر stdout (زي `raw_output_config.txt` النصي الحالي)، `cavalcade.py` بيعمل `os.mkfifo("/tmp/cava.fifo")` ويشغّل cava بإعداد بيكتب بيانات **ثنائية** (binary output format، غالبًا `bit_format = 16bit`) للـ FIFO، وبيقرأها بـ `struct`/`ctypes` مباشرة (بلا تحويل نص→رقم لكل قيمة). كمان بيستخدم `prctl(PR_SET_PDEATHSIG)` عشان لو العملية الأم اتقفلت، cava يتقفل معاها تلقائيًا (منع عمليات cava يتيمة).

**مقارنة بـ Horizons-DE:** `MediaControls.qml` الحالي بيشغّل `cava -p raw_output_config.txt` ويقرأ الإخراج كنص عبر `SplitParser` (`data.split(";").map(parseFloat)`) — شغال وبسيط، لكن فيه تكلفة parsing نصي (split+parseFloat) لكل نبضة تحديث بدل قراءة بايتات ثابتة الحجم مباشرة.

**خطة النقل:** تعديل دقيق على `MediaControls.qml` الموجود — تغيير إعداد cava لصيغة binary output عبر FIFO، واستبدال `SplitParser` بقراءة `DataStreamReader`/binary buffer مباشرة. **تحسين أداء صغير الحجم، مش ميزة جديدة.**

**الأولوية: منخفضة.** الحل الحالي شغال بالفعل وبيؤدي نفس الوظيفة — ده تحسين كفاءة هامشي (تقليل CPU overhead لكل نبضة تحديث visualizer)، مش يستاهل إعادة كتابة إلا لو فيه دليل فعلي إن الطريقة النصية الحالية بتسبب مشكلة أداء ملحوظة.

**ملاحظة توافق:** compositor-agnostic (cava أداة صوت مستقلة).

---

## 4. لمسات منخفضة الأولوية

### 4.1 GIF متحرك في شاشة الجلسة (Session Screen)
**المصدر:** caelestia، `modules/session/Content.qml` — `AnimatedImage` (GIF) بيتعرض في نص قائمة أزرار الجلسة، بسرعة قابلة للتحكم (`Config.general.sessionGifSpeed`). لمسة شخصية/جمالية بحتة. **الأولوية: منخفضة جدًا** — Horizons-DE's `SessionScreen.qml` بالفعل أعمق وظيفيًا (حماية بكلمة سر، تأكيد مزدوج) من نسخة caelestia، فهذه مجرد إضافة تجميلية اختيارية (`Config.options.sessionScreen.showAnimation`، صورة GIF قابلة للتخصيص من `Directories.qml`). **التوافق:** compositor-agnostic.

### 4.2 استخراج لوحة ألوان بـ GPU Shader لمعاينة الفيديو الحية
**المصدر:** Ambxst، `modules/widgets/dashboard/wallpapers/{palette.frag,palette.vert,MpvShaderGenerator.js}` (ملفات `.qsb` = Qt Shader Bytecode مُصرّفة مسبقًا). الفكرة: استخراج لوحة ألوان من الفيديو **أثناء تشغيله كمعاينة حية** في تاب الخلفيات عبر GPU fragment shader، بدل استدعاء سكربت خارجي (`ffmpeg`/Python) ياخد فريم واحد ثابت. **مقارنة:** `generate_colors_material.py` الحالي في Horizons-DE (بايثون، subprocess) شغال بالفعل وبيغطي الصور الثابتة والفيديوهات (على الأغلب بياخد فريم واحد ثابت من الفيديو، محتاج تأكيد إضافي مش متاح في هذه الجولة). **الأولوية: منخفضة** — تحسين أداء/جودة معاينة محتمل (تفادي subprocess لكل تغيير فيديو)، لكن يحتاج فحص فعلي لكود `generate_colors_material.py` والتأكد إنه بالفعل بيستهلك موارد ملحوظة مع الفيديو قبل تبرير كتابة GPU shader من الصفر (استثمار هندسي أعلى بكتير من باقي البنود). **التوافق:** compositor-agnostic (رسم Qt Quick Shader Effects).

---

## 5. ميزات مؤكَّد تكافؤها بالفعل (لا حاجة لعمل إضافي)

فحص الكود أثبت إن البنود دي من قائمة البرومبت **موجودة بالفعل بعمق مماثل** في Horizons-DE، فمالهاش قسم تفصيلي منفصل فوق:

| الميزة | ملف/خدمة Horizons-DE المكافئة |
|---|---|
| Audio Mixer per-app | `sidebarRight/volumeMixer/VolumeMixerEntry.qml` (`Quickshell.Services.Pipewire`) |
| Bluetooth panel | `sidebarRight/bluetoothDevices/BluetoothDialog.qml` |
| WiFi panel | `sidebarRight/wifiNetworks/WifiDialog.qml` |
| Emoji picker (كوظيفة، مش كتاب مستقل) | `services/Emojis.qml` + `LauncherSearch.qml` |
| Notes | `background/widgets/notes/NotesWidget.qml` + `overlay/notes/NotesContent.qml` |
| Video wallpaper | `services/Wallpapers.qml` + mpvpaper (نفس آلية Ambxst) |
| Cava integration مباشر | `mediaControls/MediaControls.qml` (`Process` + `SplitParser`) |
| Overview | `overview/Overview.qml`, `NiriOverview.qml`, `WindowSwitcher.qml` |
| Session/Power screen | `sessionScreen/SessionScreen.qml` (أعمق من caelestia فعليًا) |
| OSD | `onScreenDisplay/OnScreenDisplay.qml` |
| Settings Crawler | مُغطّى في `docs/quickshell-competitor-audit.md` §3 (مبني هذه الجلسة) |

---

## 6. جدول ملخّص — مرتّب بالأولوية

| # | الميزة | المصدر | الأولوية | Wayland فقط؟ | تكلفة تقديرية |
|---|---|---|---|---|---|
| 1 | نظام Toast موحّد | caelestia | **عالية** | لا (agnostic) | متوسطة (خدمة + مكوّن عرض جديدين) |
| 2 | WindowInfo popup للنافذة النشطة | caelestia | **عالية** | جزئيًا (المعاينة المصغّرة بس Wayland) | متوسطة (نمط popup جاهز، محتاج ربط بـ WM.qml) |
| 3 | Freeze mode في Screenshot | caelestia | **عالية-متوسطة** | نعم (grim/slurp أصلاً) | منخفضة (تعديل ملف موجود) |
| 4 | Integrated Dock في البار | Ambxst | متوسطة | نعم (ToplevelManager) | منخفضة (إعادة استخدام منطق Dock.qml) |
| 5 | لوحة Kanban | Ax-Shell | متوسطة | لا (agnostic) | متوسطة (ويدجت جديد + تخزين JSON) |
| 6 | EasyEffects panel كامل (presets) | Ambxst | متوسطة | لا (agnostic) | متوسطة (تحتاج قراءة presets EasyEffects) |
| 7 | Clipboard tab: pin/alias/reorder/preview | Ambxst | متوسطة | نعم (cliphist/wl-copy أصلاً) | عالية (أكبر ملف اتفحص، ميزات كتير) |
| 8 | Tmux tab | Ambxst | متوسطة-منخفضة | لا (agnostic) | متوسطة (خدمة + واجهة جديدتين + dependency جديد) |
| 9 | Pomodoro ↔ مشغّل الوسائط | Ambxst | منخفضة | لا (agnostic) | منخفضة (تعديل صغير على ملف موجود) |
| 10 | GIF في شاشة الجلسة | caelestia | منخفضة جدًا | لا (agnostic) | منخفضة جدًا |
| 11 | استخراج لوحة ألوان بـ Shader للفيديو | Ambxst | منخفضة | لا (agnostic) | عالية (يحتاج تبرير أداء أولاً) |
| 12 | Cava عبر FIFO ثنائي | Ax-Shell | منخفضة | لا (agnostic) | منخفضة (تحسين ملف موجود) |
| 13 | Gradient Stops Editor لسطوح الثيم | Ambxst | منخفضة | لا (agnostic) | عالية جدًا (تغيير نظام ألوان كامل) |
| 14 | Nexus (نمط nav-pane موحّد) | caelestia | منخفضة (كنقل مباشر) | لا (agnostic) | عالية جدًا (قرار IA على مستوى الشل، خارج نطاق هذا المستند) |

---

## المصادر
- `G:\dotfiles\Ax-Shell\modules\kanban.py`, `modules\cavalcade.py`
- `G:\dotfiles\Ambxst\modules\bar\{IntegratedDock,IntegratedDockAppButton,clock\Pomodoro}.qml`
- `G:\dotfiles\Ambxst\modules\widgets\dashboard\{clipboard\ClipboardTab,tmux\TmuxTab,controls\{EasyEffectsPanel,ColorPickerView,GradientStopsEditor},wallpapers\*}.qml`
- `G:\dotfiles\caelestia-shell\modules\{windowinfo\*,areapicker\AreaPicker,utilities\toasts\*,session\Content,osd\Content,nexus\**}.qml`
- `G:\End4-PXpC\shell\modules\ii\{bar,sidebarLeft,sidebarRight,background\widgets,dock,overview,sessionScreen,regionSelector,mediaControls}\**`
- `G:\End4-PXpC\shell\services\{Cliphist,Wallpapers,Emojis,WM}.qml`
- `G:\End4-PXpC\shell\modules\common\Config.qml` (بنية الـ schema المستخدَمة في كل مقترحات الإعدادات أعلاه)
- `G:\End4-PXpC\dotfiles\sdata\dist-arch\illogical-impulse-{widgets,audio}\PKGBUILD` (فحص الـ dependencies الحالية: cava موجود، tmux غير موجود)
- `G:\End4-PXpC\docs\quickshell-competitor-audit.md`, `dots-integration-audit.md`, `i3-quickshell-research.md` (تجنّب تكرار البحث + ملاحظات التوافق مع i3/X11)

---

# 2. نظام الأنيميشن الشامل — خطة التوحيد والتخصيص

> نطاق هذا التقرير: بحث وتخطيط فقط لنظام الـ Animation/Motion في Horizons-DE. لا تعديل ولا إنشاء أي كود. المصادر: `caelestia-shell` (نظام Anim tokens)، `Ambxst` (أنيميشن ثقيل/شيدرز)، `Ax-Shell` (CSS transitions)، والكود الحالي في `G:\End4-PXpC\shell`.

---

## 0. الخلاصة التنفيذية

- نظام `Anim` بتاع caelestia هو **QML خالص فعليًا** — الجزء اللي في C++ (`plugin/src/Caelestia/Config/anim.cpp`) مالوش أي قيمة وظيفية إضافية بالنسبة لـ Horizons-DE، لأن كل اللي بيعمله (تخزين bezier control points reactive + ضرب الـ duration في scale factor reactive) موجود أصلاً في `Config.qml` (`JsonObject`/`JsonAdapter`) و`Appearance.qml` (Singleton بخصائص `real`/`list<real>` reactive). يعني **ينفع نعمل نسخة QML-only 100% من نفس الفكرة بدون أي C++ plugin جديد**. التفاصيل في القسم 1.
- نظام `Appearance.animation.*` الحالي في Horizons-DE (حوالي 419 استخدام في 130 ملف) شغال كويس ومتجذر جدًا — **مينفعش نلغيه**. الخطة المقترحة هي إضافة طبقة "tokens" جديدة جنبه (مش بدل منه)، وربط الأسماء الحالية (`elementMove`, `elementMoveFast`, ...) بحيث تبقى مجرد "aliases" لقيم الـ tokens الجديدة — توحيد بدون كسر. التفاصيل في القسم 2.
- Ambxst فيه تقنيات حركة/تأثيرات باهظة فعلاً على مستوى GPU/CPU (شيدرز مخصصة لتلوين الـ wallpaper حسب الـ palette، حقن شيدر GLSL حي في mpv للفيديو wallpapers، نافذة بار مقصوصة بـ mask أكبر من محتواها الفعلي عشان تسمح بحركة auto-hide من غير قص). كلها قابلة للتحويل لخيارات مقفولة خلف `PerformanceProfiles` بدل ما تتفرض. التفاصيل في القسم 3.
- Horizons-DE عنده أصلاً نصف حل لمكوّن زي `AnimLoader` (وهو `FadeLoader.qml`) لكن بيعمل fade على `opacity` بس من غير تبديل `sourceComponent` بمنتصف الحركة — فيه فجوة حقيقية هنا. التفاصيل في القسم 4.
- فيه صفحة "Motion" موجودة فعلاً في `InterfaceConfig.qml` (نمط الحركة + سرعة الحركة) — الأنسب توسيعها بدل عمل صفحة جديدة منفصلة، مع إضافة قائمة تفعيل/تعطيل فردي لكل تقنية "ثقيلة". التفاصيل في القسم 5.

---

## 1. تحليل نظام Anim tokens بتاع caelestia بالتفصيل

### 1.1 الـ 14 نوع (enum) وتصنيفهم

الملف `G:\dotfiles\caelestia-shell\components\Anim.qml` (ده `NumberAnimation` بسيط بيعرّف enum QML عادي — **مش C++**):

```qml
enum Type {
    StandardSmall = 0, Standard, StandardLarge, StandardExtraLarge,      // 0-3
    EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge,  // 4-7
    FastSpatial, DefaultSpatial, SlowSpatial,                            // 8-10
    FastEffects, DefaultEffects, SlowEffects                             // 11-13
}
```

بيتقسّموا فعليًا لـ 3 عائلات:

| المجموعة | الأعضاء | فكرة الاستخدام |
|---|---|---|
| **Standard × 4 أحجام** | Small/Normal/Large/ExtraLarge | حركة "غير معبّرة" (non-overshoot)، مدتها بتفرق حسب حجم العنصر المتحرك (كل ما العنصر أكبر مساحة على الشاشة كل ما احتاج وقت أطول ليبان سلس) |
| **Emphasized × 4 أحجام** | نفس الـ 4 أحجام لكن بمنحنى Material 3 "emphasized" (فيه overshoot خفيف) | نفس الفكرة بس لعناصر "مهمة" بصريًا (انتقال رئيسي مش تفصيلة ثانوية) |
| **Spatial (Fast/Default/Slow)** | حركة عناصر بتتحرك مكانيًا (position/size/transform) | مدتها وcurve منفصلين تمامًا (350/500/650ms) — مش مبنية على "الحجم" زي الفوق |
| **Effects (Fast/Default/Slow)** | حركة خصائص بصرية بحتة (opacity, color, blur) | (150/200/300ms) — أسرع بكتير من الـ Spatial لأنها مش بتحرك حاجة في الفراغ |

### 1.2 حساب الـ duration (من `Anim.qml`)

```
لو type بين 0 و 13:
  لو type من مجموعة Spatial/Effects (8-13): يرجع duration مخصص لكل واحد فيهم
    (Tokens.anim.durations.expressiveFastSpatial ... expressiveSlowEffects)
  غير كده (0-7, يعني Standard/Emphasized):
    idx = type % 4   // بيرجع نفس الـ [small, normal, large, extraLarge] لكل من Standard وEmphasized
    يرجع Tokens.anim.durations[types[idx]]
```

يعني: الـ 4 أحجام في Standard و4 أحجام في Emphasized بيشتركوا في **نفس جدول الـ duration** (small=200, normal=400, large=600, extraLarge=1000 — القيم الافتراضية من `AnimDurationTokens` في `tokens.hpp`)، والفرق الوحيد بينهم هو الـ **easing curve** مش الـ duration.

### 1.3 حساب الـ easing

```
لو type من Spatial/Effects (8-13): كل واحد ليه curve منفصل تمامًا (6 قيم = cubic bezier واحد)
لو type من Emphasized (4-7): يرجع curve "emphasized" الموحّد (12 قيمة = bezier spline من segmentين)
غير كده (Standard 0-3): يرجع curve "standard" الموحّد (6 قيم)
```

### 1.4 القيم الافتراضية الخام (من `tokens.hpp`)

```
AnimCurves (كل curve = مصفوفة نقاط بيزييه):
  emphasized:               [0.05,0, 2/15,0.06, 1/6,0.4, 5/24,0.82, 0.25,1, 1,1]   (segmentين)
  emphasizedAccel:          [0.3,0, 0.8,0.15, 1,1]
  emphasizedDecel:          [0.05,0.7, 0.1,1, 1,1]
  standard:                 [0.2,0, 0,1, 1,1]
  standardAccel:            [0.3,0, 1,1, 1,1]
  standardDecel:            [0,0, 0,1, 1,1]
  expressiveFastSpatial:    [0.42,1.67, 0.21,0.9, 1,1]
  expressiveDefaultSpatial: [0.38,1.21, 0.22,1, 1,1]
  expressiveSlowSpatial:    [0.39,1.29, 0.35,0.98, 1,1]
  expressiveFastEffects:    [0.31,0.94, 0.34,1, 1,1]
  expressiveDefaultEffects: [0.34,0.8, 0.34,1, 1,1]
  expressiveSlowEffects:    [0.34,0.88, 0.34,1, 1,1]

AnimDurationTokens (بالميللي ثانية، قبل الضرب في scale):
  small=200, normal=400, large=600, extraLarge=1000
  expressiveFastSpatial=350, expressiveDefaultSpatial=500, expressiveSlowSpatial=650
  expressiveFastEffects=150, expressiveDefaultEffects=200, expressiveSlowEffects=300
```

كل الأرقام دي بتتضرب بـ `scale` (`CONFIG_GLOBAL_PROPERTY`) — أي إعداد عام واحد بيكبّر/يصغّر كل الحركة في الشل مرة واحدة، بنفس فكرة `motionDurationScale` الموجودة أصلاً في Horizons-DE.

### 1.5 هل الـ C++ ضروري؟ لأ — والسبب بالتفصيل

الكلاسات في `anim.cpp`/`anim.hpp` و`appearanceconfig.cpp`/`.hpp` بتعمل حاجتين بس:

1. **بناء `QEasingCurve` من مصفوفة الأرقام** عبر `QEasingCurve::addCubicBezierSegment()` — لكن ده **بالظبط** نفس اللي بيحصل تلقائيًا في QML لما تكتب:
   ```qml
   easing.type: Easing.BezierSpline
   easing.bezierCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
   ```
   يعني الـ C++ مش بيضيف قدرة QML مالهاش، هو بس بيحسبها مسبقًا كـ `QEasingCurve` object بدل ما يسيبها للـ QML engine يحسبها. زيادة أداء نظرية ضئيلة جدًا (مرة واحدة لكل تغيير قيمة)، مش سبب معماري.

2. **ضرب الـ duration الأساسي في `scale` وعمل `NOTIFY` عند التغيير** — ده بالظبط اللي بتعمله `motionDuration()` function وخاصية `motionDurationScale` الموجودين فعلاً في `Appearance.qml` النهارده (`Math.round(baseDuration * motionDurationScale)`).

3. **تخزين القيم الافتراضية كـ config قابل لإعادة التحميل من JSON حي (hot-reload)** — ده بالظبط اللي بيوفره `Config.qml` عندنا فعلاً عبر `JsonObject`/`JsonAdapter` (Quickshell's own)، ونفس آلية الـ `Behavior`/reactive بايندنج شغالة تمامًا بنفس الطريقة على `QtObject` عادي.

**الخلاصة**: نظام الـ tokens بتاع caelestia (شكل الـ enum، منطق حساب duration/easing، تقسيم Standard/Emphasized/Spatial/Effects) قابل للنقل **حرفيًا بلا أي تنازل وظيفي** كـ QML خالص في Horizons-DE، معتمدين على:
- `Appearance.qml` كمكان تخزين الـ tokens (بدل C++ `Tokens` singleton).
- QML's native `enum` declaration جوه أي نوع (`NumberAnimation { enum Type {...} }`) — بالظبط زي `Anim.qml` نفسه، مفيش أي حاجة C++-only هنا.
- `Config.qml` (JsonObject) كمكان تخزين أي إعدادات المستخدم عايز يعدّل فيها control points (اختياري، مش أولوية).

**ملاحظة جانبية مهمة**: caelestia بيستخدم C++ plugin أصلاً لأسباب تانية غير الـ anim (validation، exposing config كنوع QML مُصرّف، أداء الوصول للـ config في مسارات ساخنة جدًا زي الألوان) — مش خصيصًا عشان نظام الحركة. فمفيش داعي نستورد التعقيد ده كله عشان نستفيد بس من فكرة الـ Anim tokens.

### 1.6 مكونات مساعدة تانية شفناها في caelestia (تستحق تتبنى بنفس المنطق)

- `AnchorAnim.qml`: نفس فكرة `Anim` بس بيرث من `AnchorAnimation` بدل `NumberAnimation` (لتحريك anchors)، وعنده مجموعة فرعية أصغر (11 قيمة، من غير Effects triad لأن anchors مالهاش معنى "effect").
- `CAnim.qml`: `ColorAnimation` بسيطة جدًا، مربوطة دايمًا على `expressiveSlowEffects` (مفيهاش enum اختيار — قرار تصميمي إنهم مش محتاجين تنويع في سرعة تغيير الألوان).
- استخدام فعلي حقيقي (من الـ grep على `modules/` و`components/`): أكتر نوع مستخدم هو `DefaultEffects` (بيظهر في أكتر من 20 مكان — أزرار، مؤشرات، شريط تمرير، حقول نص)، يليه `FastSpatial` (تفاعلات hover/press سريعة)، وبعدين `StandardLarge`/`SlowEffects` للحركات الأكبر (صور الغلاف، صناديق الحوار).

---

## 2. خطة توحيد تدريجي — Anim tokens جنب `Appearance.animation.*` الحالي

### 2.1 الوضع الحالي في Horizons-DE (لازم يفضل شغال)

في `G:\End4-PXpC\shell\modules\common\Appearance.qml`:

- `animationCurves` (QtObject): بيعرّف فعليًا **جزء من** نفس منظومة caelestia:
  - `expressiveFastSpatial` / `expressiveDefaultSpatial` / `expressiveSlowSpatial` — موجودين، وحتى فيهم **تفريع إضافي** caelestia معندهاش: بيتغيروا حسب `motionStyle` (`smooth` بيدّي curve غير-overshoot، `expressive` بيدّي نفس أرقام caelestia الأصلية بالظبط `[0.42,1.67,...]`).
  - `expressiveEffects` — موجود **نوع واحد بس** (مش fast/default/slow زي caelestia)، مربوط بمدة 200ms ثابتة.
  - `emphasized`, `emphasizedAccel`, `emphasizedDecel`, `standard`, `standardAccel`, `standardDecel` — موجودين بنفس القيم **بالظبط** زي caelestia (نفس أرقام Material 3).
  - **الفجوة**: مفيش `expressiveFastEffects`/`expressiveSlowEffects` منفصلين، ومفيش تقسيم Standard/Emphasized × Small/Normal/Large/ExtraLarge (الـ 8 حالات الأولى في enum caelestia) — الـ duration بتاعهم (200/400/600/1000) مش موجود كـ tokens منفصلة، كل حاجة بتتعرّف كـ "اسم استخدام" (`elementMove`, `elementMoveSmall`, ...) بدل "حجم عام".

- `animation` (QtObject): ده الطبقة اللي **كل الشل بيستخدمها فعليًا** — كل عنصر فيها (`elementMove`, `elementMoveSmall`, `elementMoveEnter`, `elementMoveExit`, `elementMoveFast`, `elementResize`, `clickBounce`, `scroll`, `menuDecel`, `sidebarSlideEnter`, `sidebarSlideExit`) عبارة عن حزمة `{duration, type, bezierCurve, velocity, numberAnimation Component, [colorAnimation Component]}` جاهزة للاستخدام بنمط:
  ```qml
  Behavior on opacity {
      animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
  }
  ```
  هذا النمط مستخدم في **419 مكان عبر 130 ملف** (تأكدنا بالـ grep) — من `Revealer.qml`, `FadeLoader.qml`, `StyledSwitch.qml` (الـ Behavior on color)، `NotificationItem.qml`، `Workspaces.qml` (17 استخدام في ملف واحد) وغيرهم.

- `Config.qml` عنده بالفعل `appearance.motion.style` (smooth|expressive) و`appearance.motion.durationScale` (0.5–2.0)، وده اللي `Appearance.motionStyle`/`motionDurationScale`/`motionDuration()` بيقرأوا منه.

### 2.2 المشكلة اللي التوحيد بيحلها

- الأسماء الحالية (`elementMove`, `elementMoveFast`, ...) أسماء **استخدام** (use-case names) مش أسماء **حجم/نوع عام** — كل مطوّر جديد عايز يضيف حركة جديدة بيضطر إما (أ) يستخدم اسم موجود مش مناسب تمامًا، أو (ب) يضيف اسم جديد في `Appearance.animation` (زي ما حصل فعلًا — 10 أسماء دلوقتي، وهيزيدوا مع الوقت).
- فيه تسرّب فعلي لقيم مش موحّدة: `StyledSwitch.qml` (اللي قرأناه) بيستخدم `NumberAnimation` **يدوي بالكامل** بقيم `duration: 320`/`160` وbezier `[0.42, 1.5, 0.28, 0.95, 1, 1]` مش موجودة في `Appearance.animationCurves` أصلًا — يعني فيه انحراف عن النظام المركزي حتى دلوقتي.
- مفيش تصنيف "Spatial vs Effects" ولا "Small/Normal/Large/ExtraLarge" بشكل عام قابل لإعادة الاستخدام بره الأسماء المخصصة.

### 2.3 الخطة: طبقة جديدة "جنب" مش "بدل"

**الخطوة 1 — إضافة `Appearance.motionTokens` (QtObject جديد تمامًا، بدون لمس أي حاجة موجودة):**

```qml
motionTokens: QtObject {
    readonly property QtObject durations: QtObject {
        readonly property int small: root.motionDuration(200)
        readonly property int normal: root.motionDuration(400)
        readonly property int large: root.motionDuration(600)
        readonly property int extraLarge: root.motionDuration(1000)
        readonly property int fastSpatial: animationCurves.expressiveFastSpatialDuration
        readonly property int defaultSpatial: animationCurves.expressiveDefaultSpatialDuration
        readonly property int slowSpatial: animationCurves.expressiveSlowSpatialDuration
        readonly property int fastEffects: root.motionDuration(150)   // جديد — كان ناقص
        readonly property int defaultEffects: animationCurves.expressiveEffectsDuration
        readonly property int slowEffects: root.motionDuration(300)  // جديد — كان ناقص
    }
    // curves: إعادة استخدام animationCurves الموجودة زي ما هي + إضافة fastEffects/slowEffects
    // الناقصين فقط (نفس منطق caelestia: interpolate خطي بسيط بين fast/default أو تثبيت
    // نفس منحنى default مبدئيًا لحد ما نحتاج تمايز فعلي).
}
```

**الخطوة 2 — إنشاء مكوّن `MotionAnim.qml` (نظير `Anim.qml`) في `shell/modules/common/`:**

```qml
// MotionAnim.qml — NumberAnimation بيقرأ من Appearance.motionTokens
NumberAnimation {
    enum Type {
        StandardSmall, Standard, StandardLarge, StandardExtraLarge,
        EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge,
        FastSpatial, DefaultSpatial, SlowSpatial,
        FastEffects, DefaultEffects, SlowEffects
    }
    property int type: MotionAnim.DefaultSpatial
    duration: /* نفس منطق caelestia بالظبط، يقرأ من Appearance.motionTokens.durations */
    easing:   /* نفس منطق caelestia، يقرأ من Appearance.animationCurves + الإضافتين الجديدتين */
}
```
+ نظائر: `MotionColorAnim.qml` (~`CAnim`)، `MotionAnchorAnim.qml` (~`AnchorAnim`) اختياريين حسب الحاجة الفعلية.

**الخطوة 3 — ربط الأسماء القديمة كـ "مرايا" لقيم الـ tokens الجديدة (مش تغيير سلوكها):**

مثال — بدل ما تفضل `elementMoveFast` قيمة مستقلة، تتحول (داخليًا بس، من غير ما حد يحس بفرق) لمرجع مباشر:
```qml
property QtObject elementMoveFast: QtObject {
    property int duration: motionTokens.durations.defaultEffects   // كانت animationCurves.expressiveEffectsDuration — نفس الرقم بالظبط
    property list<real> bezierCurve: animationCurves.expressiveEffects
    // باقي الخصائص زي ما هي (numberAnimation, colorAnimation Components)
}
```
كل الـ 130 ملف يفضلوا شغالين **بدون أي تعديل فيهم** لأن الواجهة (`Appearance.animation.elementMoveFast.numberAnimation.createObject(this)`) متغيرتش، بس القيمة بقت مصدرها موحّد.

**الخطوة 4 — تصحيح الانحرافات الموجودة (اختياري، فرصة تنظيف لاحقة مش شرط الآن):**
- `StyledSwitch.qml` بيستخدم bezier يدوي (`[0.42, 1.5, 0.28, 0.95, 1, 1]`, duration 320/160) مش من النظام المركزي — تحديد فرصة migration مستقبلية لربطه بـ `MotionAnim.type: MotionAnim.EmphasizedSmall` أو حجم مشابه بعد قياس الفرق البصري.

**الخطوة 5 — قاعدة للكود الجديد فقط (مش إجباري على القديم):**
أي widget/feature جديدة من الآن فصاعدًا **الأفضلية** لاستخدام `MotionAnim { type: MotionAnim.FastSpatial }` مباشرة بدل إضافة اسم جديد في `Appearance.animation`. الأسماء القديمة تفضل كما هي لحاجات الاستخدام العام المتكرر جدًا (زي `elementMoveFast` اللي بقى معياري في المشروع) لكن مش لازم تتوسع أكتر.

**لا يوجد migration إجباري** لـ 130 الملف — التوافق (backward-compat) كامل من اليوم الأول لأن الخطوة 3 بترجع نفس القيم بالظبط.

---

## 3. تقنيات الأنيميشن "الثقيلة" — الكتالوج والخطة الاختيارية

### 3.1 من Ambxst

| # | التقنية | الوصف التقني | التكلفة المتوقعة | مستوى الربط المقترح |
|---|---|---|---|---|
| 1 | **بار "أكبر من محتواه" + `mask: Region`** (`Bar.qml`: `implicitHeight: orientation === "horizontal" ? 200 : Screen.height` + `mask: Region { item: barContent.barHitbox }`) | الـ `PanelWindow` بيتعمله حجز مساحة تصادفية أكبر بكتير من البار الفعلي (200px بدل ~40-50px)، وبعدين الـ hit region الحقيقي بس هو اللي بيتحدد بالـ mask، بحيث حركة الـ `Translate` (slide في/بره) للـ auto-hide متتقصّش عند حواف نافذة الـ layer-shell. | **منخفضة-متوسطة GPU/VRAM**: سطح compositor إضافي دائم (طول الشاشة الرأسي أو 200px أفقي) لكل شاشة، حتى لو مش ظاهر بصريًا — تكلفة ذاكرة/تركيب مستمرة صغيرة لكل شاشة متصلة، مش تكلفة "لحظة الحركة" بس. | **Balanced فما فوق** (تكلفتها منخفضة نسبيًا وتحل مشكلة قص حقيقية) — تعطيلها في Max Performance ترجع البار لسلوك "قص عادي بدون فراغ إضافي" (تراجع بسيط في نعومة الـ auto-hide، مقبول). |
| 2 | **حقن شيدر GLSL حي في mpv لتلوين الفيديو wallpaper** (`Wallpaper.qml` + `MpvShaderGenerator.js` + IPC عبر socket لـ mpvpaper) | بيتولّد شيدر GLSL مخصص فيه الـ 26 لون الحالية من الـ Material palette، يتكتب على القرص، ويتبعت لعملية mpv الشغالة حية عبر IPC socket (`glsl-shaders` property) — كل تغيير ثيم بيعمل إعادة توليد وكتابة وإرسال (مع debounce 500ms). | **مرتفعة CPU (عملية mpv خارجية شغالة باستمرار بتفك فيديو) + GPU (باص شيدر إضافي كل فريم) + I/O**. ده أساسًا نوع مختلف تمامًا من التكلفة عن صورة ثابتة. | **Experience/Max Experience فقط** — لازم يبقى مقفول تمامًا في Max Performance/Performance (فيديو wallpaper أصلًا حاجة اختيارية، والشيدر الحي فوقه طبقة تكلفة إضافية لازم تتفصل عنه كـ toggle منفصل). |
| 3 | **باص شيدر ثنائي لتلوين wallpaper ثابت حسب الـ palette** (`palette.frag`/`.vert` + `ShaderEffectSource` لالتقاط "نسيج palette" 26×1 بكسل + شيدر fragment بيعمل Gaussian-weighted remap لكل بكسل) | كل بكسل في الصورة بيتقاس ضد أقرب لون في الـ palette (حتى 128 عيّنة لكل بكسل نظريًا) عبر حلقة `for` في الشيدر، وبيتكرر كل ما الـ layer يتعلّم "dirty" (تغيير wallpaper أو ثيم). | **متوسطة GPU** — مش مستمرة كل فريم لو الـ layer `enabled` بس مربوط بحالة ثابتة (تينت on/off)، لكن كل إعادة حساب أثقل من `MultiEffect` عادي. | **Experience فما فوق** — البديل الأبسط (بدون تينت شيدر، صورة عادية) يفضل الافتراضي لباقي المستويات. |
| 4 | **Unified two-pass blur+shadow+mask shader** (`UnifiedPanelEffect.qml` + `pass1`/`pass2` `.frag.qsb`) | بديل مخصص لـ `MultiEffect` القياسي، باصين شيدر (أفقي بعدين رأسي) بيعملوا blur + dilation + شادو + قناع، مع خيار `liveUpdate` (يتحسب كل فريم أثناء الحركة، أو يتحسب مرة واحدة ويتخزن كنسيج). | **متوسطة-مرتفعة GPU لو `liveUpdate: true`** (بيتحسب كل فريم أثناء أي حركة تكبير/تصغير/تحريك للوحة)، **منخفضة لو `false`** (نسيج مخبوز). | **Experience فما فوق للوضع `liveUpdate: true`**؛ الوضع الثابت (`liveUpdate: false`) يقدر يبقى متاح من Balanced كبديل أرخص لـ `MultiEffect` العادي بتاع Qt. |
| 5 | **حركة انتقال wallpaper بالـ scale+opacity** (`transitionAnimation` في `Wallpaper.qml`: `ParallelAnimation` بتكبّر لـ 1.01 وتقلّل الشفافية لـ 0.5 بعدين ترجع) | بسيطة نسبيًا (NumberAnimation عادية على scale/opacity) — مش شيدر، لكن بتتحرك فوق صورة كاملة الشاشة فبتكلفتها تعتمد على حجم الصورة نفسها في الذاكرة. | **منخفضة** | **متاحة من Balanced** — تكلفتها زهيدة قياسًا بالتقنيات التانية. |

### 3.2 من caelestia (للمقارنة — أنيميشن "معقّد" مش بالضرورة "ثقيل" على الهاردوير)

| # | التقنية | الوصف | التكلفة | ملاحظة |
|---|---|---|---|---|
| 6 | **`AnimatedLogo.qml`**: حركة شعار افتتاحية مركّبة (rotation overshoot 0→750→710→725→720°، scale bounce بـ `OutBack`، `MultiEffect` blur-out أثناء الظهور، 3 نجوم بتظهر متتابعة كل واحدة بتاعمل loop لانهائي `y`+`scale`) | ~500 سطر من `SequentialAnimation`/`ParallelAnimation` منسّقة يدويًا، ملهاش علاقة بنظام الـ Anim tokens إطلاقًا (كل القيم hardcoded محليًا في نفس الملف) | **منخفضة-متوسطة أثناء الافتتاح فقط** (باص `MultiEffect` blur لمدة ~1 ثانية)، **منخفضة مستمرة بعدها** (6 `NumberAnimation` لانهائية بسيطة بدون شيدر) | التكلفة المستمرة (infinite loops) بعد انتهاء الافتتاح صغيرة لكنها **مش صفر** — كل حركة `Animation.Infinite` هي evaluation دوري دائم حتى لو العنصر مش متغير بصريًا بشكل ملحوظ، وده بيهم بالذات على اللابتوبات (منع الجهاز من الدخول في idle كامل). يستاهل يتحط تحت toggle مستقل حتى لو تكلفته منخفضة. |
| 7 | **Spring/overshoot accents** (`NotchAnimationBehavior.qml`: `scale`/`opacity` بـ `Easing.OutBack`/`overshoot: 1.2`؛ و`NotificationAnimation.qml`: تفكيك مع `leftMargin`+`scale`+`opacity` بـ`OutBack`/`overshoot: 1.1`) | آلية QML مختلفة تمامًا عن bezier curves (`easing.overshoot` property مش قابلة للتعبير كـ bezier عادي) | **منخفضة جدًا** (NumberAnimation عادية، بدون شيدر) | ده بالأساس **بُعد ذوق (taste)** مش بُعد أداء — الأنسب ربطه بـ `motion.style`/خيار "spring accents" منفصل عن أي performance gate، مش بـ Performance Profiles. |

### 3.3 من Ax-Shell (نقطة مقارنة، مش للاستيراد المباشر)

- نموذج CSS واحد بسيط: `transition: all 0.25s cubic-bezier(0.175, 0.885, 0.32, 1.275);` معاد استخدامه حرفيًا في 20+ مكان عبر `styles/*.css` (bar, buttons, controls, dock, launcher, notch, player, power, tools, wallpapers)، مع استثناءات قليلة لسرعة أهدأ (`0.1s ease` في dashboard/metrics/overview لعناصر بتتحدّث بشكل مستمر زي المقاييس الحيّة).
- هذا هو الحد الأدنى المطلق لمنظومة حركة: منحنى واحد، سرعة واحدة تقريبًا، `transition: all` (بيراقب كل خاصية CSS اتغيرت، حتى لو مقصودش تتحرك — ضريبة أداء بسيطة على محرك GTK CSS نفسه، تافهة قياسًا بالشيدرز، لكنها موجودة).
- **الفايدة الوحيدة من المقارنة دي لـ Horizons-DE**: تأكيد إن "كل عنصر تفاعلي لازم يكون عنده transition افتراضي ولو بسيط" هو معيار حتى في أبسط الأنظمة — ده أصلًا محقق في Horizons-DE عبر النظام الحالي (`Appearance.animation.*`) وأغنى منه بكتير.

### 3.4 مبدأ الربط بـ Performance Profiles (بدل نظام موازٍ)

إضافة مفاتيح جديدة تحت `appearance.motion.heavy.*` في `Config.qml`، وتوسيع خرائط `config` في `PerformanceProfiles.qml` (نفس الأسلوب المتّبع فعلاً مع `background.widgets.*`):

```
appearance.motion.heavy.wallpaperShaderTint          (تقنية #2 + #3)  -> false: maxPerformance/performance/balanced | true: experience/maxExperience
appearance.motion.heavy.unifiedShaderPanelEffect      (تقنية #4، liveUpdate)  -> false حتى balanced | true: experience+
appearance.motion.heavy.oversizedAutoHideSurface      (تقنية #1)       -> false: maxPerformance فقط | true: performance فما فوق (تكلفتها منخفضة)
appearance.motion.heavy.introFlourishes               (تقنية #6، شعارات/سبلاش متحركة)  -> false: maxPerformance | true: الباقي
appearance.motion.style.springAccents                 (تقنية #7، overshoot bounce)      -> بُعد ذوق منفصل، افتراضيًا مربوط بـ motion.style === "expressive"
```

كل مفتاح فيهم لازم يبقى **قابل للتخصيص الفردي بعد اختيار أي profile** (بالظبط زي ما `background.widgets.clock.enable` وأخواتها شغالين دلوقتي — الـ profile بيحط قيمة افتراضية، والمستخدم يقدر يقلبها تاني من غير ما الـ profile selector "يقاومه"). هذا يحقق مباشرة مطلب "الشمولية + قابلية التخصيص الكاملة" المذكور في خلفية المهمة.

---

## 4. خطة مكوّن على غرار `AnimLoader`

### 4.1 الفجوة الحالية

`G:\End4-PXpC\shell\modules\common\widgets\FadeLoader.qml` (موجود فعلًا):
```qml
Loader {
    property bool shown: true
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
```
ده بيعمل **إظهار/إخفاء** (show/hide) بس — مش **تبديل محتوى** (content swap). لو غيّرت `sourceComponent` بتاعه وهو ظاهر، هيحصل قطع فوري بلا أي انتقال، لأن مفيش تسلسل "فيد آوت → تبديل → فيد إن" زي `AnimLoader.qml` بتاع caelestia:

```qml
// caelestia AnimLoader.qml — الفكرة الأساسية
SequentialAnimation {
    Anim { target: root; property: "opacity"; to: 0; type: root.outAnimType }
    ScriptAction { script: root.sourceComponent = root.sourceComp }
    Anim { target: root; property: "opacity"; to: 1; type: root.inAnimType }
}
```

### 4.2 التصميم المقترح لـ Horizons-DE

مكوّن جديد (اسم مقترح لتفادي تعارض مع `FadeLoader` الموجود): `shell/modules/common/widgets/SwapLoader.qml` أو `MotionLoader.qml`:

- **واجهة الاستخدام**: نفس فلسفة caelestia — `property Component sourceComp` (بدل `sourceComponent` المباشر)، و`SequentialAnimation` داخلية تعمل فيد آوت → `ScriptAction` لتبديل `sourceComponent` → فيد إن.
- **مصدر القيم**: بدل `type: Anim.FastEffects/DefaultEffects` المباشر بتاع caelestia، يقرأ من نفس طبقة `MotionAnim`/`Appearance.motionTokens` المقترحة في القسم 2 (أو من `Appearance.animation.elementMoveFast`/`elementMoveEnter` الموجودين فعلًا لو مفيش داعي لانتظار الـ tokens الجديدة) — بحيث الـ `outAnimType`/`inAnimType` قابلين للتخصيص من الخارج زي caelestia بالظبط.
- **التوافق مع Max Performance / "تقليل الحركة"**: لما `motionDurationScale` يوصل لحد معيّن قريب من الصفر (أو نضيف فلاغ صريح `appearance.motion.reduceMotion` مستقبلًا)، الأنسب إن الحركة تتقلّص لمدة شبه-فورية تلقائيًا (بما إن كل الـ durations بتتضرب في `motionDurationScale` أصلًا) من غير ما كل استخدام لـ `SwapLoader` يحتاج يتحقق يدويًا من الـ profile — بمعنى: الحل موجود بالفعل بمجرد ربط الـ durations بشكل صحيح، مفيش حاجة إضافية مطلوبة هنا.
- **علاقته بـ `FadeLoader` الموجود**: يفضل `FadeLoader` زي ما هو لحالة الإظهار/الإخفاء البسيطة (استخدامه منتشر بالفعل)؛ `SwapLoader` الجديد يغطي حالة استخدام مختلفة ومفقودة فعلًا (تبديل محتوى صفحة إعدادات، تبديل widget خلفية، تبديل تبويب) بدل ما كل مكان يحتاجها يعمل تسلسل `SequentialAnimation` يدوي بنفسه من الصفر (زي ما حصل بالضبط في `Ambxst`'s `Wallpaper.qml` — `transitionAnimation` مكتوبة يدويًا محليًا).

---

## 5. إعدادات Settings UI المطلوبة

### 5.1 الوضع الحالي

`shell/modules/ii/settings/pages/InterfaceConfig.qml` عنده بالفعل قسم **"Motion"** (`ContentSubsection { title: Translation.tr("Motion") }`):
- `ConfigSelectionArray` لـ "Animation style" (Smooth/Expressive) → `Config.options.appearance.motion.style`.
- Slider لـ "Animation speed" (50%–200%) → `Config.options.appearance.motion.durationScale`.

و`ExperienceConfig.qml` عنده مفتاح مختصر مكرر لنفس المفهوم ("Expressive motion" switch) بيكتب لنفس `appearance.motion.style` — لا يوجد تعارض (نفس المفتاح، واجهتين مختلفتين لمستخدمين مختلفين: صفحة كاملة مقابل صفحة تجربة سريعة)، فقط للتوثيق.

### 5.2 الإضافات المقترحة

**أ. توسيع قسم "Motion" الموجود في `InterfaceConfig.qml`** بدل إنشاء صفحة منفصلة (تجنبًا لتكاثر صفحات الإعدادات):
- إضافة `GroupedList` جديدة تحت نفس الـ `ContentSubsection` أو subsection فرعية "Motion effects" فيها `ConfigSwitch` واحد لكل مفتاح من مفاتيح `appearance.motion.heavy.*` المقترحة في القسم 3.4:
  - "تلوين شيدر حي للـ wallpaper الفيديو/الثابت حسب الألوان" (`wallpaperShaderTint`)
  - "تأثير شيدر ظل/ضبابية مخصص للوحات (بدل التأثير القياسي)" (`unifiedShaderPanelEffect`)
  - "سطح بار موسّع للإخفاء التلقائي السلس (VRAM إضافية بسيطة)" (`oversizedAutoHideSurface`)
  - "حركات افتتاحية/خمول (شعار متحرك، بريق نجوم)" (`introFlourishes`)
  - "لمسات ارتداد/spring في الظهور (Notch، الإشعارات)" (spring accents، مرتبط بـ`motion.style` لكن قابل للفصل)
- كل صف يحتاج شارة تكلفة بسيطة (نص أو أيقونة) موازية لنفس منهجية تعليق `PerformanceProfiles.qml` نفسه (الضبابية أولًا كأكبر تكلفة GPU موثقة، بعدين الظلال، بعدين الحركة، بعدين الودجات الخلفية) — يعني رتّب القائمة بنفس الترتيب: شيدرز > سطح موسّع > حركات افتتاحية > لمسات ارتداد.
- كل switch لازم يقرأ/يكتب مباشرة من/لـ `Config.options.appearance.motion.heavy.*` المقترح إضافته لـ `Config.qml`، وده يفضل شغال بشكل مستقل عن أي profile مُختار حاليًا (بنفس نمط `background.widgets.*` الموجود فعلًا) — لا حاجة لآلية جديدة، فقط تمديد النمط الموجود.

**ب. ملاحظة صريحة على التقنيات غير المطبَّقة بعد**: التقنيات #2/#3/#4 (شيدرز wallpaper وshiedr اللوحات الموحّد) **غير موجودة فعليًا في Horizons-DE اليوم** — أي مفتاح Settings ليها لازم يُشحن كـ "قريبًا/يتطلب PR منفصل" أو يُؤجَّل بالكامل لحد ما الميزة الأساسية (الشيدر نفسه) تتبنى فعليًا في كود منفصل عن هذه المهمة. هذا التقرير بحثي/تخطيطي فقط ولا ينشئ أي كود.

**ج. لا حاجة لصفحة Settings منفصلة لطبقة الـ tokens الداخلية (القسم 1-2)** — دي إعادة هيكلة داخلية شفافة للمستخدم النهائي، مفيهاش أي إعداد جديد يحتاج واجهة (القيم اللي المستخدم شايفها فعلاً هي بالظبط "Animation style" و"Animation speed" الموجودين بالفعل).

---

## 6. ملخص الملفات المرجعية

- **caelestia-shell**: `components/Anim.qml`, `components/AnchorAnim.qml`, `components/CAnim.qml`, `components/AnimLoader.qml`, `plugin/src/Caelestia/Config/{anim,appearanceconfig,tokens}.{hpp,cpp}`, `modules/nexus/common/AnimatedLogo.qml`.
- **Ambxst**: `modules/bar/{Bar,BarContent}.qml`, `modules/notch/NotchAnimationBehavior.qml`, `modules/notifications/NotificationAnimation.qml`, `config/defaults/theme.js`, `modules/widgets/dashboard/wallpapers/{Wallpaper.qml,palette.frag,MpvShaderGenerator.js}`, `modules/components/UnifiedPanelEffect.qml`.
- **Ax-Shell**: `main.css`, `styles/*.css`.
- **Horizons-DE**: `shell/modules/common/Appearance.qml`, `shell/modules/common/PerformanceProfiles.qml`, `shell/modules/common/Config.qml` (حوالي السطر 297 لـ `appearance.motion`، والسطر 343+ لـ `hyprland.animations`)، أمثلة استخدام: `shell/modules/common/widgets/{Revealer,FadeLoader,StyledSwitch,NotificationItem}.qml`, `shell/modules/ii/bar/Workspaces.qml`, وصفحة الإعدادات `shell/modules/ii/settings/pages/{InterfaceConfig,ExperienceConfig}.qml`.

---

# 3. فورك axctl المحلي — خطة التكامل والتطوير

**تاريخ:** 2026-09-05
**نطاق المهمة:** بحث وتخطيط فقط — لا تعديل كود، لا git operations. المصادر: axctl الفعلي (`G:\dotfiles\axctl`)، تكامل Ambxst معه (`G:\dotfiles\Ambxst`)، وكود Horizons-DE الحالي (`G:\End4-PXpC`).

**اكتشاف حاسم قبل أي حاجة تانية:** axctl مرخّص بـ **GNU AGPL-3.0** (`G:\dotfiles\axctl\LICENSE`، هيدر واضح "GNU Affero General Public License, Version 3"). هذا يغيّر كل حسابات "الفورك المحلي" — تفاصيل كاملة في القسم 2 والقسم 6. كمان: **Horizons-DE نفسه مفيهوش ملف LICENSE على الإطلاق** حاليًا (`G:\End4-PXpC` — لا `LICENSE`، لا `LICENSE.md`، ولا أي ذكر ترخيص في `README.md`)، يعني قرار الترخيص لسه معلَّق أصلاً حتى قبل ما نفكر في axctl.

---

## 1. تحليل axctl معماريًا

### 1.1 البنية العامة (packages)

```
axctl/
├── main.go                  # CLI entrypoint + daemon bootstrap (عند الـ ROOT، غير قياسي — موثّق كده في AGENTS.md بتاعته نفسه)
├── pkg/
│   ├── ipc/
│   │   ├── interface.go     # الـ Compositor interface (العقد الموحّد)
│   │   ├── types.go         # Window/Workspace/Monitor/Capabilities/Layout/Event
│   │   ├── config.go        # ConfigUniversal + Keybind + AmbxstKeybinds (تفصيل في 2.3)
│   │   ├── config_unmarshal.go, cache.go, colors.go, errors.go
│   │   ├── hyprland/        # Hyprland adapter (راو socket + Lua dispatch)
│   │   ├── niri/            # Niri adapter (JSON IPC عبر $NIRI_SOCKET)
│   │   ├── mango/           # Mango adapter (dwl-ipc، /run/user/$UID/mango.sock)
│   │   ├── mock/            # Mock compositor لل tests (call tracking + error injection)
│   │   └── wayland/         # Wayland client bindings يدوية + generated protocol code
│   │       ├── client/                     # display/registry/event dispatch يدوي
│   │       ├── ext_idle_notify_v1/         # بروتوكول idle الرسمي (agnostic تمامًا عن الـ compositor)
│   │       ├── foreign_toplevel_v1/        # wlr-foreign-toplevel (wlroots compositors)
│   │       └── idle_inhibit_v1/            # idle inhibit الرسمي
│   ├── config/               # TOML loader/watcher/apply (axctl.toml)
│   └── server/                # JSON-RPC server + state cache + idle/brightness/darkmode
```

**نقطة مهمة غير موثّقة بوضوح في الـ README:** جزء كبير من `pkg/server` (idle.go، brightness.go، darkmode.go) **مش خاص بأي compositor خالص** — دي helpers عامة لأي جلسة Wayland/Linux (brightnessctl/ddcutil، gsettings/dconf color-scheme، Wayland idle-notify/idle-inhibit الرسمي). يعني axctl فعليًا أكبر من "IPC موحّد للـ compositor" — هو داشبورد أوامر نظام عام حط جواه كمان طبقة compositor-abstraction.

### 1.2 الـ compositors المدعومة **فعليًا في الكود** (مش بس المُعلنة)

تأكدت بالـ grep المباشر على كل الشجرة: **صفر إشارة لـ i3 أو sway في axctl بالكامل** (لا كود، لا تعليق، لا اسم ملف). المدعوم فعليًا:

| Compositor | الملف | آلية الاتصال |
|---|---|---|
| Hyprland | `pkg/ipc/hyprland/client.go` | raw Unix socket خاص بـ hyprctl (`$XDG_RUNTIME_DIR/hypr/$SIG/.socket.sock` للأوامر، `.socket2.sock` للأحداث) — **مش hyprctl subprocess**، اتصال مباشر بالبروتوكول |
| Niri | `pkg/ipc/niri/client.go` | JSON IPC عبر `$NIRI_SOCKET` |
| Mango | `pkg/ipc/mango/client.go` + `dwlipc/dwl_ipc.go` | بروتوكول dwl-ipc، `/run/user/$UID/mango.sock` |

هذا يتطابق تمامًا مع اللي كان مكتوب في `docs/dots-integration-audit.md` السابق — بس بتأكيد مباشر من الكود دلوقتي، مش بس من الـ README.

### 1.3 شكل الـ JSON-RPC protocol بالضبط

**النقل (transport):** JSON مفصول بأسطر (line-delimited) فوق Unix domain socket دائم في `/tmp/axctl-$UID.sock` (قابل للتجاوز عبر `AXCTL_SOCKET` env). ملحوظة: المسار في `/tmp` وليس `$XDG_RUNTIME_DIR` — عزل بسيط عبر الـ UID في اسم الملف، لكن مفيش أي مصادقة إضافية على مستوى التطبيق.

**الطلب (كل سطر):**
```json
{"id": 1, "method": "Window.Focus", "params": {"id": "0xabc123"}}
```
`method` دايمًا بصيغة `Category.Action` (Window/Workspace/Monitor/Layout/Config/System/Darkmode/Brightness)، وكل الأفعال متسردة صراحة في `main.go` (`handleRPC`) للـ CLI، وفي `server.go` (`handleConnection`) لل daemon — تطابق يدوي بين الاتنين، **مفيش أي كود توليد آلي (schema/reflection) بيربطهم**، يعني إضافة method جديدة تتطلب تعديل مكانين منفصلين يدويًا.

**الرد:**
```json
{"id": 1, "result": "ok", "error": ""}
```
`result` بيرجع `"ok"` كـ sentinel string لما مفيش نتيجة حقيقية (مش `null` أو `true`)، والـ CLI (`main.go`) بيتعامل معاها كحالة خاصة ("Success" بدل طبع الـ JSON خام). أي `id` فاضي في الـ params بيتحل تلقائيًا لـ "النافذة النشطة حاليًا" عبر `resolveID()` — سلوك ضمني موحّد عبر كل الـ Window.* methods.

**قناة الأحداث (subscribe):** نفس نوع الاتصال بالظبط — عميل بيبعت `System.Subscribe` وبعدها بيستقبل على **نفس الـ connection** إشعارات JSON-RPC 2.0 بصيغة مختلفة شكليًا:
```json
{"jsonrpc":"2.0","method":"Event.WindowFocused","params":{...},"state":{"windows":[...],"workspaces":[...],"monitors":[...]}}
```
كل إشعار بيحمل **State Dump كامل** (مش diff) — أبسط للعميل، أثقل على الشبكة/الـ socket لو عدد النوافذ كبير. الـ CLI's `axctl subscribe` بيفتح اتصال منفصل مخصص لهذا الغرض فقط، وبيفلتر أي سطر مالوش `"jsonrpc":"2.0"` (يعني بيرفض ردود الطلبات العادية لو غلط واتخلطوا في نفس الاتصال).

**تزامن:** كل اتصال بيتعامل معاه بحلقة قراءة/تنفيذ/كتابة متسلسلة تمامًا (لا pipelining) — طلب واحد في المرة على نفس الاتصال، لكن السيرفر بيعمل `go s.handleConnection(conn)` لكل اتصال جديد، يعني اتصالات متعددة متوازية مسموحة.

### 1.4 دورة حياة الـ socket (lifecycle)

1. `axctl daemon` بيكتشف الـ compositor بترتيب صارم: Hyprland env var أولاً → Niri → Mango (أول نجاح بيكسب، مفيش أولوية قابلة للتهيئة).
2. **حماية instance واحد:** بيحاول `Dial` على الـ socket القديم أولاً — لو نجح، يطبع "already running" ويخرج؛ لو فشل، بيمسح أي ملف socket قديم (stale) ويعمل `Listen` من جديد. فيه نافذة سباق ضيقة (race) نظريًا بين لحظة فشل الـ Dial ولحظة الـ Listen لو داعمَين اتشغّلوا في نفس اللحظة بالظبط.
3. **مفيش systemd socket-activation ولا auto-restart ولا health-check** — الاعتماد كامل على العملية الأم (الشل أو أي مشرف) إنها تخلي الداعم شغال. Ambxst بالذات بتحل ده عبر مشرف عمليات خاص بيها هي (تفصيل في القسم 3 تحت).
4. عند `SIGINT`/`SIGTERM` بس بيتنضف الـ socket file (`os.Remove`). أي kill قسري (SIGKILL/crash) بيسيب socket "stale" لازم يتكتشف ويتنضف في المرة الجاية.

### 1.5 توليد ملفات الإعداد (hyprland.lua/.conf)

axctl عنده **مولّدين متوازيين** لـ Hyprland: `generator.go` (صيغة hyprlang الكلاسيكية `.conf`) و `generator_lua.go` (صيغة Lua الأحدث اللي Hyprland أضافها، `hl.config({...})`). الاختيار بينهم **مش تلقائي بناءً على نسخة Hyprland الفعلية المكتشفة** (رغم إن `client.go` عنده فعليًا فحص نسخة `supportsLuaDispatchers()` يستخدمه للـ *dispatch* الحي) — الاختيار بيتحدد بس من امتداد مسار الإخراج اللي المستخدم حدده (`.conf` أو `.lua`) عبر `[target]` في التوml أو المسار الافتراضي. يعني ممكن نظريًا تولّد ملف `.lua` لـ Hyprland قديم مايفهموش، من غير أي تحذير.

التدفق الكامل: التوml (`~/.config/axctl/config.toml` أو `-c <path>`) بيتحمّل → `fsnotify` watcher بيراقبه هو وأي ملفات `include` → عند أي تغيير، `config.ApplyConfig()` بيعمل حاجتين في نفس اللحظة: (أ) dispatch حي فوري للـ compositor الشغال (`keyword`/`eval hl.config(...)` لـ Hyprland، أوامر مكافئة لـ Niri/Mango)، و(ب) إعادة توليد الملف الثابت (`.conf`/`.lua`) من نفس الـ `ConfigUniversal`. المسار الافتراضي لو مفيش `[target]`: `~/.config/hypr/axctl.generated.{conf,lua}` — **إلا في حالة compositor غير معروف** حيث الافتراضي يرجع لمسار Ambxst الصريح (تفصيل قسم 2.3).

---

## 2. خطة الفورك المحلي

### 2.1 المسار المقترح

`G:\End4-PXpC\tools\axctl\` — مجلد `tools/` جديد على نفس مستوى `shell/`, `dotfiles/`, `i3/`, `install/`, `docs/` الحاليين. **السبب:** axctl بيبني binary مستقل (Go daemon) مالوش أي علاقة بشجرة QML — حطه جوه `shell/` (اللي هو جذر إعدادات Quickshell) ممكن يعرّض محرّك QML لفحص/تحميل شجرة Go ضخمة بلا داعي، وبيكسر الفصل النظيف بين "إعداد الشل" و"أداة مستقلة مبنية من المصدر" اللي installer.sh أصلاً بيميّز بينهم (`DO_SHELL` مقابل `DO_BUILD`).

### 2.2 فورك حقيقي (git history) مقابل إعادة كتابة نظيفة مستوحاة

**الخيار أ — فورك حقيقي بالتاريخ (`git subtree add` أو `git remote add` + `git subtree split`):**
- **الميزة:** يحافظ على تاريخ/نسبة المساهمين (مهم لالتزام AGPL — إثبات "الكود المصدري الكامل مع أي تعديلات" أسهل لما يكون كل شيء، بالتاريخ، جوه نفس الـ repo). تحديثات المصدر مستقبلًا (`git subtree pull`) سهلة. يحترم روح الفورك مفتوح المصدر.
- **العيب:** بيجيب تاريخ git كامل تاني (commits/blobs) جوه repo شل QML — حجم الـ repo هيزيد، و`git log` هيبان فيه commits من مساهمين axctl مالهاش علاقة بمشروع Horizons-DE، وده ممكن يربّك أي حد بيتصفح تاريخ الـ repo مستقبلًا.

**الخيار ب — إعادة كتابة نظيفة "مستوحاة من الفكرة" (بلا نسخ كود axctl فعليًا):**
- **الميزة:** حرية ترخيص كاملة (تقدر تختار أي ترخيص لـ Horizons-DE بالكامل بلا التزام AGPL)، مفيش تتبّع upstream.
- **العيب:** بترمي مئات الساعات من كود مُختبر وشغال فعليًا (dual-dispatch Hyprland حسب النسخة، بروتوكول dwl-ipc الخاص بـ Mango، Wayland idle-notify bindings يدوية) — لازم تتعاد كتابتها واختبارها من الصفر. مجهود ضخم غير متناسب مع هدف "إضافة دعم i3 لأداة موجودة".

**التوصية:** بناءً على طلب المستخدم الصريح ("فورك محلي... مع نفس الريبو... نعدل عليه")، **الخيار أ هو المقصود فعليًا**. لكن لازم القرار يترافق بوعي كامل: أي binary مبني من `tools/axctl/` هيفضل **مرخّص AGPL-3.0** بغض النظر عن أي ترخيص يختاره Horizons-DE لباقي الـ repo (AGPL كود لا يتغيّر ترخيصه بمجرد نقله لمكان تاني). التوصية العملية: يتعامل مع `tools/axctl/` كوحدة مرخّصة بشكل منفصل وواضح (تحتفظ بملف `LICENSE` بتاعها الأصلي كامل زي ما هو، عدم دمج كودها مباشرة جوه binary الشل نفسه لو كان الشل ناوي يبقى بترخيص مختلف) — بالظبط زي ما `DO_BUILD` بيعامل بناء Quickshell نفسه كخطوة بناء منفصلة من مصدر خارجي، مش كأنه "ملك" Horizons-DE بالكامل.

**تحذير ترخيص إضافي (القسم 13 من AGPL):** لو الـ daemon المفروك هيتوزّع أو يُستخدم كخدمة شبكية (حتى لو Unix socket محلي بس بين عمليتين على نفس الجهاز — الأثر القانوني للـ AGPL بيغطي أي "تفاعل عن بُعد عبر شبكة" وممكن يُفسَّر بشكل واسع)، لازم يكون فيه وسيلة واضحة يوصل بيها أي مستخدم لكود المصدر الكامل المعدَّل — امتلاك فورك حقيقي بالتاريخ (الخيار أ) فعليًا **بيسهّل** الالتزام ده (المصدر كله موجود شفاف جوه نفس الـ repo العام)، وده سبب إضافي يرجّح الخيار أ لو القرار النهائي هو المضي في axctl أصلاً.

### 2.3 تعديلات فورية لازمة (اقتران axctl بـ Ambxst المكتشف في الكود نفسه)

بالـ grep المباشر على كامل شجرة axctl لكلمة "ambxst" (case-insensitive)، ظهر اقتران حقيقي على **مستويين مختلفين**، مش بس في التوثيق:

1. **مستوى المسارات (سهل التعديل):**
   - `pkg/server/paths.go`: `legacyHyprlandPath()` و `DefaultOutputPath()` بيرجّعوا حرفيًا `~/.local/share/ambxst/hyprland.conf` كمسار احتياطي افتراضي (مستخدم لما الـ compositor نوعه مش معروف).
   - `pkg/config/loader.go`: `DefaultConfigPath()` بيرجع لـ `~/.local/share/ambxst/axctl.toml` لو `$XDG_CONFIG_HOME/axctl/config.toml` مش موجود.
   - **التعديل:** إعادة تسمية بسيطة لمسار محايد (`~/.local/share/horizons/...` أو الاعتماد الكامل على `-c`/`[target]` بلا احتياطي مسمّى بمشروع تاني أصلاً).

2. **مستوى الـ schema (تعديل أعمق، كسر توافقي):**
   - `pkg/ipc/config.go`: النوع `AmbxstKeybinds` (بحرفه الكبير) وحقل `ConfigKeybinds.Ambxst` بمفتاح JSON حرفي `"ambxst"` — ده مش تسمية عشوائية، هو **جزء من الـ schema الرسمي** لملف التوml/JSON نفسه.
   - **الثلاث مولّدات كلهم** (`hyprland/generator.go`, `hyprland/generator_lua.go`, `mango/generator.go`, `niri/generator.go`) بيفحصوا `config.Ambxst.System`/`.Binds` صراحة عشان يسموا الـ binds المولّدة (`"Ambxst System: X"`, `"Ambxst: X"`).
   - **التعديل:** تغيير اسم المفتاح لحاجة محايدة (`"shell"` أو `"horizons"`) في `config.go` + كل المولّدات الأربعة + كل ملفات الاختبار اللي بتتأكد على النص القديم حرفيًا (`generator_lua_test.go`, `niri/generator_test.go` بيحتووا على تعليقات وأسرت تشاور على "ambxst" صراحة) — **هذا تغيير كاسر (breaking) على مستوى صيغة ملف الإعداد**، لازم يترافق بتحديث كل الاختبارات المتأثرة وإلا `go test ./...` (أمر التطوير الرسمي المذكور في README) هيفشل فورًا بعد الفورك.

**ملحوظة إيجابية:** باقي axctl (الـ `Compositor` interface، النقل عبر JSON-RPC، منطق النوافذ/المساحات/الشاشات) **compositor-generic بالكامل ومفيهوش أي اقتران بـ Ambxst** — التعديلات المطلوبة محصورة في النقطتين فوق بس.

---

## 3. خطة دمج compositor: هل axctl يدعم i3؟

**الإجابة: لأ، صفر دعم i3/sway في axctl حاليًا** (تأكيد مباشر بالـ grep، مش استنتاج من التوثيق). خطة إضافة backend لـ i3:

### 3.1 التصميم المقترح: `pkg/ipc/i3/client.go`

بيطبّق نفس `ipc.Compositor` interface. **الميزة الكبرى هنا:** منطق i3 IPC **جاهز ومُختبر فعليًا وشغال في الإنتاج** داخل `G:\End4-PXpC\shell\services\I3Backend.qml` الحالي — الشغلانة أساسًا "نقل" (port) من QML/JS لـ Go، مش "اختراع" من الصفر زي ما كان لازم يحصل مع Hyprland/Niri وقت ما اتعمِلوا:

| وظيفة axctl (`ipc.Compositor`) | مصدر المنطق الجاهز في `I3Backend.qml` | رسالة i3 IPC |
|---|---|---|
| `ListWindows`/`ActiveWindow` | `collectWindows()` + `normalizeWindow()` (تراجع شجري recursive) | `GET_TREE` (type 4) |
| `ListWorkspaces`/`ActiveWorkspace` | الـ mapping في `getWorkspaces` Process | `GET_WORKSPACES` (type 1) |
| `ListMonitors` | الـ mapping في `getOutputs` Process | `GET_OUTPUTS` (type 3) |
| `FocusWindow`/`CloseWindow`/`MoveWindow`/`SwitchWorkspace`/... | `runI3()` — بناء نص أمر i3 (`[con_id=X] focus`, `workspace "Y"`, ...) | `RUN_COMMAND` (type 0) |
| `Subscribe` | `eventStream` Process (`i3-msg -t subscribe -m [...]`) | `SUBSCRIBE` (type 2) |

- **اكتشاف الـ socket:** نفس منطق `I3SOCK`/`WINDOWMANAGER` الموجود فعلاً في `WM.qml.detectCompositor()` — إعادة استخدام مباشرة للمعرفة، مش بحث جديد.
- **فرصة تحسين حقيقية أثناء النقل:** axctl عنده نموذج state-cache بيفرّق الأحداث (`cache.AddWindow`/`RemoveWindow`/`MarkWindowFocused`) بدل إعادة جلب كل الشجرة (`GET_TREE`) عند أي حدث — وده **أفضل من** السلوك الحالي في `I3Backend.qml` اللي بيعمل debounce (80ms) ثم إعادة جلب **الكل** (`updateAll()`) عند أي حدث بلا تمييز نوعه. تفكيك أحداث i3 (`"window::new"`, `"window::close"`, `"window::focus"`, `"window::title"` — كلهم تحت نوع event واحد اسمه `"window"` في بروتوكول i3، بخلاف Hyprland اللي بيبعت سطر منفصل لكل نوع) محتاج منطق ترجمة جديد مش موجود في أي مكان حاليًا — ده الجزء الوحيد اللي مش "نقل مباشر" فعليًا.
- **ما لا ينطبق على i3 (يرجع `ErrNotSupported`):** `GetConfig`/`SetConfig`/`ReloadConfig`/`GetAnimations`/layer rules/blur/shadow — i3 مالوش بروتوكول إعداد حي على الإطلاق (نفس الخلاصة اللي وصلها `docs/i3-quickshell-research.md` قسم 3: التأثيرات دي محتاجة picom خارجي بالكامل، خارج نطاق أي IPC).
- **`idle.go` تحتاج انتباه خاص:** الـ `IdleManager` الحالي في axctl مبني بالكامل على بروتوكولات Wayland (`ext_idle_notify_v1`, `idle_inhibit_v1`) — دي **مش موجودة أصلاً على X11/i3**. إضافة i3 backend لازم يترافق بمسار بديل لميزات الـ idle (منطقيًا: XScreenSaver X11 extension، أو `logind`/D-Bus idle inhibitors) وإلا كل أوامر `System.Idle*`/`System.Inhibit*` هترجع خطأ فوري تحت i3 — مش مجرد "غير مدعوم برسالة واضحة"، محتاج فحص إضافي.
- **حجم المجهود المتوقع:** مقارب لحجم `niri/client.go` أو `mango/client.go` الحاليين (~500-700 سطر تقديريًا) — إضافة متوسطة الحجم قابلة للتنفيذ فعليًا، مش مشروع بحثي مفتوح.
- **اختبار:** نفس نمط `pkg/ipc/mock/compositor.go` (call tracking + error injection) المستخدم بالفعل لكل backend تاني — بنية اختبار جاهزة، مفيش حاجة جديدة تتبنى.

### 3.2 بديل/منافس جزئي يستاهل الأخذ في الاعتبار: `Quickshell.I3`

بحسب `docs/i3-quickshell-research.md` (قسم 2.2)، **Quickshell نفسه عنده موديول رسمي `Quickshell.I3`** بيوفّر `I3.dispatch()` عبر socket دائم واحد + `I3.workspaces`/`I3.monitors` observable — **بلا أي Go daemon خالص**. الموديول **مبيغطيش شجرة النوافذ** (مفيش `I3Window`)، فمش بديل كامل لـ `get_tree`، لكنه بديل مباشر وأخف بكتير لجزء "الـ workspaces/monitors + إرسال أوامر بلا spawn عملية جديدة في كل مرة" اللي هو جزء كبير من الدافع وراء axctl أصلاً. **التوصية:** ما يمنعش المضي في إضافة i3 backend لـ axctl (فايدة إعادة الاستخدام خارج Quickshell نفسه لسه قائمة)، لكن أي خطة تكامل QML قصيرة المدى (قسم 4) ينفع تستفيد من `Quickshell.I3` كخطوة أرخص وأسرع أولاً، مستقلة تمامًا عن axctl.

---

## 4. خطة تكامل QML جانب Horizons-DE (تدريجي، بلا لمس الكود الشغال)

### المبادئ الأساسية
- axctl **لا يكون أبدًا اعتماد إجباري**: `WM.qml` لازم يشتغل بالظبط زي دلوقتي لو الداعم مش شغال (الواقع الحالي فعلاً: axctl مش مثبّت بواسطة `installer.sh` أصلاً، فالغياب هو المسار الافتراضي الوحيد إلا لو المستخدم فعّله صراحة).
- **بلا استبدال فجائي:** الـ backends الحالية (`HyprlandBackend`, `NiriBackend`, `I3Backend`, `NullBackend`) المُنشأة عبر `switch` في `WM.createBackend()` (`G:\End4-PXpC\shell\services\WM.qml` سطر 81-94) **تفضل كما هي بلا أي تعديل**.

### الخطوة المقترحة: `AxctlBackend.qml` كخيار إضافي، مش بديل

- مكوّن جديد `AxctlBackend.qml` بنفس السطح البرمجي الدقيق لكل backend حالي (`windowList`, `workspaces`, `workspaceById`, `activeWorkspace`, `monitors`, `focusedMonitor`, `focusWindow()`, `closeWindow()`, `switchWorkspace()`, `moveWindowToWorkspace()`, `monitorFor()`, `activeWorkspaceForMonitor()`, `biggestWindowForWorkspace()`, `fullscreenOnMonitor()`, `monitorGeometry()`). لأن `WM.qml` بيتعامل مع الـ backend بالكامل عبر `backend?.X` (سطر 97-112)، **طبقة الـ proxy دي محتاجة صفر تعديل** — أكبر ضمان أمان في الخطة كلها: الواجهة العامة اللي باقي الشل بيعتمد عليها مبتتغيرش.
- **آلية الاختيار الآمنة:** عند بدء التشغيل، لو فلاج تفعيل صريح مفعّل (مقترح: `Config.wm.useAxctl`، افتراضيًا `false`)، يتم فحص غير-حاجب (non-blocking) لاتصال بـ `/tmp/axctl-$UID.sock` (أو `$AXCTL_SOCKET`) بـ timeout قصير عبر `Quickshell.Io.Socket`. لو الاتصال نجح، يتنشأ `AxctlBackend` بدل الـ backend الأصلي؛ لو فشل/انتهت المهلة، يتنشأ الـ backend الأصلي **بالظبط زي اليوم**. هذا النمط **مش مخترع** — منسوخ حرفيًا من نمط `probeTimer`/`socketAvailable` الموجود فعلاً وشغال في `Ambxst/modules/services/BackendService.qml`.
- **شبكة أمان وقت التشغيل:** لو الـ socket سقط في نص الجلسة (الداعم اتقفل/كراش)، `AxctlBackend` لازم يبعت إشارة يسمعها `WM.qml` ويرجع فورًا لإنشاء الـ backend الأصلي حيًا (نفس منطق `createBackend()` بدون فرع axctl). هذا سلوك **جديد كليًا** (الـ backends الحالية بتتنشأ مرة واحدة بس في `Component.onCompleted` ومبتتبدلش أبدًا) — محتاج اختبار خاص ومنفصل، لكنه إضافي وما بيلمسش ملفات i3/Hyprland/Niri الحالية إطلاقًا.

### ترتيب تنفيذ تدريجي مقترح (كل خطوة قابلة للتراجع بمفردها)

1. **فورك axctl وبناؤه فقط** — بلا أي تعديل QML. يتحقق من قصة الأداة/التبعية بمعزل تام، الداعم مش موصول بالشل خالص، صفر خطورة على أي جلسة شغالة.
2. **إضافة `AxctlBackend.qml`** لكن `Config.wm.useAxctl` مقفول على `false` (فلاج تطوير غير موثّق للمستخدم العادي) — يسمح للمطورين يجربوا يدويًا مقابل جلسة Hyprland/i3 حقيقية بلا أي أثر على أي مستخدم فعلي.
3. **بعد استقرار مثبت من الخطوة 2**، التفكير في تفعيل افتراضي **لكل compositor على حدة** (مثلًا Hyprland الأول لأن dispatch Lua بتاع axctl أكتر نضجًا، مع إبقاء i3 على `I3Backend.qml` الأصلي لحد ما يكون فيه i3 backend مُختبر فعليًا في axctl — قسم 3).
4. **`HyprlandData.qml`, `I3Backend.qml`, `hyprconfigurator.py` تفضل بلا لمس طول المسار ده بالكامل** — هما شبكة الأمان لكل خطوة فوق؛ مفيش في الخطة دي أي بند بيطلب حذفهم أو إعادة كتابتهم.

### خارج النطاق عمدًا في هذه الدفعة: استبدال `hyprconfigurator.py`

`hyprconfigurator.py` عنده ميزة **مالهاش مكافئ في axctl حاليًا**: فحص حي (`option_is_supported()` عبر `hyprctl -j getoption`) قبل توليد أي مفتاح إعداد، عشان يتفادى كتابة مفاتيح غير مدعومة على نسخة Hyprland الحالية. مولّدات axctl (`generator.go`/`generator_lua.go`) **بتولّد الإعداد بلا شرط**، بلا أي فحص دعم حي. استبدال `hyprconfigurator.py` بـ `Config.Apply` بتاع axctl دلوقتي هيخاطر بتوليد مفاتيح مش مدعومة صامتة — لازم يتحول لمبادرة منفصلة، مشروطة بإضافة نفس نوع فحص الدعم الحي لمولّدات axctl الأول.

---

## 5. متطلبات بناء جديدة على installer.sh

- **مكوّن اختياري جديد** (`axctl`) يُضاف لقائمة `--components` الحالية (`dots,shell,bundled,build,deps,sysupdate,backup`)، افتراضيًا معطّل (`DO_AXCTL=false`) بنفس فلسفة `DO_BUILD`/`DO_BUNDLED` الحاليين — عشان محدش يتفاجئ بتنزيل Go toolchain على تثبيت موجود.
- **فحص التبعيات** (بلوك `_chk` الموجود حول السطر ~811 من `installer.sh`، مربوط حاليًا بـ `DO_BUILD`): يُضاف بلوك مواز `if [[ "$DO_AXCTL" == true ]]` يفحص `go` (نسخة ≥ 1.25 حسب `go.mod` الأصلي بتاع axctl — الفورك المحلي يقدر يثبّت أي نسخة يقررها الفريق) بنفس نمط `_chk "label" "command"` الحالي بالظبط.
- **خطوة البناء:** دالة جديدة `build_axctl_step()` بنفس شكل `build_quickshell_step()` (سطر 1264 من installer.sh) — `step "..."`، قصر-دائرة عند `DRY_RUN`، تفويض لدالة `hz_build_axctl`/`build_axctl` تتعرّف في ملف `build.sh` (نفس نمط `hz_build_quickshell` الحالي) — بتشغّل `go build -o axctl .` جوه `tools/axctl/` وتحط الـ binary الناتج في نفس مكان الـ binaries المبنية التانية (زي مكان `quickshell` المبني).
- **axctl مش محتاج toolchain الـ C++ خالص:** `go.mod` بتاعه (`fsnotify`, `go-toml/v2`, `golang.org/x/sys`) بلا أي cgo — يعني مش محتاج `g++`/`pkg-config`/`make` المستخدمين حاليًا لبناء Quickshell. ده محور تبعية منفصل تمامًا (Go toolchain مقابل C++ toolchain) ويستاهل فلاج مستقل بدل الدمج جوه `--with-build`.
- **إزالة متسقة:** إضافة `no-axctl`/`^axctl` لنفس نمط تعطيل المكوّنات الموجود (`--components no-dots` مثلًا) عشان توقيف/إزالة الداعم + الـ sockets/config المولّدة بشكل نظيف.
- **خيار أرخص أولي (يستاهل قرار من الفريق):** بما إن axctl upstream بيوزّع binaries جاهزة (`curl -L get.axeni.de/axctl | sh`، مؤكد من `README.md`/`install.sh` بتاعته)، ممكن أول دفعة (`DO_AXCTL`) تكتفي بتنزيل/تحقق binary محدد (pinned release) بدل فرض Go toolchain من الأساس، وتأجيل "نبني الفورك بتاعنا من المصدر" لحد ما الفورك فعليًا يختلف عن upstream بشكل مهم (زي ما لما يتم دمج i3 backend أو إعادة تسمية مسارات ambxst). هذا قرار للفريق، مش نتيجة حتمية — بما إن الطلب الصريح كان "فورك محلي... وتعدل عليه"، البناء من الفورك المحلي هو الهدف النهائي على أي حال.

---

## 6. تقييم مخاطر صريح

| الخطر | الشرح | الخطورة |
|---|---|---|
| **الترخيص (AGPL-3.0)** | axctl مرخّص AGPL-3.0 كامل (نص القسم 13 عن "الاستخدام الشبكي" قد يُفسَّر بشكل واسع). Horizons-DE **مفيهوش أي ملف LICENSE حاليًا** — استيراد فورك AGPL بيفرض قرار ترخيص كان لسه مؤجَّل ضمنيًا. أي binary مبني من الفورك يفضل AGPL بغض النظر عن ترخيص باقي الـ repo. | **عالية** — قرار يحتاج توضيح صريح من صاحب المشروع قبل أي التزام تنفيذي |
| **لغة/toolchain تانية جوه مشروع QML** | إضافة Go كمتطلب صيانة مستمر (مش مجهود لمرة واحدة) — أي كسر مستقبلي في Lua API بتاع Hyprland، أو أي quirk جديد لـ compositor، بيبقى الآن مشكلة Go كود، مش QML مألوف لفريق المشروع. | متوسطة-عالية |
| **توقف upstream عن axctl** | axctl مشروع شبه-فردي (Axenide) مصمم أصلًا لخدمة Ambxst بالذات — الدليل: مسارات/مفاتيح schema خاصة بـ Ambxst مبنية جوه axctl نفسه (قسم 2.3)، مش بس في توثيقه. نفس النمط اللي التدقيق السابق لاحظه بالفعل مع Ax-Shell. فورك حقيقي بالتاريخ (خيار أ، قسم 2.2) بيقلّل الخطر ده أكتر من مجرد الاعتماد على upstream. | متوسطة (مخفَّفة جزئيًا لو الفورك حقيقي) |
| **تداخل الـ compositors المدعومة** | axctl يدعم Hyprland/Niri/Mango؛ Horizons-DE يدعم Hyprland/Niri/i3. Mango عبء زائد بلا فائدة لـ Horizons-DE، وi3 (الأكثر احتياجًا للحل) هو بالظبط الناقص — يعني أكبر فايدة محتملة من axctl (i3 backend موحّد) **مش موجودة يوم واحد**، لازم تُبنى (قسم 3). | متوسطة |
| **تعقيد إضافي للمستخدم النهائي** | داعم خلفية ثاني + socket ثاني + صيغة إعداد ثالثة (TOML) قد تتضارب مع ملفات Hyprland Lua/i3 conf المولّدة بالفعل عبر `hyprconfigurator.py`/مزامنة dotfiles الحالية. نظامان بإمكانهما كتابة نفس ملفات `~/.config/hypr/*` يخلق خطر تضارب/كتابة فوق صامتة لو حدود التكامل (القسم 4، "كتابة الإعداد خارج النطاق حاليًا") ما اتحفظش بدقة مع تطور المشروع. | متوسطة |
| **فجوة اختبار/CI** | مجموعة اختبارات axctl (`go test ./...`، ~26 اختبار حسب `AGENTS.md`) مش جزء من أي CI حالي لـ Horizons-DE. إضافة موديول Go يعني إما قبول نقطة تكامل غير مُختبرة ضمن عملية إصدار Horizons-DE، أو استثمار بنية تحتية إضافية (Go في CI) فوق installer.sh لوحده. | منخفضة-متوسطة |

### ملاحظات مخفِّفة (إيجابية) تستحق الذكر

- تجريد `Compositor` interface ونمط الاختبار بالـ mock (`pkg/ipc/mock`) في axctl **مصمَّمين جيدًا فعليًا وقابلين لإعادة الاستخدام مباشرة** — مش تصميم يستاهل رفضه بالكامل.
- إضافة i3 backend لـ axctl **أقل خطورة مما تبدو**: المنطق الصعب (بناء رسائل i3 IPC، تحليل JSON للشجرة/المساحات/الشاشات) **موجود فعلاً، مُختبر، وشغال في الإنتاج** داخل `I3Backend.qml` — هذه عملية "نقل" (port) موثوق، مش "تصميم من الصفر" زي ما كان الحال مع Hyprland/Niri وقت ما اتعملوا لأول مرة.
- خطة التكامل من جانب QML (قسم 4) مصمَّمة بحيث **لا تلمس** `I3Backend.qml`, `HyprlandData.qml`, أو أي كود i3/Wayland شغال حاليًا — كل التعديلات إضافية (additive) وقابلة للتراجع خطوة بخطوة، متسقة مع التوجيه الصريح بالحذر الشديد في أي تعديل يمس i3/Wayland.

---

## المصادر

- `G:\dotfiles\axctl\README.md`, `AGENTS.md`, `LICENSE`, `main.go`, `go.mod`
- `G:\dotfiles\axctl\pkg\ipc\interface.go`, `types.go`, `config.go`
- `G:\dotfiles\axctl\pkg\ipc\hyprland\client.go`, `generator.go`, `generator_lua.go`
- `G:\dotfiles\axctl\pkg\server\server.go`, `paths.go`
- `G:\dotfiles\axctl\pkg\config\types.go`
- `G:\dotfiles\Ambxst\modules\services\AxctlService.qml`, `BackendService.qml`, `CompositorConfig.qml`, `CompositorTomlWriter.qml`
- `G:\dotfiles\Ambxst\backend\pkg\svc\compositor\service.go`, `G:\dotfiles\Ambxst\backend\go.mod`, `flake.nix`, `nix\packages\backend.nix`
- `G:\End4-PXpC\shell\services\WM.qml`, `I3Backend.qml`, `HyprlandData.qml`
- `G:\End4-PXpC\shell\scripts\hyprland\hyprconfigurator.py`
- `G:\End4-PXpC\docs\dots-integration-audit.md`, `docs\i3-quickshell-research.md`
- `G:\End4-PXpC\installer.sh` (أقسام `--components`, `DO_BUILD`, `build_quickshell_step`)

---

# 4. نظام الثيمات والهوية البصرية — خطة الـ Presets

> **المبدأ الحاكم لكل هذا التقرير:** المطلوب مش استبدال نظام M3/matugen بتاع Horizons-DE — ده نظام شغّال، ديناميكي (بيستخرج الألوان من الـ wallpaper)، ومربوط بكل حاجة. المطلوب هو طبقة **Presets** تتحط *فوق* النظام ده: كل preset عبارة عن "نقطة بداية" (starting point) بتضبط مجموعة قيم في `Config.options.appearance.*` (roundness, shadow, glass, transparency, font pairing, وربما بعض الإضافات الجديدة البسيطة) دفعة واحدة، والمستخدم يقدر يعدّل أي قيمة بعد كده عادي زي ما هو حاصل دلوقتي. **الاكتشاف الأهم في البحث ده: Horizons-DE عنده فعليًا نواة preset system شغالة بالفعل** في `ExperienceConfig.qml` (حقل `builtInTheme` + دالة `applyTheme()`) — يعني المطلوب مش نظام جديد من الصفر، لكن **توسعة** لحاجة موجودة وناجحة في فلسفتها.

---

## 0. المصادر اللي اتقرأت (لسهولة الرجوع)

| الملف | الغرض |
|---|---|
| `G:\dotfiles\Ambxst\config\defaults\theme.js` | القيم الافتراضية لكل الـ "sr" surface roles |
| `G:\dotfiles\Ambxst\assets\presets\*\theme.json` (9 ملفات) | الـ presets الجاهزة: Ambxst Default, Caelestiax, Dotsquared, Frutiger Aero, Frutiger Aqua, GNOME, Liquid Glass, Manga, Retro |
| `G:\dotfiles\Ambxst\modules\components\StyledRect.qml` | آلية الرسم الفعلية (Rectangle عادي / ShaderEffect لكل من linear, radial, halftone) |
| `G:\dotfiles\Ambxst\modules\theme\Styling.qml` | دالة `getStyledRectConfig(variant)` اللي بتربط اسم الـ variant بالـ theme role |
| `G:\dotfiles\Ambxst\modules\widgets\dashboard\controls\ThemePanel.qml` | محرر الثيم المباشر (Live editor) داخل الـ dashboard |
| `G:\dotfiles\Ambxst\modules\widgets\presets\{PresetsButton,PresetsPopup,PresetsTab}.qml` | واجهة إدارة الـ presets (بحث/إنشاء/تسمية/تحديث/حذف) |
| `G:\dotfiles\Ambxst\modules\services\PresetsService.qml`, `PresetCommandService.qml` | الخدمة اللي بتنسخ/تحمّل ملفات الكونفيج بتاعة الـ preset |
| `G:\dotfiles\Ambxst\config\Config.qml` (أسطر ~65-131، 3408-3480) | تحميل `theme.json` عبر `FileView`+`JsonAdapter`، وربطها بـ `Config.theme` |
| `G:\dotfiles\caelestia-shell\services\Colours.qml` | نظام الألوان (M3Palette + طبقات شفافية محسوبة ديناميكيًا) |
| `G:\dotfiles\caelestia-shell\plugin\src\Caelestia\Config\appearanceconfig.{hpp,cpp}` | نظام الـ Tokens (C++ **مُصرَّف native**، مش QML خالص) |
| Grep على `Tokens.rounding` / `Tokens.padding` في كل الشل | تأكيد شكل الـ token ladder الكامل |
| `G:\dotfiles\Ax-Shell\config\data.py`, `main.css`, `styles/*.css`, `config/matugen/templates/ax-shell.css` | أبسط نظام: متغيرات CSS من matugen مباشرة، بدون أي طبقة تجريد |
| `G:\End4-PXpC\shell\modules\common\Appearance.qml` (كامل) | "ملف الـ components الأساسي" بتاع Horizons-DE |
| `G:\End4-PXpC\shell\modules\common\Config.qml` (قسم appearance كامل + `applyPerformanceProfile`/`applyVisualEffectExclusivity`) | تخزين الإعدادات + منطق التطبيق دفعة واحدة |
| `G:\End4-PXpC\shell\modules\common\PerformanceProfiles.qml` | **نفس الفلسفة المطلوبة للـ presets، شغالة فعليًا لمحور تاني (الأداء)** |
| `G:\End4-PXpC\shell\modules\ii\settings\pages\QuickConfig.qml` | الواجهة اللي بتطبّق الـ Performance Profiles (نموذج UI جاهز نقلّده) |
| `G:\End4-PXpC\shell\modules\ii\settings\pages\ExperienceConfig.qml` | **preset system مصغّر شغّال بالفعل** (`builtInTheme`: adaptive/midnight/paper/aurora/mono) |
| `G:\End4-PXpC\shell\services\SystemTheming.qml` | إدارة قوالب matugen (تفعيل/تعطيل قالب لكل تطبيق) |
| `G:\End4-PXpC\dotfiles\dots\.config\matugen\` | قوالب matugen الفعلية المستخدمة (gtk, hyprland, kde, fuzzel...) |

---

## 1. جدول المقارنة الكامل — الـ 9 presets بتاعة Ambxst

كل preset في Ambxst هو ملف `theme.json` واحد بيملأ **19 "variant" role** (`srBg`, `srPopup`, `srInternalBg`, `srBarBg`, `srPane`, `srCommon`, `srFocus`, و 3×4 لأزواج primary/secondary/tertiary/error: العادي + Focus + Over) + إعدادات عامة (`roundness`, `font`, `shadow*`, `oledMode`, `lightMode`, `tintIcons`, `animDuration`). كل variant فيه: `gradient` (مصفوفة `[color, position]`)، `gradientType` (`linear`/`radial`/`halftone`)، `gradientAngle`/`gradientCenterX/Y`، خصائص halftone (`halftoneDotMin/Max`, `halftoneStart/End`, ألوان النقط)، `border: [color, width]`، `itemColor` (لون النص/الأيقونة فوق السطح ده)، و`opacity`.

| Preset | الاستدارة (roundness) | الخط | الظل (shadow) | نوع الـ gradient الغالب | halftone؟ | ملاحظات هوية بصرية | ممكن تتحقق بأدوات QML عندنا بدون كود native؟ |
|---|---|---|---|---|---|---|---|
| **Ambxst Default** | 16 | Roboto Condensed / Iosevka Mono | opacity 0.5, blur 1, بدون offset | `linear` بلون واحد (stop واحد = عمليًا لون مصمت) | لا | خط أساس متوازن، بدون أي درجة مبالغ فيها — مرجع للـ "لا preset" | **نعم بالكامل** — لون مصمت + ظل قياسي، ده أصلًا شكل `Appearance.qml` الحالي |
| **Caelestiax** | 16 | Roboto Condensed / Iosevka Mono | blur **0.96** (شبه بلا تغيير) | نفس Default تمامًا (كل الـ gradients لون واحد) | لا | تمثيل لهوية caelestia-shell **داخل** Ambxst: مفيش أي gradient حقيقي أو halftone — الاعتماد الكامل على نظام الألوان المسطّح، مش على تأثيرات بصرية زخرفية | **نعم بالكامل** — هي أصلًا "بدون تأثيرات" تقريبًا |
| **Dotsquared** | **0** (حواف حادة تمامًا) | **Terminus 8px** (bitmap/pixel font) لكل من UI والـ mono | XOffset/YOffset = **1/1**, blur **0** (ظل بكسل حاد بدون نعومة) | `halftone` كثيف على أغلب الأسطح (`halftoneDotMin≈halftoneDotMax≈2` — يعني نقط شبه ثابتة الحجم = نسيج "شبكة نقط" منتظم، مش تدرّج فعلي) | **نعم، أساسي** | هوية "بكسل/تيرمينال منقّط" — أقرب لمحاكاة شل الـ dots (اسم الملف حرفيًا "Dotsquared") | **جزئيًا** — الاستدارة صفر + الخط البكسلي + الظل الحاد كلهم عاديين تمامًا في QML. **نقطة الـ halftone فعليًا محتاجة `ShaderEffect`** (شوف قسم 1.1 تحت) لإنه نسيج procedural مش gradient خطي |
| **Frutiger Aero** | 16 | Roboto Condensed / Iosevka Mono | opacity **0.25** (ناعم جدًا) | `radial` متعدد الـ stops (4 ألوان) بيستخدم container colors (`blueContainer`→`surfaceContainerLowest`→`blueContainer`→`greenContainer`) — تدرّج "سماء/عشب" زجاجي كلاسيكي على طراز Windows Vista Aero | لا | **lightMode: true** — زجاج فاتح شفاف (opacity الأسطح نفسها 0.7-0.9) فوق تدرّج سماء/عشب متعدد الألوان | **نعم للتدرّج نفسه إذا 2 لون بس** (Rectangle gradient خطي عادي)، **لكن Radial متعدد الـ stops (˃2 لون) محتاج ShaderEffect** لأن QtQuick `Rectangle.gradient` لا يدعم radial أصلاً |
| **Frutiger Aqua** | 16 | نفس الأساس | opacity **0** (بلا ظل إطلاقًا — الاعتماد الكامل على لمعان التدرّج) | `linear`/`radial` بـ **5-7 stops بألوان hex ثابتة** (`#99D0FC`, `#0D75BC`, `#1686D1`...) **بدل** أسماء الـ theme roles | لا | تأثير "جل أزرق لامع" (Mac OS X Aqua) — لكن **مش مربوط بالـ M3 palette إطلاقًا**؛ الألوان مكتوبة صراحةً (hardcoded) فمهما غيّر المستخدم الـ wallpaper أو الـ accent color هتفضل زرقاء ثابتة | **التدرّج بحاجة ShaderEffect** (أكتر من 2 stop)، **وكسر التوافق مع matugen مقصود في تصميم الـ preset ده نفسه** — نقطة نحتاج نتجنبها في نسختنا (schema بتاعنا هيجبر استخدام أسماء الـ roles مش hex ثابت) |
| **GNOME** | 14 | Roboto Condensed / **Roboto Mono** (مش Iosevka Nerd Font — GNOME مش محتاج نيرد-فونت لايقونات) | opacity 0.5, blur 1 (قياسي) | `linear` بلون واحد لكل الأسطح، حدود (`border`) شبه معدومة العرض | لا | **الأبسط بصريًا** — ألوان مصمتة مسطّحة، بدون تدرّج أو halftone أو حدود بارزة → طراز Adwaita/GNOME النظيف | **نعم بالكامل 100%** — أسهل preset يتطبّق |
| **Liquid Glass** | 14 | Roboto Condensed / Roboto Mono | opacity 0.5 (قياسي) | `radial` بـ 2 stop بس، لكن الحيلة إن **الـ opacity نفسه منخفض جدًا** (0.2–0.7 حسب السطح) بدل التدرّج نفسه — الشفافية هي الأداة الأساسية للهوية، مش الألوان | لا | زجاج "مطفي/frosted" حديث (iOS/visionOS-style): سطوح شبه شفافة بتدي إحساس عمق، بدون تعقيد لوني | **نعم بالكامل تقريبًا** — تدرّج بسيط 2-stop شغال بـ `Rectangle.gradient` العادي، والشفافية أصلًا موجودة كمفهوم كامل في `Config.options.appearance.glass` عندنا |
| **Manga** | **0** | **Terminus 8px** | opacity 1, blur **0**, حدود عرض 1 على كل سطح | `halftone` حقيقي (نقط screentone) على معظم الأسطح الأساسية (Bg/Popup/Common/Focus/Pane) بألوان متباينة (أبيض/أسود) | **نعم، أساسي** | هوية "كوميك/مانجا": حواف حادة + حدود سوداء صريحة + نقط halftone تحاكي طباعة screentone الكوميك، `lightMode` و`oledMode` معًا (تباين عالي) | **جزئيًا** — نفس ملاحظة Dotsquared: الاستدارة صفر + الحدود السوداء عاديين، لكن الـ halftone الحقيقي (نقط متغيّرة الحجم) محتاج `ShaderEffect` |
| **Retro** | **0** | **Terminus 8px** | XOffset/YOffset = 1/1, blur 0 | مزيج: `halftone` كثيف على Background/Bar/Common، لكن `linear` عادي على primary/secondary/tertiary | نعم (جزئي) | هوية "تيرمينال 8-bit/CRT قديم": نفس روح Dotsquared لكن أخف (halftone على الخلفيات فقط، مش كل الأسطح) | **جزئيًا** — نفس القيد: الأجزاء الـ linear سهلة، الـ halftone محتاج shader |

### 1.1 خلاصة تقنية: هل الـ gradient/halftone محتاج كود native؟

أهم اكتشاف تقني في `G:\dotfiles\Ambxst\modules\components\StyledRect.qml`:

- **لون واحد (single-stop gradient)** → بيتحول لـ `color:` عادي على الـ `Rectangle` (`ClippingRectangle` تحديدًا) — **صفر تكلفة، صفر كود إضافي**.
- **`linear` أو `radial` بـ 2 لون فقط** → ممكن تتعمل بـ `Rectangle.gradient: Gradient { GradientStop {...} }` العادي بتاع QtQuick **لكن فقط للـ linear** (QtQuick's built-in gradient لا يدعم radial ولا angle مخصص ولا أكتر من نمط "top-to-bottom" بسيط فعليًا حسب orientation).
- **`linear`/`radial` بأكتر من 2 stop، أو بزاوية مخصّصة، أو radial بمركز مُزاح** → Ambxst بيستخدم **`ShaderEffect` مع شادرات `.qsb` مُصرَّفة مسبقًا** (`linear_gradient.vert/frag.qsb`, `radial_gradient.vert/frag.qsb`). ده جزء من QML/Quickshell القياسي (مافيش C++ ولا build system خارجي) — بس بيحتاج **كتابة GLSL وتصريفه بأداة `qsb`** (خطوة إضافية عن `.qml` عادي، لكنها لسه "QML tooling" مش "native code" بمعنى compiled binary/plugin).
- **`halftone`** (نقط متغيّرة الحجم كنسيج) → **دايمًا محتاج `ShaderEffect`**. مفيش طريقة تعمل نسيج نقط procedural بـ `Rectangle` عادي أو `MultiEffect`/`Qt5Compat.GraphicalEffects` الجاهزة.
- **الظل (`shadow*`)** → بيتعمل بمكوّن `Shadow {}` مخصص (على الأرجح `MultiEffect`/`DropShadow` من `Qt5Compat.GraphicalEffects` أو `QtQuick.Effects` — نفس المكتبات المتاحة أصلًا في Horizons-DE، شفنا استخدامها فعليًا في `QuickConfig.qml` نفسه: `import Qt5Compat.GraphicalEffects`).

**الخلاصة للقرار المعماري:** أي preset فيه فقط (roundness + font + shadow + transparency/glass + لون مصمت أو تدرّج 2-لون) **قابل للتنفيذ فورًا بأدوات Horizons-DE الحالية بدون أي كود جديد غير QML عادي**. أي preset فيه halftone أو gradient معقّد (>2 stops/radial بزاوية) **يحتاج مكوّن `ShaderEffect` جديد** — ده لسه QML بحت (زي `MultiEffect` أو الـ blur shaders اللي Hyprland نفسه بيستخدمها compositor-side)، لكنه مجهود إضافي حقيقي مش مجرد ضبط قيم. **القرار المقترح: نبدأ بالـ presets اللي محتاجة القسم الأول بس (وهو أغلبها)، ونأجّل الـ halftone الحقيقي كـ "Phase 2 / تحسين اختياري"**.

---

## 2. أنظمة المقارنة الأخرى (باختصار مركّز)

### 2.1 caelestia-shell — نظام Tokens (⚠️ C++ مُصرَّف، مش قابل للنقل حرفيًا)

من `appearanceconfig.hpp` (كلاسات C++ حقيقية مسجّلة كـ QML types عبر module `Caelestia.Config` — plugin مُصرَّف بالكامل، مش QML):

- **فلسفة "scale واحد فوق سلّم ثابت"**: `AppearanceRounding`/`AppearanceSpacing`/`AppearancePadding` كل واحد فيه خاصية `scale` وحيدة (افتراضي 1) بتتضرب في سلّم قيم ثابت داخليًا (`extraSmall/small/medium/large/largeIncreased/extraLarge/extraLargeIncreased/extraExtraLarge/full`). يعني preset الاستدارة بالكامل = رقم واحد بس (`scale: 0.7` مثلاً يخلي كل الاستدارات في الشل أصغر بنفس النسبة).
- `AppearanceFont`: نفس المبدأ (`scale` عام) + لكل نمط خط (headline/title/body/label/mono/icon) عائلة/حجم/وزن/**`vaxes`** — وده حاجة لافتة: `vaxes: {"ROND": 25}` بيستخدم **variable font axis اسمه "ROND"** (Google Sans Flex وخطوط مشابهة بتدعم محور "Roundness" داخل الخط نفسه!) — يعني استدارة الحروف نفسها (مش بس الصناديق) بتتغيّر حسب الخط. ملاحظة: Horizons-DE أصلًا بيستخدم "Google Sans Flex" ومعرّف `variableAxes` في `Appearance.qml` (`font.variableAxes.main = {"wght":450,"wdth":100}`) — يبقى **البنية التحتية لدعم محور "ROND" موجودة بالفعل ومجرد إضافة مفتاح جديد**.
- `AppearanceTransparency`: `enabled` + `base` + `layers` — نفس مفهوم `Config.options.appearance.transparency` عندنا حرفيًا لكن بأسماء أبسط.
- `deformScale`: مضاعِف لدرجة "تشوّه/liquid" الأشكال (مربوط غالبًا بأنيميشن الـ blob/morph بتاع caelestia) — مش عندنا حاليًا مكافئ مباشر.
- **Colours.qml**: نظام ألوان "مسطّح" (M3Palette + `alterColour()`/`layer()` بتحسب شفافية الطبقات ديناميكيًا من لون واحد أساسي) — أبسط بكتير من نظام الـ 19-variant-per-surface بتاع Ambxst، وأقرب فلسفيًا لنظام `Appearance.qml.colors` عندنا (layer0-4 مشتقة من base واحد).

**القرار:** فلسفة الـ "scale واحد فوق سلّم" **قابلة للنقل بالكامل لـ QML بحت** (مجرد خاصية `real` واحدة بتتضرب في أرقام `rounding.*` الحالية) — من غير أي حاجة للـ C++ plugin بتاع caelestia نفسه. ده أرخص وأبسط حل لمحور "roundness" في الـ preset schema بتاعنا.

### 2.2 Ax-Shell — أبسط نظام (مرجع للحد الأدنى)

- Python/GTK/Fabric. matugen بيولّد ملف CSS واحد فيه `:vars { --primary: ...; --background: ...; }` (`config/matugen/templates/ax-shell.css`)، و`styles/*.css` كلها بتستهلك `var(--x)` عادي زي أي CSS.
- `border-radius: 16px` **مكتوب مرة واحدة global** على `* {}` في `main.css` — مفيش أي مفهوم "roundness scale" أو ladder إطلاقًا، رقم ثابت واحد للتطبيق كله.
- مفيش أي مفهوم gradient/halftone/shadow قابل للتخصيص كـ "هوية" — الظلال في `styles/shadows.css` منفصل تمامًا وثابت.

**الفايدة من المقارنة دي:** بتأكد إن **preset "بسيط" حقيقي ينفع يكون مجرد: رقم استدارة واحد + إعداد شفافية/ظل + اختيار خط** — مفيش داعي كل preset يكون معقد زي Ambxst عشان يبان كـ "هوية مختلفة".

---

## 3. الخطة المعمارية: طبقة الـ Presets فوق `Appearance.qml`/`Config.qml`

### 3.1 المبدأ: توسعة `builtInTheme` الموجود فعليًا، مش نظام جديد

`ExperienceConfig.qml` (أسطر 15-39) عنده بالفعل:

```qml
function applyTheme(name) {
    Config.options.appearance.builtInTheme = name
    const a = Config.options.appearance
    switch (name) {
    case "midnight":
        a.palette.type = "scheme-expressive"; a.palette.accentColor = "#8ab4f8"
        a.glass.enable = true; a.glass.opacity = 0.72; a.transparency.enable = true
        break
    // ... paper / aurora / mono / default(adaptive)
    }
}
```

وده **حرفيًا نفس نمط** `PerformanceProfiles.qml` + `Config.applyPerformanceProfile()` (JS object ثابت فيه id/name/description + مجموعة `Config.options.*` paths تتطبّق دفعة واحدة بضغطة زرار واحدة، زي ما طلب المستخدم بالظبط: *"زرار يطبّق كل حاجة دفعة واحدة"*).

**الفرق الوحيد بين اللي موجود دلوقتي واللي مطلوب:**
1. الـ presets الحالية (5: adaptive/midnight/paper/aurora/mono) بتضبط بس (`palette.type`, `palette.accentColor`, `glass.*`, `transparency.enable`) — **مفيش فيها roundness ولا shadow ولا font pairing ولا motion** رغم إن كل ده متاح كـ `Config.options.appearance.*` بالفعل جزئيًا (motion) أو محتاج إضافة بسيطة (roundness scale, shadow style).
2. الـ presets دي **hardcoded في دالة JS** مش قابلة للتوسعة من ملف بيانات خارجي، ومفيش واجهة "تصفّح presets متعددة بمعاينة" زي `PresetsTab.qml` بتاع Ambxst — بس ده مش لازم في المرحلة الأولى (5-8 presets ثابتة كفاية، مفيش داعي لنظام "استيراد/تصدير/إنشاء preset من المستخدم" زي Ambxst الأول مرة).

### 3.2 الإضافات الجديدة المطلوبة على `Appearance.qml` / `Config.qml`

عشان الـ presets تقدر تغطي روح Ambxst (roundness/shadow/font) من غير كسر حاجة موجودة، الإضافات المقترحة (كلها اختيارية وبقيم افتراضية = السلوك الحالي بالظبط، يعني **zero regression**):

```qml
// Config.qml -> appearance JsonObject (إضافات جديدة فقط، السطور الموجودة تفضل زي ما هي)
property JsonObject appearance: JsonObject {
    // ... existing properties untouched ...

    // === جديد: طبقة الـ roundness كـ "scale" فوق rounding.* الحالي، مستوحى من caelestia Tokens ===
    property real roundnessScale: 1.0   // 0.4 (GNOME) .. 1.3 (Liquid Glass) .. 0 (Retro/حواف حادة)

    // === جديد: هوية الظل، بدل القيم الثابتة المبعثرة حاليًا في hyprland.decoration.shadow ===
    property JsonObject shadowStyle: JsonObject {
        property real opacity: 0.35   // يقرأها الشل QML للـ drop-shadows الخاصة به (Menu/Popup/Tooltip)، غير Hyprland's own window shadow
        property int xOffset: 0
        property int yOffset: 2
        property real blur: 1.0       // 0 = ظل حاد بدون تنعيم (retro/8-bit)، 1 = طبيعي، >1 = ناعم جدًا (glass)
    }

    // === جديد: preset النشط حاليًا (مرجع فقط — نفس فكرة builtInTheme بس معمم) ===
    property string activePreset: "adaptive" // كان "builtInTheme" - نفس الحقل، إعادة تسمية اختيارية أو الإبقاء عليه
}
```

> **ملاحظة مهمة:** مفيش داعي لنسخ نظام "sr\* per-surface variant" الكامل بتاع Ambxst (19 variant منفصل، كل واحد بتدرّجه وحدوده الخاصة) — ده overkill لفلسفة Horizons-DE الحالية اللي بتعتمد على **derivation** (كل لون مُشتق رياضيًا من `m3colors` + `ColorUtils.mix/transparentize/solveOverlayColor`) مش على **تعريف يدوي منفصل لكل سطح**. الحفاظ على مبدأ الاشتقاق ده هو بالظبط "الحفاظ على الهوية البصرية" اللي طلبها المستخدم — مش نسخ بنية Ambxst حرفيًا.

### 3.3 Schema مقترح لملف الـ preset (JSON)، بأسماء Horizons-DE مش أسماء Ambxst

بدل `theme.json` بتاع Ambxst، نقترح preset يكون object JS بسيط (يتحط في ملف `PresetsDefinitions.qml` كـ singleton زي `PerformanceProfiles.qml` بالظبط — **مش ملف JSON منفصل على القرص**، عشان يفضل جزء من الكود المُراجَع بدل ملف مستخدم قابل للتلف):

```js
{
    id: "liquidGlass",
    name: "Liquid Glass",
    description: "زجاج مطفي شفاف يحاكي iOS/visionOS، استدارة أعلى، ظل ناعم جدًا.",
    icon: "water_drop",
    preview: { // Optional: قيم لعرض بطاقة معاينة بدون تطبيق فعلي (انظر قسم 4)
        roundness: 0.85, glass: true, accentHint: "#8ab4f8"
    },
    config: { // نفس شكل PerformanceProfiles.config: dotted-path -> value
        "appearance.visualEffect": "glass",
        "appearance.glass.enable": true,
        "appearance.glass.opacity": 0.78,
        "appearance.roundnessScale": 1.15,
        "appearance.shadowStyle.opacity": 0.25,
        "appearance.shadowStyle.blur": 1.6,
        "appearance.fonts.main": "Google Sans Flex",
        "appearance.motion.style": "smooth",
    },
    hypr: { // نفس شكل PerformanceProfiles.hypr - يتطبق عبر HyprlandConfig.setMany() من الصفحة
        "decoration:blur:variant": "acrylic",
        "decoration:rounding": 24,
    },
    // نفس فكرة acrylicVariantOnly بتاعة maxExperience: fallback لو الميزة مش مدعومة
    requiresCapability: "blurVariantSupported",
    fallback: { hypr: { "decoration:blur:variant": "kawase" } },
}
```

هذا الـ schema **بيعيد استخدام حرفيًا** نفس آلية `Config.setNestedValue()` و`HyprlandConfig.setMany()` الموجودة بالفعل لتطبيق الـ Performance Profiles — صفر كود جديد للتطبيق نفسه، بس كود جديد لتعريف قائمة الـ presets + صفحة UI تعرضها (قسم 4).

### 3.4 التوافق مع matugen — لا تعارض

الـ presets **لا تلمس** آلية استخراج الألوان من الـ wallpaper (`palette.type`, `wallColorQuant`, matugen scripts) إلا في حالة واحدة مقصودة: preset زي "Midnight" أو "Aurora" ممكن (زي الموجود فعليًا في `ExperienceConfig.qml`) يضبط `palette.type` و`palette.accentColor` كـ "اقتراح ابتدائي" فقط — والمستخدم حر يرجعها لـ `"auto"` في أي وقت بضغطة واحدة في `InterfaceConfig.qml` الموجودة بالفعل. أي preset "محايد" (GNOME, Retro, Ambxst-Default-equivalent) **يسيب `palette.type = "auto"` زي ما هي** ويقتصر تأثيره على roundness/shadow/glass/font/motion بس — ده الأنسب لمعظم الـ presets عشان يفضل الشل "بيتبع الخلفية" زي ما هي الفلسفة الأساسية.

---

## 4. خطة الـ UI: صفحة/تبويب Settings جديد

### 4.1 أين تتحط

**الأفضل: توسعة `ExperienceConfig.qml` الموجودة بالفعل**، مش صفحة منفصلة جديدة — لإنها أصلًا فيها section اسمه "Built-in themes" وده بالظبط مكان الـ presets. التغيير المطلوب:

1. تحويل الـ 5 قيم الموجودة (`adaptive/midnight/paper/aurora/mono`) + الـ presets الجديدة (`gnome`, `liquidGlass`, `retroTerminal`, ...) لمصفوفة بيانات في singleton جديد (`ThemePresets.qml`, بنفس بنية `PerformanceProfiles.qml` حرفيًا) بدل الـ `switch` المكتوب يدويًا جوه `ExperienceConfig.qml`.
2. `ExperienceConfig.qml` تستدعي `Config.applyThemePreset(id, HyprlandData.blurVariantSupported)` (دالة جديدة في `Config.qml` بنفس بنية `applyPerformanceProfile()` بالظبط) بدل الـ `switch` الحالي.
3. الـ `ConfigSelectionArray` الموجودة فعليًا (سطر 79-91) تتغذى من `ThemePresets.presets.map(p => ({displayName, icon, value: p.id}))` بدل المصفوفة الثابتة الحالية — **نفس المكوّن بالظبط**، مجرد تغيير مصدر البيانات.
4. إضافة نص وصف تحت الاختيار (زي `performanceSection.currentProfile.description` في `QuickConfig.qml` سطر 284-291) — نفس النمط حرفيًا.

### 4.2 معاينة بصرية اختيارية (Phase 2، أولوية أقل)

Ambxst عنده `PresetsTab.qml` بمعاينة نصية/بحث فوري داخل popup منفصل. **مش لازم ننسخ ده في المرحلة الأولى** — الحل الأبسط (ويكفي تمامًا): كل preset في `ConfigSelectionArray` يديله بس اسم + أيقونة + جملة وصف (زي الموجود بالظبط لـ Performance Profiles) — أرخص في التنفيذ وأقرب لفلسفة Horizons-DE في باقي صفحات الـ Settings. لو حبينا معاينة بصرية حقيقية لاحقًا، ممكن نضيف صف صغير من "swatches" (مربعات ألوان + دائرة توضح roundness) بجانب كل خيار في نفس `ConfigSelectionArray` — بدون الحاجة لنافذة popup منفصلة زي Ambxst.

### 4.3 مخطط الكود (ملخّص)

```
shell/modules/common/ThemePresets.qml        (جديد - singleton، نفس بنية PerformanceProfiles.qml)
shell/modules/common/Config.qml               (إضافة: roundnessScale, shadowStyle + applyThemePreset())
shell/modules/common/Appearance.qml           (قراءة roundnessScale لضرب rounding.* + shadowStyle)
shell/modules/ii/settings/pages/ExperienceConfig.qml  (تعديل: استبدال الـ switch اليدوي بـ ThemePresets)
```

مفيش ملفات جديدة كتير، ومفيش تغيير في `InterfaceConfig.qml` (بيفضل هو المكان اللي فيه التحكم اليدوي التفصيلي بعد اختيار الـ preset، بالظبط زي علاقة `QuickConfig.qml` بـ `InterfaceConfig.qml` الحالية).

---

## 5. خطة تنفيذ تفصيلية لـ 3 presets

تم اختيار: **Liquid Glass** (الأقرب لنظام `glass` الموجود عندنا) + **GNOME** (هوية معروفة وواضحة وأبسط تنفيذ) + **Retro Terminal** (يدمج روح Dotsquared+Retro بتاعة Ambxst: هوية تيرمينال/بكسل مميزة، وبيوضح حدود "من غير شادر جديد" بشكل عملي).

### 5.1 Liquid Glass

**الفكرة:** الشل أصلًا عنده `visualEffect: "glass"` مربوط بـ `hyprland.decoration.blur.variant = "acrylic"` (Hyprland's native Liquid Glass compositor effect) — الـ preset ده أساسًا **تفعيل + ضبط دقيق** لحاجة موجودة، مش بناء جديد.

| الإعداد | القيمة المقترحة | ملاحظة |
|---|---|---|
| `appearance.visualEffect` | `"glass"` | يفعّل `glass.enable=true` تلقائيًا عبر `applyVisualEffectExclusivity()` الموجودة |
| `appearance.glass.opacity` | `0.80` | زجاج شبه شفاف واضح لكن مش مبالغ فيه |
| `appearance.roundnessScale` (جديد) | `1.15` | استدارة أعلى شوية من الافتراضي — زجاج iOS-style بيميل لحواف أنعم |
| `appearance.shadowStyle.blur` (جديد) | `1.6` | ظل أوسع وأنعم (زي preset "Liquid Glass" بتاع Ambxst: opacity منخفض + انتشار) |
| `appearance.shadowStyle.opacity` (جديد) | `0.25` | ظل خفيف — الشفافية نفسها هي أداة العمق مش الظل |
| `appearance.motion.style` | `"smooth"` | حركة غير مبالغ فيها تناسب الزجاج |
| `hyprland.decoration.blur.variant` | `"acrylic"` | نفس اللي بيستخدمه preset `maxExperience` الأداء فعليًا — إعادة استخدام مباشرة |
| `hyprland.decoration.blur.acrylic.clarity` | `0.82` (القيمة الافتراضية الحالية) | تفضل زي ما هي، preset الثيم لا يكرر إعدادات الأداء |
| Fallback (زي `maxExperience.acrylicVariantOnly`) | لو `!blurVariantSupported`: `hyprland.decoration.blur.variant = "frost"` | frost أقرب بصريًا لـ acrylic من kawase العادي |

**لا إضافات جديدة مطلوبة خارج roundnessScale/shadowStyle المقترحين في قسم 3.2.**

### 5.2 GNOME

**الفكرة:** preset "تسطيح" — إلغاء كل تأثير زخرفي (ظل خفيف جدًا، بدون شفافية، استدارة أقل)، خط بديل، حدود واضحة بدل التدرّجات.

| الإعداد | القيمة المقترحة | ملاحظة |
|---|---|---|
| `appearance.visualEffect` | `"none"` | بدون blur ولا glass ولا transparency — GNOME/Adwaita مسطّح تمامًا |
| `appearance.roundnessScale` (جديد) | `0.75` | استدارة أقل من الافتراضي (Ambxst's GNOME preset استخدم 14 بدل 16 — نسبة ~0.875، لكن اخترنا أقل شوية عشان يبان الفرق أوضح في سياقنا) |
| `appearance.shadowStyle.opacity` (جديد) | `0.5` | قياسي — GNOME فعليًا بيستخدم نفس الظل الافتراضي |
| `appearance.fonts.main` | `"Cantarell"` أو fallback `"Noto Sans"` لو غير متاح على النظام | الخط الافتراضي لـ GNOME الحقيقي (Ambxst preset استخدم Roboto Mono للـ mono، إحنا هنسيب `monospace` زي ما هو عشان الـ terminal/code لا يتأثر) |
| `appearance.motion.style` | `"smooth"` | بدون overshoot — GNOME's own animation style غير spring-y |
| `hyprland.decoration.blur.enabled` | `false` | يتوافق مع `visualEffect: "none"` |
| `hyprland.decoration.shadow.range` | القيمة الافتراضية الحالية (20) | مفيش داعي لتصغيرها، GNOME shadows فعليًا موجودة لكن دقيقة |

**ملاحظة عن الخط:** لازم نتأكد إن `Cantarell` متاح كـ fallback آمن (معظم توزيعات Linux اللي فيها GNOME عندها الخط ده مثبت أصلًا؛ لو مش موجود، QML بيرجع تلقائيًا للخط الافتراضي للنظام — مفيش خطر فعلي).

### 5.3 Retro Terminal (دمج روح Dotsquared + Retro)

**الفكرة:** هوية "تيرمينال/بكسل" مميزة — حواف حادة تمامًا، خط bitmap، ظل بكسلي حاد (offset بدون blur)، بدون glass ولا transparency، مع الاحتفاظ بالـ halftone كـ **تحسين اختياري مستقبلي** (Phase 2) بدل حاجز أمام الإصدار الأول.

| الإعداد | القيمة المقترحة | ملاحظة |
|---|---|---|
| `appearance.visualEffect` | `"none"` | بدون أي تأثير زجاجي — تيرمينال كلاسيكي |
| `appearance.roundnessScale` (جديد) | `0.0` | حواف حادة 100% (زي `roundness: 0` في كل من Dotsquared/Manga/Retro بتاعة Ambxst) |
| `appearance.shadowStyle.blur` (جديد) | `0.0` | ظل بكسلي حاد بدون تنعيم (نفس `shadowBlur: 0` في Ambxst) |
| `appearance.shadowStyle.xOffset`/`yOffset` (جديد) | `1` / `1` | إزاحة بكسل واحد بالظبط (زي القيم الحرفية في Dotsquared/Retro) |
| `appearance.fonts.main` / `monospace` | `"Terminus"` (أو fallback `"Iosevka Term"` / الخط النيرد الحالي لو Terminus مش مثبت) | خط bitmap صريح — يحتاج توثيق في الـ preset إن الخط ده لازم يتثبّت منفصل (مش كل التوزيعات عندها Terminus افتراضيًا) |
| `appearance.motion.durationScale` | `0.6` | حركة أسرع/أقل تدرّجًا تناسب طابع "طرفية" |
| `hyprland.decoration.blur.enabled` | `false` | |
| `hyprland.decoration.rounding` | `0` | مطابقة roundness الشل نفسه على مستوى نوافذ الـ compositor كمان |
| **Halftone (Phase 2، اختياري)** | مكوّن `HalftoneBackground.qml` جديد (`ShaderEffect` بنفس منطق `halftone.frag` بتاع Ambxst) يُستخدم اختياريًا كخلفية لبعض اللوحات (Bar/Popup) | **مؤجّل عمدًا** — يحتاج كتابة + تصريف شادر GLSL جديد؛ الـ preset يشتغل ويبان مميز بصريًا بالكامل من غيره في الإصدار الأول |

---

## 6. الأولويات (من الأعلى قيمة/الأقل خطورة، للأقل)

| # | البند | القيمة | الخطورة | لماذا هنا |
|---|---|---|---|---|
| 1 | توسعة `PerformanceProfiles.qml` pattern لملف `ThemePresets.qml` جديد + دالة `Config.applyThemePreset()` | عالية جدًا | منخفضة جدًا | إعادة استخدام كود مُختبَر بالفعل (نفس الآلية شغالة اليوم لـ 5 performance profiles)، صفر كسر لأي حاجة موجودة |
| 2 | إضافة `appearance.roundnessScale` + `appearance.shadowStyle.*` لـ `Config.qml`/`Appearance.qml` بقيم افتراضية = السلوك الحالي بالظبط | عالية | منخفضة | فتح الباب لكل الـ presets الأخرى؛ قيم افتراضية غير مؤثرة = zero regression مضمون |
| 3 | تعديل `ExperienceConfig.qml` ليقرأ من `ThemePresets.presets` بدل الـ `switch` اليدوي (توسعة الـ 5 الموجودين + إضافة GNOME/Liquid Glass/Retro Terminal) | عالية | منخفضة | يستخدم مكوّن UI موجود بالفعل (`ConfigSelectionArray`)، تغيير مصدر بيانات فقط |
| 4 | preset **GNOME** كامل | متوسطة-عالية | **منخفضة جدًا** | لا يحتاج أي إضافة جديدة غير القسمين 1-2، وأسهل preset تقنيًا في كل التقرير |
| 5 | preset **Liquid Glass** كامل | عالية | منخفضة | يعيد استخدام `visualEffect=glass`/`acrylic` الموجودين فعليًا بالكامل — القيمة عالية لأنه أقرب preset لهوية الشل الحالية أصلًا |
| 6 | preset **Retro Terminal** (بدون halftone) | متوسطة | منخفضة-متوسطة | يحتاج fallback فونت موثّق (Terminus قد لا يكون مثبتًا) — الخطورة الوحيدة هنا واجهة/توثيق مش كود |
| 7 | معاينة بصرية بسيطة (swatches) جنب كل preset في `ConfigSelectionArray` | متوسطة | منخفضة | تحسين UX، مش لازم للإطلاق الأول |
| 8 | مكوّن `ShaderEffect` للـ halftone (Dotsquared/Manga/preset مستقبلي) | منخفضة-متوسطة (قيمة بصرية عالية لكن نطاق ضيق) | **متوسطة-عالية** | يحتاج كتابة GLSL جديد + تصريف `.qsb` + اختبار أداء على GPUs مختلفة — مجهود حقيقي غير مضمون العائد له نفس الأولوية |
| 9 | نظام "استيراد/تصدير/إنشاء preset مخصص من المستخدم" (زي `PresetsService`/`PresetsTab` الكامل بتاع Ambxst، بما فيه bundling لملفات كونفيج متعددة) | منخفضة حاليًا | متوسطة (تعقيد UI + إدارة ملفات) | غير مطلوب في نطاق المهمة الحالية (presets جاهزة ثابتة تكفي)؛ يُقترح فقط لو ظهر طلب مستخدمين حقيقي لاحقًا |

---

# 5. الإضافات الرسمية (hyprland-plugins) وأنظمة البناء — خطة الخيارات الاختيارية

**تاريخ:** 2026-09-05
**النطاق:** هذا المستند جزء من دفعة تخطيط بحثية أكبر (`05-plugins-packaging.md`، الخامس من ستة). يبني فوق `docs/dots-integration-audit.md` (القسم 3 فيه عمل تعريفًا أوليًا سريعًا لقائمة الـ 8 plugins) بدل ما يكرره — هنا التركيز على **العمق التقني الحقيقي لكل plugin** (من الـ README الفعلي، مش تخمين) + **خطة تنفيذ ملموسة** لجعلها اختيارات Opt-In في واجهة الإعدادات، مع تغييرات `installer.sh` و`Config.qml` محددة بالاسم. باقي التقارير في نفس الدفعة: `01-bars-widgets.md` (البار/الويدجتس)، `02-animations.md` (الأنيميشن)، `03-axctl-fork.md` (axctl تحديدًا)، `04-theming-presets.md` (الثيمات/presets) — فمفيش تكرار عميق لموضوعاتهم هنا، غير إشارة عابرة عند التقاطع.

**مبدأ حاكم واحد لكل التقرير:** كل حاجة هنا **Opt-In بحت** — القيمة الافتراضية لأي plugin هي **مُعطّل (disabled)**، ومفيش أي تغيير في `installer.sh` أو `Config.qml` المقترح هنا يفرض تثبيت أو تفعيل أي plugin تلقائيًا على أي مستخدم قائم أو جديد.

---

## 0. خلفية ضرورية: إيه هو hyprpm وإزاي Horizons-DE بيتعامل مع إعداد Hyprland

قبل تفصيل الـ 8 plugins، لازم فهم قناتين موجودتين فعلاً في الكود عشان أي مقترح بعد كده يبني عليهم مش يخترعهم من الصفر:

### 0.1 `hyprpm` — مدير الإضافات الرسمي بتاع Hyprland نفسه
`hyprpm` بيتوزّع كجزء من حزمة `hyprland` نفسها (مش حزمة منفصلة) — يعني مفيش اعتماد إضافي لازم يتضاف في `PKGBUILD` عشان الأداة تكون موجودة، بس **بناء** أي plugin بيه محتاج توفّر headers/build deps بتاعة Hyprland نفسها (عادة موجودة تلقائيًا مع حزمة `hyprland-git`/`hyprland` على Arch، لكن يستاهل فحص فعلي وقت التنفيذ مش افتراض). أوامره الأساسية:
- `hyprpm add <git-url>` — يستنسخ ريبو الإضافات (هنا `https://github.com/hyprwm/hyprland-plugins`) ويبنيه.
- `hyprpm enable <name>` / `hyprpm disable <name>` — تفعيل/تعطيل إضافة مبنية بالفعل (سريع، بلا إعادة بناء).
- `hyprpm remove <name>` — إزالة كاملة (المصدر المبني كمان).
- `hyprpm update` — إعادة سحب وبناء كل الإضافات المضافة (مطلوبة بعد أي ترقية لـ Hyprland نفسه — تفصيل كامل في قسم المخاطر).
- `hyprpm list` / `hyprctl -j plugin list` — فحص الحالة (الأداة التانية دي مُستخدَمة فعلاً في `installer.sh` الحالي، تفصيل تحت).

### 0.2 القناة الموجودة فعلاً في الكود لكتابة إعداد Hyprland من الشل
`shell/services/HyprlandConfig.qml` (singleton) بيوفّر `HyprlandConfig.set(key, value)` / `setMany(entries)` / `reset(key)`. كل واحدة منهم بتستدعي `Quickshell.execDetached(["python3", hyprconfigurator.py, "--file", shellOverridesPath, "--set", key, value])`. الملف المُستهدف هو:
```
~/.config/hypr/hyprland/shellOverrides/main.lua
```
وهو **مُولَّد بالكامل، ممنوع التعديل اليدوي** (أول سطر فيه حرفيًا: `-- DO NOT EDIT THIS FILE. IT IS MANAGED BY THE SHELL`). `hyprconfigurator.py` بياخد مفتاح بصيغة `"decoration:blur:enabled"` ويحوّله لسطر Lua متداخل:
```lua
hl.config({ decoration = { blur = { enabled = true } } })
```
عبر `to_lua_line()` اللي بتقسّم المفتاح على `:` وتبني جدول Lua متداخل حرفيًا حسب الأجزاء. **النقطة الحرجة لخطة الـ plugins:** نفس الدالة دي، لو استُدعيت بمفتاح زي `"plugin:hyprexpo:columns"`، هتولّد تلقائيًا:
```lua
hl.config({ plugin = { hyprexpo = { columns = 3 } } })
```
وهو **بالظبط** الشكل اللي المفروض يكافئ صيغة `hyprland.conf` الكلاسيكية `plugin { hyprexpo { columns = 3 } }` بتاعة الـ plugin. الكود الحالي فعليًا **مش بيستخدم namespace اسمه `plugin:` خالص** في أي حتة من الـ 60+ مفتاح المدعومة حاليًا (كلها `general`/`decoration`/`input`/`dwindle`/`master`/`group`/`gestures`/`cursor`/`misc`) — فده **افتراض معماري لسه محتاج تحقق فعلي** (تشغيل Hyprland حقيقي + plugin مُفعّل + تجربة `hl.config({ plugin = {...} })` والتأكد إنه بيتقبل مفاتيح لـ plugin مش محمّل أصلاً وقت التشغيل الأول) قبل ما يتعمّد عليه في أي تنفيذ فعلي — مذكور بوضوح كنقطة تحقّق مطلوبة، مش حقيقة مؤكدة.

كمان `hyprland.lua` (نقطة الدخول الرئيسية) بيحمّل `shellOverrides/main.lua` **إجباريًا** وبيحمّل `shellOverrides/animations.lua` **اختياريًا** وبأمان (`pcall`):
```lua
require("hyprland.shellOverrides.main")
if is_file_exists(HOME .. "/.config/hypr/hyprland/shellOverrides/animations.lua") then
    pcall(require, "hyprland.shellOverrides.animations")
end
```
ده نمط **جاهز للتكرار حرفيًا** لملف جديد `shellOverrides/plugins.lua` (تفصيل في القسم 2) — ميزة `pcall` هنا مهمة جدًا لملف الـ plugins تحديدًا لأنه أكتر عرضة للفشل (مفتاح `plugin:X:Y` غير موجود لو الـ plugin X نفسه مش محمّل فعليًا وقتها).

### 0.3 سابقة موجودة فعلاً: إزالة `hyprglass`
`installer.sh` فيه دالة كاملة اسمها `cleanup_hyprglass()` (تشتغل تلقائيًا في كل تثبيت/تحديث، بلا شرط) بتتعامل بالظبط مع نفس فئة المشاكل اللي هنقابلها هنا:
- تفريغ أي plugin محمّل فعليًا من Hyprland الشغال: `hyprctl -j plugin list` ثم `hyprctl plugin unload <path>`.
- إزالة أي تسجيل عبر `hyprpm`: `hyprpm list | grep -qi hyprglass` ثم `hyprpm remove hyprglass`.
- مسح ملفات متبقية (`$QS_CONFIG_DIR/plugins/hyprglass`, `shellOverrides/hyprglass.lua`).
- تنظيف أي إشارة قديمة بصيغة classic syntax (`plugin = /path/.../hyprglass.so`) من `hyprland.conf` القديم.

هذا **دليل عملي مباشر** إن الفريق سبق وتعامل مع دورة حياة plugin (تحميل/إلغاء تحميل/تنظيف ملفات/hyprpm) داخل نفس `installer.sh` — يعني القدرة التقنية والنمط المطلوبين لدعم الـ hyprland-plugins الرسمية **موجودين بالفعل جزئيًا في الكود**، بس في الاتجاه المعاكس (إزالة plugin غير رسمي)، مش إضافة plugins رسمية. القسم 2 هيقترح دالة اختية `install_hyprland_plugin()`/`remove_hyprland_plugin()` بنفس الروح.

---

## 1. الإضافات الثمانية: تحليل تقني + خطة تفعيل لكل واحدة

جدول سريع أولاً (من `hyprpm.toml` + الـ READMEs الفعلية):

| Plugin | التغيير الفعلي على مستوى الـ compositor | طريقة التثبيت | حد أدنى (`since_hyprland`) |
|---|---|---|---|
| `borders-plus-plus` | يرسم 1-9 حدود إضافية **ثابتة** حول كل نافذة (فوق حد Hyprland الأساسي) | `hyprpm` (build عبر `make`) | غير محدد (متوافق مع كل نسخ الـ pin list) |
| `csgo-vulkan-fix` | Hook على مستوى الـ compositor يخدع أي تطبيق (مش بس CS2) بدقة شاشة وهمية + تصحيح موضع الماوس | `hyprpm` (build عبر `make`) | غير محدد |
| `hyprbars` | يضيف طبقة رسم (render layer) شريط عنوان فوق كل نافذة، مع أزرار قابلة للنقر تُطلق أوامر `hyprctl dispatch` | `hyprpm` (build عبر `make`) | غير محدد |
| `hyprexpo` | يعترض حركة الـ workspace ويرسم Overview شبكي (columns×rows) لكل النوافذ المفتوحة، مع دعم gesture من التتش باد | `hyprpm` (build عبر `make`) | `4364` (رقم commit/build داخلي لـ Hyprland، وليس رقم إصدار دلالي) |
| `hyprscrolling` | **يستبدل** خوارزمية التبليط بالكامل بتخطيط تمرير أفقي (columns بعرض نسبي)، بديل كامل عن `dwindle`/`master` | `hyprpm` (build عبر `make`) | `6066` |
| `hyprtrails` | يضيف تأثير رسم إضافي (أثر بصري) خلف كل نافذة أثناء الحركة — تكلفة render إضافية حقيقية لكل فريم حركة | `hyprpm` (build عبر `make`) | غير محدد |
| `hyprwinwrap` | يربط نافذة عميل حي (client) خلف كل شيء كخلفية تفاعلية (بديل `xwinwrap` لـ Wayland) | `hyprpm` (build عبر `make`) | غير محدد |
| `xtra-dispatchers` | يضيف 4 dispatchers جديدة فقط (`moveorexec`, `throwunfocused`, `bringallfrom`, `closeunfocused`) — بلا أي تأثير بصري أو حالة دائمة | `hyprpm` (build عبر `make`) | `5573` |

**ملاحظة على "الحد الأدنى":** أرقام `since_hyprland` في `hyprpm.toml` (4364, 5573, 6066) **مش أرقام إصدار دلالي** (0.4x.x) — هي أرقام مرجعية داخلية لـ hyprpm نفسه لمقارنة توافق البناء، ومحسوبة تلقائيًا وقت `hyprpm add`/`update`، مش حاجة تحتاج Horizons-DE يتحقق منها يدويًا — hyprpm بيرفض البناء بنفسه لو النسخة قديمة جدًا. الأهم فعليًا هو **آلية الـ `commit_pins`** الموضّحة في القسم 3 (المخاطر).

كل الـ 8 لازم `hyprpm` — **مفيش ولا واحدة منهم بديل بناء يدوي موثّق رسميًا** (الـ README الرئيسي بيقول صراحة: *"hyprland-plugins only officially supports installation via `hyprpm`"*). ده يبسّط خطة التنفيذ: مفيش حاجة اسمها "مسار بناء بديل" لازم نصممه — القناة الوحيدة المدعومة هي `hyprpm add`/`enable`.

### 1.1 `hyprexpo`

**الوصف التقني (من الـ README):** overview بأسلوب GNOME/KDE/wf — عند التفعيل (`bind = ..., hyprexpo:expo, toggle`) بيعرض كل نوافذ الـ workspace الحالي (أو مجموعة workspaces) في شبكة `columns × rows` قابلة للتحكم، مع `workspace_method` بيحدد إزاي يحسب نقطة البداية (`center current` أو `first N`). بيدعم gesture تتش باد (3 أو 4 أصابع، مسافة قابلة للضبط، اتجاه قابل للعكس).

**التقاطع مع Horizons-DE الحالي:** الشل عنده Overview مبني بالكامل QML (`Overview.qml`، مذكور في `dots-integration-audit.md`). ده **مش فجوة تُسدّ** — هو خيار بديل بفلسفة مختلفة (rendering على مستوى الـ compositor نفسه بدل QML overlay)، يستاهل يكون Opt-In بالظبط عشان كده: بعض المستخدمين ممكن يفضّلوا سلوك hyprexpo الأصلي (خصوصًا الـ gesture support اللي مش موجود بالضرورة في الـ QML Overview).

**خطة Config.qml:**
```qml
property JsonObject plugins: JsonObject {
    property JsonObject hyprexpo: JsonObject {
        property bool enabled: false
        property int columns: 3
        property int gapSize: 5
        property string bgColor: "rgb(111111)"
        property string workspaceMethod: "center current"
        property bool enableGesture: true
        property int gestureFingers: 3
        property int gestureDistance: 300
        property bool gesturePositive: true
    }
    // ... باقي الـ 7 plugins بنفس النمط
}
```
(المسار الكامل: `Config.options.hyprland.plugins.hyprexpo.*`، جنب `dwindle`/`master`/`group` الموجودين فعلاً في نفس الملف حوالي السطر 559-581.)

**واجهة الإعدادات:** `ContentSection` جديدة اسمها "Official Plugins" داخل `pages/HyprlandConfig.qml` (تفصيل كامل في القسم 2) — `GroupedList` فيها `ConfigSwitch` لكل plugin، ولما `hyprexpo.enabled` يبقى `true` تتكشف صف إضافي (`ConfigSpinBox` لـ columns/gap، `ConfigTextField` للـ bg color، `ConfigSwitch` لـ enable_gesture + إعداداته).

**تغييرات `installer.sh`:** إضافة CSV اختياري جديد بنفس فلسفة `--launchers` الموجود بالفعل (سطر 44-47 من الملف الحالي):
```
--plugins <csv>       Optional official Hyprland plugins to build via hyprpm:
                      hyprexpo,hyprbars,hyprscrolling,hyprtrails,hyprwinwrap,
                      borders-plus-plus,xtra-dispatchers (or "none").
                      Omit to be asked interactively; default is none.
--skip-plugins        Don't offer/install optional plugins at all
```
مع دالة `install_hyprland_plugins()` جديدة (نفس بنية `install_launchers()` سطر ~1014 من `installer.sh`):
```bash
install_hyprland_plugins(){
  step "$(L "Optional official Hyprland plugins (hyprpm)" "إضافات Hyprland الرسمية الاختيارية (hyprpm)")"
  command -v hyprpm &>/dev/null || { warn "hyprpm not found (ships with Hyprland itself) — skipping."; return 0; }
  run hyprpm add https://github.com/hyprwm/hyprland-plugins   # idempotent: hyprpm skips if already added
  # ... لكل اسم في $PLUGINS_CSV: run hyprpm enable "$name"
}
```
مهم: `csgo-vulkan-fix` **مُستبعَد عمدًا** من القائمة اللي بتتعرض في الـ CLI والـ Settings UI (تفصيل في القسم 5).

### 1.2 `hyprbars`

**الوصف التقني:** يضيف شريط عنوان native (طبقة رسم) فوق كل نافذة، بارتفاع (`bar_height`)، لون خلفية/نص قابلين للتخصيص، خط، محاذاة عنوان، وأزرار (`hyprbars-button = color, size, icon, on-click[, fgcolor]`) بتنفّذ أي أمر shell عند الضغط. يدعم window rules ديناميكية (`plugin:hyprbars:nobar`, `bar_color`, `title_color`) — يعني ممكن تُستبعد نوافذ معيّنة أو تتلوّن بشكل مختلف حسب الكلاس.

**ملاحظة تصميمية مهمة:** ده شريط عنوان **native حقيقي جوه الـ compositor**، منفصل تمامًا عن أي chrome بيرسمه الشل نفسه. تفعيله جنب شل بيوفّر بالفعل تحكم كامل في الإطار البصري (زي Horizons-DE) بيعني ازدواج chrome محتمل (شريط عنوان الشل + شريط عنوان hyprbars سوا) — لازم تحذير واضح في الـ UI، مش بس toggle عادي.

**Config.qml:**
```qml
property JsonObject hyprbars: JsonObject {
    property bool enabled: false
    property int barHeight: 15
    property string barColor: ""            // فاضي = افتراضي Hyprland
    property string colText: ""
    property int barTextSize: 10
    property string barTextFont: "Sans"
    property string barTextAlign: "center"  // center | left
    property string barButtonsAlignment: "right" // right | left
    property bool barPartOfWindow: true
    property bool barPrecedenceOverBorder: false
    property int barPadding: 7
    property int barButtonPadding: 5
    property bool iconOnHover: false
    // hyprbars-button مش "مفتاح = قيمة" عادي — هو keyword متكرر
    // (زي customBindsLua/customRulesLua الموجودين بالفعل في الملف)، فلازم
    // يتخزن كـ list<var> ويتولّد كسطور Lua منفصلة، مش عبر HyprlandConfig.set() العادي.
    property list<var> buttons: [
        { "color": "rgb(ff4040)", "size": 10, "icon": "󰖭", "onClick": "hyprctl dispatch killactive", "fgColor": "" }
    ]
}
```
**تنبيه تنفيذي:** `hyprbars-button` مش مفتاح مفرد قابل للتعبير بصيغة `"plugin:hyprbars:key"` عادية (زي باقي المفاتيح) — هو keyword يتكرر لكل زرار، فمحتاج مسار توليد Lua مخصص شبيه بمسار `customBindsLua`/`customRulesLua` الموجودين بالفعل في `Config.qml` (سطر 582-583) و`hyprconfigurator.py` (`save_custom_file`)، مش `HyprlandConfig.set()` العادي. هذا تفصيل يستاهل يُؤخذ بعين الاعتبار وقت التنفيذ الفعلي، مش مجرد إضافة صف `ConfigSwitch` بسيط.

**واجهة الإعدادات:** `ConfigSwitch` رئيسي + صف تحذير ثابت ("قد يظهر شريط عنوان مزدوج فوق نوافذك") + قسم فرعي (`ContentSubsection`) لخصائص الشريط الأساسية فقط (الارتفاع، اللون، المحاذاة) — تحرير الأزرار نفسها (JSON مخصص) أفضل يترك كخيار متقدم "Edit buttons (advanced)" بدل واجهة كاملة لكل زرار، تفاديًا لتعقيد UI غير متناسب مع الفائدة.

### 1.3 `hyprscrolling`

**الوصف التقني:** بديل كامل لخوارزميات التبليط (`dwindle`/`master`) — تخطيط أعمدة أفقية بعرض نسبي (`column_width` كنسبة من عرض الشاشة)، مع رسائل تحكم (`move`, `colresize`, `movewindowto`) بدل الـ dispatchers التقليدية. **الـ README نفسه يقول صراحة: "This plugin is a work in progress!"**

**تحذير معماري:** ده مش إضافة تُفعَّل جنب التخطيط الحالي — هو **يستبدل** `general:layout` بالكامل. تفعيله يعني كل إعدادات `dwindle`/`master` الموجودة فعليًا في `HyprlandConfig.qml` (`preserveSplit`, `smartSplit`, `mfact`, `orientation`, ...) تبقى **بلا تأثير فوري** طالما الـ layout الفعّال هو `hyprscrolling`. أي واجهة إعداد لازم توضّح ده بشكل صريح (زي التعامل مع `decoration:blur:variant` الحالي اللي بيعطّل خيارات متضاربة — نفس فلسفة `applyVisualEffectExclusivity()` الموجودة في `Config.qml`).

**Config.qml:**
```qml
property JsonObject hyprscrolling: JsonObject {
    property bool enabled: false
    property bool fullscreenOnOneColumn: false
    property real columnWidth: 0.5
    property string explicitColumnWidths: "0.333, 0.5, 0.667, 1.0"
}
```
تفعيل `enabled: true` لازم يستدعي `HyprlandConfig.set("general:layout", "hyprscrolling")` (بدل `"dwindle"`)، وتعطيله يرجّع `general:layout` لقيمته السابقة (`Config.options.hyprland.general.layout`، الموجودة فعلاً كـ property بالسطر ~490).

**واجهة الإعدادات:** أعلى مستوى تحذير من كل القائمة — `ConfigSwitch` رئيسي + نص تحذير أحمر/برتقالي ثابت ("Work-in-progress upstream. Replaces your tiling layout entirely — Dwindle/Master settings won't apply while enabled.") + رابط لباقي إعدادات hyprscrolling فقط بعد التفعيل.

### 1.4 `hyprtrails`

**الوصف التقني:** رسم أثر (trail) بصري خلف النوافذ أثناء الحركة. المطورين أنفسهم واصفينه: *"A neat, but useless plugin"*، وبيحذروا صراحة: *"the curve-related settings are only for advanced users... incredibly impact performance"*. الإعداد الوحيد الموصى بيه فعليًا هو اللون.

**Config.qml:**
```qml
property JsonObject hyprtrails: JsonObject {
    property bool enabled: false
    property string color: "rgba(ffaa00ff)"
}
```
عمدًا **بلا** إعدادات curve متقدمة — الـ README نفسه بيحذّر منها، فمفيش داعي نعرّض واجهة لحاجة الـ upstream نفسه بينصح بعدم لمسها.

**واجهة الإعدادات:** `ConfigSwitch` + `ConfigTextField` لون واحد بس. صف تحذير أداء ثابت ("Significant GPU/render cost while windows move — the developers call this one 'neat but useless'.").

### 1.5 `hyprwinwrap`

**الوصف التقني:** استنساخ لـ `xwinwrap` على Wayland — بيربط نافذة عميل حقيقية (Class match بالظبط، مش regex) كخلفية حية خلف كل شيء. مثال الـ README الرسمي بيشغّل `kitty` بسكربت `cava` جواه كخلفية صوتية حية، مع ملاحظة تقنية دقيقة: لازم `sleep` قبل تشغيل `cava` "لأن تغيير الحجم بيحصل بعد الفتح بمللي ثانية، وده بيكسر cava" — إشارة لتوقيت حساس في التعامل مع النافذة المُغلَّفة.

**التقاطع مع Horizons-DE:** `dots-integration-audit.md` (القسم 3، آخر عمود) عمل إشارة صريحة إن ده **بديل محتمل لآلية `mpvpaper` الحالية لخلفيات الفيديو** ويستاهل فحص منفصل — هذا التقرير بيؤكد نفس الملاحظة بعد قراءة الـ README كاملة: الفرق الجوهري إن `hyprwinwrap` بيغلّف **أي عميل Wayland** (مش بس فيديو عبر mpv) — يعني ممكن يفتح الباب لخلفيات تفاعلية حقيقية (زي مثال `cava` نفسه) مش بس تشغيل فيديو سلبي.

**Config.qml:**
```qml
property JsonObject hyprwinwrap: JsonObject {
    property bool enabled: false
    property string targetClass: "kitty-bg"   // exact match, NOT regex
}
```
**ملاحظة تنفيذية:** الـ plugin نفسه بيعرّف **مطابقة الكلاس فقط** — إطلاق العميل الفعلي (`kitty -c ... --class=... <script>`) مسؤولية خارجية (exec-once)، مش جزء من إعداد الـ plugin. يعني تفعيل هذا الخيار من الإعدادات لازم يترافق مع UI لاختيار/تحرير أمر الإطلاق نفسه (زي حقل الأمر المخصص الموجود بالفعل لأدوات تانية في الشل)، مش مجرد `ConfigSwitch` واحد.

### 1.6 `borders-plus-plus`

**الوصف التقني:** حدود إضافية **ثابتة** (static — لا أنيميشن) حول النوافذ، حتى 9 حدود، كل واحدة بلون وسمك مستقل (`-1` = يورث `general:border_size`)، مع خيار `natural_rounding` (تطابق استدارة الحد الخارجي مع الداخلي).

**Config.qml:**
```qml
property JsonObject bordersPlusPlus: JsonObject {
    property bool enabled: false
    property int addBorders: 1        // 0-9
    property var borderColors: ["rgb(ffffff)"]   // list<string>, بطول addBorders
    property var borderSizes: [10]               // list<int>, -1 = يورث general:border_size
    property bool naturalRounding: true
}
```

**واجهة الإعدادات:** الأنسب منطقيًا داخل `ContentSubsection` الحدود الموجودة بالفعل في `HyprlandConfig.qml` (قسم `general:col.active_border`/`general:border_size` حوالي السطر 2084-2166) — مش قسم منفصل — لأنها امتداد مباشر لنفس مفهوم "حدود النافذة" اللي المستخدم بيعدّله هناك أصلاً. `ConfigSpinBox` لعدد الحدود (0-9) يتحكم ديناميكيًا في عدد صفوف اللون/السمك المعروضة.

### 1.7 `xtra-dispatchers`

**الوصف التقني:** 4 dispatchers فقط، بلا أي حالة بصرية دائمة أو تأثير أداء — `moveorexec` (انقل أو نفّذ لو مش موجودة)، `throwunfocused`/`bringallfrom` (نقل نوافذ الـ workspace)، `closeunfocused`. كلها dispatchers تُستدعى فقط عبر `bind =`، مفيش أي "تفعيل دائم" بالمعنى البصري.

**ملاحظة أولوية:** ده الوحيد من الـ 8 اللي **قيمته الحقيقية مرتبطة بالكامل بسؤال منفصل** لسه ما اتفحصش في نطاق هذا التقرير: هل نظام الـ Lua الحالي لـ keybinds (`hyprland/keybinds.lua` / `custom/keybinds.lua`) عنده مكافئ لأي من الأربعة دول أصلاً؟ لو الإجابة "أيوه" فمفيش قيمة تُذكر لتفعيله كـ plugin كامل مقابل dispatcher موجود بالفعل. `dots-integration-audit.md` عمل نفس الملاحظة بالضبط ("يستاهل فحص لو فيه dispatcher معيّن ناقص") — هذا التقرير بيؤكدها كسؤال مفتوح **لسه محتاج فحص فعلي على `keybinds.lua`**، مش إجابة جاهزة.

**Config.qml:**
```qml
property JsonObject xtraDispatchers: JsonObject {
    property bool enabled: false   // تفعيل/تعطيل الـ plugin بس؛ مفيش إعدادات فرعية (dispatchers فقط، لا قيم config)
}
```
**واجهة الإعدادات:** `ConfigSwitch` واحد بلا تفاصيل إضافية — أبسط صف في القائمة كلها تقنيًا، لكن **بدون قيمة عملية فورية للمستخدم إلا لو ربطناه بـ keybind فعلي** في نفس الوقت (يعني التفعيل من الإعدادات لوحده مش كافي — محتاج أيضًا إضافة bind فعلي في `custom/keybinds.lua` أو واجهة الـ Keybinds الموجودة أصلاً في `KeybindsConfig.qml` تستخدم الـ dispatcher الجديد). هذا الربط (توليد bind تلقائي عند التفعيل) قرار تصميم منفصل يستاهل نقاش، مش حل جاهز في هذا المستند.

### 1.8 `csgo-vulkan-fix` — **مُستبعَد من واجهة الإعدادات عمدًا**

**الوصف التقني:** hook لفرض دقة شاشة وهمية على تطبيق مُحدَّد بالضبط (مطابقة `class` حرفية، مش regex) + تصحيح اختياري لموضع الماوس. رغم إن الـ README بيقول "can work with any app, really"، الاستخدام الوحيد الموثّق هو CS2/CS:GO مع `-vulkan` launch option.

**التوصية:** **عدم عرضه في واجهة الإعدادات خالص**، مش حتى كخيار منخفض الأولوية. السبب: هذا مش إعداد "شل سطح مكتب" بأي تعريف — هو حل مشكلة لعبة واحدة بعلامة تجارية محددة. لو حد محتاجه فعليًا، الطريق الصح هو التوثيق (يذكر إنه موجود عبر `hyprpm add` يدويًا خارج الشل) مش صف في `Config.qml`/Settings UI. هذا هو الاستثناء الوحيد من مبدأ "اعرض الـ 8 كلهم" المذكور في وصف المهمة — مذكور بوضوح هنا كقرار واعٍ، مش إغفال.

---

## 2. تصميم قسم "Plugins" الجديد في الإعدادات

### 2.1 القرار: إضافة `ContentSection` جديدة داخل `pages/HyprlandConfig.qml`، مش صفحة منفصلة

`HyprlandConfig.qml` أصلاً **مُسجَّلة بشرط `HORIZONS_WINDOW_MANAGER === "hyprland"`** في `SettingsContent.qml` (السطر ~93: `list.push({ name: Translation.tr("Hyprland"), ..., component: Qt.resolvedUrl("pages/HyprlandConfig.qml") })` جوه بلوك شرطي). بما إن الـ 8 plugins **كلهم حصريًا Hyprland**، إضافة `ContentSection` جديدة داخل نفس الصفحة الموجودة أوفر من صفحة منفصلة (مفيش عنصر تنقّل إضافي في القائمة الجانبية، والشرط الوجودي بالفعل صحيح ومتحقق).

**مكان الإدراج المقترح:** أول `ContentSection` في الملف (قبل `Displays`، حوالي السطر 227) أو آخر واحدة (بعد قسم Animations، حوالي السطر 2861+) — التوصية: **آخر السطر**، لأنها مجموعة اختيارات "متقدمة/تجريبية" منطقيًا تُقرأ بعد الإعدادات الأساسية للـ compositor، مش أول حاجة يشوفها المستخدم.

### 2.2 هيكل QML توضيحي (تصميم، مش كود جاهز للّصق)

```qml
ContentSection {
    icon: "extension"
    shape: MaterialShape.Shape.Clover4Leaf
    title: Translation.tr("Official Plugins (hyprpm)")

    StyledText {
        // بانر تحذير ثابت، مرئي دايمًا مهما كانت الحالة — قسم 3 بيفصّل النص
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Appearance.colors.colOnErrorContainer  // نفس لون التحذيرات الموجود بالفعل في الشل
        text: Translation.tr("Plugins run inside Hyprland's own process. A crash in a plugin can crash your whole session, not just the shell.")
    }

    GroupedList {
        ConfigSwitch {
            buttonIcon: "grid_view"
            text: Translation.tr("hyprexpo — GNOME/KDE-style overview")
            checked: Config.options.hyprland.plugins.hyprexpo.enabled
            onCheckedChanged: PluginManager.setEnabled("hyprexpo", checked)
        }
        // صف تفاصيل يتوسّع فقط لو enabled — نفس نمط "Advanced Monitor Settings"
        // (ContentSubsection مشروط بـ visible) الموجود بالفعل في نفس الملف
        ContentSubsection {
            visible: Config.options.hyprland.plugins.hyprexpo.enabled
            title: Translation.tr("hyprexpo settings")
            GroupedList {
                ConfigSpinBox { text: Translation.tr("Columns"); value: Config.options.hyprland.plugins.hyprexpo.columns; from: 1; to: 10 }
                // ... gap_size, workspace_method, gesture fields
            }
        }
        // ... تكرار لباقي الـ 6 (hyprbars, hyprscrolling, hyprtrails, hyprwinwrap, borders-plus-plus, xtra-dispatchers)
    }
}
```

هذا يستخدم **حصريًا** مكوّنات موجودة فعلاً في `qs.modules.common.widgets` (`ConfigSwitch`, `ConfigSpinBox`, `ConfigComboBox`, `ConfigTextField` — مُتحقَّق منهم بالفعل يُستخدَموا بنفس النمط في باقي `HyprlandConfig.qml`) و`GroupedList`/`ContentSection`/`ContentSubsection` — **صفر مكوّن جديد لازم يُبنى** لواجهة التفعيل نفسها.

### 2.3 الطبقة المفقودة: `PluginManager` — مش مجرد `HyprlandConfig.set()`

هنا الفرق الجوهري بين هذا القسم وكل الأقسام التانية في `HyprlandConfig.qml`: تفعيل `ConfigSwitch` عادي بيستدعي `HyprlandConfig.set(key, value)` وخلاص — القيمة موجودة بالفعل في `hyprland.conf`، بس بنغيّر رقم. **plugin مش مُثبَّت أصلاً** أول مرة، فـ toggle بسيط مش كافي. المطلوب singleton/service جديد (اسم مقترح: `services/HyprlandPlugins.qml`) بمسؤوليات:

1. **فحص حالة أولي:** `hyprctl -j plugin list` (نفس الأمر المُستخدَم بالفعل في `cleanup_hyprglass`) لمعرفة إيه المُحمَّل فعليًا الآن.
2. **عند أول تفعيل لأي plugin:** تشغيل (`Quickshell.Io.Process`، مش `execDetached` — محتاج نلتقط الخروج/الأخطاء، مش نطلقه وننساه) لسلسلة:
   ```
   hyprpm add https://github.com/hyprwm/hyprland-plugins   (idempotent)
   hyprpm enable <plugin-name>
   ```
   ده **بناء فعلي** (compile C++)، ممكن ياخد من ثواني لدقيقة — لازم إشارة تحميل/progress في الـ UI (spinner على الـ `ConfigSwitch` نفسه)، وليس toggle فوري.
3. **عند إلغاء التفعيل:** `hyprpm disable <name>` (سريع، بيحتفظ بالبناء عشان إعادة التفعيل تبقى فورية) — **مش** `hyprpm remove` (ده يمسح البناء بالكامل، لازم يبقى فعل منفصل واعٍ زي "Uninstall build" وليس نتيجة جانبية لإطفاء toggle).
4. **بعد نجاح enable:** استدعاء `HyprlandConfig.set("plugin:<name>:<key>", value)` لكل إعداد فرعي (نفس القناة الموجودة، قسم 0.2) — يعني `PluginManager` بيغلّف `HyprlandConfig` الموجود، مش بديل ليه.
5. **تحميل تلقائي عند بدء التشغيل:** hyprpm بيحتاج استدعاء (`hyprpm reload -n`) عند كل بدء تشغيل لـ Hyprland عشان الإضافات المفعّلة تتحمّل فعليًا (مش بتُحمَّل تلقائيًا لوحدها من نسخة تشغيل لأخرى) — نفس نمط الملف الاختياري `shellOverrides/animations.lua` الموصوف في القسم 0.2، هنا المقترح ملف `shellOverrides/plugins.lua` يحتوي:
   ```lua
   -- DO NOT EDIT — managed by the shell (Settings > Hyprland > Plugins)
   hl.on("hyprland.start", function ()
       hl.exec_cmd("hyprpm reload -n")
   end)
   hl.config({ plugin = { hyprexpo = { columns = 3 } } })
   -- ... باقي مفاتيح الـ plugins المفعّلة فقط
   ```
   وإضافة سطر واحد جديد في `hyprland.lua` بنفس نمط `animations.lua` بالظبط (سطر 48-50 الحالي):
   ```lua
   if is_file_exists(HOME .. "/.config/hypr/hyprland/shellOverrides/plugins.lua") then
       pcall(require, "hyprland.shellOverrides.plugins")
   end
   ```
   الملف بيتولّد فقط لما فيه plugin واحد على الأقل مُفعَّل (غيابه الكامل = لا تغيير سلوك خالص، بالظبط زي `animations.lua` الاختياري حاليًا).

### 2.4 تغييرات `Config.qml` المُجمَّعة

إضافة `JsonObject` واحد جديد `plugins` جوه `hyprland` (جنب `dwindle`/`master`/`group` الموجودين، حوالي السطر 581)، يحتوي الـ 7 (بدون `csgo-vulkan-fix`) sub-objects المفصّلة في القسم 1 أعلاه. الاسم المقترح للجذر: `Config.options.hyprland.plugins.*`.

---

## 3. تقييم المخاطر: عدم توافق الإصدار (version mismatch) وسلوك الـ pinning بتاع hyprpm

### 3.1 آلية الـ pinning الفعلية (من `hyprpm.toml` الحقيقي)

`hyprpm.toml` بيحتوي مصفوفة `commit_pins` — **29 زوج** commit hash، كل زوج هو `[commit في hyprland-plugins, commit مقابل في Hyprland نفسه]`، بيغطوا كل إصدار من 0.37.0 لحد 0.48.1. هذا **ليس توثيقًا تاريخيًا فقط** — هو الآلية اللي `hyprpm` بيستخدمها فعليًا وقت `add`/`update` عشان يقرر **أي commit من مستودع الإضافات يبنيه** بناءً على نسخة Hyprland المُثبَّتة فعليًا وقتها. النتيجة العملية لهذا التصميم:

- لو Hyprland المُثبَّت **نسخة git rolling أحدث من آخر pin مسجَّل** (زي `29e2e59...` المقابل لـ 0.48.1 في آخر السطر) — و`hyprland-plugins` نفسه (كملف محلي هنا) ممكن يكون أقدم من آخر تحديث فعلي على GitHub وقت أي تنفيذ فعلي — `hyprpm` ممكن يفشل في إيجاد pin مطابق، أو يبني ضد commit مش متوافق تمامًا فعليًا.
- الـ README الرئيسي نفسه بيقول صراحة: *"hyprland-plugins follows hyprland-git and requires you to be on hyprland-git or tagged >= v0.33.1"* — يعني **مفيش ضمان استقرار ABI عبر الإصدارات**، والـ upstream نفسه بيتوقع إن المستخدم على نسخة git متابعة أول بأول، مش نسخة تاجد ثابتة قديمة.
- **السيناريو الأخطر عمليًا (وموثّق فعليًا في نفس الكود الحالي):** ترقية عادية لحزمة `hyprland` (زي `pacman -Syu` على Arch، أو أي رول-أوت مستقبلي مشابه لـ `--with-sysupdate` في `installer.sh`) من غير إعادة بناء الإضافات المفعّلة عبر `hyprpm update` — الـ plugin القديم يفضل **محمّل فعليًا في عملية Hyprland الجديدة** وممكن يعمل crash فوري أو سلوك غير متوقع. هذا بالظبط النوع اللي `cleanup_hyprglass()` اتكتبت أصلاً عشان تتعامل معاه بأثر رجعي (تعليقها الفعلي في الكود: *"the compositor keeps a crashy plugin mapped into its own process until it's told to unload"*).

### 3.2 ليه المخاطرة هنا أعلى من أي إعداد Hyprland تاني موجود بالفعل

كل الإعدادات الموجودة حاليًا في `HyprlandConfig.qml` (blur, gaps, dwindle, ...) هي **قيم داخل عملية Hyprland نفسها بمنطق مُختبَر ومُستقر عبر إصدارات كتير** — أسوأ سيناريو فشل هو `option_is_supported()` (الموجودة فعلاً في `hyprconfigurator.py`) بترجع `False` والمفتاح يتمسح بهدوء. أما plugin فهو **كود C++ خارجي مُحمَّل (`dlopen`) جوه نفس عملية الـ compositor** — لو مبني ضد ABI مختلف عن Hyprland الشغال فعليًا، النتيجة المحتملة مش "إعداد اتجاهل بهدوء" — النتيجة **crash لعملية Hyprland كلها**، يعني خروج فوري من الجلسة كاملة (كل النوافذ المفتوحة، مش بس الشل). هذا الفرق الجوهري لازم يكون **واضح جدًا في نص الـ UI نفسه**، مش مجرد ملاحظة في التوثيق.

### 3.3 التصميم المقترح للتواصل مع المستخدم في واجهة الإعدادات

1. **بانر تحذير ثابت** (موصوف في القسم 2.2) ظاهر دايمًا فوق قائمة الـ plugins، بلا شرط — مش رسالة تظهر مرة واحدة وتُنسى.
2. **فحص توافق حي عند فتح القسم:** استدعاء `hyprctl -j plugin list` (تمامًا زي `cleanup_hyprglass`) لعرض حالة كل plugin مُفعَّل فعليًا (محمّل / غير محمّل / كان محمّل وطار — الحالة التالتة دي أخطر حالة ولازم تظهر كتحذير أحمر صريح "Plugin X failed to load — likely a Hyprland version mismatch. Run hyprpm update.").
3. **نفس نمط الفحص المتفائل الموجود بالفعل في `HyprlandData.qml`:** `blurVariantSupported` بيبدأ `true` (تفاؤل افتراضي) وبيتحدَّث بعد استدعاء `hyprctl -j getoption` حقيقي، مع تعليق صريح في الكود: *"a failed/slow hyprctl call never shows a [false negative]"*. **نفس المبدأ بالظبط** لازم يُطبَّق هنا: عدم القدرة على الوصول لـ `hyprctl` (الشل بيشتغل، Hyprland لسه بيقلع، ...) لازم يُعامَل كـ "غير معروف"، **مش** "فشل" — تفاديًا لتحذيرات كاذبة عند كل إعادة تشغيل عادية.
4. **زرار "Rebuild plugins" صريح** (`hyprpm update`) داخل نفس القسم، مش مدفون في التوثيق — يُعرَض بس لو فيه plugin واحد على الأقل مُفعَّل، مع نص يشرح **امتى** يُستخدَم ("بعد أي تحديث لحزمة Hyprland نفسها").
5. **(اختياري، أولوية أقل):** خطاف في مسار `installer.sh update` نفسه — لو `DO_BUILD` أو تحديث نظام حصل ومفيش plugin واحد مُفعَّل على الأقل في `Config.qml`، تشغيل `hyprpm update` تلقائيًا كخطوة صيانة روتينية (زي `cleanup_hyprglass` بالظبط: تشتغل دايمًا بلا شرط طالما فيه شيء لتنظيفه). هذا تحسين لاحق، مش أساسي لـ MVP الأولي.

---

## 4. مسح لباقات/حزم-بناء أخرى (native/compiled) في الشلات التانية غير مغطاة هنا

**تذكير بالنطاق (زي ما اتحدد في وصف المهمة):** البار/الويدجتس في `01-bars-widgets.md`، الأنيميشن في `02-animations.md`، axctl تحديدًا في `03-axctl-fork.md`، الثيمات في `04-theming-presets.md`. الجدول تحت **إشارة سريعة فقط** لأي "حزمة بناء" native تانية لاحظتها في نفس الـ 4 مستودعات المفحوصة، بلا تكرار عمق التقارير التانية:

| المكوّن | من أين | نوعه | ملاحظة نطاق |
|---|---|---|---|
| `axctl` (Go binary) | Ambxst / axctl repo مستقل | daemon IPC مستقل عن أي إطار عمل شل | **مُغطّى بالكامل في `03-axctl-fork.md`** — مذكور هنا للإكمال فقط |
| `caelestia-shell/plugin/*` | caelestia-shell | **QML plugin مُترجَم (C++/Qt6)** — مش Hyprland plugin خالص، ده امتداد Quickshell نفسه (`import Caelestia`) | نوع "حزمة بناء" **مختلف جوهريًا** عن الـ 8 اللي فوق — يستاهل سطر مستقل تحت |
| `ambxst` (Go binary) | Ambxst repo | binary الشل نفسه (daemon يشرف على Quickshell/axctl/wl-paste) | لا ينطبق على Horizons-DE (فريم ورك مختلف كليًا) — مذكور فقط كنمط توزيع (تحت) |
| Ax-Shell (كامل) | Ax-Shell repo | Python+GTK3، بلا أي مكوّن native مُترجَم خالص | خارج نطاق هذا المسح تمامًا — لا يوجد "بناء" بالمعنى المقصود هنا |
| `gray-git` | Ax-Shell `install.sh` | حزمة AUR إضافية تُثبَّت بأمر منفصل (`yes | $aur_helper -Syy --needed --devel --noconfirm gray-git`) | غرضها **غير واضح من `install.sh` وحده** — لا يوجد سياق كافٍ لتحديدها بثقة هنا؛ أولوية فحص منخفضة جدًا نظرًا لعدم وضوح الفائدة أصلاً |

### 4.1 `caelestia-shell/plugin` — نمط بناء مختلف عن كل ما سبق، يستاهل ملاحظة معمارية

`plugin/CMakeLists.txt` بيبني موديول QML **حقيقي مُترجَم** (مش plugin Hyprland) — Qt6 (`Core Qml Gui Quick QuickControls2 Concurrent Sql Network DBus`) + مكتبات نظام خارجية عبر `pkg-config` (`libqalculate`, `libpipewire-0.3`, `aubio`, `cava`/`libcava`). المخرجات: خدمات (`Cpu`/`Memory`/`Storage`/`Gpu`/`NetworkUsage`/`Cava`/`BeatTracker`/...) ومكوّنات (`SparklineItem`, `VisualiserBars`, ...) بيتم استيرادها من QML عبر `import Caelestia` بعد تسجيلها كموديول QML مُترجَم فعليًا.

**ليه ده مهم لهذا التقرير تحديدًا (بناء/تعبئة، مش ميزات):** هذا **مسار توزيع/بناء بديل بالكامل** — بدل QML خالص (نمط Horizons-DE وAmbxst الحاليين)، أو plugin Hyprland (compositor-level، القسم 1)، أو Go daemon منفصل (axctl)، عندنا هنا **رابع نمط**: C++/Qt6 QML extension module مُترجَم يتطلّب Qt6 dev toolchain كامل + `pkg-config` + مكتبات نظام متخصصة (صوت/طاقة/تصور). هذا استثمار هندسي وتوليفة اعتماديات (dependencies) أثقل بكتير من أي حاجة موجودة حاليًا في `installer.sh` (اللي حاليًا أقصى بناء عنده هو Quickshell نفسه، عبر `build_quickshell_step`). **مش مقترح تبنّيه هنا** — فقط توثيق إنه موجود كنمط بديل حقيقي لو احتاج Horizons-DE مستقبلًا مكوّن أداء عالي (زي beat-tracking صوتي حي) يصعب تنفيذه بكفاءة في QML خالص — قرار معماري كبير خارج نطاق "اختيارات Opt-In" المطلوبة هنا.

### 4.2 نمط توزيع `ambxst` (Go binary) — ملاحظة تقنية عابرة، بلا فعل مطلوب

`Ambxst/install.sh` (دالة `download_binary()`) بيحمّل **binary مُصرَّف مسبقًا** (`ambxst-linux-$ARCH`) من GitHub Releases + ملف `SHA256SUMS`، ويتحقق منه (`sha256sum --check`) قبل التثبيت — بديل كامل عن البناء المحلي (اللي متاح كخيار ثانوي فقط عبر `make install` لو المعمارية مش مدعومة). هذا **نمط توزيع مختلف جوهريًا** عمّا يفعله `installer.sh` الحالي (اللي دايمًا إما يبني Quickshell من المصدر محليًا، أو يعتمد على حزمة توزيع جاهزة عبر `pacman`/`dnf` — مفيش نمط "تحميل + تحقق checksum لـ binary مُصرَّف من الريبو نفسه" لأي مكوّن Horizons-DE الخاص حاليًا). مذكور هنا فقط كخيار هندسي محتمل لو Horizons-DE بنى يومًا مكوّن native خاص بيه (زي axctl fork المذكور في `03-axctl-fork.md`) — لا فعل مطلوب الآن.

---

## 5. الأولوية: أي plugin يُعرَض أولًا (من الأعلى قيمة/الأقل خطورة، للأدنى)

| # | Plugin | القيمة | الخطورة | السبب المختصر |
|---|---|---|---|---|
| 1 | `hyprexpo` | عالية | منخفضة | مستقل تمامًا، سهل التبديل بـ bind واحد، ميزة مطلوبة فعليًا من مستخدمين قادمين من GNOME/KDE — التعقيد الوحيد هو التداخل الاختياري مع QML `Overview.qml` الموجود، وده تعقيد UX بسيط (توضيح إنهم بديلان)، مش تعقيد تقني |
| 2 | `hyprwinwrap` | عالية | متوسطة | مذكور بالفعل كبديل محتمل حقيقي لآلية `mpvpaper` في تدقيق سابق؛ الخطورة متوسطة بسبب حساسية التوقيت الموثّقة في مثال الـ README نفسه (`sleep` قبل `cava`) |
| 3 | `borders-plus-plus` | متوسطة | منخفضة جدًا | تجميلي بحت، بلا حالة ديناميكية، امتداد طبيعي لإعدادات الحدود الموجودة بالفعل في نفس الصفحة |
| 4 | `xtra-dispatchers` | غير محدَّدة بعد | منخفضة | تقنيًا آمن تمامًا (dispatchers بلا حالة)، لكن قيمته الفعلية معلّقة على فحص لم يتم بعد لـ `keybinds.lua` الحالي — **قرار الأولوية الحقيقي مؤجَّل لحين هذا الفحص** |
| 5 | `hyprbars` | منخفضة عمدًا | منخفضة (تقنيًا) | خطورة UX (ازدواج chrome) أعلى من الخطورة التقنية؛ يبقى Opt-In مُطفَأ افتراضيًا لفئة ضيقة من المستخدمين |
| 6 | `hyprscrolling` | مشروطة | عالية | الـ upstream نفسه يصنّفه WIP + بيستبدل التخطيط بالكامل؛ يستاهل التفعيل لكن بأقل استثمار UI ممكن (تحذير واضح، بلا صقل إضافي) لحين نضج الـ plugin |
| 7 | `hyprtrails` | منخفضة جدًا | متوسطة (أداء) | حتى المطورين وصفوه "useless"؛ تكلفة render حقيقية موثّقة ذاتيًا |
| 8 | `csgo-vulkan-fix` | لا تنطبق | لا تنطبق | **مُستبعَد من واجهة الإعدادات كليًا** (قسم 1.8) — خارج نطاق شل سطح مكتب من أساسه |

**خلاصة الأولوية للتنفيذ الفعلي (لو هتتنفّذ على مراحل):** ابدأ بـ `hyprexpo` + `borders-plus-plus` كـ proof-of-concept لآلية `PluginManager`/`hyprpm add`/`enable` الموصوفة في القسم 2.3 (أبسط اتنين تقنيًا، أوضح قيمة فورية) — لو الآلية اشتغلت صح معاهم، باقي الـ 5 (عدا `csgo-vulkan-fix` المُستبعَد) إضافة تكرارية بنفس القالب، مش إعادة هندسة.

---

## المصادر
- `/g/dotfiles/hyprland-plugins/README.md`, `hyprpm.toml`, وملفات `README.md` الفردية لكل الـ 8 plugins
- `G:\End4-PXpC\installer.sh` (`--launchers`/`install_launchers()`, `--components`, `confirm()`, `cleanup_hyprglass()`)
- `G:\End4-PXpC\shell\services\HyprlandConfig.qml`, `G:\End4-PXpC\shell\scripts\hyprland\hyprconfigurator.py`
- `G:\End4-PXpC\shell\services\HyprlandData.qml` (نمط `blurVariantSupported`)
- `G:\End4-PXpC\shell\modules\common\Config.qml` (سطر ~343-620، هيكل `hyprland.*`)
- `G:\End4-PXpC\shell\modules\ii\settings\pages\HyprlandConfig.qml`, `SettingsContent.qml`
- `G:\End4-PXpC\shell\modules\common\widgets\{ConfigSwitch,ContentSection,GroupedList,ContentPage}.qml`
- `G:\End4-PXpC\dotfiles\dots\.config\hypr\hyprland.lua`, `hyprland/execs.lua`, `hyprland/shellOverrides/main.lua`
- `G:\End4-PXpC\dotfiles\sdata\dist-arch\illogical-impulse-{hyprland,widgets}\PKGBUILD`
- `G:\End4-PXpC\docs\dots-integration-audit.md`, `G:\End4-PXpC\docs\quickshell-competitor-audit.md`
- `/g/dotfiles/Ax-Shell/install.sh`, `/g/dotfiles/Ambxst/{flake.nix,Makefile,install.sh}`, `/g/dotfiles/caelestia-shell/{CMakeLists.txt,flake.nix,plugin/CMakeLists.txt}`, `/g/dotfiles/axctl/go.mod`

---

*هذا المستند نتيجة عمل 5 subagents متوازية بتاريخ 2026-09-05، دُمجت في ملف واحد. المصادر الخارجية (Ax-Shell, Ambxst, caelestia-shell, axctl, hyprland-plugins) محلية على جهاز المستخدم ومش جزء من هذا الـ repo.*
