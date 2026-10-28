#!/usr/bin/env bash
# Fire a WEA from your Linux box with custom text — no phone app needed.
#   ./fire.sh "<body>" ["<title>"] [--no-sound]
# Robust against adb's quote re-splitting: the text is sent as files and read
# back on the device with "$(cat ...)", so spaces/punctuation never break.
set -euo pipefail
ADB="${ADB:-adb}"
BODY="${1:-Excessive Heat Warning: extreme heat expected today. Limit outdoor activity and stay hydrated.}"
TITLE="${2:-Emergency alert: Extreme heat}"
SOUND=1; [ "${3:-}" = "--no-sound" ] && SOUND=0

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
printf '%s' "$BODY"  > "$TMP/body.txt"
printf '%s' "$TITLE" > "$TMP/title.txt"

{
  echo '#!/system/bin/sh'
  if [ "$SOUND" = 1 ]; then
    echo 'CLASSPATH=/data/local/tmp/play.dex nohup app_process /system/bin Play /data/local/tmp/cmas_ringtone.ogg 9000 >/dev/null 2>&1 &'
    echo 'sleep 1; i=0; while [ "$i" -lt 10 ]; do input keyevent 24; i=$((i+1)); done'
  fi
  echo 'am start -n com.samsung.android.messaging/.ui.view.cmas.CmasDialogRegionalActivity \'
  echo ' --es body "$(cat /data/local/tmp/body.txt)" \'
  echo ' --es msgIdentifier "$(cat /data/local/tmp/title.txt)" \'
  echo ' --es cmas_message_uri "content://cellbroadcasts_fwk/1"'
} > "$TMP/_fire.sh"

$ADB push "$TMP/body.txt"  /data/local/tmp/body.txt  >/dev/null
$ADB push "$TMP/title.txt" /data/local/tmp/title.txt >/dev/null
$ADB push "$TMP/_fire.sh"  /data/local/tmp/_fire.sh  >/dev/null
$ADB shell su -c 'sh /data/local/tmp/_fire.sh'
echo "fired: [$TITLE] $BODY"
