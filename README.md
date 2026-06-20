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

- On Pixel, the camera shutter AND the screenshot play the same sound file:
  camera_click.ogg, via android.media.MediaActionSound (SHUTTER_CLICK), which
  reads /product/media/audio/ui/ first. Silencing that one file kills both.
- On every boot, post-fs-data.sh bind-mounts a short SILENT clip over the real
  UI sound files. The read-only partitions (/system, /product, /vendor, etc.)
  are NEVER modified -- the bind is a mount-namespace overlay, so the change is
  fully reversible by removing the module and rebooting.
- It uses an explicit `mount --bind` rather than the root manager's systemless
  magic-mount, because magic-mount does NOT reliably reach the separate
  /product partition on KernelSU 3.2.0 (verified on a Pixel 10a, Android 17):
  /system overlays apply but /product ones silently do not, which left the
  shutter/screenshot sound playing. An explicit bind works the same on Magisk,
  KernelSU, and APatch.
- The filename and partition lists live in module/sound_paths.sh and are shared
  between install time and boot time. At install, customize.sh scans every
  partition where Pixel may keep UI audio (/system, /system/product, /product,
  /system_ext, /system/system_ext, /vendor, /odm) for known sound filenames
  (camera_click.ogg, camera_focus.ogg, VideoRecord.ogg, VideoStop.ogg, plus OEM
  variants) and prints exactly which files will be silenced, so you can confirm
  the module matched something on your specific firmware before you reboot.

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
   missed the file actually in use. v2 scans all known partitions and silences
   every matching file it finds.

3. Its update-binary was the legacy 2019 trampoline that referenced
   /dev/magisk_img, which has been dead since Magisk v19. v2 uses the current
   install_module trampoline (Magisk 20.4+, and KernelSU / APatch via their
   Magisk compatibility shim).

v2.1 additionally replaces the magic-mount overlay with an explicit
`mount --bind` in post-fs-data.sh, after magic-mount was found not to overlay
the /product partition on KernelSU 3.2.0 (so v2.0 installed cleanly but
silenced nothing on a Pixel 10a).

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

If sounds still play after flashing and rebooting, first confirm the bind
actually took effect. From a root shell, check the live file -- the silent
clip is ~3.6k, so the live file should be that size, not the original:

```
su -c 'ls -l /product/media/audio/ui/camera_click.ogg'
```

If it is still the original (larger) size, the bind did not apply; capture the
mount state and module log and open an issue. If the file IS the silent clip
but a sound still plays, the sound is coming from a file this module does not
know about -- list every candidate on the device:

```
su -c 'find /system /product /system_ext /vendor /odm -type f \( -iname "*.ogg" -o -iname "*.mp3" -o -iname "*.wav" \) 2>/dev/null | grep -iE "shutter|screen|capture|camera|snap"'
```

Include this output when filing an issue so the filename/partition lists in
module/sound_paths.sh can be extended.

## Limitations

- Only silences sounds that are stored as loose files. Third-party camera apps
  that bundle their own shutter sound inside the APK are NOT affected.
- Some regional Pixel firmware (for example, Japan / Korea SIM-locked units)
  enforce the shutter below this layer and may bake the sound into an APK;
  bind mounts cannot silence a sound embedded inside an APK.

## Repository Layout

```
module/                                  -- module source, zipped into the flashable artifact
  module.prop                            -- metadata: id=silence-shutter-screenshot,
                                            name="Silence Shutter and Screenshot", version v2.1
  customize.sh                           -- install-time validator/preview (scans partitions, lists matches)
  post-fs-data.sh                        -- boot-time worker: bind-mounts the silent clip over found files
  sound_paths.sh                         -- shared SSCAM_SOUNDS / SSCAM_DIRS lists (sourced by both)
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
