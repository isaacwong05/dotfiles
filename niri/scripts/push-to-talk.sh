#!/usr/bin/env bash
# ~/.config/niri/scripts/push-to-talk.sh

PIDFILE="/tmp/ptt-record.pid"
AUDIOFILE="/tmp/ptt-recording.wav"

if [ -f "$PIDFILE" ]; then
  # Currently recording → stop it
  kill -INT "$(cat "$PIDFILE")" 2>/dev/null
  rm -f "$PIDFILE"
  sleep 0.3  # let the file finish writing

  notify-send "Transcribing..." -t 2000

  RESULT=$(curl -s 127.0.0.1:8080/v1/audio/transcriptions \
    -F file="@$AUDIOFILE" \
    -F model="whisper-1" | jq -r '.text')

  if [ -n "$RESULT" ]; then
    echo -n "$RESULT" | wl-copy
    notify-send "Transcribed" "$RESULT"
  else
    notify-send "Transcription failed" "No text returned"
  fi

  rm -f "$AUDIOFILE"
else
  # Not recording → start it
  notify-send "Recording..." -t 1000
  pw-record --target=@DEFAULT_SOURCE@ "$AUDIOFILE" &
  echo $! > "$PIDFILE"
fi
