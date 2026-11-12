#!/usr/bin/env bash
# Read-only Oracle RAC / Clusterware health snapshot.
# Run as the Grid Infrastructure owner with the GI environment configured.
# Review command availability and paths for your platform/release.

set -u

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }

echo "===== RAC HEALTH SNAPSHOT: $(timestamp) ====="
echo
echo "===== HOST ====="
hostname
hostname -f 2>/dev/null || true
uname -a

echo
echo "===== CLUSTER NODES ====="
if command -v olsnodes >/dev/null 2>&1; then
  olsnodes -n -s
else
  echo "olsnodes not found; configure the Grid Infrastructure environment."
fi

echo
echo "===== CRS CHECK ====="
if command -v crsctl >/dev/null 2>&1; then
  crsctl check crs 2>&1 || true
  crsctl check cluster -all 2>&1 || true
  echo
  echo "===== RESOURCE SUMMARY ====="
  crsctl stat res -t 2>&1 || true
else
  echo "crsctl not found; configure the Grid Infrastructure environment."
fi

echo
echo "===== OCR CHECK ====="
if command -v ocrcheck >/dev/null 2>&1; then
  ocrcheck 2>&1 || true
else
  echo "ocrcheck not found."
fi

echo
echo "===== VOTING DISKS ====="
if command -v crsctl >/dev/null 2>&1; then
  crsctl query css votedisk 2>&1 || true
fi

echo
echo "===== FILESYSTEM SUMMARY ====="
df -h 2>&1

echo
echo "===== END: $(timestamp) ====="
