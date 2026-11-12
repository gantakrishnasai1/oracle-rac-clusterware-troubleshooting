#!/usr/bin/env bash
# Example node reboot detector.
# Intended to be run periodically by cron/systemd timer.
# Sends an email only when the most recent boot time is within the configured
# lookback window. This does not persist prior alert state; repeated runs during
# the window may send repeated alerts. Add state management before production use.

set -u

LOOKBACK_MINUTES="${LOOKBACK_MINUTES:-30}"
MAIL_TO="${MAIL_TO:-}"
HOST="$(hostname -f 2>/dev/null || hostname)"
BOOT_TIME="$(uptime -s 2>/dev/null || true)"

if [[ -z "$BOOT_TIME" ]]; then
  echo "Unable to determine boot time using uptime -s."
  exit 1
fi

BOOT_EPOCH="$(date -d "$BOOT_TIME" +%s 2>/dev/null || true)"
NOW_EPOCH="$(date +%s)"

if [[ -z "$BOOT_EPOCH" ]]; then
  echo "Unable to parse boot time: $BOOT_TIME"
  exit 1
fi

AGE_SECONDS=$((NOW_EPOCH - BOOT_EPOCH))
AGE_MINUTES=$((AGE_SECONDS / 60))

if (( AGE_SECONDS < 0 )); then
  echo "Boot time is in the future; check system clock: $BOOT_TIME"
  exit 1
fi

if (( AGE_MINUTES <= LOOKBACK_MINUTES )); then
  SUBJECT="Node reboot detected on ${HOST}"
  BODY="A recent reboot was detected.

Host: ${HOST}
Boot time: ${BOOT_TIME}
Minutes since boot: ${AGE_MINUTES}
Detection time: $(date '+%Y-%m-%d %H:%M:%S %Z')
Lookback window: ${LOOKBACK_MINUTES} minutes
"

  if [[ -n "$MAIL_TO" ]] && command -v mail >/dev/null 2>&1; then
    printf '%s\n' "$BODY" | mail -s "$SUBJECT" "$MAIL_TO"
  else
    printf '%s\n' "$BODY"
    echo "MAIL_TO is unset or mail command unavailable; printed alert to stdout."
  fi
else
  echo "No reboot within the last ${LOOKBACK_MINUTES} minutes. Last boot: ${BOOT_TIME}"
fi
