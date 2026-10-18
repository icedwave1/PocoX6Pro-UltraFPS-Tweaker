#!/system/bin/sh
# KernelSU Action Button Handler (Quick Switcher v2.5)

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
    cat << 'EOF' > "$CONFIG"
ENABLED=1
PROFILE=extreme
THERMAL_BYPASS=1
LOCK_120HZ=1
GPU_BOOST=1
UCLAMP_BOOST=1
IO_TWEAKS=1
MICROFREEZE_KILLER=1
NETWORK_BOOST=1
TOUCH_BOOST=1
AUDIO_LATENCY=1
DRAM_BOOST=1
EOF
    sh "$MODDIR/scripts/apply_profile.sh" "extreme"
    echo "Tweaker: ENABLED (EXTREME HARDCORE GAMING active!)"
fi

exit 0
