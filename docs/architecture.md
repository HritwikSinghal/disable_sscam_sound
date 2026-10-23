# Pixel Sound Expert -- architecture

TL;DR: the shutter/screenshot part bind-mounts a short silent Ogg clip over
`camera_click.ogg` (and friends) on every boot from `post-fs-data.sh`. The
headphone part is a prebuilt RRO that sets two framework bools to false. Both
are systemless and reversible.

## Shutter and screenshot sound

- On Pixel, the camera shutter and the screenshot play the SAME file:
  `camera_click.ogg`, via `android.media.MediaActionSound` (SHUTTER_CLICK),
  which reads `/product/media/audio/ui/` first. Silencing that file kills both.
  An inotify trace confirmed the screenshot opens the file live on every
  capture; it is not baked into SystemUI.apk.
- `post-fs-data.sh` runs each boot before zygote. For every file found in
  `SSCAM_DIRS` x `SSCAM_SOUNDS` (`module/sound_paths.sh`) it:
  1. `chcon u:object_r:system_file:s0` the clip so SystemUI can read it
     (otherwise it keeps its `/data/adb` context);
  2. `mount --bind` the clip over the file;
  3. best-effort susfs `add_open_redirect` of the same path.
- `customize.sh` only validates and previews at install time: it scans the
  same lists, prints what will be silenced, and warns about KernelSU module
  hiding and a missing metamodule. It must not delete `silent.ogg` or build a
  `system/` tree for the sounds -- `validate.sh` enforces the first.
- `sound_paths.sh` is the single source of truth for both scripts so the
  preview and the boot-time bind never drift.

### Why `mount --bind` and not magic-mount

KernelSU 3.2.0 magic-mount applies `/system` overlays but silently does NOT
reach the separate `/product` partition (verified on Pixel 10a, Android 17).
v2.0 installed cleanly and silenced nothing. An explicit bind behaves the same
on Magisk, KernelSU and APatch.

### Why `silent.ogg` must not be empty

A 0-byte file crashes SystemUI and breaks screenshot saving on Android 13+.
`silent.ogg` is a real ~0.25 s Ogg/Vorbis clip (~3.6 KB); both `customize.sh`
and `post-fs-data.sh` refuse an empty one.

## Module hiding on KernelSU

KernelSU "Umount modules" and susfs `auto_try_umount=1` (often paired with
ReZygisk for Play Integrity) unmount every module mount from the namespace of
non-root apps. System UI is such an app, so it is handed the original file
while a root shell sees the silent clip. Proven device-wide: the unrelated
`bindhosts` module's `/system/etc/hosts` was also invisible to System UI.

- No mount-based overlay can win: the hiding layer removes it afterwards.
- susfs `open_redirect` would bypass this in the kernel, but on the Pixel 10a
  kernel `CONFIG_KSU_SUSFS_OPEN_REDIRECT` is advertised yet a no-op (tested in
  isolation). The module still applies it in case other kernels honor it.
- Per-app umount cannot be set from a module: `ksud` has no CLI for it, only
  the global `ksud feature set kernel_umount 0`, and the per-app state lives in
  `/data/adb/ksu/.allowlist`, which only the manager writes. Hence the
  one-time manual step in the README.
- Global alternative: turn off "Umount modules" and set `auto_try_umount=0` in
  `/data/adb/susfs4ksu/config.sh`. This weakens root hiding for every app.
- If another uid-1000 component plays the sound on some build, also turn off
  "Umount modules" for "Android System".

Verify what an app sees through its own mount namespace, not a root shell
(root is exempt from umount):

```
su -c 'ls -l /proc/$(pidof com.android.systemui)/root/product/media/audio/ui/camera_click.ogg'
```

## Headphone volume warning

On Android 14 QPR1+ the warning is sound dose (CSD,
https://source.android.com/docs/core/audio/sound-dose) in
`com.android.server.audio.SoundDoseHelper`: it warns at every 100% of the
weekly dose and at 500% lowers media volume to RS1. The legacy "Raise volume
above recommended level?" dialog lives in the same class.

- CSD runs when `config_safe_media_volume_enabled` AND
  `config_safe_sound_dosage_enabled` are true (or sysprop
  `audio.safemedia.csd.force`).
- The legacy warning runs when `config_safe_media_volume_enabled` is true and
  CSD is off. So turning off CSD alone brings the legacy warning back.
- Pixel's `/vendor` RRO sets both true. The module's RRO
  (`module/system/product/overlay/NoSafeMediaVolume/NoSafeMediaVolumeOverlay.apk`,
  source in `overlay/`) sets both false. system_server reads them once at boot.

Constraints on the RRO:

- `targetSdkVersion` < 29 and preinstalled: the bools are not in
  framework-res's `<overlayable>`, and Android skips that check only for pre-Q
  preinstalled overlays.
- Must sit on `/product` (or `/system_ext`) to outrank the `/vendor` RRO;
  `/system/overlay` loses.
- `cmd overlay fabricate` (FRRO) does not work: shell-owned fabricated overlays
  are deleted at boot, before system_server reads the bools.
- Unlike the sound bind, this relies on the systemless `system/` tree. KernelSU
  mounts that only through a metamodule (`/data/adb/metamodule`, e.g. Hybrid
  Mount 6.2.2, verified). Magisk mounts it natively.

Rebuild the APK after editing `overlay/` (needs aapt2 + apksigner; signs with
the gitignored `overlay/keystore.jks` -- keep reusing it):

```
ANDROID_JAR=/path/to/android.jar bash scripts/build-overlay.sh
```

`ANDROID_JAR` may also be a device's `framework-res.apk`.

## Install, update and release

- `META-INF/com/google/android/update-binary` is the modern `install_module`
  trampoline (Magisk 20.4+, KernelSU/APatch compatible). The 2019 one used the
  dead `/dev/magisk_img`.
- Module files sit at the zip root (`build.sh` zips from inside `module/`).
- In-app update: `module.prop` `updateJson` points at
  `releases/latest/download/update.json`. On each `v*` tag, `release.yml`
  validates, builds, generates `update.json` (`scripts/gen-update-json.sh`)
  and publishes both to a GitHub Release, so the manager always reads the
  newest release with no commit-back.
- v2.5 renamed the module id from `silence-shutter-screenshot` to
  `pixel-sound-expert`. Managers treat a new id as a new module, so
  `customize.sh` touches `/data/adb/modules/silence-shutter-screenshot/remove`;
  the manager deletes the old module on the next boot.

## History

The 2019 module (`reference/original-broken-module.zip`) failed on modern
Pixel because it shipped a 0-byte ogg, overlaid only
`system/product/media/audio/ui`, and used the legacy update-binary.

| Version | Change |
|---|---|
| v2.0 | Rewrite: real silent clip, scan all partitions, modern installer |
| v2.1 | magic-mount -> `mount --bind` (magic-mount misses `/product` on KernelSU) |
| v2.2 | best-effort susfs open_redirect; install-time module-hiding warning |
| v2.3 | in-app auto-update via `updateJson` |
| v2.4 | RRO disabling the headphone volume warning |
| v2.5 | renamed to Pixel Sound Expert; GPL-3.0 |

## Repo layout

```
module/            flashable module (zipped as-is)
  module.prop        id, version, updateJson
  customize.sh       install-time preview + warnings + old-id cleanup
  post-fs-data.sh    boot-time bind + open_redirect
  sound_paths.sh     SSCAM_SOUNDS / SSCAM_DIRS
  silent.ogg         ~0.25 s silent Ogg/Vorbis
  system/product/overlay/NoSafeMediaVolume/   prebuilt RRO
  META-INF/...       installer trampoline
overlay/           RRO source
scripts/           build.sh, validate.sh, build-overlay.sh, gen-update-json.sh
.github/workflows/ ci.yml (lint + validate + build), release.yml (tag -> release)
reference/         original broken 2019 module
```
