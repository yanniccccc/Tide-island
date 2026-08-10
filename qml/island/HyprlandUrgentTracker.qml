import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var hyprMonitor: null
    property var pendingAddresses: []
    property int resolveAttempt: 0

    signal urgentWorkspace(int workspaceId)

    function normalizedAddress(address) {
        return String(address || "").trim().toLowerCase().replace(/^0x/, "");
    }

    function enqueueAddress(address) {
        const normalized = normalizedAddress(address);
        if (normalized === "" || pendingAddresses.indexOf(normalized) >= 0)
            return;

        const nextAddresses = pendingAddresses.slice();
        nextAddresses.push(normalized);
        pendingAddresses = nextAddresses;
        if (!resolveTimer.running) {
            resolveAttempt = 0;
            resolveTimer.start();
        }
    }

    function finishCurrentAddress() {
        const nextAddresses = pendingAddresses.slice(1);
        pendingAddresses = nextAddresses;
        resolveAttempt = 0;
        if (nextAddresses.length > 0)
            resolveTimer.restart();
    }

    function resolveCurrentAddress() {
        if (pendingAddresses.length === 0)
            return;

        const targetAddress = pendingAddresses[0];
        const toplevels = Hyprland.toplevels && Hyprland.toplevels.values
            ? Hyprland.toplevels.values : [];

        for (let index = 0; index < toplevels.length; ++index) {
            const toplevel = toplevels[index];
            if (!toplevel || normalizedAddress(toplevel.address) !== targetAddress)
                continue;

            const workspace = toplevel.workspace;
            const monitor = toplevel.monitor || (workspace ? workspace.monitor : null);
            if (!workspace || workspace.id < 1 || !root.hyprMonitor || !monitor) {
                finishCurrentAddress();
                return;
            }

            if (monitor.id === root.hyprMonitor.id) {
                const activeWorkspace = root.hyprMonitor.activeWorkspace;
                if (!activeWorkspace || activeWorkspace.id !== workspace.id)
                    root.urgentWorkspace(workspace.id);
            }

            finishCurrentAddress();
            return;
        }

        ++resolveAttempt;
        if (resolveAttempt < 6)
            resolveTimer.restart();
        else
            finishCurrentAddress();
    }

    Timer {
        id: resolveTimer
        interval: 70
        repeat: false
        onTriggered: root.resolveCurrentAddress()
    }

    Connections {
        target: Hyprland
        enabled: root.enabled

        function onRawEvent(event) {
            if (!event || String(event.name) !== "urgent")
                return;
            const args = event.parse(1);
            root.enqueueAddress(args.length > 0 ? args[0] : "");
        }
    }
}
