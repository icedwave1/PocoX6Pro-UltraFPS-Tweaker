#!/system/bin/sh
# KernelSU Action Button Handler (Quick Switcher)

MODDIR="${0%/*}"
CONFIG="$MODDIR/config.ini"

if [ -f "$CONFIG" ]; then
    . "$CONFIG"
else
    ENABLED=1
    PROFILE="extreme"
fi

# Toggle logic
if [ "$ENABLED" = "1" ] && [ "$PROFILE" = "extreme" ]; then
    # Switch to Stock
    echo "ENABLED=0" > "$CONFIG"
    echo "PROFILE=stock" >> "$CONFIG"
    sh "$MODDIR/scripts/apply_profile.sh" "stock"
    echo "Tweaker: DISABLED (Stock Mode applied)"
else
    # Switch to Extreme
    echo "ENABLED=1" > "$CONFIG"
    echo "PROFILE=extreme" >> "$CONFIG"
    echo "THERMAL_BYPASS=1" >> "$CONFIG"
    echo "LOCK_120HZ=1" >> "$CONFIG"
    echo "GPU_BOOST=1" >> "$CONFIG"
    echo "UCLAMP_BOOST=1" >> "$CONFIG"
    echo "IO_TWEAKS=1" >> "$CONFIG"
    echo "MICROFREEZE_KILLER=1" >> "$CONFIG"
    sh "$MODDIR/scripts/apply_profile.sh" "extreme"
    echo "Tweaker: ENABLED (EXTREME HARDCORE GAMING active!)"
fi

exit 0
