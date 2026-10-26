# Kali NetHunter on the Samsung Galaxy Note 9 (SM-N960F / crownlte)

Build notes for getting Kali NetHunter — and a **custom NetHunter kernel** — running on the
Exynos Galaxy Note 9 (Android 10 / One UI 2.5), which has **no official or up-to-date
NetHunter build**. The only community kernel (Sexynos V2.0, 2020) is gone (dead download),
so the kernel here was built from a current source tree.

## Result

- Bootloader unlocked (Exynos variant), **TWRP 3.7.0_9-0**, **Magisk 28.1**
  (do **not** use Magisk 30.x — newer Magisk has issues with NetHunter).
- **NetHunter Lite** installed (Kali chroot + app) as a Magisk module.
- **Custom NetHunter kernel built from source** (4.9.118) adding:
  - `CONFIG_USB_CONFIGFS_F_HID=y` → HID / DuckHunter / BadUSB keyboard
  - `CONFIG_USB_CONFIGFS_RNDIS=y` → BadUSB MITM
  - `CONFIG_USB_CONFIGFS_MASS_STORAGE=y` → USB exfil
  - `CONFIG_MAC80211=y` + `rt2800usb`/`rtl8187`/`r8188eu`/`ath9k_htc`/`carl9170`/`mt7601u`
    (external USB-Wi-Fi injection, built as modules)
  - `RKP_CFP_JOPP` disabled (Samsung control-flow protection)

Verified after flashing: boots, root works, and the HID / RNDIS / mass_storage USB gadget
functions can be created (the capabilities stock NetHunter Lite could not provide).

## Kernel build

- **Source:** `0xwhitehatdev/stock_universal_9810` (maintained crownlte 4.9 tree)
- **Toolchain:** Samsung-hardened GCC 4.9 (`gcc-cfp/gcc-ibv-jopp`)
- **Env:** `ARCH=arm64 ANDROID_MAJOR_VERSION=q PLATFORM_VERSION=10`

### Fixes needed to build on a modern host (GCC 15 / python3-only)

1. `scripts/dtc` `yylloc` multiple definition (GCC 10+ `-fno-common`) →
   append `-fcommon` to `HOSTCFLAGS` in the top `Makefile`.
2. `fs/sdcardfs` "recursive inclusion" Kconfig → export `ANDROID_MAJOR_VERSION=q`
   (the `source "fs/sdcardfs/$ANDROID_MAJOR_VERSION/Kconfig"` line).
3. Toolchain `gcc`/`g++`/`c++` driver wrappers have a `#!/usr/bin/python` shebang →
   change to `#!/usr/bin/python3` (python2/3-compatible wrappers).
4. `init/_uh.S` `.incbin "init/uh.8g.elf"` not found in an `O=` (out-of-tree) build →
   add to `init/Makefile`:  `AFLAGS__uh.o += -I$(srctree) -Wa,-I$(srctree)`
5. Missing generated `olog.pb.h` (stripped protobuf) breaks every file via
   `include/linux/ologk.h` → copy the dummy `drivers/kperfmon/ologk.h`
   over `include/linux/ologk.h` (the build's own fallback, applied up front).
6. RKP CFP post-link `instrument.py` is python2-only → disable `CONFIG_RKP_CFP_JOPP`
   (it is `default n`, not selected by anything).

## Flash

Package `arch/arm64/boot/Image` with **AnyKernel3**:
`BLOCK=/dev/block/platform/11120000.ufs/by-name/BOOT`, `IS_SLOT_DEVICE=0`.
Flash the zip in TWRP and reboot — AnyKernel3 auto-preserves Magisk.
Keep a copy of the working `boot.img`; restore with `heimdall flash --BOOT boot.img`
from Download Mode if a build bootloops.

## Limitations / TODO

- **Internal Wi-Fi (`wlan0`) monitor mode needs nexmon** (Broadcom firmware patch) —
  not included here. `Monitor mode failed on wlan0` is expected without it. For
  injection, use an **external USB Wi-Fi adapter** (install the built driver modules,
  or rebuild them `=y`).
- SELinux is **Enforcing** (HID/BadUSB work under it; switch to permissive if a tool needs it).
