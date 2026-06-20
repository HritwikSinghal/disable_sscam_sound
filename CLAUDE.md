# disable_sscam_sound

A flashable Magisk / KernelSU / APatch module that silences the camera shutter
and screenshot sound on modern Android (especially Google Pixel). It works
systemlessly by overlaying a short silent Ogg clip over the system UI sound
files -- the read-only partitions are never modified, so it is fully reversible.

## Repo layout

- `module/` -- module source, zipped into the flashable artifact
  - `module.prop` -- metadata (id, name, version)
  - `customize.sh` -- install-time validator + preview (scans partitions, lists matches)
  - `post-fs-data.sh` -- boot-time worker: bind-mounts the silent clip over found files
  - `sound_paths.sh` -- shared `SSCAM_SOUNDS` / `SSCAM_DIRS` lists (sourced by both)
  - `silent.ogg` -- a short (~0.25s) silent Ogg/Vorbis clip
  - `META-INF/com/google/android/{update-binary,updater-script}` -- installer trampoline
- `scripts/build.sh` -- builds `dist/disable_sscam_sound-<version>.zip` (version from module.prop)
- `scripts/validate.sh` -- sanity-checks the module source
- `.github/workflows/build.yml` -- validate + build + upload artifact on push/PR
- `.github/workflows/release.yml` -- publish the zip to a GitHub Release on a `v*` tag
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
