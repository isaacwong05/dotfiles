#!/usr/bin/env python3
# whisper-dict-daemon: hold-to-talk via evdev.
#
# hold Mod+D to record, release to transcribe + type. no niri bind needed —
# this reads raw key events from /dev/input, so it sees press AND release
# (niri binds only fire on press). requires the user to be in the `input`
# group (already configured in configuration.nix).
#
# tool paths are substituted by nix at build time (@placeholder@ -> store path).
# run as a systemd user service (see configuration.nix).

import evdev
import os
import re
import signal
import subprocess
import sys
import threading
from pathlib import Path

# --- tool paths (substituted by nix) ---
NOTIFY = "@libnotify@/bin/notify-send"
PW_RECORD = "@pipewire@/bin/pw-record"
WHISPER = "@whisper_cpp@/bin/whisper-cli"
WTYPE = "@wtype@/bin/wtype"
WL_COPY = "@wl_clipboard@/bin/wl-copy"
PKILL = "@procps@/bin/pkill"
OPENCC = "@opencc@/bin/opencc"

# --- config (overridable via env) ---
# WHISPER_DICT_MODEL defaults to the english base model baked in at build
# time (@model_default@). override with a path to a multilingual model
# (e.g. the ggml-whisper-small derivation) to use other languages.
MODEL = os.environ.get("WHISPER_DICT_MODEL", "@model_default@")
THREADS = os.environ.get("WHISPER_DICT_THREADS", "8")
LANG = os.environ.get("WHISPER_DICT_LANG", "en")
# optional: pipe transcript through opencc for simplified->traditional chinese.
# e.g. WHISPER_DICT_OPENCC=s2t. harmless on non-chinese text (passthrough).
OPENCC_CFG = os.environ.get("WHISPER_DICT_OPENCC", "")

# --- hotkey: Super (left or right) + D ---
HOTKEY_KEY = evdev.ecodes.KEY_D
HOTKEY_MODS = {evdev.ecodes.KEY_LEFTMETA, evdev.ecodes.KEY_RIGHTMETA}

# --- state dirs ---
RUNDIR = Path(
    os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
) / "whisper-dict"
RUNDIR.mkdir(parents=True, exist_ok=True)
REC_FILE = RUNDIR / "recording.wav"


def notify(title, body=""):
    subprocess.run(
        [NOTIFY, "-a", "Dictation", "-t", "4000", title, body],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def find_keyboards():
    """find all real keyboard devices via evdev.

    returns a list of InputDevices. filters out virtual devices (ydotoold,
    uinput, power/sleep buttons, etc.) and requires both letter keys and
    super/ctrl modifiers to qualify. monitors ALL matching devices so the
    hotkey works regardless of which keyboard the user types on.
    """
    virtual = [
        "virtual", "ydotoold", "xdotool", "uinput",
        "sleep button", "power button", "lid switch", "video bus",
    ]
    keyboards = []
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            caps = dev.capabilities()
            if evdev.ecodes.EV_KEY not in caps:
                continue
            keys = caps[evdev.ecodes.EV_KEY]
            has_letters = evdev.ecodes.KEY_A in keys
            has_mods = (
                evdev.ecodes.KEY_LEFTMETA in keys
                or evdev.ecodes.KEY_RIGHTMETA in keys
            )
            if not has_letters or not has_mods:
                continue
            if any(p in dev.name.lower() for p in virtual):
                continue
            keyboards.append(dev)
        except (OSError, PermissionError):
            continue
    return keyboards


class DictationDaemon:
    def __init__(self):
        self.keys_pressed = set()
        self.is_recording = False
        self.transcribing = False
        self.rec_proc = None

    def start_recording(self):
        if self.is_recording:
            return
        self.is_recording = True
        # kill any orphaned pw-record from a crashed previous run
        subprocess.run(
            [PKILL, "-INT", "-f", f"pw-record.*{REC_FILE}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        REC_FILE.unlink(missing_ok=True)
        notify("Dictation", "recording — release Mod+D to transcribe")
        self.rec_proc = subprocess.Popen(
            [PW_RECORD, "--rate", "16000", "--channels", "1",
             "--container", "wav", str(REC_FILE)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def stop_and_transcribe(self):
        if not self.is_recording:
            return
        self.is_recording = False

        # stop pw-record gracefully (SIGINT -> finalize wav header)
        if self.rec_proc:
            self.rec_proc.send_signal(signal.SIGINT)
            try:
                self.rec_proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.rec_proc.kill()
                self.rec_proc.wait()
            self.rec_proc = None

        if not REC_FILE.exists() or REC_FILE.stat().st_size < 1000:
            notify("Dictation error", "no audio captured (mic missing or busy?)")
            return

        # transcribe in a background thread so the event loop keeps reading
        # key events. if the user presses Mod+D during transcription, the
        # `not self.transcribing` guard in on_key_event blocks the new press.
        threading.Thread(target=self._transcribe, daemon=True).start()

    def _transcribe(self):
        self.transcribing = True
        notify("Dictation", "transcribing...")

        try:
            result = subprocess.run(
                [WHISPER, "-m", MODEL, "-f", str(REC_FILE),
                 "-np", "-nt", "-l", LANG, "-t", THREADS],
                capture_output=True, text=True, timeout=60,
            )
        except subprocess.TimeoutExpired:
            notify("Dictation error", "transcription timed out")
            self.transcribing = False
            return

        text = re.sub(r"\s+", " ", result.stdout).strip()

        # optional: convert simplified -> traditional chinese. opencc leaves
        # non-chinese text untouched, so it's safe to always run when set.
        if OPENCC_CFG:
            try:
                oc = subprocess.run(
                    [OPENCC, "-c", OPENCC_CFG],
                    input=text, text=True,
                    capture_output=True, timeout=10,
                )
                text = oc.stdout.strip() if oc.stdout else text
            except Exception:
                pass  # non-fatal: fall back to simplified

        if not text or text == "[BLANK_AUDIO]":
            if "error:" in result.stderr:
                notify("Dictation error", "whisper failed (see journal)")
            else:
                notify("Dictation", "no speech detected")
            self.transcribing = False
            return

        # type into the focused window (non-fatal: clipboard backup covers us)
        try:
            subprocess.run(
                [WTYPE, "--", text], timeout=5,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass

        # clipboard backup
        try:
            subprocess.run(
                [WL_COPY], input=text, text=True, timeout=5,
            )
        except Exception:
            pass

        notify("Dictation done", text[:80])
        self.transcribing = False

    def on_key_event(self, event):
        if event.type != evdev.ecodes.EV_KEY:
            return

        if event.value == 1:  # key down
            self.keys_pressed.add(event.code)
        elif event.value == 0:  # key up
            self.keys_pressed.discard(event.code)

        has_mods = any(m in self.keys_pressed for m in HOTKEY_MODS)

        # D pressed with Super held -> start recording
        if (
            event.code == HOTKEY_KEY
            and event.value == 1
            and has_mods
            and not self.is_recording
            and not self.transcribing
        ):
            self.start_recording()

        # D released -> stop + transcribe
        if (
            event.code == HOTKEY_KEY
            and event.value == 0
            and self.is_recording
        ):
            self.stop_and_transcribe()

    def run(self):
        keyboards = find_keyboards()
        if not keyboards:
            notify(
                "Dictation error",
                "no keyboard found (are you in the input group?)",
            )
            sys.exit(1)

        names = ", ".join(d.name for d in keyboards)
        print(f"whisper-dict-daemon: monitoring {len(keyboards)} keyboard(s): {names}", file=sys.stderr)
        print(f"  hotkey: Super+D (hold to record, release to transcribe)", file=sys.stderr)
        print(f"  model: {MODEL}", file=sys.stderr)
        print(f"  language: {LANG}", file=sys.stderr)
        if OPENCC_CFG:
            print(f"  opencc: {OPENCC_CFG}", file=sys.stderr)

        # monitor all keyboards simultaneously via select(). this ensures the
        # hotkey works regardless of which keyboard the user types on.
        from select import select

        try:
            while True:
                r, _, _ = select(keyboards, [], [])
                for dev in r:
                    for event in dev.read():
                        self.on_key_event(event)
        except OSError as e:
            print(f"whisper-dict-daemon: keyboard device lost: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    DictationDaemon().run()
