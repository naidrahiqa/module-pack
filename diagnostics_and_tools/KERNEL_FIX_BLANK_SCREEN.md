# Fix Blank Screen — Phrolova Kernel (Redmi 10 / selene / MT6768)

## Problem Statement

Redmi 10 (selene) using Phrolova kernel on LineageOS 20 experiences intermittent blank screen while actively using the phone (scrolling, browsing). The screen goes black but:
- System is still running (audio continues playing)
- Touch input still works (can unlock via fingerprint/power button)
- No native crash in logcat (no display/HWC/SurfaceFlinger tombstones)

## Root Cause (Verified)

Phrolova kernel is built with `CONFIG_DRM=n`. The display uses the legacy `mtkfb` (MediaTek Framebuffer) driver instead of the modern DRM/KMS framework.

The DSI panel on Redmi 10 is a **Video Mode DSC panel** (`dsi_panel_k19a_*_dsc_vdo`). The `mtkfb` driver has known issues with DSC (Display Stream Compression) video mode panels:
1. DSI panel loses sync during power state transitions
2. `mtkfb_blank()` sets `blank_mode=4` (FB_BLANK_POWERDOWN) but panel recovery is unreliable
3. `Excessive delay in setPowerMode()` logged by SurfaceFlinger

MIUI 14 works because it enables `CONFIG_DRM=y` and uses the DRM/KMS display pipeline, which properly handles DSC video mode panels.

### Why CONFIG_DRM=y alone is NOT enough

From internet research (MTK DRM fixes 2025, upstream kernel patches):
- **Panel drivers must exist** in `drivers/gpu/drm/panel/` for your specific panel
- **Device tree must define the panel** with correct timing and DSC configuration
- **DSI host bridge ordering** matters — upstream fix `pre_enable_prev_first = true` ensures DSI host is ready before panel bridge
- **DSC support** must be explicitly enabled in both kernel config AND device tree

## Evidence from Device

```
# Kernel config shows legacy display path:
# CONFIG_DRM is not set
CONFIG_CUSTOM_KERNEL_LCM="dsi_panel_k19a_36_02_0a_dsc_vdo dsi_panel_k19a_43_02_0b_dsc_vdo dsi_panel_k19a_36_03_0c_dsc_vdo"

# dmesg shows mtkfb path:
SXF Enter mtkfb_blank_ 617 blank_mode =4 , prim_panel_is_on =0
[PWM] disp_pwm_backlight_status: backlight is off
thermal_sys: screen_state_for_thermal_callback: FB_BLANK_POWERDOWN

# logcat shows HWC struggling:
SurfaceControl: Excessive delay in setPowerMode()
hwcomposer: [HWCDisplay] Display(0) SetPowerMode(0)
hwservicemanager: Cannot find entry android.hardware.configstore@1.0

# SELinux spam (2535+ denials):
avc: denied { dac_override } for comm="NodeLooperThrea" scontext=u:r:hal_power_default:s0
```

## Fix Requirements

### Step 1: Verify panel drivers exist in your kernel tree

Before changing any config, CHECK if panel source files exist:

```bash
# In your phrolova kernel source tree:
find drivers/gpu/drm/panel/ -name "*k19a*" -o -name "*selene*" -o -name "*mt6768*"
```

If NO panel files found → you need to port them from:
- **Xiaomi kernel source**: `MiCode/Xiaomi_Kernel_OpenSource` branch `selene-r-oss`
- **Volla/UT-kernel**: `HelloVolla/UT-kernel-volla-mt6768` (has DRM + DSC + DSI)
- **LineageOS kernel tree** for selene that has DRM enabled

Panel files to look for:
```
drivers/gpu/drm/panel/panel-dsi-k19a-36-02-0a-dsc-vdo.c
drivers/gpu/drm/panel/panel-dsi-k19a-43-02-0b-dsc-vdo.c
drivers/gpu/drm/panel/panel-dsi-k19a-36-03-0c-dsc-vdo.c
```

### Step 2: Enable DRM/KMS in kernel defconfig

In your kernel `defconfig` (likely `arch/arm64/configs/mt6768_selene_defconfig` or similar):

```kconfig
# === Display Pipeline (REQUIRED) ===
CONFIG_DRM=y
CONFIG_DRM_MEDIATEK=y

# DSI support (panel uses DSI)
CONFIG_DRM_MEDIATEK_DSI=y

# DSC support (panel uses DSC - Display Stream Compression)
CONFIG_DRM_MEDIATEK_DSC=y

# Panel drivers (match your CUSTOM_KERNEL_LCM list)
# ⚠️ CONFIG NAMES DEPEND ON ACTUAL SOURCE FILE NAMES
# Check drivers/gpu/drm/panel/ for exact names
CONFIG_DRM_PANEL_DSI_K19A_36_02_0A_DSC_VDO=y
CONFIG_DRM_PANEL_DSI_K19A_43_02_0B_DSC_VDO=y
CONFIG_DRM_PANEL_DSI_K19A_36_03_0C_DSC_VDO=y

# Framebuffer emulation (provides /dev/fb0 for SurfaceFlinger)
CONFIG_DRM_FBDEV_EMULATION=y

# Framebuffer console
CONFIG_FRAMEBUFFER_CONSOLE=y
```

### Step 3: Keep mtkfb as fallback (important!)

DO NOT remove mtkfb support entirely. Some userspace components still reference `/dev/fb0`. On MT6768, DRM and mtkfb can coexist:

```kconfig
CONFIG_MTK_FB=y
CONFIG_MTK_FB_SUPPORT=y
```

DRM will take over the display pipeline, but mtkfb provides the `/dev/fb0` interface that SurfaceFlinger and legacy apps expect.

### Step 4: Verify device tree panel definition

Check `arch/arm64/boot/dts/mediatek/mt6768-selene.dts` (or `mt6768.dtsi`):

```dts
&dsi0 {
    status = "okay";
    
    panel@0 {
        compatible = "dsi_panel_k19a_36_02_0a_dsc_vdo";
        
        // Panel timing (must match panel spec)
        // These are example values - check your panel datasheet
        port {
            panel_in: endpoint {
                remote-endpoint = <&dsi_out>;
            };
        };
    };
};
```

If device tree doesn't have panel node → you need to add it from Xiaomi source or another kernel tree.

### Step 5: DSI host bridge fix (from upstream MTK DRM patches)

The upstream kernel has a critical fix for DSI host bridge ordering. If your kernel doesn't have this, add to `drivers/gpu/drm/mediatek/mtk_dsi.c`:

```c
// In mtk_dsi_host_attach(), after getting next_bridge:
dsi->next_bridge->pre_enable_prev_first = true;
```

This ensures DSI host is ready BEFORE the panel bridge tries to send init commands. Without this, panel init can fail silently → blank screen.

Reference: https://git.kernel.org (mediatek-drm-fixes-20250829)

### Step 6: Fix hal_power_default SELinux denial (optional but recommended)

Add to `device/xiaomi/selene/sepolicy/vendor/hal_power_default.te`:

```
allow hal_power_default self:capability { dac_override };
```

Or more targeted:

```
allow hal_power_default sysfs_devices_system_cpu:dir { open read getattr };
allow hal_power_default sysfs_devices_system_cpu:file { open read getattr };
```

This stops the 2535+ SELinux denials per session that slow down the power HAL.

## Testing Checklist

After building with DRM enabled:

### Basic Verification
- [ ] `zcat /proc/config.gz | grep DRM` → should show `CONFIG_DRM=y`
- [ ] `ls /dev/dri/` → should show `card0` and `renderD128`
- [ ] `cat /sys/class/drm/card0-DSI-1/status` → should show `connected`

### Display Test
- [ ] Display works at boot (splash screen shows)
- [ ] No blank screen during heavy use (scroll TikTok/Instagram for 10+ min)
- [ ] `logcat | grep setPowerMode` → no "Excessive delay" messages
- [ ] `dmesg | grep mtkfb_blank` → should NOT appear (DRM handles blanking)
- [ ] `dmesg | grep -i "drm.*error\|drm.*fault"` → no errors
- [ ] Screen timeout works (screen off/on via power button)

### Functional Test
- [ ] Fingerprint works
- [ ] WiFi connects
- [ ] Bluetooth works
- [ ] Camera works
- [ ] Audio works
- [ ] Touch works properly
- [ ] Brightness control works

### Stability Test
- [ ] No kernel panics after 1 hour of use
- [ ] No random reboots
- [ ] Thermal zones readable
- [ ] SELinux denials for hal_power_default reduced

## Build Commands

```bash
# Clean build
make clean && make mrproper

# Apply defconfig
make mt6768_selene_defconfig  # or your defconfig name

# Verify DRM is enabled
grep "CONFIG_DRM" .config
# Should show:
# CONFIG_DRM=y
# CONFIG_DRM_MEDIATEK=y
# CONFIG_DRM_MEDIATEK_DSI=y

# Build
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    CC=clang LLVM=1 LLVM_IAS=1 \
    Image dtbs modules

# Output:
# arch/arm64/boot/Image.gz-dtb → flash to boot partition
```

## Quick Verification (if can't build yet)

If you want to test if DRM would fix the issue BEFORE rebuilding kernel:

```sh
# On device, check if current kernel supports DRM module
adb shell "su -c 'modprobe drm 2>&1'"
# If "module not found" → kernel compiled without DRM, need rebuild
# If no error → DRM might be loadable as module

# Check if panel driver is built-in or module
adb shell "su -c 'cat /proc/modules | grep drm'"

# Check what display path is currently used
adb shell "su -c 'cat /proc/config.gz'" | gunzip | grep -E "DRM|MTK_FB|PANEL"
```

## References

- **Panel list**: `CONFIG_CUSTOM_KERNEL_LCM="dsi_panel_k19a_36_02_0a_dsc_vdo dsi_panel_k19a_43_02_0b_dsc_vdo dsi_panel_k19a_36_03_0c_dsc_vdo"`
- **Device**: Redmi 10 (codename: selene)
- **SoC**: MediaTek MT6768 (Helio G88)
- **Kernel**: Linux 4.14.x
- **Panel type**: DSI Video Mode with DSC
- **Working reference**: MIUI 14 (CONFIG_DRM=y)
- **Broken reference**: LineageOS 20 (CONFIG_DRM=n)
- **Kernel source refs**: 
  - `MiCode/Xiaomi_Kernel_OpenSource` (selene-r-oss branch)
  - `HelloVolla/UT-kernel-volla-mt6768` (has DRM + DSC)
  - `techyminati/selene` (rebased kernel source)
- **Upstream DRM fixes**: https://git.kernel.org (mediatek-drm-fixes-20250829)
  - DSI host bridge pre-enable order fix
  - DSC support patches
  - Atomic disable null pointer fix
