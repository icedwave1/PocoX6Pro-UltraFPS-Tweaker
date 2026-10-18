#!/system/bin/sh
# Poco X6 Pro 5G - Advanced Hardware Status Reporter v2.5 (JSON)

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
NETWORK_BOOST=1
TOUCH_BOOST=1
AUDIO_LATENCY=1
DRAM_BOOST=1

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
BAT_CURRENT="0"
if [ -f "/sys/class/power_supply/battery/temp" ]; then
    RAW_BATT=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
    if [ -n "$RAW_BATT" ]; then
        BAT_TEMP=$((RAW_BATT / 10))
    fi
fi
if [ -f "/sys/class/power_supply/battery/current_now" ]; then
    RAW_CUR=$(cat /sys/class/power_supply/battery/current_now 2>/dev/null)
    if [ -n "$RAW_CUR" ]; then
        BAT_CURRENT=$((RAW_CUR / 1000))
    fi
fi

# Individual 8 CPU Core Frequencies
read_cpu_f() {
    CPU_ID="$1"
    PATH_F="/sys/devices/system/cpu/cpu$CPU_ID/cpufreq/scaling_cur_freq"
    if [ -f "$PATH_F" ]; then
        F=$(cat "$PATH_F" 2>/dev/null)
        echo "$((F / 1000))"
    else
        echo "0"
    fi
}

F0=$(read_cpu_f 0)
F1=$(read_cpu_f 1)
F2=$(read_cpu_f 2)
F3=$(read_cpu_f 3)
F4=$(read_cpu_f 4)
F5=$(read_cpu_f 5)
F6=$(read_cpu_f 6)
F7=$(read_cpu_f 7)

# Governors
GOV_LITTLE="schedutil"
if [ -f "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]; then
    GOV_LITTLE=$(cat "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" 2>/dev/null)
fi

# RAM & ZRAM info from /proc/meminfo
MEM_TOTAL=0
MEM_AVAIL=0
SWAP_TOTAL=0
SWAP_FREE=0

if [ -f "/proc/meminfo" ]; then
    MEM_TOTAL=$(grep "MemTotal:" /proc/meminfo | awk '{print int($2/1024)}')
    MEM_AVAIL=$(grep "MemAvailable:" /proc/meminfo | awk '{print int($2/1024)}')
    SWAP_TOTAL=$(grep "SwapTotal:" /proc/meminfo | awk '{print int($2/1024)}')
    SWAP_FREE=$(grep "SwapFree:" /proc/meminfo | awk '{print int($2/1024)}')
fi

# Refresh Rate
REFRESH_RATE=$(dumpsys display 2>/dev/null | grep -oE "fps=[0-9.]+" | head -n1 | cut -d= -f2)
if [ -z "$REFRESH_RATE" ]; then
    REFRESH_RATE="120"
fi

# TCP Congestion
TCP_CC="unknown"
if [ -f "/proc/sys/net/ipv4/tcp_congestion_control" ]; then
    TCP_CC=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)
fi

# Last log snippet
LAST_LOG=""
if [ -f "$LOG" ]; then
    LAST_LOG=$(tail -n 12 "$LOG" | tr '\n' ' ' | tr '"' "'")
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
  "network_boost": $NETWORK_BOOST,
  "touch_boost": $TOUCH_BOOST,
  "audio_latency": $AUDIO_LATENCY,
  "dram_boost": $DRAM_BOOST,
  "cpu_temp": "$CPU_TEMP",
  "battery_temp": "$BAT_TEMP",
  "battery_current": "$BAT_CURRENT mA",
  "freqs": [$F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7],
  "governor": "$GOV_LITTLE",
  "refresh_rate": "$REFRESH_RATE Hz",
  "tcp_congestion": "$TCP_CC",
  "mem_total": "$MEM_TOTAL MB",
  "mem_avail": "$MEM_AVAIL MB",
  "swap_total": "$SWAP_TOTAL MB",
  "swap_free": "$SWAP_FREE MB",
  "last_log": "$LAST_LOG"
}
EOF
