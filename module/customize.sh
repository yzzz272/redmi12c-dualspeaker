#!/system/bin/sh
#
# earth_dual_speaker - customize.sh
#
# Sourced by Magisk's module_installer.sh after the module files are extracted
# into $MODPATH. Never call exit here: use abort so the installer can clean up.
#
# This module only ships a systemless overlay of /vendor/etc/audio_device.xml.
# It never writes the real vendor file, the installer itself never writes the
# mixer (the HAL applies the configured gains when it routes to speaker_output),
# and it installs no boot script.

BASELINE_SHA256="0d173c2bf7db1b8669926f23135596114f243458697c5dbfc2fa4572a88b56ba"
PATCHED_SHA256="11334e073a7d35b0151f6d4b912caa07544b320b3a4a637b8e5be6d90b06e50c"

EXPECTED_DEVICE="earth"
EXPECTED_API="34"
EXPECTED_LINEAGE_VERSION="21.0-20240509-UNOFFICIAL-earth"
EXPECTED_KERNEL_TAG="e1d7983c7a49"

VENDOR_XML="/vendor/etc/audio_device.xml"
MODULE_XML="$MODPATH/system/vendor/etc/audio_device.xml"

ui_print "*******************************"
ui_print " earth_dual_speaker v0.1.0-experimental"
ui_print " EXPERIMENTAL: receiver gain set to +4dB (Handset_PGA_GAIN=4Db)"
ui_print "*******************************"

ui_print "- Checking device, Android version, build and kernel"

[ "$(getprop ro.product.device)" = "$EXPECTED_DEVICE" ] || \
    abort "! Unsupported device: '$(getprop ro.product.device)' (expected '$EXPECTED_DEVICE')"

[ "$API" = "$EXPECTED_API" ] || \
    abort "! Unsupported Android API level: '$API' (expected '$EXPECTED_API' = Android 14)"

[ "$(getprop ro.lineage.version)" = "$EXPECTED_LINEAGE_VERSION" ] || \
    abort "! Unsupported build: '$(getprop ro.lineage.version)' (expected '$EXPECTED_LINEAGE_VERSION')"

case "$(uname -r)" in
    *"$EXPECTED_KERNEL_TAG"*)
        ui_print "- Kernel: $(uname -r)"
        ;;
    *)
        abort "! Unsupported kernel: '$(uname -r)' (expected a kernel containing '$EXPECTED_KERNEL_TAG')"
        ;;
esac

ui_print "- Checking $VENDOR_XML"

command -v sha256sum >/dev/null 2>&1 || abort "! sha256sum is not available in the installer shell"
[ -f "$VENDOR_XML" ] || abort "! Missing $VENDOR_XML"

CURRENT_SHA256=$(sha256sum "$VENDOR_XML")
CURRENT_SHA256=${CURRENT_SHA256%% *}

case "$CURRENT_SHA256" in
    "$BASELINE_SHA256")
        ui_print "- Vendor config matches the stock baseline"
        ;;
    "$PATCHED_SHA256")
        ui_print "- Vendor config already matches this module (same-version reinstall)"
        ;;
    *)
        abort "! $VENDOR_XML checksum mismatch: $CURRENT_SHA256 (expected $BASELINE_SHA256 or $PATCHED_SHA256)"
        ;;
esac

[ -f "$MODULE_XML" ] || abort "! Packaged overlay is missing: $MODULE_XML"

PACKAGED_SHA256=$(sha256sum "$MODULE_XML")
PACKAGED_SHA256=${PACKAGED_SHA256%% *}

[ "$PACKAGED_SHA256" = "$PATCHED_SHA256" ] || \
    abort "! Packaged overlay checksum mismatch: $PACKAGED_SHA256 (expected $PATCHED_SHA256)"

set_perm "$MODULE_XML" 0 0 0644 u:object_r:vendor_configs_file:s0

ui_print "- Overlay prepared: $VENDOR_XML will be replaced systemlessly after reboot"
ui_print "  the on-disk file is untouched"
ui_print ""
ui_print "EXPERIMENTAL - NOT SAFETY RATED"
ui_print "- Tested: one short trial at media volume 3/15, receiver audible at +4dB"
ui_print "- NOT tested: max volume, long-term hardware safety, calls, bluetooth, headphones, reboot behaviour"
ui_print "- Scope: the patch follows HAL speaker_output, so media, ringtone and speakerphone"
ui_print "  enable the receiver when they select that path; specific combinations are UNTESTED"
ui_print "- Normal call and headphone paths are textually unchanged, but their behaviour is UNTESTED"
ui_print "  and not guaranteed to be unaffected"
ui_print "- These checks only run at install time; nothing validates compatibility at boot"
ui_print "- Roll back by disabling or removing this module and rebooting"
ui_print "- Do that BEFORE any ROM, OTA or kernel change"
ui_print "- No boot script, no automatic reboot; the installer never writes the mixer,"
ui_print "  the HAL applies these configured gains during routing"
