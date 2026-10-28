# Building the NetHunter kernel — Galaxy Note 9 (SM-N960F / crownlte)

Reproducible build notes for the custom Kali NetHunter kernel used on the
Exynos 9810 Note 9 (`crownlte`). This repo does **not** vendor the full 1 GB
kernel tree or the toolchains — it carries our changes as patches against the
public base, plus the defconfig, the AnyKernel3 packaging config, and the
ready-to-flash zip.

- **Kernel:** 4.9.118 (`-g3bf42088`)
- **Device:** Samsung Galaxy Note 9 SM-N960F/DS, Exynos 9810, `crownlte`, Android 10 / One UI 2.5
- **Result:** boots with Magisk root; USB **HID / BadUSB**, RNDIS, and mass-storage gadgets work.

## What's in this repo

| Path | What it is |
|------|------------|
| `patches/` | Our 4 source changes vs the base kernel (apply with `git apply`) |
| `defconfig/exynos9810-crownlte-nethunter_defconfig` | The kernel config we built |
| `anykernel/anykernel.sh` | AnyKernel3 packaging config (flash settings) |
| `nethunter-kernel-crownlte.zip` | **Ready-to-flash** AnyKernel3 zip (TWRP / `twrp install`) |
| `build.log` | Final build output (for reference) |

## Sources (not vendored here)

| Component | Upstream | Pin |
|-----------|----------|-----|
| Kernel source | https://github.com/0xwhitehatdev/stock_universal_9810 | commit `3bf42088` |
| Toolchain | Samsung GCC 4.9 `gcc-cfp/gcc-ibv-jopp` (aarch64-linux-android-4.9) | — |
| Packaging | https://github.com/osm0sis/AnyKernel3 | — |

> **Toolchain prerequisite:** the Samsung GCC 4.9 wrapper scripts (`gcc`, `g++`,
> `c++`) have a `#!/usr/bin/python` shebang. On a modern host with no `python`
> binary, patch them to `#!/usr/bin/python3` or the build fails immediately.

## The changes (what each patch/knob fixes)

Building this 2020-era Samsung tree with a modern GCC/host needs 6 fixes —
4 are source patches here, 2 are build-env settings:

| # | Change | Why |
|---|--------|-----|
| `patches/0001` | `HOSTCFLAGS += -fcommon` (`Makefile`) | GCC 10+ defaults to `-fno-common`; `dtc`'s `yylloc` hits multiple-definition |
| `patches/0002` | `AFLAGS__uh.o += -I$(srctree) -Wa,-I$(srctree)` (`init/Makefile`) | `.incbin "init/uh.8g.elf"` not found in an `O=` out-of-tree build |
| `patches/0003` | dummy `include/linux/ologk.h` (no-op `ologk()/perflog()`, no `olog.pb.h`) | the generated `olog.pb.h` protobuf header is missing |
| `patches/0004` | always expose `BIT(NL80211_IFTYPE_MONITOR)` (`bcmdhd .../wl_cfg80211.c`) | phy now advertises monitor mode (see "Known limits") |
| build env | `ANDROID_MAJOR_VERSION=q` | otherwise `sdcardfs` recurses / mis-detects the Android version |
| defconfig | `# CONFIG_RKP_CFP_JOPP is not set` | its build step needs python2 instrumentation that won't run |

**Config additions** in the defconfig vs the stock crownlte config:
`USB_CONFIGFS_F_HID=y` (HID/BadUSB), `USB_CONFIGFS_SERIAL=y`,
`USB_CONFIGFS_MASS_STORAGE=y`, `MAC80211=y`, plus external USB-Wi-Fi driver
modules (`rt2800usb`, `rtl8187`, `rtl8192cu`, `rtl8xxxu`, `r8188eu`,
`ath9k_htc`, `carl9170`, `mt7601u`, `p54usb`, `zd1211rw`).

## Build

```sh
# 1. Base source at the pinned commit
git clone https://github.com/0xwhitehatdev/stock_universal_9810.git src
git -C src checkout 3bf42088

# 2. Apply our patches + drop in the defconfig
git -C src apply /path/to/patches/*.patch
cp defconfig/exynos9810-crownlte-nethunter_defconfig src/arch/arm64/configs/

# 3. Toolchain (Samsung GCC 4.9 gcc-ibv-jopp) — fix the python shebangs first
export ARCH=arm64
export ANDROID_MAJOR_VERSION=q
export PLATFORM_VERSION=10
export CROSS_COMPILE=/path/to/tc49/gcc-cfp/gcc-ibv-jopp/aarch64-linux-android-4.9/bin/aarch64-linux-android-

# 4. Configure + build
cd src
make O=out exynos9810-crownlte-nethunter_defconfig
make O=out -j"$(nproc)"
# -> out/arch/arm64/boot/Image
```

## Package + flash

```sh
# Package: drop the built Image into AnyKernel3 (uses anykernel/anykernel.sh here)
cp out/arch/arm64/boot/Image  AnyKernel3/Image
cd AnyKernel3 && zip -r9 nethunter-kernel-crownlte.zip . -x '*.git*'
```

Flash the zip in **TWRP** (or `adb push` + `twrp install`). The AnyKernel
config writes to the boot partition:
`/dev/block/platform/11120000.ufs/by-name/BOOT`.

**Recovery net:** keep a copy of the working rooted boot image and restore with
`heimdall flash --BOOT boot-magisk-backup.img` (device in Download mode) if a
build doesn't boot.

## Known limits

- **Internal Wi-Fi monitor/injection is not solved.** Patch `0004` makes the
  phy *advertise* monitor mode, but activation (`iw ... set type monitor`)
  returns `-22` — the Samsung `bcmdhd` driver's cfg80211 monitor path is a
  stub. Real monitor would need the legacy `WLC_SET_MONITOR` ioctl path and
  likely the mon firmware; injection is a separate firmware limit. For
  reliable injection, use an external USB adapter (e.g. MT7612U) with the
  driver modules above.
- Keep **Magisk 28.1** (Magisk 30.x breaks NetHunter). SELinux stays Enforcing.
