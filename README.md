# ⚡ Vertex (Samsung Daily Optimizer)

> **Keep your Samsung Galaxy fast, smooth, and stutter-free — automatically.**

Vertex is an automated performance module for Samsung Galaxy phones running One UI. Think of it as a **nightly pit crew** for your phone: while you sleep, it cleans out system junk, stops background micro-stutters, and keeps your phone feeling brand new.

Compatible with **KernelSU**, **Magisk**, **APatch**, and **Temproot**.

---

## 🌟 What Vertex Does

| What You Feel | How Vertex Does It |
|---|---|
| 🌋 **Vulkan UI Acceleration** | Renders One UI using high-performance Vulkan (`SkiaVK`) hardware acceleration instead of legacy OpenGL ES for maximum frame stability. |
| 🎯 **Instant Touch Response** | Boosts digitizer sampling and gives real-time priority to touch processing threads so taps register instantly without input lag. |
| 🧈 **Silky Smooth 120Hz Scrolling** | Stops One UI from awkwardly dropping down to 60Hz mid-scroll in apps like Twitter, Instagram, or Chrome (`120Hz Smooth Scroll`). |
| 📻 **Force Classic Bluetooth (A2DP)** | Disables bug-prone Bluetooth LE Audio streams (`bap.unicast.client.enabled=false`) to force reliable Classic A2DP audio (Samsung Scalable Codec) just like on Galaxy tablets. |
| 🎧 **No More Audio Stutter** | Stops your Galaxy Buds or Bluetooth headphones from cutting out when you lock your screen or walk around. |
| 🚀 **Instant App Switching** | Fixes Samsung's slow virtual memory ("RAM Plus") so your apps open quickly and stay in memory without lag. |
| 🗄️ **Defragmented App Databases** | Compacts and defragments SQLite databases overnight so apps open snappy and don't slow down over time. |
| ⚡ **Zero-Overhead Storage** | Tunes UFS 3.1 & 4.0 storage queues for maximum read/write throughput and minimum app launch delays. |
| ❄️ **Cool Gaming & Desk Mode** | Play games or charge at your desk without heating up the phone or wearing out the battery (*Bypass Charging*). |
| 🧹 **Automatic Daily Tune-Up** | Cleans out crash dumps, dead app caches, and organizes memory at 5:00 AM (only when you aren't using the phone!). |
| 🔋 **Deep Bloat Hibernation** | Puts over 15 unneeded Samsung background services (AR Zone, Live Stickers, Rubin app, diagnostic telemetry) to sleep. |

---

## 📲 How to Install

1. **Download**: Grab **`Vertex.zip`** from the [Latest Release](https://github.com/WollyDev24/Vertex/releases/latest).
2. **Flash**:
   - Open your root app (**KernelSU**, **Magisk**, or **APatch**).
   - Tap **Modules** ➜ **Install from storage** ➜ select `Vertex.zip`.
3. **Choose RAM Plus**:
   - During flashing, use your **Volume Up** button to pick **0 GB (Off)** — *Recommended for the fastest, smoothest experience!*
4. **Reboot** your phone. You're done! 🎉

*(Don't have root manager? Check the [Standalone Guide](#standalone-installation-no-flashing) below).*

---

## 🎨 The Dashboard

Vertex includes a built-in dashboard right inside KernelSU, APatch, or MMRL. Tap the **WebUI** button to open it:

- **Master Switch**: See when your next automatic 5:00 AM tune-up is scheduled, or run one right now.
- **Vulkan UI Card**: Native Vulkan hardware acceleration (`SkiaVK`) with SurfaceFlinger zero-latency latching.
- **Touch Boost Card**: 240Hz digitizer sensitivity and real-time scheduling for `InputDispatcher`.
- **RAM Plus Card**: Switch between 0 GB, 2 GB, 4 GB, or 8 GB with one tap.
- **ZRAM Engine Card**: Boost your memory capacity using high-speed compression (`ZSTD`).
- **Smooth Scroll Card**: Lock your screen to 120Hz for zero micro-stutter, or tap to restore standard dynamic LTPO.
- **Bypass Charging Card**: Power your phone directly from the charger without heating the battery while gaming.
- **Audio Guard Card**: Give real-time priority to Bluetooth and audio threads to prevent glitches.
- **Classic Bluetooth Card**: Force standard A2DP audio and disable LE Audio to eliminate stutter on Galaxy Buds.
- **Deep Hibernation Card**: Put 15+ background Samsung bloat daemons to sleep.
- **1-Tap Maintenance**: Run instant optimization, defragment SQLite databases, trim storage (`fstrim`), and compact memory on demand.

*To open in Samsung Internet or Chrome: run `su -c /data/adb/modules/samsung_daily_optimizer/start_webui.sh` and visit `http://127.0.0.1:8888`.*

---

## ❓ Frequently Asked Questions (FAQ)

### Will this delete my photos, messages, or apps?
**No, never.** Vertex only cleans temporary system crash dumps, dead app caches, and inactive memory buffers. Your personal data, photos, and files are 100% untouched.

### Why should I turn off RAM Plus (0 GB)?
Samsung's "RAM Plus" uses your phone's storage flash drive as extra memory. Because flash storage is much slower than real RAM, swapping data in and out causes micro-freezes and audio stutter. Modern Galaxy phones (8 GB / 12 GB RAM) run **significantly faster** with RAM Plus turned off.

### Does Vertex drain my battery?
**No.** Vertex does not stay running heavy tasks in the background. It schedules a quick 3-second cleanup at 5:00 AM, and if you are using your phone, it politely waits until the screen turns off. Hibernating Samsung diagnostic background trackers often *improves* standby battery life.

### Which devices are supported?
All modern Samsung Galaxy devices running **Any One Ui Version** (Galaxy S24, S23, S22, S21, Z Fold, Z Flip, A-series, and Galaxy Tabs).

---

## 🛠️ What happens under the hood

<details>
<summary><b>Click to expand kernel and sysctl tuning details</b></summary>

- **Vulkan HWUI Rendering**: `debug.hwui.renderer = skiavk` offloads UI rasterization directly to the Vulkan API.
- **Zero-Latency Frame Latching**: `debug.sf.latch_unsignaled = 1` and `debug.sf.enable_gl_backpressure = 0` eliminates fence wait stalls in SurfaceFlinger.
- **Touch & Input Real-Time Boost**: Forces digitizer sensitivity (`touch_sensitivity 1`) and prioritizes `InputDispatcher`/`InputReader` threads with `nice -20` assigned to `top-app` cpuset.
- **SQLite Database Optimization**: Nightly runs `PRAGMA wal_checkpoint(TRUNCATE); VACUUM;` on user application databases to reclaim fragmented pages and accelerate app cold starts.
- **UFS 4.0 Storage Tuning**: Sets flash block queue schedulers to `none` / `mq-deadline`, `nomerges = 2`, `add_random = 0`, and `iostats = 0`.
- **Deep Bloat Hibernation**: Restricts 15+ non-essential Samsung background services (AR Zone, Live Stickers, Rubin app, Bixby dummy agent) via `RESTRICTED` standby buckets.
- **ZRAM Switcher**: Supports `zstd`, `lz4`, and `lzo-rle`. On ARMv9 (Snapdragon 8 Gen 3 / Exynos 2400), `zstd` offers ~35% higher compression ratio.
- **Virtual Memory (VM)**: Lowers `vm.swappiness` to 60 (down from Samsung stock 160-180), tunes `dirty_ratio = 20`, and `dirty_background_ratio = 10`.
- **Dentry & Inode Caching**: `vm.vfs_cache_pressure = 50` keeps directory structures in RAM for faster cold app launches.
- **Timer Jitter**: Raises `vm.stat_interval = 10` and sets `kernel.sched_schedstats = 0` to reduce context switch accounting overhead.
- **Network & Audio**: Enables **TCP BBR** congestion control, disables BLE/Wi-Fi background polling collisions with 2.4 GHz Bluetooth, disables BT HCI snoop logs, sets `wifi_sleep_policy = 2`, and pins audio HAL/BT threads to Performance Cores (Cortex-A720/X4).
- **Safe Compilation**: Profile-guided ART compilation (`speed-profile`) strictly excludes `com.android.systemui` to prevent breaking Xposed/Vector hooks.
- **Config file**: Tunable via `/data/adb/modules/samsung_daily_optimizer/config.prop`.

</details>

---

## 💻 Standalone Installatio

If you use Temproot or prefer running Vertex directly from a terminal:

```bash
# 1. Copy folder to /data/local/tmp/SamsungDailyOptimizer
# 2. Start the 5:00 AM scheduler:
su -c /data/local/tmp/SamsungDailyOptimizer/start_daemon.sh

# Run optimization immediately:
su -c /data/local/tmp/SamsungDailyOptimizer/run_now.sh

# Interactive terminal menu:
su -c /data/local/tmp/SamsungDailyOptimizer/configure.sh
```

---

## 📜 License
Open-source under the [MIT License](LICENSE). Made for the Samsung Galaxy community.
