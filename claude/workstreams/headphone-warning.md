---
name: headphone-warning
description: Headphone high-volume warning / sound dose (CSD) / safe media volume disabled via RRO overlay (NoSafeMediaVolume), Hybrid Mount metamodule on KernelSU
status: done
---

# Headphone volume warning (v2.4)

Shipped in v2.4, verified on Pixel 10a with KernelSU 3.4 + Hybrid Mount 6.2.2:
overlay `[x]`, `mEnableCsd=false`, `SAFE_MEDIA_VOLUME_DISABLED`.

Mechanism and constraints (targetSdk < 29, must live on /product, FRRO does not
survive boot, metamodule needed on KernelSU): docs/architecture.md
"Headphone volume warning".

Untested: Magisk, APatch.
