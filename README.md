# disable_sscam_sound

A flashable Magisk / KernelSU / APatch module that silences the camera
shutter sound AND the screenshot sound on modern Android, with a focus on
Google Pixel.

On Pixel, the camera shutter and the screenshot capture both play the SAME
underlying UI sound file (camera_click.ogg). This module overlays a short
silent clip over the real UI sound files so both go quiet -- without ever
modifying the read-only system partitions.

Since v2.4 it also disables the headphone "high volume" warning and the
automatic volume lowering that follows it -- see
[Headphone volume warning](#headphone-volume-warning-v24). On KernelSU that
part needs a metamodule such as Hybrid Mount.

## Legal Note

Disabling the camera shutter sound is ILLEGAL in some countries, notably
Japan and South Korea. Do NOT use this module where it is prohibited. This
is intended for use on the user's own device, in jurisdictions where it is
lawful. You are responsible for complying with your local laws.

## How It Works

- On Pixel, the camera shutter AND the screenshot play the same sound file:
  camera_click.ogg, via android.media.MediaActionSound (SHUTTER_CLICK), which
  reads /product/media/audio/ui/ first. Silencing that one file kills both.
- On every boot, post-fs-data.sh silences each found sound file two ways:
  (1) `mount --bind` of a short SILENT clip over the real file, and (2) a
  best-effort susfs `add_open_redirect` of the same path. The read-only
  partitions (/system, /product, /vendor, etc.) are NEVER modified -- both are
  overlays, fully reversible by removing the module and rebooting.
- It uses an explicit `mount --bind` rather than the root manager's systemless
  magic-mount, because magic-mount does NOT reliably reach the separate
  /product partition on KernelSU 3.2.0 (verified on a Pixel 10a, Android 17):
  /system overlays apply but /product ones silently do not. An explicit bind
  works the same on Magisk, KernelSU, and APatch.
- IMPORTANT: on a KernelSU setup that HIDES modules from apps (KernelSU "Umount
  modules" and/or susfs auto_try_umount), neither overlay reaches System UI and
  the sound keeps playing. See "Why the sound may still play" below -- this is
  the most common reason it does not work, and the fix is a one-time setting.
- The filename and partition lists live in module/sound_paths.sh and are shared
  between install time and boot time. At install, customize.sh scans every
  partition where Pixel may keep UI audio (/system, /system/product, /product,
  /system_ext, /system/system_ext, /vendor, /odm) for known sound filenames
  (camera_click.ogg, camera_focus.ogg, VideoRecord.ogg, VideoStop.ogg, plus OEM
  variants) and prints exactly which files will be silenced, so you can confirm
  the module matched something on your specific firmware before you reboot.

## Headphone volume warning (v2.4+)

Pixels warn when headphone volume stays high ("High volume for headphones")
and may lower the volume on their own. On Android 14 QPR1+ this is sound dose
(CSD, see https://source.android.com/docs/core/audio/sound-dose) in
`com.android.server.audio.SoundDoseHelper`: it warns at every 100% of the
weekly dose and at 500% lowers media volume to RS1. The older safe-media-volume
dialog ("Raise volume above recommended level?") lives in the same class.

Both are gated by two framework bools, which Pixel turns on through its vendor
overlay:

- CSD runs when `config_safe_media_volume_enabled` AND
  `config_safe_sound_dosage_enabled` are true.
- The legacy warning runs when `config_safe_media_volume_enabled` is true and
  CSD is off.

The module ships an RRO,
`module/system/product/overlay/NoSafeMediaVolume/NoSafeMediaVolumeOverlay.apk`,
that sets both to false. system_server reads them once at boot, so a reboot is
needed after installing or removing the module.

Requirements:

- KernelSU: a metamodule (e.g. Hybrid Mount) must be installed -- KernelSU
  mounts a module's `system/` tree only through one, and the overlay must be in
  `/product/overlay` when the package manager scans at boot. The installer
  warns if `/data/adb/metamodule` is missing.
- Magisk mounts the overlay natively.

Verified on a Pixel 10a (Android 17, CP3A.261005.005, KernelSU 3.4 + Hybrid
Mount 6.2.2 + susfs) with:

```
adb shell cmd overlay list android | grep nosafemediavolume
# [x] io.github.hritwiksinghal.overlay.nosafemediavolume
adb shell dumpsys audio | grep -E 'mEnableCsd|mSafeMediaVolumeState'
#   mEnableCsd=false
#   mSafeMediaVolumeState=SAFE_MEDIA_VOLUME_DISABLED
```

If the overlay is listed as `[ ]` or missing, the module's `system/` tree was
not mounted -- check the metamodule.

These warnings protect your hearing and are required by regulation in some
regions (EU EN 50332-3). Disabling them is your call on your own device.

The overlay is prebuilt and committed. To rebuild it after editing `overlay/`:

```
ANDROID_JAR=/path/to/android.jar bash scripts/build-overlay.sh
```

`ANDROID_JAR` may also be a device's `framework-res.apk`. The script signs
with `overlay/keystore.jks` (gitignored); keep reusing the same key.

## Why the sound may still play on KernelSU (module hiding)

On a KernelSU setup that HIDES modules from apps -- KernelSU's "Umount modules"
feature and/or susfs `auto_try_umount=1` (commonly paired with Zygisk / ReZygisk
for Play Integrity) -- this module installs correctly but the screenshot and
shutter sound KEEP playing. This is not a bug in the overlay; it is the hiding
stack doing exactly what it is meant to.

Why it happens (all verified on a Pixel 10a, Android 17, KernelSU 3.2.0 + susfs):

- The screenshot opens and reads /product/media/audio/ui/camera_click.ogg LIVE
  on every capture (confirmed by an inotify trace). It is the right file.
- The module-hiding feature UNMOUNTS every module overlay from the mount
  namespace of non-root apps so they cannot detect root. System UI -- which
  plays the screenshot sound -- is such an app, so it is handed the ORIGINAL,
  un-silenced file. A root shell sees the 3.6k silent clip; System UI sees the
  original. (Proven device-wide: the unrelated `bindhosts` module's
  /system/etc/hosts overlay is ALSO invisible to System UI.)
- No mount-based overlay (magic-mount or bind) can win against this, because the
  hiding layer removes the mount from the app afterward.
- susfs `add_open_redirect` COULD bypass the umount by redirecting the file open
  in the kernel, and the module applies it best-effort. But on some kernels
  (including the Pixel 10a build tested) `CONFIG_KSU_SUSFS_OPEN_REDIRECT` is
  advertised in `enabled_features` yet is a NO-OP at runtime, so it does not
  help there.

### Fix (recommended): unhide modules from System UI only

Keep root-hiding for your other apps; just let System UI see the overlay:

1. Open the KernelSU / KernelSU-Next manager app.
2. Go to the app list; enable "show system apps" if needed.
3. Find "System UI" (package com.android.systemui).
4. Open its profile and turn OFF "Umount modules" for it.
5. Reboot.

After reboot the silent overlay reaches System UI and the sound is gone, while
banking / Play-Integrity apps stay hidden. (If your build plays the sound from
another uid-1000 component, also turn off "Umount modules" for "Android System"
/ the system package.)

### Fix (simplest, but weakens hiding): disable module-umount globally

Turn off "Umount modules" in the KernelSU manager and set `auto_try_umount=0` in
/data/adb/susfs4ksu/config.sh, then reboot. The overlay then reaches every app
-- but every app can also see your modules again, which weakens Play Integrity /
root hiding. Only do this if hiding does not matter to you on this device.

### Plain Magisk / non-hiding KernelSU

If you do NOT run module hiding, none of the above is needed -- the bind overlay
reaches all apps and the sound is silenced after a reboot.

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

v2.1 replaced the magic-mount overlay with an explicit `mount --bind` in
post-fs-data.sh, after magic-mount was found not to overlay the /product
partition on KernelSU 3.2.0 (so v2.0 installed cleanly but silenced nothing on a
Pixel 10a).

v2.2 adds a best-effort susfs `add_open_redirect` layer and documents that, on
KernelSU setups with module hiding (Umount modules / susfs auto_try_umount), the
overlay is unmounted from System UI and a one-time per-app setting is needed --
see "Why the sound may still play" above.

## Compatibility

- Magisk v20.4 or newer
- KernelSU (the headphone-warning overlay additionally needs a metamodule such
  as Hybrid Mount)
- APatch (headphone-warning overlay untested)
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
3. Reboot. The shutter and screenshot sounds will be silent, and the
   headphone volume warning is off.
4. If nothing is silenced, the installer prints a warning. Run the diagnostic
   below and open an issue with the output.

## Updates (in-app auto-update)

From v2.3 on, the module supports the root manager's built-in updater. module.prop
carries an `updateJson` field pointing at:

```
https://github.com/HritwikSinghal/disable_sscam_sound/releases/latest/download/update.json
```

On every `v*` tag, CI builds the zip, generates `update.json` (version,
versionCode, the tagged zip URL, and a changelog URL), and uploads BOTH as
release assets. Because the URL targets `releases/latest/download/update.json`,
the manager always reads the newest release's metadata -- no commit-back to the
repo. KernelSU(-Next) / Magisk / APatch will then show an update and flash it
in-app when a newer `versionCode` is published.

Note: auto-update only works once you are running a build that already contains
the `updateJson` field (v2.3+). Install v2.3 manually once; subsequent releases
update from within the manager. The `changelog` shown by the updater is
[CHANGELOG.md](CHANGELOG.md).

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
                                            name="Silence Shutter, Screenshot and Headphone Warning", v2.4,
                                            updateJson (in-app auto-update URL)
  customize.sh                           -- install-time validator/preview (scans partitions, lists
                                            matches; warns if KernelSU module-hiding is active)
  post-fs-data.sh                        -- boot-time worker: bind-mounts the silent clip over found
                                            files (+ best-effort susfs open_redirect)
  sound_paths.sh                         -- shared SSCAM_SOUNDS / SSCAM_DIRS lists (sourced by both)
  silent.ogg                             -- real ~0.25s silent Ogg/Vorbis clip (NOT a 0-byte file)
  system/product/overlay/NoSafeMediaVolume/
    NoSafeMediaVolumeOverlay.apk         -- prebuilt RRO disabling sound dose + safe media volume
  META-INF/com/google/android/
    update-binary                        -- modern installer trampoline (install_module)
    updater-script                       -- modern installer trampoline
overlay/                                 -- RRO source (AndroidManifest.xml, res/values/bools.xml)
CHANGELOG.md                             -- changelog shown by the in-app updater (update.json points here)
scripts/
  build.sh                               -- builds dist/disable_sscam_sound-<version>.zip from module/
                                            (version read from module.prop)
  validate.sh                            -- sanity-checks module source: required files, module.prop
                                            keys (incl. updateJson), non-empty ogg, signed overlay APK,
                                            LF, update.json JSON
  build-overlay.sh                       -- rebuilds the overlay APK from overlay/ (aapt2, apksigner)
  gen-update-json.sh                     -- generates update.json (version, versionCode, zipUrl,
                                            changelog) from module.prop + the release tag
.github/workflows/
  build.yml                              -- validates + builds the zip on every push/PR,
                                            uploads it as a CI artifact
  release.yml                            -- on a v* git tag, builds the zip, generates update.json,
                                            and publishes both to a GitHub Release
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
