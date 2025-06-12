#!/bin/bash

# ========== Config ==========
LOG_FILE="wifi_diagnostics.log"
PING_TARGET="8.8.8.8"
ROUTER_IP="192.168.1.1"
THRESHOLD_SIGNAL=-70
THRESHOLD_LOSS=5
INTERVAL=10
TRACEROUTE_INTERVAL=300  # 5 minutes
LAST_TRACEROUTE_TIME=0
WDUTIL="sudo /usr/bin/wdutil"

# ========== Functions ==========

get_wdutil_info() {
    $WDUTIL info
}

get_value() {
    echo "$1" | awk -v key="$2" '
        $0 ~ "^ *"key"[ ]*:" {
            match($0, /-?[0-9]+(\.[0-9]+)?/)
            if (RSTART > 0) print substr($0, RSTART, RLENGTH)
        }'
}

get_string_value() {
    echo "$1" | awk -v key="$2" '
        $0 ~ "^ *"key"[ ]*:" {
            sub(".*: ", "", $0); print $0
        }'
}

get_signal_strength_level() {
    local rssi="$1"
    if [ -z "$rssi" ]; then
        echo "Unknown"
    elif [ "$rssi" -ge -50 ]; then
        echo "Excellent (100%)"
    elif [ "$rssi" -ge -60 ]; then
        echo "Very Good (80%)"
    elif [ "$rssi" -ge -67 ]; then
        echo "Good (60%)"
    elif [ "$rssi" -ge -70 ]; then
        echo "Fair (40%)"
    else
        echo "Poor (20%)"
    fi
}

ping_loss() {
    ping -c 5 -q "$PING_TARGET" | awk -F',' '/packet loss/ {print $3}' | sed 's/%//'
}

ping_stats() {
    ping -c 5 -q "$PING_TARGET" | awk -F'/' '/rtt/ {print $5}'
}

ping_router_loss() {
    ping -c 5 -q "$ROUTER_IP" | awk -F',' '/packet loss/ {print $3}' | sed 's/%//'
}

dns_resolution_time() {
    dig +stats google.com | awk '/Query time:/ {print $4}'
}

run_traceroute() {
    echo "--- Traceroute ---" >> "$LOG_FILE"
    traceroute -m 5 -q 1 "$PING_TARGET" >> "$LOG_FILE"
    echo "------------------" >> "$LOG_FILE"
}

# ========== Init ==========
sudo -v || exit 1

echo "===== macOS Wi-Fi Diagnostic Monitor (wdutil) ====="
echo "Target: $PING_TARGET"
echo "Logging to: $LOG_FILE"
echo "-----------------------------------------"

PREV_SSID=""
PREV_BSSID=""

# ========== Main Loop ==========
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    NOW=$(date +%s)
    INFO=$(get_wdutil_info)

    SIGNAL=$(get_value "$INFO" "RSSI")
    NOISE=$(get_value "$INFO" "Noise")
    RATE=$(get_value "$INFO" "Tx Rate")
    SSID=$(get_string_value "$INFO" "SSID")
    BSSID=$(get_string_value "$INFO" "BSSID")
    CHANNEL=$(get_string_value "$INFO" "Channel")

    LOSS=$(ping_loss)
    LATENCY=$(ping_stats)
    ROUTER_LOSS=$(ping_router_loss)
    DNS_TIME=$(dns_resolution_time)
    STRENGTH_LEVEL=$(get_signal_strength_level "$SIGNAL")

    echo "$TIMESTAMP" >> "$LOG_FILE"
    echo "SSID: $SSID | BSSID: $BSSID | Channel: $CHANNEL" >> "$LOG_FILE"
    echo "RSSI: ${SIGNAL:-N/A} dBm ($STRENGTH_LEVEL) | Noise: ${NOISE:-N/A} dBm | Rate: ${RATE:-N/A} Mbps" >> "$LOG_FILE"
    echo "Ping Loss: ${LOSS:-N/A}% | Avg Latency: ${LATENCY:-N/A} ms | Router Loss: ${ROUTER_LOSS:-N/A}% | DNS Time: ${DNS_TIME:-N/A} ms" >> "$LOG_FILE"
    echo "------------------------------------------------" >> "$LOG_FILE"

    echo "$TIMESTAMP — SSID: $SSID, Signal: $SIGNAL dBm ($STRENGTH_LEVEL), Loss: ${LOSS}% @ ${LATENCY}ms, Router Loss: ${ROUTER_LOSS}%"

    if [[ "$SSID" != "$PREV_SSID" ]]; then
        echo "[!] SSID changed from '$PREV_SSID' to '$SSID'"
        echo "$TIMESTAMP [LOG] SSID changed from '$PREV_SSID' to '$SSID'" >> "$LOG_FILE"
        PREV_SSID="$SSID"
    fi

    if [[ "$BSSID" != "$PREV_BSSID" ]]; then
        echo "[!] BSSID changed from '$PREV_BSSID' to '$BSSID'"
        echo "$TIMESTAMP [LOG] BSSID changed from '$PREV_BSSID' to '$BSSID'" >> "$LOG_FILE"
        PREV_BSSID="$BSSID"
    fi

    if [[ "$SIGNAL" =~ ^-?[0-9]+$ ]] && [ "$SIGNAL" -lt "$THRESHOLD_SIGNAL" ]; then
        echo "[!] Weak signal: $SIGNAL dBm"
    fi

    if [[ "$LOSS" =~ ^[0-9]+(\.[0-9]+)?$ ]] && awk "BEGIN {exit !($LOSS > $THRESHOLD_LOSS)}"; then
        echo "[!] High internet packet loss: $LOSS%"
    fi

    if [[ "$ROUTER_LOSS" =~ ^[0-9]+(\.[0-9]+)?$ ]] && awk "BEGIN {exit !($ROUTER_LOSS > 5)}"; then
        echo "[!] High router packet loss: $ROUTER_LOSS%"
    fi

    if (( NOW - LAST_TRACEROUTE_TIME >= TRACEROUTE_INTERVAL )); then
        run_traceroute
        LAST_TRACEROUTE_TIME=$NOW
    fi

    sleep "$INTERVAL"
done
