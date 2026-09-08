# جرد صفحات الإعدادات من المصدر

لقطة من نسخة العمل بتاريخ 7 سبتمبر 2026. لكل ملف: العناوين والتسميات وتصريحات عناصر الخيارات، مع رقم السطر. يليها مسارات Config/NiriConfig المباشرة. هذا جرد مساعد؛ النصوص الوصفية والقيم المعروضة ليست بالضرورة خيارات مستقلة، والمسارات الديناميكية تحتاج ربطًا يدويًا في سجل التنفيذ.

## About

المصدر: `shell/modules/ii/settings/pages/About.qml` — 226 سطرًا.

```text
77: text: SystemInfo.distroName
86: text: "Kernel " + (SystemInfo.kernelVersion || "Loading...")
124: buttonText: Translation.tr("Update Horizons")
131: text: parent.buttonText
153: label: "CPU"
161: label: "GPU"
175: label: "Memory"
183: label: "Disk"
191: label: "Shell"
199: label: "Packages"
207: label: "Updates"
219: label: "Uptime"
```

مسارات الخصائص المباشرة:

```text
15: Config.options.settings.style
```

## BackgroundConfig

المصدر: `shell/modules/ii/settings/pages/BackgroundConfig.qml` — 1439 سطرًا.

```text
81: title: Translation.tr("Wallpaper")
136: text: "desktop_windows"
141: text: Translation.tr("Desktop")
159: text: "lock"
164: text: Translation.tr("Lockscreen")
216: text: "image"
221: text: Config.options.background.wallpaperPath.split("/").pop()
238: text: Translation.tr("Use same wallpaper for both")
249: text: Translation.tr("Preview wallpaper")
258: text: Translation.tr("Blur wall")
269: text: Translation.tr("Split blur amount")
284: text: Translation.tr("Split blur side")
298: text: Translation.tr("Wallpaper change interval (min)")
311: text: Translation.tr("Transitions")
314: { displayName: Translation.tr("None"), icon: "block", value: "" },
315: { displayName: Translation.tr("Circle"), icon: "circle", value: "circleSelect" },
316: { displayName: Translation.tr("Circle Pit"), icon: "blur_circular", value: "circlePit" },
317: { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
318: { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
319: { displayName: Translation.tr("Peel"), icon: "layers", value: "Peel" },
320: { displayName: Translation.tr("Fade"), icon: "gradient", value: "transition" },
321: { displayName: Translation.tr("Pixelate"), icon: "grain", value: "pixelate" },
322: { displayName: Translation.tr("Stripes"), icon: "texture_minus", value: "stripes" },
323: { displayName: Translation.tr("CRT"), icon: "tv", value: "crt" },
324: { displayName: Translation.tr("Dissolve"), icon: "blur_on", value: "dissolve" },
325: { displayName: Translation.tr("Glitch"), icon: "bug_report", value: "glitch" },
326: { displayName: Translation.tr("Ripple"), icon: "water", value: "ripple" },
327: { displayName: Translation.tr("Shatter"), icon: "broken_image", value: "shatter" },
328: { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
345: title: Translation.tr("Centered wallpaper")
352: text: Translation.tr("Enable")
361: text: Translation.tr("Show only when locked")
391: text: Translation.tr("Background Color")
399: text: Translation.tr("Size")
418: title: Translation.tr("Clock")
437: text: Translation.tr("Enable")
446: text: Translation.tr("Show only when locked")
454: text: Translation.tr("Placement strategy")
463: displayName: Translation.tr("Draggable"),
468: displayName: Translation.tr("Least busy"),
473: displayName: Translation.tr("Most busy"),
480: text: Translation.tr("Clock style")
488: displayName: Translation.tr("Digital"),
493: displayName: Translation.tr("Cookie"),
498: displayName: Translation.tr("Pixel"),
505: text: Translation.tr("Clock style (locked)")
513: displayName: Translation.tr("Digital"),
518: displayName: Translation.tr("Cookie"),
523: displayName: Translation.tr("Pixel"),
533: title: Translation.tr("Digital clock settings")
541: text: Translation.tr("Vertical")
547: text: Translation.tr("Show date")
556: text: Translation.tr("Animate time change")
562: text: Translation.tr("Use adaptive alignment")
573: text: Translation.tr("Automatic colors")
584: text: Translation.tr("Color")
595: placeholderText: Translation.tr("Font family")
596: text: Config.options.background.widgets.clock.digital.font.family
615: text: Translation.tr("Font weight")
628: text: Translation.tr("Font size")
641: text: Translation.tr("Font width")
653: text: Translation.tr("Font roundness")
668: title: Translation.tr("Cookie clock settings")
672: text: Translation.tr("Auto styling with Gemini")
681: text: Translation.tr("Use old sine wave cookie implementation")
690: text: Translation.tr("Sides")
702: text: Translation.tr("Constantly rotate")
714: text: Translation.tr("Hour marks")
727: text: Translation.tr("Digits in the middle")
744: text: "Dial Style"
758: displayName: "",
763: displayName: Translation.tr("Dots"),
768: displayName: Translation.tr("Full"),
773: displayName: Translation.tr("Numbers"),
781: text: Translation.tr("Hour hand")
788: displayName: "",
793: displayName: Translation.tr("Classic"),
798: displayName: Translation.tr("Hollow"),
803: displayName: Translation.tr("Fill"),
810: text: Translation.tr("Minute hand")
818: displayName: "",
823: displayName: Translation.tr("Classic"),
828: displayName: Translation.tr("Thin"),
833: displayName: Translation.tr("Medium"),
838: displayName: Translation.tr("Bold"),
845: text: Translation.tr("Second hand")
853: displayName: "",
858: displayName: Translation.tr("Classic"),
863: displayName: Translation.tr("Line"),
868: displayName: Translation.tr("Dot"),
875: text: Translation.tr("Date style")
883: displayName: "",
888: displayName: Translation.tr("Bubble"),
893: displayName: Translation.tr("Border"),
898: displayName: Translation.tr("Rect"),
908: title: Translation.tr("Pixel Clock Settings")
912: text: Translation.tr("Pixel clock orientation")
921: displayName: Translation.tr("Horizontal"),
926: displayName: Translation.tr("Vertical"),
936: title: Translation.tr("Quote")
940: text: Translation.tr("Enable")
948: text: Translation.tr("Follow Clock Font")
960: text: Translation.tr("Quote")
961: placeholderText: Translation.tr("Quote")
983: title: Translation.tr("Custom Image")
988: text: Translation.tr("Enable")
1015: title: Translation.tr("Widgets")
1018: title: Translation.tr("Show widgets on")
1037: name: Translation.tr("Weather"),
1043: name: Translation.tr("Image converter"),
1049: name: Translation.tr("Media Player"),
1055: name: Translation.tr("Resources"),
1061: name: Translation.tr("Visualizer"),
1067: name: Translation.tr("Mirrored visualizer"),
1073: name: Translation.tr("Full monitor visualizer"),
1079: name: Translation.tr("Calendar"),
1085: name: Translation.tr("World Clock"),
1091: name: Translation.tr("User Card"),
1097: name: Translation.tr("Notes"),
1103: name: Translation.tr("To-Do"),
1109: name: Translation.tr("Timers"),
1115: name: Translation.tr("Network Info"),
1121: name: Translation.tr("System History"),
1127: name: Translation.tr("Uptime"),
1150: text: modelData.icon
1194: text: "lock"
1198: text: Translation.tr("Show only on the lock screen")
1203: text: modelData.name
1208: text: modelData.enabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
1217: title: Translation.tr("Visualizer")
1231: text: "restart_alt"
1237: text: Translation.tr("Reset visualizer settings")
1245: text: Translation.tr("Pause while a window covers the desktop")
1253: text: Translation.tr("Width")
1260: text: Translation.tr("Maximum height")
1267: text: Translation.tr("Frequency bands")
1274: text: Translation.tr("Noise gate")
1281: text: Translation.tr("Rise response")
1288: text: Translation.tr("Fall response")
1298: text: Translation.tr("The visualizer redraws on every audio frame and keeps cava capturing, so it is the most expensive thing on the desktop. With this on, it is torn down completely on any screen whose active workspace holds a tiled or fullscreen window - and cava stops once no screen is showing one. Floating windows don't count, since the desktop stays visible around them. Each screen is judged on its own: a window on one monitor never stops the visualizer on another.")
1303: title: Translation.tr("Full monitor visualizer")
1309: text: Translation.tr("Pause while a window covers the desktop")
1315: text: Translation.tr("Maximum height")
1322: text: Translation.tr("Bar width")
1329: text: Translation.tr("Bar spacing")
1336: text: Translation.tr("Smoothing duration")
1346: text: Translation.tr("The classic full-width end4 spectrum. It is attached to the bottom of every eligible monitor and is not a draggable canvas widget.")
1351: title: Translation.tr("Mirrored visualizer")
1357: text: Translation.tr("Pause while a window covers the desktop")
1363: text: Translation.tr("Width")
1370: text: Translation.tr("Total height")
1377: text: Translation.tr("Frequency bands")
1384: text: Translation.tr("Noise gate")
1391: text: Translation.tr("Rise response")
1398: text: Translation.tr("Fall response")
1408: text: Translation.tr("This spectrum grows above and below its center line. Unlock desktop widgets, then drag it anywhere on the canvas; its position is saved like the other widgets.")
1413: title: Translation.tr("Canvas")
1420: text: Translation.tr("Show alignment grid while dragging")
1429: text: Translation.tr("Show snap lines when dropping")
```

مسارات الخصائص المباشرة:

```text
338: Config.options.background
353: Config.options.background.centeredWallpaper
392: Config.options.background.centeredWallpaperColor
362: Config.options.background.centeredWallpaperOnlyWhenLocked
374: Config.options.background.centeredWallpaperShape
400: Config.options.background.centeredWallpaperSize
250: Config.options.background.enableWallpaperPreview
109: Config.options.background.lockWall
259: Config.options.background.showBlur
1421: Config.options.background.showGrid
1430: Config.options.background.showSnapLines
271: Config.options.background.splitRatio
286: Config.options.background.splitSide
42: Config.options.background.thumbnailPath
330: Config.options.background.wallpaperAnimation
107: Config.options.background.wallpaperPath
221: Config.options.background.wallpaperPath.split
1080: Config.options.background.widgets.calendar.enable
574: Config.options.background.widgets.clock.color
673: Config.options.background.widgets.clock.cookie.aiStyling
703: Config.options.background.widgets.clock.cookie.constantlyRotate
877: Config.options.background.widgets.clock.cookie.dateStyle
712: Config.options.background.widgets.clock.cookie.dialNumberStyle
782: Config.options.background.widgets.clock.cookie.hourHandStyle
715: Config.options.background.widgets.clock.cookie.hourMarks
812: Config.options.background.widgets.clock.cookie.minuteHandStyle
847: Config.options.background.widgets.clock.cookie.secondHandStyle
691: Config.options.background.widgets.clock.cookie.sides
728: Config.options.background.widgets.clock.cookie.timeIndicators
682: Config.options.background.widgets.clock.cookie.useSineCookie
563: Config.options.background.widgets.clock.digital.adaptiveAlignment
557: Config.options.background.widgets.clock.digital.animateChange
596: Config.options.background.widgets.clock.digital.font.family
654: Config.options.background.widgets.clock.digital.font.roundness
629: Config.options.background.widgets.clock.digital.font.size
616: Config.options.background.widgets.clock.digital.font.weight
642: Config.options.background.widgets.clock.digital.font.width
548: Config.options.background.widgets.clock.digital.showDate
542: Config.options.background.widgets.clock.digital.vertical
438: Config.options.background.widgets.clock.enable
915: Config.options.background.widgets.clock.pixel.orientation
457: Config.options.background.widgets.clock.placementStrategy
941: Config.options.background.widgets.clock.quote.enable
950: Config.options.background.widgets.clock.quote.followClock
962: Config.options.background.widgets.clock.quote.text
421: Config.options.background.widgets.clock.showOnlyWhenLocked
421: Config.options.background.widgets.clock.style
424: Config.options.background.widgets.clock.styleLocked
989: Config.options.background.widgets.customImage.enable
995: Config.options.background.widgets.customImage.shape
1323: Config.options.background.widgets.fullMonitorVisualizer.barWidth
1074: Config.options.background.widgets.fullMonitorVisualizer.enable
1316: Config.options.background.widgets.fullMonitorVisualizer.height
1310: Config.options.background.widgets.fullMonitorVisualizer.hideWhenObscured
1337: Config.options.background.widgets.fullMonitorVisualizer.smoothingDuration
1330: Config.options.background.widgets.fullMonitorVisualizer.spacing
1044: Config.options.background.widgets.images.enable
68: Config.options.background.widgets.lockOnly
61: Config.options.background.widgets.lockOnly.indexOf
65: Config.options.background.widgets.lockOnly.slice
1050: Config.options.background.widgets.media.enable
1116: Config.options.background.widgets.networkInfo.enable
1098: Config.options.background.widgets.notes.enable
1056: Config.options.background.widgets.resources.enable
1122: Config.options.background.widgets.systemHistory.enable
1110: Config.options.background.widgets.timers.enable
1104: Config.options.background.widgets.todo.enable
1128: Config.options.background.widgets.uptime.enable
1092: Config.options.background.widgets.userCard.enable
47: Config.options.background.widgets.visualizer
1282: Config.options.background.widgets.visualizer.attack
1268: Config.options.background.widgets.visualizer.barCount
1062: Config.options.background.widgets.visualizer.enable
1261: Config.options.background.widgets.visualizer.height
1246: Config.options.background.widgets.visualizer.hideWhenObscured
1275: Config.options.background.widgets.visualizer.noiseFloor
1289: Config.options.background.widgets.visualizer.release
1254: Config.options.background.widgets.visualizer.width
1392: Config.options.background.widgets.visualizerMirror.attack
1378: Config.options.background.widgets.visualizerMirror.barCount
1068: Config.options.background.widgets.visualizerMirror.enable
1371: Config.options.background.widgets.visualizerMirror.height
1358: Config.options.background.widgets.visualizerMirror.hideWhenObscured
1385: Config.options.background.widgets.visualizerMirror.noiseFloor
1399: Config.options.background.widgets.visualizerMirror.release
1364: Config.options.background.widgets.visualizerMirror.width
1038: Config.options.background.widgets.weather.enable
1086: Config.options.background.widgets.worldClock.enable
299: Config.options.wallpaperSelector.changeInterval
```

## BarConfig

المصدر: `shell/modules/ii/settings/pages/BarConfig.qml` — 1464 سطرًا.

```text
40: { id: "leftSidebarButton", name: Translation.tr("Left Sidebar Button"),  icon: "left_panel_open" },
41: { id: "workspaces",        name: Translation.tr("Workspaces"),           icon: "steppers" },
42: { id: "weatherBar",        name: Translation.tr("Weather"),              icon: "flare" },
43: { id: "media",             name: Translation.tr("Media"),                icon: "music_note" },
44: { id: "resources",         name: Translation.tr("Resources"),            icon: "empty_dashboard" },
45: { id: "systemIcons",       name: Translation.tr("System Icons"),         icon: "info" },
46: { id: "networkSpeed",      name: Translation.tr("Network Speed"),        icon: "network_check" },
47: { id: "vpnIndicator",      name: Translation.tr("VPN Indicator"),        icon: "vpn_lock" },
48: { id: "clockWidget",       name: Translation.tr("Clock"),                icon: "schedule" },
49: { id: "utilButtons",       name: Translation.tr("Util Buttons"),         icon: "toggle_on" },
50: { id: "sysTray",           name: Translation.tr("Tray"),                 icon: "inbox" },
51: { id: "batteryIndicator",  name: Translation.tr("Battery"),              icon: "battery_android_frame_full" },
52: { id: "bluetooth",         name: Translation.tr("Bluetooth"),            icon: "bluetooth" },
53: { id: "activeWindow",      name: Translation.tr("Active Window"),        icon: "subtitles" },
54: { id: "powerButton",       name: Translation.tr("Power Button"),         icon: "power_settings_new" },
55: { id: "updatesCount",      name: Translation.tr("Updates"),              icon: "deployed_code_update" },
56: { id: "docktoPanel",       name: Translation.tr("Dock to Panel"),        icon: "apps" },
57: { id: "visualizer",        name: Translation.tr("Visualizer"),           icon: "graphic_eq" },
58: { id: "pomodoroBar",       name: Translation.tr("Pomodoro"),             icon: "timer" },
59: { id: "hyprlandXkbIndicator", name: Translation.tr("Keyboard Layout"),  icon: "keyboard" },
60: { id: "divisor",           name: Translation.tr("Divider"),              icon: "horizontal_distribute" },
61: { id: "launcherButton",    name: Translation.tr("Launcher Button"),      icon: "search" },
62: { id: "idleInhibitor",     name: Translation.tr("Idle Inhibitor"),       icon: "coffee" },
63: { id: "uptime",            name: Translation.tr("Uptime"),               icon: "avg_pace" },
64: { id: "privacyIndicator",  name: Translation.tr("Privacy Indicator"),    icon: "shield_lock" },
112: { id: "m3Clock",       name: Translation.tr("Clock"),                    icon: "schedule" },
113: { id: "m3MiniStats",   name: Translation.tr("Mini Stats (CPU/RAM)"),    icon: "monitoring" },
114: { id: "m3NotifStatus", name: Translation.tr("Notification Status"),     icon: "notifications" },
119: return w ? w.name : id
125: { id: "wifi",       name: Translation.tr("Wi-Fi"),        icon: "wifi" },
126: { id: "bluetooth",  name: Translation.tr("Bluetooth"),    icon: "bluetooth" },
127: { id: "nightLight", name: Translation.tr("Night Light"),  icon: "bedtime" },
128: { id: "darkMode",   name: Translation.tr("Dark Mode"),    icon: "dark_mode" },
129: { id: "mic",        name: Translation.tr("Microphone"),   icon: "mic" },
130: { id: "dnd",        name: Translation.tr("Do Not Disturb"), icon: "do_not_disturb_on" },
131: { id: "airplane",   name: Translation.tr("Airplane Mode"), icon: "flight" },
132: { id: "rotation",   name: Translation.tr("Screen Rotation"), icon: "screen_rotation_alt" },
133: { id: "location",   name: Translation.tr("Location Services"), icon: "location_on" },
134: { id: "nfc",        name: Translation.tr("NFC"),          icon: "nfc" },
135: { id: "hotspot",    name: Translation.tr("Wi-Fi Hotspot"), icon: "wifi_tethering" },
140: return t ? t.name : id
150: return app ? app.name : id
157: .map(a => ({ id: a.id, name: a.name, icon: "apps" }))
190: title: Translation.tr("Bar Mode")
194: text: Translation.tr("Active bar")
199: { displayName: Translation.tr("Classic"),      icon: "horizontal_rule",    value: "classic" },
200: { displayName: Translation.tr("Mesobar (formerly Top Island)"), icon: "dock", value: "mesoBar" },
201: { displayName: Translation.tr("M3 Island"),    icon: "interests",          value: "m3Island" },
202: { displayName: Translation.tr("Tasklist"),     icon: "list",               value: "tasklistBar" },
203: { displayName: Translation.tr("Sys Monitor"),  icon: "monitoring",         value: "sysmonitorBar" },
204: { displayName: Translation.tr("Quick Actions"),icon: "tune",               value: "quickActionsBar" },
205: { displayName: Translation.tr("Info Strip"),   icon: "remove",             value: "infoStrip" },
216: title: Translation.tr("Screens")
218: title: Translation.tr("Show bar on")
239: text: Translation.tr("All")
272: text: monitorRow.modelData.name
301: title: Translation.tr("Bar Layout")
333: title: Translation.tr("Mesobar Layout")
365: title: Translation.tr("M3 Island Layout")
380: text: Translation.tr("\"Clock\" is a normal widget in this list now, not a fixture - put it anywhere, add widgets on either side of it, or remove it and use something else entirely (e.g. Workspaces) as the idle pill.")
404: title: Translation.tr("M3 Island Options")
408: text: Translation.tr("Clock style")
413: { displayName: Translation.tr("M3 Pill"), icon: "pill", value: "m3" },
414: { displayName: Translation.tr("Minimal"), icon: "remove", value: "minimal" },
415: { displayName: Translation.tr("Digital"), icon: "timer", value: "digital" },
422: text: Translation.tr("Show date")
428: text: Translation.tr("Hover peek")
437: text: Translation.tr("Show seconds")
443: text: Translation.tr("Use 24-hour clock")
452: text: Translation.tr("Reserve screen space")
461: text: Translation.tr("Click to expand")
467: text: Translation.tr("Launcher hug")
473: text: Translation.tr("Show expanded details")
480: text: Translation.tr("Launcher maximum visible results")
486: text: Translation.tr("Scroll over island")
491: { displayName: Translation.tr("Volume"),      icon: "volume_up",  value: "volume" },
492: { displayName: Translation.tr("Media seek"),  icon: "skip_next",  value: "mediaSeek" },
493: { displayName: Translation.tr("Expand/collapse"), icon: "unfold_more", value: "layoutCycle" },
494: { displayName: Translation.tr("Off"),         icon: "block",      value: "none" },
499: text: Translation.tr("Expanded height")
505: text: Translation.tr("Animation speed")
510: { displayName: Translation.tr("Fast"),   icon: "fast_forward", value: "fast" },
511: { displayName: Translation.tr("Normal"), icon: "speed",        value: "normal" },
512: { displayName: Translation.tr("Slow"),   icon: "slow_motion_video", value: "slow" },
517: text: Translation.tr("Hug corner size")
524: text: Translation.tr("Corner style")
529: { displayName: Translation.tr("Hug"),   icon: "line_curve", value: 0 },
530: { displayName: Translation.tr("Float"), icon: "view_day",   value: 1 },
535: text: Translation.tr("Notification display time (ms, 0 = global)")
544: text: Translation.tr("Show Background")
550: text: Translation.tr("Show Frame")
558: text: Translation.tr("Blend the wallpaper into the island")
564: text: Translation.tr("Wallpaper strength")
573: text: Translation.tr("Readability scrim")
586: text: Translation.tr("The island shows the exact piece of wallpaper it is sitting on, lined up with the desktop behind it, so it reads as carved out of the wallpaper instead of floating on top of it. The scrim lays the island's normal colour back over that image - drop it to 0 for a pure window onto the wallpaper, raise it if the pill's text gets lost over a busy one.")
591: text: Translation.tr("Use Frame Color as Background")
597: text: Translation.tr("Frame thickness")
605: text: Translation.tr("Frame Color")
617: title: Translation.tr("Positioning & Style")
622: text: Translation.tr("Bar position")
631: { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
632: { displayName: Translation.tr("Left"),   icon: "arrow_back",     value: 2 },
633: { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
634: { displayName: Translation.tr("Right"),  icon: "arrow_forward",  value: 3 }
638: text: Translation.tr("Bar position")
644: { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
645: { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 }
651: text: Translation.tr("Mesobar style")
657: { displayName: Translation.tr("Hug"),     icon: "line_curve",  value: 0 },
658: { displayName: Translation.tr("Float"),   icon: "view_day",    value: 1 },
659: { displayName: Translation.tr("Islands"), icon: "crop_3_2",    value: 2 },
660: { displayName: Translation.tr("M3"),      icon: "interests",   value: 3 }
666: text: Translation.tr("Width")
672: { displayName: Translation.tr("Fit content"), icon: "fit_screen", value: "content" },
673: { displayName: Translation.tr("Percent"),     icon: "width",       value: "percent" }
678: text: Translation.tr("Width (% of screen)")
687: text: Translation.tr("Bar style")
693: { displayName: Translation.tr("Hug"),     icon: "line_curve",  value: 0 },
694: { displayName: Translation.tr("Float"),   icon: "view_day",    value: 1 },
695: { displayName: Translation.tr("Islands"), icon: "crop_3_2",    value: 2 },
696: { displayName: Translation.tr("M3"),      icon: "interests",   value: 3 }
702: text: Translation.tr("Group style")
708: { displayName: Translation.tr(""),          icon: "block",         value: "transparent" },
709: { displayName: Translation.tr("Pills"),     icon: "pill",          value: "pills" },
710: { displayName: Translation.tr("Separated"), icon: "view_column_2", value: "separated" },
711: { displayName: Translation.tr("Segmented"), icon: "tablet",        value: "segmented" },
717: text: Translation.tr("Group style")
723: { displayName: Translation.tr(""),          icon: "block",         value: "transparent" },
724: { displayName: Translation.tr("Pills"),     icon: "pill",          value: "pills" },
725: { displayName: Translation.tr("Separated"), icon: "view_column_2", value: "separated" },
726: { displayName: Translation.tr("Segmented"), icon: "tablet",        value: "segmented" },
732: text: Translation.tr("Group Color")
743: text: Translation.tr("Show Background")
751: text: Translation.tr("Autohide")
756: { displayName: Translation.tr("No"),  icon: "close", value: false },
757: { displayName: Translation.tr("Yes"), icon: "check", value: true }
766: text: Translation.tr("Hover Region Width (px)")
773: text: Translation.tr("Push Windows When Hidden")
779: text: Translation.tr("Show On Super Press")
789: text: Translation.tr("Show Frame")
801: text: Translation.tr("Follow Frame Color")
809: text: Translation.tr("Frame thickness")
817: text: Translation.tr("Frame Color")
830: title: Translation.tr("Mesobar Options")
836: text: Translation.tr("Show Frame")
848: text: Translation.tr("Follow Frame Color")
855: text: Translation.tr("Frame thickness")
862: text: Translation.tr("Frame Color")
875: title: Translation.tr("Tasklist Options")
882: text: Translation.tr("Show Labels")
889: text: Translation.tr("Max Button Width")
909: title: Translation.tr("System Monitor Options")
916: text: Translation.tr("CPU")
922: text: Translation.tr("CPU Temperature")
931: text: Translation.tr("RAM")
937: text: Translation.tr("Disk")
946: text: Translation.tr("Swap")
952: text: Translation.tr("Network")
959: text: Translation.tr("RAM warning threshold (%)")
966: text: Translation.tr("CPU warning threshold (%)")
973: text: Translation.tr("Temperature warning threshold (°C)")
980: text: Translation.tr("Disk warning threshold (%)")
987: text: Translation.tr("Swap warning threshold (%)")
1000: title: Translation.tr("Quick Actions Options")
1007: text: Translation.tr("Volume Slider")
1013: text: Translation.tr("Brightness Slider")
1033: text: Translation.tr("Hotspot SSID")
1039: placeholderText: Hotspot.ssid
1040: text: Config.options.quickActionsBar.hotspotSsid
1048: text: Translation.tr("Hotspot Password")
1054: placeholderText: Hotspot.password
1055: text: Config.options.quickActionsBar.hotspotPassword
1069: title: Translation.tr("Info Strip Options")
1076: text: Translation.tr("Active Window")
1082: text: Translation.tr("Clock")
1091: text: Translation.tr("CPU Usage")
1097: text: Translation.tr("Memory Usage")
1104: text: Translation.tr("Notification Dot")
1115: title: Translation.tr("Notifications")
1119: text: Translation.tr("Popup position")
1125: { displayName: Translation.tr("Top left"),      value: "top_left" },
1126: { displayName: Translation.tr("Top center"),    value: "top_center" },
1127: { displayName: Translation.tr("Top right"),     value: "top_right" },
1128: { displayName: Translation.tr("Bottom left"),   value: "bottom_left" },
1129: { displayName: Translation.tr("Bottom center"), value: "bottom_center" },
1130: { displayName: Translation.tr("Bottom right"),  value: "bottom_right" }
1135: text: Translation.tr("Unread indicator: show count")
1141: text: Translation.tr("Timeout duration (ms)")
1153: title: Translation.tr("Tray")
1158: text: Translation.tr("Make icons pinned by default")
1164: text: Translation.tr("Tint icons")
1176: title: Translation.tr("Divider")
1180: text: Translation.tr("Style")
1185: { displayName: Translation.tr("Line"),  icon: "more_vert",           value: "rect" },
1186: { displayName: Translation.tr("Dot"),   icon: "fiber_manual_record", value: "dot" },
1187: { displayName: Translation.tr("Space"), icon: "space_bar",           value: "space" }
1193: text: Translation.tr("Space width (px)")
1206: title: Translation.tr("Utility Buttons")
1213: text: Translation.tr("Screen snip")
1219: text: Translation.tr("Color picker")
1228: text: Translation.tr("Keyboard toggle")
1234: text: Translation.tr("Mic toggle")
1243: text: Translation.tr("Dark/Light toggle")
1249: text: Translation.tr("Performance Profile")
1258: text: Translation.tr("Record Screen")
1264: text: Translation.tr("Wallpapers Toggle")
1277: title: Translation.tr("Workspaces")
1282: text: Translation.tr("Always show numbers")
1287: text: Translation.tr("Numbers style")
1292: { displayName: Translation.tr("Normal"),    icon: "timer_10",        value: '[]' },
1293: { displayName: Translation.tr("Han chars"), icon: "glyphs",          value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
1294: { displayName: Translation.tr("Roman"),     icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
1299: text: Translation.tr("Show app icons")
1305: text: Translation.tr("Workspaces shown")
1312: text: Translation.tr("Show preview on hover")
1317: text: Translation.tr("Indicator style")
1322: { displayName: Translation.tr("Dots"),  icon: "radio_button_checked", value: "dot" },
1323: { displayName: Translation.tr("Icons"), icon: "interests",            value: "icon" },
1334: title: Translation.tr("Resources")
1341: text: Translation.tr("CPU")
1347: text: Translation.tr("CPU Temperature")
1356: text: Translation.tr("RAM")
1362: text: Translation.tr("Disk")
1371: text: Translation.tr("Swap")
1377: text: Translation.tr("Style")
1382: { displayName: Translation.tr("Filled"),  icon: "incomplete_circle", value: "filled" },
1383: { displayName: Translation.tr("Outline"), icon: "circles",           value: "outline" }
1388: text: Translation.tr("Show Percentage")
1394: text: Translation.tr("Polling interval (ms)")
1407: title: Translation.tr("Media")
1414: text: Translation.tr("Preferred Player")
1415: placeholderText: Translation.tr("e.g. spotify, firefox")
1428: text: Translation.tr("Pin media controls")
1434: text: Translation.tr("Show only title")
1440: text: Translation.tr("Max media width")
1452: title: Translation.tr("Tooltips")
1457: text: Translation.tr("Click to show")
```

مسارات الخصائص المباشرة:

```text
753: Config.options.bar.autoHide.enable
767: Config.options.bar.autoHide.hoverRegionWidth
774: Config.options.bar.autoHide.pushWindows
780: Config.options.bar.autoHide.showWhenPressingSuper.enable
37: Config.options.bar.barMode
90: Config.options.bar.borderless
625: Config.options.bar.bottom
690: Config.options.bar.cornerStyle
1194: Config.options.bar.divider.spacing
1182: Config.options.bar.divider.style
802: Config.options.bar.followFrameColor
819: Config.options.bar.frameColor
810: Config.options.bar.frameThickness
735: Config.options.bar.groupColor
1136: Config.options.bar.indicators.notifications.showUnreadCount
84: Config.options.bar.layouts.leftLayout
85: Config.options.bar.layouts.middleLayout
86: Config.options.bar.layouts.rightLayout
1429: Config.options.bar.media.alwaysVisible
1441: Config.options.bar.media.maxWidth
1435: Config.options.bar.media.onlyTitle
1416: Config.options.bar.media.preferredPlayer
1342: Config.options.bar.resources.alwaysShowCpu
1348: Config.options.bar.resources.alwaysShowCpuTemp
1363: Config.options.bar.resources.alwaysShowDisk
1357: Config.options.bar.resources.alwaysShowRam
1372: Config.options.bar.resources.alwaysShowSwap
1389: Config.options.bar.resources.showValue
1379: Config.options.bar.resources.style
241: Config.options.bar.screenList
286: Config.options.bar.screenList.includes
246: Config.options.bar.screenList.length
275: Config.options.bar.screenList.slice
744: Config.options.bar.showBackground
790: Config.options.bar.showFrame
1458: Config.options.bar.tooltips.clickToShow
1220: Config.options.bar.utilButtons.showColorPicker
1244: Config.options.bar.utilButtons.showDarkModeToggle
1229: Config.options.bar.utilButtons.showKeyboardToggle
1235: Config.options.bar.utilButtons.showMicToggle
1250: Config.options.bar.utilButtons.showPerformanceProfileToggle
1259: Config.options.bar.utilButtons.showScreenRecord
1214: Config.options.bar.utilButtons.showScreenSnip
1265: Config.options.bar.utilButtons.showWallpaperToggle
305: Config.options.bar.vertical
1283: Config.options.bar.workspaces.alwaysShowNumbers
1319: Config.options.bar.workspaces.indicatorStyle
1289: Config.options.bar.workspaces.numberMap
1300: Config.options.bar.workspaces.showAppIcons
1306: Config.options.bar.workspaces.shown
1077: Config.options.infoStrip.showActiveWindow
1083: Config.options.infoStrip.showClock
1092: Config.options.infoStrip.showCpuUsage
1098: Config.options.infoStrip.showMemoryUsage
1105: Config.options.infoStrip.showNotificationDot
507: Config.options.m3Island.animationSpeed
174: Config.options.m3Island.borderless
462: Config.options.m3Island.clickToExpand
423: Config.options.m3Island.clockShowDate
438: Config.options.m3Island.clockShowSeconds
410: Config.options.m3Island.clockStyle
444: Config.options.m3Island.clockUse24h
518: Config.options.m3Island.cornerStyle
500: Config.options.m3Island.expandedHeight
592: Config.options.m3Island.followFrameColor
607: Config.options.m3Island.frameColor
599: Config.options.m3Island.frameThickness
429: Config.options.m3Island.hoverPeek
519: Config.options.m3Island.hugCornerSize
468: Config.options.m3Island.launcherHug
481: Config.options.m3Island.launcherMaxResults
164: Config.options.m3Island.layouts.expandedLayout
163: Config.options.m3Island.layouts.hoverLayout
162: Config.options.m3Island.layouts.restingLayout
536: Config.options.m3Island.notificationTimeout
453: Config.options.m3Island.reserveScreenSpace
488: Config.options.m3Island.scrollAction
545: Config.options.m3Island.showBackground
551: Config.options.m3Island.showFrame
474: Config.options.m3Island.verbose
559: Config.options.m3Island.wallpaperBackground.enable
567: Config.options.m3Island.wallpaperBackground.opacity
576: Config.options.m3Island.wallpaperBackground.scrim
103: Config.options.mesoBar.borderless
654: Config.options.mesoBar.cornerStyle
849: Config.options.mesoBar.followFrameColor
864: Config.options.mesoBar.frameColor
856: Config.options.mesoBar.frameThickness
97: Config.options.mesoBar.layouts.leftLayout
98: Config.options.mesoBar.layouts.middleLayout
99: Config.options.mesoBar.layouts.rightLayout
837: Config.options.mesoBar.showFrame
669: Config.options.mesoBar.widthMode
680: Config.options.mesoBar.widthPercent
1121: Config.options.notifications.position
1142: Config.options.notifications.timeout
1313: Config.options.overview.hoverPreviewInBar
1055: Config.options.quickActionsBar.hotspotPassword
1040: Config.options.quickActionsBar.hotspotSsid
1014: Config.options.quickActionsBar.showBrightnessSlider
1008: Config.options.quickActionsBar.showVolumeSlider
1023: Config.options.quickActionsBar.toggles
144: Config.options.quickActionsBar.toggles.map
1027: Config.options.quickActionsBar.toggles.some
1395: Config.options.resources.updateInterval
967: Config.options.sysmonitorBar.cpuWarningThreshold
981: Config.options.sysmonitorBar.diskWarningThreshold
960: Config.options.sysmonitorBar.memoryWarningThreshold
917: Config.options.sysmonitorBar.showCpu
923: Config.options.sysmonitorBar.showCpuTemp
938: Config.options.sysmonitorBar.showDisk
953: Config.options.sysmonitorBar.showNetwork
932: Config.options.sysmonitorBar.showRam
947: Config.options.sysmonitorBar.showSwap
988: Config.options.sysmonitorBar.swapWarningThreshold
974: Config.options.sysmonitorBar.tempWarningThreshold
890: Config.options.tasklistBar.maxButtonWidth
154: Config.options.tasklistBar.pinnedApps
883: Config.options.tasklistBar.showLabels
1159: Config.options.tray.invertPinnedItems
1165: Config.options.tray.monochromeIcons
```

## ExperienceConfig

المصدر: `shell/modules/ii/settings/pages/ExperienceConfig.qml` — 418 سطرًا.

```text
80: title: Translation.tr("Built-in themes")
84: text: Translation.tr("Theme starting point")
88: { displayName: Translation.tr("Adaptive"), icon: "wallpaper", value: "adaptive" },
89: { displayName: Translation.tr("Midnight glass"), icon: "nightlight", value: "midnight" },
90: { displayName: Translation.tr("Paper"), icon: "article", value: "paper" },
91: { displayName: Translation.tr("Aurora"), icon: "colors", value: "aurora" },
92: { displayName: Translation.tr("Monochrome"), icon: "contrast", value: "mono" }
99: text: Translation.tr("Liquid glass surfaces")
105: text: Translation.tr("Expressive motion")
112: text: Translation.tr("Glass opacity (%)")
124: title: Translation.tr("Notification experience")
128: text: Translation.tr("Display mode")
132: { displayName: Translation.tr("Toasts"), icon: "notifications", value: "toast" },
133: { displayName: Translation.tr("Compact"), icon: "notification_important", value: "compact" },
134: { displayName: Translation.tr("History only"), icon: "history", value: "history" },
135: { displayName: Translation.tr("Island"), icon: "interests", value: "island" }
140: text: Translation.tr("Card style")
144: { displayName: Translation.tr("Material"), icon: "rounded_corner", value: "material" },
145: { displayName: Translation.tr("Glass"), icon: "water_drop", value: "glass" },
146: { displayName: Translation.tr("Minimal"), icon: "minimize", value: "minimal" }
153: text: Translation.tr("Pause timeout on hover")
159: text: Translation.tr("Critical alerts in quiet mode")
166: text: Translation.tr("Auto-silence popups while screen sharing")
175: text: Translation.tr("Only mutes toast popups for as long as something is actually capturing your screen - notifications still land in the list, and this never touches the quiet-mode switch itself, so it can't un-mute you the moment sharing ends if you muted it yourself. Critical alerts still break through, same as quiet mode above.")
179: text: Translation.tr("Maximum visible cards")
186: text: Translation.tr("Expand notifications on hover")
192: text: Translation.tr("Hover expand delay (ms)")
203: text: Translation.tr("Show preview on system-icons hover")
209: text: Translation.tr("Recent items")
222: text: Translation.tr("Per-app notification rules (JSON)")
242: title: Translation.tr("Windows & focus")
246: text: Translation.tr("Use generated theme colours for window borders")
258: text: Translation.tr("Focused window opacity (%)")
269: text: Translation.tr("Unfocused opacity (%)")
281: text: Translation.tr("Dim inactive windows")
294: title: Translation.tr("Session screen")
298: text: Translation.tr("Presentation")
302: { displayName: Translation.tr("Centered screen"), icon: "center_focus_strong", value: "center" },
303: { displayName: Translation.tr("Side sheet"), icon: "right_panel_open", value: "edge" }
311: text: Translation.tr("Side")
315: { displayName: Translation.tr("Right"), icon: "right_panel_open", value: "right" },
316: { displayName: Translation.tr("Left"), icon: "left_panel_open", value: "left" }
322: text: Translation.tr("Side sheet width")
330: text: Translation.tr("Action layout")
334: { displayName: Translation.tr("Compact grid"), icon: "grid_view", value: 4 },
335: { displayName: Translation.tr("Comfortable"), icon: "view_module", value: 3 },
336: { displayName: Translation.tr("Large actions"), icon: "view_agenda", value: 2 }
343: text: Translation.tr("Show hibernate")
349: text: Translation.tr("Show task manager")
358: text: Translation.tr("Show firmware reboot")
364: text: Translation.tr("Show safety warnings")
371: text: Translation.tr("Confirm shutdown, reboot, and firmware actions")
381: title: Translation.tr("Pomodoro in the bar")
387: text: Translation.tr("Add Pomodoro from Bar → Layout to place this control in any bar or island.")
393: text: Translation.tr("Show focus / break label")
399: text: Translation.tr("Show seconds")
406: text: Translation.tr("Click action")
410: { displayName: Translation.tr("Start / pause"), icon: "play_arrow", value: "toggle" },
411: { displayName: Translation.tr("Reset"), icon: "restart_alt", value: "reset" },
412: { displayName: Translation.tr("Open sidebar"), icon: "right_panel_open", value: "sidebar" }
```

مسارات الخصائص المباشرة:

```text
17: Config.options.appearance
16: Config.options.appearance.builtInTheme
100: Config.options.appearance.glass.enable
114: Config.options.appearance.glass.opacity
106: Config.options.appearance.motion.style
407: Config.options.bar.pomodoro.clickAction
394: Config.options.bar.pomodoro.showLabel
400: Config.options.bar.pomodoro.showSeconds
204: Config.options.bar.systemIconsHover.enable
211: Config.options.bar.systemIconsHover.recentLimit
259: Config.options.hyprland.decoration.activeOpacity
282: Config.options.hyprland.decoration.dimInactive
270: Config.options.hyprland.decoration.inactiveOpacity
48: Config.options.hyprland.general
247: Config.options.hyprland.general.autoThemeBorders
225: Config.options.notifications.appRules
167: Config.options.notifications.autoSilentOnScreenShare
129: Config.options.notifications.displayMode
187: Config.options.notifications.expandOnHover
194: Config.options.notifications.hoverExpandDelay
180: Config.options.notifications.maxVisible
154: Config.options.notifications.pauseOnHover
160: Config.options.notifications.showCriticalWhenQuiet
141: Config.options.notifications.style
331: Config.options.sessionScreen.columns
372: Config.options.sessionScreen.confirmDestructive
312: Config.options.sessionScreen.edge
323: Config.options.sessionScreen.edgeWidth
299: Config.options.sessionScreen.presentation
359: Config.options.sessionScreen.showFirmware
344: Config.options.sessionScreen.showHibernate
350: Config.options.sessionScreen.showTaskManager
365: Config.options.sessionScreen.showWarnings
```

## GeneralConfig

المصدر: `shell/modules/ii/settings/pages/GeneralConfig.qml` — 645 سطرًا.

```text
54: title: Translation.tr("Time")
95: text: {
107: text: DateTime.longDate
130: text: Translation.tr("Format")
142: { displayName: Translation.tr("24h"), value: "hh:mm" },
143: { displayName: Translation.tr("12h am/pm"), value: "h:mm ap" },
144: { displayName: Translation.tr("12h AM/PM"), value: "h:mm AP" }
149: text: Translation.tr("Second precision")
157: text: Translation.tr("Show date")
166: text: Translation.tr("Clock String Format")
167: placeholderText: Translation.tr("Clock String Format")
177: text: Translation.tr("Date String Format")
178: placeholderText: Translation.tr("Date String Format")
190: title: Translation.tr("Screen Canvas — Screenshot & Video Editor")
197: text: Translation.tr("Controls how the screenshot / video annotation canvas behaves: auto-open, close after save/copy, and editor defaults.")
201: ContentSubsectionLabel { text: Translation.tr("After capture") }
205: text: Translation.tr("Screenshots")
209: { displayName: Translation.tr("Open editor"), icon: "edit", value: "editor" },
210: { displayName: Translation.tr("Notify"), icon: "notifications", value: "notification" },
211: { displayName: Translation.tr("Just copy"), icon: "content_copy", value: "silent" }
216: text: Translation.tr("Recordings")
220: { displayName: Translation.tr("Open editor"), icon: "edit", value: "editor" },
221: { displayName: Translation.tr("Notify"), icon: "notifications", value: "notification" },
222: { displayName: Translation.tr("Just save"), icon: "save", value: "silent" }
230: text: {
240: ContentSubsectionLabel { text: Translation.tr("After Save / Copy") }
244: text: Translation.tr("Close after saving image")
250: text: Translation.tr("Close after exporting video")
256: text: Translation.tr("Close after copying image")
262: text: Translation.tr("Close after copying video")
268: text: Translation.tr("Click outside to close")
274: text: Translation.tr("Esc closes canvas")
280: text: Translation.tr("Confirm if unsaved annotations")
286: text: Translation.tr("Clear annotations when closing")
293: ContentSubsectionLabel { text: Translation.tr("Video editor") }
299: text: Translation.tr("Auto-play video on open")
305: text: Translation.tr("Loop playback")
312: text: Translation.tr("Start muted")
320: text: Translation.tr("Default annotation duration (s)")
331: ContentSubsectionLabel { text: Translation.tr("Canvas & defaults") }
335: text: Translation.tr("Default tool")
339: { displayName: Translation.tr("Pen"), icon: "draw", value: "pen" },
340: { displayName: Translation.tr("Arrow"), icon: "north_east", value: "arrow" },
341: { displayName: Translation.tr("Rect"), icon: "rectangle", value: "rect" },
342: { displayName: Translation.tr("Circle"), icon: "circle", value: "circle" },
343: { displayName: Translation.tr("Highlight"), icon: "ink_highlighter", value: "highlight" },
344: { displayName: Translation.tr("Blur"), icon: "blur_on", value: "blur" }
349: text: Translation.tr("Default stroke width")
363: text: Translation.tr("Default color")
388: text: Translation.tr("Also copy on save")
394: text: Translation.tr("Image save mode")
398: { displayName: Translation.tr("Edited suffix"), icon: "note_add", value: "editedSuffix" },
399: { displayName: Translation.tr("Overwrite"), icon: "save", value: "overwrite" },
400: { displayName: Translation.tr("Ask"), icon: "help", value: "ask" }
405: text: Translation.tr("Show notifications / toasts")
411: text: Translation.tr("Canvas dim opacity %")
423: text: Translation.tr("How it works: Screenshots — region → Copy saves & copies, Edit opens editor directly. These toggles control whether Copy also opens the canvas and whether Save/Copy auto-closes it. Videos — recording → notification action Edit or auto-open if enabled.")
430: title: Translation.tr("Battery")
438: text: Translation.tr("Low warning")
449: text: Translation.tr("Critical warning")
463: text: Translation.tr("Automatic suspend")
471: text: Translation.tr("at")
485: text: Translation.tr("Full warning")
501: title: Translation.tr("Audio")
505: text: Translation.tr("Earbang protection")
515: text: Translation.tr("Max allowed increase")
526: text: Translation.tr("Volume limit")
542: title: Translation.tr("Sounds")
546: text: Translation.tr("Battery")
555: text: Translation.tr("Pomodoro")
567: title: Translation.tr("Language")
573: text: Translation.tr("Interface Language")
576: { displayName: Translation.tr("Auto (System)"), value: "auto" },
577: ...Translation.allAvailableLanguages.map(lang => ({ displayName: lang, value: lang }))
597: text: Translation.tr("Locale code")
598: placeholderText: Translation.tr("e.g. fr_FR, de_DE, zh_CN...")
599: value: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
610: mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
624: title: Translation.tr("Work safety")
628: text: Translation.tr("Hide clipboard images copied from sussy sources")
636: text: Translation.tr("Hide sussy/anime wallpapers")
```

مسارات الخصائص المباشرة:

```text
506: Config.options.audio.protection.enable
527: Config.options.audio.protection.maxAllowed
516: Config.options.audio.protection.maxAllowedIncrease
464: Config.options.battery.automaticSuspend
450: Config.options.battery.critical
486: Config.options.battery.full
439: Config.options.battery.low
472: Config.options.battery.suspend
579: Config.options.language.ui
412: Config.options.screenCanvas.canvasDimOpacity
287: Config.options.screenCanvas.clearOnClose
269: Config.options.screenCanvas.closeOnClickOutside
257: Config.options.screenCanvas.closeOnCopyImage
263: Config.options.screenCanvas.closeOnCopyVideo
275: Config.options.screenCanvas.closeOnEsc
245: Config.options.screenCanvas.closeOnSaveImage
251: Config.options.screenCanvas.closeOnSaveVideo
281: Config.options.screenCanvas.confirmCloseWhenUnsaved
321: Config.options.screenCanvas.defaultAnnotationDuration
375: Config.options.screenCanvas.defaultColor
350: Config.options.screenCanvas.defaultStrokeWidth
336: Config.options.screenCanvas.defaultTool
206: Config.options.screenCanvas.imageResultMode
395: Config.options.screenCanvas.imageSaveMode
389: Config.options.screenCanvas.saveAlsoCopiesToClipboard
406: Config.options.screenCanvas.showNotifications
300: Config.options.screenCanvas.videoAutoPlayOnOpen
306: Config.options.screenCanvas.videoLoopPlayback
313: Config.options.screenCanvas.videoMutedOnOpen
217: Config.options.screenCanvas.videoResultMode
548: Config.options.sounds.battery
556: Config.options.sounds.pomodoro
179: Config.options.time.dateFormat
96: Config.options.time.format
73: Config.options.time.secondPrecision
158: Config.options.time.showDate
629: Config.options.workSafety.enable.clipboard
637: Config.options.workSafety.enable.wallpaper
```

## HyprlandSettings

المصدر: `shell/modules/ii/settings/pages/HyprlandSettings.qml` — 3285 سطرًا.

```text
230: title: Translation.tr("Displays")
241: title: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.name ?? "")
248: text: Translation.tr("Enabled")
260: text: Translation.tr("Resolution & Refresh Rate")
279: text: Translation.tr("Orientation")
287: { displayName: Translation.tr("Normal"), icon: "screen_rotation_alt", value: 0 },
288: { displayName: "90°",                    icon: "rotate_90_degrees_cw",  value: 1 },
289: { displayName: "180°",                   icon: "screen_rotation",       value: 2 },
290: { displayName: "270°",                   icon: "rotate_90_degrees_ccw", value: 3 },
296: text: Translation.tr("Scale")
309: text: Translation.tr("Position X")
321: text: Translation.tr("Position Y")
336: text: {
346: title: Translation.tr("Advanced Monitor Settings")
354: text: Translation.tr("Mirror")
357: let result = [{ displayName: Translation.tr("None"), value: "" }]
361: result.push({ displayName: monitorConfig.monitors[i].name, value: monitorConfig.monitors[i].name })
374: text: Translation.tr("Bit Depth")
382: { displayName: "8", icon: "looks_one", value: 8 },
383: { displayName: "10", icon: "looks_two", value: 10 }
389: text: Translation.tr("VRR")
397: { displayName: Translation.tr("Off"), icon: "block", value: 0 },
398: { displayName: Translation.tr("On"), icon: "check", value: 1 },
399: { displayName: Translation.tr("Fullscreen"), icon: "fullscreen", value: 2 }
407: text: Translation.tr("Color Management")
410: { displayName: Translation.tr("Auto"), value: "auto" },
411: { displayName: "sRGB", value: "srgb" },
412: { displayName: Translation.tr("Wide Color"), value: "wide" },
413: { displayName: "HDR", value: "hdr" },
414: { displayName: "EDID", value: "edid" }
426: text: Translation.tr("Reserved Area")
440: text: Translation.tr("Transform")
448: { displayName: Translation.tr("Normal"),  icon: "screen_rotation_alt",  value: 0 },
449: { displayName: "90°",                     icon: "rotate_90_degrees_cw",  value: 1 },
450: { displayName: "180°",                    icon: "screen_rotation",       value: 2 },
451: { displayName: "270°",                    icon: "rotate_90_degrees_ccw", value: 3 },
452: { displayName: Translation.tr("Flipped"), icon: "flip",                  value: 4 },
453: { displayName: "90° + Flip",             icon: "flip_camera_android",   value: 5 },
454: { displayName: "180° + Flip",            icon: "screen_lock_portrait",  value: 6 },
455: { displayName: "270° + Flip",            icon: "switch_video",          value: 7 }
467: title: Translation.tr("Layout")
471: text: Translation.tr("Tiling Layout")
479: { displayName: Translation.tr("Dwindle"),   icon: "browse",             value: "dwindle"   },
480: { displayName: Translation.tr("Master"),    icon: "auto_awesome_mosaic", value: "master"    },
481: { displayName: Translation.tr("Scrolling"), icon: "view_carousel",       value: "scrolling" },
488: title: Translation.tr("Dwindle")
492: text: Translation.tr("Preserve Split")
498: text: Translation.tr("Smart Split")
504: text: Translation.tr("Smart Resizing")
513: title: Translation.tr("Master")
516: text: Translation.tr("New Window Status")
521: { displayName: "Slave", icon: "person", value: "slave" },
522: { displayName: "Master", icon: "star", value: "master" },
523: { displayName: "Inherit", icon: "history", value: "inherit" }
527: text: Translation.tr("Master Factor")
534: text: Translation.tr("Orientation")
539: { displayName: Translation.tr("Left"), icon: "arrow_back", value: "left" },
540: { displayName: Translation.tr("Right"), icon: "arrow_forward", value: "right" },
541: { displayName: Translation.tr("Top"), icon: "arrow_upward", value: "top" },
542: { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" },
543: { displayName: Translation.tr("Center"), icon: "center_focus_strong", value: "center" }
550: title: Translation.tr("Group")
554: text: Translation.tr("Auto Group")
560: text: Translation.tr("Drag Into Group")
566: text: Translation.tr("Merge Groups On Drag")
572: text: Translation.tr("Group Bar Enabled")
584: title: Translation.tr("Input")
588: title: Translation.tr("Keyboard")
626: text: Translation.tr("Keyboard layouts")
646: text: modelData
657: text: "close"
683: { displayName: "us — English (US)", value: "us" },
684: { displayName: "ara — Arabic", value: "ara" },
685: { displayName: "eg — Arabic (Egypt)", value: "eg" },
686: { displayName: "sa — Arabic (Saudi)", value: "sa" },
687: { displayName: "fr — French", value: "fr" },
688: { displayName: "de — German", value: "de" },
689: { displayName: "es — Spanish", value: "es" },
690: { displayName: "ru — Russian", value: "ru" },
691: { displayName: "tr — Turkish", value: "tr" },
692: { displayName: "fa — Persian", value: "fa" },
693: { displayName: "ir — Persian (Iran)", value: "ir" },
694: { displayName: "gb — English (UK)", value: "gb" },
695: { displayName: "it — Italian", value: "it" },
696: { displayName: "latam — Latin American", value: "latam" },
697: { displayName: "in — Indian", value: "in" },
698: { displayName: "cn — Chinese", value: "cn" },
699: { displayName: "jp — Japanese", value: "jp" }
723: property string placeholderText: "ara"
735: text: "ara"
746: mainText: Translation.tr("Add")
765: text: Translation.tr("Hyprland uses comma-separated layouts. Example: us,ara. Indicator in bar shows active layout. Click bar indicator to switch.")
771: text: Translation.tr("Layout switch shortcut")
779: { displayName: Translation.tr("None"), value: "" },
780: { displayName: "Alt+Shift", value: "grp:alt_shift_toggle" },
781: { displayName: "Ctrl+Shift", value: "grp:ctrl_shift_toggle" },
782: { displayName: "Win+Space", value: "grp:win_space_toggle" },
783: { displayName: "Caps Lock", value: "grp:caps_toggle" },
784: { displayName: "Alt+Caps", value: "grp:alt_caps_toggle" },
785: { displayName: "Both Shifts", value: "grp:shifts_toggle" },
786: { displayName: "Both Alts", value: "grp:alts_toggle" },
787: { displayName: "Ctrl+Alt", value: "grp:ctrl_alt_toggle" },
788: { displayName: "Shift+Caps", value: "grp:shift_caps_toggle" }
796: text: Translation.tr("Extra XKB options")
797: placeholderText: Translation.tr("e.g., caps:swapescape, compose:ralt")
820: text: Translation.tr("Variant (per layout, comma-separated)")
821: placeholderText: Translation.tr("e.g., ,, or dvorak")
842: text: Translation.tr("Model")
843: placeholderText: "pc104"
861: text: Translation.tr("Rules")
862: placeholderText: "evdev"
879: text: Translation.tr("Numlock by default")
890: text: Translation.tr("Repeat delay (ms)")
902: text: Translation.tr("Repeat rate")
912: text: Translation.tr("Follow mouse")
920: { displayName: Translation.tr("Disabled"), icon: "mouse",     value: 0 },
921: { displayName: Translation.tr("Full"),     icon: "open_with",  value: 1 },
922: { displayName: Translation.tr("Loose"),    icon: "drag_pan",   value: 2 },
923: { displayName: Translation.tr("Explicit"), icon: "ads_click",  value: 3 },
930: title: Translation.tr("Touchpad")
934: text: Translation.tr("Natural scroll")
945: text: Translation.tr("Disable while typing")
956: text: Translation.tr("Clickfinger behavior")
967: text: Translation.tr("Scroll factor")
981: title: Translation.tr("Touchpad Advanced")
985: text: Translation.tr("Tap to Click")
994: text: Translation.tr("Tap Button Map")
1002: { displayName: "LRM", icon: "mouse", value: 0 },
1003: { displayName: "LMR", icon: "mouse", value: 1 }
1008: text: Translation.tr("Tap and Drag")
1018: text: Translation.tr("Drag Lock")
1032: title: Translation.tr("Mouse & Input")
1036: text: Translation.tr("Sensitivity")
1051: text: Translation.tr("Accel Profile")
1054: { displayName: Translation.tr("None"), value: "" },
1055: { displayName: "Flat", value: "flat" },
1056: { displayName: "Adaptive", value: "adaptive" }
1067: text: Translation.tr("Force No Accel")
1078: text: Translation.tr("Scroll Factor")
1091: text: Translation.tr("Scroll Button")
1103: text: Translation.tr("Left Handed")
1119: title: Translation.tr("Visual & Aesthetics")
1124: text: Translation.tr("Window Rounding")
1135: text: Translation.tr("Rounding Power")
1147: text: Translation.tr("Blur")
1175: text: Translation.tr("Blur Size")
1186: text: Translation.tr("Blur Passes")
1197: text: Translation.tr("Blur Vibrancy")
1209: text: Translation.tr("Blur XRay")
1219: text: Translation.tr("Blur New Optimizations")
1233: text: Translation.tr("Your running Hyprland doesn't support blur styles yet (decoration:blur:variant needs hyprwm/Hyprland PR #15661, merged 2026-08-22 — not in any tagged release yet, only in a from-source/-git build past that commit). Picking one below will be silently ignored until Hyprland is updated to a build that includes it; plain blur still works normally.")
1237: text: Translation.tr("Blur Style")
1251: { displayName: Translation.tr("Kawase (Classic)"), icon: "blur_on", value: "kawase" },
1252: { displayName: Translation.tr("Frost"), icon: "ac_unit", value: "frost" },
1253: { displayName: Translation.tr("Liquid Glass (Acrylic)"), icon: "water_drop", value: "acrylic" },
1254: { displayName: Translation.tr("Prism"), icon: "diamond", value: "prism" },
1255: { displayName: Translation.tr("Ripple"), icon: "waves", value: "ripple" },
1256: { displayName: Translation.tr("Drops"), icon: "water_drop", value: "drops" },
1257: { displayName: Translation.tr("Water"), icon: "water", value: "water" },
1258: { displayName: Translation.tr("Fluid Jar"), icon: "science", value: "fluid_jar" },
1259: { displayName: Translation.tr("Heat Shimmer"), icon: "thermostat", value: "heat_shimmer" },
1260: { displayName: Translation.tr("Aurora"), icon: "auto_awesome", value: "aurora" },
1261: { displayName: Translation.tr("Haze"), icon: "blur_circular", value: "haze" }
1269: text: Translation.tr("Native Hyprland blur variants (decoration:blur:variant, merged upstream Aug 2026) — applies to every window Hyprland blurs, not just this shell's panels. Fancier styles cost more GPU/CPU, especially the animated ones.")
1274: text: Translation.tr("Glass Refraction")
1286: text: Translation.tr("Glass Pattern Size")
1298: text: Translation.tr("Glass Roughness")
1311: text: Translation.tr("Liquid Glass Refraction")
1323: text: Translation.tr("Liquid Glass Edge Width")
1335: text: Translation.tr("Liquid Glass Clarity")
1348: text: Translation.tr("Liquid Glass Chromatic Aberration")
1361: text: Translation.tr("Liquid Glass Tint (0xAARRGGBB)")
1363: placeholderText: "0x14EEF5FF"
1374: text: Translation.tr("Ripple Strength")
1386: text: Translation.tr("Ripple Radius")
1398: text: Translation.tr("Ripple Wave Width")
1410: text: Translation.tr("Ripple Duration")
1424: text: Translation.tr("Drops Speed (0 = still, costs more GPU above 0)")
1437: text: Translation.tr("Water Strength")
1449: text: Translation.tr("Water Pointer Radius")
1461: text: Translation.tr("Water Propagation Speed")
1474: text: Translation.tr("Water Damping")
1487: text: Translation.tr("Water Max Duration (s)")
1501: text: Translation.tr("Fluid Jar Color (0xAARRGGBB)")
1503: placeholderText: "0xCC3399FF"
1513: text: Translation.tr("Fluid Jar Speed")
1526: text: Translation.tr("Fluid Jar Fill Amount")
1539: text: Translation.tr("Fluid Jar Mass")
1552: text: Translation.tr("Fluid Jar Precision (2x recommended, 4x+ expensive)")
1565: text: Translation.tr("Fluid Jar Turbulence")
1578: text: Translation.tr("Fluid Jar Distortion")
1591: text: Translation.tr("Heat Shimmer Speed (0 = still, costs more GPU above 0)")
1604: text: Translation.tr("Aurora Speed (0 = frozen, costs more GPU above 0)")
1616: text: Translation.tr("Aurora Intensity")
1629: text: Translation.tr("Aurora Color 1 (0xAARRGGBB)")
1631: placeholderText: "0x29F0A0FF"
1641: text: Translation.tr("Aurora Color 2 (0xAARRGGBB)")
1643: placeholderText: "0x7A4DFFFF"
1654: text: Translation.tr("Haze Intensity")
1667: text: Translation.tr("Haze Iridescence")
1679: text: Translation.tr("Border Size")
1690: text: Translation.tr("Gaps In")
1701: text: Translation.tr("Gaps Out")
1712: text: Translation.tr("Gaps Workspaces")
1723: text: Translation.tr("Active Opacity")
1735: text: Translation.tr("Inactive Opacity")
1747: text: Translation.tr("Fullscreen Opacity")
1759: text: Translation.tr("Dim Inactive")
1769: text: Translation.tr("Dim Strength")
1782: text: Translation.tr("Dim Special")
1794: text: Translation.tr("Border Part Of Window")
1805: text: Translation.tr("Shadow Enabled")
1815: text: Translation.tr("Shadow Range")
1827: text: Translation.tr("Shadow Render Power")
1839: text: Translation.tr("Shadow Sharp")
1850: text: Translation.tr("Shadow Offset X")
1862: text: Translation.tr("Shadow Offset Y")
1874: text: Translation.tr("Shadow Scale")
1889: text: Translation.tr("Shadow Inactive Color")
1890: placeholderText: "rgba(00000020)"
1902: title: Translation.tr("Advanced Decoration")
1907: text: Translation.tr("Dim Modal")
1918: text: Translation.tr("Dim Around")
1931: title: Translation.tr("Advanced Blur")
1935: text: Translation.tr("Noise")
1948: text: Translation.tr("Contrast")
1961: text: Translation.tr("Brightness")
1974: text: Translation.tr("Vibrancy Darkness")
1988: text: Translation.tr("Blur Special")
1999: text: Translation.tr("Blur Popups")
2010: text: Translation.tr("Popups Ignore Alpha")
2027: title: Translation.tr("General & Snap")
2031: text: Translation.tr("Resize On Border")
2041: text: Translation.tr("Allow Tearing")
2051: text: Translation.tr("Snap Enabled")
2061: text: Translation.tr("Snap Window Gap")
2073: text: Translation.tr("Snap Monitor Gap")
2085: text: Translation.tr("Snap Border Overlap")
2096: text: Translation.tr("Snap Respect Gaps")
2109: title: Translation.tr("Advanced General Settings")
2115: text: Translation.tr("Active Border Color")
2116: placeholderText: Translation.tr("rgba(33, 33, 33, 1.0)")
2128: text: Translation.tr("Inactive Border Color")
2129: placeholderText: Translation.tr("rgba(33, 33, 33, 0.8)")
2141: text: Translation.tr("Nogroup Border Color")
2142: placeholderText: Translation.tr("rgba(33, 33, 33, 0.8)")
2153: text: Translation.tr("Float Gaps")
2165: text: Translation.tr("Extend Border Grab Area")
2176: text: Translation.tr("Hover Icon On Border")
2187: text: Translation.tr("No Focus Fallback")
2203: title: Translation.tr("Misc")
2207: text: Translation.tr("Disable Hyprland Logo")
2217: text: Translation.tr("Disable Splash Rendering")
2226: text: Translation.tr("VRR")
2234: { displayName: Translation.tr("Off"), icon: "block", value: 0 },
2235: { displayName: Translation.tr("On"), icon: "check", value: 1 },
2236: { displayName: Translation.tr("Fullscreen Only"), icon: "fullscreen", value: 2 }
2241: text: Translation.tr("Mouse Move Enables DPMS")
2251: text: Translation.tr("Key Press Enables DPMS")
2261: text: Translation.tr("Animate Manual Resizes")
2271: text: Translation.tr("Animate Mouse Window Dragging")
2280: text: Translation.tr("Focus On Activate")
2288: { displayName: "0 - Next candidate", icon: "looks_one", value: 0 },
2289: { displayName: "1 - Window under cursor", icon: "mouse", value: 1 },
2290: { displayName: "2 - Most recent", icon: "history", value: 2 }
2300: title: Translation.tr("Cursor")
2304: text: Translation.tr("Zoom Factor")
2316: text: Translation.tr("Zoom Rigid")
2326: text: Translation.tr("Hide On Key Press")
2336: text: Translation.tr("Inactive Timeout (s)")
2347: text: Translation.tr("Hotspot Padding")
2358: text: Translation.tr("No Warps")
2368: text: Translation.tr("Persistent Warps")
2383: title: Translation.tr("Gestures")
2387: text: Translation.tr("Workspace Swipe Distance")
2398: text: Translation.tr("Swipe Cancel Ratio (%)")
2410: text: Translation.tr("Swipe Min Speed")
2421: text: Translation.tr("Swipe Direction Lock")
2437: title: Translation.tr("Custom Binds (Advanced)")
2444: text: Translation.tr("Add any hl.bind(...) lines. File is ~/.config/hypr/custom/keybinds.lua and is auto-sourced by hyprland.lua. Example: hl.bind(\"SUPER + T\", hl.dsp.exec_cmd(\"kitty\"))")
2456: text: Config.options.hyprland.customBindsLua
2457: placeholderText: "-- hl.bind(\"SUPER + T\", hl.dsp.exec_cmd(\"kitty\"))"
2471: mainText: Translation.tr("Save Binds")
2477: mainText: Translation.tr("Reload Hyprland")
2504: title: Translation.tr("Custom Window Rules (Advanced)")
2511: text: Translation.tr("Add any hl.window_rule / hl.workspace_rule / hl.layer_rule lines. File is ~/.config/hypr/custom/rules.lua. Example: hl.window_rule({match={class=\"kitty\"}, float=true})")
2523: text: Config.options.hyprland.customRulesLua
2524: placeholderText: "-- hl.window_rule({match={class=\"kitty\"}, float=true})"
2538: mainText: Translation.tr("Save Rules")
2544: mainText: Translation.tr("Reload Hyprland")
2567: title: Translation.tr("Workspace Rules")
2574: text: Translation.tr("Bind workspaces to monitors, set per-workspace gaps, border, rounding, etc. Each rule generates a hl.workspace_rule() line.")
2596: text: modelData.workspace || "*"
2603: text: modelData.monitor || ""
2610: text: {
2617: if (modelData.defaultName) props.push("name:" + modelData.defaultName)
2628: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
2647: StyledText { visible: newWrWorkspace.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "ws"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
2653: StyledText { visible: newWrMonitor.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "monitor"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
2656: materialIcon: "add"; mainText: Translation.tr("Add")
2670: StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Workspace: number/name/* for all. Monitor: output name or empty. Example: '1' on 'DP-1' binds workspace 1 to DP-1.") }
2680: mainText: Translation.tr("Save")
2723: title: Translation.tr("Window Rules (Structured)")
2730: text: Translation.tr("Apply rules to windows by class/title. Each rule generates a hl.window_rule() line.")
2751: text: modelData.class || modelData.title || "*"
2758: text: {
2778: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
2797: StyledText { visible: newWrClass.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "class"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
2799: StyledText { text: Translation.tr("→"); color: Appearance.colors.colSubtext }
2804: { displayName: "Float", value: "float" },
2805: { displayName: "Pin", value: "pinned" },
2806: { displayName: "No Focus", value: "nofocus" },
2807: { displayName: "No Shadow", value: "noshadow" },
2808: { displayName: "No Blur", value: "noblur" },
2809: { displayName: "None", value: "" }
2814: materialIcon: "add"; mainText: Translation.tr("Add")
2830: StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Match by class name. Actions: Float, Pin, No Focus, No Shadow, No Blur (per-window blur/glass opt-out — blur itself is configured globally under Settings > Hyprland > Blur Style). For advanced rules, use the Custom Rules textarea below.") }
2838: mainText: Translation.tr("Save")
2880: title: Translation.tr("Autostart Apps")
2890: title: Translation.tr("Animations")
2894: text: Translation.tr("Enable")
2904: text: Translation.tr("Workspace Wraparound")
2914: text: Translation.tr("Custom Editor (advanced)")
2929: text: Translation.tr("Presets")
2942: { displayName: Translation.tr("Smooth"),         icon: "animation",             value: "smooth"         },
2943: { displayName: Translation.tr("Snappy"),         icon: "bolt",                  value: "snappy"         },
2944: { displayName: Translation.tr("Expressive"),     icon: "move_selection_right",  value: "expressive"     },
2945: { displayName: Translation.tr("Reduced Motion"), icon: "accessibility_new",     value: "reduced_motion" },
2946: { displayName: Translation.tr("Niri Like"),      icon: "mobiledata_arrows",     value: "niri"           },
2957: text: {
2989: title: Translation.tr("Curves (bezier / spring)")
3008: StyledText { text: modelData.name; color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 120; elide: Text.ElideRight }
3009: StyledText { text: modelData.type; color: Appearance.colors.colSubtext; Layout.preferredWidth: 60 }
3015: text: {
3023: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
3042: property string placeholderText: "myCurve"
3044: StyledText { visible: newCurveName.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "name"; color: Appearance.colors.colSubtext }
3047: id: newCurveType; Layout.preferredWidth: 110; model: [{displayName:"bezier", value:"bezier"}, {displayName:"spring", value:"spring"}]; textRole: "displayName"
3050: materialIcon: "add"; mainText: Translation.tr("Add")
3057: if (t==="spring") arr.push({name:n, type:"spring", mass:1, stiffness:100, damping:15})
3058: else arr.push({name:n, type:"bezier", points:[[0.4,0],[0.2,1]]})
3066: StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Bezier: points {x0,y0} {x1,y1} (0-1+) — Spring: mass 1, stiffness 50-500, damping 5-50. Example presets imported from hyprland.lua: easeOutQuint, easy (spring).") }
3069: materialIcon: "download"; mainText: Translation.tr("Load Preset Into Custom")
3074: {name:"emphasizedDecel", type:"bezier", points:[[0.05,0.7],[0.1,1]]},
3075: {name:"emphasizedAccel", type:"bezier", points:[[0.3,0],[0.8,0.15]]},
3076: {name:"menu_decel", type:"bezier", points:[[0.1,1],[0,1]]},
3077: {name:"menu_accel", type:"bezier", points:[[0.52,0.03],[0.72,0.08]]},
3078: {name:"stall", type:"bezier", points:[[1,-0.1],[0.7,0.85]]}
3096: materialIcon: "save"; mainText: Translation.tr("Apply Custom")
3107: title: Translation.tr("Animation Tree (inherits parent if unset)")
3115: StyledText { text: Translation.tr("Leaf"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 140; font.pixelSize: Appearance.font.pixelSize.smaller }
3116: StyledText { text: Translation.tr("Enabled"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 70; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
3117: StyledText { text: Translation.tr("Speed (ds)"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 90; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
3118: StyledText { text: Translation.tr("Curve"); color: Appearance.colors.colSubtext; Layout.fillWidth: true; font.pixelSize: Appearance.font.pixelSize.smaller }
3119: StyledText { text: Translation.tr("Style"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 110; font.pixelSize: Appearance.font.pixelSize.smaller }
3134: StyledText { text: modelData.leaf; color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 140; elide: Text.ElideRight; font.pixelSize: Appearance.font.pixelSize.small }
3149: text: String(modelData.speed)
3163: let names = Config.options.hyprland.animations.customCurves.map(c=>({displayName:c.name, value:c.name}))
3164: names.unshift({displayName:"default", value:"default"})
3191: text: modelData.style || ""
3192: property string placeholderText: "slide"
3203: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
3220: {displayName:"global", value:"global"}, {displayName:"windows", value:"windows"}, {displayName:"windowsIn", value:"windowsIn"}, {displayName:"windowsOut", value:"windowsOut"}, {displayName:"windowsMove", value:"windowsMove"},
3221: {displayName:"layers", value:"layers"}, {displayName:"layersIn", value:"layersIn"}, {displayName:"layersOut", value:"layersOut"},
3222: {displayName:"fade", value:"fade"}, {displayName:"fadeIn", value:"fadeIn"}, {displayName:"fadeOut", value:"fadeOut"}, {displayName:"fadeSwitch", value:"fadeSwitch"}, {displayName:"fadeShadow", value:"fadeShadow"}, {displayName:"fadeDim", value:"fadeDim"}, {displayName:"fadeLayers", value:"fadeLayers"}, {displayName:"fadeLayersIn", value:"fadeLayersIn"}, {displayName:"fadeLayersOut", value:"fadeLayersOut"}, {displayName:"fadePopups", value:"fadePopups"}, {displayName:"fadePopupsIn", value:"fadePopupsIn"}, {displayName:"fadePopupsOut", value:"fadePopupsOut"}, {displayName:"fadeDpms", value:"fadeDpms"},
3223: {displayName:"border", value:"border"}, {displayName:"borderangle", value:"borderangle"}, {displayName:"shadowangle", value:"shadowangle"}, {displayName:"glowangle", value:"glowangle"}, {displayName:"workspaces", value:"workspaces"}, {displayName:"workspacesIn", value:"workspacesIn"}, {displayName:"workspacesOut", value:"workspacesOut"}, {displayName:"specialWorkspace", value:"specialWorkspace"}, {displayName:"specialWorkspaceIn", value:"specialWorkspaceIn"}, {displayName:"specialWorkspaceOut", value:"specialWorkspaceOut"}, {displayName:"zoomFactor", value:"zoomFactor"}, {displayName:"monitorAdded", value:"monitorAdded"}
3227: materialIcon: "add"; mainText: Translation.tr("Add leaf")
3239: StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Speed: 1ds=100ms. Styles: windows/layers → slide/popin/gnomed, workspaces → slide/slidevert/fade/slidefade, borderangle → once/loop, popin needs % e.g. popin 80%. Leave empty to inherit parent.") }
3248: text: Translation.tr("New installs load this file automatically. If nothing changes when you pick a preset, your hyprland.lua predates that and needs this line added manually:") + '\n\nrequire("hyprland/shellOverrides/animations")'
3258: mainText: justCopied ? Translation.tr("Copied!") : Translation.tr("Copy line")
```

مسارات الخصائص المباشرة:

```text
1157: Config.options.appearance.visualEffect
61: Config.options.hyprland
2931: Config.options.hyprland.animations.animation
52: Config.options.hyprland.animations.customAnims
3139: Config.options.hyprland.animations.customAnims.slice
51: Config.options.hyprland.animations.customCurves
3177: Config.options.hyprland.animations.customCurves.find
3163: Config.options.hyprland.animations.customCurves.map
3025: Config.options.hyprland.animations.customCurves.slice
2915: Config.options.hyprland.animations.customEnabled
2895: Config.options.hyprland.animations.enable
2905: Config.options.hyprland.animations.workspaceWraparound
2327: Config.options.hyprland.cursor.hideOnKeyPress
2348: Config.options.hyprland.cursor.hotspotPadding
2337: Config.options.hyprland.cursor.inactiveTimeout
2359: Config.options.hyprland.cursor.noWarps
2369: Config.options.hyprland.cursor.persistentWarps
2305: Config.options.hyprland.cursor.zoomFactor
2317: Config.options.hyprland.cursor.zoomRigid
2456: Config.options.hyprland.customBindsLua
2523: Config.options.hyprland.customRulesLua
1724: Config.options.hyprland.decoration.activeOpacity
1349: Config.options.hyprland.decoration.blur.acrylic.aberration
1324: Config.options.hyprland.decoration.blur.acrylic.bulb
1336: Config.options.hyprland.decoration.blur.acrylic.clarity
1312: Config.options.hyprland.decoration.blur.acrylic.refraction
1362: Config.options.hyprland.decoration.blur.acrylic.tint
1630: Config.options.hyprland.decoration.blur.aurora.color1
1642: Config.options.hyprland.decoration.blur.aurora.color2
1617: Config.options.hyprland.decoration.blur.aurora.intensity
1605: Config.options.hyprland.decoration.blur.aurora.speed
1963: Config.options.hyprland.decoration.blur.brightness
1950: Config.options.hyprland.decoration.blur.contrast
1425: Config.options.hyprland.decoration.blur.drops.speed
1148: Config.options.hyprland.decoration.blur.enabled
1502: Config.options.hyprland.decoration.blur.fluidJar.color
1579: Config.options.hyprland.decoration.blur.fluidJar.distortion
1527: Config.options.hyprland.decoration.blur.fluidJar.fillAmount
1540: Config.options.hyprland.decoration.blur.fluidJar.mass
1553: Config.options.hyprland.decoration.blur.fluidJar.precision
1514: Config.options.hyprland.decoration.blur.fluidJar.speed
1566: Config.options.hyprland.decoration.blur.fluidJar.turbulence
1275: Config.options.hyprland.decoration.blur.glass.refraction
1299: Config.options.hyprland.decoration.blur.glass.roughness
1287: Config.options.hyprland.decoration.blur.glass.size
1655: Config.options.hyprland.decoration.blur.haze.intensity
1668: Config.options.hyprland.decoration.blur.haze.iridescence
1592: Config.options.hyprland.decoration.blur.heatShimmer.speed
1220: Config.options.hyprland.decoration.blur.newOptimizations
1937: Config.options.hyprland.decoration.blur.noise
1187: Config.options.hyprland.decoration.blur.passes
2000: Config.options.hyprland.decoration.blur.popups
2011: Config.options.hyprland.decoration.blur.popupsIgnorealpha
1411: Config.options.hyprland.decoration.blur.ripple.duration
1387: Config.options.hyprland.decoration.blur.ripple.radius
1375: Config.options.hyprland.decoration.blur.ripple.strength
1399: Config.options.hyprland.decoration.blur.ripple.width
1176: Config.options.hyprland.decoration.blur.size
1989: Config.options.hyprland.decoration.blur.special
1169: Config.options.hyprland.decoration.blur.variant
1198: Config.options.hyprland.decoration.blur.vibrancy
1976: Config.options.hyprland.decoration.blur.vibrancyDarkness
1475: Config.options.hyprland.decoration.blur.water.damping
1488: Config.options.hyprland.decoration.blur.water.duration
1450: Config.options.hyprland.decoration.blur.water.radius
1462: Config.options.hyprland.decoration.blur.water.speed
1438: Config.options.hyprland.decoration.blur.water.strength
1210: Config.options.hyprland.decoration.blur.xray
1795: Config.options.hyprland.decoration.borderPartOfWindow
1919: Config.options.hyprland.decoration.dimAround
1760: Config.options.hyprland.decoration.dimInactive
1908: Config.options.hyprland.decoration.dimModal
1783: Config.options.hyprland.decoration.dimSpecial
1770: Config.options.hyprland.decoration.dimStrength
1748: Config.options.hyprland.decoration.fullscreenOpacity
1736: Config.options.hyprland.decoration.inactiveOpacity
1125: Config.options.hyprland.decoration.rounding
1136: Config.options.hyprland.decoration.roundingPower
1891: Config.options.hyprland.decoration.shadow.colorInactive
1806: Config.options.hyprland.decoration.shadow.enabled
1851: Config.options.hyprland.decoration.shadow.offsetX
1857: Config.options.hyprland.decoration.shadow.offsetY
1816: Config.options.hyprland.decoration.shadow.range
1828: Config.options.hyprland.decoration.shadow.renderPower
1875: Config.options.hyprland.decoration.shadow.scale
1840: Config.options.hyprland.decoration.shadow.sharp
493: Config.options.hyprland.dwindle.preserveSplit
505: Config.options.hyprland.dwindle.smartResizing
499: Config.options.hyprland.dwindle.smartSplit
2042: Config.options.hyprland.general.allowTearing
1680: Config.options.hyprland.general.borderSize
2117: Config.options.hyprland.general.colActiveBorder
2130: Config.options.hyprland.general.colInactiveBorder
2143: Config.options.hyprland.general.colNogroupBorder
2166: Config.options.hyprland.general.extendBorderGrabArea
2154: Config.options.hyprland.general.floatGaps
1691: Config.options.hyprland.general.gapsIn
1702: Config.options.hyprland.general.gapsOut
1713: Config.options.hyprland.general.gapsWorkspaces
2177: Config.options.hyprland.general.hoverIconOnBorder
473: Config.options.hyprland.general.layout
2188: Config.options.hyprland.general.noFocusFallback
2032: Config.options.hyprland.general.resizeOnBorder
2086: Config.options.hyprland.general.snapBorderOverlap
2052: Config.options.hyprland.general.snapEnabled
2074: Config.options.hyprland.general.snapMonitorGap
2097: Config.options.hyprland.general.snapRespectGaps
2062: Config.options.hyprland.general.snapWindowGap
2737: Config.options.hyprland.general.windowRules
2780: Config.options.hyprland.general.windowRules.slice
2582: Config.options.hyprland.general.workspaceRules
2630: Config.options.hyprland.general.workspaceRules.slice
2399: Config.options.hyprland.gestures.workspaceSwipeCancelRatio
2422: Config.options.hyprland.gestures.workspaceSwipeDirectionLock
2388: Config.options.hyprland.gestures.workspaceSwipeDistance
2411: Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce
555: Config.options.hyprland.group.autoGroup
561: Config.options.hyprland.group.dragIntoGroup
573: Config.options.hyprland.group.groupbar.enabled
567: Config.options.hyprland.group.mergeGroupsOnDrag
1058: Config.options.hyprland.input.accelProfile
914: Config.options.hyprland.input.followMouse
1068: Config.options.hyprland.input.forceNoAccel
608: Config.options.hyprland.input.kbLayout
593: Config.options.hyprland.input.kbLayoutSwitchShortcut
844: Config.options.hyprland.input.kbModel
592: Config.options.hyprland.input.kbOptions
863: Config.options.hyprland.input.kbRules
822: Config.options.hyprland.input.kbVariant
1104: Config.options.hyprland.input.leftHanded
880: Config.options.hyprland.input.numlock
891: Config.options.hyprland.input.repeatDelay
903: Config.options.hyprland.input.repeatRate
1092: Config.options.hyprland.input.scrollButton
1079: Config.options.hyprland.input.scrollFactor
1038: Config.options.hyprland.input.sensitivity
957: Config.options.hyprland.input.touchpad.clickfingerBehavior
946: Config.options.hyprland.input.touchpad.disableWhileTyping
1019: Config.options.hyprland.input.touchpad.dragLock
935: Config.options.hyprland.input.touchpad.naturalScroll
968: Config.options.hyprland.input.touchpad.scrollFactor
1009: Config.options.hyprland.input.touchpad.tapAndDrag
996: Config.options.hyprland.input.touchpad.tapButtonMap
986: Config.options.hyprland.input.touchpad.tapToClick
529: Config.options.hyprland.master.mfact
518: Config.options.hyprland.master.newStatus
536: Config.options.hyprland.master.orientation
2262: Config.options.hyprland.misc.animateManualResizes
2272: Config.options.hyprland.misc.animateMouseWindowDragging
2208: Config.options.hyprland.misc.disableHyprlandLogo
2218: Config.options.hyprland.misc.disableSplashRendering
2282: Config.options.hyprland.misc.focusOnActivate
2252: Config.options.hyprland.misc.keyPressEnablesDpms
2242: Config.options.hyprland.misc.mouseMoveEnablesDpms
2228: Config.options.hyprland.misc.vrr
```

## InterfaceConfig

المصدر: `shell/modules/ii/settings/pages/InterfaceConfig.qml` — 2046 سطرًا.

```text
17: { name: "clock", label: Translation.tr("Clock"), icon: "schedule" },
18: { name: "weather", label: Translation.tr("Weather"), icon: "partly_cloudy_day" },
19: { name: "calendar", label: Translation.tr("Calendar"), icon: "calendar_month" },
20: { name: "worldClock", label: Translation.tr("World clock"), icon: "public" },
21: { name: "notes", label: Translation.tr("Notes"), icon: "sticky_note_2" },
22: { name: "todo", label: Translation.tr("To-do list"), icon: "checklist" },
23: { name: "userCard", label: Translation.tr("User card"), icon: "badge" },
24: { name: "media", label: Translation.tr("Media player"), icon: "music_note" },
25: { name: "timers", label: Translation.tr("Timers"), icon: "timer" },
26: { name: "images", label: Translation.tr("Images"), icon: "image" },
27: { name: "visualizer", label: Translation.tr("Audio visualizer"), icon: "graphic_eq" },
28: { name: "visualizerMirror", label: Translation.tr("Mirrored visualizer"), icon: "vertical_align_center" },
29: { name: "fullMonitorVisualizer", label: Translation.tr("Full monitor visualizer"), icon: "fullscreen" },
30: { name: "customImage", label: Translation.tr("Custom image"), icon: "photo" },
31: { name: "resources", label: Translation.tr("System resources"), icon: "monitoring" },
32: { name: "networkInfo", label: Translation.tr("Network info"), icon: "wifi" },
33: { name: "uptime", label: Translation.tr("Uptime"), icon: "hourglass_top" },
34: { name: "systemHistory", label: Translation.tr("System history graphs"), icon: "monitor_heart" }
78: title: Translation.tr("Screens & workspaces")
83: text: Translation.tr("Use one workspace set across all screens")
99: title: Translation.tr("Appearance")
103: text: Translation.tr("Extra Background Tint")
108: text: Translation.tr("Fake Screen Rounding")
113: { displayName: Translation.tr("None"), icon: "block", value: 0 },
114: { displayName: Translation.tr("Always"), icon: "check", value: 1 },
115: { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
120: title: Translation.tr("Visual Effect")
125: text: Translation.tr("Panel style")
144: { displayName: Translation.tr("None"), icon: "block", value: "none" },
145: { displayName: Translation.tr("Blur"), icon: "blur_on", value: "blur" },
146: { displayName: Translation.tr("Transparency"), icon: "opacity", value: "transparency" },
147: { displayName: Translation.tr("Liquid Glass"), icon: "water_drop", value: "glass" }
155: text: Translation.tr("What each one actually changes:\n• None - shell panels are painted solid. Compositor blur is turned off.\n• Blur - turns Hyprland's blur on (decoration:blur) and makes this shell's own panels translucent so there is something for it to show through. Windows stay opaque unless you also turn on the switch below.\n• Transparency - only this shell's panels; the compositor is left alone, so what shows through is the raw wallpaper/windows, unblurred. The sliders below set how much.\n• Liquid Glass - Blur plus Hyprland's \"acrylic\" blur variant (decoration:blur:variant), which adds refraction and tint on top.\nAll three of the non-None options are mutually exclusive, and none of them touch app windows' own opacity.")
171: text: Translation.tr("Your running Hyprland has no decoration:blur:variant support (it needs a build newer than any tagged release), so the compositor half of Liquid Glass - the refraction and tint on windows - is being ignored. What you're seeing is the shell's own panel translucency over ordinary blur. Settings > Hyprland > Blur Style has the details.")
176: title: Translation.tr("Window Transparency (for Blur/Glass)")
185: text: Translation.tr("Panel translucency")
194: text: Translation.tr("Make regular app windows slightly transparent")
216: text: Translation.tr("Blur/Glass only shows through a window that isn't fully opaque — a normal app window has no transparency of its own, so the effect stays invisible on it even though it now applies compositor-wide. This gives every window (focused and unfocused) a modest default transparency so Blur/Glass is visible everywhere without hand-writing a windowrulev2 opacity rule per app. Off by default — no visual change until you turn it on. Fine-tune the exact amounts under Settings > Hyprland > Decoration (\"Active/Inactive Opacity\"), or exclude specific apps there via Window Rules.")
221: title: Translation.tr("Transparency")
226: text: Translation.tr("Automatic (disables Background slider)")
232: text: Translation.tr("Background")
241: text: Translation.tr("Content")
252: title: Translation.tr("Liquid Glass")
256: text: Translation.tr("Glass opacity")
269: text: Translation.tr("Liquid Glass is Hyprland's native \"acrylic\" blur variant, applied compositor-wide to every window. Fine-tune refraction, tint and the other blur styles under Settings > Hyprland > Blur Style.")
274: title: Translation.tr("Motion")
277: text: Translation.tr("Animation style")
282: { displayName: Translation.tr("Smooth"), icon: "water", value: "smooth" },
283: { displayName: Translation.tr("Expressive"), icon: "auto_awesome", value: "expressive" }
287: text: Translation.tr("Animation speed")
297: title: Translation.tr("Palette")
300: text: Translation.tr("Palette Type")
305: { displayName: "Auto", display: "Auto", value: "auto" },
306: { displayName: "Tonal Spot", display: "Tonal Spot", value: "scheme-tonal-spot" },
307: { displayName: "Expressive", display: "Expressive", value: "scheme-expressive" },
308: { displayName: "Vibrant", display: "Vibrant", value: "scheme-vibrant" },
309: { displayName: "Rainbow", display: "Rainbow", value: "scheme-rainbow" },
310: { displayName: "Fruit Salad", display: "Fruit Salad", value: "scheme-fruit-salad" },
311: { displayName: "Monochrome", display: "Monochrome", value: "scheme-monochrome" }
318: text: Translation.tr("Accent Color (hex, empty=auto)")
319: placeholderText: "#ff0000"
331: title: Translation.tr("Settings Panel")
334: text: Translation.tr("Style")
339: { displayName: Translation.tr("Default"), icon: "settings_panorama", value: "default" },
340: { displayName: Translation.tr("Minimal"), icon: "settings_heart", value: "minimal" }
345: text: Translation.tr("Border width")
354: text: Translation.tr("Border Color")
367: title: Translation.tr("Left Sidebar")
388: text: "music_note_2"
393: text: Translation.tr("Media Player")
404: text: Translation.tr("Enable")
410: text: Translation.tr("Follow Album Colors")
436: text: "smart_toy"
441: text: Translation.tr("AI")
452: { displayName: Translation.tr("No"), icon: "close", value: 0 },
453: { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
454: { displayName: Translation.tr("Local"), icon: "sync_saved_locally", value: 2 }
474: text: "playing_cards"
479: text: Translation.tr("Weeb")
490: { displayName: Translation.tr("No"), icon: "close", value: 0 },
491: { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
492: { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
518: text: Translation.tr("Enable Translator")
530: title: Translation.tr("Right Sidebar")
535: text: Translation.tr('Banner')
544: text: Translation.tr('Bottom Group')
553: text: Translation.tr('Media Player')
562: text: Translation.tr('Keep right sidebar loaded')
571: title: Translation.tr("Quick toggles")
574: text: Translation.tr("Style")
583: displayName: Translation.tr("Classic"),
588: displayName: Translation.tr("Android"),
597: text: Translation.tr("Columns")
610: title: Translation.tr("Sliders")
614: text: Translation.tr("Enable")
623: text: Translation.tr("Brightness")
633: text: Translation.tr("Volume")
643: text: Translation.tr("Microphone")
657: title: Translation.tr("Hot Corners")
660: title: Translation.tr("Top")
665: text: Translation.tr("Enable")
671: text: Translation.tr("Hover to trigger")
677: text: Translation.tr("Place at bottom")
683: text: Translation.tr("Value scroll")
689: text: Translation.tr("Visualize region")
696: text: Translation.tr("Force hover at absolute corner")
703: text: Translation.tr("Enable hover trigger on bottom corners")
710: text: Translation.tr("Vertical offset")
717: text: Translation.tr("Region width")
724: text: Translation.tr("Region height")
732: text: Translation.tr("Top-left action")
742: text: Translation.tr("Top-right action")
751: text: Translation.tr("Left-corner scroll")
755: { displayName: Translation.tr("Brightness"), icon: "brightness_6", value: "brightness" },
756: { displayName: Translation.tr("Volume"), icon: "volume_up", value: "volume" }
761: text: Translation.tr("Right-corner scroll")
765: { displayName: Translation.tr("Volume"), icon: "volume_up", value: "volume" },
766: { displayName: Translation.tr("Brightness"), icon: "brightness_6", value: "brightness" }
772: title: Translation.tr("Bottom")
777: text: Translation.tr("Bottom-left")
787: text: Translation.tr("Bottom-right")
802: title: Translation.tr("Overview")
807: text: Translation.tr("Show workspaces in launcher (SUPER)")
813: text: Translation.tr("Show preview on hover over workspaces in bar")
818: text: Translation.tr("Launcher Position")
823: { displayName: Translation.tr("Top"), display: Translation.tr("Top - results below"), value: "top" },
824: { displayName: Translation.tr("Bottom"), display: Translation.tr("Bottom - results above"), value: "bottom" },
825: { displayName: Translation.tr("Center"), display: Translation.tr("Center - centered"), value: "center" }
830: text: Translation.tr("Animate center position")
835: text: Translation.tr("Center animation delay (ms)")
845: text: Translation.tr("Enable")
853: text: Translation.tr("Center icons")
861: text: Translation.tr("Scale (%)")
871: text: Translation.tr("Style")
879: displayName: Translation.tr("Default"),
884: displayName: Translation.tr("Niri Like"),
893: title: Translation.tr("Default Settings")
903: text: Translation.tr("Rows")
914: text: Translation.tr("Columns")
938: displayName: Translation.tr("Left to right"),
943: displayName: Translation.tr("Right to left"),
957: displayName: Translation.tr("Top-down"),
962: displayName: Translation.tr("Bottom-up"),
975: title: Translation.tr("Dock")
981: text: Translation.tr("Enable")
987: text: Translation.tr("Background")
993: text: Translation.tr("Hover to reveal")
999: text: Translation.tr("Pinned on startup")
1007: title: Translation.tr("Buttons & Media")
1011: text: Translation.tr("Media Player")
1017: text: Translation.tr("Show Pin Button")
1023: text: Translation.tr("Show Apps Button")
1029: text: Translation.tr("Use original icon colors")
1039: title: Translation.tr("System themes")
1045: text: Translation.tr("System icon theme")
1047: model: SystemTheming.iconThemes.map(theme => ({ displayName: theme, value: theme }))
1053: text: Translation.tr("Mouse cursor theme")
1055: model: SystemTheming.cursorThemes.map(theme => ({ displayName: theme, value: theme }))
1062: text: Translation.tr("Cursor size")
1077: title: Translation.tr("Lock screen")
1083: text: Translation.tr("Use Hyprlock (instead of Quickshell)")
1089: text: Translation.tr("Launch on startup")
1096: text: Translation.tr("Show Widgets")
1102: text: Translation.tr("Show Toolbars")
1109: text: Translation.tr("Show left toolbar (username/media)")
1116: text: Translation.tr("Show right toolbar (battery/power)")
1123: text: Translation.tr("Show media player info")
1129: text: Translation.tr("Hide lock controls when idle")
1136: text: Translation.tr("Hide controls after (seconds)")
1143: text: Translation.tr("Customize lock layout per display")
1149: text: Translation.tr("Primary lock-controls monitor")
1152: { displayName: Translation.tr("First connected monitor"), value: "" },
1153: ...Quickshell.screens.map(screen => ({ displayName: screen.name, value: screen.name }))
1160: text: Translation.tr("Unlock box just on the primary monitor")
1167: title: Translation.tr("Lock screen live preview")
1187: text: GlobalStates.lockPreviewOpen ? "visibility_off" : "preview"
1193: text: GlobalStates.lockPreviewOpen
1205: text: Translation.tr("Shows the lock wallpaper and all permitted widgets on every monitor without locking the session. Drag widgets directly; positions are saved independently of the desktop. Choose widgets in the editor or below.")
1211: title: Translation.tr("Widgets shown when locked")
1219: text: Translation.tr("Choose widgets for the lock screen independently of the desktop. Widget content is shared; positions are saved separately.")
1230: text: modelData.label
1239: title: Translation.tr("Security")
1243: text: Translation.tr("Require password to power off/restart")
1249: text: Translation.tr("Also unlock keyring")
1257: title: Translation.tr("Biometrics")
1261: text: Translation.tr("Enable fingerprint unlock (fprintd / PAM)")
1268: text: Translation.tr("Start fingerprint scan when locked")
1274: text: Translation.tr("Animate biometric sensor")
1280: text: Translation.tr("Enable Face ID / IR camera authentication")
1287: text: Translation.tr("Start Face ID scan when locked")
1294: text: Translation.tr("Face scan timeout (seconds)")
1304: text: Translation.tr("Face authentication command")
1313: text: Translation.tr("The default command is ‘howdy test’. Replace it with your installed Face ID script if needed; the lock unlocks only when that command exits successfully.")
1319: title: Translation.tr("Style: General")
1323: text: Translation.tr("Center clock")
1329: text: Translation.tr('Show "Locked" text')
1335: text: Translation.tr("Use varying shapes for password characters")
1343: title: Translation.tr("Password and sensor position")
1347: text: Translation.tr("Password controls position")
1351: { displayName: Translation.tr("Bottom center"), icon: "south", value: "bottom" },
1352: { displayName: Translation.tr("Screen center"), icon: "center_focus_strong", value: "center" },
1353: { displayName: Translation.tr("Left edge"), icon: "left_panel_open", value: "left" },
1354: { displayName: Translation.tr("Right edge"), icon: "right_panel_open", value: "right" }
1359: text: Translation.tr("Bottom margin")
1370: text: Translation.tr("Fine-tune each element below independently - the password box, and the left/right toolbars, each used to share one offset and could only move together. Now every one below moves on its own.")
1376: title: Translation.tr("Element positions")
1385: text: label
1394: text: Translation.tr("Horizontal offset")
1401: text: Translation.tr("Vertical offset")
1408: text: Translation.tr("Scale (%)")
1419: ElementOffsetControls { Layout.fillWidth: true; label: Translation.tr("Password box"); groupKey: "password" }
1420: ElementOffsetControls { Layout.fillWidth: true; label: Translation.tr("Left toolbar (username, media, keyboard layout)"); groupKey: "leftToolbar"; visible: Config.options.lock.showLeftToolbar }
1421: ElementOffsetControls { Layout.fillWidth: true; label: Translation.tr("Right toolbar (battery, sleep, power)"); groupKey: "rightToolbar"; visible: Config.options.lock.showRightToolbar }
1426: title: Translation.tr("Style: Blurred")
1430: text: Translation.tr("Enable blur")
1436: text: Translation.tr("Samples")
1443: text: Translation.tr("Extra wallpaper zoom (%)")
1455: title: Translation.tr("Overlay")
1460: text: Translation.tr("Show app launch indicator")
1466: text: Translation.tr("Keep indicator above windows")
1472: text: Translation.tr("Launch indicator timeout (ms)")
1479: text: Translation.tr("Enable opening zoom animation")
1487: text: Translation.tr("Darken screen")
1496: title: Translation.tr("Floating Image")
1503: text: Translation.tr("Image source")
1522: title: Translation.tr("Crosshair")
1540: text: Translation.tr("Crosshair code")
1541: placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
1562: text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
1574: mainText: Translation.tr("Open editor")
1588: title: Translation.tr("Region selector (screen snipping/Google Lens)")
1591: title: Translation.tr("Hint target regions")
1595: text: Translation.tr('Windows')
1603: text: Translation.tr('Layers')
1611: text: Translation.tr('Content')
1621: title: Translation.tr("Google Lens")
1625: text: Translation.tr("Selection Type")
1632: { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
1633: { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
1640: title: Translation.tr("Rectangular selection")
1644: text: Translation.tr("Show aim lines")
1654: title: Translation.tr("Circle selection")
1659: text: Translation.tr("Stroke width")
1671: text: Translation.tr("Padding")
1687: title: Translation.tr("On-screen display")
1691: text: Translation.tr("Timeout (ms)")
1706: title: Translation.tr("Wallpaper selector")
1712: text: Translation.tr('Attach to the M3 island')
1724: text: Translation.tr("Opens the selector against the island's real edge - tracking it as the pill morphs and moves - with the same concave corners the island uses to meet the screen edge, so it reads as a drawer pulled out of the island instead of a separate panel underneath it. Off falls back to the fixed bar-height offset, which the island doesn't actually have.")
1728: text: Translation.tr('Use system file picker')
1737: text: Translation.tr('Show home directory in quick access')
1746: text: Translation.tr('Close after selection')
1755: text: Translation.tr('Show blur background')
1764: text: Translation.tr("Columns in grid view")
1776: text: Translation.tr("Wallpaper change interval (min)")
1788: text: Translation.tr('Always show search bar')
1798: text: Translation.tr("Custom Wallpaper Folder")
1799: placeholderText: Translation.tr("e.g., /home/user/Pictures")
1820: text: Translation.tr("Live Wallpaper Folder")
1821: placeholderText: Translation.tr("e.g., /home/user/Videos/Wallpapers")
1844: title: Translation.tr("Fonts")
1851: text: Translation.tr("Font family name (e.g., Google Sans Flex)")
1871: text: Translation.tr("Numbers family name")
1891: text: Translation.tr("Title family name")
1911: text: Translation.tr("Monospace font name (e.g., JetBrains Mono NF)")
1931: text: Translation.tr("Nerd Fonts Icons (e.g., JetBrains Mono NF)")
1951: text: Translation.tr("Reading font name (e.g., Readex Pro)")
1971: text: Translation.tr("Expressive font name (e.g., Space Grotesk)")
1991: title: Translation.tr("Color generation")
1997: text: Translation.tr("Shell & utilities")
2003: text: Translation.tr("Qt apps")
2009: text: Translation.tr("Terminal")
2017: text: Translation.tr("Force dark mode in terminal")
2024: text: Translation.tr("Terminal: Harmony (%)")
2031: text: Translation.tr("Terminal: Harmonize threshold")
2038: text: Translation.tr("Terminal: Foreground boost (%)")
```

مسارات الخصائص المباشرة:

```text
1467: Config.options.appLaunch.aboveWindows
1461: Config.options.appLaunch.showIndicator
1473: Config.options.appLaunch.timeout
188: Config.options.appearance.blurPanelTransparency
104: Config.options.appearance.extraBackgroundTint
110: Config.options.appearance.fakeScreenRounding
1972: Config.options.appearance.fonts.expressive
1932: Config.options.appearance.fonts.iconNerd
1852: Config.options.appearance.fonts.main
1912: Config.options.appearance.fonts.monospace
1872: Config.options.appearance.fonts.numbers
1952: Config.options.appearance.fonts.reading
1892: Config.options.appearance.fonts.title
259: Config.options.appearance.glass.enable
260: Config.options.appearance.glass.opacity
290: Config.options.appearance.motion.durationScale
279: Config.options.appearance.motion.style
320: Config.options.appearance.palette.accentColor
302: Config.options.appearance.palette.type
228: Config.options.appearance.transparency.automatic
236: Config.options.appearance.transparency.backgroundTransparency
245: Config.options.appearance.transparency.contentTransparency
227: Config.options.appearance.transparency.enable
126: Config.options.appearance.visualEffect
1998: Config.options.appearance.wallpaperTheming.enableAppsAndShell
2004: Config.options.appearance.wallpaperTheming.enableQtApps
2010: Config.options.appearance.wallpaperTheming.enableTerminal
2018: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
2032: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
2025: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony
2039: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost
1711: Config.options.bar.barMode
1542: Config.options.crosshair.code
982: Config.options.dock.enable
994: Config.options.dock.hoverToReveal
1030: Config.options.dock.monochromeIcons
1000: Config.options.dock.pinnedOnStartup
1024: Config.options.dock.showAppsButton
988: Config.options.dock.showBackground
1012: Config.options.dock.showMedia
1018: Config.options.dock.showPinButton
195: Config.options.hyprland.decoration.activeOpacity
139: Config.options.hyprland.decoration.blur.enabled
140: Config.options.hyprland.decoration.blur.variant
200: Config.options.hyprland.decoration.inactiveOpacity
1130: Config.options.lock.autoHideControls
1288: Config.options.lock.biometrics.autoStartFaceAuth
1269: Config.options.lock.biometrics.autoStartFingerprint
1281: Config.options.lock.biometrics.enableFaceAuth
1262: Config.options.lock.biometrics.enableFingerprint
1306: Config.options.lock.biometrics.faceCommand
1295: Config.options.lock.biometrics.faceTimeoutSeconds
1275: Config.options.lock.biometrics.showSensorAnimation
1431: Config.options.lock.blur.enable
1444: Config.options.lock.blur.extraZoom
1437: Config.options.lock.blur.size
1324: Config.options.lock.centerClock
1137: Config.options.lock.controlsIdleSeconds
14: Config.options.lock.enabledWidgets
38: Config.options.lock.enabledWidgets.includes
1090: Config.options.lock.launchOnStartup
1395: Config.options.lock.layout
1361: Config.options.lock.layout.bottomMargin
1348: Config.options.lock.layout.passwordPlacement
1336: Config.options.lock.materialShapeChars
1144: Config.options.lock.perScreenLayout
1155: Config.options.lock.primaryMonitor
1244: Config.options.lock.security.requirePasswordToPower
1250: Config.options.lock.security.unlockKeyring
1110: Config.options.lock.showLeftToolbar
1330: Config.options.lock.showLockedText
1124: Config.options.lock.showMedia
1117: Config.options.lock.showRightToolbar
1103: Config.options.lock.showToolbars
1097: Config.options.lock.showWidgets
1161: Config.options.lock.unlockBoxPrimaryMonitorOnly
1084: Config.options.lock.useHyprlock
1692: Config.options.osd.timeout
1488: Config.options.overlay.darkenScreen
1504: Config.options.overlay.floatingImage.imageSource
1480: Config.options.overlay.openingZoomAnimation
831: Config.options.overview.centerAnimation
839: Config.options.overview.centerAnimationDuration
854: Config.options.overview.centerIcons
915: Config.options.overview.columns
846: Config.options.overview.enable
814: Config.options.overview.hoverPreviewInBar
951: Config.options.overview.orderBottomUp
932: Config.options.overview.orderRightLeft
820: Config.options.overview.position
904: Config.options.overview.rows
862: Config.options.overview.scale
808: Config.options.overview.showWorkspacesInLauncher
873: Config.options.overview.style
449: Config.options.policies.ai
487: Config.options.policies.weeb
1672: Config.options.regionSelector.circle.padding
1660: Config.options.regionSelector.circle.strokeWidth
1645: Config.options.regionSelector.rect.showAimLines
1612: Config.options.regionSelector.targetRegions.content
1604: Config.options.regionSelector.targetRegions.layers
1596: Config.options.regionSelector.targetRegions.windows
1627: Config.options.search.imageSearch.useCircleSelection
356: Config.options.settings.borderColor
346: Config.options.settings.borderSize
336: Config.options.settings.style
536: Config.options.sidebar.banner
545: Config.options.sidebar.bottomGroup
678: Config.options.sidebar.cornerOpen.bottom
781: Config.options.sidebar.cornerOpen.bottomLeftAction
791: Config.options.sidebar.cornerOpen.bottomRightAction
672: Config.options.sidebar.cornerOpen.clickless
697: Config.options.sidebar.cornerOpen.clicklessCornerEnd
711: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
725: Config.options.sidebar.cornerOpen.cornerRegionHeight
718: Config.options.sidebar.cornerOpen.cornerRegionWidth
666: Config.options.sidebar.cornerOpen.enable
704: Config.options.sidebar.cornerOpen.hoverAllCorners
752: Config.options.sidebar.cornerOpen.leftScrollAction
762: Config.options.sidebar.cornerOpen.rightScrollAction
736: Config.options.sidebar.cornerOpen.topLeftAction
746: Config.options.sidebar.cornerOpen.topRightAction
684: Config.options.sidebar.cornerOpen.valueScroll
690: Config.options.sidebar.cornerOpen.visualize
563: Config.options.sidebar.keepRightSidebarLoaded
411: Config.options.sidebar.media.artColors
405: Config.options.sidebar.media.enable
554: Config.options.sidebar.mediaPlayer
615: Config.options.sidebar.quickSliders.enable
625: Config.options.sidebar.quickSliders.showBrightness
645: Config.options.sidebar.quickSliders.showMic
635: Config.options.sidebar.quickSliders.showVolume
598: Config.options.sidebar.quickToggles.android.columns
577: Config.options.sidebar.quickToggles.style
519: Config.options.sidebar.translator.enable
1777: Config.options.wallpaperSelector.changeInterval
1747: Config.options.wallpaperSelector.closeAfterSelection
1765: Config.options.wallpaperSelector.columns
1713: Config.options.wallpaperSelector.dockToIsland
1823: Config.options.wallpaperSelector.liveWallpapersPath
1756: Config.options.wallpaperSelector.showBlurBackground
1738: Config.options.wallpaperSelector.showHomePath
1789: Config.options.wallpaperSelector.showSearchbar
1729: Config.options.wallpaperSelector.useSystemFileDialog
1801: Config.options.wallpaperSelector.userPath
84: Config.options.workspaceLinking.unifiedMultiMonitor
```

## KeybindsConfig

المصدر: `shell/modules/ii/settings/pages/KeybindsConfig.qml` — 910 سطرًا.

```text
261: MaterialSymbol { text: "keyboard"; iconSize: 20; color: Appearance.colors.colPrimary }
263: text: page.creatingNew ? Translation.tr("New keybind")
274: MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 18; color: Appearance.colors.colOnLayer0 }
293: text: page.pendingNewKeyStr.length ? page.pendingNewKeyStr : Translation.tr("Press any key combo… (e.g. SUPER + K)")
301: text: page.selectedBind ? Translation.tr("Original: ") + formatKeybind(page.selectedBind.mods, page.selectedBind.key) + "  •  " + page.selectedBind.dispatcher
314: text: Translation.tr("Dispatcher")
321: model: page.allDispatchers().map(d => ({ displayName: d, value: d }))
322: .concat([{ displayName: Translation.tr("Custom…"), value: "__custom__" }])
334: placeholderText: Translation.tr("e.g. hl.dsp.exec_cmd")
335: text: page.newDispatcherCustom
339: text: Translation.tr("Params")
345: placeholderText: Translation.tr("e.g. \"kitty\"")
346: text: page.newParams
350: text: Translation.tr("Description")
356: placeholderText: Translation.tr("What does this bind do? (auto-filled if left blank)")
357: text: page.newComment
381: text: "warning"
390: text: page.captureConflict
400: text: page.captureConflict && page.isEssentialBind(page.captureConflict)
418: text: Translation.tr("I understand, save anyway")
429: buttonText: Translation.tr("Cancel")
438: mainText: (page.creatingNew || page.duplicatingBind) ? Translation.tr("Create") : Translation.tr("Save")
503: text: Translation.tr("No manual typing needed — just press the keys. Stored in ~/.config/hypr/custom/keybinds.lua and overrides the default.")
509: property alias text: toastTxt.text
540: title: Translation.tr("Keybinds — Actions & Shortcuts")
545: text: Translation.tr("This editor reads and writes Hyprland's own keybinds.lua, so it's only available on Hyprland. On i3/X11, keybinds live in ~/.config/i3/horizons.conf (or your own i3 config) instead — it's a plain, commented text file, not something this editor can see or change. See docs/i3-quickshell-research.md in the repo for the full list of what each Hyprland keybind maps to on i3.")
553: title: Translation.tr("Keybinds — Actions & Shortcuts")
559: text: Translation.tr("All shortcuts are read automatically from hyprland/keybinds.lua (+ custom/keybinds.lua). Click Edit to capture a new combo — no typing required. Search filters by action or keys.")
567: placeholderText: Translation.tr("Search action or keybind… (e.g. ‘screenshot’ or ‘SUPER + S’)")
568: text: page.searchQuery
573: mainText: Translation.tr("New Keybind")
590: StyledToolTip { text: Translation.tr("Create a brand-new keybind from scratch") }
594: mainText: Translation.tr("Reload")
596: StyledToolTip { text: Translation.tr("Re-read hyprland/keybinds.lua") }
599: buttonText: Translation.tr("Clear custom")
601: StyledToolTip { text: Translation.tr("Clears ~/.config/hypr/custom/keybinds.lua") }
610: text: Translation.tr("%1 sections • %2 total binds").arg(flatSections().length).arg(flatSections().reduce((a,s)=>a+(s.keybinds?.length??0),0))
616: StyledText { font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colSubtext; text: Translation.tr("modifier") }
618: StyledText { font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colSubtext; text: Translation.tr("key") }
628: title: section.name && section.name.length ? section.name : Translation.tr("General")
673: MaterialSymbol { text: "link"; iconSize: 14; color: Appearance.colors.colPrimary }
675: text: Translation.tr("%1 shortcuts trigger this action").arg(groupCol.group.binds.length)
713: text: bind.comment && bind.comment.length ? bind.comment : (bind.dispatcher + " " + bind.params)
724: text: bind.dispatcher
734: text: bind.params.length > 55 ? bind.params.slice(0,55) + "…" : bind.params
766: text: modelData
782: text: bind.key ?? ""
790: text: "—"
798: mainText: Translation.tr("Edit")
811: StyledToolTip { text: Translation.tr("Capture new shortcut automatically") }
832: buttonText: {
854: text: resetDeleteBtn.isCustomOnly
861: text: "block"
875: mainText: groupCol.multi ? Translation.tr("Add another shortcut") : Translation.tr("Add shortcut for this action")
888: StyledToolTip { text: Translation.tr("Bind another key combo to trigger the same action") }
900: title: Translation.tr("How it works")
906: text: Translation.tr("Shortcuts are parsed from ~/.config/hypr/hyprland/keybinds.lua. Editing a shortcut appends an override to ~/.config/hypr/custom/keybinds.lua (e.g. hl.bind(\"SUPER + K\", ...)). Hyprland reloads automatically. Use Clear custom to reset. Synthetic entries (dispatcher=comment) are display-only.")
```

مسارات الخصائص المباشرة:

```text
لا توجد مسارات مباشرة؛ راجع خدمات الصفحة وإجراءاتها.
```

## NiriSettings

المصدر: `shell/modules/ii/settings/pages/NiriSettings.qml` — 686 سطرًا.

```text
86: text: page.includeStatus === "misplaced"
96: mainText: page.includeStatus === "misplaced" ? Translation.tr("Fix") : Translation.tr("Setup")
109: mainText: justCopied ? Translation.tr("Copied!") : Translation.tr("Copy lines")
130: title: Translation.tr("Displays")
141: title: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.name ?? "")
148: text: Translation.tr("Enabled")
160: text: Translation.tr("Resolution & Refresh Rate")
179: text: Translation.tr("Orientation")
187: { displayName: Translation.tr("Normal"), icon: "screen_rotation_alt", value: 0 },
188: { displayName: "90°",                    icon: "rotate_90_degrees_cw",  value: 1 },
189: { displayName: "180°",                   icon: "screen_rotation",       value: 2 },
190: { displayName: "270°",                   icon: "rotate_90_degrees_ccw", value: 3 },
196: text: Translation.tr("Variable refresh rate (VRR)")
207: text: Translation.tr("Scale")
220: text: Translation.tr("Position X")
232: text: Translation.tr("Position Y")
249: title: Translation.tr("Layout")
254: text: Translation.tr("Gaps")
264: text: Translation.tr("Center focused column")
271: { displayName: Translation.tr("Never"),       icon: "close",                       value: "never" },
272: { displayName: Translation.tr("On overflow"), icon: "keyboard_double_arrow_right", value: "on-overflow" },
273: { displayName: Translation.tr("Always"),      icon: "align_horizontal_center",     value: "always" },
278: text: Translation.tr("Default column width")
285: { displayName: "⅓", icon: "crop_portrait", value: 0.33333 },
286: { displayName: "½", icon: "crop_square",   value: 0.5 },
287: { displayName: "⅔", icon: "crop_landscape", value: 0.66667 },
297: title: Translation.tr("Input")
300: title: Translation.tr("Keyboard")
307: text: Translation.tr("Keyboard layout")
308: placeholderText: Translation.tr("e.g., us, es, latam")
324: text: Translation.tr("Numlock by default")
334: text: Translation.tr("Repeat delay (ms)")
345: text: Translation.tr("Repeat rate")
356: text: Translation.tr("Focus follows mouse")
367: title: Translation.tr("Touchpad")
371: text: Translation.tr("Tap to click")
381: text: Translation.tr("Natural scroll")
391: text: Translation.tr("Disable while typing")
401: text: Translation.tr("Scroll factor")
413: text: Translation.tr("Acceleration speed")
426: title: Translation.tr("Mouse")
430: text: Translation.tr("Natural scroll")
440: text: Translation.tr("Acceleration speed")
457: title: Translation.tr("Visual & Aesthetics")
462: text: Translation.tr("Window Rounding")
473: text: Translation.tr("Border")
483: text: Translation.tr("Border Size")
494: text: Translation.tr("Focus ring")
504: text: Translation.tr("Focus ring width")
515: text: Translation.tr("Shadows")
525: text: Translation.tr("Shadow softness")
536: text: Translation.tr("Shadow spread")
547: title: Translation.tr("Blur")
551: text: Translation.tr("Blur")
561: text: Translation.tr("Blur Passes")
572: text: Translation.tr("Blur Offset")
584: text: Translation.tr("Blur Noise (%)")
596: text: Translation.tr("Blur Saturation (%)")
613: title: Translation.tr("Cursor")
618: text: Translation.tr("Cursor theme")
619: model: [{ displayName: Translation.tr("Default"), value: "" }]
620: .concat(SystemTheming.cursorThemes.map(t => ({ displayName: t, value: t })))
628: text: Translation.tr("Cursor size")
646: text: Translation.tr("Hide while typing")
660: title: Translation.tr("Animations")
664: text: Translation.tr("Enable")
674: text: Translation.tr("Slowdown (×10)")
```

مسارات الخصائص المباشرة:

```text
665: NiriConfig.options.animations.enable
675: NiriConfig.options.animations.slowdown
647: NiriConfig.options.cursor.hideWhenTyping
622: NiriConfig.options.cursor.size
621: NiriConfig.options.cursor.theme
552: NiriConfig.options.decoration.blur.enable
585: NiriConfig.options.decoration.blur.noise
573: NiriConfig.options.decoration.blur.offset
562: NiriConfig.options.decoration.blur.passes
597: NiriConfig.options.decoration.blur.saturation
474: NiriConfig.options.decoration.border.enable
484: NiriConfig.options.decoration.border.width
495: NiriConfig.options.decoration.focusRing.enable
505: NiriConfig.options.decoration.focusRing.width
463: NiriConfig.options.decoration.rounding
516: NiriConfig.options.decoration.shadow.enable
526: NiriConfig.options.decoration.shadow.softness
537: NiriConfig.options.decoration.shadow.spread
357: NiriConfig.options.input.focusFollowsMouse
309: NiriConfig.options.input.kbLayout
441: NiriConfig.options.input.mouse.accelSpeed
431: NiriConfig.options.input.mouse.naturalScroll
325: NiriConfig.options.input.numlock
335: NiriConfig.options.input.repeatDelay
346: NiriConfig.options.input.repeatRate
414: NiriConfig.options.input.touchpad.accelSpeed
392: NiriConfig.options.input.touchpad.disableWhileTyping
382: NiriConfig.options.input.touchpad.naturalScroll
402: NiriConfig.options.input.touchpad.scrollFactor
372: NiriConfig.options.input.touchpad.tap
266: NiriConfig.options.layout.centerFocusedColumn
280: NiriConfig.options.layout.defaultColumnWidth
255: NiriConfig.options.layout.gaps
```

## Profile

المصدر: `shell/modules/ii/settings/pages/Profile.qml` — 321 سطرًا.

```text
61: title: Translation.tr("Avatar")
68: text: Translation.tr("Avatar path")
69: placeholderText: Translation.tr("Leave empty to use ~/.face, e.g. /home/youruser/Pictures/avatar")
149: text: "check"
173: text: "image"
179: text: Translation.tr("Pick a folder above to see avatars here")
188: title: Translation.tr("Identity")
194: placeholderText: SystemInfo.username
195: text: Translation.tr("Display name")
213: placeholderText: SystemInfo.hostname
214: text: Translation.tr("Hostname")
226: text: Translation.tr("Description text")
235: { displayName: Translation.tr("Distro"), icon: "deployed_code", value: "distro" },
236: { displayName: Translation.tr("Uptime"), icon: "timelapse",     value: "uptime" },
246: title: Translation.tr("Presets")
254: text: Translation.tr("Save as")
255: placeholderText: Translation.tr("Name, description (optional)")
271: text: Translation.tr("No presets yet")
312: title: presetDelegate.presetName
```

مسارات الخصائص المباشرة:

```text
24: Config.options.profile.avatarPath
116: Config.options.profile.avatarPicture
17: Config.options.profile.descriptionText
196: Config.options.profile.displayName
```

## QuickConfig

المصدر: `shell/modules/ii/settings/pages/QuickConfig.qml` — 554 سطرًا.

```text
60: text: dark ? "dark_mode" : "light_mode"
65: text: dark ? Translation.tr("Dark") : Translation.tr("Light")
81: title: Translation.tr("Wallpaper & Colors")
123: text: "Change accent color"
149: { value: "auto",               displayName: Translation.tr("Auto"),        icon: "auto_awesome" },
150: { value: "scheme-content",     displayName: Translation.tr("Content"),     icon: "image" },
151: { value: "scheme-expressive",  displayName: Translation.tr("Expressive"),  icon: "palette" },
152: { value: "scheme-fidelity",    displayName: Translation.tr("Fidelity"),    icon: "equal" },
153: { value: "scheme-fruit-salad", displayName: Translation.tr("Fruit Salad"), icon: "nutrition" },
154: { value: "scheme-monochrome",  displayName: Translation.tr("Monochrome"),  icon: "invert_colors" },
155: { value: "scheme-neutral",     displayName: Translation.tr("Neutral"),     icon: "tonality" },
156: { value: "scheme-rainbow",     displayName: Translation.tr("Rainbow"),     icon: "gradient" },
157: { value: "scheme-tonal-spot",  displayName: Translation.tr("Tonal Spot"),  icon: "lens" },
177: text: modelData.icon
186: text: modelData.displayName
211: title: Translation.tr("Transparency")
216: text: Translation.tr("Enable")
223: text: Translation.tr("Automatic")
234: text: Translation.tr("Transparency")
241: text: Translation.tr("Automatic")
251: title: Translation.tr("Performance / Experience")
271: text: Translation.tr("One click reconfigures blur, shadows, animations, transparency and background widgets to match — everything except colors, which always keep following your wallpaper.")
275: text: Translation.tr("Profile")
279: displayName: Translation.tr(p.name),
290: text: performanceSection.currentProfile ? Translation.tr(performanceSection.currentProfile.description) : ""
298: text: Translation.tr("Your running Hyprland doesn't support blur styles yet (needs hyprwm/Hyprland PR #15661 — not in any tagged release yet), so Max Experience used a fuller plain blur instead of Liquid Glass. Settings > Hyprland > Blur Style has details.")
305: title: Translation.tr("Bar & Screen")
313: text: Translation.tr("Bar position")
320: { displayName: Translation.tr("Top"), icon: "arrow_upward",   value: 0 },
321: { displayName: Translation.tr("Left"), icon: "arrow_back",     value: 2 },
322: { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
323: { displayName: Translation.tr("Right"), icon: "arrow_forward",  value: 3 }
329: text: Translation.tr("Bar style")
333: { displayName: Translation.tr("Hug"), icon: "line_curve", value: 0 },
334: { displayName: Translation.tr("Float"), icon: "view_day",   value: 1 },
335: { displayName: Translation.tr("Islands"), icon: "crop_3_2",   value: 2 },
336: { displayName: Translation.tr("M3"), icon: "interests",  value: 3 }
342: text: Translation.tr("Group style")
346: { displayName: Translation.tr("No"),          icon: "close",         value: "transparent" },
347: { displayName: Translation.tr("Pills"),     icon: "pill",          value: "pills" },
348: { displayName: Translation.tr("Separated"), icon: "view_column_2", value: "separated" }
354: text: Translation.tr("Screen round corner")
358: { displayName: Translation.tr("No"),                  icon: "close",           value: 0 },
359: { displayName: Translation.tr("Yes"),                 icon: "check",           value: 1 },
360: { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
368: title: Translation.tr("Bar & Screen")
395: text: "swap_vert"
400: text: Translation.tr("Bar position")
417: { displayName: Translation.tr("Top"), icon: "arrow_upward",   value: 0 },
418: { displayName: Translation.tr("Left"), icon: "arrow_back",     value: 2 },
419: { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
420: { displayName: Translation.tr("Right"), icon: "arrow_forward",  value: 3 }
442: text: "settop_component"
447: text: Translation.tr("Bar style")
461: { displayName: Translation.tr("Hug"), icon: "line_curve", value: 0 },
462: { displayName: Translation.tr("Float"), icon: "view_day",   value: 1 },
463: { displayName: Translation.tr("Islands"), icon: "crop_3_2",   value: 2 },
464: { displayName: Translation.tr("M3"), icon: "interests",  value: 3 }
483: text: "tab_group"
488: text: Translation.tr("Group style")
502: { displayName: Translation.tr("No"),          icon: "close",         value: "transparent" },
503: { displayName: Translation.tr("Pills"),     icon: "pill",          value: "pills" },
504: { displayName: Translation.tr("Separated"), icon: "view_column_2", value: "separated" }
525: text: "rounded_corner"
530: text: Translation.tr("Screen round corner")
544: { displayName: Translation.tr("No"),                  icon: "close",           value: 0 },
545: { displayName: Translation.tr("Yes"),                 icon: "check",           value: 1 },
546: { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
```

مسارات الخصائص المباشرة:

```text
355: Config.options.appearance.fakeScreenRounding
166: Config.options.appearance.palette.type
254: Config.options.appearance.performanceProfile
224: Config.options.appearance.transparency.automatic
217: Config.options.appearance.transparency.enable
102: Config.options.background.thumbnailPath
101: Config.options.background.wallpaperPath
343: Config.options.bar.borderless
314: Config.options.bar.bottom
330: Config.options.bar.cornerStyle
314: Config.options.bar.vertical
15: Config.options.settings.style
```

## ServicesConfig

المصدر: `shell/modules/ii/settings/pages/ServicesConfig.qml` — 771 سطرًا.

```text
47: title: Translation.tr("AI")
51: placeholderText: Translation.tr("System prompt")
52: text: Config.options.ai.systemPrompt
65: title: Translation.tr("Networking")
69: placeholderText: Translation.tr("User agent (for services that require it)")
70: text: Config.options.networking.userAgent
81: title: Translation.tr("Music Recognition")
86: text: Translation.tr("Total duration timeout (s)")
97: text: Translation.tr("Polling interval (s)")
112: title: Translation.tr("Save paths")
120: text: Translation.tr("Video Recording Path")
141: text: Translation.tr("Screenshot Path (leave empty to just copy)")
162: title: Translation.tr("Capture quality")
165: title: Translation.tr("Screenshots")
169: text: Translation.tr("Image scale (%)")
176: text: Translation.tr("Screenshot format")
180: { displayName: "PNG", icon: "lossless", value: "png" },
181: { displayName: "JPEG", icon: "photo", value: "jpg" }
186: text: Translation.tr("JPEG quality")
196: title: Translation.tr("Screen recording")
202: text: Translation.tr("Frame rate")
209: text: Translation.tr("Codec")
213: { displayName: "H.264", value: "libx264" },
214: { displayName: "HEVC", value: "libx265" },
215: { displayName: "VP9", value: "libvpx-vp9" }
221: text: Translation.tr("Recording quality")
225: { displayName: Translation.tr("Balanced"), icon: "tune", value: "balanced" },
226: { displayName: Translation.tr("High"), icon: "high_quality", value: "high" },
227: { displayName: Translation.tr("Archive"), icon: "inventory_2", value: "archive" }
232: text: Translation.tr("Audio capture")
236: { displayName: Translation.tr("None"), icon: "volume_off", value: "none" },
237: { displayName: Translation.tr("System output"), icon: "volume_up", value: "output" },
238: { displayName: Translation.tr("Microphone"), icon: "mic", value: "microphone" },
239: { displayName: Translation.tr("Mixed source (PipeWire)"), icon: "surround_sound", value: "both" }
246: text: Translation.tr("Output source override")
255: text: Translation.tr("Microphone source override")
267: title: Translation.tr("Search")
272: text: Translation.tr("Launcher")
276: { displayName: Translation.tr("Quickshell (built-in)"), icon: "search", value: "quickshell" },
277: { displayName: Translation.tr("Walker"), icon: "rocket_launch", value: "walker" },
278: { displayName: Translation.tr("Vicinae"), icon: "auto_awesome", value: "vicinae" },
279: { displayName: Translation.tr("Fuzzel"), icon: "list", value: "fuzzel" }
287: text: Translation.tr("What tapping Super opens. \"Quickshell\" is this shell's own built-in search/overview and needs nothing extra. The other three are separate apps — install them (and their background service, where needed) *before* switching to one here, or Super will just do nothing:\n"
294: text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
303: title: Translation.tr("Prefixes")
312: text: Translation.tr("Action")
322: text: Translation.tr("Clipboard")
336: text: Translation.tr("Emojis")
346: text: Translation.tr("Icons")
360: text: Translation.tr("Shell command")
370: text: Translation.tr("Web search")
384: text: Translation.tr("Apps")
394: text: Translation.tr("Keybinds")
408: text: Translation.tr("Files")
418: text: Translation.tr("SSH hosts")
431: text: Translation.tr("System services")
440: text: Translation.tr("Show actions without typing their prefix")
446: text: Translation.tr("Show files without typing their prefix")
453: text: Translation.tr("Minimum characters before searching files")
466: text: Translation.tr("With these on, actions and files also appear in an ordinary search, after the app results, instead of only behind their prefix character. Each new file search term runs one plocate query, which is why there's a minimum length.")
473: text: Translation.tr("Files searches plocate's system-wide index (falls back to mlocate's locate, then a live find under $HOME if neither index exists yet — run `sudo updatedb` once after installing plocate). System services lists systemd user + system units; starting/stopping/restarting a system-wide one prompts for authentication via pkexec.")
479: title: Translation.tr("Default applications by file type")
501: text: Translation.tr("Web links")
511: text: Translation.tr("Folders")
521: text: Translation.tr("Documents and text")
531: text: Translation.tr("Images")
541: text: Translation.tr("Audio")
551: text: Translation.tr("Video")
561: text: Translation.tr("Archives")
574: text: Translation.tr("Use the application's .desktop filename. Each change updates your user mimeapps.list, so it applies to file managers, xdg-open, browsers, and launcher results. Leave a field empty to keep its current system default.")
579: title: Translation.tr("Files, SSH & services")
583: text: Translation.tr("Open files with")
585: placeholderText: "xdg-open"
593: text: Translation.tr("Left empty, opening a file result hands it to xdg-open, i.e. whatever ~/.config/mimeapps.list says. An editor that registered itself as the handler for every text-like MIME type will therefore claim most files - if everything keeps opening in the same app, that file is why (`xdg-mime query default text/plain` shows the current winner). Put a command here to bypass it entirely; the path is appended as one quoted argument.")
597: text: Translation.tr("Enable file search")
605: text: Translation.tr("Max file results")
617: text: Translation.tr("Enable SSH quick-connect")
625: text: Translation.tr("Enable systemd service search")
633: text: Translation.tr("Max service results")
645: text: Translation.tr("Include system-wide services (needs pkexec to control)")
657: text: Translation.tr("Turning off \"Include system-wide services\" keeps only your user units in the ! search — nothing that would ever prompt for a password.")
662: title: Translation.tr("Web search")
670: text: Translation.tr("Base URL")
691: title: Translation.tr("System updates (Arch only)")
696: text: Translation.tr("Enable update checks")
705: text: Translation.tr("Check interval (mins)")
720: title: Translation.tr("Weather")
724: text: Translation.tr("Enable GPS based location")
732: text: Translation.tr("Fahrenheit unit")
740: text: Translation.tr("Polling interval (m)")
753: text: Translation.tr("City name")
```

مسارات الخصائص المباشرة:

```text
52: Config.options.ai.systemPrompt
563: Config.options.apps.defaultApplications.archives
543: Config.options.apps.defaultApplications.audio
503: Config.options.apps.defaultApplications.browser
523: Config.options.apps.defaultApplications.documents
513: Config.options.apps.defaultApplications.folders
533: Config.options.apps.defaultApplications.images
553: Config.options.apps.defaultApplications.video
584: Config.options.apps.fileOpener
273: Config.options.apps.launcher
754: Config.options.bar.weather.city
725: Config.options.bar.weather.enableGPS
741: Config.options.bar.weather.fetchInterval
733: Config.options.bar.weather.useUSCS
98: Config.options.musicRecognition.interval
87: Config.options.musicRecognition.timeout
70: Config.options.networking.userAgent
233: Config.options.screenRecord.audioMode
210: Config.options.screenRecord.codec
203: Config.options.screenRecord.frameRate
257: Config.options.screenRecord.microphoneSource
248: Config.options.screenRecord.outputSource
222: Config.options.screenRecord.quality
121: Config.options.screenRecord.savePath
177: Config.options.screenSnip.format
188: Config.options.screenSnip.jpegQuality
142: Config.options.screenSnip.savePath
170: Config.options.screenSnip.scalePercent
671: Config.options.search.engineBaseUrl
598: Config.options.search.extras.filesEnable
606: Config.options.search.extras.filesMaxResults
618: Config.options.search.extras.sshHostsEnable
626: Config.options.search.extras.systemServicesEnable
646: Config.options.search.extras.systemServicesIncludeSystemScope
634: Config.options.search.extras.systemServicesMaxResults
313: Config.options.search.prefix.action
385: Config.options.search.prefix.app
323: Config.options.search.prefix.clipboard
337: Config.options.search.prefix.emojis
409: Config.options.search.prefix.files
454: Config.options.search.prefix.filesWithoutPrefixMinLength
395: Config.options.search.prefix.keybinds
361: Config.options.search.prefix.shellCommand
441: Config.options.search.prefix.showActionsWithoutPrefix
447: Config.options.search.prefix.showFilesWithoutPrefix
419: Config.options.search.prefix.sshHosts
347: Config.options.search.prefix.symbols
432: Config.options.search.prefix.systemServices
371: Config.options.search.prefix.webSearch
295: Config.options.search.sloppy
706: Config.options.updates.checkInterval
697: Config.options.updates.enableCheck
```

## SettingsSearch

المصدر: `shell/modules/ii/settings/pages/SettingsSearch.qml` — 219 سطرًا.

```text
80: text: "search"
91: placeholderText: Translation.tr("Search every setting… (plain text, or /regex/)")
99: mainText: Translation.tr("Close")
109: text: root.results.length === 1
140: text: resultButton.modelData.pageIcon || "settings"
151: text: resultButton.modelData.sectionTitle
156: text: resultButton.modelData.pageName
163: text: (resultButton.modelData.matchingSettings ?? []).join("  •  ")
170: text: "chevron_right"
187: text: "manage_search"
193: text: Translation.tr("Type to search across every settings page")
207: text: "search_off"
213: text: Translation.tr("No settings match \"%1\"").arg(root.query)
```

مسارات الخصائص المباشرة:

```text
لا توجد مسارات مباشرة؛ راجع خدمات الصفحة وإجراءاتها.
```

## SettingsContent

المصدر: `shell/modules/ii/settings/SettingsContent.qml` — 536 سطرًا.

```text
166: { name: Translation.tr("Quick"),      icon: "instant_mix",    component: Qt.resolvedUrl("pages/QuickConfig.qml") },
167: { name: Translation.tr("General"),    icon: "browse",         component: Qt.resolvedUrl("pages/GeneralConfig.qml") },
168: { name: Translation.tr("Bar"),        icon: "toast",          iconRotation: 180, component: Qt.resolvedUrl("pages/BarConfig.qml") },
169: { name: Translation.tr("Desktop"),    icon: "texture",        component: Qt.resolvedUrl("pages/BackgroundConfig.qml") },
170: { name: Translation.tr("Interface"),  icon: "bottom_app_bar", component: Qt.resolvedUrl("pages/InterfaceConfig.qml") },
171: { name: Translation.tr("Experience"), icon: "tune",           component: Qt.resolvedUrl("pages/ExperienceConfig.qml") },
172: { name: Translation.tr("Services"),   icon: "settings",       component: Qt.resolvedUrl("pages/ServicesConfig.qml") },
175: list.push({ name: Translation.tr("Hyprland"), icon: "select_window_2", component: Qt.resolvedUrl("pages/HyprlandSettings.qml") })
176: list.push({ name: Translation.tr("Keybinds"), icon: "keyboard", component: Qt.resolvedUrl("pages/KeybindsConfig.qml") })
179: list.push({ name: Translation.tr("Niri"), icon: "select_window_2", component: Qt.resolvedUrl("pages/NiriSettings.qml") })
181: list.push({ name: Translation.tr("About"), icon: "info", component: Qt.resolvedUrl("pages/About.qml") })
274: text: "account_circle"
287: text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
302: text: {
371: text: fab.justCopied
383: text: Translation.tr("Search settings\nSearch every setting (title, description, regex supported)")
406: buttonText: modelData.name
```

مسارات الخصائص المباشرة:

```text
252: Config.options.profile.avatarPath
253: Config.options.profile.avatarPicture
303: Config.options.profile.descriptionText
287: Config.options.profile.displayName
101: Config.options.settings.style
```

## Settings

المصدر: `shell/modules/ii/settings/Settings.qml` — 188 سطرًا.

```text
184: name: "settingsToggle"
```

مسارات الخصائص المباشرة:

```text
92: Config.options.settings.borderColor
91: Config.options.settings.borderSize
89: Config.options.settings.preferredHeight
88: Config.options.settings.preferredWidth
20: Config.options.settings.style
```

## AutostartApps

المصدر: `shell/modules/common/widgets/AutostartApps.qml` — 238 سطرًا.

```text
55: text: Translation.tr("Enable")
77: text: "motion_play"
99: text: Translation.tr("Workspace")
108: text: Translation.tr("Delay")
122: text: Translation.tr("App or Command")
189: text: "delete"
201: placeholderText: Translation.tr("App (e.g. firefox)")
202: text: entryRow.modelData.cmd ?? ""
```

مسارات الخصائص المباشرة:

```text
22: Config.options.hyprland.autostartApps.apps
21: Config.options.hyprland.autostartApps.apps.length
56: Config.options.hyprland.autostartApps.enable
```

## MonitorCanvas

المصدر: `shell/modules/common/widgets/MonitorCanvas.qml` — 147 سطرًا.

```text
```

مسارات الخصائص المباشرة:

```text
لا توجد مسارات مباشرة؛ راجع خدمات الصفحة وإجراءاتها.
```
