#!/system/bin/sh
# post-fs-data.sh - runs on every boot, before zygote/system_server start.
#
# Silences each camera/screenshot UI sound that exists on the device using TWO
# layers, because no single one covers every root setup:
#
#   1) mount --bind silent.ogg over the live file. Works on Magisk and on
#      KernelSU/APatch setups that do NOT hide modules from apps.
#
#   2) susfs add_open_redirect (when the susfs CLI + kernel feature are present).
#      On KernelSU with module hiding (KernelSU "umount modules" and/or susfs
#      auto_try_umount), the bind/overlay is UNMOUNTED from non-root apps such as
#      SystemUI, so the sound keeps playing even though root shells see the
#      silent clip. open_redirect redirects the file OPEN at the kernel level,
#      independent of mounts, so it survives the umount. It MUST run before the
#      sound is first opened/decoded (system_server/SystemUI preload a SoundPool
#      sample at boot and hold it), which is why this lives in post-fs-data.
#      See the "Why it may still play" section in the README.
#
# We always do (1) and add (2) when available.
MODDIR=${0%/*}
. "$MODDIR/sound_paths.sh"
SILENT="$MODDIR/silent.ogg"

# Never bind/redirect an empty source: a 0-byte ogg crashes SystemUI / breaks
# screenshots on Android 13+ (the original module's failure mode).
[ -s "$SILENT" ] || exit 0

# Give the clip a context every reader can use. The UI sound files are part of
# the system image (u:object_r:system_file:s0), broadly readable; without this
# the source keeps its /data/adb context and the open could be denied.
chcon u:object_r:system_file:s0 "$SILENT" 2>/dev/null

# Locate the susfs CLI if this is a susfs-patched KernelSU.
SUSFS_BIN=""
for b in /data/adb/ksu/bin/ksu_susfs /data/adb/modules/susfs4ksu/bin/ksu_susfs \
         /data/adb/ksu/bin/susfs /system/bin/ksu_susfs; do
  [ -x "$b" ] && { SUSFS_BIN="$b"; break; }
done

# open_redirect uid schemes (3rd arg, REQUIRED): 0=non-app uid<10000,
# 2=all non-su procs, 4=umounted incl init-spawned. SystemUI/system_server that
# play the sound are non-su (covered by 2); 0 and 4 add belt-and-suspenders for
# system (uid 1000) and umounted processes.
SCHEMES="2 0 4"

for d in $SSCAM_DIRS; do
  [ -d "$d" ] || continue
  for s in $SSCAM_SOUNDS; do
    t="$d/$s"
    [ -f "$t" ] || continue
    # Layer 1: bind mount (visible to root + non-hiding setups).
    mount --bind "$SILENT" "$t" 2>/dev/null
    # Layer 2: kernel-level open redirect (survives module-hiding umount).
    if [ -n "$SUSFS_BIN" ]; then
      for sc in $SCHEMES; do
        "$SUSFS_BIN" add_open_redirect "$t" "$SILENT" "$sc" >/dev/null 2>&1
      done
    fi
  done
done
