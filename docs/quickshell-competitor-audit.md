# تدقيق عميق: مقارنة Horizons-DE بأفضل شِلَّين Quickshell (Ambxst + caelestia-shell)

**تاريخ:** 2026-09-05
**المصادر:** فحص كود مباشر لنسختين محليتين حمّلهما المستخدم:
- `/g/dotfiles/Ambxst` — خليفة `Ax-Shell` (المتوقف رسميًا، الـ README بتاعه بيوجّه صراحة لـ Ambxst).
- `/g/dotfiles/caelestia-shell` — شل Quickshell معروف ومستقر.
- `/g/dotfiles/hyprland-plugins` — مستودع Hyprland الرسمي للـ plugins (هيتغطى في مرحلة الـ dots القادمة، مش هنا).

**ملاحظة مهمة:** الملفين دول **مش جزء من هذا الـ repo** — مجرد checkouts محلية للدراسة/المقارنة، فمفيش أي كود منهم هيتنسخ حرفيًا بدون مراجعة ترخيص (Ambxst و caelestia-shell الاتنين GPL-family على الأغلب، لازم مراجعة الترخيص الفعلي قبل أي نقل كود حرفي — الأفكار المعمارية نفسها مفيهاش مشكلة ترخيص، بس الكود الحرفي ممكن يبقى فيه).

هذا الجزء الأول من التدقيق (الشِلّات نفسها). الـ dots (Hyprland configs المرفقة مع كل شل + `hyprland-plugins`) هتتغطى في مستند منفصل بعد كده.

---

## 1. نظرة معمارية عامة على كل شل

### 1.1 Ambxst
- QML خالص 100% — مفيش أي كود native (C++) خالص، عكس caelestia.
- **نافذة واحدة موحّدة لكل شاشة** (`UnifiedShellPanel.qml`): `PanelWindow` واحدة بتاخد الشاشة كلها (`anchors: top/bottom/left/right: true`)، طبقة `Overlay`، `exclusionMode: Ignore`. البار والـ dock والـ notch والـ sidebar كلهم عناصر QML عادية *جوه* النافذة دي، مش نوافذ منفصلة.
- **حجز المساحة (exclusiveZone) منفصل تمامًا** عن النوافذ المرئية: 4 نوافذ صغيرة شفافة عديمة التفاعل (`ReservationWindows.qml`، واحدة لكل حافة شاشة) بتحسب المساحة المطلوبة (بار + dock + frame + sidebar مجمّعين) وتحجزها بس، بلا أي محتوى مرئي أو تفاعل.
- نظام **presets** كامل: 8+ ثيمات جاهزة (`assets/presets/*/theme.json`) بتغيّر مش بس الألوان لكن الـ gradient/halftone/shadow لكل سطح في الواجهة.
- ملفات `AGENTS.md` داخل كل موديول (bar/lockscreen/widgets/...) — توثيق معماري مُوجَّه لأدوات الـ AI تحديدًا، حاجة Horizons-DE معندهوش حاليًا غير ملفات التوثيق العامة.

### 1.2 caelestia-shell
- **QML + C++ plugin أصلي** (`plugin/src/Caelestia/*`) — استثمار هندسي أعمق بكتير. الموديولات الأصلية: `Config` (نظام إعدادات وtokens أنيميشن)، `Services` (Cpu/Memory/Storage/Gpu/NetworkUsage/Lyrics/Cava/BeatTracker/SessionManager...)، `Components` (LazyListView, SparklineItem, VisualiserBars, WavyLine, CircularIndicatorManager...)، `Images`، `Models`، `Blobs` (shaders).
- **كل بانل/درج له `PanelWindow` منفصلة** لكن كلها مبنية من نوع أساسي واحد مشترك (`StyledWindow.qml`) بدل ما كل ملف يكرر إعداد `WlrLayershell`/`anchors`/`color` بنفسه.
- الـ `Config`/`Tokens` (من الـ plugin) **واعية بالشاشة نفسها** (`contentItem.Config.screen: screen.name`) — يعني ممكن تفرق القيم لكل مونيتور.
- بار عمودي (جانبي) افتراضيًا، بيتوسّع بالـ hover، مش بار أفقي تقليدي.

**الخلاصة المعمارية:** الاتنين بيحلّوا نفس المشكلة (حجز المساحة منفصل عن النافذة المرئية) لكن بطريقتين مختلفتين — Ambxst بنافذة واحدة كبيرة + محتوى شرطي جواها، caelestia بنوافذ منفصلة صغيرة بس مبنية من قاعدة مشتركة وبتتدمّر فعليًا (مش بس تتخفى) لما مش محتاجينها. **Horizons-DE حاليًا مالوش أي من الاتنين** — كل بار/سايدبار عنده `PanelWindow` مستقلة تمامًا بتحسب `exclusiveZone` بنفسها، وموجودة دايمًا حتى لو مخفية.

---

## 2. البار (Bar)

| | Ambxst | caelestia-shell | Horizons-DE (الوضع الحالي) |
|---|---|---|---|
| البنية | `BarContent.qml` (767 سطر) جوه النافذة الموحّدة | `Bar.qml` + `BarWrapper.qml` (291 سطر مجمّعة)، بار عمودي قابل للتوسّع | ملفات منفصلة لكل وضع (`Bar.qml`, `MesoBar.qml`, `VerticalBar.qml`, `SysmonitorBar.qml`, `TasklistBar.qml`) |
| Auto-hide | `reveal` property + `hideDelayTimer` في `BarContent.qml` | `shouldBeVisible` computed property + `isHovered`، والمحتوى نفسه بيتحمّل/يتشال بالكامل (`Loader { active: shouldBeVisible }`) | `Config.options.bar.autoHide` موجود لكن المحتوى فاضل موجود دايمًا، بس مخفي |
| تكامل الـ dock | `IntegratedDock.qml` — الدوك ممكن يندمج جوه البار نفسه كمكوّن واحد | منفصل | منفصل (`Dock.qml`) |
| تعدد الشاشات | `Config.bar.screenList` (فلترة صريحة لأي شاشات تظهر فيها) | `Strings.testRegexList(Config.bar.excludedScreens, screen.name)` (استبعاد بـ regex) | موجود جزئيًا عبر أنماط مختلفة لكل بار |

**نقطة قابلة للتطبيق مباشرة في Horizons-DE:** فصل حجز المساحة (exclusiveZone) عن النافذة المرئية للبار (زي القسم 1) هيحل فئة كاملة من الأخطاء المحتملة (سباقات التهيئة، تعارض القيم وقت التحريك/auto-hide) اللي Ambxst صراحة كتب تعليق عنها كسبب التصميم.

---

## 3. الـ Widgets

### Ambxst
مجموعة **ضخمة جدًا** من الويدجتس، أعمق بكتير من أي حاجة موجودة في Horizons-DE حاليًا:
- **Dashboard** شامل بتابات: Clipboard, Audio Mixer (per-app!), Bluetooth, WiFi, Color Picker (مع Gradient Stops Editor!), EasyEffects panel, Emoji picker, Metrics (موارد النظام مع رسم بياني)، **Notes** (مع utils خاصة بالـ markdown/تخزين)، **Tmux tab** (إدارة جلسات tmux من داخل الشل!)، Wallpapers (مع دعم فيديو wallpaper عبر mpv + shader استخراج لوحة الألوان `palette.frag`).
- **Presets system**: تبديل ثيم كامل (مش بس لون) بضغطة واحدة.
- **Settings Crawler** (`SettingsCrawler.js`) — بيدور جوه شجرة الإعدادات نفسها ديناميكيًا (مشابه تمامًا لميزة "بحث الإعدادات" اللي اتعملت في Horizons-DE هذه الجلسة، لكن كأداة عامة بتفحص الشجرة أوتوماتيكيًا بدل فهرس مبني يدويًا).
- Pomodoro timer **مدمج في الساعة نفسها في البار**.

### caelestia-shell
أقل عددًا في الويدجتس لكن **أعمق تقنيًا** في اللي موجود:
- Sparkline/Wavy-line/Circular indicators **مُرسومة native** (C++ `QQuickItem` مخصصة) بدل QML Shape/Canvas — أداء أعلى بكتير لأي حاجة بتتحدّث كل فريم (زي visualizer الصوت).
- Beat-tracking حقيقي للموسيقى (`beattracker.cpp`) — مش مجرد قراءة مستوى الصوت، فيه اكتشاف إيقاع فعلي (لأي أنيميشن يرقص مع الموسيقى مثلاً).
- Lyrics service أصلي (C++) بدل سكربت بايثون خارجي.

**مقارنة بـ Horizons-DE:** الويدجتس الموجودة في Horizons-DE (background widgets: clock/weather/calendar/todo/notes/...) تنافسية عدديًا مع caelestia لكن أقل بكتير من Ambxst (خصوصًا: مفيش clipboard-history-as-dashboard-tab، مفيش audio mixer per-app، مفيش tmux integration، مفيش color-picker بـ gradient editor).

---

## 4. شاشة القفل/الدخول (Lock/Login)

### الاكتشاف الأهم في كل هذا التدقيق: `Quickshell.Services.Pam`

**caelestia-shell** (`modules/lock/Pam.qml`) بيستخدم موديول **رسمي من Quickshell نفسه** اسمه `Quickshell.Services.Pam` — بيوفر نوعين:
- `PamContext` — يكلّم PAM مباشرة (مفيش subprocess، مفيش sudo) لمصادقة كلمة السر (`config: "passwd"`، مع `configDirectory` مخصص لملف pam.d خاص بيهم مرفق مع الشل نفسه — مش معتمدين على `/etc/pam.d/passwd` الجاهز في التوزيعة).
- `ManualPamContext` (مكوّن مبني فوقه في نفس الملف) — لطرق المصادقة البديلة: `config: "howdy"` و `config: "fprint"`، كل واحدة عندها `availCommand` (بيتشيّك هل المصادقة دي متاحة أصلاً قبل أي محاولة: `command -v howdy` / `fprintd-list $USER`)، `maxTries` قابل للإعداد، وربط بحالة الجهاز (`onResumed` بيحاول howdy تلقائي لما الجهاز يصحى لو مفعّل `triggerHowdyOnWake`).

**ليه ده مهم لـ Horizons-DE تحديدًا:** في وقت سابق من هذه الجلسة، اتصلح باگ صلاحيات تنفيذ ملف `face-auth.sh`، لكن اتسجّل (بدون حل) إن **howdy نفسه مش مُعلَن كـ dependency، ومفيش إعداد sudoers/passwordless-sudo لـ `sudo howdy test`** — يعني حتى بعد إصلاح صلاحيات الملف، الميزة لسه محتاجة sudo تفاعلي كل مرة، وهو بالظبط نوع المشكلة اللي `Quickshell.Services.Pam` بيحلّها جذريًا: **مفيش sudo خالص** — الاتصال بـ PAM مباشر من داخل Quickshell، بنفس الطريقة اللي أي `login`/`sudo`/`gdm` بيستخدموها. ده أعمق بكتير وأصح تقنيًا من أي سكربت shell بيعمل `sudo howdy test`.

### باقي مقارنة شاشة القفل

| | Ambxst | caelestia-shell | Horizons-DE |
|---|---|---|---|
| المصادقة | `ambxst-auth` (ملف تنفيذي مُجمّع مرفق — لسه محتاج فحص أعمق لمعرفة هل بيستخدم PAM مباشر أو helper خارجي) | `Quickshell.Services.Pam` مباشرة (الأنظف) | سكربت bash بينادي `howdy`/`sudo` |
| مكوّنات الواجهة | ساعة، معلومات مستخدم، لاعب وسائط مصغّر | `Center.qml`/`Content.qml` منفصلين، طقس (`weather/`)، إشعارات مُجمّعة (`NotifGroup.qml` — 343 سطر، متقدم)، موارد النظام حية (`Resources.qml`) | ساعة، وسائط، توزيع عناصر مستقل لكل عنصر (بعد تعديل هذه الجلسة) |
| الطقس | نعم (Clock.qml بيتضمنه) | نعم (`weather/BriefInfo.qml` + `Forecast.qml` — توقعات ممتدة مش بس الحالة الحالية) | لا يوجد widget طقس في شاشة القفل حاليًا |

---

## 5. الأداء (Performance)

### أهم فرق: قراءة موارد النظام

| | الطريقة |
|---|---|
| Horizons-DE | `Process` + سطر bash (`top`/`free`/`df` أو مشابه) على `Timer` كل بضع ثواني — تكلفة spawn عملية فرعية جديدة كل مرة |
| Ambxst | نفس الأسلوب تقريبًا (QML/bash)، مفيش كود native |
| caelestia-shell | خدمات **C++ أصلية** (`cpu.cpp`, `memory.cpp`, `storage.cpp`, `gpu.cpp`) بتقرأ `/proc`/`/sys` مباشرة من غير أي subprocess خالص، ومربوطة بنمط **مرجعية استخدام** (`ServiceRef { service: Cpu }`) — يعني الخدمة نفسها بس "شغالة" (polling) لما حد فعلاً بيعرضها على الشاشة، مش دايمًا |

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

---

## 7. توصيات مرتّبة بالأولوية لـ Horizons-DE

1. **الأعلى قيمة والأقل خطورة:** فحص `Quickshell.Services.Pam` (القسم 4) كبديل لسكربت `face-auth.sh`/`howdy` الحالي — بيحل مشكلة الـ sudoers المؤجلة من هذه الجلسة جذريًا. يحتاج تأكيد إن هذا الموديول متاح في نسخة Quickshell المبنية هنا (نفس نوع الفحص اللي اتعمل لـ `Quickshell.I3` في تدقيق i3 السابق).
2. **فصل حجز المساحة (exclusiveZone) عن النوافذ المرئية** (نمط Ambxst's `ReservationWindows.qml` أو caelestia's per-window لكن مع نافذة حجز منفصلة) — يقلل مخاطر سباقات التهيئة في أي بار/سايدبار مستقبلي.
3. **توحيد نظام الأنيميشن حول تصنيف صريح** (زي M3 Expressive tokens بتاعة caelestia) بدل الأسماء المخصصة الحالية — تحسين تدريجي، مش لازم يتغير الكود الحالي، بس أي إضافة جديدة تتصنّف بالمعيار الجديد.
4. **قراءة موارد النظام (CPU/Memory/GPU) بدون subprocess** — استلهام من caelestia's native services، لكن ده استثمار أكبر بكتير (يحتاج C++ plugin زي caelestia، أو على الأقل قراءة `/proc` مباشرة عبر QML `FileView` بدل `Process`+bash كخطوة وسط أرخص وأسهل تنفيذها من غير الالتزام ببناء plugin كامل).
5. **ميزات للنظر فيها من Ambxst (أقل إلحاحًا، لكن قيمتها واضحة للمستخدم):** clipboard كـ tab في الـ dashboard بدل launcher منفصل بس، color picker بمحرر gradient، نظام presets كامل (تبديل ثيم شامل مش بس لون).

---

## المصادر
- `/g/dotfiles/Ambxst` (محلي، غير مُوثّق كـ repo عام هنا)
- `/g/dotfiles/caelestia-shell` (محلي)
- ملفات AGENTS.md المرفقة داخل كل مشروع (توثيق معماري ذاتي)
