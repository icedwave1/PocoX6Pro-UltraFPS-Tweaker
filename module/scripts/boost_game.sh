#!/system/bin/sh
# Real-time Game Foreground Process Optimizer (Auto-boost v2.5)

# Find focused package
FOCUS_LINE=$(dumpsys window 2>/dev/null | grep -E 'mCurrentFocus|mFocusedApp' | head -n1)
PACKAGE=$(echo "$FOCUS_LINE" | grep -oE '[a-zA-Z0-9._]+/[a-zA-Z0-9._]+' | head -n1 | cut -d/ -f1)

if [ -z "$PACKAGE" ]; then
    PACKAGE=$(dumpsys activity activities 2>/dev/null | grep -E 'ResumedActivity' | head -n1 | grep -oE '[a-zA-Z0-9._]+/[a-zA-Z0-9._]+' | cut -d/ -f1)
fi

if [ -z "$PACKAGE" ]; then
    echo "Could not detect active focused app"
    exit 1
fi

echo "Detected Focused App: $PACKAGE"

# Find PID
PID=$(pidof "$PACKAGE" 2>/dev/null | awk '{print $1}')
if [ -z "$PID" ]; then
    PID=$(pgrep -f "$PACKAGE" 2>/dev/null | head -n1)
fi

if [ -z "$PID" ]; then
    echo "Process for $PACKAGE is not running"
    exit 1
fi

echo "Prioritizing PID $PID ($PACKAGE)..."

# 1. Renice to highest priority (-20)
renice -n -20 -p "$PID" 2>/dev/null

# 2. Real-time I/O class
ionice -c 1 -n 0 -p "$PID" 2>/dev/null

# 3. OOM score immunity (immune to Android LMK killing)
echo -900 > "/proc/$PID/oom_score_adj" 2>/dev/null

# 4. Taskset / CPU affinity: assign threads to performance cores (Mid + Big: cores 4-7)
taskset -p f0 "$PID" 2>/dev/null

# 5. Inject PID directly into MediaTek GED & FPSGO gaming engine nodes
if [ -f "/sys/module/ged/parameters/gx_top_app_pid" ]; then
    echo "$PID" > /sys/module/ged/parameters/gx_top_app_pid 2>/dev/null
fi
if [ -f "/sys/kernel/fpsgo/common/fpsgo_sub_pid" ]; then
    echo "$PID" > /sys/kernel/fpsgo/common/fpsgo_sub_pid 2>/dev/null
fi

echo "Game $PACKAGE (PID $PID) boosted! Tied to Mali GED + MTK Performance Cores."
exit 0
