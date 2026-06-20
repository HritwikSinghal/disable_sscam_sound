# disable_sscam_sound

A flashable Magisk / KernelSU / APatch module that silences the camera
shutter sound AND the screenshot sound on modern Android, with a focus on
Google Pixel.

On Pixel, the camera shutter and the screenshot capture both play the SAME
underlying UI sound file (camera_click.ogg). This module overlays a short
silent clip over the real UI sound files so both go quiet -- without ever
modifying the read-only system partitions.

## Legal Note

Disabling the camera shutter sound is ILLEGAL in some countries, notably
Japan and South Korea. Do NOT use this module where it is prohibited. This
is intended for use on the user's own device, in jurisdictions where it is
lawful. You are responsible for complying with your local laws.

## How It Works

- On Pixel, the camera shutter AND the screenshot use the same sound file:
  camera_click.ogg. Silencing that one file kills both.
- The module overlays a short SILENT clip over the real UI sound files using
  the root manager's systemless overlay (magic mount / overlayfs). The real
  read-only partitions (/system, /product, /vendor, etc.) are NEVER modified,
  so the change is fully reversible.
- customize.sh is ADAPTIVE. At install time it scans every partition where
  Pixel may keep UI audio:
    - /system
    - /system/product
    - /product
    - /system_ext
    - /system/system_ext
    - /vendor
  for known sound filenames, including:
    - camera_click.ogg
    - camera_focus.ogg
    - VideoRecord.ogg
    - VideoStop.ogg
    - camera_shutter.ogg
    - ScreenCapture.ogg
  For each file it actually finds, it overlays a silent copy at the correct
  module-mapped path. It then prints exactly which files it silenced, so you
  can confirm the module did something on your specific firmware.

## Why v2 -- What Was Broken in the Original 2019 Module

The original 2019 module (kept for reference at
reference/original-broken-module.zip) does NOT work on modern Pixel devices.
Three things were broken:

1. It shipped a 0-BYTE camera_click.ogg. Empty sound files crash SystemUI and
   break screenshot saving on Android 13+, and newer builds simply fall back
   to the default sound. v2 ships a real, short silent Ogg/Vorbis clip
   instead of an empty file.

2. It only overlaid ONE path (system/product/media/audio/ui). Modern Pixel
   keeps these sounds spread across several partitions, so the single overlay
   missed the file actually in use. v2 scans all known partitions and overlays
   every matching file it finds.

3. Its update-binary was the legacy 2019 trampoline that referenced
   /dev/magisk_img, which has been dead since Magisk v19. v2 uses the current
   install_module trampoline (Magisk 20.4+, and KernelSU / APatch via their
   Magisk compatibility shim).

## Compatibility

- Magisk v20.4 or newer
- KernelSU
- APatch
- Tested target: Google Pixel on recent Android.
- Systemless and fully reversible: just remove the module and reboot.

## Installation

1. Get the zip, either:
   - Download the latest disable_sscam_sound-*.zip from the GitHub Releases
     page:
     https://github.com/HritwikSinghal/disable_sscam_sound/releases
   - Or build it locally:
     ```
     bash scripts/build.sh
     ```
2. Flash it:
   - Magisk app: Modules -> Install from storage -> select the zip.
   - KernelSU / APatch app: Modules -> Install -> select the zip.
3. Reboot. The shutter and screenshot sounds will be silent.
4. If nothing is silenced, the installer prints a warning. Run the diagnostic
   below and open an issue with the output.

## Diagnostic

If sounds still play after flashing and rebooting, the sound may be baked
into an APK rather than stored as a standalone file. From a root shell,
list every candidate sound file on the device:

```
find /system /product /system_ext /vendor -type f \( -iname '*camera_click*' -o -iname '*camera_shutter*' -o -iname '*screenshot*' -o -iname '*VideoRecord*' \) 2>/dev/null
```

Include this output when filing an issue.

## Limitations

- Only silences apps that use the system UI sounds. Third-party camera apps
  that bundle their own shutter sound are NOT affected.
- Some regional Pixel firmware (for example, Japan / Korea SIM-locked units)
  enforce the shutter and may bake the sound directly into an APK. File
  overlays cannot silence sounds embedded inside an APK.

## Repository Layout

```
module/                                  -- module source, zipped into the flashable artifact
  module.prop                            -- metadata: id=silence-shutter-screenshot,
                                            name="Silence Shutter and Screenshot", version v2.0
  customize.sh                           -- adaptive installer (scans partitions, overlays found files)
  silent.ogg                             -- real ~0.25s silent Ogg/Vorbis clip (NOT a 0-byte file)
  META-INF/com/google/android/
    update-binary                        -- modern installer trampoline (install_module)
    updater-script                       -- modern installer trampoline
scripts/
  build.sh                               -- builds dist/disable_sscam_sound-<version>.zip from module/
                                            (version read from module.prop)
  validate.sh                            -- sanity-checks module source: required files, module.prop
                                            keys, non-empty ogg, LF line endings
.github/workflows/
  build.yml                              -- validates + builds the zip on every push/PR,
                                            uploads it as a CI artifact
  release.yml                            -- on a v* git tag, builds and publishes the zip
                                            to a GitHub Release
reference/
  original-broken-module.zip             -- the old 2019 module that does NOT work on modern
                                            Pixel, kept as a reference
```

## Building Locally

The build reads the version from module/module.prop and produces the zip
under dist/:

```
bash scripts/build.sh
```

To sanity-check the module source before building:

```
bash scripts/validate.sh
```
