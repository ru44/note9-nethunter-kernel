# WEA / CMAS Simulator — Galaxy Note 9 (crownlte, One UI 2.5)

A **local** Wireless Emergency Alert simulator for a rooted Samsung Galaxy Note 9.
It pops Samsung's *real* emergency-alert dialog (`CmasDialogRegionalActivity`) with
your own text **and** plays the genuine CMAS attention tone — triggered entirely
over `adb` + root. No app, no Frida.

> ⚠️ **Local only.** This renders an alert *on this one phone* for learning/testing.
> It transmits nothing to any network and cannot send alerts to other devices.
> Spoofing real emergency broadcasts over the air is illegal — don't.

## What it does
- Shows the WEA popup (title + body + OK) using Samsung Messages' own dialog Activity
- Plays the real `cmas_ringtone.ogg` loudly on the alarm stream
- Fully scriptable from `adb`

## How it works (the reverse-engineering)
The dialog is `com.samsung.android.messaging/.ui.view.cmas.CmasDialogRegionalActivity`.
Decompiling Samsung Messages (`androguard`, see `tools/`) showed:

1. Base `onCreate` → calls `k()` to build an `AlertDialog.Builder`; if it returns
   `null` it logs `"builder is null"` and `finish()`s (the activity self-closes).
2. `k()` reads three **string extras** and builds the dialog from them:
   | extra | meaning |
   |-------|---------|
   | `body` | the alert message text |
   | `msgIdentifier` | becomes the dialog title |
   | `cmas_message_uri` | a content URI — `k()` does `Uri.parse()` on it, so it must be present & parseable |
3. The gotcha: omit `cmas_message_uri` and `Uri.parse(null)` kills the builder →
   `null` → `finish()`. Supply all three and the dialog shows.

The **sound** is a separate subsystem (`CmasAlarmReceiver` + `CmasRingtone`,
played by the receive pipeline using `res/raw/cmas_ringtone.ogg`). The dialog
never plays audio, so we play the tone ourselves with a tiny headless
`MediaPlayer` (`player/Play.java`) run via `app_process` on `USAGE_ALARM`.

## Install
Requires: a rooted Note 9 (Magisk), `adb`, and the Android SDK (`d8`) only if you
want to rebuild the player. The prebuilt `player/play.dex` is included.

```bash
# from this folder, phone connected + USB debugging on
./host/install.sh
```
`install.sh` extracts `cmas_ringtone.ogg` from *your own* device's Messages APK
(the tone is Samsung's asset and is **not** committed here), builds nothing, and
pushes the player + scripts to `/data/local/tmp/`.

## Use
```bash
# full demo: siren + popup
adb shell su -c 'sh /data/local/tmp/wea.sh'

# popup only
adb shell su -c 'sh /data/local/tmp/launch_popup.sh'

# custom text:  launch_popup.sh "<body>" "<title>"
adb shell su -c 'sh /data/local/tmp/launch_popup.sh "Flash Flood Warning in your area." "Emergency alert: Severe"'
```

## Rebuild the player (optional)
```bash
cd player && ANDROID_SDK=$HOME/Android/Sdk ./build.sh
```

## Files
```
host/install.sh        extract tone from device + push everything
scripts/launch_popup.sh (device) fire the popup, optional body/title/uri args
scripts/wea.sh          (device) siren + popup together
player/Play.java        headless MediaPlayer source
player/play.dex         prebuilt dex (run via app_process)
player/build.sh         rebuild play.dex with d8 + android.jar
tools/decompile_cmas.py androguard: find how the dialog reads its extras
tools/dump_method.py    androguard: dump one method's bytecode
```

## Notes / troubleshooting
- Launching a non-exported Activity needs **root** — scripts use `su`.
- `cmas_message_uri` only needs to be a parseable `content://` URI; it does not
  require a matching DB row.
- No sound? Phone may be in **silent/DND**, or alarm volume is low. `wea.sh`
  raises it with `input keyevent 24` while the tone plays.
- Tested on SM-N960F, Android 10 / One UI 2.5, build N960FXXU9FVG2 (KSA).
