# Progress -- Pixel Sound Expert

> Last updated: 2026-10-23

Module silences the Pixel camera shutter / screenshot sound and disables the
headphone volume warning. Current release: v2.5 (rename from
disable_sscam_sound / silence-shutter-screenshot, GPL-3.0, CI lint + release
gate). Both features are verified on Pixel 10a (Android 17, KernelSU + susfs +
Hybrid Mount); see docs/architecture.md.

Now: waiting on the user's on-device install of v2.5 over v2.4 to confirm the
old module id is removed (workstreams/release-pipeline.md).

Next: optional backlog only -- see todo.md. Nothing blocks.

Workstreams:
- shutter-silencing -- done; research backlog on module hiding
- headphone-warning -- done
- release-pipeline -- active (v2.5 upgrade confirmation)
