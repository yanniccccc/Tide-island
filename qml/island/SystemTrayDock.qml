import QtQuick
import QtQuick.Effects
import Quickshell.Services.SystemTray
import IslandBackend

Item {
    id: root

    property var shellController: null
    property var parentWindow: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    readonly property var trayItems: SystemTray.items.values
    readonly property int attentionCount: {
        let total = 0;
        for (let index = 0; index < trayItems.length; ++index) {
            const item = trayItems[index];
            const pinned = shellController && shellController.isTrayItemPinned
                ? shellController.isTrayItemPinned(item) : false;
            if (!pinned && item.status === Status.NeedsAttention)
                ++total;
        }
        return total;
    }

    implicitWidth: dockRow.implicitWidth
    implicitHeight: 34
    visible: showCondition
    opacity: showCondition ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 180 } }

    Row {
        id: dockRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
            model: root.trayItems

            delegate: SystemTrayItemButton {
                required property var modelData
                readonly property bool itemPinned: root.shellController
                    && root.shellController.isTrayItemPinned
                    ? root.shellController.isTrayItemPinned(modelData)
                    : false

                visible: itemPinned
                width: visible ? 30 : 0
                height: 30
                compact: true
                showPinOnHover: true
                trayItem: modelData
                shellController: root.shellController
                parentWindow: root.parentWindow
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
            }
        }

        Item {
            id: launcher
            width: 32
            height: 32
            scale: launcherMouse.pressed ? 0.9 : (launcherMouse.containsMouse ? 1.06 : 1)

            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: launcherMouse.containsMouse || (root.parentWindow && root.parentWindow.systemTrayOpen)
                    ? "#343840" : StyleTokens.transparent
                border.width: root.parentWindow && root.parentWindow.systemTrayOpen ? 1 : 0
                border.color: "#505660"

                Behavior on color { ColorAnimation { duration: 130 } }
            }

            Grid {
                id: launcherGlyph
                anchors.centerIn: parent
                columns: 2
                spacing: 3

                Repeater {
                    model: 4
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: "#c9000000"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 4
                            height: 4
                            radius: 2
                            color: StyleTokens.textPrimaryBright
                        }
                    }
                }
            }

            MultiEffect {
                anchors.fill: launcherGlyph
                source: launcherGlyph
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
                visible: root.attentionCount > 0
                width: 9
                height: 9
                radius: 5
                anchors.right: parent.right
                anchors.top: parent.top
                color: StyleTokens.accent
                border.width: 1
                border.color: "#111318"

                SequentialAnimation on scale {
                    running: parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.72; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
                }
            }

            MouseArea {
                id: launcherMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (root.parentWindow && root.parentWindow.toggleSystemTrayWindow)
                        root.parentWindow.toggleSystemTrayWindow();
                }
            }
        }
    }
}
