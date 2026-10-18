#!/system/bin/sh
# Poco X6 Pro 5G (duchamp) - Ultra FPS Profile Engine
# Optimized for MediaTek Dimensity 8300-Ultra & Pixel Experience

MODDIR="${0%/*}/.."
CONFIG="$MODDIR/config.ini"
LOG="$MODDIR/last_action.log"

exec 1> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing FPS Tweaker Engine..."

# Load configuration
if [ -f "$CONFIG" ]; then
    . "$CONFIG"
else
    ENABLED=1
    PROFILE="extreme"
    THERMAL_BYPASS=1
    LOCK_120HZ=1
    GPU_BOOST=1
    UCLAMP_BOOST=1
    IO_TWEAKS=1
    MICROFREEZE_KILLER=1
fi

# Override profile if passed as argument $1
if [ -n "$1" ]; then
    PROFILE="$1"
fi

echo "Current Target Profile: $PROFILE (Module Enabled: $ENABLED)"

# Helper functions
safe_write() {
    FILE="$1"
    VAL="$2"
    if [ -f "$FILE" ]; then
        chmod 644 "$FILE" 2>/dev/null
        echo "$VAL" > "$FILE" 2>/dev/null
        echo "[+] $FILE -> $VAL"
    fi
}

apply_extreme() {
    echo "=== Applying EXTREME HARDCORE GAMING Profile ==="

    # 1. CPU Scaling & Governors (Dimensity 8300: 4x Little A510, 3x Mid A715, 1x Big A715 Prime)
    for pol in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -d "$pol" ]; then
            # Check available governors
            if grep -q "performance" "$pol/scaling_available_governors" 2>/dev/null; then
                safe_write "$pol/scaling_governor" "performance"
            else
                safe_write "$pol/scaling_governor" "schedutil"
                safe_write "$pol/schedutil/up_rate_limit_us" "0"
                safe_write "$pol/schedutil/down_rate_limit_us" "0"
                safe_write "$pol/schedutil/rate_limit_us" "0"
            fi
            # Set min frequency to maximum available or highest step
            if [ -f "$pol/cpuinfo_max_freq" ]; then
                MAX_F=$(cat "$pol/cpuinfo_max_freq")
                safe_write "$pol/scaling_min_freq" "$MAX_F"
            fi
        fi
    done

    # 2. UCLAMP / Energy Aware Scheduler (EAS) Top-App Boosting
    if [ "$UCLAMP_BOOST" = "1" ]; then
        echo "Boosting UCLAMP & Scheduler Priorities..."
        for top_uclamp in /dev/cpuctl/top-app/cpu.uclamp.min /sys/fs/cgroup/cpu/top-app/cpu.uclamp.min; do
            safe_write "$top_uclamp" "100" 2>/dev/null || safe_write "$top_uclamp" "1024" 2>/dev/null
        done
        for lat_sens in /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive /sys/fs/cgroup/cpu/top-app/cpu.uclamp.latency_sensitive; do
            safe_write "$lat_sens" "1"
        done
        safe_write "/dev/stune/top-app/schedtune.boost" "100"
        safe_write "/dev/stune/top-app/schedtune.prefer_idle" "1"
        safe_write "/proc/sys/kernel/sched_migration_cost_ns" "5000000"
        safe_write "/proc/sys/kernel/sched_autogroup_enabled" "0"
    fi

    # 3. MediaTek GED (Graphics Extension Driver) & Mali-G615 GPU Boost
    if [ "$GPU_BOOST" = "1" ]; then
        echo "Boosting MediaTek GED & Mali-G615 GPU Engine..."
        safe_write "/sys/module/ged/parameters/boost_gpu_enable" "1"
        safe_write "/sys/module/ged/parameters/gx_game_mode" "1"
        safe_write "/sys/module/ged/parameters/gx_force_cpu_boost" "1"
        safe_write "/sys/module/ged/parameters/ged_boost_enable" "1"
        safe_write "/sys/module/ged/parameters/timer_base_dvfs_margin" "50"
        safe_write "/sys/module/ged/parameters/gx_dfps" "0"
        safe_write "/sys/kernel/fpsgo/common/fpsgo_enable" "1"
        safe_write "/sys/kernel/fpsgo/fbt/boost_ta" "1"
        safe_write "/sys/kernel/fpsgo/fstb/fstb_self_ctrl" "0"
    fi

    # 4. Thermal Throttling Bypass
    if [ "$THERMAL_BYPASS" = "1" ]; then
        echo "Disabling MediaTek Thermal Throttling on Thermal Zones..."
        for tz in /sys/class/thermal/thermal_zone*; do
            if [ -f "$tz/mode" ]; then
                safe_write "$tz/mode" "disabled"
            fi
        done
    fi

    # 5. Refresh Rate 120Hz Lock (Pixel Experience)
    if [ "$LOCK_120HZ" = "1" ]; then
        echo "Locking Display Refresh Rate to 120Hz..."
        settings put system min_refresh_rate 120.0 2>/dev/null
        settings put system peak_refresh_rate 120.0 2>/dev/null
        settings put system user_refresh_rate 120 2>/dev/null
    fi

    # 6. Storage UFS 4.0 & I/O Latency Tweaks
    if [ "$IO_TWEAKS" = "1" ]; then
        echo "Tuning UFS 4.0 Storage Queues & Memory..."
        for block in /sys/block/sd* /sys/block/dm-*; do
            safe_write "$block/queue/read_ahead_kb" "1024"
            safe_write "$block/queue/rq_affinity" "2"
            safe_write "$block/queue/nomerges" "2"
            safe_write "$block/queue/add_random" "0"
            safe_write "$block/queue/iostats" "0"
        done
        safe_write "/proc/sys/vm/dirty_ratio" "10"
        safe_write "/proc/sys/vm/dirty_background_ratio" "5"
        safe_write "/proc/sys/vm/vfs_cache_pressure" "50"
        safe_write "/proc/sys/vm/stat_interval" "10"
    fi

    # 7. Micro-freeze Killer (Disable background tracing & log spam)
    if [ "$MICROFREEZE_KILLER" = "1" ]; then
        echo "Eliminating Background Micro-freeze sources..."
        safe_write "/sys/kernel/tracing/tracing_on" "0"
        safe_write "/sys/kernel/debug/tracing/tracing_on" "0"
        logcat -G 64K 2>/dev/null
    fi
}

apply_balanced() {
    echo "=== Applying BALANCED Profile ==="
    for pol in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -d "$pol" ]; then
            safe_write "$pol/scaling_governor" "schedutil"
            if [ -f "$pol/cpuinfo_min_freq" ]; then
                MIN_F=$(cat "$pol/cpuinfo_min_freq")
                safe_write "$pol/scaling_min_freq" "$MIN_F"
            fi
            safe_write "$pol/schedutil/up_rate_limit_us" "500"
            safe_write "$pol/schedutil/down_rate_limit_us" "20000"
        fi
    done

    # UCLAMP moderate
    safe_write "/dev/cpuctl/top-app/cpu.uclamp.min" "30" 2>/dev/null || safe_write "/dev/cpuctl/top-app/cpu.uclamp.min" "300" 2>/dev/null
    safe_write "/dev/stune/top-app/schedtune.boost" "30"

    # GED balanced
    safe_write "/sys/module/ged/parameters/boost_gpu_enable" "0"
    safe_write "/sys/module/ged/parameters/gx_game_mode" "1"

    # Thermal enabled
    for tz in /sys/class/thermal/thermal_zone*; do
        safe_write "$tz/mode" "enabled"
    done

    # 120Hz dynamic
    settings put system min_refresh_rate 60.0 2>/dev/null
    settings put system peak_refresh_rate 120.0 2>/dev/null
}

apply_battery() {
    echo "=== Applying BATTERY SAVER Profile ==="
    for pol in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -d "$pol" ]; then
            if grep -q "powersave" "$pol/scaling_available_governors" 2>/dev/null; then
                safe_write "$pol/scaling_governor" "powersave"
            else
                safe_write "$pol/scaling_governor" "schedutil"
                safe_write "$pol/schedutil/up_rate_limit_us" "2000"
                safe_write "$pol/schedutil/down_rate_limit_us" "5000"
            fi
            if [ -f "$pol/cpuinfo_min_freq" ]; then
                MIN_F=$(cat "$pol/cpuinfo_min_freq")
                safe_write "$pol/scaling_min_freq" "$MIN_F"
            fi
        fi
    done

    safe_write "/dev/cpuctl/top-app/cpu.uclamp.min" "0"
    safe_write "/dev/stune/top-app/schedtune.boost" "0"

    safe_write "/sys/module/ged/parameters/boost_gpu_enable" "0"
    safe_write "/sys/module/ged/parameters/gx_game_mode" "0"

    for tz in /sys/class/thermal/thermal_zone*; do
        safe_write "$tz/mode" "enabled"
    done

    settings put system min_refresh_rate 60.0 2>/dev/null
    settings put system peak_refresh_rate 120.0 2>/dev/null
}

apply_stock() {
    echo "=== Reverting to STOCK DEFAULT Settings ==="
    for pol in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -d "$pol" ]; then
            safe_write "$pol/scaling_governor" "schedutil"
            if [ -f "$pol/cpuinfo_min_freq" ]; then
                MIN_F=$(cat "$pol/cpuinfo_min_freq")
                safe_write "$pol/scaling_min_freq" "$MIN_F"
            fi
            if [ -f "$pol/cpuinfo_max_freq" ]; then
                MAX_F=$(cat "$pol/cpuinfo_max_freq")
                safe_write "$pol/scaling_max_freq" "$MAX_F"
            fi
            safe_write "$pol/schedutil/up_rate_limit_us" "1000"
            safe_write "$pol/schedutil/down_rate_limit_us" "10000"
        fi
    done

    safe_write "/dev/cpuctl/top-app/cpu.uclamp.min" "0"
    safe_write "/dev/stune/top-app/schedtune.boost" "0"

    safe_write "/sys/module/ged/parameters/boost_gpu_enable" "0"
    safe_write "/sys/module/ged/parameters/gx_game_mode" "0"
    safe_write "/sys/module/ged/parameters/timer_base_dvfs_margin" "0"

    for tz in /sys/class/thermal/thermal_zone*; do
        safe_write "$tz/mode" "enabled"
    done

    settings put system min_refresh_rate 60.0 2>/dev/null
    settings put system peak_refresh_rate 120.0 2>/dev/null

    safe_write "/sys/kernel/tracing/tracing_on" "1"
}

# Master execution logic
if [ "$ENABLED" = "0" ]; then
    echo "Tweaker is DISABLED. Reverting to stock."
    apply_stock
else
    case "$PROFILE" in
        extreme)
            apply_extreme
            ;;
        balanced)
            apply_balanced
            ;;
        battery)
            apply_battery
            ;;
        stock)
            apply_stock
            ;;
        *)
            apply_extreme
            ;;
    esac
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed successfully!"
exit 0
