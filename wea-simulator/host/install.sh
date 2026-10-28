#!/usr/bin/env bash
# Deploy the WEA simulator to a connected, rooted Note 9.
# Extracts the CMAS tone from the device's OWN Messages APK (not committed here),
# then pushes the player + scripts to /data/local/tmp/.
set -euo pipefail
ADB="${ADB:-adb}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[*] device:"; $ADB devices | sed -n '2p'

echo "[*] locating Samsung Messages APK..."
APK=$($ADB shell pm path com.samsung.android.messaging | tr -d '\r' | sed 's/^package://' | head -1)
echo "    $APK"

echo "[*] extracting res/raw/cmas_ringtone.ogg from your device..."
$ADB pull "$APK" "$TMP/messages.apk" >/dev/null
unzip -o -j "$TMP/messages.apk" res/raw/cmas_ringtone.ogg -d "$TMP" >/dev/null

echo "[*] pushing files to /data/local/tmp/ ..."
$ADB push "$TMP/cmas_ringtone.ogg"            /data/local/tmp/cmas_ringtone.ogg >/dev/null
$ADB push "$HERE/player/play.dex"             /data/local/tmp/play.dex          >/dev/null
$ADB push "$HERE/scripts/launch_popup.sh"     /data/local/tmp/launch_popup.sh   >/dev/null
$ADB push "$HERE/scripts/wea.sh"              /data/local/tmp/wea.sh            >/dev/null

echo "[*] done."
echo
echo "    full demo (siren + popup):  adb shell su -c 'sh /data/local/tmp/wea.sh'"
echo "    popup only:                 adb shell su -c 'sh /data/local/tmp/launch_popup.sh'"
echo "    custom:                     adb shell su -c 'sh /data/local/tmp/launch_popup.sh \"<body>\" \"<title>\"'"
