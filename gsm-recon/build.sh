#!/usr/bin/env bash
# Build the gr-gsm container (one time, ~a few minutes).
set -euo pipefail
cd "$(dirname "$0")"
docker build -t grgsm:focal .
echo
echo "built grgsm:focal"
echo "next:  ./scan.sh        (find a live cell near you)"
echo "then:  ./monitor.sh <freq>   (+ wireshark on lo, filter: gsmtap)"
