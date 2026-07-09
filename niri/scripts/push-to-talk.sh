#!/usr/bin/env bash
PIDFILE="/tmp/ptt-record.pid"
AUDIOFILE="/tmp/ptt-recording.wav"

if [ -f "$PIDFILE" ]; then
  kill -INT "$(cat "$PIDFILE")" 2>/dev/null
  rm -f "$PIDFILE"
  sleep 0.3

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
  notify-send "Recording..." -t 1000
  pw-record --target=@DEFAULT_SOURCE@ "$AUDIOFILE" &
  echo $! > "$PIDFILE"
fi
