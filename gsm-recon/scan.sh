#!/usr/bin/env bash
# Scan a GSM band for live cells (base stations) in range and print each one's
# ARFCN, downlink frequency, MCC/MNC, LAC and CID. Pick a strong one's
# frequency and feed it to ./monitor.sh.
#
#   ./scan.sh            # GSM900  (Europe/ME/Asia/Africa — try this first)
#   ./scan.sh DCS1800    # GSM1800 (a.k.a. DCS — also common outside Americas)
#   ./scan.sh PCS1900    # GSM1900 (Americas)
#   ./scan.sh GSM850     # GSM850  (Americas)
#
# Needs the SDR plugged in. No --net=host needed: the scanner just prints.
set -euo pipefail
BAND="${1:-GSM900}"
GAIN="${2:-40}"
exec docker run --rm -it \
  -v /dev/bus/usb:/dev/bus/usb --device-cgroup-rule 'c 189:* rmw' \
  grgsm:focal grgsm_scanner -b "$BAND" -g "$GAIN"
