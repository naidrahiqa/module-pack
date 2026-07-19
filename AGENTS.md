# AGENTS.md — CustomROM-Fix

KernelSU Next module collection untuk **Redmi 12 (Helio G88)** — HyperOS & custom ROM. Shell scripts + C++ native daemons. Flash via KSU Manager.

## Project Layout

```
CustomROM-Fix/
├── opencode.json              # OpenCode AI config
├── AGENTS.md                  # This file — AI agent instructions
├── README.md                  # Main docs (Indonesian)
├── rebuild-zips.js            # Zip builder (Node.js archiver)
├── package.json               # Node.js dependencies
├── evanescia/                 # VM tuning + ZRAM + memory pressure
│   ├── module.prop
│   ├── post-fs-data.sh        # Early boot VM params
│   ├── service.sh             # Runtime memory monitor
│   ├── customize.sh           # KSU installer UI
│   ├── sepolicy.rule          # SELinux rules
│   └── META-INF/              # Magisk/KSU install metadata
├── hyacine_io/                # Storage I/O + FUSE + SD card + USB
│   ├── module.prop
│   ├── post-fs-data.sh        # FUSE passthrough + read-ahead
│   ├── service.sh             # Block queue + SD scan + USB hotplug
│   ├── customize.sh
│   ├── sepolicy.rule
│   ├── system/bin/mount.ntfs  # Kernel driver mount wrapper
│   └── META-INF/
├── kairitsu_safe/             # Crash prevention + OOM + watchdog
│   ├── module.prop
│   ├── post-fs-data.sh        # Bootloop detection
│   ├── service.sh             # Rescue Party disable + memory monitor
│   ├── watchdog.sh            # D-state monitor
│   ├── customize.sh
│   ├── sepolicy.rule
│   └── META-INF/
├── spoof_fierce/              # Per-game device spoof + WebUI
│   ├── module.prop
│   ├── post-fs-data.sh        # Boot props + real device capture
│   ├── service.sh             # Runtime verify + WebUI data gen
│   ├── api.sh                 # WebUI backend (calls native spoof_api)
│   ├── SpoofFierce.json       # Device profiles + game packages
│   ├── src/
│   │   ├── spoof_module.cpp   # Zygisk native hook (JNI + COW props)
│   │   ├── api_handler.c      # Native API (JSON parser + actions)
│   │   ├── json_lite.c/.h     # Lightweight JSON parser
│   │   ├── zygisk.hpp
│   │   ├── CMakeLists.txt     # Builds both .so and executable
│   │   └── build-ndk.bat      # Windows NDK build script
│   ├── lib/arm64-v8a/
│   │   └── libspoof_fierce.so
│   ├── bin/
│   │   └── spoof_api          # Native API handler executable
│   ├── webroot/
│   │   ├── index.html         # Dark theme WebUI
│   │   ├── status.json        # Generated at boot
│   │   └── apps.json          # Generated at boot
│   ├── build-online.sh        # On-device .so build
│   ├── build-termux.sh        # Termux build script
│   ├── customize.sh
│   ├── sepolicy.rule
│   └── META-INF/
├── h_thermal/                 # Thermal disable + PPM unlock
│   ├── module.prop
│   ├── post-fs-data.sh        # Zero thermal props at boot
│   ├── service.sh             # Thermal zone + PPM + GPU disable
│   ├── sepolicy.rule          # SELinux rules for thermal sysfs
│   ├── customize.sh
│   └── META-INF/
├── game_perftune/             # Per-game GPU boost + network + CPU pinning
│   ├── module.prop
│   ├── post-fs-data.sh        # Boot-time base tuning (GPU + TCP buffers)
│   ├── service.sh             # Thin launcher for native daemon
│   ├── game_detect.sh         # Manual control (start/stop/add/remove/list)
│   ├── src/
│   │   ├── game_perftune.c    # Main native daemon
│   │   ├── game_list.c/.h     # Game package list management
│   │   ├── gpu_tuner.c/.h     # GPU sysfs tuning
│   │   ├── net_tuner.c/.h     # Network sysfs tuning
│   │   ├── cpu_pinner.c/.h    # CPU cpuset pinning
│   │   ├── CMakeLists.txt     # Build config
│   │   └── build-ndk.bat      # Windows NDK build script
│   ├── lib/arm64-v8a/
│   │   └── game_perftune      # Native daemon executable
│   ├── customize.sh
│   ├── sepolicy.rule
│   └── META-INF/
└── diagnostics_and_tools/     # Diagnostic scripts
```

## Module Versions

| Module | ID | Version | Key Changes |
|--------|-----|---------|-------------|
| Evanescia Memory | `evanescia-memory` | v1.2.0 | PSI fix, SELinux rules, write logging |
| Hyacine IO | `hyacine-io` | v1.4.0 | USB detection fix, timeout, FUSE verify |
| Kairitsu Safe | `kairitsu-safe` | v1.2.0 | D-state count fix, Rescue Party verify |
| Spoof Fierce | `spoof_fierce` | v2.0.0 | C++ native API, JSON validation, tr fix |
| H-Thermal | `H_Thermal` | v1.1.0 | grep -oP fix, sepolicy, readback verify |
| Game PerfTune | `game-perftune` | v2.0.0 | Full C++ rewrite, META-INF, cpuset fix |

## Shell Scripting Rules (Critical)

These are hard-won lessons from debugging on-device:

### mksh, not bash
- Android's `/system/bin/sh` is mksh
- No arrays, no `[[ ]]`, limited string ops
- Use `for x in ...; do ...; done` not `for x in (...); do`

### No `local` in top-level while loops
- mksh silently crashes. This killed evanescia and castorice_power service.sh in v3.2.0
- Use functions for scoped variables

### `timeout` commands for anything slow
- `dumpsys display`, FUSE operations, mount attempts
- Helio G88 is slow; hangs are common

### Verify writes
- Always readback after writing to `/proc/sys/vm/*`, `/sys/class/*`, `/proc/ppm/*`
- Silent failures are the norm

### FUSE passthrough is sacred — DO NOT TOUCH
- `persist.sys.fuse.passthrough.enable` corrupts SD card boot sector if toggled
- This happened on 2026-06-21. User had to use EaseUS Recovery
- If anything involves FUSE, STOP and ask user first. No exceptions.

### `resetprop` in post-fs-data may no-op
- Property subsystem isn't ready that early. Use it, but verify.

### NEVER spoof hardware props at boot
- `ro.hardware` and `ro.hardware.chipname` — Display HAL reads these at boot
- Changing = blank screen on MediaTek
- Only safe at runtime (apply_game) when display already initialized
- Caused black screen on Redmi 12 on 2026-06-22 AND 2026-06-23

### NEVER spoof vendor/ODM/system props
- `ro.product.vendor.*`, `ro.product.odm.*`, `ro.product.system.*`, `ro.product.system_ext.*`
- These control radio/RIL modem initialization
- Changing = signal loss
- Only safe: `ro.product.model/brand/device/board/marketname` (product level)
- Caused signal loss on Redmi 12 on 2026-06-25

### Windows zip backslash issue
- Creating zips on Windows with `Compress-Archive` produces backslash paths
- This breaks KSU module installation and WebUI
- Always use archiver library with explicit forward-slash paths (rebuild-zips.js)

### Version strings must match module.prop
- Log headers in post-fs-data.sh, service.sh, and customize.sh must show correct version

### Never use `find -exec rm -rf {} +` on directories with special characters
- Backslash filenames on Android are literal, not path separators
- Caused accidental deletion of all 4 Castorice modules on 2026-06-22

### Always flatten multiline JSON before sed/grep
- `sed`'s `.*` doesn't match newlines
- Use `tr -d '\n\r'` before sed matching

### NEVER strip quotes from JSON values you need to re-embed
- `tr -d '"'` on extracted values produces invalid JSON when re-inserting

### NEVER use `grep -oP` (PCRE) on Android
- Android's toybox/busybox grep does NOT support `-P` (Perl regex)
- Use `sed` instead: `grep -oP '\[.*?\]'` → `sed 's/.*\[\(.*\)\].*/\1/'`
- Caused h_thermal thermal props never zeroed on 2026-07-19

### Use `tr -d '\n\r'` not `tr -d '\n' '\r'`
- Two arguments to `tr -d` deletes chars from FIRST string only. `\r` is NOT removed
- Caused Windows-edited configs corrupting spoofed props on 2026-07-19

## Cross-Module Conflicts

| Conflict | Modules | Notes |
|----------|---------|-------|
| VM params | evanescia vs others | evanescia owns swappiness, dirty_ratio, min_free_kbytes |
| FUSE passthrough | hyacine-io | ONLY toggle from hyacine-io. Never from other modules |
| I/O scheduler | evanescia (mq-deadline) + hyacine-io (read_ahead) | No conflict, different params |
| SD card scan | hyacine-io | Merged from customrom-fix. Do NOT duplicate |
| Hardware props | spoof_fierce | Runtime only (apply_game), NEVER at boot |
| Vendor/ODM props | spoof_fierce | NEVER spoof. Signal loss |
| Thermal | H-Thermal vs X_THERMAL | No conflict — can use both |
| CPU governor | encore | No conflict with evanescia |

## Testing

No test framework. All verification is on-device via adb:

```sh
# Check modules loaded
su -c "ls /data/adb/modules/"

# Check logs
su -c "cat /data/local/tmp/evanescia.log | tail -20"
su -c "cat /data/local/tmp/hyacine_io.log | tail -20"
su -c "cat /data/local/tmp/kairitsu_service.log | tail -20"
su -c "cat /data/local/tmp/spoof_fierce.log | tail -20"

# Check PPM (thermal)
su -c "cat /proc/ppm/policy_status"

# Check CPU max freq
su -c "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"

# Check spoof status
su -c "getprop ro.product.model; getprop ro.hardware; getprop ro.surface_flinger.game_default_frame_rate_override"

# Check WebUI data (spoof_fierce)
su -c "cat /data/adb/modules/spoof_fierce/webroot/status.json"
```

## Zip Build Process

```sh
# Install archiver
npm install archiver

# Build all zips (run from project root)
node rebuild-zips.js

# Push to device
adb push *.zip /sdcard/Download/
```

**DO NOT** use Windows built-in zip tools.

## Install Order

1. `kairitsu_safe` — boot protection dulu
2. Reboot
3. `hyacine_io` — storage I/O
4. `evanescia` — memory tuning
5. `h_thermal` — thermal unlock
6. `spoof_fierce` — device spoof
7. Reboot final

## Conventions

- Docs and commit messages in **Indonesian** (informal)
- Author: **Naidrahiqa**
- Version format: `vX.Y.Z` in module.prop, `-ksunext` suffix in filenames
- Logs go to `/data/local/tmp/`
- Zip files for release go to repo root
- Build zips with Node.js archiver library (rebuild-zips.js)
