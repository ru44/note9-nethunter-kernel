# gsm-recon — passively watch the GSM control channel with an SDR

A **receive-only** setup for decoding the GSM (2G) control channel over the air
with a cheap SDR, on **Ubuntu 26.04**. This is the listening counterpart to the
`wea-simulator/` in this repo: there we drove a CMAS popup from the phone side;
here we watch the real cellular broadcast side from the air — the same system
information and (where present) cell-broadcast frames a tower pushes to every
phone around it.

> **Legal / safety:** this only ever **receives**. Listening to the RF spectrum
> is passive. Do **not** transmit on cellular bands — that's the regulated part,
> and it's a different project entirely. Decoding traffic that isn't yours may
> be restricted where you live; keep it to your own test SIM / your own cell
> environment and to learning how the framing works.

---

## Why Docker (the version story)

`gr-gsm` — the GNU Radio app that demodulates and decodes GSM — only builds
cleanly against **GNU Radio 3.8**. Ubuntu 26.04 ships **GNU Radio 3.10 +
Python 3.14**, and there is no `gr-gsm` package for it. Rather than fight that,
we pin the GSM-decode stack inside a container and keep the host clean:

```
┌─ HOST  (Ubuntu 26.04, native apt) ─────────────┐   ┌─ DOCKER (ubuntu:20.04) ────────┐
│  rtl_test   check the dongle                     │   │  GNU Radio 3.8                 │
│  gqrx       eyeball the spectrum                 │   │  gr-gsm (built from source)    │
│  wireshark  read decoded GSMTAP   ◄──────────────┼───┤  grgsm_scanner                 │
│                                                  │UDP│  grgsm_livemon_headless        │
│                                      127.0.0.1:4729   │    → GSMTAP on the loopback    │
└──────────────────────────────────────────────────┘   └────────────────────────────────┘
```

The container demodulates and fires each decoded frame as a **GSMTAP** packet to
`127.0.0.1:4729`. Run it with `--net=host` and those packets land on the host
loopback, where **Wireshark** (interface `lo`, filter `gsmtap`) displays them.

---

## Hardware

- An **RTL-SDR** (RTL2832U) dongle — the cheap ~$30 kind. (A HackRF/other works
  too; it's RX-only here regardless — see "Other SDRs" below.)
- An antenna that covers your GSM band (GSM900: ~935–960 MHz downlink).
- The dongle is **not plugged in yet** on this box — stage the software now; the
  only live steps are `rtl_test` and the scan, once it arrives.

---

## Setup

### 1. Host tools (one time)
```bash
sudo ./host-setup.sh      # rtl-sdr, gqrx, wireshark, gnuradio + DVB blacklist
```
Then unplug/replug the SDR (blacklist) and log out/in once (wireshark group).

### 2. Build the container (one time, a few minutes)
```bash
./build.sh                # builds image  grgsm:focal
```

### 3. Verify the dongle (once it's plugged in)
```bash
rtl_test -t               # should list the tuner (e.g. R820T) and no "usb claim" error
```
If it says the device is in use, the DVB driver blacklist didn't take — replug.

---

## Use

### 4. Find a live cell
```bash
./scan.sh                 # GSM900 (Europe/ME/Asia/Africa)
./scan.sh DCS1800         # GSM1800
./scan.sh PCS1900         # GSM1900 (Americas)
```
Each hit prints an **ARFCN**, its **downlink frequency**, and the cell's
**MCC / MNC / LAC / CID**. Note the frequency of the strongest one.

### 5. Watch it live
Terminal A (host) — open Wireshark, capture on **`lo`**, display filter `gsmtap`.
Or headless:
```bash
sudo tshark -i lo -f 'udp port 4729' -Y gsmtap
```
Terminal B:
```bash
./monitor.sh 942.4M       # use the frequency scan.sh gave you  (+ optional gain)
```
Frames start streaming into Wireshark.

---

## What you're actually seeing

The GSM downlink control channel is a tidy little broadcast system. In Wireshark
you'll mostly see **`GSM CCCH`** / **`GSM SACCH`** frames carrying:

- **System Information Type 1–4** — the cell telling every phone its identity and
  rules: the **LAI** (MCC/MNC/LAC), the **Cell ID**, neighbor ARFCNs, and which
  channels do what. This is exactly what your SDR-side `gr-gsm` and the phone's
  RIL log (`adb logcat -b radio`) are both talking about — watch them side by
  side and you're seeing the *same conversation from both ends*.
- **Paging Requests** — the network going "is phone X here?" before a call/SMS.
- **Immediate Assignment** — the network handing a phone a dedicated channel.
- **System Information Type 2** lists neighbor cells — that's the data an
  IMSI-catcher detector checks for anomalies (a "cell" with no neighbors is
  suspicious).

Cell **broadcast** (the SMS-CB channel that carries CMAS/WEA — channel 4370 etc.,
the subject of `wea-simulator/`) rides this same air interface. Whether you can
see it depends on whether the operator is broadcasting anything on it right now.

---

## ⚠️ Will there even be GSM to hear?

Honest caveat: **2G is being switched off** in many countries, and large parts of
the Gulf (including Saudi networks) have refarmed or sunset 2G/3G. If `scan.sh`
finds **nothing**, that's the most likely reason — the setup isn't broken, there
just may be no GSM on the air where you are.

`gr-gsm` decodes **GSM (2G) only**. LTE/5G use OFDM and are a different toolchain:
- **LTE**: `srsRAN` (has a cell scanner / `srsue`), or **FALCON** for downlink
  control-channel sniffing.
- The receive-only ADS-B / `rtl_433` / AIS projects work *everywhere* and are a
  great first win while you sort out whether local 2G exists.

A quick way to check for local 2G without any of this: on the Note 9, dial
`*#0011#` (ServiceMode) or look in Settings → Connections → Mobile networks →
Network mode for a "2G/GSM only" option and whether it ever registers.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `rtl_test`: "usb_claim_interface error -6" | DVB driver grabbed it → replug after `host-setup.sh`, or `sudo rmmod dvb_usb_rtl28xxu` |
| Container can't see the SDR | add `--privileged` to the `docker run` in `scan.sh`/`monitor.sh` (USB cgroup passthrough fallback) |
| Wireshark shows nothing on `lo` | confirm `monitor.sh` is running with `--net=host`; filter is `gsmtap`; try `sudo tshark -i lo` to rule out permissions |
| `scan.sh` finds no cells | likely no 2G on the air (see above); also try `DCS1800`, raise gain, better antenna/position |
| Permissions on `lo` capture | `sudo dpkg-reconfigure wireshark-common` → Yes, then re-login |

## Other SDRs

`scan.sh`/`monitor.sh` default to RTL-SDR (gr-osmosdr auto-detects it). For a
HackRF etc., pass an explicit source arg to the gr-gsm tools, e.g. add
`--args "hackrf=0"` to the `grgsm_livemon_headless` line in `monitor.sh`.

## Files

| File | What |
|---|---|
| `Dockerfile` | focal + GNU Radio 3.8 + gr-gsm built from source |
| `build.sh`   | build the `grgsm:focal` image |
| `host-setup.sh` | native host SDR tools + Wireshark + DVB blacklist |
| `scan.sh`    | scan a GSM band for live cells |
| `monitor.sh` | decode one frequency → GSMTAP → host Wireshark |
