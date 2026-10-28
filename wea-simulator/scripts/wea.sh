#!/system/bin/sh
# Full WEA demo: loud CMAS attention tone + the emergency-alert popup.
# Run as root (su). Optional args forwarded to launch_popup.sh: "<body>" "<title>"
DUR="${WEA_SOUND_MS:-9000}"

# 1) play the real CMAS tone headless on the alarm stream
CLASSPATH=/data/local/tmp/play.dex nohup app_process /system/bin Play \
  /data/local/tmp/cmas_ringtone.ogg "$DUR" >/dev/null 2>&1 &

# 2) raise the alarm volume while it plays
sleep 1
i=0; while [ "$i" -lt 10 ]; do input keyevent 24; i=$((i+1)); done

# 3) show the popup
sh /data/local/tmp/launch_popup.sh "$@"
