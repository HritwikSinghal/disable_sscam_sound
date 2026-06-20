# Tasks
disable_sscam_sound -- flashable module to silence camera shutter and screenshot sound on modern Android (Pixel).

> Planned, phased work lives in claude/progress.md. This file is only for ad-hoc items and follow-ups that do not belong to a phase.

## Ad-hoc / Follow-ups (2026-06-20)
- [ ] Add an updateJson URL to module.prop for in-app module updates -- module/module.prop
- [ ] Consider generating silent.ogg in CI instead of committing the binary (needs ffmpeg in the workflow) -- scripts/build.sh, .github/workflows/build.yml
- [ ] Add more known shutter/screenshot sound filenames if device testing finds others -- module/customize.sh
- [ ] Document the find-based diagnostic one-liner in the README so users can report missing sound paths -- README.md
- [ ] Confirm KernelSU and APatch install paths behave identically to Magisk once a device is available -- module/customize.sh
