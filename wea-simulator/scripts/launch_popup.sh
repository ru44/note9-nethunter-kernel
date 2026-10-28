#!/system/bin/sh
# Fire the Samsung CMAS emergency-alert popup with custom text.
# Usage: launch_popup.sh "<body>" "<title>" "<cmas_message_uri>"
# Run as root (su) because the Activity is not exported.
BODY="${1:-Excessive Heat Warning: extreme heat expected today. Limit outdoor activity and stay hydrated.}"
TITLE="${2:-Emergency alert: Extreme heat}"
URI="${3:-content://cellbroadcasts_fwk/1}"

am start -n com.samsung.android.messaging/.ui.view.cmas.CmasDialogRegionalActivity \
 --es body "$BODY" \
 --es msgIdentifier "$TITLE" \
 --es cmas_message_uri "$URI"
