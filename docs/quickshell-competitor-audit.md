# تدقيق عميق: مقارنة Horizons-DE بثلاث شِلّات (Ax-Shell + Ambxst + caelestia-shell)

**تاريخ:** 2026-09-05
**المصادر:** فحص كود مباشر لثلاث نسخ محلية حمّلها المستخدم:
- `/g/dotfiles/Ax-Shell` — الأصل التاريخي، **متوقف رسميًا** (الـ README نفسه بيوجّه لـ Ambxst)، ومبني على تقنية مختلفة تمامًا عن الباقي: **Python + GTK3 (إطار عمل Fabric)**، مش QML/Quickshell خالص.
- `/g/dotfiles/Ambxst` — خليفة `Ax-Shell` الرسمي (إعادة كتابة كاملة بـ QML/Quickshell).
- `/g/dotfiles/caelestia-shell` — شل Quickshell مستقل معروف ومستقر (مش من نفس عائلة Ax-Shell/Ambxst).
- `/g/dotfiles/hyprland-plugins` — مستودع Hyprland الرسمي للـ plugins (هيتغطى في مرحلة الـ dots القادمة، مش هنا).

**ملاحظة مهمة:** التلاتة دول **مش جزء من هذا الـ repo** — مجرد checkouts محلية للدراسة/المقارنة، فمفيش أي كود منهم هيتنسخ حرفيًا بدون مراجعة ترخيص (كلهم GPL-family على الأغلب، لازم مراجعة الترخيص الفعلي قبل أي نقل كود حرفي — الأفكار المعمارية نفسها مفيهاش مشكلة ترخيص، بس الكود الحرفي ممكن يبقى فيه).

**ليه Ax-Shell مهم رغم إنه متوقف:** بيوضّح بالظبط إيه اللي Ambxst *ورثه*، إيه اللي *طوّره*، وإيه اللي *أسقطه* بالكامل وقت إعادة الكتابة لـ QML — ومقارنة إطار عمل مختلف كليًا (Python/GTK3 مقابل QML/Quickshell) بتدّي زاوية مفيدة لوحدها، مش بس كنسخة قديمة.

هذا الجزء الأول من التدقيق (الشِلّات نفسها). الـ dots (Hyprland configs المرفقة مع كل شل + `hyprland-plugins`) هتتغطى في مستند منفصل بعد كده.

---

## 0. Ax-Shell: تقنية مختلفة تمامًا (Python + GTK3 + Fabric)

قبل أي مقارنة تفصيلية، الفرق الجوهري: Ax-Shell مش QML خالص — `main.py` بيستورد `from fabric import Application` (إطار عمل Python لبناء شلّات Wayland فوق GTK)، والويدجتس نفسها GTK3 widgets (`gi.require_version("Gtk", "3.0")`) مع `gtk-layer-shell` لدعم الـ layer-shell بروتوكول، والتنسيق عبر CSS حقيقي (`main.css`) بدل QML property bindings.

**إيه اللي مميز فيه لوحده (ولسه مالوش مكافئ في Ambxst ولا caelestia ولا Horizons-DE):**
- **`modules/kanban.py`** — لوحة Kanban كاملة (أعمدة/بطاقات قابلة للسحب، تخزين JSON محلي) كويدجت داخل الشل نفسه. Ambxst أسقطها بالكامل وقت إعادة الكتابة — مش موجودة في أي حاجة تانية اتفحصت.
- **`modules/cavalcade.py`** — تكامل مباشر مع `cava` عبر قراءة ملفه الإعدادي (`configparser`) واستخراج عدد الأعمدة (`get_bars`)، مع تحليل بيانات ثنائية خام (`struct`/`ctypes`) بدل تحليل نصي سطر-بسطر بسيط — نوع تكامل أعمق من مجرد "شغّل cava واقرأ الإخراج".
- **`services/monitor_focus.py`** — خدمة مخصصة لتتبع أي مونيتور عليه الفوكس حاليًا (منفصلة عن باقي خدمات الـ compositor).

**إيه اللي Ambxst طوّره فوقه (تأكيد، مش تخمين):** نظام presets الكامل (theme.json بمواصفات gradient/halftone) **جديد بالكامل** — مفيش أي حاجة شبهه في Ax-Shell. الـ notch/dashboard الموحّد اتوسّع بشكل كبير (Ax-Shell's `notch.py` سطوره 1446 بايثون مقابل معمارية QML مقسّمة على عدة ملفات في Ambxst).

**اكتشاف أداء عملي وقابل للتطبيق فورًا في Horizons-DE:** `modules/metrics.py` بيستخدم **`psutil`** (مكتبة بايثون ناضجة ومُسرَّعة بـ C) لقراءة CPU/الذاكرة/القرص/الشبكة — **صفر استدعاء subprocess** لأي من دول (بس GPU لسه عبر `subprocess.check_output(["nvtop", "-s"])` لأنه مفيش بديل بايثون خالص عملي). ده وسط بين أسلوب Horizons-DE الحالي (bash + Process لكل حاجة) وأسلوب caelestia (C++ plugin كامل، قسم 5) — تكلفة تنفيذه أقل بكتير من بناء plugin C++، ومكسب أداء حقيقي (تفادي spawn عملية فرعية لكل نبضة polling).

---

## 1. نظرة معمارية عامة على كل شل

### 1.1 Ax-Shell (Python/GTK3/Fabric)
- `widgets/wayland.py` بيغلّف `GtkLayerShell` مباشرة (Layer enum: Background/Bottom/Top/Overlay) — طبقة تجريد رفيعة جدًا فوق بروتوكول الـ layer-shell نفسه، على عكس Quickshell اللي بيوفر `PanelWindow`/`WlrLayershell` كنوع QML جاهز.
- مفيش أي فصل بين حجز المساحة والنافذة المرئية (النمط اللي هيتكرر في Ambxst وcaelestia) — الأسلوب أقرب لـ "كل موديول عنده نافذته الخاصة" زي Horizons-DE الحالي بالظبط.
- **مفيش شاشة قفل/دخول خاصة به خالص** — مفيش `lockscreen`/`lock` module في القائمة كاملة. الاعتماد على `hyprlock`/أداة خارجية مفترض.

### 1.2 Ambxst
- QML خالص 100% — مفيش أي كود native (C++) خالص.
- **نافذة واحدة موحّدة لكل شاشة** (`UnifiedShellPanel.qml`): `PanelWindow` واحدة بتاخد الشاشة كلها (`anchors: top/bottom/left/right: true`)، طبقة `Overlay`، `exclusionMode: Ignore`. البار والـ dock والـ notch والـ sidebar كلهم عناصر QML عادية *جوه* النافذة دي، مش نوافذ منفصلة.
- **حجز المساحة (exclusiveZone) منفصل تمامًا** عن النوافذ المرئية: 4 نوافذ صغيرة شفافة عديمة التفاعل (`ReservationWindows.qml`، واحدة لكل حافة شاشة) بتحسب المساحة المطلوبة (بار + dock + frame + sidebar مجمّعين) وتحجزها بس، بلا أي محتوى مرئي أو تفاعل.
- نظام **presets** كامل: 8+ ثيمات جاهزة (`assets/presets/*/theme.json`) بتغيّر مش بس الألوان لكن الـ gradient/halftone/shadow لكل سطح في الواجهة.
- ملفات `AGENTS.md` داخل كل موديول (bar/lockscreen/widgets/...) — توثيق معماري مُوجَّه لأدوات الـ AI تحديدًا، حاجة Horizons-DE معندهوش حاليًا غير ملفات التوثيق العامة.

### 1.3 caelestia-shell
- **QML + C++ plugin أصلي** (`plugin/src/Caelestia/*`) — استثمار هندسي أعمق بكتير. الموديولات الأصلية: `Config` (نظام إعدادات وtokens أنيميشن)، `Services` (Cpu/Memory/Storage/Gpu/NetworkUsage/Lyrics/Cava/BeatTracker/SessionManager...)، `Components` (LazyListView, SparklineItem, VisualiserBars, WavyLine, CircularIndicatorManager...)، `Images`، `Models`، `Blobs` (shaders).
- **كل بانل/درج له `PanelWindow` منفصلة** لكن كلها مبنية من نوع أساسي واحد مشترك (`StyledWindow.qml`) بدل ما كل ملف يكرر إعداد `WlrLayershell`/`anchors`/`color` بنفسه.
- الـ `Config`/`Tokens` (من الـ plugin) **واعية بالشاشة نفسها** (`contentItem.Config.screen: screen.name`) — يعني ممكن تفرق القيم لكل مونيتور.
- بار عمودي (جانبي) افتراضيًا، بيتوسّع بالـ hover، مش بار أفقي تقليدي.

**الخلاصة المعمارية:** Ax-Shell وHorizons-DE بيتشاركوا نفس النمط (كل موديول يدير نافذته بنفسه، بلا فصل حجز/عرض). Ambxst وcaelestia الاتنين حلّوا مشكلة الفصل ده لكن بطريقتين مختلفتين — Ambxst بنافذة واحدة كبيرة + محتوى شرطي جواها، caelestia بنوافذ منفصلة صغيرة بس مبنية من قاعدة مشتركة وبتتدمّر فعليًا (مش بس تتخفى) لما مش محتاجينها.

---

## 2. البار (Bar)

| | Ax-Shell | Ambxst | caelestia-shell | Horizons-DE (الوضع الحالي) |
|---|---|---|---|---|
| البنية | `modules/bar.py` (627 سطر بايثون) | `BarContent.qml` (767 سطر) جوه النافذة الموحّدة | `Bar.qml` + `BarWrapper.qml` (291 سطر مجمّعة)، بار عمودي قابل للتوسّع | ملفات منفصلة لكل وضع (`Bar.qml`, `MesoBar.qml`, `VerticalBar.qml`, `SysmonitorBar.qml`, `TasklistBar.qml`) |
| Auto-hide | `hide_timer`/`hide_revealer` (GLib.timeout_add) | `reveal` property + `hideDelayTimer` في `BarContent.qml` | `shouldBeVisible` computed property + `isHovered`، والمحتوى نفسه بيتحمّل/يتشال بالكامل (`Loader { active: shouldBeVisible }`) | `Config.options.bar.autoHide` موجود لكن المحتوى فاضل موجود دايمًا، بس مخفي |
| تكامل الـ dock | منفصل (`modules/dock.py`) | `IntegratedDock.qml` — الدوك ممكن يندمج جوه البار نفسه كمكوّن واحد | منفصل | منفصل (`Dock.qml`) |
| تعدد الشاشات | — | `Config.bar.screenList` (فلترة صريحة) | `Strings.testRegexList(Config.bar.excludedScreens, screen.name)` (استبعاد بـ regex) | موجود جزئيًا عبر أنماط مختلفة لكل بار |

**نقطة قابلة للتطبيق مباشرة في Horizons-DE:** فصل حجز المساحة (exclusiveZone) عن النافذة المرئية للبار (زي القسم 1) هيحل فئة كاملة من الأخطاء المحتملة (سباقات التهيئة، تعارض القيم وقت التحريك/auto-hide) اللي Ambxst صراحة كتب تعليق عنها كسبب التصميم.

---

## 3. الـ Widgets

### Ax-Shell
كل الويدجتس الأساسية موجودة (bar/dock/notch/dashboard/launcher/notifications/overview/emoji/wallpapers/weather/mixer/network/bluetooth/tmux/pins/tools/updater) — تقريبًا نفس قائمة Ambxst الوظيفية، **زائد Kanban** اللي اتسقطت بعدين (قسم 0).

### Ambxst
مجموعة **ضخمة جدًا** من الويدجتس، أعمق بكتير من أي حاجة موجودة في Horizons-DE حاليًا:
- **Dashboard** شامل بتابات: Clipboard, Audio Mixer (per-app!), Bluetooth, WiFi, Color Picker (مع Gradient Stops Editor!), EasyEffects panel, Emoji picker, Metrics (موارد النظام مع رسم بياني)، **Notes** (مع utils خاصة بالـ markdown/تخزين)، **Tmux tab** (إدارة جلسات tmux من داخل الشل!)، Wallpapers (مع دعم فيديو wallpaper عبر mpv + shader استخراج لوحة الألوان `palette.frag`).
- **Presets system**: تبديل ثيم كامل (مش بس لون) بضغطة واحدة — جديد بالكامل، مش موروث من Ax-Shell.
- **Settings Crawler** (`SettingsCrawler.js`) — بيدور جوه شجرة الإعدادات نفسها ديناميكيًا (مشابه تمامًا لميزة "بحث الإعدادات" اللي اتعملت في Horizons-DE هذه الجلسة، لكن كأداة عامة بتفحص الشجرة أوتوماتيكيًا بدل فهرس مبني يدويًا).
- Pomodoro timer **مدمج في الساعة نفسها في البار**.

### caelestia-shell
أقل عددًا في الويدجتس لكن **أعمق تقنيًا** في اللي موجود:
- Sparkline/Wavy-line/Circular indicators **مُرسومة native** (C++ `QQuickItem` مخصصة) بدل QML Shape/Canvas — أداء أعلى بكتير لأي حاجة بتتحدّث كل فريم (زي visualizer الصوت).
- Beat-tracking حقيقي للموسيقى (`beattracker.cpp`) — مش مجرد قراءة مستوى الصوت، فيه اكتشاف إيقاع فعلي (لأي أنيميشن يرقص مع الموسيقى مثلاً).
- Lyrics service أصلي (C++) بدل سكربت بايثون خارجي.

**مقارنة بـ Horizons-DE:** الويدجتس الموجودة في Horizons-DE (background widgets: clock/weather/calendar/todo/notes/...) تنافسية عدديًا مع caelestia لكن أقل بكتير من Ambxst/Ax-Shell (خصوصًا: مفيش clipboard-history-as-dashboard-tab، مفيش audio mixer per-app، مفيش tmux integration، مفيش color-picker بـ gradient editor، مفيش kanban).

---

## 4. شاشة القفل/الدخول (Lock/Login)

### الاكتشاف الأهم في كل هذا التدقيق: `Quickshell.Services.Pam`

**caelestia-shell** (`modules/lock/Pam.qml`) بيستخدم موديول **رسمي من Quickshell نفسه** اسمه `Quickshell.Services.Pam` — بيوفر نوعين:
- `PamContext` — يكلّم PAM مباشرة (مفيش subprocess، مفيش sudo) لمصادقة كلمة السر (`config: "passwd"`، مع `configDirectory` مخصص لملف pam.d خاص بيهم مرفق مع الشل نفسه — مش معتمدين على `/etc/pam.d/passwd` الجاهز في التوزيعة).
- `ManualPamContext` (مكوّن مبني فوقه في نفس الملف) — لطرق المصادقة البديلة: `config: "howdy"` و `config: "fprint"`، كل واحدة عندها `availCommand` (بيتشيّك هل المصادقة دي متاحة أصلاً قبل أي محاولة: `command -v howdy` / `fprintd-list $USER`)، `maxTries` قابل للإعداد، وربط بحالة الجهاز (`onResumed` بيحاول howdy تلقائي لما الجهاز يصحى لو مفعّل `triggerHowdyOnWake`).

**ليه ده مهم لـ Horizons-DE تحديدًا:** في وقت سابق من هذه الجلسة، اتصلح باگ صلاحيات تنفيذ ملف `face-auth.sh`، لكن اتسجّل (بدون حل) إن **howdy نفسه مش مُعلَن كـ dependency، ومفيش إعداد sudoers/passwordless-sudo لـ `sudo howdy test`** — يعني حتى بعد إصلاح صلاحيات الملف، الميزة لسه محتاجة sudo تفاعلي كل مرة، وهو بالظبط نوع المشكلة اللي `Quickshell.Services.Pam` بيحلّها جذريًا: **مفيش sudo خالص** — الاتصال بـ PAM مباشر من داخل Quickshell، بنفس الطريقة اللي أي `login`/`sudo`/`gdm` بيستخدموها. ده أعمق بكتير وأصح تقنيًا من أي سكربت shell بيعمل `sudo howdy test`.

### باقي مقارنة شاشة القفل

| | Ax-Shell | Ambxst | caelestia-shell | Horizons-DE |
|---|---|---|---|---|
| موجودة أصلاً؟ | **لا** — مفيش lockscreen module خالص | نعم | نعم | نعم |
| المصادقة | (خارجي، غالبًا hyprlock) | `ambxst-auth` (ملف تنفيذي مُجمّع مرفق — لسه محتاج فحص أعمق لمعرفة هل بيستخدم PAM مباشر أو helper خارجي) | `Quickshell.Services.Pam` مباشرة (الأنظف) | سكربت bash بينادي `howdy`/`sudo` |
| مكوّنات الواجهة | — | ساعة، معلومات مستخدم، لاعب وسائط مصغّر | `Center.qml`/`Content.qml` منفصلين، طقس (`weather/`)، إشعارات مُجمّعة (`NotifGroup.qml` — 343 سطر، متقدم)، موارد النظام حية (`Resources.qml`) | ساعة، وسائط، توزيع عناصر مستقل لكل عنصر (بعد تعديل هذه الجلسة) |
| الطقس | — | نعم (Clock.qml بيتضمنه) | نعم (`weather/BriefInfo.qml` + `Forecast.qml` — توقعات ممتدة مش بس الحالة الحالية) | لا يوجد widget طقس في شاشة القفل حاليًا |

---

## 5. الأداء (Performance)

### أهم فرق: قراءة موارد النظام

| | الطريقة |
|---|---|
| Horizons-DE | `Process` + سطر bash (`top`/`free`/`df` أو مشابه) على `Timer` كل بضع ثواني — تكلفة spawn عملية فرعية جديدة كل مرة |
| Ax-Shell | **`psutil`** (بايثون، بلا subprocess) للـ CPU/Memory/Disk/Network؛ GPU لسه عبر `subprocess` (nvtop) لعدم وجود بديل عملي |
| Ambxst | نفس أسلوب Horizons-DE تقريبًا (QML/bash)، مفيش كود native |
| caelestia-shell | خدمات **C++ أصلية** (`cpu.cpp`, `memory.cpp`, `storage.cpp`, `gpu.cpp`) بتقرأ `/proc`/`/sys` مباشرة من غير أي subprocess خالص، ومربوطة بنمط **مرجعية استخدام** (`ServiceRef { service: Cpu }`) — يعني الخدمة نفسها بس "شغالة" (polling) لما حد فعلاً بيعرضها على الشاشة، مش دايمًا |

ملاحظة: Ax-Shell عمليًا بيوضّح إن فيه **درجة وسطى** بين "bash لكل حاجة" و"C++ plugin كامل" — لو Horizons-DE مستقبلاً حاب يستخدم بايثون في أي سكربت مشابه (زي `thumbgen.py`/`hyprconfigurator.py` الموجودين أصلاً)، `psutil` بديل رخيص التنفيذ نسبيًا لقراءة CPU/Memory/Disk بلا أي subprocess.

### الـ Lazy Loading
- caelestia: **77** استخدام لـ `asynchronous: true` عبر الكود — شبه كل `Loader` تقريبًا. الأدراج (drawers) نفسها كنوافذ منفصلة بتتدمّر فعليًا (`active: false` على الـ Loader اللي بيستضيف المحتوى) لما مش ظاهرة، مش مجرد `visible: false`.
- Ambxst: **17 من 34** Loader بس معلَّمة `asynchronous: true` (~50%).
- Horizons-DE: بعد إصلاحات هذه الجلسة (صفحات الإعدادات) أصبح عندها نفس الانضباط في مكان واحد على الأقل، لكن مفيش نمط عام مُطبَّق في كل الشل زي caelestia.

### الأنيميشن ذات التكلفة العالية
- Ambxst: بار متحرك بشدة (Behavior على x/y/width/height/opacity/rotation/color في ملف واحد بس) — تكلفة GPU أعلى وقت auto-hide/reveal، خصوصًا مع `implicitHeight: 200` (نافذة أكبر من المحتوى الفعلي عشان تسع الحركة، مع `mask: Region` عشان الماوس ميتأثرش بالمساحة الزيادة — تقنية سليمة، بس التكلفة الأساسية (حركة مستمرة) موجودة).
- caelestia: حركة أقل عددًا لكن كل حركة بتاخد duration/easing من نظام tokens مركزي واحد (قسم 6) بدل قيم متفرقة.

---

## 6. الأنيميشن (نظام التوكِنز — أهم اكتشاف في هذا القسم)

**caelestia-shell**'s `Anim.qml` — مكوّن `NumberAnimation` واحد قابل لإعادة الاستخدام، بـ enum فيه 14 "نوع حركة" مطابق حرفيًا لمواصفة **Material Design 3 Expressive Motion** الرسمية:
```
StandardSmall/Standard/StandardLarge/StandardExtraLarge
EmphasizedSmall/Emphasized/EmphasizedLarge/EmphasizedExtraLarge
FastSpatial/DefaultSpatial/SlowSpatial
FastEffects/DefaultEffects/SlowEffects
```
أي حركة في أي مكان في الكود بتكتب `Anim { type: Anim.EmphasizedLarge }` وتاخد المدة والـ easing الصح تلقائيًا من مصدر واحد (`Tokens.anim.*`، محسوبة في الـ plugin الأصلي). صفر تكرار لقيم المنحنيات في أي ملف widget.

**مقابل Horizons-DE:** `Appearance.qml`'s `animation` object فيه مجموعة مسميات خاصة بالمشروع (`elementMove`, `elementMoveSmall`, `elementMoveFast`, `elementResize`, `clickBounce`, `scroll`, `menuDecel`, `sidebarSlideEnter/Exit`) — مش مبنية على تصنيف رسمي موحّد، فأي حركة جديدة محتاجة قرار يدوي "أي واحدة من دول أقرب لها" بدل تصنيف مباشر بالغرض (spatial/effects) والحجم (small/default/large). النظام شغال وبيتوسّع بالـ `motionDurationScale` (اتفحص وأُصلح جزء منه هذه الجلسة)، لكن أقل انتظامًا من نظام caelestia.

كمان لاحظ `AnimLoader.qml` (قسم منفصل، caelestia) — مكوّن عام لعمل fade-out/swap-content/fade-in لأي `Loader` بضبطه مرة واحدة، بدل ما كل مكان يحتاج يبني transition خاص بيه.

**مقابل Ax-Shell:** بايثون/GTK مالوش نظام tokens مركزي للحركة — الحركة في Fabric غالبًا عبر CSS transitions (`main.css`) أو `GLib.timeout_add` يدوي لكل حالة، أقل مركزية حتى من Horizons-DE الحالي.

---

## 7. توصيات مرتّبة بالأولوية لـ Horizons-DE

1. **الأعلى قيمة والأقل خطورة:** فحص `Quickshell.Services.Pam` (القسم 4) كبديل لسكربت `face-auth.sh`/`howdy` الحالي — بيحل مشكلة الـ sudoers المؤجلة من هذه الجلسة جذريًا. يحتاج تأكيد إن هذا الموديول متاح في نسخة Quickshell المبنية هنا (نفس نوع الفحص اللي اتعمل لـ `Quickshell.I3` في تدقيق i3 السابق).
2. **فصل حجز المساحة (exclusiveZone) عن النوافذ المرئية** (نمط Ambxst's `ReservationWindows.qml` أو caelestia's per-window لكن مع نافذة حجز منفصلة) — يقلل مخاطر سباقات التهيئة في أي بار/سايدبار مستقبلي.
3. **قراءة موارد النظام بلا subprocess عبر خطوة وسط رخيصة:** لو أي سكربت بايثون موجود أصلاً هيتلمس (زي `thumbgen.py`)، استخدام `psutil` (نمط Ax-Shell) لأي قراءة CPU/Memory/Disk جديدة أرخص بكتير من الالتزام ببناء C++ plugin كامل زي caelestia، مع مكسب أداء حقيقي.
4. **توحيد نظام الأنيميشن حول تصنيف صريح** (زي M3 Expressive tokens بتاعة caelestia) بدل الأسماء المخصصة الحالية — تحسين تدريجي، مش لازم يتغير الكود الحالي، بس أي إضافة جديدة تتصنّف بالمعيار الجديد.
5. **قراءة موارد النظام (CPU/Memory/GPU) الكاملة بدون subprocess عبر C++ native** — استلهام من caelestia's native services، استثمار أكبر بكتير من البند 3، يحتاج C++ plugin فعلي.
6. **ميزات للنظر فيها (أقل إلحاحًا، لكن قيمتها واضحة للمستخدم):** clipboard كـ tab في الـ dashboard بدل launcher منفصل بس (Ambxst)، color picker بمحرر gradient (Ambxst)، نظام presets كامل لتبديل الثيم الشامل (Ambxst)، لوحة Kanban كويدجت (Ax-Shell، أُسقطت من الخلف عمدًا لكن ممكن تتفحص كفكرة منفصلة).

---

## المصادر
- `/g/dotfiles/Ax-Shell` (محلي، متوقف رسميًا)
- `/g/dotfiles/Ambxst` (محلي)
- `/g/dotfiles/caelestia-shell` (محلي)
- ملفات AGENTS.md المرفقة داخل كل مشروع (توثيق معماري ذاتي)
