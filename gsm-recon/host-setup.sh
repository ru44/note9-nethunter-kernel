#!/usr/bin/env bash
# One-time HOST setup on Ubuntu 26.04. Installs the native SDR tools (everything
# EXCEPT gr-gsm, which runs in the Docker container) and Wireshark to read the
# decoded GSMTAP. Run with sudo:  sudo ./host-setup.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo: sudo $0"; exit 1; }
REAL_USER="${SUDO_USER:-$USER}"

apt-get update
apt-get install -y rtl-sdr gr-osmosdr gqrx-sdr wireshark gnuradio

# The kernel's DVB-T driver grabs RTL dongles on plug-in; blacklist it so the
# SDR tools can claim the device instead.
cat > /etc/modprobe.d/blacklist-rtlsdr.conf <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF

# Let your user capture on 'lo' without root (then log out/in once).
usermod -aG wireshark "$REAL_USER" || true

echo
echo "done."
echo "  * unplug/replug the SDR (or reboot) so the DVB blacklist takes effect"
echo "  * log out and back in once so the 'wireshark' group applies"
echo "  * if Wireshark still won't capture: sudo dpkg-reconfigure wireshark-common  (answer Yes)"
echo "  * verify the dongle:  rtl_test -t"
