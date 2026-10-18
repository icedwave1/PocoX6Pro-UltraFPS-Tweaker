#!/system/bin/sh
# Poco X6 Pro 5G Ultra FPS Tweaker - Late Start Service

MODDIR="${0%/*}"

# Wait until Android has fully completed booting
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done

# Wait extra 5 seconds for thermal-engine and vendor services to settle
sleep 5

echo "[service.sh] Applying saved profile on boot..." >> "$MODDIR/service.log"
sh "$MODDIR/scripts/apply_profile.sh" >> "$MODDIR/service.log" 2>&1
