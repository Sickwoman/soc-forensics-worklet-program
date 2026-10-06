#!/usr/bin/env bash
# Lab-grade device posture check, run on the client device before it is onboarded.
# It emits a JSON attestation and exits non-zero if any required check fails, so
# provision-peer.sh can refuse a device that is not in a safe state.
#
# The three checks below are stubs read from the environment so the lab can turn
# them on and off. On a real endpoint, replace each stub with a genuine probe,
# noted beside it, and feed the result from an MDM or posture agent. This is a
# teaching model of posture, not a commercial one.
#
# Usage: posture-check.sh <device_id>
set -euo pipefail
device_id="${1:?usage: posture-check.sh <device_id>}"

# A single switch to fail everything, used in the demo to show a rejected device.
fail_all="${ZT_POSTURE_FAIL:-no}"

check() {
    # check <name> <env-var> <default>  -> echoes pass/fail
    local val="${!2:-$3}"
    [ "$fail_all" = yes ] && val=no
    [ "$val" = yes ] && echo pass || echo fail
}

# disk_encryption: real probe would be `cryptsetup status` or `fscryptctl`
disk=$(check disk_encryption ZT_DISK_ENCRYPTION yes)
# firewall_on: real probe would be `ufw status` or `nft list ruleset`
fw=$(check firewall_on ZT_FIREWALL_ON yes)
# os_patched: real probe would compare patch age against a threshold
patched=$(check os_patched ZT_OS_PATCHED yes)

result=pass
for v in "$disk" "$fw" "$patched"; do
    [ "$v" = fail ] && result=fail
done

cat <<JSON
{"device_id":"$device_id","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","checks":{"disk_encryption":"$disk","firewall_on":"$fw","os_patched":"$patched"},"result":"$result"}
JSON

[ "$result" = pass ]
