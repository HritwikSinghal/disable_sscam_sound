# Tasks
disable_sscam_sound -- flashable module to silence camera shutter and screenshot sound on modern Android (Pixel).

> Planned, phased work lives in claude/progress.md. This file is only for ad-hoc items and follow-ups that do not belong to a phase.

## Ad-hoc / Follow-ups (2026-06-20)
- [x] Add an updateJson URL to module.prop for in-app module updates -- module/module.prop (done v2.3: updateJson -> releases/latest/download/update.json; release.yml generates+uploads update.json via scripts/gen-update-json.sh; CHANGELOG.md added)
- [ ] Consider generating silent.ogg in CI instead of committing the binary (needs ffmpeg in the workflow) -- scripts/build.sh, .github/workflows/build.yml
- [ ] Add more known shutter/screenshot sound filenames if device testing finds others -- module/sound_paths.sh (note: list moved here from customize.sh)
- [x] Document the find-based diagnostic one-liner in the README so users can report missing sound paths -- README.md (done in v2.x)
- [~] Confirm KernelSU and APatch install paths -- KernelSU(-Next) confirmed on Pixel 10a; APatch still untested. -- module/customize.sh
- [ ] APatch: confirm $KSU is not set there so the install-time hiding warning logic still behaves (it only warns when $KSU=true) -- module/customize.sh
- [ ] (research) Make the overlay survive umount WITHOUT the per-app toggle on hiding setups -- susfs legit_mounts.txt / add_sus_mount, or equivalent -- module/post-fs-data.sh
- [ ] (research) open_redirect is a no-op on the Pixel 10a kernel despite CONFIG flag; verify it works (and silences) on kernels that honor it -- module/post-fs-data.sh
