#!/usr/bin/env bash
set -e

LAST_IP_FILE="/app/data/last_ip.txt"

echo "Starting Cloudflare IP updater..."

while true; do
    CURRENT_IP=$(curl -4 -s https://api.ipify.org)

    if [[ -z "$CURRENT_IP" ]]; then
        echo "[$(date)] Error: Could not retrieve public IP"
        sleep 60
        continue
    fi

    # Load last known IP
    if [[ -f "$LAST_IP_FILE" ]]; then
        LAST_IP=$(cat "$LAST_IP_FILE")
    else
        LAST_IP=""
    fi

    # Compare
    if [[ "$CURRENT_IP" == "$LAST_IP" ]]; then
        echo "[$(date)] IP unchanged ($CURRENT_IP). Skipping Cloudflare update."
        sleep 60
        continue
    fi

    echo "[$(date)] IP changed: $LAST_IP → $CURRENT_IP"
    echo "$CURRENT_IP" > "$LAST_IP_FILE"

    # Build Cloudflare JSON
    JSON_PAYLOAD=$(cat <<EOF
{
  "name": "$CF_LIST_NAME",
  "description": "$CF_LIST_DESCRIPTION",
  "items": [
    {
      "value": "$CURRENT_IP/32",
      "description": "Auto-updated WAN IP"
    }
  ]
}
EOF
)

    # Send update to Cloudflare
    RESPONSE=$(curl -s -X PUT \
      "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/gateway/lists/$CF_LIST_ID" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "$JSON_PAYLOAD")

    if echo "$RESPONSE" | grep -q '"success":[ ]*true'; then
        echo "[$(date)] Successfully updated Cloudflare list"
    else
        echo "[$(date)] Cloudflare update failed:"
        echo "$RESPONSE"
    fi

    # Optional Pushover notification
    if [[ -n "$PUSHOVER_TOKEN" && -n "$PUSHOVER_USER" ]]; then
        curl -s \
          -F "token=$PUSHOVER_TOKEN" \
          -F "user=$PUSHOVER_USER" \
          -F "title=WAN IP Updated" \
          -F "message=New IP: $CURRENT_IP" \
          https://api.pushover.net/1/messages.json >/dev/null 2>&1
        echo "[$(date)] Sent Pushover notification"
    else
        echo "[$(date)] Pushover not configured, skipping notification"
    fi

    sleep 60
done
