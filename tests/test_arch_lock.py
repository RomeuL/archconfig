"""Exercise the real launcher without touching the desktop or authenticating."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


LAUNCHER = Path(__file__).resolve().parents[1] / "home/.local/bin/arch-lock"


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.state = self.root / "state/arch-lock"
        self.state.mkdir(parents=True)
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        self.log = self.root / "calls"
        self.env = dict(os.environ, PATH=f"{self.bin}:/usr/bin:/bin",
                        XDG_STATE_HOME=str(self.root / "state"),
                        XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_RUNTIME_DIR=str(self.runtime),
                        TEST_CALLS=str(self.log), TEST_QS_EXIT="42",
                        TEST_BATTERY="0", TEST_DPMS_EXIT="0")
        self.stub("pgrep", "exit 1")
        self.stub("pkill", 'echo stop-idle >> "$TEST_CALLS"')
        self.stub("systemctl", 'echo "systemctl $*" >> "$TEST_CALLS"')
        self.stub("hyprlock", 'echo hyprlock >> "$TEST_CALLS"')
        self.stub("quickshell", '''
printf 'qs %s\n' "$*" >> "$TEST_CALLS"
case "$*" in *'ipc call'*) exit 0;; esac
if [ -n "${TEST_QS_SLEEP:-}" ]; then sleep "$TEST_QS_SLEEP"; fi
exit "$TEST_QS_EXIT"
''')
        self.stub("hyprctl", 'echo "dpms $*" >> "$TEST_CALLS"; exit "$TEST_DPMS_EXIT"')
        battery = self.root / "config/hypr/scripts/on-battery.sh"
        battery.parent.mkdir(parents=True)
        battery.write_text('#!/bin/sh\nexit "$TEST_BATTERY"\n')
        battery.chmod(0o755)

    def stub(self, name, body):
        target = self.bin / name
        target.write_text("#!/bin/sh\n" + body + "\n")
        target.chmod(0o755)

    def run_lock(self, *args):
        return subprocess.run([str(LAUNCHER), *args], env=self.env,
                              capture_output=True, text=True, timeout=5)

    def calls(self):
        return self.log.read_text() if self.log.exists() else ""

    def test_not_enabled_keeps_hyprlock(self):
        self.assertEqual(self.run_lock().returncode, 0)
        self.assertEqual(self.calls(), "hyprlock\n")

    def test_only_authenticated_exit_skips_fallback(self):
        (self.state / "enabled").touch()
        for code in (0, 1, 137, 42):
            with self.subTest(exit_code=code):
                self.log.unlink(missing_ok=True)
                self.env["TEST_QS_EXIT"] = str(code)
                result = self.run_lock()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual("hyprlock" in self.calls(), code != 42)

    def test_concurrent_requests_do_not_open_two_lockers(self):
        (self.state / "enabled").touch()
        self.env["TEST_QS_SLEEP"] = "0.6"
        first = subprocess.Popen([str(LAUNCHER)], env=self.env,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            import time
            deadline = time.monotonic() + 2
            while not self.log.exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue(self.log.exists())
            self.assertEqual(self.run_lock().returncode, 0)
            self.assertEqual(first.wait(timeout=3), 0)
            self.assertEqual(self.calls().count("qs "), 1)
        finally:
            if first.poll() is None:
                first.kill()
                first.wait()

    def test_ac_keeps_display_on(self):
        self.env["TEST_BATTERY"] = "1"
        self.assertEqual(self.run_lock("screen-off").returncode, 0)
        self.assertEqual(self.calls(), "")

    def test_battery_pauses_before_powering_off(self):
        self.assertEqual(self.run_lock("screen-off").returncode, 0)
        calls = self.calls()
        self.assertLess(calls.index("locker pause"), calls.index('action = "off"'))

    def test_failed_dpms_resumes_animation(self):
        self.env["TEST_DPMS_EXIT"] = "1"
        self.assertEqual(self.run_lock("screen-off").returncode, 1)
        self.assertIn("locker resume", self.calls())

    def test_wake_powers_on_before_resuming(self):
        self.assertEqual(self.run_lock("screen-on").returncode, 0)
        self.assertLess(self.calls().index('action = "on"'), self.calls().index("locker resume"))

    def test_disable_does_not_kill_existing_locker(self):
        (self.state / "enabled").touch()
        self.assertEqual(self.run_lock("disable").returncode, 0)
        self.assertFalse((self.state / "enabled").exists())
        self.assertEqual(self.calls(), "")

    def test_start_idle_uses_persistent_user_service(self):
        self.assertEqual(self.run_lock("start-idle").returncode, 0)
        self.assertIn("import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE", self.calls())
        self.assertIn("start hypridle.service", self.calls())
        self.assertNotIn("stop-idle", self.calls())

    def test_reload_idle_replaces_older_direct_instance(self):
        self.assertEqual(self.run_lock("reload-idle").returncode, 0)
        self.assertIn("import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE", self.calls())
        self.assertLess(self.calls().index("stop-idle"), self.calls().index("restart hypridle.service"))


if __name__ == "__main__":
    unittest.main()
