import QtQuick
import QtQuick.Effects
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import IslandBackend

Item {
    id: root

    property var trayItem: null
    property var shellController: null
    property var parentWindow: null
    property bool showLabel: false
    property bool showPinOnHover: true
    property bool compact: false
    property string textFontFamily: ""
    property string iconFontFamily: ""
    readonly property bool hovered: itemMouseArea.containsMouse || pinMouseArea.containsMouse
    readonly property bool pinned: shellController && shellController.isTrayItemPinned
        ? shellController.isTrayItemPinned(trayItem)
        : false
    readonly property bool boostTranslucentIcon: trayItem
        && String(trayItem.id || "").toLowerCase() === "privateinternetaccess"
    readonly property string displayTitle: {
        if (!trayItem)
            return "Tray item";
        const tooltip = String(trayItem.tooltipTitle || "").trim();
        return tooltip !== "" ? tooltip : String(trayItem.title || trayItem.id || "Tray item");
    }

    signal invoked

    function openMenu() {
        if (!trayItem || !trayItem.hasMenu || !parentWindow)
            return false;
        const point = root.mapToItem(null, root.width / 2, root.height + 4);
        trayItem.display(parentWindow, Math.round(point.x), Math.round(point.y));
        return true;
    }

    function primaryAction() {
        if (!trayItem)
            return;
        if (trayItem.onlyMenu && openMenu()) {
            invoked();
            return;
        }
        trayItem.activate();
        invoked();
    }

    function togglePinned() {
        if (shellController && shellController.toggleTrayItemPinned)
            shellController.toggleTrayItemPinned(trayItem);
    }

    implicitWidth: compact ? 30 : 84
    implicitHeight: compact ? 30 : 70
    scale: itemMouseArea.pressed ? 0.91 : (hovered ? 1.04 : 1)

    Behavior on scale {
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.compact ? width / 2 : 18
        color: root.compact
            ? (root.hovered ? "#343840" : StyleTokens.transparent)
            : (root.hovered ? "#292c33" : "#1d2026")
        border.width: root.compact ? 0 : 1
        border.color: root.hovered ? "#414650" : "#292d34"

        Behavior on color { ColorAnimation { duration: 130 } }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - (root.compact ? 8 : 12)
        spacing: root.showLabel ? 6 : 0

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.compact ? 20 : 28
            height: width

            Item {
                id: iconComposite
                anchors.fill: parent

                IconImage {
                    anchors.fill: parent
                    source: root.trayItem ? root.trayItem.icon : ""
                    mipmap: true
                }

                Repeater {
                    model: root.boostTranslucentIcon ? 2 : 0

                    IconImage {
                        anchors.fill: parent
                        source: root.trayItem ? root.trayItem.icon : ""
                        mipmap: true
                    }
                }
            }

            MultiEffect {
                anchors.fill: iconComposite
                source: iconComposite
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: "#f0000000"
                shadowOpacity: 0.95
                shadowBlur: 0.65
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 1
                shadowScale: 1.12
            }

            Rectangle {
                visible: root.trayItem && root.trayItem.status === Status.NeedsAttention
                width: 7
                height: 7
                radius: 4
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: StyleTokens.accent
                border.width: 1
                border.color: "#111318"

                SequentialAnimation on opacity {
                    running: parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
                }
            }
        }

        Text {
            visible: root.showLabel
            width: parent.width
            text: root.displayTitle
            color: StyleTokens.textSecondary
            font.family: root.textFontFamily
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton)
                root.primaryAction();
            else if (mouse.button === Qt.RightButton) {
                if (!root.openMenu() && root.trayItem)
                    root.trayItem.secondaryActivate();
            } else if (mouse.button === Qt.MiddleButton && root.trayItem) {
                root.trayItem.secondaryActivate();
            }
        }

        onWheel: function(wheel) {
            if (!root.trayItem)
                return;
            const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
            const delta = horizontal ? wheel.angleDelta.x : wheel.angleDelta.y;
            root.trayItem.scroll(delta, horizontal);
            wheel.accepted = true;
        }
    }

    Rectangle {
        visible: root.showPinOnHover && root.hovered
        z: 3
        width: root.compact ? 14 : 20
        height: width
        radius: width / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.compact ? -4 : 3
        anchors.rightMargin: root.compact ? -4 : 3
        color: pinMouseArea.pressed ? "#505660" : "#373b44"
        border.width: 1
        border.color: "#555b66"

        Text {
            anchors.centerIn: parent
            text: root.pinned ? "×" : "●"
            color: root.pinned ? StyleTokens.textPrimary : StyleTokens.accent
            font.family: root.textFontFamily
            font.pixelSize: root.compact ? 10 : 11
            font.bold: true
        }

        MouseArea {
            id: pinMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: root.togglePinned()
        }
    }
}
