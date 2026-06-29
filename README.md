# CustomROM Fix Suite — KernelSU Next

Koleksi modul KernelSU Next (ksunext) khusus **Redmi 12 (Helio G88)** — HyperOS & custom ROM.

> **Target:** KernelSU Next only. Tidak kompatibel dengan Magisk murni.
> **Tested on:** Project Infinity X 3.10 (GADGETNiK), HyperOS 14 stock, Inferno Kernel 4.19.325
> **Author:** Naidrahiqa

---

## Daftar Modul

### 1. Evanescia Memory v1.1.0
**ID:** `evanescia-memory`
**Fokus:** VM Tuning + ZRAM + Memory Pressure Response

- `vm.swappiness` 40 (60 untuk <4GB RAM)
- `vm.dirty_ratio` 15, `vm.dirty_bg_ratio` 5
- `vm.vfs_cache_pressure` 80
- `vm.min_free_kbytes` 24MB (8GB), 20MB (6GB), 16MB (4GB)
- `vm.extra_free_kbytes` 4MB (8GB), 3MB (6GB), 2MB (4GB)
- ZRAM: zstd/lz4 detection, streams = ncpu/2
- I/O scheduler: mq-deadline untuk eMMC
- Memory monitor (10 menit interval)
- Drop caches saat available < 5%
- Compact memory tiap 60 menit (hanya jika PSI > 10, load <= 3)
- Re-lock VM params 1x setelah 3s (fight ROM init overrides)

### 2. Hyacine IO v1.3.0
**ID:** `hyacine-io`
**Fokus:** Storage I/O + FUSE + SD Card + USB Hotplug

- `read_ahead_kb=1024` untuk eMMC/SD
- FUSE passthrough (SuSFS-aware, auto-toggle)
- Block queue tuning: `nr_requests=128`, `nomerges=0`, `add_random=0`
- SD card media scan (merged dari customrom-fix)
- USB hotplug detection (polling 300s)
- **Tidak duplicate** dengan customrom-fix (sudah di-remove)

### 3. Kairitsu Safe v1.1.0
**ID:** `kairitsu-safe`
**Fokus:** Crash Prevention + Storage + Watchdog

- Bootloop protection (auto-disable setelah 3x rapid boot)
- Rescue Party disable
- MediaProvider broadcast (URI: `/storage/emulated/0`)
- Memory monitor (120s interval, log-only, threshold < 3%)
- Watchdog: 180s interval, D-state monitor (threshold 300s)
- Zombie process cleanup

### 4. Spoof Fierce v1.0.0
**ID:** `spoof_fierce`
**Fokus:** Per-Game Device Spoof + WebUI

- Spoof `ro.product.model/brand/manufacturer/device/board/marketname`
- Dynamic hardware props (`ro.hardware`, `ro.hardware.chipname`, `ro.board.platform`) — **runtime only, NEVER at boot**
- Per-game FPS override (60/90/120/144/165)
- 9 device presets (Xiaomi 15 Ultra, Samsung S25 Ultra, OnePlus 13, Pixel 9 Pro, Xiaomi 14, ROG Phone 9 Pro, iQOO 13, Realme GT7 Pro, Galaxy Z Fold6)
- WebUI: dark theme, bottom nav, SVG icons, real device detection
- Real device info captured at boot BEFORE spoof (saved to `real_device.json`)
- Game add/remove/apply via WebUI (`ksu.exec` + `api.sh`)
- App picker with icon support (`ksu://icon/` API)
- Backup/restore config

### 5. H-Thermal v1.0.0
**ID:** `H_Thermal`
**Fokus:** Thermal Disable + PPM Unlock + CPU Max Frequency

- PPM policies 3-8 disabled (FORCE_LIMIT, PWR_THRO, THERMAL, DLPT, HARD_USER_LIMIT, USER_LIMIT)
- CPU A55 max: 1800MHz, A75 max: 2000MHz
- Thermal zones: read-only (disable writes)
- Kompatibel dengan evanescia memory module
- Compatible with X_THERMAL (no conflict, different approach)

### 6. Game PerfTune v1.0.0
**ID:** `game-perftune`
**Fokus:** Per-Game CPU Governor, GPU Boost, Network Latency, I/O Priority

- GPU boost via GED (`gpu_cust_boost_freq=900000`, `gx_game_mode=1`)
- CPU pinning ke big cores (A75 = cores 6-7) untuk game processes
- Network: `tcp_low_latency=1`, `tcp_slow_start_after_idle=0`, `tcp_no_metrics_save=1`
- TCP buffer tuning (rmem/wmem)
- 25+ game packages pre-configured (ML, PUBG, Genshin, CODM, FF, dll)
- Game detection via `dumpsys window` (mCurrentFocus) polling 3s
- Auto-restore defaults saat game close
- Manual control: `game_detect.sh [start|stop|status|add|remove|list]`
- Notification saat boost ON/OFF
- **Tidak konflik** dengan encore (CPU governor) — hanya GPU + network + pinning

---

## Install

**Urutan yang direkomendasikan:**

1. Uninstall module lama (via KSU Manager)
2. Reboot
3. Install `kairitsu_safe` — boot protection dulu
4. Reboot
5. Install `hyacine_io`
6. Install `evanescia` — memory tuning
7. Install `h_thermal` — thermal unlock
8. Install `spoof_fierce` — device spoof
9. Install `game_perftune` — game optimization
10. Reboot final

**Catatan:**
- `customrom-fix` sudah dihapus, semua fungsinya di-merge ke `hyacine-io`
- Spoof fierce hardware props (`ro.hardware`, `ro.hardware.chipname`) hanya di-set saat user klik "Apply Game" di WebUI, bukan pas boot. Setting ini saat boot = blank screen di MediaTek devices.

---

## Verifikasi

**Cek module aktif:**
```sh
su -c "ls /data/adb/modules/"
# Harus ada: evanescia-memory, hyacine-io, kairitsu-safe, spoof_fierce, H_Thermal, game-perftune
```

**Cek log evanescia (memory):**
```sh
su -c "cat /data/local/tmp/evanescia.log | tail -20"
# Harus muncul: "min_free_kbytes: OK" dengan value 24576
```

**Cek log hyacine (I/O):**
```sh
su -c "cat /data/local/tmp/hyacine_io.log | tail -20"
# Harus muncul: "read_ahead 179:0: OK"
```

**Cek log kairitsu (stability):**
```sh
su -c "cat /data/local/tmp/kairitsu_service.log | tail -20"
# Harus muncul: "All started."
```

**Cek log spoof (spoofing):**
```sh
su -c "cat /data/local/tmp/spoof_fierce.log | tail -20"
# Harus muncul: "System props: model=25010PN30G brand=Xiaomi board=sun fps=120"
```

**Cek status.json (WebUI data):**
```sh
su -c "cat /data/adb/modules/spoof_fierce/webroot/status.json"
# Harus valid JSON dengan packages berisi array package names
```

**Cek api.sh:**
```sh
su -c "sh /data/adb/modules/spoof_fierce/api.sh status"
su -c "cat /data/adb/modules/spoof_fierce/webroot/status.json | grep packages"
# Harus ada: "packages":["com.mobile.legends",...]
```

**Cek PPM (thermal unlock):**
```sh
su -c "cat /proc/ppm/policy_status"
# Policies 3-8 harus: disabled
```

**Cek CPU max frequency:**
```sh
su -c "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
# cpu0-5 (A55): 1800000, cpu6-7 (A75): 2000000
```

**Cek game_perftune:**
```sh
su -c "cat /data/local/tmp/game_perftune.log | tail -20"
# Harus muncul: "Game PerfTune v1.1.0 (daemon)"
su -c "sh /data/adb/modules/game_perftune/game_detect.sh status"
# Cek GPU boost + network status
```

**Cek spoof status:**
```sh
su -c "getprop ro.product.model; getprop ro.surface_flinger.game_default_frame_rate_override"
# 25010PN30G
# 120
```

---

## Struktur Project

```
CustomROM-Fix/
├── evanescia/                ← VM Tuning + Memory Response
│   ├── module.prop
│   ├── post-fs-data.sh
│   ├── service.sh
│   ├── customize.sh
│   └── sepolicy.rule
├── hyacine_io/               ← Storage I/O + FUSE + SD Card + USB
│   ├── module.prop
│   ├── post-fs-data.sh
│   ├── service.sh
│   ├── customize.sh
│   └── sepolicy.rule
├── kairitsu_safe/            ← Crash + OOM + Watchdog
│   ├── module.prop
│   ├── post-fs-data.sh
│   ├── service.sh
│   ├── watchdog.sh
│   ├── customize.sh
│   └── sepolicy.rule
├── spoof_fierce/             ← Device Spoof + WebUI
│   ├── module.prop
│   ├── post-fs-data.sh       ← Boot props + real device capture
│   ├── service.sh            ← Runtime verify + WebUI data gen
│   ├── api.sh                ← WebUI backend (status/scan/add/remove/apply)
│   ├── SpoofFierce.json      ← Device profiles + game packages
│   ├── src/
│   │   ├── spoof_module.cpp  ← Zygisk native hook (JNI + COW props)
│   │   ├── zygisk.hpp
│   │   └── CMakeLists.txt
│   ├── lib/arm64-v8a/
│   │   └── libspoof_fierce.so
│   ├── webroot/
│   │   ├── index.html        ← Dark theme WebUI
│   │   ├── status.json       ← Generated at boot
│   │   └── apps.json         ← Generated at boot
│   ├── build-online.sh       ← On-device .so build script
│   ├── customize.sh
│   └── sepolicy.rule
├── h_thermal/                ← Thermal Disable + PPM Unlock
│   ├── module.prop
│   ├── service.sh
│   ├── customize.sh
│   └── sepolicy.rule
├── game_perftune/            ← Per-Game GPU/Network/CPU Tuning
│   ├── module.prop
│   ├── post-fs-data.sh       ← Boot-time base tuning (GPU + TCP)
│   ├── service.sh            ← Game detection daemon (polling 3s)
│   ├── game_detect.sh        ← Manual control (start/stop/add/remove)
│   ├── customize.sh
│   └── sepolicy.rule
├── diagnostics_and_tools/    ← Diagnostic scripts
└── README.md
```

---

## Known Issues & Conflicts

### Encore Tweaks (Rem01Gaming)
- Encore manages CPU governor (schedutil) + daemon (encored)
- **Tidak konflik** dengan modul lain

### X_THERMAL (Kutu Moba)
- Disables all thermal zones + kills thermal services
- MTK thermal HAL service tetap jalan tapi thermal zones di-chmod 000
- **User explicitly chose to keep this module**

### H-Thermal vs X_THERMAL
- H-Thermal disable PPM throttle + set CPU max freq (clean approach)
- X_THERMAL disable thermal zones (aggressive, leaves services running)
- **Tidak konflik** — bisa dipakai bersamaan atau salah satu saja

### FUSE Deadlock
- FUSE mount bisa deadlock kalau app (TikTok, dll) heavy I/O
- Hyacine IO pakai `timeout` untuk prevent hang
- Kalau terjadi: kill app yang heavy I/O

### MTK Secure Element Service
- `mtk_secure_element_hal_service` crash loop — **MTK driver issue**
- Init auto-restart, ga ngaruh ke performa

### Hardware Props Spoof
- `ro.hardware` dan `ro.hardware.chipname` hanya boleh di-spoof at **runtime** (saat apply_game)
- Jangan pernah spoof di **post-fs-data.sh** — display HAL baca prop ini pas boot
- Di MediaTek devices = blank screen jika diubah saat boot

---

## Troubleshooting

**Module tidak aktif?**
- Cek di KSU Manager → module list → pastikan enabled
- `ls /data/adb/modules/<id>/disable` — kalo ada, hapus

**Layar blank tapi scrcpy jalan?**
- Pastikan spoof_fierce tidak spoof `ro.hardware` di post-fs-data.sh
- Hard restart: tahan power button 10-15 detik
- Kalau masih blank: kemungkinan hardware issue (konektor display)

**WebUI spoof_fierce tidak muncul?**
- Cek: `ls /data/adb/modules/spoof_fierce/webroot/index.html`
- Kalau tidak ada: reinstall module dari KSU Manager

**WebUI Games tab kosong (No games added)?**
- Cek: `su -c "cat /data/adb/modules/spoof_fierce/webroot/status.json | grep packages"`
- Kalau `packages:[]` tapi SpoofFierce.json ada packages: `extract_pkgs` bug (JSON multiline)
- Fix: update api.sh, lalu `su -c "sh /data/adb/modules/spoof_fierce/api.sh status"`

**WebUI add game tidak work?**
- Cek: `su -c "grep 'Added' /data/local/tmp/spoof_fierce.log | tail -5"`
- Kalau tidak ada log "Added": `ksu.exec` mungkin bermasalah
- Cek: `su -c "cat /data/adb/modules/spoof_fierce/SpoofFierce.json | grep packages"` — package mungkin sudah ditambahkan

**File masih invisible?**
- Tunggu 1 menit setelah boot (MediaProvider butuh waktu)
- Cek log: `cat /data/local/tmp/kairitsu_service.log`

**App masih force close?**
- Cek `/data/local/tmp/waguri_watchdog.log` — app apa yang di-kill?
- Watchdog cuma log, gak kill. Kalo app FC, bukan karena watchdog.

**Storage tidak terbaca?**
- Cek SuSFS: `ls /sys/fs/susfs/` — kalo ada, FUSE passthrough disabled
- Cek mount: `cat /proc/mounts | grep sdcard`

**CPU tidak full speed?**
- Cek PPM: `cat /proc/ppm/policy_status` — pastikan policies 3-8 disabled
- Cek max freq: `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq`

---

## Changelog

### v1.0.0-ksunext (h_thermal)
- **ADD:** PPM policies 3-8 disabled (CPU unlock)
- **ADD:** CPU max frequency (A55=1800MHz, A75=2000MHz)
- **ADD:** Thermal zones read-only

### v1.3.0-ksunext (hyacine-io)
- **MERGE:** SD card media scan dari customrom-fix ke hyacine-io
- **REMOVE:** customrom-fix module (semua fungsinya sudah di-merge)

### v1.1.0-ksunext (evanescia)
- **FIX:** `min_free_kbytes` 128MB → 24MB (8GB RAM) — sebelumnya bikin reclaim storm
- **FIX:** `extra_free_kbytes` 64MB → 4MB
- **FIX:** Compact memory interval 30 menit → 60 menit, PSI threshold 5 → 10
- **IMPROVED:** RAM-tiered tuning (4GB/6GB/8GB)

### v1.0.0-ksunext (spoof_fierce)
- **FIX:** Hapus `ro.hardware`/`ro.hardware.chipname` dari post-fs-data.sh — causes blank screen on MediaTek
- **FIX:** `extract_pkgs` — flatten JSON (`tr -d '\n\r'`) sebelum sed — caused `packages:[]` in status.json
- **FIX:** `add`/`remove` commands — flatten JSON before sed, handle multiline SpoofFierce.json
- **FIX:** WebUI path — rebuilt zip dengan forward-slash paths (Windows backslash issue)
- **ADD:** Hardware props spoof at runtime only (apply_game) — display HAL sudah cache real values pas boot
- **ADD:** Dynamic `ro.hardware` derivation (qcom/google based on manufacturer)
- **ADD:** Zygisk native hook (`spoof_module.cpp`) — JNI Build fields + COW props
- **ADD:** Real device info captured at boot BEFORE spoof (saved to `real_device.json`)
- **ADD:** WebUI — dark theme, bottom nav, SVG icons, app picker with icon support
- **IMPROVED:** `execCmd` callback pattern matches Encore exactly (`exec_callback_` prefix, 15s timeout)
- **IMPROVED:** App labels in scan — remove com/org/net/io prefixes, dots→spaces, capitalize

### v1.1.0-ksunext (all modules)
- **FIX:** Version strings di semua script harus match module.prop
- **FIX:** Zip rebuilt dengan Node.js archiver (forward-slash paths) — Windows Compress-Archive produces broken backslash paths
- **IMPROVED:** Professional install UI dengan device compatibility check
- **UPDATED:** Author changed to Naidrahiqa

### v1.0.0-ksunext
- Initial release

---

## Author

Naidrahiqa
