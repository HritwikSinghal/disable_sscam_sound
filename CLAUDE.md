# disable_sscam_sound

A flashable Magisk / KernelSU / APatch module that silences the camera shutter
and screenshot sound on modern Android (especially Google Pixel). It works
systemlessly by overlaying a short silent Ogg clip over the system UI sound
files -- the read-only partitions are never modified, so it is fully reversible.

## Repo layout

- `module/` -- module source, zipped into the flashable artifact
  - `module.prop` -- metadata (id, name, version, `updateJson` for in-app auto-update)
  - `customize.sh` -- install-time validator + preview (scans partitions, lists matches)
  - `post-fs-data.sh` -- boot-time worker: bind-mounts the silent clip over found files
  - `sound_paths.sh` -- shared `SSCAM_SOUNDS` / `SSCAM_DIRS` lists (sourced by both)
  - `silent.ogg` -- a short (~0.25s) silent Ogg/Vorbis clip
  - `system/product/overlay/NoSafeMediaVolume/NoSafeMediaVolumeOverlay.apk` -- prebuilt RRO that disables the headphone volume warning
  - `META-INF/com/google/android/{update-binary,updater-script}` -- installer trampoline
- `overlay/` -- RRO source; `scripts/build-overlay.sh` rebuilds the committed APK (needs aapt2/apksigner + `ANDROID_JAR`; key `overlay/keystore.jks` is gitignored)
- `scripts/build.sh` -- builds `dist/disable_sscam_sound-<version>.zip` (version from module.prop)
- `scripts/validate.sh` -- sanity-checks the module source
- `scripts/gen-update-json.sh` -- generates `update.json` (version, versionCode, zipUrl, changelog) for in-app auto-update
- `CHANGELOG.md` -- changelog shown by the in-app updater (`update.json` `changelog` URL points here)
- `.github/workflows/build.yml` -- validate + build + upload artifact on push/PR
- `.github/workflows/release.yml` -- on a `v*` tag: build the zip, generate `update.json`, publish both to a GitHub Release
- `reference/original-broken-module.zip` -- the old broken module, kept for reference

## Key facts

- The camera shutter and the screenshot share the SAME sound file
  (`camera_click.ogg`) on Pixel -- silencing it kills both.
- `silent.ogg` MUST be a real short (~0.25s) Ogg/Vorbis clip, NEVER a 0-byte
  file. Empty files crash SystemUI and break screenshot saving on Android 13+;
  this was a root cause of the original module's failure.
- Silencing is done by `post-fs-data.sh` on every boot, which `mount --bind`s
  `silent.ogg` over each existing UI sound file. This replaced magic-mount
  overlays in v2.1: KernelSU 3.2.0 magic-mount does NOT reach the separate
  `/product` partition (verified on Pixel 10a / Android 17 -- `/system` overlays
  applied, `/product` ones silently did not), so v2.0 installed but silenced
  nothing. `mount --bind` works the same on Magisk, KernelSU, and APatch.
- The screenshot sound on modern Pixel is NOT baked into SystemUI.apk -- it is
  `camera_click.ogg` played via `MediaActionSound` (SHUTTER_CLICK), which reads
  `/product/media/audio/ui/` first. Silencing that file silences both.
- `customize.sh` does NOT delete `silent.ogg` and does NOT build a `system/`
  overlay tree -- `post-fs-data.sh` needs the clip present at boot to bind it.
  `validate.sh` enforces this.
- `sound_paths.sh` holds the `SSCAM_SOUNDS` / `SSCAM_DIRS` lists and is sourced
  by both `customize.sh` (preview) and `post-fs-data.sh` (bind) -- keep it the
  single source of truth so the two never drift.
- `chcon u:object_r:system_file:s0` is applied to the clip before binding so
  SystemUI can read it (otherwise it keeps its `/data/adb` context).
- `update-binary` must be the modern `install_module` trampoline (Magisk 20.4+,
  KernelSU/APatch compatible), NOT the legacy `/dev/magisk_img` one from 2019.
- Module artifact paths must sit at the ZIP ROOT (zip from inside `module/`).
- In-app auto-update: `module.prop` `updateJson` points at
  `releases/latest/download/update.json`. `release.yml` generates `update.json`
  (via `gen-update-json.sh`) and uploads it as a release asset on every `v*`
  tag, so the manager always reads the newest release -- no commit-back to the
  repo. Auto-update only takes effect from a build that ALREADY ships
  `updateJson` (v2.3+); the first such build is installed manually.

- Headphone warning (v2.4+): `SoundDoseHelper` enables CSD when
  `config_safe_media_volume_enabled && config_safe_sound_dosage_enabled` (or
  sysprop `audio.safemedia.csd.force`), and the legacy safe-volume warning when
  `config_safe_media_volume_enabled` is true and CSD is off. Pixel's vendor RRO
  sets both true; the module's RRO sets both false. Turning off CSD alone would
  bring back the legacy warning, so `config_safe_media_volume_enabled` is the
  key bool.
- The RRO must target SDK < 29 and be preinstalled: these bools are not in
  framework-res's `<overlayable>`, and Android skips the overlayable check
  only for pre-Q preinstalled overlays. It must sit on `/product` (or
  `/system_ext`) to outrank the `/vendor` RRO; `/system/overlay` loses.
- `cmd overlay fabricate` (FRRO) does NOT work for this: shell-owned fabricated
  overlays are deleted at boot, and system_server reads the bools only at boot.
- Unlike the shutter part, the RRO relies on the systemless `system/` tree. On
  KernelSU that needs a metamodule (`/data/adb/metamodule`, e.g. Hybrid Mount);
  verified working on Pixel 10a with Hybrid Mount 6.2.2. Verify with
  `dumpsys audio | grep -E 'mEnableCsd|mSafeMediaVolumeState'`.

## Conventions

- ASCII-only in all files (use `--` for dashes, `->` for arrows, `-` for
  bullets; no Unicode or emoji).
- `module.prop` and all shell files use LF line endings (CRLF breaks the installer).
- Bump `version` and `versionCode` in `module/module.prop` together for every
  release; tag as `v<version>` to trigger the release workflow.

## Long-Running Project

This project uses session-persistent tracking. At the start of every session:
1. Read `claude/progress.md` silently for a full catch-up -- do not ask the user to re-explain anything.
2. Do NOT automatically continue working -- wait for the user to indicate they want to proceed.
3. After each completed task, update `claude/progress.md` immediately (mark `[x]`, recount Status Summary, update date).
4. `claude/progress.md` is the primary task tracker. Use `claude/tasks.md` only for ad-hoc items outside the long-running plan.
