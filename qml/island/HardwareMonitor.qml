import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool active: true
    property real cpuUsage: -1
    property real cpuTemperature: -1
    property real ramUsage: -1
    property real gpuUsage: -1
    property real gpuTemperature: -1
    property real memoryUsedKiB: -1
    property real memoryTotalKiB: -1
    property real swapUsedKiB: -1
    property real swapTotalKiB: -1
    property string cpuName: "Processor"
    property string gpuName: "Graphics"
    property string lastError: ""
    property real previousCpuTotal: -1
    property real previousCpuIdle: -1

    readonly property var statIds: [
        "cpu_usage", "cpu_temp", "ram_usage", "gpu_usage", "gpu_temp"
    ]

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function percentText(value) {
        return value >= 0 ? Math.round(value * 100) + "%" : "Unavailable";
    }

    function temperatureText(value) {
        return value >= 0 ? Math.round(value) + "°C" : "Unavailable";
    }

    function bytesText(kibibytes) {
        if (kibibytes < 0)
            return "Unavailable";
        const gibibytes = kibibytes / 1048576.0;
        if (gibibytes >= 1)
            return gibibytes.toFixed(gibibytes >= 10 ? 1 : 2) + " GiB";
        return (kibibytes / 1024.0).toFixed(0) + " MiB";
    }

    function labelFor(statId) {
        switch (statId) {
        case "cpu_usage": return "CPU";
        case "cpu_temp": return "CPU temp";
        case "ram_usage": return "RAM";
        case "gpu_usage": return "GPU";
        case "gpu_temp": return "GPU temp";
        default: return "Hardware";
        }
    }

    function componentLabelFor(statId) {
        if (String(statId).indexOf("cpu_") === 0)
            return "CPU";
        if (String(statId).indexOf("ram_") === 0)
            return "RAM";
        if (String(statId).indexOf("gpu_") === 0)
            return "GPU";
        return "HW";
    }

    function iconFor(statId) {
        switch (statId) {
        case "cpu_usage": return "󰻠";
        case "cpu_temp": return "";
        case "ram_usage": return "󰍛";
        case "gpu_usage": return "󰢮";
        case "gpu_temp": return "";
        default: return "•";
        }
    }

    function valueFor(statId) {
        switch (statId) {
        case "cpu_usage": return cpuUsage;
        case "cpu_temp": return cpuTemperature;
        case "ram_usage": return ramUsage;
        case "gpu_usage": return gpuUsage;
        case "gpu_temp": return gpuTemperature;
        default: return -1;
        }
    }

    function textFor(statId) {
        return statId.indexOf("_temp") >= 0
            ? temperatureText(valueFor(statId))
            : percentText(valueFor(statId));
    }

    function shortTextFor(statId) {
        const value = valueFor(statId);
        if (value < 0)
            return "--";
        return statId.indexOf("_temp") >= 0
            ? Math.round(value) + "°"
            : Math.round(value * 100) + "%";
    }

    function refresh() {
        if (active && !snapshotProcess.running)
            snapshotProcess.running = true;
    }

    function applySnapshot(line) {
        const fields = String(line || "").split("|");
        if (fields.length < 14 || fields[0] !== "TIDEHW")
            return;

        const total = Number(fields[1]);
        const idle = Number(fields[2]);
        if (previousCpuTotal >= 0 && total > previousCpuTotal) {
            const totalDelta = total - previousCpuTotal;
            const idleDelta = idle - previousCpuIdle;
            cpuUsage = clamp01((totalDelta - idleDelta) / totalDelta);
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;

        const totalMemory = Number(fields[3]);
        const availableMemory = Number(fields[4]);
        memoryTotalKiB = totalMemory > 0 ? totalMemory : -1;
        memoryUsedKiB = totalMemory > 0 ? Math.max(0, totalMemory - availableMemory) : -1;
        ramUsage = totalMemory > 0 ? clamp01(memoryUsedKiB / totalMemory) : -1;
        swapTotalKiB = Number(fields[5]) > 0 ? Number(fields[5]) : 0;
        swapUsedKiB = Math.max(0, swapTotalKiB - Math.max(0, Number(fields[6])));
        cpuTemperature = Number(fields[7]);
        gpuUsage = Number(fields[8]) >= 0 ? clamp01(Number(fields[8]) / 100.0) : -1;
        gpuTemperature = Number(fields[9]);
        cpuName = fields[10] || "Processor";
        gpuName = fields[11] || "Graphics";
        lastError = "";
    }

    Process {
        id: snapshotProcess
        running: false
        command: ["sh", "-c",
            "set -- $(awk '/^cpu / { t=0; for(i=2;i<=NF;i++) t+=$i; print t, $5+$6; exit }' /proc/stat)\n"
            + "cpu_total=${1:--1}; cpu_idle=${2:--1}\n"
            + "mem_total=$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo)\n"
            + "mem_avail=$(awk '/^MemAvailable:/ {print $2; exit}' /proc/meminfo)\n"
            + "swap_total=$(awk '/^SwapTotal:/ {print $2; exit}' /proc/meminfo)\n"
            + "swap_free=$(awk '/^SwapFree:/ {print $2; exit}' /proc/meminfo)\n"
            + "cpu_temp=-1\n"
            + "for zone in /sys/class/thermal/thermal_zone*; do\n"
            + "  [ -r \"$zone/type\" ] && [ -r \"$zone/temp\" ] || continue\n"
            + "  type=$(cat \"$zone/type\" 2>/dev/null)\n"
            + "  case \"$type\" in *x86_pkg_temp*|*cpu-thermal*|*cpu_thermal*) value=$(cat \"$zone/temp\" 2>/dev/null);; *) continue;; esac\n"
            + "  [ \"${value:-0}\" -gt 1000 ] 2>/dev/null && value=$((value / 1000))\n"
            + "  [ \"${value:--1}\" -gt \"$cpu_temp\" ] 2>/dev/null && cpu_temp=$value\n"
            + "done\n"
            + "for hw in /sys/class/hwmon/hwmon*; do\n"
            + "  [ -r \"$hw/name\" ] || continue; name=$(cat \"$hw/name\" 2>/dev/null)\n"
            + "  case \"$name\" in coretemp|k10temp|zenpower|cpu_thermal) ;; *) continue;; esac\n"
            + "  for sensor in \"$hw\"/temp*_input; do [ -r \"$sensor\" ] || continue; value=$(cat \"$sensor\" 2>/dev/null); value=$((value / 1000)); [ \"$value\" -gt \"$cpu_temp\" ] && cpu_temp=$value; done\n"
            + "done\n"
            + "gpu_usage=-1; gpu_temp=-1; gpu_name=Graphics\n"
            + "if command -v nvidia-smi >/dev/null 2>&1; then\n"
            + "  nv=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null | head -n 1)\n"
            + "  if [ -n \"$nv\" ]; then oldifs=$IFS; IFS=,; set -- $nv; IFS=$oldifs; gpu_usage=$(printf '%s' \"$1\" | tr -d ' '); gpu_temp=$(printf '%s' \"$2\" | tr -d ' '); gpu_name=$(printf '%s' \"$3\" | sed 's/^ *//;s/ *$//;s/|/ /g'); fi\n"
            + "fi\n"
            + "if [ \"$gpu_usage\" = -1 ]; then\n"
            + "  for busy in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r \"$busy\" ] || continue; gpu_usage=$(cat \"$busy\" 2>/dev/null); device=${busy%/gpu_busy_percent}; driver=$(basename \"$(readlink -f \"$device/driver\" 2>/dev/null)\"); [ -n \"$driver\" ] && gpu_name=\"$driver GPU\"; for sensor in \"$device\"/hwmon/hwmon*/temp1_input; do [ -r \"$sensor\" ] || continue; gpu_temp=$(cat \"$sensor\" 2>/dev/null); gpu_temp=$((gpu_temp / 1000)); break; done; break; done\n"
            + "fi\n"
            + "cpu_name=$(awk -F: '/model name|Hardware/ {sub(/^ +/,\"\",$2); gsub(/\\|/,\" \",$2); print $2; exit}' /proc/cpuinfo)\n"
            + "[ -n \"$cpu_name\" ] || cpu_name=Processor\n"
            + "printf 'TIDEHW|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|0|0\\n' \"$cpu_total\" \"$cpu_idle\" \"${mem_total:--1}\" \"${mem_avail:--1}\" \"${swap_total:-0}\" \"${swap_free:-0}\" \"$cpu_temp\" \"$gpu_usage\" \"$gpu_temp\" \"$cpu_name\" \"$gpu_name\""
        ]

        stdout: SplitParser {
            onRead: function(line) { root.applySnapshot(line); }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.lastError = "Hardware data could not be read.";
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
