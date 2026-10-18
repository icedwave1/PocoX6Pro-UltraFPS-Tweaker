#!/system/bin/sh
# Flush DNS, Reset network buffers & Re-enable Wi-Fi Low Latency Lock

echo "[Network] Flushing local DNS resolver caches..."
ndc resolver clearnetdns wlan0 2>/dev/null
ndc resolver clearnetdns rmnet_data0 2>/dev/null

echo "[Network] Applying TCP Fast-Path & Congestion Control..."
if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
    echo "bbr" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
fi
echo 1 > /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null
echo 16384 > /proc/sys/net/ipv4/tcp_notsent_lowat 2>/dev/null

echo "[Network] Locking Wi-Fi Driver to Esports Low-Latency Mode..."
cmd wifi set-low-latency-mode enabled 2>/dev/null
svc wifi set-multicast-enabled true 2>/dev/null
iw dev wlan0 set power_save off 2>/dev/null

echo "Network optimized! Ping jitter minimized."
exit 0
