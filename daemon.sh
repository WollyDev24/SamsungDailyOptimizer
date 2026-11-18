#!/system/bin/sh
# Vertex Daemon & Audio Guard
# 1. Real-time audio guard: Pins Bluetooth & Audio HAL threads to Performance Cores 4-9
# 2. Daily maintenance: Executes optimizer.sh at 05:00 AM (with screen-off aware deferral)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/daemon.pid"

# Terminate duplicate daemon processes
for p in $(pgrep -f "sh .*/daemon\.sh" 2>/dev/null); do
    [ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null
done
echo $$ > "$PID_FILE" 2>/dev/null
echo $$ > /dev/vertex_daemon.pid 2>/dev/null
echo $$ > /data/local/tmp/vertex_daemon.pid 2>/dev/null

log_daemon() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] [DAEMON] $1"
    if [ -d /sdcard/Download ]; then
        echo "[$TIMESTAMP] [DAEMON] $1" >> /sdcard/Download/Vertex-boot-events.log 2>/dev/null
    fi
}

log_daemon "Vertex daemon started (PID $$). Audio guard active & scheduled for 05:00 AM."

# Function to pin audio threads to Performance Cores (Cores 4-9)
protect_audio_threads() {
    AUDIO_DAEMONS="com.android.bluetooth audioserver secaudiohalaidl android.hardware.audio.service com.sec.android.app.soundalive android.hardware.bluetooth@1.1-service-qti"
    for daemon in $AUDIO_DAEMONS; do
        for p in $(pidof "$daemon" 2>/dev/null); do
            renice -n -16 -p "$p" >/dev/null 2>&1
            if [ -d "/proc/$p/task" ]; then
                for t in /proc/"$p"/task/*; do
                    t_num=$(basename "$t")
                    renice -n -16 -p "$t_num" >/dev/null 2>&1
                    taskset -p -c 4-9 "$t_num" >/dev/null 2>&1 || taskset -p 0x3f0 "$t_num" >/dev/null 2>&1
                    [ -d /dev/cpuset/foreground-boost ] && echo "$t_num" > /dev/cpuset/foreground-boost/tasks 2>/dev/null
                    [ -d /dev/cpuset/top-app ] && echo "$t_num" > /dev/cpuset/top-app/tasks 2>/dev/null
                done
            fi
        done
    done
    settings put system lockscreen_sounds_enabled 0 2>/dev/null
}

# Correct v1.4.2 scheduling defect: starting this daemon at 05:01-23:59
# must NOT interpret the missed 05:00 time as a reason to run immediately.
# Keep the entire daily optimizer and all tuning controls unchanged.
LAST_OPT_DAY=""
START_DAY=$(date '+%Y%m%d' 2>/dev/null)
START_H=$(date '+%H' 2>/dev/null)
START_H=$((10#$START_H))
if [ "$START_H" -ge 5 ]; then
    LAST_OPT_DAY="$START_DAY"
    log_daemon "Startup at/after 05:00: next maintenance is tomorrow at 05:00."
else
    log_daemon "Startup before 05:00: next maintenance is today at 05:00."
fi

while true; do
    CUR_DAY=$(date '+%Y%m%d' 2>/dev/null)
    CUR_H=$(date '+%H' 2>/dev/null)
    CUR_H=$((10#$CUR_H))

    # 1. Daily 05:00 AM Maintenance Pass
    if [ "$CUR_H" -ge 5 ] && [ "$LAST_OPT_DAY" != "$CUR_DAY" ]; then
        log_daemon "05:00 AM schedule reached! Checking device state..."

        SMART_SCREEN_AWARE=1
        if [ -f "$SCRIPT_DIR/config.prop" ]; then
            . "$SCRIPT_DIR/config.prop"
        elif [ -f "/data/adb/modules/samsung_daily_optimizer/config.prop" ]; then
            . "/data/adb/modules/samsung_daily_optimizer/config.prop"
        fi

        if [ "$SMART_SCREEN_AWARE" = "1" ]; then
            MAX_WAIT=60
            WAIT_COUNT=0
            while [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; do
                if dumpsys power 2>/dev/null | grep -q "mWakefulness=Awake"; then
                    log_daemon "Screen active. Deferring 60s for zero UI stutter ($((WAIT_COUNT + 1))/$MAX_WAIT min)..."
                    sleep 60
                    WAIT_COUNT=$((WAIT_COUNT + 1))
                else
                    break
                fi
            done
        fi

        log_daemon "Running daily optimization pass..."
        if [ -f "$SCRIPT_DIR/optimizer.sh" ]; then
            sh "$SCRIPT_DIR/optimizer.sh"
        elif [ -f "/data/adb/modules/samsung_daily_optimizer/optimizer.sh" ]; then
            sh "/data/adb/modules/samsung_daily_optimizer/optimizer.sh"
        fi

        LAST_OPT_DAY="$CUR_DAY"
        log_daemon "Daily optimization completed."
    fi

    # 2. Intelligent Audio Stutter Guard
    # If Bluetooth A2DP audio is actively playing, pin threads to Performance Cores 4-9
    IS_PLAYING=0
    if dumpsys bluetooth_manager 2>/dev/null | grep -q "mIsPlaying: true"; then
        IS_PLAYING=1
    elif dumpsys media.audio_flinger 2>/dev/null | grep -A 5 "AUDIO_DEVICE_OUT_BLUETOOTH_A2DP" | grep -q "Standby: no"; then
        IS_PLAYING=1
    fi

    if [ "$IS_PLAYING" = "1" ]; then
        protect_audio_threads
        sleep 20
    else
        sleep 60
    fi
done
