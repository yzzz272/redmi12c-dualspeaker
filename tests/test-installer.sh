#!/usr/bin/env bash
#
# Installer guard tests for module/customize.sh.
#
# These tests never touch a real device: no root, no /vendor, no network.
# customize.sh is sourced from a temporary copy whose ONLY change is the
# VENDOR_XML path assignment, which is redirected to a fixture file. The
# production script is never modified to make the guard bypassable.
#
# Every fixture lives under one `mktemp -d` directory that is removed on exit.
# Requires bash and sha256sum (Git Bash on Windows works).

set -u

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
customize_src="$repo_root/module/customize.sh"
baseline_xml="$repo_root/config/stock/audio_device.xml"
module_xml="$repo_root/module/system/vendor/etc/audio_device.xml"

for required in "$customize_src" "$baseline_xml" "$module_xml"; do
    if [ ! -f "$required" ]; then
        printf 'missing required file: %s\n' "$required" >&2
        exit 1
    fi
done
if ! command -v sha256sum >/dev/null 2>&1; then
    printf 'sha256sum is required\n' >&2
    exit 1
fi

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/earth-guard.XXXXXX") || {
    printf 'mktemp -d failed\n' >&2
    exit 1
}
cleanup() { rm -rf -- "$tmp_root"; }
trap cleanup EXIT HUP INT TERM

customize_hash_before=$(sha256sum "$customize_src")

# --------------------------------------------------------------- fixtures ---

# Replace the single VENDOR_XML assignment with a fixture path, and prove that
# it is the only difference from the production script.
render_customize() {
    local vendor_path=$1 out=$2 escaped changed
    escaped=${vendor_path//\\/\\\\}
    escaped=${escaped//&/\\&}
    escaped=${escaped//|/\\|}
    sed "s|^VENDOR_XML=\"/vendor/etc/audio_device.xml\"\$|VENDOR_XML=\"$escaped\"|" \
        "$customize_src" >"$out" || return 1
    changed=$(diff "$customize_src" "$out" | grep -c '^[<>]')
    if [ "$changed" -ne 2 ]; then
        printf 'harness error: expected exactly one changed line, got %s\n' "$changed" >&2
        return 1
    fi
    if grep -q '^VENDOR_XML="/vendor/etc/audio_device.xml"$' "$out"; then
        printf 'harness error: VENDOR_XML redirect was not applied\n' >&2
        return 1
    fi
}

CASE_DIR=''
begin_case() {
    CASE_DIR=$(mktemp -d "$tmp_root/case.XXXXXX") || {
        printf 'mktemp -d failed\n' >&2
        exit 1
    }
    mkdir -p "$CASE_DIR/module/system/vendor/etc" "$CASE_DIR/vendor"
    cp -- "$module_xml" "$CASE_DIR/module/system/vendor/etc/audio_device.xml"
    cp -- "$baseline_xml" "$CASE_DIR/vendor/audio_device.xml"
    render_customize "$CASE_DIR/vendor/audio_device.xml" "$CASE_DIR/customize.sh" || exit 1
}

# ------------------------------------------------------------------ stubs ---
# Minimal stand-ins for the Magisk installer helpers that customize.sh uses.
# set_perm only records its arguments; it never chmods anything.

ui_print() { printf '%s\n' "$*" >>"$CASE_DIR/ui_print.log"; }
abort() { printf '%s\n' "$*" >>"$CASE_DIR/abort.log"; exit 1; }
set_perm() { printf '%s\n' "$*" >>"$CASE_DIR/set_perm.log"; }
getprop() {
    case ${1-} in
        ro.product.device) printf '%s\n' "${TEST_DEVICE-}" ;;
        ro.lineage.version) printf '%s\n' "${TEST_LINEAGE-}" ;;
        *) printf '\n' ;;
    esac
}
uname() { printf '%s\n' "${TEST_KERNEL-}"; }

# ---------------------------------------------------------------- harness ---

pass_count=0
fail_count=0

GOOD_DEVICE='earth'
GOOD_API='34'
GOOD_LINEAGE='21.0-20240509-UNOFFICIAL-earth'
GOOD_KERNEL='4.19.306-perf-07808-ge1d7983c7a49'

reset_env() {
    TEST_DEVICE=$GOOD_DEVICE
    TEST_API=$GOOD_API
    TEST_LINEAGE=$GOOD_LINEAGE
    TEST_KERNEL=$GOOD_KERNEL
}

# run_case <name> <pass|fail>
run_case() {
    local name=$1 expect=$2 status=0 ok=1 reason='' vendor_before vendor_after

    vendor_before=$(sha256sum "$CASE_DIR/vendor/audio_device.xml")

    (
        MODPATH="$CASE_DIR/module"
        API=$TEST_API
        source "$CASE_DIR/customize.sh"
    ) >"$CASE_DIR/stdout.log" 2>&1 || status=$?

    vendor_after=$(sha256sum "$CASE_DIR/vendor/audio_device.xml")
    if [ "$vendor_before" != "$vendor_after" ]; then
        ok=0
        reason='the vendor fixture was modified'
    fi

    if [ "$expect" = 'pass' ]; then
        if [ "$status" -ne 0 ]; then
            ok=0
            reason="exit status $status, expected 0"
        elif [ -s "$CASE_DIR/abort.log" ]; then
            ok=0
            reason="abort was called: $(head -n 1 "$CASE_DIR/abort.log")"
        elif [ "$(wc -l <"$CASE_DIR/set_perm.log" 2>/dev/null || printf '0')" -ne 1 ]; then
            ok=0
            reason='set_perm was not called exactly once'
        else
            local expected_perm="$CASE_DIR/module/system/vendor/etc/audio_device.xml 0 0 0644 u:object_r:vendor_configs_file:s0"
            if [ "$(cat "$CASE_DIR/set_perm.log")" != "$expected_perm" ]; then
                ok=0
                reason="unexpected set_perm arguments: $(cat "$CASE_DIR/set_perm.log")"
            fi
        fi
    else
        if [ "$status" -eq 0 ]; then
            ok=0
            reason='exit status 0, expected the installer to abort'
        elif [ ! -s "$CASE_DIR/abort.log" ]; then
            ok=0
            reason='the installer failed without calling abort'
        elif [ -s "$CASE_DIR/set_perm.log" ]; then
            ok=0
            reason='set_perm was called even though the install was rejected'
        fi
    fi

    if [ "$ok" -eq 1 ]; then
        pass_count=$((pass_count + 1))
        printf 'ok   %s\n' "$name"
    else
        fail_count=$((fail_count + 1))
        printf 'FAIL %s: %s\n' "$name" "$reason"
        sed 's/^/       /' "$CASE_DIR/stdout.log" | tail -n 5
    fi
    return 0
}

# ------------------------------------------------------------------ cases ---

reset_env
begin_case
run_case 'stock baseline vendor config passes' pass

reset_env
begin_case
cp -- "$module_xml" "$CASE_DIR/vendor/audio_device.xml"
run_case 'same-version reinstall (patched vendor config) passes' pass

reset_env
TEST_DEVICE='earthx'
begin_case
run_case 'wrong device is rejected' fail

reset_env
TEST_API='33'
begin_case
run_case 'wrong Android API level is rejected' fail

reset_env
TEST_LINEAGE='21.0-20250101-UNOFFICIAL-earth'
begin_case
run_case 'wrong LineageOS build is rejected' fail

reset_env
TEST_KERNEL='4.19.306-perf-00000-gdeadbeef'
begin_case
run_case 'wrong kernel is rejected' fail

reset_env
begin_case
printf '\n<!-- tampered vendor fixture -->\n' >>"$CASE_DIR/vendor/audio_device.xml"
run_case 'unknown vendor config hash is rejected' fail

reset_env
begin_case
printf '\n' >>"$CASE_DIR/module/system/vendor/etc/audio_device.xml"
run_case 'tampered packaged overlay is rejected' fail

reset_env
begin_case
rm -f "$CASE_DIR/module/system/vendor/etc/audio_device.xml"
run_case 'missing packaged overlay is rejected' fail

# ----------------------------------------------------------------- summary ---

if [ "$(sha256sum "$customize_src")" != "$customize_hash_before" ]; then
    printf 'FAIL module/customize.sh was modified by the test run\n'
    fail_count=$((fail_count + 1))
fi

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
if [ "$fail_count" -ne 0 ]; then
    exit 1
fi
