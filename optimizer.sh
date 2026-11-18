#!/system/bin/sh
# Vertex Routine (formerly Samsung Daily Optimizer)
# Automated performance maintenance for Samsung Galaxy devices (One UI)
# Safe for Xposed / Vector (com.android.systemui is explicitly excluded)

export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH:/system/bin:/system/xbin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load configuration if present
if [ -f "$SCRIPT_DIR/config.prop" ]; then
    . "$SCRIPT_DIR/config.prop"
elif [ -f "/data/adb/modules/samsung_daily_optimizer/config.prop" ]; then
    . "/data/adb/modules/samsung_daily_optimizer/config.prop"
fi

# Defaults
RAM_PLUS_ENABLED="${RAM_PLUS_ENABLED:-1}"
RAM_PLUS_SIZE="${RAM_PLUS_SIZE:-2048}"
TUNE_SWAPPINESS="${TUNE_SWAPPINESS:-1}"
SWAPPINESS_VALUE="${SWAPPINESS_VALUE:-60}"
TUNE_READ_AHEAD="${TUNE_READ_AHEAD:-1}"
READ_AHEAD_KB="${READ_AHEAD_KB:-512}"
PURGE_CRASH_LOGS="${PURGE_CRASH_LOGS:-1}"
TRIM_APP_CACHES="${TRIM_APP_CACHES:-1}"
DISABLE_BACKGROUND_BLE_SCAN="${DISABLE_BACKGROUND_BLE_SCAN:-1}"
DISABLE_BACKGROUND_WIFI_SCAN="${DISABLE_BACKGROUND_WIFI_SCAN:-1}"
WHITELIST_AUDIO_APPS="${WHITELIST_AUDIO_APPS:-1}"
ENHANCED_CPU_RESPONSIVENESS="${ENHANCED_CPU_RESPONSIVENESS:-1}"
SHOW_NOTIFICATIONS="${SHOW_NOTIFICATIONS:-1}"
TUNE_VFS_CACHE="${TUNE_VFS_CACHE:-1}"
VFS_CACHE_PRESSURE="${VFS_CACHE_PRESSURE:-50}"
DISABLE_SCHED_STATS="${DISABLE_SCHED_STATS:-1}"
TUNE_STAT_INTERVAL="${TUNE_STAT_INTERVAL:-1}"
STAT_INTERVAL_SEC="${STAT_INTERVAL_SEC:-10}"
ENABLE_TCP_BBR="${ENABLE_TCP_BBR:-1}"
DISABLE_BT_SNOOP_LOG="${DISABLE_BT_SNOOP_LOG:-1}"
TUNE_WIFI_SLEEP="${TUNE_WIFI_SLEEP:-1}"
RESTRICT_SAMSUNG_TELEMETRY="${RESTRICT_SAMSUNG_TELEMETRY:-1}"
DEEP_BLOAT_HIBERNATION="${DEEP_BLOAT_HIBERNATION:-1}"
BOOST_AUDIO_PRIORITY="${BOOST_AUDIO_PRIORITY:-1}"
PREVENT_LOCKSCREEN_AUDIO_STUTTER="${PREVENT_LOCKSCREEN_AUDIO_STUTTER:-1}"
TUNE_ZRAM_ALGORITHM="${TUNE_ZRAM_ALGORITHM:-1}"
ZRAM_COMP_ALGORITHM="${ZRAM_COMP_ALGORITHM:-zstd}"
FORCE_120HZ_REFRESH="${FORCE_120HZ_REFRESH:-0}"
BYPASS_CHARGING_ENABLED="${BYPASS_CHARGING_ENABLED:-0}"
VULKAN_UI_ENABLED="${VULKAN_UI_ENABLED:-1}"
SF_ZERO_LATENCY_LATCHING="${SF_ZERO_LATENCY_LATCHING:-1}"
TUNE_UFS_SCHEDULER="${TUNE_UFS_SCHEDULER:-1}"
SQLITE_VACUUM_ENABLED="${SQLITE_VACUUM_ENABLED:-1}"
TOUCH_BOOST_ENABLED="${TOUCH_BOOST_ENABLED:-1}"
DISABLE_LE_AUDIO="${DISABLE_LE_AUDIO:-1}"

# Notification helpers (Live NowBar / Dynamic Island notification while running, static on finish)
notify_live() {
    [ "$SHOW_NOTIFICATIONS" != "1" ] && return 0
    cmd notification post -S media -i @android:drawable/stat_notify_sync -t "Vertex" "samsung_optimizer" "$1" >/dev/null 2>&1
}

notify_done() {
    [ "$SHOW_NOTIFICATIONS" != "1" ] && return 0
    cmd notification post -i @android:drawable/ic_dialog_info -t "Vertex" "samsung_optimizer" "$1" >/dev/null 2>&1
}

# Determine log file path
if [ -d "/data/adb/modules/samsung_daily_optimizer" ]; then
    LOG_FILE="/data/adb/modules/samsung_daily_optimizer/optimizer.log"
elif [ -w "$SCRIPT_DIR" ]; then
    LOG_FILE="$SCRIPT_DIR/optimizer.log"
else
    LOG_FILE="/data/local/tmp/samsung_daily_optimizer.log"
fi

# Log rotation: keep last 300 lines if larger than 256KB
if [ -f "$LOG_FILE" ]; then
    FILE_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$FILE_SIZE" -gt 262144 ]; then
        tail -n 300 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

log() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE" 2>/dev/null
}

log "======================================================"
log "Starting Vertex Optimization..."
log "======================================================"

notify_live "⚡ Starting daily optimization routine..."

# 1. RAM Plus Configuration
log "Configuring RAM Plus settings..."
notify_live "⚙️ Tuning RAM Plus & kernel parameters..."
if [ "$RAM_PLUS_ENABLED" = "0" ] || [ "$RAM_PLUS_SIZE" = "0" ]; then
    settings put global ram_expand_size 0 2>/dev/null && log "  [OK] RAM Plus DISABLED (0 MB)" || log "  [WARN] Failed to disable RAM Plus"
else
    settings put global ram_expand_size "$RAM_PLUS_SIZE" 2>/dev/null && log "  [OK] RAM Plus set to ${RAM_PLUS_SIZE} MB" || log "  [WARN] Failed to set RAM Plus"
fi

# 2. Kernel VM & Swappiness Tuning
if [ "$TUNE_SWAPPINESS" = "1" ]; then
    log "Tuning kernel VM parameters..."
    if [ -w /proc/sys/vm/swappiness ]; then
        echo "$SWAPPINESS_VALUE" > /proc/sys/vm/swappiness 2>/dev/null && log "  [OK] Kernel swappiness set to $SWAPPINESS_VALUE"
    fi
    if [ -w /proc/sys/vm/dirty_background_ratio ]; then
        echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null
    fi
    if [ -w /proc/sys/vm/dirty_ratio ]; then
        echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null
    fi
    if [ "$TUNE_VFS_CACHE" = "1" ] && [ -w /proc/sys/vm/vfs_cache_pressure ]; then
        echo "$VFS_CACHE_PRESSURE" > /proc/sys/vm/vfs_cache_pressure 2>/dev/null && log "  [OK] VFS cache pressure set to $VFS_CACHE_PRESSURE"
    fi
    if [ "$DISABLE_SCHED_STATS" = "1" ] && [ -w /proc/sys/kernel/sched_schedstats ]; then
        echo 0 > /proc/sys/kernel/sched_schedstats 2>/dev/null && log "  [OK] Kernel scheduler statistics disabled"
    fi
    if [ "$TUNE_STAT_INTERVAL" = "1" ] && [ -w /proc/sys/vm/stat_interval ]; then
        echo "$STAT_INTERVAL_SEC" > /proc/sys/vm/stat_interval 2>/dev/null && log "  [OK] VM stat interval set to ${STAT_INTERVAL_SEC}s"
    fi
fi

# 3. Flash Storage Read-Ahead & UFS 4.0 Scheduler Tuning
if [ "$TUNE_READ_AHEAD" = "1" ]; then
    log "Optimizing flash storage read-ahead queue..."
    for q in /sys/block/sd*/queue/read_ahead_kb /sys/block/nvme*/queue/read_ahead_kb; do
        if [ -w "$q" ]; then
            echo "$READ_AHEAD_KB" > "$q" 2>/dev/null
        fi
    done
    log "  [OK] Block read-ahead set to ${READ_AHEAD_KB} KB"
fi

if [ "$TUNE_UFS_SCHEDULER" = "1" ]; then
    log "Optimizing UFS storage queue schedulers & merge limits..."
    for q in /sys/block/sd*/queue /sys/block/nvme*/queue; do
        [ -d "$q" ] || continue
        if grep -q "none" "$q/scheduler" 2>/dev/null; then
            echo "none" > "$q/scheduler" 2>/dev/null
        elif grep -q "mq-deadline" "$q/scheduler" 2>/dev/null; then
            echo "mq-deadline" > "$q/scheduler" 2>/dev/null
        fi
        [ -w "$q/nomerges" ] && echo 2 > "$q/nomerges" 2>/dev/null
        [ -w "$q/add_random" ] && echo 0 > "$q/add_random" 2>/dev/null
        [ -w "$q/iostats" ] && echo 0 > "$q/iostats" 2>/dev/null
    done
    log "  [OK] UFS I/O scheduler set to zero-overhead queueing"
fi

# 4. Wireless & Audio Stability (Reduce 2.4GHz interference)
log "Configuring wireless radio scans and Doze whitelists..."
notify_live "📶 Stabilizing wireless radio & audio streaming..."
if [ "$DISABLE_BACKGROUND_BLE_SCAN" = "1" ]; then
    settings put global ble_scan_always_enabled 0 2>/dev/null && log "  [OK] Background BLE scanning disabled"
    settings put system nearby_scanning_enabled 0 2>/dev/null && log "  [OK] Samsung nearby device scanning disabled"
fi
if [ "$DISABLE_BACKGROUND_WIFI_SCAN" = "1" ]; then
    settings put global wifi_scan_always_enabled 0 2>/dev/null && log "  [OK] Background Wi-Fi scanning disabled"
fi

if [ "$WHITELIST_AUDIO_APPS" = "1" ]; then
    TARGET_PKGS="com.samsung.accessory.budsunitemgr com.samsung.accessory.paranmgr com.google.android.apps.youtube.music com.metrolist.music com.spotify.music"
    for pkg in $TARGET_PKGS; do
        if pm list packages 2>/dev/null | grep -q "$pkg"; then
            if dumpsys deviceidle whitelist 2>/dev/null | grep -q "$pkg"; then
                log "  [SKIP] $pkg already in Doze whitelist"
            else
                cmd deviceidle whitelist "+$pkg" 2>/dev/null && log "  [ADDED] $pkg added to Doze whitelist"
            fi
        fi
    done
fi

if [ "$ENABLE_TCP_BBR" = "1" ] && [ -w /proc/sys/net/ipv4/tcp_congestion_control ]; then
    if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        echo "bbr" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null && log "  [OK] TCP congestion control set to BBR"
    else
        CURRENT_TCP=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)
        log "  [INFO] TCP congestion algorithm: $CURRENT_TCP"
    fi
fi

if [ "$DISABLE_BT_SNOOP_LOG" = "1" ]; then
    settings put global bluetooth_btsnoop_default_mode disabled 2>/dev/null
    setprop persist.bluetooth.btsnoopenable false 2>/dev/null
    log "  [OK] Bluetooth HCI snoop logging disabled"
fi

if [ "$TUNE_WIFI_SLEEP" = "1" ]; then
    settings put global wifi_sleep_policy 2 2>/dev/null && log "  [OK] Wi-Fi sleep policy set to never sleep"
fi

# 5. Samsung Enhanced CPU Responsiveness
if [ "$ENHANCED_CPU_RESPONSIVENESS" = "1" ]; then
    settings put global sem_enhanced_cpu_responsiveness 1 2>/dev/null && log "  [OK] Enhanced CPU responsiveness enabled"
fi

# 6. Samsung Diagnostics, AR Zone & Bloat Deep Hibernation
if [ "$RESTRICT_SAMSUNG_TELEMETRY" = "1" ] || [ "$DEEP_BLOAT_HIBERNATION" = "1" ]; then
    log "Restricting Samsung diagnostic, AR Zone, and bloat services..."
    notify_live "🛡️ Hibernating Samsung diagnostic & background bloat daemons..."
    BLOAT_PKGS="com.sec.android.diagmonagent com.samsung.android.survey.service com.samsung.android.ipsgeofence com.samsung.android.visionarapps com.samsung.android.aremoji com.samsung.android.aremojieditor com.samsung.android.livestickers com.samsung.android.stickercenter com.samsung.android.app.camera.sticker.facearavatar.preload com.samsung.android.rubin.app com.samsung.android.kidsinstaller com.sec.android.app.billing com.samsung.android.spaymini com.samsung.android.bixby.agent.dummy"
    for bpkg in $BLOAT_PKGS; do
        if pm list packages 2>/dev/null | grep -q "$bpkg"; then
            am set-standby-bucket "$bpkg" restricted 2>/dev/null
            cmd appops set "$bpkg" RUN_IN_BACKGROUND ignore 2>/dev/null
            log "  [RESTRICTED] $bpkg placed into restricted standby"
        fi
    done
fi

# 7. Crash Logs & Stale Cache Cleanup
if [ "$PURGE_CRASH_LOGS" = "1" ]; then
    log "Purging crash dumps, ANR traces, and dropbox logs..."
    notify_live "🧹 Purging crash logs & trimming app caches..."
    rm -f /data/anr/* 2>/dev/null
    rm -f /data/tombstones/* 2>/dev/null
    rm -f /data/system/dropbox/* 2>/dev/null
    log "  [OK] Stale ANRs, tombstones, and crash reports cleared"
fi

if [ "$TRIM_APP_CACHES" = "1" ]; then
    log "Trimming system and app caches..."
    pm trim-caches 4096M >/dev/null 2>&1 && log "  [OK] Dead caches trimmed"
fi

# 8. Kernel Memory Compaction & Storage Trim
log "Executing kernel memory maintenance and storage trim..."
notify_live "💾 Compacting kernel memory & running fstrim..."
sync
if [ -w /proc/sys/vm/compact_memory ]; then
    echo 1 > /proc/sys/vm/compact_memory 2>/dev/null && log "  [OK] Kernel memory compacted"
fi
if [ -w /proc/sys/vm/drop_caches ]; then
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null && log "  [OK] Inactive page cache dropped"
fi

fstrim -v /data 2>/dev/null | while read -r line; do log "  [TRIM] /data: $line"; done
fstrim -v /cache 2>/dev/null | while read -r line; do log "  [TRIM] /cache: $line"; done

# 9. Safe Selective ART AOT / Profile Compilation
# NOTE: com.android.systemui is strictly excluded to prevent breaking Dynamic Island / Xposed
log "Running selective ART profile compilation (excluding SystemUI)..."
notify_live "🚀 Profile compiling apps (Speed-profile)..."
COMPILE_PKGS="com.sec.android.app.launcher com.android.bluetooth com.google.android.apps.youtube.music com.metrolist.music com.samsung.accessory.budsunitemgr"
for pkg in $COMPILE_PKGS; do
    if pm list packages 2>/dev/null | grep -q "$pkg"; then
        log "  Compiling $pkg (speed-profile)..."
        cmd package compile -m speed-profile "$pkg" >/dev/null 2>&1 && log "  [OK] $pkg compiled successfully" || log "  [WARN] Failed to compile $pkg"
    fi
done

# 10. Real-Time Audio & Bluetooth Thread Priority Boost
# Prevents audio thread starvation, screen-lock stutters, and L/R earbud desync
if [ "$BOOST_AUDIO_PRIORITY" = "1" ]; then
    log "Boosting Bluetooth, AudioFlinger, SoundAlive, and Exynos Audio HAL priorities..."
    notify_live "🎧 Prioritizing audio HAL & Bluetooth streaming threads..."
    AUDIO_DAEMONS="audioserver secaudiohalaidl android.hardware.audio.service com.android.bluetooth com.sec.android.app.soundalive android.hardware.bluetooth@1.1-service-qti"
    for daemon in $AUDIO_DAEMONS; do
        for apid in $(pidof "$daemon" 2>/dev/null); do
            renice -n -16 -p "$apid" >/dev/null 2>&1
            if [ -d "/proc/$apid/task" ]; then
                for atid in /proc/"$apid"/task/*; do
                    tid_num=$(basename "$atid")
                    [ -d /dev/cpuset/foreground-boost ] && echo "$tid_num" > /dev/cpuset/foreground-boost/tasks 2>/dev/null
                    [ -d /dev/cpuset/top-app ] && echo "$tid_num" > /dev/cpuset/top-app/tasks 2>/dev/null
                done
            fi
        done
    done
    log "  [OK] Audio HAL (secaudiohalaidl), SoundAlive, and Bluetooth pinned to performance cpusets"
fi

# 10b. Lockscreen Audio Collision Guard
# Disables lockscreen sound effect to prevent AudioFlinger PCM stream re-negotiation & 1-second stutter on screen lock
if [ "$PREVENT_LOCKSCREEN_AUDIO_STUTTER" = "1" ]; then
    settings put system lockscreen_sounds_enabled 0 2>/dev/null
    log "  [OK] Lockscreen sound effect disabled to prevent Bluetooth stream collision on lock"
fi

# 11. ZRAM Compression Algorithm Engine Tuning
# One UI/Samsung RAM Plus can be actively using zram0 and its writeback backend.
# Never swapoff/reset/recreate an initialized zram0 from a live daily optimizer.
# Keep ZSTD support available for an uninitialized device only; otherwise
# defer the algorithm choice safely and leave all other tuning unchanged.
if [ "$TUNE_ZRAM_ALGORITHM" = "1" ] && [ -r /sys/block/zram0/comp_algorithm ]; then
    CURRENT_ALG=$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' /sys/block/zram0/comp_algorithm 2>/dev/null)
    TARGET_ALG="${ZRAM_COMP_ALGORITHM:-zstd}"
    ZRAM_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null)
    ZRAM_SIZE="${ZRAM_SIZE:-unknown}"

    if [ "$CURRENT_ALG" = "$TARGET_ALG" ]; then
        log "  [OK] ZRAM compression already active: [$CURRENT_ALG]"
    elif [ "$ZRAM_SIZE" = "0" ] && ! grep -q 'zram0' /proc/swaps 2>/dev/null; then
        # Kernel permits selecting the primary compressor before setting disksize.
        # Do NOT initialize/mkswap/swapon here; leave that to Samsung init.
        if grep -qw "$TARGET_ALG" /sys/block/zram0/comp_algorithm 2>/dev/null; then
            if echo "$TARGET_ALG" > /sys/block/zram0/comp_algorithm 2>/dev/null; then
                NEW_ALG=$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' /sys/block/zram0/comp_algorithm 2>/dev/null)
                log "  [OK] Prepared uninitialized ZRAM compressor: [$NEW_ALG]"
            else
                log "  [WARN] Could not select $TARGET_ALG before ZRAM initialization"
            fi
        else
            log "  [INFO] Target $TARGET_ALG not listed in kernel ZRAM compressors; keeping [$CURRENT_ALG]"
        fi
    else
        log "  [GUARD] ZRAM initialized (size=$ZRAM_SIZE, compressor=$CURRENT_ALG); requested $TARGET_ALG deferred."
        log "  [GUARD] Preserving Samsung RAM Plus/writeback; no swapoff/reset/mkswap/swapon."
    fi
fi

# 12. Display Smooth Scroll Lock (120Hz Force)
if [ "$FORCE_120HZ_REFRESH" = "1" ]; then
    settings put system min_refresh_rate 120.0 2>/dev/null
    settings put system peak_refresh_rate 120.0 2>/dev/null
    log "  [OK] Display minimum refresh rate locked to 120Hz (zero micro-stutter)"
fi

if [ "$BYPASS_CHARGING_ENABLED" = "1" ]; then
    echo 1 > /sys/class/power_supply/battery/batt_slate_mode 2>/dev/null || echo 0 > /sys/class/power_supply/battery/charging_enabled 2>/dev/null
    log "  [OK] Bypass charging mode maintained (battery charging stopped)"
fi

# 12. Force Classic Bluetooth A2DP (Disable LE Audio Unicast/Broadcast)
if [ "$DISABLE_LE_AUDIO" = "1" ]; then
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
    log "  [OK] Force Classic Bluetooth active (LE Audio disabled for zero stutter)"
fi

# 13. Vulkan Skia UI & SurfaceFlinger Zero-Latency Frame Latching
if [ "$VULKAN_UI_ENABLED" = "1" ]; then
    setprop debug.hwui.renderer skiavk
    log "  [OK] HWUI UI renderer set to SkiaVK (Vulkan hardware acceleration)"
fi
if [ "$SF_ZERO_LATENCY_LATCHING" = "1" ]; then
    setprop debug.sf.latch_unsignaled 1
    setprop debug.sf.enable_gl_backpressure 0
    setprop debug.sf.early_phase_offset_ns 500000
    setprop debug.sf.early_app_phase_offset_ns 500000
    log "  [OK] SurfaceFlinger unsignaled frame latching enabled (zero input lag)"
fi

# 14. Touch Digitizer Sampling Boost & InputDispatcher Real-Time Scheduling
if [ "$TOUCH_BOOST_ENABLED" = "1" ]; then
    settings put system touch_sensitivity 1 2>/dev/null
    for spid in $(pidof system_server 2>/dev/null); do
        if [ -d "/proc/$spid/task" ]; then
            for tid in /proc/"$spid"/task/*; do
                t_comm=$(cat "$tid/comm" 2>/dev/null)
                case "$t_comm" in
                    *InputDispatcher*|*InputReader*)
                        t_num=$(basename "$tid")
                        renice -n -20 -p "$t_num" >/dev/null 2>&1
                        taskset -p -c 4-9 "$t_num" >/dev/null 2>&1 || taskset -p 0x3f0 "$t_num" >/dev/null 2>&1
                        [ -d /dev/cpuset/top-app ] && echo "$t_num" > /dev/cpuset/top-app/tasks 2>/dev/null
                        ;;
                esac
            done
        fi
    done
    log "  [OK] Touch sensitivity boosted & InputDispatcher prioritized"
fi

# 15. SQLite Database Defragmentation & Vacuum Pass
if [ "$SQLITE_VACUUM_ENABLED" = "1" ]; then
    SQLITE_BIN=""
    for bin in /system/bin/sqlite3 /system/xbin/sqlite3 /apex/com.android.runtime/bin/sqlite3 /data/adb/ksu/bin/sqlite3 /data/adb/magisk/sqlite3; do
        if [ -x "$bin" ]; then
            SQLITE_BIN="$bin"
            break
        fi
    done
    if [ -n "$SQLITE_BIN" ]; then
        log "Defragmenting & vacuuming user app SQLite databases with $SQLITE_BIN..."
        notify_live "🗄️ Defragmenting SQLite databases..."
        COUNT=0
        for db in $(find /data/data -maxdepth 4 -name "*.db" -type f 2>/dev/null | grep -v -E "google\.android\.gms|telephony\.registry"); do
            "$SQLITE_BIN" "$db" "PRAGMA wal_checkpoint(TRUNCATE); VACUUM;" >/dev/null 2>&1 && COUNT=$((COUNT + 1))
        done
        log "  [OK] Defragmented $COUNT SQLite databases (dead indexes cleared & pages compacted)"
    else
        log "  [INFO] sqlite3 binary not found in standard system paths, skipping database vacuum"
    fi
fi

log "======================================================"
log "Optimization completed successfully."
log "======================================================"

notify_done "✅ Optimization complete! Memory compacted & storage trimmed."
