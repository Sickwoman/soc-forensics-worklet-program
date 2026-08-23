#!/usr/bin/env bash
# Usage: bash volatility-analysis.sh path-to-memory-dump
set -euo pipefail
DUMP="$1"

echo "Hashing dump for chain of custody"
sha256sum "$DUMP"

echo "Identifying OS profile"
vol3 -f "$DUMP" windows.info || vol3 -f "$DUMP" linux.info

echo "Listing process tree"
vol3 -f "$DUMP" windows.pstree || vol3 -f "$DUMP" linux.pstree

echo "Scanning for hidden processes"
vol3 -f "$DUMP" windows.psscan || vol3 -f "$DUMP" linux.pslist

echo "Extracting command line history"
vol3 -f "$DUMP" windows.cmdline || vol3 -f "$DUMP" linux.bash

echo "Listing network connections at time of capture"
vol3 -f "$DUMP" windows.netscan || vol3 -f "$DUMP" linux.netstat
