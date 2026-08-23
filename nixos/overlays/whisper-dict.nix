# whisper-dict: push-to-talk speech-to-text for niri.
#
# two entry points:
# - whisper-dict-daemon (default): a python evdev daemon that does true
#   hold-to-talk — hold Mod+D to record, release to transcribe. runs as a
#   systemd user service. sees press AND release because it reads raw
#   /dev/input events (niri binds only fire on press).
# - whisper-dict (fallback): a toggle script — first press records, second
#   press transcribes. useful for testing or if the daemon isn't running.
#
# both share the same model derivation and pipeline:
# pw-record (16khz mono wav) -> whisper-cli -> wtype + wl-copy, with
# notify-send at every state change.
final: prev: {
  # ggml whisper model as a fixed-output derivation.
  # cached + offline + reproducible. adds ~141 MB to the nix store closure,
  # but it's shared, deduped, and never re-downloaded.
  #
  # base.en chosen over small.en: on a ryzen 7 6800hs (8c/16t) base.en
  # transcribes a short utterance in ~0.8s on cpu (benchmarked with 8
  # threads on the jfk sample), which feels snappy for push-to-talk; small.en
  # (~466 MB) is ~2-3x slower for a modest accuracy gain. to switch, swap
  # this fetchurl for ggml-small.en.bin (and its sha256).
  ggml-whisper-base-en = final.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
    sha256 = "00nhqqvgwyl9zgyy7vk9i3n017q2wlncp5p7ymsk0cpkdp47jdx0";
  };
  # multilingual model for non-english (chinese/cantonese, etc.). ~466 MB,
  # ~2-3x slower than base.en. needed because base.en can't hear non-english.
  # whisper's `zh` is trained primarily on mandarin, so cantonese comes out
  # mandarin-style — no separate yue model exists in whisper.cpp.
  ggml-whisper-small = final.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
    sha256 = "0ywqxbziyp2bv72riyjpw4brk9v46d4cfbjfwqvvjrrq0srakqqv";
  };

  # hold-to-talk daemon. reads raw key events from /dev/input via evdev,
  # so it sees both press and release (unlike niri binds which only fire
  # on press). requires the user to be in the `input` group.
  #
  # the python source is in ./whisper-dict-daemon.py with @placeholder@ tokens
  # that get substituted with nix store paths at build time — avoids embedding
  # bash escaping inside python and keeps the .py file syntax-highlightable.
  whisper-dict-daemon =
    let
      pythonEnv = final.python3.withPackages (ps: [ ps.evdev ]);
      scriptContent = builtins.readFile ./whisper-dict-daemon.py;
      scriptWithPaths =
        final.lib.replaceStrings
          [
            "@libnotify@"
            "@pipewire@"
            "@whisper_cpp@"
            "@wtype@"
            "@wl_clipboard@"
            "@procps@"
            "@opencc@"
            "@model_default@"
          ]
          [
            "${final.libnotify}"
            "${final.pipewire}"
            "${final.whisper-cpp}"
            "${final.wtype}"
            "${final.wl-clipboard}"
            "${final.procps}"
            "${final.opencc}"
            "${final.ggml-whisper-base-en}"
          ]
          scriptContent;
      scriptFile = final.writeText "whisper-dict-daemon.py" scriptWithPaths;
    in
    final.runCommand "whisper-dict-daemon"
      {
        nativeBuildInputs = [ final.makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${pythonEnv}/bin/python3 $out/bin/whisper-dict-daemon \
          --add-flags ${scriptFile}
      '';

  # toggle fallback script. kept for manual use / testing — the daemon is
  # the primary interface. same pipeline, but driven by a state file instead
  # of in-memory state.
  whisper-dict = final.writeShellApplication {
    name = "whisper-dict";
    runtimeInputs = with final; [
      pipewire
      whisper-cpp
      wtype
      wl-clipboard
      libnotify
      coreutils
      procps
    ];
    text = ''
      set -euo pipefail

      # where to keep state. XDG_RUNTIME_DIR is tmpfs, wiped on logout, so no
      # stale recordings pile up on disk.
      RUNDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/whisper-dict"
      mkdir -p "$RUNDIR"
      STATE_FILE="$RUNDIR/state"
      REC_FILE="$RUNDIR/recording.wav"
      PID_FILE="$RUNDIR/pw-record.pid"
      LOCK_FILE="$RUNDIR/lock"
      ERR_FILE="$RUNDIR/whisper.err"

      # model: defaults to english base.en baked in at build time. override
      # with WHISPER_DICT_MODEL to point at a multilingual model derivation.
      MODEL="''${WHISPER_DICT_MODEL:-${final.ggml-whisper-base-en}}"
      THREADS="''${WHISPER_DICT_THREADS:-8}"
      # 'en' is fast and correct for this setup; override with WHISPER_DICT_LANG
      # (e.g. 'auto' for auto-detect, which adds ~1-2s) without a rebuild.
      LANG="''${WHISPER_DICT_LANG:-en}"

      notify() {
        # -a sets the app name so noctalia's notification daemon groups these.
        notify-send -a "Dictation" -t 4000 "$1" "''${2:-}"
      }

      # one press at a time: a press during transcription gets told to wait
      # instead of racing the state file. the backgrounded pw-record MUST NOT
      # inherit this fd (see the start branch) or it holds the lock for the
      # whole recording and every later press deadlocks on "busy".
      exec 9>"$LOCK_FILE"
      if ! flock -n 9; then
        notify "Dictation busy" "still transcribing, try again in a moment"
        exit 0
      fi

      read_state() {
        if [[ -f "$STATE_FILE" ]]; then
          cat "$STATE_FILE" 2>/dev/null || echo idle
        else
          echo idle
        fi
      }

      # stop pw-record: prefer graceful SIGINT via the recorded pid (pw-record
      # installs a handler that finalizes the wav header), then sweep any orphan
      # matching our recording path in case the pid file was stale from a
      # crashed previous run. the poll gives it up to ~1s before SIGKILL.
      stop_recording() {
        local pid=""
        [[ -f "$PID_FILE" ]] && pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -z "$pid" ]] || ! kill -INT "$pid" 2>/dev/null; then
          pkill -INT -f "pw-record.*$REC_FILE" 2>/dev/null || true
          pid="$(pgrep -f "pw-record.*$REC_FILE" 2>/dev/null | head -1 || true)"
        fi
        if [[ -n "$pid" ]]; then
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
          done
          kill -KILL "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
      }

      state="$(read_state)"
      case "$state" in
        recording)
          # --- stop + transcribe ---
          echo "transcribing" > "$STATE_FILE"

          stop_recording

          if [[ ! -s "$REC_FILE" ]]; then
            notify "Dictation error" "no audio captured (mic missing or busy?)"
            echo idle > "$STATE_FILE"
            exit 1
          fi

          notify "Dictation" "transcribing..."

          # -np strips the banner/timing lines, -nt strips timestamps, so
          # stdout is just the transcript.
          # whisper-cli exits 0 even on model/audio errors, so the `if !` only
          # catches the timeout below; real errors are detected afterward by
          # empty stdout + non-empty stderr. timeout (-k 5 60) guarantees a
          # hung whisper can't hold the lock forever.
          if ! text="$(timeout -k 5 60 whisper-cli \
              -m "$MODEL" \
              -f "$REC_FILE" \
              -np -nt \
              -l "$LANG" \
              -t "$THREADS" \
              2>"$ERR_FILE")"; then
            notify "Dictation error" "whisper timed out or crashed (see $ERR_FILE)"
            echo idle > "$STATE_FILE"
            exit 1
          fi

          # collapse whitespace + trim.
          text="$(printf '%s' "$text" | tr -d '\r' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"

          if [[ -z "$text" ]]; then
            # empty stdout + real error lines in stderr = failure (bad audio,
            # model issue); empty stdout + only benign logs = genuine no-speech.
            # whisper-cli always prints a `load_backend:` line to stderr, so a
            # mere non-empty err file isn't a failure signal — look for `error:`.
            if grep -q 'error:' "$ERR_FILE" 2>/dev/null; then
              notify "Dictation error" "whisper failed (see $ERR_FILE)"
            else
              notify "Dictation" "no speech detected"
            fi
            echo idle > "$STATE_FILE"
            exit 0
          fi

          # type into the focused window. wtype is wayland-native and needs no
          # daemon (unlike ydotool/ydotoold). failures here are non-fatal: the
          # clipboard copy + notification preview below still save the text.
          if ! wtype -- "$text" 2>/dev/null; then
            notify "Dictation" "typing failed, text is on the clipboard"
          fi

          # clipboard backup so the text survives even if wtype missed the
          # focused window or typed into the wrong surface. wl-copy daemonizes
          # by default (forks a background holder to serve pastes), so it MUST
          # not inherit fd 9 or that daemon holds the flock forever and the
          # next dictation deadlocks on "busy". same fix as pw-record: 9>&-.
          printf '%s' "$text" | wl-copy 9>&-

          # preview capped at 80 chars so the notification stays one line.
          preview="$(printf '%s' "$text" | cut -c1-80)"
          notify "Dictation done" "$preview"

          echo idle > "$STATE_FILE"
          ;;

        *)
          # --- start recording ---
          rm -f "$REC_FILE" "$ERR_FILE"

          # sweep any orphaned pw-record from a crashed previous run before
          # starting fresh, so two captures never fight the mic at once.
          if pgrep -f "pw-record.*$REC_FILE" >/dev/null 2>&1; then
            pkill -INT -f "pw-record.*$REC_FILE" 2>/dev/null || true
            sleep 0.1
            pkill -KILL -f "pw-record.*$REC_FILE" 2>/dev/null || true
          fi

          # 16khz mono s16 wav is exactly what whisper.cpp wants.
          # records from the pipewire default source; --target can pin a
          # specific mic if the default is wrong (not exposed yet).
          # 9>&- is the critical bit: without it the backgrounded pw-record
          # inherits fd 9 (the flock) and holds the lock for the whole
          # recording, so the stop press can never acquire it — every later
          # Mod+D deadlocks on "busy". closing fd 9 in the child only.
          pw-record --rate 16000 --channels 1 --container wav "$REC_FILE" 9>&- &
          echo $! > "$PID_FILE"

          # give it a beat, then make sure pw-record didn't immediately die
          # (no input device, pipewire not running, etc.).
          sleep 0.15
          if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            notify "Dictation error" "pw-record failed to start (pipewire down?)"
            rm -f "$PID_FILE"
            echo idle > "$STATE_FILE"
            exit 1
          fi

          echo recording > "$STATE_FILE"
          notify "Dictation" "recording — press Mod+D again to transcribe"
          ;;
      esac
    '';
  };

  # convenience: switch the daemon between english-only and multilingual
  # without a rebuild. sets env vars on the systemd user manager and restarts
  # the daemon so it picks them up. run from a terminal:
  #   whisper-dict-mode-en   -> base.en + english (fast, default)
  #   whisper-dict-mode-zh   -> small (multilingual) + auto-detect (chinese)
  # both models are already in the nix store (fetched at build time).
  whisper-dict-mode-en = final.writeShellScriptBin "whisper-dict-mode-en" ''
    systemctl --user set-environment \
      WHISPER_DICT_MODEL="${final.ggml-whisper-base-en}" \
      WHISPER_DICT_LANG="en" \
      WHISPER_DICT_OPENCC=""
    systemctl --user restart whisper-dict-daemon
    ${final.libnotify}/bin/notify-send -a "Dictation" -t 3000 \
      "Dictation: English" "base.en model, fast"
  '';
  whisper-dict-mode-zh = final.writeShellScriptBin "whisper-dict-mode-zh" ''
    systemctl --user set-environment \
      WHISPER_DICT_MODEL="${final.ggml-whisper-small}" \
      WHISPER_DICT_LANG="auto" \
      WHISPER_DICT_OPENCC="s2t"
    systemctl --user restart whisper-dict-daemon
    ${final.libnotify}/bin/notify-send -a "Dictation" -t 3000 \
      "Dictation: Multilingual" "small model, auto-detect, traditional chinese"
  '';
}
