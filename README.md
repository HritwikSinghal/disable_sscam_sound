# Pixel Sound Expert

Magisk / KernelSU / APatch module for Google Pixel that:

- silences the camera shutter and screenshot sound
- disables the headphone "high volume" warning and its automatic volume lowering

Systemless: remove the module and reboot to restore stock behavior.
Verified on Pixel 10a, Android 17.

> Silencing the shutter is illegal in some countries (e.g. Japan, South Korea).
> Use only where lawful.

## Install

1. Download the zip from [Releases](https://github.com/HritwikSinghal/pixel-sound-expert/releases).
2. Root manager -> Modules -> Install from storage -> select the zip.
3. Reboot.

Later updates install from inside the root manager. Upgrading from the old
`silence-shutter-screenshot` module removes it automatically.

| Manager | Shutter / screenshot | Headphone warning |
|---|---|---|
| Magisk 20.4+ | yes | yes |
| KernelSU(-Next) | yes, see below if hiding modules | needs a metamodule (e.g. Hybrid Mount) |
| APatch | untested | untested |

## KernelSU with module hiding

With "Umount modules" or susfs `auto_try_umount` on, System UI never sees the
module and the shutter still clicks. Fix once:
KernelSU app -> app list (show system apps) -> **System UI** -> turn off
**Umount modules** -> reboot. Other apps stay hidden.

## Troubleshooting

```
su -c 'ls -l /product/media/audio/ui/camera_click.ogg'      # ~3.6 KB = silenced
dumpsys audio | grep -E 'mEnableCsd|mSafeMediaVolumeState'  # false / DISABLED
```

Still hearing a sound? Open an issue with the installer output and:

```
su -c 'find /system /product /system_ext /vendor /odm -name "*.ogg" | grep -iE "camera|shutter|screen"'
```

## Development

```
bash scripts/validate.sh && bash scripts/build.sh   # -> dist/pixel-sound-expert-<version>.zip
```

Release: bump `version` + `versionCode` in `module/module.prop`, add a
`CHANGELOG.md` entry, push tag `v<version>`.
Internals: [docs/architecture.md](docs/architecture.md).

## License

[GPL-3.0](LICENSE)
