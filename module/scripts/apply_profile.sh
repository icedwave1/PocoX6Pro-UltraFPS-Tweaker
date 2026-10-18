#!/system/bin/sh
# Poco X6 Pro 5G (duchamp) - Ultra FPS Profile Engine v2.5
# Specialized for MediaTek Dimensity 8300-Ultra (MT6897) & Pixel Experience

MODDIR="${0%/*}/.."
CONFIG="$MODDIR/config.ini"
LOG="$MODDIR/last_action.log"

exec 1> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Ultra FPS Engine v2.5..."

# Load configuration with robust defaults
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

if [ -n "$1" ]; then
    PROFILE="$1"
fi

echo "Active Target Profile: $PROFILE (Module Enabled: $ENABLED)"

safe_write() {
    FILE="$1"
    VAL="$2"
    if [ -e "$FILE" ]; then
        chmod 666 "$FILE" 2>/dev/null
        echo "$VAL" > "$FILE" 2>/dev/null
        echo "[+] $FILE -> $VAL"
    fi
}

# --- Core Subsystems ---

apply_cpu_scheduler() {
    MODE="$1"
    echo "[-] Configuring CPU Clusters & Scheduler ($MODE)..."

    # Dimensity 8300: cpu0-3 (A510), cpu4-6 (A715), cpu7 (A715 Prime)
    if [ "$MODE" = "extreme" ] || [ "$MODE" = "esports" ]; then
        # Force all 8 cores ONLINE (prevent sleep core collapse in games)
        for c in 0 1 2 3 4 5 6 7; do
            safe_write "/sys/devices/system/cpu/cpu$c/online" "1"
        done

        # MTK PPM (Processor Power Management) Sysboost
        safe_write "/proc/ppm/policy/sysboost_status" "1"
        safe_write "/proc/ppm/policy/hard_userlimit_cpu_core" "8"

        # Governors
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
            if [ -d "$pol" ]; then
                if grep -q "performance" "$pol/scaling_available_governors" 2>/dev/null; then
                    safe_write "$pol/scaling_governor" "performance"
                else
                    safe_write "$pol/scaling_governor" "schedutil"
                    safe_write "$pol/schedutil/up_rate_limit_us" "0"
                    safe_write "$pol/schedutil/down_rate_limit_us" "0"
                    safe_write "$pol/schedutil/rate_limit_us" "0"
                    safe_write "$pol/schedutil/hispeed_load" "65"
                fi
                if [ -f "$pol/cpuinfo_max_freq" ]; then
                    MAX_F=$(cat "$pol/cpuinfo_max_freq")
                    safe_write "$pol/scaling_min_freq" "$MAX_F"
                fi
            fi
        done
        safe_write "/proc/sys/kernel/sched_schedstats" "0"
        safe_write "/proc/sys/kernel/sched_cfs_bandwidth_slice_us" "3000"
    elif [ "$MODE" = "balanced" ]; then
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
            if [ -d "$pol" ]; then
                safe_write "$pol/scaling_governor" "schedutil"
                safe_write "$pol/schedutil/up_rate_limit_us" "500"
                safe_write "$pol/schedutil/down_rate_limit_us" "20000"
                if [ -f "$pol/cpuinfo_min_freq" ]; then
                    MIN_F=$(cat "$pol/cpuinfo_min_freq")
                    safe_write "$pol/scaling_min_freq" "$MIN_F"
                fi
            fi
        done
    elif [ "$MODE" = "battery" ]; then
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
            if [ -d "$pol" ]; then
                if grep -q "powersave" "$pol/scaling_available_governors" 2>/dev/null; then
                    safe_write "$pol/scaling_governor" "powersave"
                else
                    safe_write "$pol/scaling_governor" "schedutil"
                    safe_write "$pol/schedutil/up_rate_limit_us" "2000"
                    safe_write "$pol/schedutil/down_rate_limit_us" "5000"
                fi
            fi
        done
    else
        # Stock reset
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
            if [ -d "$pol" ]; then
                safe_write "$pol/scaling_governor" "schedutil"
                safe_write "$pol/schedutil/up_rate_limit_us" "1000"
                safe_write "$pol/schedutil/down_rate_limit_us" "10000"
                if [ -f "$pol/cpuinfo_min_freq" ]; then
                    MIN_F=$(cat "$pol/cpuinfo_min_freq")
                    safe_write "$pol/scaling_min_freq" "$MIN_F"
                fi
                if [ -f "$pol/cpuinfo_max_freq" ]; then
                    MAX_F=$(cat "$pol/cpuinfo_max_freq")
                    safe_write "$pol/scaling_max_freq" "$MAX_F"
                fi
            fi
        done
    fi
}

apply_uclamp() {
    if [ "$UCLAMP_BOOST" = "1" ]; then
        echo "[-] Boosting UCLAMP & EAS Top-App Priority..."
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
    else
        safe_write "/dev/cpuctl/top-app/cpu.uclamp.min" "0"
        safe_write "/dev/stune/top-app/schedtune.boost" "0"
        safe_write "/proc/sys/kernel/sched_migration_cost_ns" "500000"
    fi
}

apply_gpu_ged() {
    if [ "$GPU_BOOST" = "1" ]; then
        echo "[-] Boosting MediaTek GED & Mali-G615 DVFS Pipeline..."
        safe_write "/sys/module/ged/parameters/boost_gpu_enable" "1"
        safe_write "/sys/module/ged/parameters/gx_game_mode" "1"
        safe_write "/sys/module/ged/parameters/gx_force_cpu_boost" "1"
        safe_write "/sys/module/ged/parameters/ged_boost_enable" "1"
        safe_write "/sys/module/ged/parameters/timer_base_dvfs_margin" "50"
        safe_write "/sys/module/ged/parameters/gx_dfps" "0"
        safe_write "/sys/module/ged/parameters/enable_game_self_frc" "0"
        safe_write "/sys/kernel/fpsgo/common/fpsgo_enable" "1"
        safe_write "/sys/kernel/fpsgo/fbt/boost_ta" "1"
        safe_write "/sys/kernel/fpsgo/fbt/switch_idle" "0"
        safe_write "/sys/kernel/fpsgo/fstb/fstb_self_ctrl" "0"
        # Mali GPU power policy
        safe_write "/sys/class/misc/mali0/device/power_policy" "always_on"
    else
        safe_write "/sys/module/ged/parameters/boost_gpu_enable" "0"
        safe_write "/sys/module/ged/parameters/gx_game_mode" "0"
        safe_write "/sys/module/ged/parameters/timer_base_dvfs_margin" "0"
        safe_write "/sys/class/misc/mali0/device/power_policy" "coarse_demand"
    fi
}

apply_dvfsrc_dram() {
    if [ "$DRAM_BOOST" = "1" ]; then
        echo "[-] Boosting MediaTek DVFSRC LPDDR5X DRAM Bandwidth..."
        for node in /sys/devices/platform/*dvfsrc*/dvfsrc_force_vcore_dvfs /sys/kernel/debug/dvfsrc/*; do
            safe_write "$node" "1" 2>/dev/null
        done
        safe_write "/sys/devices/platform/10012000.dvfsrc/dvfsrc_opp_table" "0" 2>/dev/null
    fi
}

apply_thermal() {
    if [ "$THERMAL_BYPASS" = "1" ]; then
        echo "[-] Disabling MediaTek Kernel Thermal Throttling..."
        for tz in /sys/class/thermal/thermal_zone*; do
            if [ -f "$tz/mode" ]; then
                safe_write "$tz/mode" "disabled"
            fi
        done
    else
        for tz in /sys/class/thermal/thermal_zone*; do
            if [ -f "$tz/mode" ]; then
                safe_write "$tz/mode" "enabled"
            fi
        done
    fi
}

apply_120hz_display() {
    if [ "$LOCK_120HZ" = "1" ]; then
        echo "[-] Locking 120Hz Display Refresh Rate (Pixel Experience)..."
        settings put system min_refresh_rate 120.0 2>/dev/null
        settings put system peak_refresh_rate 120.0 2>/dev/null
        settings put system user_refresh_rate 120 2>/dev/null

        # Prioritize SurfaceFlinger
        SF_PID=$(pidof surfaceflinger 2>/dev/null)
        if [ -n "$SF_PID" ]; then
            renice -n -20 -p "$SF_PID" 2>/dev/null
            taskset -p f0 "$SF_PID" 2>/dev/null # Pin to performance cores 4-7
        fi
    else
        settings put system min_refresh_rate 60.0 2>/dev/null
        settings put system peak_refresh_rate 120.0 2>/dev/null
    fi
}

apply_network_ping() {
    if [ "$NETWORK_BOOST" = "1" ]; then
        echo "[-] Tuning Gaming Network Latency & TCP Fast-Path..."
        # TCP Congestion Control
        if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
            safe_write "/proc/sys/net/ipv4/tcp_congestion_control" "bbr"
        else
            safe_write "/proc/sys/net/ipv4/tcp_congestion_control" "cubic"
        fi
        safe_write "/proc/sys/net/ipv4/tcp_low_latency" "1"
        safe_write "/proc/sys/net/ipv4/tcp_fastopen" "3"
        safe_write "/proc/sys/net/ipv4/tcp_notsent_lowat" "16384"
        safe_write "/proc/sys/net/ipv4/tcp_tw_reuse" "1"
        safe_write "/proc/sys/net/ipv4/tcp_syncookies" "0"

        # Wi-Fi Low Latency Lock
        cmd wifi set-low-latency-mode enabled 2>/dev/null
        svc wifi set-multicast-enabled true 2>/dev/null
        iw dev wlan0 set power_save off 2>/dev/null
    fi
}

apply_io_storage() {
    if [ "$IO_TWEAKS" = "1" ]; then
        echo "[-] Optimizing UFS 4.0 Queues & Linux VM Memory Management..."
        for block in /sys/block/sd* /sys/block/dm-*; do
            safe_write "$block/queue/read_ahead_kb" "1024"
            safe_write "$block/queue/rq_affinity" "2"
            safe_write "$block/queue/nomerges" "2"
            safe_write "$block/queue/add_random" "0"
            safe_write "$block/queue/iostats" "0"
            safe_write "$block/queue/iosched/slice_idle" "0"
        done
        safe_write "/proc/sys/vm/swappiness" "30"
        safe_write "/proc/sys/vm/vfs_cache_pressure" "40"
        safe_write "/proc/sys/vm/dirty_ratio" "10"
        safe_write "/proc/sys/vm/dirty_background_ratio" "5"
        safe_write "/proc/sys/vm/page-cluster" "0" # Zero decompression hitching from zRAM
        safe_write "/proc/sys/vm/stat_interval" "15"
    fi
}

apply_microfreeze_killer() {
    if [ "$MICROFREEZE_KILLER" = "1" ]; then
        echo "[-] Eliminating Micro-freeze Sources & Background Jitter..."
        safe_write "/sys/kernel/tracing/tracing_on" "0"
        safe_write "/sys/kernel/debug/tracing/tracing_on" "0"
        logcat -G 64K 2>/dev/null
    else
        safe_write "/sys/kernel/tracing/tracing_on" "1"
    fi
}

# --- Execution Router ---

if [ "$ENABLED" = "0" ]; then
    echo "Tweaker is DISABLED. Reverting all to Stock..."
    apply_cpu_scheduler "stock"
    apply_uclamp
    apply_gpu_ged
    apply_thermal
    apply_120hz_display
    apply_network_ping
    apply_io_storage
    apply_microfreeze_killer
else
    case "$PROFILE" in
        extreme)
            apply_cpu_scheduler "extreme"
            apply_uclamp
            apply_gpu_ged
            apply_dvfsrc_dram
            apply_thermal
            apply_120hz_display
            apply_network_ping
            apply_io_storage
            apply_microfreeze_killer
            ;;
        esports)
            apply_cpu_scheduler "esports"
            apply_uclamp
            apply_gpu_ged
            apply_dvfsrc_dram
            apply_thermal
            apply_120hz_display
            apply_network_ping
            apply_io_storage
            apply_microfreeze_killer
            ;;
        balanced)
            apply_cpu_scheduler "balanced"
            apply_uclamp
            apply_gpu_ged
            apply_thermal
            apply_120hz_display
            apply_io_storage
            ;;
        battery)
            apply_cpu_scheduler "battery"
            apply_uclamp
            apply_gpu_ged
            apply_thermal
            apply_120hz_display
            ;;
        stock)
            apply_cpu_scheduler "stock"
            apply_uclamp
            apply_gpu_ged
            apply_thermal
            apply_120hz_display
            apply_network_ping
            apply_io_storage
            apply_microfreeze_killer
            ;;
        *)
            apply_cpu_scheduler "extreme"
            apply_uclamp
            apply_gpu_ged
            apply_dvfsrc_dram
            apply_thermal
            apply_120hz_display
            apply_network_ping
            apply_io_storage
            apply_microfreeze_killer
            ;;
    esac
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] All subsystems processed successfully!"
exit 0
