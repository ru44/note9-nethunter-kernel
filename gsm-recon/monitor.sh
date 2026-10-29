#!/usr/bin/env bash
# Live-monitor ONE GSM downlink frequency and stream decoded frames as GSMTAP
# to the host loopback, where Wireshark reads them.
#
#   ./monitor.sh 942.4M [gain]
#
# Get the frequency from ./scan.sh first. Then, on the HOST, in another terminal:
#   wireshark  -> capture interface "lo" -> display filter: gsmtap
# or headless:
#   sudo tshark -i lo -f 'udp port 4729' -Y gsmtap
#
# --net=host is required so the container's GSMTAP packets (127.0.0.1:4729)
# appear on the host's loopback.
set -euo pipefail
FREQ="${1:?usage: ./monitor.sh <downlink-freq e.g. 942.4M> [gain]}"
GAIN="${2:-40}"
exec docker run --rm -it \
  --net=host \
  -v /dev/bus/usb:/dev/bus/usb --device-cgroup-rule 'c 189:* rmw' \
  grgsm:focal grgsm_livemon_headless -f "$FREQ" -g "$GAIN"
