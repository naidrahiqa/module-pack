# Spoof Fierce

Device spoofing module for KernelSU. Spoofs product properties to unlock higher graphics settings (90/120/165fps) in mobile games.

**Play Integrity safe** - only spoofs product props, not security props. Build fingerprint unchanged.

## Features

- Per-game device spoofing (each game gets its own target device + FPS)
- 8 flagship device presets with local images
- Claude-style WebUI for managing settings
- Dynamic FPS per game (60/90/120/144/165)
- GameSpace sync support
- Auto-verify on boot (re-applies if ROM resets props)
- No GPU/EGL/OpenGL changes (safe for Mali GPUs)
- marketname spoof (About Phone shows spoofed device name)
- Backup/Restore config from WebUI
- FPS Test feature
- Search/filter in app list

## Requirements

- KernelSU (tested with ksud 3.2.0)
- Android 10+
- resetprop at `/data/adb/ksu/bin/resetprop`

## Installation

1. Download `Spoof_Fierce_v1.0.0.zip`
2. Open KernelSU app → Modules → Install from storage
3. Select the zip file
4. Reboot

## Usage

### WebUI

Open KernelSU → Modules → Spoof Fierce → **Launch**

#### Games Tab
- View all added games with per-game settings
- Toggle on/off per game
- Change FPS per game (dropdown)
- **Apply** - Apply spoof for that specific game
- **Edit** - Change target device/FPS
- **X** - Remove game
- **+ Add Game** - Browse installed apps, select target device
- **Apply All Enabled** - Apply all enabled games at once
- **Sync GameSpace** - Push config to Infinity X GameSpace

#### Device Tab
- View current spoofed properties
- Change default target device for new games
- View marketname (About Phone display name)
- Backup/Restore config

#### Log Tab
- View recent activity log

#### About Tab
- Module version info
- FPS Test (apply 60/90/120/144/165 globally to test)
- Quick Actions (restore all props)

### Manual Config

**Default device** (`device.conf`):
```
model|brand|manufacturer|device|board|fps|marketname
```
Example: `25010PN30G|Xiaomi|Xiaomi|xuanyuan|sun|120|Xiaomi 15 Ultra`

**Per-game config** (`games.conf`):
```
package|model|manufacturer|board|hardware|device|fps|enabled
```
Example: `com.mobile.legends|25010PN30G|Xiaomi|sun|qcom|xuanyuan|120|1`

### Disable Module

```bash
touch /data/local/tmp/spoof_fierce_disable
```

Remove the file to re-enable:
```bash
rm /data/local/tmp/spoof_fierce_disable
```

## Device Presets

| Device | Chipset | Board | Device Codename | Max FPS |
|--------|---------|-------|-----------------|---------|
| Xiaomi 15 Ultra | Snapdragon 8 Elite | sun | xuanyuan | 120 |
| Samsung S25 Ultra | Snapdragon 8 Elite | e3q | e3q | 120 |
| OnePlus 13 | Snapdragon 8 Elite | sun | houji | 120 |
| Pixel 9 Pro | Tensor G4 | zuma | husky | 120 |
| Xiaomi 14 | Snapdragon 8 Gen 3 | kalama | houji | 120 |
| iQOO 13 | Snapdragon 8 Elite | sun | kona | 120 |
| ROG Phone 9 | Snapdragon 8 Elite | sun | artemi | 165 |
| Realme GT7 Pro | Snapdragon 8 Elite | sun | lemans | 120 |

## Spoofed Properties

| Property | Description |
|----------|-------------|
| `ro.product.model` | Device model number |
| `ro.product.brand` | Device brand |
| `ro.product.manufacturer` | Device manufacturer |
| `ro.product.device` | Device codename |
| `ro.product.board` | Board/platform |
| `ro.product.marketname` | Display name in About Phone |
| `ro.surface_flinger.game_default_frame_rate_override` | FPS limit |
| `debug.graphics.game_default_frame_rate_disabled` | FPS enforcement |

**NOT spoofed**: `ro.build.fingerprint` (Play Integrity safe)

## Boot Process

1. **post-fs-data.sh** - Reads `device.conf`, applies default spoof props + marketname
2. **service.sh** - Waits for boot complete, verifies props, re-applies if reset, scans apps
3. **api.sh** - WebUI backend (read/write configs, apply/restore spoof)

## Known Issues

- `ksu.exec()` return values don't work in WebUI - solved by reading files via fetch
- `ksu.exec('pm list packages')` doesn't execute from WebUI - solved by boot-time cache in `apps_cache.tmp`
- Per-game spoof does NOT affect Play Integrity (only product props changed)
- GameSpace sync is manual only (auto-sync caused blank screen)

## File Structure

```
spoof_fierce/
├── module.prop          # Module metadata (v1.0.0)
├── post-fs-data.sh      # Boot-time spoof + marketname
├── service.sh           # Runtime verify + app scan
├── api.sh               # WebUI backend
├── device.conf          # Default target device (7 fields)
├── games.conf           # Per-game config
├── sepolicy.rule        # SELinux rules
├── customize.sh         # Installer
├── webroot/
│   ├── index.html       # WebUI frontend (Claude-style)
│   └── img/             # Device images (8 phones)
└── META-INF/            # KernelSU installer
```

## Logs

```bash
cat /data/local/tmp/spoof_fierce.log
```

## Uninstall

1. Disable in KernelSU → Modules
2. Reboot
3. Delete module folder: `rm -rf /data/adb/modules/spoof_fierce`

## Credits

- **opencode** - Author
- Device images from GSMArena
- Inspired by Infinity X GameSpace
