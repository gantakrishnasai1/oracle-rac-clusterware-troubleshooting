
#!/bin/bash
#
# Script Name : rac_health_snapshot.sh
# Description : Oracle RAC and Grid Infrastructure health snapshot.
# Platform    : Oracle Linux 8 / Linux
# Execution   : Run as Grid Infrastructure owner (grid).
# Access      : Read-only diagnostic commands.
#
# Usage:
#   ./rac_health_snapshot.sh
#   ./rac_health_snapshot.sh /path/to/output
#
# Note:
#   ASM checks are optional and require ASM access.
#

# --------------------------------------------------
# Configuration
# --------------------------------------------------

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
HOSTNAME_VALUE=$(hostname -f 2>/dev/null || hostname)

OUTPUT_DIR="${1:-./rac_health_reports}"
REPORT_FILE="${OUTPUT_DIR}/rac_health_${HOSTNAME_VALUE}_${TIMESTAMP}.log"

PASS_COUNT=0
FAIL_COUNT=0
WARNING_COUNT=0
SKIP_COUNT=0

# --------------------------------------------------
# Initialize
# --------------------------------------------------

if ! mkdir -p "$OUTPUT_DIR"; then
    echo "ERROR: Unable to create output directory: $OUTPUT_DIR"
    exit 1
fi

# Redirect all output to both terminal and report file.
exec > >(tee -a "$REPORT_FILE") 2>&1

# --------------------------------------------------
# Report functions
# --------------------------------------------------

print_header() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

run_check() {
    LABEL="$1"
    shift

    echo
    echo "------------------------------------------------------------"
    echo "CHECK: $LABEL"
    echo "COMMAND: $*"
    echo "------------------------------------------------------------"

    "$@"
    RC=$?

    if [ "$RC" -eq 0 ]; then
        echo "[PASS] $LABEL"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "[FAIL] $LABEL (Exit Code: $RC)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

run_optional_check() {
    LABEL="$1"
    shift

    echo
    echo "------------------------------------------------------------"
    echo "OPTIONAL CHECK: $LABEL"
    echo "COMMAND: $*"
    echo "------------------------------------------------------------"

    "$@"
    RC=$?

    if [ "$RC" -eq 0 ]; then
        echo "[PASS] $LABEL"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "[WARNING] $LABEL (Exit Code: $RC)"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
}

skip_check() {
    echo "[SKIP] $1"
    SKIP_COUNT=$((SKIP_COUNT + 1))
}

# --------------------------------------------------
# Report start
# --------------------------------------------------

print_header "ORACLE RAC HEALTH SNAPSHOT"

echo "Hostname       : $HOSTNAME_VALUE"
echo "Execution Time : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Executed User  : $(id -un)"
echo "Report File    : $REPORT_FILE"

# --------------------------------------------------
# Host information
# --------------------------------------------------

print_header "1. HOST INFORMATION"

run_check "Hostname" hostname
run_check "Operating System" uname -a
run_check "System uptime" uptime

# --------------------------------------------------
# Network information
# --------------------------------------------------

print_header "2. NETWORK INFORMATION"

if command -v ip >/dev/null 2>&1; then
    run_check "Network interfaces" ip addr show
    run_check "Network routing" ip route show
else
    skip_check "ip command is unavailable"
fi

# --------------------------------------------------
# Clusterware checks
# --------------------------------------------------

print_header "3. CLUSTERWARE HEALTH CHECKS"

if command -v crsctl >/dev/null 2>&1; then

    run_check "Local Clusterware status" crsctl check crs

    run_check "Cluster-wide status" crsctl check cluster -all

    run_check "Cluster resource status" crsctl stat res -t

else
    skip_check "crsctl command unavailable. Check Grid environment."
fi

# --------------------------------------------------
# RAC node membership
# --------------------------------------------------

print_header "4. RAC NODE MEMBERSHIP"

if command -v olsnodes >/dev/null 2>&1; then
    run_check "RAC node membership" olsnodes -n -s
else
    skip_check "olsnodes command unavailable"
fi

# --------------------------------------------------
# OCR checks
# --------------------------------------------------

print_header "5. OCR HEALTH CHECKS"

if command -v ocrcheck >/dev/null 2>&1; then
    run_check "OCR integrity" ocrcheck
else
    skip_check "ocrcheck command unavailable"
fi

if command -v ocrconfig >/dev/null 2>&1; then
    run_optional_check "OCR backup information" ocrconfig -showbackup
else
    skip_check "ocrconfig command unavailable"
fi

# --------------------------------------------------
# Voting disk checks
# --------------------------------------------------

print_header "6. VOTING DISK CHECKS"

if command -v crsctl >/dev/null 2>&1; then
    run_check "Voting disk configuration" crsctl query css votedisk
else
    skip_check "crsctl command unavailable"
fi

# --------------------------------------------------
# ASM checks
# --------------------------------------------------

print_header "7. ASM HEALTH CHECKS"

if command -v asmcmd >/dev/null 2>&1; then

    run_optional_check "ASM disk group status" asmcmd lsdg

    run_optional_check "ASM disk status" asmcmd lsdsk -p

else
    skip_check "asmcmd unavailable or ASM environment not configured"
fi

# --------------------------------------------------
# Filesystem checks
# --------------------------------------------------

print_header "8. FILESYSTEM UTILIZATION"

if command -v df >/dev/null 2>&1; then
    run_check "Filesystem utilization" df -h
else
    skip_check "df command unavailable"
fi

# --------------------------------------------------
# Important process checks
# --------------------------------------------------

print_header "9. IMPORTANT PROCESSES"

if command -v ps >/dev/null 2>&1; then
    run_check "Oracle/Grid processes" ps -ef
else
    skip_check "ps command unavailable"
fi

# --------------------------------------------------
# Final summary
# --------------------------------------------------

print_header "10. HEALTH CHECK SUMMARY"

echo "Hostname       : $HOSTNAME_VALUE"
echo "Execution Time : $(date '+%Y-%m-%d %H:%M:%S')"
echo
echo "PASS           : $PASS_COUNT"
echo "FAIL           : $FAIL_COUNT"
echo "WARNING        : $WARNING_COUNT"
echo "SKIP           : $SKIP_COUNT"
echo

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "OVERALL STATUS : CHECK REQUIRED"
elif [ "$WARNING_COUNT" -gt 0 ]; then
    echo "OVERALL STATUS : REVIEW WARNINGS"
else
    echo "OVERALL STATUS : CHECKS COMPLETED"
fi

echo
echo "Report saved at: $REPORT_FILE"

print_header "END OF RAC HEALTH SNAPSHOT"

# A non-zero exit status indicates at least one failed mandatory check.
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi

exit 0
