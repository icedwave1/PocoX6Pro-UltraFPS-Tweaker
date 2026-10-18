#!/system/bin/sh
# Poco X6 Pro 5G - Status Reporter (Output JSON)

MODDIR="${0%/*}/.."
CONFIG="$MODDIR/config.ini"
LOG="$MODDIR/last_action.log"

# Default fallback values
ENABLED=1
PROFILE="extreme"
THERMAL_BYPASS=1
LOCK_120HZ=1
GPU_BOOST=1
UCLAMP_BOOST=1
IO_TWEAKS=1
MICROFREEZE_KILLER=1

if [ -f "$CONFIG" ]; then
    . "$CONFIG"
fi

# Temperatures
CPU_TEMP="N/A"
if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
    RAW_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    if [ -n "$RAW_TEMP" ]; then
        if [ "$RAW_TEMP" -gt 1000 ]; then
            CPU_TEMP=$((RAW_TEMP / 1000))
        else
            CPU_TEMP=$RAW_TEMP
        fi
    fi
fi

BAT_TEMP="N/A"
if [ -f "/sys/class/power_supply/battery/temp" ]; then
    RAW_BATT=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
    if [ -n "$RAW_BATT" ]; then
        BAT_TEMP=$((RAW_BATT / 10))
    fi
fi

# CPU Frequencies (Dimensity 8300: policy0, policy4, policy7)
read_freq() {
    POL="$1"
    if [ -f "/sys/devices/system/cpu/cpufreq/$POL/scaling_cur_freq" ]; then
        F=$(cat "/sys/devices/system/cpu/cpufreq/$POL/scaling_cur_freq" 2>/dev/null)
        echo "$((F / 1000))"
    else
        echo "0"
    fi
}

FREQ_LITTLE=$(read_freq "policy0")
FREQ_MID=$(read_freq "policy4")
FREQ_BIG=$(read_freq "policy7")

# Governors
GOV_LITTLE="unknown"
if [ -f "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]; then
    GOV_LITTLE=$(cat "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" 2>/dev/null)
fi

# Refresh Rate
REFRESH_RATE=$(dumpsys display 2>/dev/null | grep -oE "fps=[0-9.]+" | head -n1 | cut -d= -f2)
if [ -z "$REFRESH_RATE" ]; then
    REFRESH_RATE="120"
fi

# Last log snippet
LAST_LOG=""
if [ -f "$LOG" ]; then
    LAST_LOG=$(tail -n 10 "$LOG" | tr '\n' ' ' | tr '"' "'")
fi

# Output JSON
cat << EOF
{
  "enabled": $ENABLED,
  "profile": "$PROFILE",
  "thermal_bypass": $THERMAL_BYPASS,
  "lock_120hz": $LOCK_120HZ,
  "gpu_boost": $GPU_BOOST,
  "uclamp_boost": $UCLAMP_BOOST,
  "io_tweaks": $IO_TWEAKS,
  "microfreeze_killer": $MICROFREEZE_KILLER,
  "cpu_temp": "$CPU_TEMP",
  "battery_temp": "$BAT_TEMP",
  "freq_little": "$FREQ_LITTLE MHz",
  "freq_mid": "$FREQ_MID MHz",
  "freq_big": "$FREQ_BIG MHz",
  "governor": "$GOV_LITTLE",
  "refresh_rate": "$REFRESH_RATE Hz",
  "last_log": "$LAST_LOG"
}
EOF
