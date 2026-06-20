# disable_sscam_sound

A flashable Magisk / KernelSU / APatch module that silences the camera shutter
and screenshot sound on modern Android (especially Google Pixel). It works
systemlessly by overlaying a short silent Ogg clip over the system UI sound
files -- the read-only partitions are never modified, so it is fully reversible.

## Repo layout

- `module/` -- module source, zipped into the flashable artifact
  - `module.prop` -- metadata (id, name, version)
  - `customize.sh` -- adaptive installer (scans partitions, overlays silent clips)
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
- `customize.sh` is adaptive: it scans `/system`, `/system/product`, `/product`,
  `/system_ext`, `/system/system_ext`, and `/vendor` for known sound filenames
  and overlays only the ones that exist, mapping each to the correct module
  overlay path.
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
