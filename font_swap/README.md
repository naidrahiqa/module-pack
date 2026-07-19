# Font Swap v1.0.0

System font customization module untuk **Redmi 10 (selene) MT6768** — LineageOS 20 (Android 13).

## Features

- Font flipping (runtime font switching)
- Multiple font profiles (Google Sans, Roboto variants, Slab, Mono, Rounded, Condensed)
- Custom font file support (.ttf/.otf)
- Font scale adjustment (0.85–1.3)
- HWUI font cache optimization
- Font rendering optimization

## Install

Flash via KSU Manager. Reboot setelah install.

## Usage

```sh
# List available fonts
sh /data/adb/modules/font_swap/font_config.sh list

# Apply a profile
sh /data/adb/modules/font_swap/font_config.sh apply google

# Set custom font file
sh /data/adb/modules/font_swap/font_config.sh custom /sdcard/MyFont.ttf

# Adjust font scale
sh /data/adb/modules/font_swap/font_config.sh set-scale 1.1

# Restore default
sh /data/adb/modules/font_swap/font_config.sh restore

# Check status
sh /data/adb/modules/font_swap/font_config.sh status
```

## Font Profiles

Place `.ttf` or `.otf` files in the corresponding directory under `fonts/`:

```
fonts/
├── default/      — Stock Roboto
├── google/       — Google Sans (Pixel style)
├── roboto/       — Roboto with condensed numerals
├── slab/         — Roboto Slab (serif)
├── mono/         — Roboto Mono (monospace)
├── rounded/      — Google Sans Rounded
├── condensed/    — Roboto Condensed
└── custom/       — User custom fonts
```

## Properties

| Property | Value | Description |
|----------|-------|-------------|
| `persist.sys.font.flipping` | `1` | Enable runtime font switching |
| `ro.config.font_scale` | `1.0` | Font scale (0.85–1.3) |
| `persist.sys.font_rendering` | `1` | Optimized font rendering |
| `debug.hwui.font_cache` | `1` | HWUI font cache enabled |
| `persist.sys.font.custom` | `<path>` | Custom font file path |

## Disable

```sh
touch /data/local/tmp/font_swap_disable
```

## Logs

```sh
cat /data/local/tmp/font_swap.log
```

## Author

Naidrahiqa
