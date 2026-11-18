#!/system/bin/sh
# Vertex late service script
MODDIR="${0%/*}"

# Load configuration if present
if [ -f "$MODDIR/config.prop" ]; then
    . "$MODDIR/config.prop"
fi

# Temporary diagnostics: observe startup and native/system crashes (5 min max)
# This does not change Vertex optimization settings.
VERTEX_DIAG_DIR=/sdcard/Download
[ -d "$VERTEX_DIAG_DIR" ] || VERTEX_DIAG_DIR=/data/local/tmp
printf '[%s] Vertex service starting, root=%s, boot_reason=%s\n' \
    "$(date '+%F %T')" "$(id -u)" "$(getprop sys.boot.reason)" \
    >> "$VERTEX_DIAG_DIR/Vertex-boot-events.log" 2>/dev/null
if [ -x /system/bin/logcat ]; then
    (
        /system/bin/toybox timeout 300 /system/bin/logcat \
            -b crash -b system -v threadtime \
            -f "$VERTEX_DIAG_DIR/Vertex-rescue-log.txt" -r 2048 -n 4
    ) >/dev/null 2>&1 &
fi


# Apply boot-time Vulkan UI rendering & zero-latency frame latching
if [ "${VULKAN_UI_ENABLED:-1}" = "1" ]; then
    setprop debug.hwui.renderer skiavk
fi
if [ "${SF_ZERO_LATENCY_LATCHING:-1}" = "1" ]; then
    setprop debug.sf.latch_unsignaled 1
    setprop debug.sf.enable_gl_backpressure 0
fi

# Apply display refresh rate & touch sensitivity
if [ "${FORCE_120HZ_REFRESH:-0}" = "1" ]; then
    settings put system min_refresh_rate 120.0 2>/dev/null
    settings put system peak_refresh_rate 120.0 2>/dev/null
fi
if [ "${TOUCH_BOOST_ENABLED:-1}" = "1" ]; then
    settings put system touch_sensitivity 1 2>/dev/null
fi
if [ "${BYPASS_CHARGING_ENABLED:-0}" = "1" ]; then
    echo 1 > /sys/class/power_supply/battery/batt_slate_mode 2>/dev/null || echo 0 > /sys/class/power_supply/battery/charging_enabled 2>/dev/null
fi

# Force Classic Bluetooth A2DP & Disable LE Audio
if [ "${DISABLE_LE_AUDIO:-1}" = "1" ]; then
    RP=""
    for p in resetprop /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop /data/adb/ap/bin/resetprop; do
        if command -v "$p" >/dev/null 2>&1 || [ -x "$p" ]; then
            RP="$p"
            break
        fi
    done
    [ -z "$RP" ] && RP="setprop"
    $RP -n bluetooth.profile.bap.unicast.client.enabled false 2>/dev/null
    $RP -n bluetooth.profile.bap.broadcast.source.enabled false 2>/dev/null
    $RP -n bluetooth.profile.bap.broadcast.assist.enabled false 2>/dev/null
    $RP -n bluetooth.profile.csip.set_coordinator.enabled false 2>/dev/null
    $RP -n persist.bluetooth.leaudio_offload.disabled true 2>/dev/null
    $RP -n persist.bluetooth.leaudio_mode disabled 2>/dev/null
    setprop bluetooth.profile.bap.unicast.client.enabled false 2>/dev/null
    setprop persist.bluetooth.leaudio_offload.disabled true 2>/dev/null
fi

# Apply UFS 4.0 scheduler queue optimizations
if [ "${TUNE_UFS_SCHEDULER:-1}" = "1" ]; then
    for q in /sys/block/sd*/queue /sys/block/nvme*/queue; do
        [ -d "$q" ] || continue
        grep -q "none" "$q/scheduler" 2>/dev/null && echo "none" > "$q/scheduler" 2>/dev/null
        [ -w "$q/nomerges" ] && echo 2 > "$q/nomerges" 2>/dev/null
        [ -w "$q/add_random" ] && echo 0 > "$q/add_random" 2>/dev/null
        [ -w "$q/iostats" ] && echo 0 > "$q/iostats" 2>/dev/null
    done
fi

# Launch scheduler daemon in background
if [ "${DAEMON_ENABLED:-1}" = "1" ]; then
    setsid nohup sh "$MODDIR/daemon.sh" >/dev/null 2>&1 &
fi
