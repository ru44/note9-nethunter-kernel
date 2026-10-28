#!/usr/bin/env bash
# Rebuild play.dex from Play.java using the Android SDK (d8 + android.jar).
set -euo pipefail
: "${ANDROID_SDK:=$HOME/Android/Sdk}"
AJAR=$(ls "$ANDROID_SDK"/platforms/android-3*/android.jar | sort -V | tail -1)
D8=$(ls "$ANDROID_SDK"/build-tools/*/d8 | sort -V | tail -1)
echo "android.jar: $AJAR"
echo "d8:          $D8"

rm -rf cls && mkdir -p cls
javac --release 11 -classpath "$AJAR" -d cls Play.java
"$D8" cls/Play.class --min-api 29 --lib "$AJAR" --output .
mv -f classes.dex play.dex
rm -rf cls
echo "built play.dex"
