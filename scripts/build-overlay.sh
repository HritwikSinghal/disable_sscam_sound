#!/usr/bin/env bash
# Rebuild the headphone-warning RRO overlay APK from overlay/ and drop it into
# module/system/product/overlay/NoSafeMediaVolume/. The resulting APK is
# committed (like silent.ogg), so CI and build.sh never need the Android SDK;
# run this only when overlay/ changes.
#
# Usage: scripts/build-overlay.sh
# Env:
#   ANDROID_JAR  android.jar from an SDK platform, or a device's framework-res.apk
#                (adb pull /system/framework/framework-res.apk). Required.
#   KEYSTORE     signing keystore (default: overlay/keystore.jks, gitignored).
#                Keep reusing the same key across releases.
#   KS_PASS      keystore password (default: android)
# Needs: aapt2, zipalign, apksigner (Android build-tools).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/overlay"
OUT="$ROOT/module/system/product/overlay/NoSafeMediaVolume/NoSafeMediaVolumeOverlay.apk"
KEYSTORE="${KEYSTORE:-$SRC/keystore.jks}"
KS_PASS="${KS_PASS:-android}"

[ -n "${ANDROID_JAR:-}" ] && [ -f "$ANDROID_JAR" ] || { echo "ERROR: set ANDROID_JAR to android.jar or framework-res.apk" >&2; exit 1; }
[ -f "$KEYSTORE" ] || { echo "ERROR: keystore not found: $KEYSTORE" >&2; exit 1; }
for t in aapt2 zipalign apksigner; do
  command -v "$t" >/dev/null || { echo "ERROR: $t not in PATH" >&2; exit 1; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

aapt2 compile --dir "$SRC/res" -o "$TMP/res.zip"
aapt2 link -I "$ANDROID_JAR" --manifest "$SRC/AndroidManifest.xml" \
  --no-resource-removal -o "$TMP/unsigned.apk" "$TMP/res.zip"
zipalign -f -p 4 "$TMP/unsigned.apk" "$TMP/aligned.apk"
apksigner sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" --out "$TMP/signed.apk" "$TMP/aligned.apk"
apksigner verify "$TMP/signed.apk"

mkdir -p "$(dirname "$OUT")"
cp "$TMP/signed.apk" "$OUT"
echo "Built: $OUT"
aapt2 dump resources "$OUT" | grep -A1 'bool/'
