# CustomROM-Fix — KernelSU Next Module Suite

Koleksi 23 modul KernelSU Next untuk **Redmi 10 (selene, MT6768)** — LineageOS 20 / custom ROM.

> **Target:** KernelSU Next only.
> **Tested on:** LineageOS 20 (Android 13), Redmi 10 (selene) MT6768, 6GB RAM
> **Author:** Naidrahiqa

---

## Daftar Modul

### Original 6

| # | Module | ID | Fitur Utama |
|---|--------|----|-------------|
| 1 | **Evanescia Memory** v1.2.0 | `evanescia-memory` | VM tuning, ZRAM (zstd/lz4), memory pressure, drop caches, compact memory |
| 2 | **Hyacine IO** v1.4.0 | `hyacine-io` | FUSE passthrough, read-ahead 1024KB, block queue tuning, SD scan, USB hotplug |
| 3 | **Kairitsu Safe** v1.2.0 | `kairitsu-safe` | Bootloop protection, Rescue Party disable, D-state watchdog, zombie cleanup |
| 4 | **Spoof Fierce** v2.0.0 | `spoof_fierce` | Per-game device spoof, Zygisk hook, WebUI, 9 device presets, FPS override |
| 5 | **H-Thermal** v1.1.0 | `H_Thermal` | PPM throttle disable, CPU max freq unlock (A55=1800, A75=2000), thermal zones |
| 6 | **Game PerfTune** v2.0.0 | `game-perftune` | GPU boost (GED), CPU pinning big cores, TCP tuning, game daemon (C++) |

### New Feature Modules

| # | Module | ID | Fitur Utama |
|---|--------|----|-------------|
| 7 | **Multi Audio** v1.0.0 | `multi_audio` | Concurrent audio playback untuk PIP/dual app |
| 8 | **Media Fix** v1.0.0 | `media_fix` | Video playback repair, codec optimization |
| 9 | **Storage Fix** v1.0.0 | `storage_fix` | Telegram save-to-gallery, storage permission fix |
| 10 | **Camera Fix** v1.0.0 | `camera_fix` | HAL3, RAW, ZSL, JPEG max quality, OIS support |
| 11 | **GPS Fix** v1.0.0 | `gps_fix` | Multi-constellation GPS, AGPS, EPO, faster lock |
| 12 | **UI Enhance** v1.0.0 | `ui_enhance` | Native C++ daemon — rendering, animation, surfaceflinger tuning |
| 13 | **Network Fix** v1.0.0 | `network_fix` | Native C++ daemon — TCP/TSO, DNS, latency optimization |
| 14 | **Battery Fix** v1.0.0 | `battery_fix` | Native C++ daemon — battery drain optimization, wakelock control |

### Customization Modules

| # | Module | ID | Fitur Utama |
|---|--------|----|-------------|
| 15 | **Font Swap** v1.0.0 | `font_swap` | 7 font profiles, custom font support, scale control |
| 16 | **Touch Fix** v1.0.0 | `touch_fix` | Touch sensitivity, edge filter, palm rejection, input boost |
| 17 | **Status Bar Mod** v1.0.0 | `statusbar_mod` | 10 icon toggles, 3 icon styles, carrier name, clock format |
| 18 | **WiFi Boost** v1.0.0 | `wifi_boost` | MT6631 optimization, signal boost, scan intervals, WFD |
| 19 | **Power Menu** v1.0.0 | `power_menu` | Extended power menu — screenshot, airplane, reboot, shutdown |
| 20 | **Display Color** v1.0.0 | `display_color` | Color calibration, saturation, contrast, night mode, HW comp GPU |
| 21 | **Fingerprint Speed** v1.0.0 | `fingerprint_speed` | Quick unlock, wakeup, delay removal, biometric tuning |
| 22 | **Speaker Boost** v1.0.0 | `speaker_boost` | Speaker boost level 8, headset boost 6, fluence recording |
| 23 | **Volume Steps** v1.0.0 | `volume_steps` | Media/BT 30 steps, ring/alarm/system 15 steps |

---

## Install

Semua module udah di-install via `ksud module install` dari `/sdcard/Download/`. Tinggal **reboot**.

**Urutan install kalo dari awal:**
1. `kairitsu_safe` — boot protection
2. Reboot
3. `hyacine_io` — storage I/O
4. `evanescia` — memory tuning
5. `h_thermal` — thermal unlock
6. Sisa module lain — urutan bebas
7. Reboot final

**Build zips dari source (Windows):**
```sh
npm install archiver
node rebuild-zips.js
adb push *.zip /sdcard/Download/
```

---

## Verifikasi

```sh
# Cek module
su -c "ls /data/adb/modules/"

# Cek log
su -c "cat /data/local/tmp/evanescia.log | tail -5"
su -c "cat /data/local/tmp/spoof_fierce.log | tail -5"

# Cek PPM (thermal unlock)
su -c "cat /proc/ppm/policy_status"

# Cek spoof status
su -c "getprop ro.product.model"

# Status bar config
su -c "sh /data/adb/modules/statusbar_mod/statusbar_config.sh"

# Font config
su -c "sh /data/adb/modules/font_swap/font_config.sh status"
```

---

## Struktur Project

```
CustomROM-Fix/
├── rebuild-zips.js          ← Build script (Node.js archiver)
├── AGENTS.md                ← AI agent instructions
├── README.md
├── evanescia/               ← Memory tuning
├── hyacine_io/              ← Storage I/O
├── kairitsu_safe/           ← Boot protection
├── spoof_fierce/            ← Device spoof + WebUI + native C++
├── h_thermal/               ← Thermal unlock
├── game_perftune/           ← Game perf daemon (C++)
├── multi_audio/             ← Concurrent audio
├── media_fix/               ← Video playback
├── storage_fix/             ← Storage permission
├── camera_fix/              ← Camera quality
├── gps_fix/                 ← GPS accuracy
├── ui_enhance/              ← UI daemon (C++)
├── network_fix/             ← Network daemon (C++)
├── battery_fix/             ← Battery daemon (C++)
├── font_swap/               ← Font customization
├── touch_fix/               ← Touch sensitivity
├── statusbar_mod/           ← Status bar customization
├── wifi_boost/              ← WiFi optimization
├── power_menu/              ← Extended power menu
├── display_color/           ← Display color tuning
├── fingerprint_speed/       ← Fingerprint speed
├── speaker_boost/           ← Speaker volume
├── volume_steps/            ← Volume steps
└── diagnostics_and_tools/   ← Documentation & tools
```

---

## Known Issues & Cross-Module Conflicts

Lihat `AGENTS.md` untuk detail lengkap. Highlights:
- **FUSE passthrough** — Hanya hyacine-io yang boleh toggle. Jangan dari module lain.
- **VM params** — evanescia owns swappiness, dirty_ratio, min_free_kbytes.
- **Hardware props** — spoof_fierce hanya di runtime (apply_game), NEVER at boot.
- **Vendor/ODM props** — Jangan pernah di-spoof. Signal loss.
- **grep -oP** — Jangan dipake di Android (toybox grep). Pake sed.

---

## Release

Download zip dari GitHub Releases atau build sendiri pake `node rebuild-zips.js`.

---

## Author

Naidrahiqa
