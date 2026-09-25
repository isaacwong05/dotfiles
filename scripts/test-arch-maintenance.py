#!/usr/bin/env python3
import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).with_name("arch-maintenance.py")
spec = importlib.util.spec_from_file_location("arch_maintenance", SCRIPT)
maintenance = importlib.util.module_from_spec(spec)
spec.loader.exec_module(maintenance)


class MaintenanceTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        state = Path(self.tempdir.name)
        self.patches = [
            patch.object(maintenance, "STATE_DIR", state),
            patch.object(maintenance, "LOG_FILE", state / "maintenance.log"),
            patch.object(maintenance, "LOCK_FILE", state / "maintenance.lock"),
            patch.object(maintenance, "command_exists", lambda name: name in {"paru", "systemctl", "journalctl"}),
            patch.object(maintenance, "run_command", self.fake_command),
        ]
        for item in self.patches:
            item.start()

    def tearDown(self):
        for item in reversed(self.patches):
            item.stop()
        self.tempdir.cleanup()

    @staticmethod
    def fake_command(args, **kwargs):
        if args[:2] == ["pacman", "-Qqe"]:
            return 0, "base\nlinux"
        if args[:2] == ["pacman", "-Qqm"]:
            return 0, "paru\nexample-aur"
        if args[:2] == ["pacman", "-Qtdq"]:
            return 0, ""
        if args[:2] == ["paru", "-Qua"]:
            return 0, ""
        if args[:1] == ["systemctl"]:
            return 0, ""
        if args[:1] == ["journalctl"]:
            return 0, "Journal clean"
        return 0, ""

    def test_report_is_read_only_and_writes_package_snapshots(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(maintenance.report(), 0)
        text = output.getvalue()
        state = Path(self.tempdir.name)
        self.assertIn("official updates", text)
        self.assertIn("foreign/AUR packages", text)
        self.assertEqual((state / "explicit-packages.txt").read_text(), "base\nlinux\n")
        self.assertEqual((state / "foreign-packages.txt").read_text(), "paru\nexample-aur\n")
        self.assertTrue((state / "maintenance.log").exists())

    def test_dry_run_does_not_update(self):
        with patch.object(maintenance, "report", return_value=0) as report:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(maintenance.apply(dry_run=True), 0)
            report.assert_called_once_with()

    def test_timer_is_weekly_and_persistent(self):
        timer = Path(__file__).parents[1] / "config/systemd/user/arch-maintenance-report.timer"
        text = timer.read_text()
        self.assertIn("OnCalendar=Sun *-*-* 10:00:00", text)
        self.assertIn("Persistent=true", text)


if __name__ == "__main__":
    unittest.main()
