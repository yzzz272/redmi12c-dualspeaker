# Provenance

Everything redistributed inside `dist/earth-dual-speaker-v0.1.0-experimental.zip`
that is not authored here is listed below with its exact upstream origin, hash and
license evidence.

The ZIP has 9 entries:

| ZIP entry | Origin |
| --- | --- |
| `customize.sh`, `module.prop` | authored here (GPL-3.0) |
| `META-INF/com/google/android/updater-script` | authored here, contains only `#MAGISK` |
| `META-INF/com/google/android/update-binary` | Magisk upstream, unmodified |
| `META-INF/com/google/android/update-binary.LICENSE-GPL-3.0.txt` | Magisk upstream `LICENSE`, unmodified |
| `META-INF/com/google/android/update-binary.NOTICE.txt` | authored here (`provenance/NOTICE-module_installer.txt`) |
| `META-INF/com/google/android/audio_device.xml.LICENSE-Apache-2.0.txt` | Apache License 2.0 text, unmodified |
| `META-INF/com/google/android/audio_device.xml.NOTICE.txt` | authored here (`provenance/NOTICE-audio_device_xml.txt`) |
| `system/vendor/etc/audio_device.xml` | LineageOS device-tree XML, modified (4 appended `kctl` lines) |

## Magisk module installer (`update-binary`)

| Field | Value |
| --- | --- |
| Upstream project | Magisk (topjohnwu/Magisk) |
| Upstream URL | https://github.com/topjohnwu/Magisk |
| Pinned ref | tag `v31.1` |
| Pinned commit | `0972f67d97f9b6302b67c5171283330c74114b4a` |
| Upstream path | `scripts/module_installer.sh` |
| Raw URL | https://raw.githubusercontent.com/topjohnwu/Magisk/0972f67d97f9b6302b67c5171283330c74114b4a/scripts/module_installer.sh |
| SHA256 | `bcf4b1d9913f3af17755569c853e0b5a75b8005f6a18eb3f86dadcc0e968c29d` |
| Local copy | `provenance/upstream/module_installer.sh` (byte-identical, unmodified) |
| ZIP entry | `META-INF/com/google/android/update-binary` |
| License | GNU General Public License v3.0 |

The pinned tag matches the Magisk running on the target device
(`31.1:MAGISKSU`, version code `31100`).

## Magisk license text

| Field | Value |
| --- | --- |
| Upstream path | `LICENSE` |
| Raw URL | https://raw.githubusercontent.com/topjohnwu/Magisk/0972f67d97f9b6302b67c5171283330c74114b4a/LICENSE |
| SHA256 | `589ed823e9a84c56feb95ac58e7cf384626b9cbf4fda2a907bc36e103de1bad2` |
| Local copy | `provenance/upstream/LICENSE-GPL-3.0.txt` (byte-identical, unmodified) |
| ZIP entry | `META-INF/com/google/android/update-binary.LICENSE-GPL-3.0.txt` |

The GPL-3.0 text ships inside the ZIP next to the redistributed installer script,
together with `provenance/NOTICE-module_installer.txt`
(ZIP entry `META-INF/com/google/android/update-binary.NOTICE.txt`).

## Audio config baseline (`config/stock/audio_device.xml`)

The public build input is a byte-identical copy of the upstream device-tree file.

| Field | Value |
| --- | --- |
| Upstream repository | https://github.com/LineageOS/android_device_xiaomi_earth |
| Pinned commit | `87007ad3e1ada83423abe0d560809b9a1c8ffda9` ("earth: Configure Audio stack", 2024-03-28) |
| Upstream path | `configs/audio/audio_device.xml` |
| Raw URL | https://raw.githubusercontent.com/LineageOS/android_device_xiaomi_earth/87007ad3e1ada83423abe0d560809b9a1c8ffda9/configs/audio/audio_device.xml |
| Git blob | `0601191b039b0a31fadea6700d84b2c412e0f1c1` |
| Size | 35521 bytes |
| SHA256 | `0d173c2bf7db1b8669926f23135596114f243458697c5dbfc2fa4572a88b56ba` |
| Local copy | `config/stock/audio_device.xml` (byte-identical, unmodified) |
| Device copy | `/vendor/etc/audio_device.xml` on the target Redmi 12C (`earth`), same SHA256 |

### License evidence

- The upstream device-tree repository has **no** `LICENSE`, `COPYING` or `NOTICE`
  file, and the GitHub API reports its license as `null`.
- Its LineageOS 21 `README.md` (HEAD `20fda9b252de46ed4a08a3d66ccfbb92178a8def`)
  declares:

  ```
  Copyright (C) 2023 The LineageOS Project
  SPDX-License-Identifier: Apache-2.0
  ```

- `configs/audio/audio_device.xml` itself carries **no** per-file copyright or
  license header.

So the license is Apache-2.0 **as declared by the device-tree README**; the XML
file does not itself carry an SPDX identifier. This project is not an official
LineageOS release and is not endorsed by the LineageOS project. The root
`LICENSE` (GPL-3.0) does not cover this file.

Apache License 2.0 text:

| Field | Value |
| --- | --- |
| Official URL | https://www.apache.org/licenses/LICENSE-2.0.txt |
| SHA256 | `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30` |
| Local copy | `provenance/upstream/LICENSE-APACHE-2.0.txt` (byte-identical, unmodified) |
| ZIP entry | `META-INF/com/google/android/audio_device.xml.LICENSE-Apache-2.0.txt` |

### Modification notice

`provenance/NOTICE-audio_device_xml.txt` (ZIP entry
`META-INF/com/google/android/audio_device.xml.NOTICE.txt`) records the upstream
commit, the upstream and modified SHA256 values, and the only change made:

- `speaker_output/turnon` gains `Handset_PGA_GAIN=4Db` and `RCV Mux=Voice Playback`.
- `speaker_output/turnoff` gains `RCV Mux=Open` and `Handset_PGA_GAIN=8Db`.

Exactly four lines are appended; every other byte of the XML is preserved,
including the XML declaration.

`module/system/vendor/etc/audio_device.xml` (SHA256
`11334e073a7d35b0151f6d4b912caa07544b320b3a4a637b8e5be6d90b06e50c`) is generated
from the baseline by `build-module.ps1`, which fails if the baseline hash, the
generated hash, the semantic diff or the byte-level revert check does not match.

## Magisk module guide (read, not redistributed)

| Field | Value |
| --- | --- |
| URL | https://topjohnwu.github.io/Magisk/guides.html |
| Source | `docs/guides.md` at commit `0972f67d97f9b6302b67c5171283330c74114b4a` |
| SHA256 | `4b267c7b3055904198092877ddf70ccfdfca19dc8afe4b1b8ae822fbf0c04f3c` |

Used for the module layout (`module.prop` strict format, `customize.sh` contract,
`META-INF/com/google/android/updater-script` containing only `#MAGISK`).

## Not redistributed

Local research material is excluded from this repository by `.gitignore`:
raw device dumps, mixer/policy captures, kernel sources used for reading, and the
one-shot probe script. Only the technical baseline XML above is published.

## Build environment

`build-module.ps1` runs on PowerShell 7 and uses only .NET/BCL APIs
(`System.Xml`, `System.IO.Compression`). No third-party packer or re-packed
installer is used.
