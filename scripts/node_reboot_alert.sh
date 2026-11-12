
#!/bin/bash
#
# Script Name : node_reboot_alert.sh
# Description : Detect server reboot and send email notification.
# OS          : Oracle Linux 8 / Linux
# Detection   : Last 15 minutes
# Schedule    : Every 10 minutes using cron
#

set -u

# --------------------------------------------------
# Configuration
# --------------------------------------------------

LOOKBACK_MINUTES="${LOOKBACK_MINUTES:-15}"
MAIL_TO="${MAIL_TO:-dba-team@example.com}"

SCRIPT_DIR="/var/tmp/node_reboot_alert"
HOSTNAME_VALUE=$(hostname -f 2>/dev/null || hostname)

STATE_FILE="${SCRIPT_DIR}/last_notified_boot"
LOG_FILE="${SCRIPT_DIR}/node_reboot_alert.log"
LOCK_FILE="${SCRIPT_DIR}/node_reboot_alert.lock"

# --------------------------------------------------
# Initialize
# --------------------------------------------------

if ! mkdir -p "$SCRIPT_DIR"; then
    echo "ERROR: Unable to create $SCRIPT_DIR"
    exit 1
fi

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# --------------------------------------------------
# Prevent concurrent executions
# --------------------------------------------------

if ! command -v flock >/dev/null 2>&1; then
    log_message "ERROR: flock command not found."
    exit 1
fi

exec 200>"$LOCK_FILE"

if ! flock -n 200; then
    log_message "Another execution is already running."
    exit 0
fi

# --------------------------------------------------
# Validate configuration
# --------------------------------------------------

if ! [[ "$LOOKBACK_MINUTES" =~ ^[0-9]+$ ]] || \
   [ "$LOOKBACK_MINUTES" -le 0 ]; then
    log_message "ERROR: Invalid LOOKBACK_MINUTES."
    exit 1
fi

if [ -z "$MAIL_TO" ] || \
   [ "$MAIL_TO" = "dba-team@example.com" ]; then
    log_message "ERROR: Configure a valid MAIL_TO address."
    exit 1
fi

for cmd in uptime date mailx hostname; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_message "ERROR: Required command not found: $cmd"
        exit 1
    fi
done

# --------------------------------------------------
# Get system boot time
# --------------------------------------------------

BOOT_TIME=$(uptime -s 2>/dev/null)

if [ -z "$BOOT_TIME" ]; then
    log_message "ERROR: Unable to determine system boot time."
    exit 1
fi

BOOT_EPOCH=$(date -d "$BOOT_TIME" +%s 2>/dev/null)

if ! [[ "$BOOT_EPOCH" =~ ^[0-9]+$ ]]; then
    log_message "ERROR: Unable to convert boot time."
    exit 1
fi

CURRENT_EPOCH=$(date +%s)

# --------------------------------------------------
# Calculate elapsed time
# --------------------------------------------------

ELAPSED_SECONDS=$((CURRENT_EPOCH - BOOT_EPOCH))

if [ "$ELAPSED_SECONDS" -lt 0 ]; then
    log_message "ERROR: Boot time is in the future. Check system time."
    exit 1
fi

ELAPSED_MINUTES=$((ELAPSED_SECONDS / 60))

# --------------------------------------------------
# Check reboot detection window
# --------------------------------------------------

if [ "$ELAPSED_SECONDS" -gt "$((LOOKBACK_MINUTES * 60))" ]; then
    log_message "No reboot detected within the last ${LOOKBACK_MINUTES} minutes."
    exit 0
fi

# --------------------------------------------------
# Check duplicate notification
# --------------------------------------------------

LAST_NOTIFIED_BOOT=""

if [ -f "$STATE_FILE" ]; then
    LAST_NOTIFIED_BOOT=$(cat "$STATE_FILE")
fi

if [ "$LAST_NOTIFIED_BOOT" = "$BOOT_EPOCH" ]; then
    log_message "Alert already sent for boot time: $BOOT_TIME"
    exit 0
fi

# --------------------------------------------------
# Prepare email notification
# --------------------------------------------------

SUBJECT="ALERT: Server Reboot Detected - ${HOSTNAME_VALUE}"

BODY="
SERVER REBOOT ALERT

Hostname       : ${HOSTNAME_VALUE}
Boot Time      : ${BOOT_TIME}
Detection Time : $(date '+%Y-%m-%d %H:%M:%S')
Elapsed Time   : ${ELAPSED_MINUTES} minutes
Lookback       : ${LOOKBACK_MINUTES} minutes

Please investigate the server reboot event.

This is an automated notification.
"

# --------------------------------------------------
# Send email alert
# --------------------------------------------------

if printf '%s\n' "$BODY" | mailx -s "$SUBJECT" "$MAIL_TO"; then

    # Update state only after successful mail command
    if printf '%s\n' "$BOOT_EPOCH" > "${STATE_FILE}.tmp" && \
       mv "${STATE_FILE}.tmp" "$STATE_FILE"; then

        log_message "SUCCESS: Reboot alert sent to ${MAIL_TO}. Boot time: ${BOOT_TIME}"

    else
        log_message "ERROR: Email sent but unable to update notification state."
        exit 1
    fi

else
    log_message "ERROR: Failed to send email to ${MAIL_TO}."
    exit 1
fi

exit 0
