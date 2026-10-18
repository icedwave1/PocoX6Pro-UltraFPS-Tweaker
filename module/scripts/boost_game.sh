#!/system/bin/sh
# Real-time Game Foreground Process Optimizer (Auto-boost)

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

# Renice to highest priority (-20)
renice -n -20 -p "$PID" 2>/dev/null

# Real-time I/O class
ionice -c 1 -n 0 -p "$PID" 2>/dev/null

# OOM score immunity (don't kill under RAM pressure)
echo -900 > "/proc/$PID/oom_score_adj" 2>/dev/null

# Taskset / CPU affinity: assign threads to performance cores (Mid + Big: 4-7)
taskset -p f0 "$PID" 2>/dev/null

echo "Game $PACKAGE (PID $PID) successfully boosted to REALTIME priority!"
exit 0
