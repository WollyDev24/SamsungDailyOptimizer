# Changelog

All notable changes to the **Vertex** (formerly Samsung Daily Optimizer) project will be documented in this file.

---

## [v1.4.2 One UI 9 / ZRAM-safe community fix] - 2026-11-18

Original Vertex developer: Wolly (WollyDev24), https://github.com/WollyDev24/Vertex. Community fix: Lernik.

- Saved: Vulkan, SurfaceFlinger, Touch Boost, UFS, Bluetooth, RAM Plus setting, ZRAM, scheduler, and other Vertex features.
- Fixed: Dangerous re-creation of active ZRAM in optimizer.sh and via WebUI.
- Maintained old fix: the planner no longer mistakes the launch in the evening for missed optimization at 05:00.
- Diagnostics saved: the module still tries to record launch logs.

---

## [v1.4.2] - 2026-11-18

### ⚙️ Master Daemon & Reliability
* **Persistent 5:00 AM Master Switch**: Fixed master daemon state persistence across WebUI exits by syncing to both `localStorage` (`vtx_master`) and disk `config.prop` (`DAEMON_ENABLED=1`).
* **Robust PID & Process Detection**: Replaced brittle file-only PID lookup with multi-tier process table and `/proc` verification (`pgrep -f "sh .*/daemon\.sh"` and `/dev/vertex_daemon.pid`), preventing the toggle from falsely reverting to "Off" when the daemon is actively running.
* **Session Detachment via setsid**: Updated `start_daemon.sh` and `service.sh` to spawn background tasks using `setsid nohup` to prevent Android WebViews or session cleanups from terminating background processes.

---

## [v1.4.1] - 2026-11-18

### 🎧 Audio & Bluetooth
* **Force Classic Bluetooth (A2DP / Disable LE Audio)**: Added dedicated root system toggle (`DISABLE_LE_AUDIO=1`) using `resetprop` to disable the Bluetooth LE Audio BAP client and broadcast profiles (`bluetooth.profile.bap.unicast.client.enabled=false`). Completely stops Galaxy Buds from using bug-prone BLE isochronous streams and forces standard high-quality Classic Bluetooth A2DP (Samsung Scalable Codec) for 100% stutter-free listening.
* **Persistent WebUI State**: Fixed all 11 card toggles syncing synchronously via `localStorage` and `config.prop`, eliminating toggle resets on app exit.

---

## [v1.4] - 2026-11-17

### 🌋 Graphics & Touch Performance
* **SkiaVK Vulkan HWUI Rendering**: Enables Android's Vulkan rendering pipeline (`debug.hwui.renderer=skiavk`) on modern Adreno and Xclipse RDNA3 GPUs for native hardware acceleration, reduced CPU draw-call overhead, and buttery 120Hz UI transitions.
* **SurfaceFlinger Zero-Latency Frame Latching**: Implements unsignaled frame latching (`debug.sf.latch_unsignaled=1`, `enable_gl_backpressure=0`) allowing SurfaceFlinger to latch display buffers immediately without fence waits, eliminating visual stutter and input lag.
* **Touch Boost & Real-Time InputDispatcher**: Forces 240Hz digitizer touch sensitivity (`touch_sensitivity 1`) and elevates `InputDispatcher` and `InputReader` threads to real-time `nice -20` pinned to `top-app` performance cores.

### 🗄️ Storage & Database Optimization
* **SQLite Database Defragmentation & Vacuum**: Daily pass automatically compacts user app databases using `PRAGMA wal_checkpoint(TRUNCATE); VACUUM;`, reclaiming dead space and speeding up app launch times across browsers and messaging apps.
* **UFS 4.0 Queue Scheduler Tuning**: Configures flash block queues to zero-overhead scheduling (`none`/`mq-deadline`), disabling entropy pooling (`add_random=0`), I/O statistics overhead (`iostats=0`), and enabling aggressive merges (`nomerges=2`).

### 🛡️ Deep Bloat & Background Daemon Hibernation
* **15+ Samsung Daemons Restricted**: Hibernates resource-heavy background services into the Android `RESTRICTED` standby bucket (`am set-standby-bucket` & `appops RUN_IN_BACKGROUND ignore`), including AR Zone, Live Stickers, Rubin Core, Avatar preloads, and Bixby dummy agents, preserving battery life and RAM headroom.

### 🎨 Native One UI Dashboard Overhaul
* **Home Up Card Interface**: Redesigned all controls into One UI Home Up-style grid cards with instant 0ms optimistic UI toggle feedback and smooth micro-haptics.
* **Gesture-Dismissable Bottom Sheets**: Native bottom sheets for RAM Plus, ZRAM engine selection, system diagnostics, and terminal logs featuring touch velocity drag-to-dismiss physics.
* **System Bar Immersion**: Integrated edge-to-edge support with custom status bar clipping and native back navigation (`window.ksu.exit()` / back key simulation).
* **High-Speed Batched Polling**: Consolidated root shell metrics into a single unified `===VTX===` query, reducing query latency from ~3.5s to 200ms.

---

## [v1.3] - 2026-11-16

### 🚀 Performance & Display
* **ZRAM Compression Engine Switcher (`ZSTD`)**: Dynamically switch kernel ZRAM compression to **ZSTD** for ~35% higher compression ratio on modern ARMv9 CPUs, storing significantly more compressed pages in RAM before swapping. Includes 1-tap switching between **ZSTD**, **LZ4**, and stock **LZO-RLE** in the WebUI.
* **120Hz Smooth Scroll Lock**: Forces display minimum refresh rate to 120Hz (`min_refresh_rate 120.0`) to eradicate scrolling micro-stutters and aggressive 60Hz downclocking, with 1-tap toggle back to dynamic LTPO (1Hz-120Hz).

### 🔋 Battery & Hardware Longevity
* **Bypass Charging (Desk & Gaming Mode)**: Powers the device directly from the wall charger without routing charging current into the lithium battery (`batt_slate_mode`), preventing battery wear, overheating, and thermal throttling while gaming or docked.
* **Smart Screen-Off Aware Scheduler**: The daily 5:00 AM daemon now checks display wakefulness (`mWakefulness=Awake`). If the user is actively using the phone at 5:00 AM, maintenance is deferred up to 60 minutes until the screen is off and the device is idle, guaranteeing uninterrupted user interaction.

---

## [v1.2] - 2026-11-16

### 🏷️ Rebrand
* **Display Name**: Rebranded the module display name and UI to **Vertex** while preserving the internal module ID (`samsung_daily_optimizer`) for seamless updates and full backwards compatibility.

### 🎨 Material 3 WebUI Dashboard
* **Native ReZygisk / KernelSU Design**: Completely overhauled the Web UI to match the clean Material 3 dark aesthetic.
* **Top Working Status Banner**: Real-time operational indicator (`✓ Working`) with dynamic status checks.
* **Material 3 Bottom Navigation**: Smooth, single-page navigation with pill highlights across **Home**, **RAM Plus**, **Actions**, and **Logs**.
* **Categorized System Overview**: Displays live stats for Android/Kernel versions, RAM & ZRAM allocation, VFS cache parameters, network congestion, and audio radio guards.
* **Interactive Terminal Log Viewer**: Built-in activity log viewer with one-click refresh and automatic scroll-to-bottom.
* **Dual Execution Modes**: Seamlessly renders inside KernelSU / APatch / MMRL embedded WebViews, or in standalone mobile/desktop browsers via the integrated zero-dependency micro HTTP server on port `8888`.

### 🏝️ Live Dynamic Island & One UI NowBar Notifications
* **Ongoing Live Capsule**: Automatically posts persistent, animated progress notifications using `category=transport` and sync indicators during maintenance passes.
* **Real-Time Step Tracking**: Follow along as the optimizer tunes RAM Plus, stabilizes wireless radios, purges crash dumps, compacts memory, and runs ART compilations.
* **Clean Completion Transition**: Seamlessly converts the ongoing pill into a dismissable static notification without cluttering your notification shade.

### 🎧 Real-Time Audio Scheduling (Buds3 Pro Desync Fix)
* **Thread Priority Boost**: Automatically gives `com.android.bluetooth`, `audioserver`, and `android.hardware.audio.service` real-time scheduling priority (`nice -16`).
* **High-Performance CPUSet Migration**: Pins audio and Bluetooth encoder worker threads directly to the `top-app` performance CPU cores (`/dev/cpuset/top-app`).
* **Eliminates Buffer Underruns**: Prevents background widgets (KWGT), overlays, or system tasks from preempting 24-bit Samsung Seamless Codec (SSC) processing, stopping left/right earbud phase-drift and re-sync stutters.

### ⚡ Kernel & Memory Subsystem Tuning
* **VFS Cache Pressure Tuning (`vm.vfs_cache_pressure = 50`)**: Keeps directory structures and file inodes cached in RAM longer, accelerating app launch and switching speeds.
* **Disabled Scheduler Statistics (`kernel.sched_schedstats = 0`)**: Eliminates scheduler context-switch accounting overhead across all CPU cores.
* **Optimized VM Stat Interval (`vm.stat_interval = 10`)**: Reduces idle CPU timer wakeups from once per second to every 10 seconds to save battery during screen-off.

### 🌐 Network & Wireless Streaming Enhancements
* **TCP BBR Congestion Control**: Sets default TCP congestion control to Google's BBR algorithm for lower packet latency, reduced bufferbloat, and smoother lossless music streaming.
* **Disabled Bluetooth HCI Snoop Logging**: Silences `bluetooth_btsnoop_default_mode` to prevent background packet dumps to internal flash and eliminate audio thread I/O stalls.
* **Optimized Wi-Fi Sleep Policy (`wifi_sleep_policy = 2`)**: Prevents modem link degradation while streaming audio with the screen off.

### 🛡️ Samsung Diagnostics & Telemetry Hibernation
* **Restricted App Standby**: Automatically places telemetry and diagnostic services into the `RESTRICTED` app standby bucket (`cmd appops` & `am set-standby-bucket`):
  * `com.sec.android.diagmonagent` (Samsung Diagnostic Monitor)
  * `com.samsung.android.survey.service` (Customer Survey)
  * `com.samsung.android.ipsgeofence` (Background Geofence Beaconing)
* **Privacy & Battery**: Eliminates unwanted background modem wakeups without breaking Knox, Samsung Accounts, or system stability.

---

## [v1.1] - 2026-11-15

* Added interactive Volume key hardware selection during flashing for RAM Plus (0 GB vs 2 GB).
* Added standalone interactive CLI configuration utility (`configure.sh`).
* Added memory compaction (`compact_memory`) and flash storage trim (`fstrim`).
* Added background BLE and Wi-Fi always-scanning disablement.
* Added Doze sleep whitelisting for Buds managers and music streaming apps.
* Added selective ART profile compilation with explicit SystemUI exclusion to protect Dynamic Island / Xposed hooks.
* Added Samsung Enhanced CPU responsiveness toggle.
