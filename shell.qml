//@ pragma UseQApplication

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import IslandBackend

Scope {
    id: shellRoot

    readonly property bool screenRecordingActive: SystemServices.screenRecordingActive
    property bool focusEnabled: false
    property bool nightLightEnabled: false
    property bool shuttingDown: false
    property bool islandAutoHideRuntimeEnabled: true
    property var notificationObjects: ({})
    property var pinnedTrayIds: []

    readonly property var userConfig: UserConfig

    function trayItemKey(item) {
        if (!item)
            return "";
        const itemId = String(item.id || "").trim();
        return itemId !== "" ? itemId : String(item.title || "").trim();
    }

    function isTrayItemPinned(item) {
        const itemKey = trayItemKey(item);
        return itemKey !== "" && pinnedTrayIds.indexOf(itemKey) >= 0;
    }

    function toggleTrayItemPinned(item) {
        const itemKey = trayItemKey(item);
        if (itemKey === "")
            return;

        const nextIds = pinnedTrayIds.slice();
        const currentIndex = nextIds.indexOf(itemKey);
        if (currentIndex >= 0)
            nextIds.splice(currentIndex, 1);
        else
            nextIds.push(itemKey);

        pinnedTrayIds = nextIds;
        trayPinStore.pinnedIds = nextIds;
        trayPinsFile.writeAdapter();
    }

    function loadTrayPinsFromDisk() {
        let storedIds = [];
        try {
            const contents = trayPinsFile.text();
            if (contents.trim() !== "") {
                const parsed = JSON.parse(contents);
                storedIds = parsed && Array.isArray(parsed.pinnedIds) ? parsed.pinnedIds : [];
            }
        } catch (error) {
            storedIds = [];
        }

        const cleanIds = [];
        const seen = ({});
        for (let index = 0; index < storedIds.length; ++index) {
            const itemId = String(storedIds[index] || "").trim();
            if (itemId === "" || seen[itemId])
                continue;
            seen[itemId] = true;
            cleanIds.push(itemId);
        }
        pinnedTrayIds = cleanIds;
    }

    FileView {
        id: trayPinsFile
        path: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
            + "/tide-island/system-tray.json"
        preload: true
        watchChanges: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: trayPinStore
            property var pinnedIds: []
        }

        onLoaded: shellRoot.loadTrayPinsFromDisk()
        onFileChanged: shellRoot.loadTrayPinsFromDisk()
    }

    function forEachWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window)
                callback(window);
        }
    }

    function showNotificationAll(notification) {
        shellRoot.forEachWindow((window) => {
            if (window && window.showNotification)
                window.showNotification(notification, !focusEnabled);
        });
    }

    function trackNotification(notification) {
        if (!notification)
            return;

        notification.tracked = true;
        const nextObjects = Object.assign({}, notificationObjects);
        nextObjects[String(notification.id)] = notification;
        notificationObjects = nextObjects;

        notification.closed.connect(function() {
            shellRoot.forgetNotification(notification.id, notification);
        });
    }

    function forgetNotification(notificationId, expectedNotification) {
        const key = String(notificationId);
        if (expectedNotification && notificationObjects[key] !== expectedNotification)
            return;

        const nextObjects = Object.assign({}, notificationObjects);
        delete nextObjects[key];
        notificationObjects = nextObjects;

        shellRoot.forEachWindow((window) => {
            if (window && window.removeNotification)
                window.removeNotification(notificationId);
        });
    }

    function invokeNotification(notificationId) {
        const notification = notificationObjects[String(notificationId)];
        if (!notification)
            return;

        const actions = notification.actions || [];
        let action = null;
        for (let index = 0; index < actions.length; index++) {
            if (String(actions[index].identifier).toLowerCase() === "default") {
                action = actions[index];
                break;
            }
        }
        if (!action)
            return;

        action.invoke();
        notification.dismiss();
        forgetNotification(notificationId);
    }

    function dismissNotification(notificationId) {
        const notification = notificationObjects[String(notificationId)];
        if (notification)
            notification.dismiss();
        forgetNotification(notificationId);
    }

    function clearNotifications() {
        const ids = Object.keys(notificationObjects);
        for (let index = 0; index < ids.length; index++) {
            const notification = notificationObjects[ids[index]];
            if (notification)
                notification.dismiss();
        }
        notificationObjects = ({});
        shellRoot.forEachWindow((window) => {
            if (window && window.clearNotifications)
                window.clearNotifications();
        });
    }

    function anyOverviewOpen() {
        if (CompositorBackend.compositor === "niri")
            return false;

        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.overviewPhase !== "closed")
                return true;
        }

        return false;
    }

    function prepareOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.prepareOverview());
    }

    function cancelPreparedOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.cancelPreparedOverview());
    }

    function openOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.openOverview());
    }

    function closeOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.closeOverview());
    }

    function toggleOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        if (shellRoot.anyOverviewOpen())
            shellRoot.closeOverviewAll();
        else
            shellRoot.openOverviewAll();
    }

    function anyIslandShown() {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.autoHideTargetVisible)
                return true;
        }

        return false;
    }

    function showIslandAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.showIslandWindow)
                window.showIslandWindow();
        });
    }

    function hideIslandAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.hideIslandWindow)
                window.hideIslandWindow();
        });
    }

    function toggleIslandAll() {
        if (shellRoot.anyIslandShown())
            shellRoot.hideIslandAll();
        else
            shellRoot.showIslandAll();
    }

    function refreshIslandAutoHideAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.refreshAutoHideWindow)
                window.refreshAutoHideWindow();
        });
    }

    function refreshOverviewWallpaperCaches(wallpaperPath) {
        shellRoot.forEachWindow((window) => {
            if (window
                    && wallpaperPath !== undefined
                    && wallpaperPath !== null
                    && String(wallpaperPath) !== "") {
                window.wallpaperPickerActiveWallpaper = String(wallpaperPath);
            }
            if (window && window.prewarmWallpaperCache)
                window.prewarmWallpaperCache();
        });
    }

    function forFocusedWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        let fallbackWindow = null;
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && !fallbackWindow)
                fallbackWindow = window;
            if (window && window.monitorFocused) {
                callback(window);
                return;
            }
        }

        if (fallbackWindow)
            callback(fallbackWindow);
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            shellRoot.toggleOverviewAll();
        }

        function open() {
            shellRoot.openOverviewAll();
        }

        function close() {
            shellRoot.closeOverviewAll();
        }

        function refreshWallpaperCache() {
            shellRoot.refreshOverviewWallpaperCaches();
        }
    }

    IpcHandler {
        target: "island"

        function show() {
            shellRoot.showIslandAll();
        }

        function open() {
            shellRoot.showIslandAll();
        }

        function reveal() {
            shellRoot.showIslandAll();
        }

        function hide() {
            shellRoot.hideIslandAll();
        }

        function toggle() {
            shellRoot.toggleIslandAll();
        }

        function enableAutoHide() {
            shellRoot.islandAutoHideRuntimeEnabled = true;
            shellRoot.refreshIslandAutoHideAll();
        }

        function disableAutoHide() {
            shellRoot.islandAutoHideRuntimeEnabled = false;
            shellRoot.showIslandAll();
        }
    }

    IpcHandler {
        target: "tide"

        function showClock() {
            shellRoot.forFocusedWindow((window) => window.showClockWindow());
        }

        function showCustom() {
            shellRoot.forFocusedWindow((window) => window.showCustomInfoWindow());
        }

        function showLyrics() {
            shellRoot.forFocusedWindow((window) => window.showLyricsWindow());
        }

        function swipeRight() {
            shellRoot.forFocusedWindow((window) => window.swipeRightWindow());
        }

        function swipeLeft() {
            shellRoot.forFocusedWindow((window) => window.swipeLeftWindow());
        }

        function togglePlayer() {
            shellRoot.forFocusedWindow((window) => window.togglePlayerWindow());
        }

        function toggleControlCenter() {
            shellRoot.forFocusedWindow((window) => window.toggleControlCenterWindow());
        }

        function toggleNotificationCenter() {
            shellRoot.forFocusedWindow((window) => window.toggleNotificationCenterWindow());
        }

        function toggleWallpaperPicker() {
            shellRoot.forFocusedWindow((window) => window.toggleWallpaperPickerWindow());
        }

        function toggleApplicationLauncher() {
            shellRoot.forFocusedWindow((window) => window.toggleApplicationLauncherWindow());
        }

        function toggleSystemTray() {
            shellRoot.forFocusedWindow((window) => window.toggleSystemTrayWindow());
        }
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: false

        onNotification: function(notification) {
            shellRoot.trackNotification(notification);
            shellRoot.showNotificationAll(notification);
        }
    }

    Component.onDestruction: {
        shuttingDown = true;
    }

    Component.onCompleted: {
        SystemServices.ensureUserConfigAvailable();
        SystemServices.requestScreenRecordingSnapshot();
    }

    Variants {
        id: panelVariants

        model: Quickshell.screens

        DynamicIslandWindow {
            required property var modelData

            screen: modelData
            shellRootController: shellRoot
        }
    }
}
