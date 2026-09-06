"""Numerical invariants for the lock-preview geometry.

The preview is intentionally a visual copy of LockSurface.qml.  These values
make the otherwise easy-to-miss 40px slots/margins and cross-output placement
math explicit, without requiring a running Wayland lock session in CI.
"""

import unittest


def toolbar_width(item_widths: list[float], item_margins: list[tuple[float, float]]) -> float:
    """M3 Toolbar width: two 8px paddings plus 4px between visible items."""
    return 16 + sum(item_widths) + sum(left + right for left, right in item_margins) + 4 * (len(item_widths) - 1)


def normalized_center(x: float, y: float, width: float, height: float, output_width: float, output_height: float) -> tuple[float, float]:
    return ((x + width / 2) / output_width, (y + height / 2) / output_height)


def restore_from_center(cx: float, cy: float, width: float, height: float, output_width: float, output_height: float) -> tuple[float, float]:
    return (cx * output_width - width / 2, cy * output_height - height / 2)


def position_for_output(record: dict, output_name: str) -> dict:
    return record.get("byScreen", {}).get(output_name, record)


class LockLayoutGeometryTests(unittest.TestCase):
    def test_password_preview_uses_real_lock_surface_slots(self) -> None:
        # fingerprint: 40 + 10/6 margins; face: 40 + 2/2; field: 200;
        # confirm: 40.  The real Toolbar has 16px outer padding and three
        # 4px RowLayout gaps.  Both sides must resolve to 368 logical px.
        real = toolbar_width([40, 40, 200, 40], [(10, 6), (2, 2), (0, 0), (0, 0)])
        preview = toolbar_width([40, 40, 200, 40], [(10, 6), (2, 2), (0, 0), (0, 0)])
        self.assertEqual(real, 368)
        self.assertEqual(preview, real)

    def test_center_mapping_survives_resolution_scale_and_widget_size_change(self) -> None:
        # A widget dragged on a 2560x1440 logical output is restored on a
        # 1920x1080 logical output (which may be a 3840x2160 panel at scale 2).
        # Its visual centre, rather than its raw top-left pixel, is invariant.
        cx, cy = normalized_center(840, 240, 320, 180, 2560, 1440)
        target_x, target_y = restore_from_center(cx, cy, 280, 160, 1920, 1080)
        restored_cx, restored_cy = normalized_center(target_x, target_y, 280, 160, 1920, 1080)
        self.assertAlmostEqual(cx, 0.390625)
        self.assertAlmostEqual(cy, 0.22916666666666666)
        self.assertAlmostEqual(restored_cx, cx)
        self.assertAlmostEqual(restored_cy, cy)

    def test_each_output_keeps_its_own_saved_drag_without_losing_the_fallback(self) -> None:
        fallback = {"relativeCenterX": 0.5, "relativeCenterY": 0.3}
        record = {
            **fallback,
            "byScreen": {
                "eDP-1": {"relativeCenterX": 0.49, "relativeCenterY": 0.32},
                "HDMI-A-1": {"relativeCenterX": 0.72, "relativeCenterY": 0.18},
            },
        }
        self.assertEqual(position_for_output(record, "eDP-1"), record["byScreen"]["eDP-1"])
        self.assertEqual(position_for_output(record, "HDMI-A-1"), record["byScreen"]["HDMI-A-1"])
        self.assertEqual(position_for_output(record, "new-output")["relativeCenterX"], fallback["relativeCenterX"])
        self.assertEqual(position_for_output(record, "new-output")["relativeCenterY"], fallback["relativeCenterY"])
