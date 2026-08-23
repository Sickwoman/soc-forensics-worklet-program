#!/usr/bin/env bash
# Usage: bash verify-image-integrity.sh path-to-image-file
set -euo pipefail
IMG="$1"
echo "SHA-256 hash:"
sha256sum "$IMG"
echo "MD5 hash:"
md5sum "$IMG"
echo "Save both hashes into docs/forensic-integrity-log-template.md"
