import QtQuick
import Quickshell.Services.SystemTray
import IslandBackend

Item {
    id: root

    property var shellController: null
    property var parentWindow: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: false
    readonly property var trayItems: SystemTray.items.values
    readonly property int unpinnedCount: {
        let total = 0;
        for (let index = 0; index < trayItems.length; ++index) {
            const pinned = shellController && shellController.isTrayItemPinned
                ? shellController.isTrayItemPinned(trayItems[index]) : false;
            if (!pinned)
                ++total;
        }
        return total;
    }
    readonly property int rowCount: Math.max(1, Math.ceil(unpinnedCount / 4))
    readonly property real preferredHeight: Math.min(304, 70 + rowCount * 76)

    signal closeRequested

    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1 : 0.94

    Behavior on opacity { NumberAnimation { duration: showCondition ? 260 : 150 } }
    Behavior on scale {
        SpringAnimation {
            spring: 8
            damping: root.showCondition ? 0.43 : 0.76
            mass: 0.7
            epsilon: 0.007
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Item {
            width: parent.width
            height: 34

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "System Tray"
                color: StyleTokens.textPrimaryBright
                font.family: root.textFontFamily
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 102
                anchors.verticalCenter: parent.verticalCenter
                text: root.unpinnedCount === 1 ? "1 app" : root.unpinnedCount + " apps"
                color: StyleTokens.textMuted
                font.family: root.textFontFamily
                font.pixelSize: 11
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: closeMouse.containsMouse ? "#353941" : StyleTokens.transparent

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: StyleTokens.textSecondary
                    font.family: root.textFontFamily
                    font.pixelSize: 18
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.closeRequested()
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - 42

            Text {
                visible: root.unpinnedCount === 0
                anchors.centerIn: parent
                text: root.trayItems.length === 0
                    ? "No tray applications are running"
                    : "All tray applications are pinned"
                color: StyleTokens.textMuted
                font.family: root.textFontFamily
                font.pixelSize: 12
            }

            Flickable {
                visible: root.unpinnedCount > 0
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: trayFlow.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: trayFlow
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.trayItems

                        delegate: SystemTrayItemButton {
                            required property var modelData
                            readonly property bool itemPinned: root.shellController
                                && root.shellController.isTrayItemPinned
                                ? root.shellController.isTrayItemPinned(modelData)
                                : false

                            visible: !itemPinned
                            width: visible ? 84 : 0
                            height: visible ? 70 : 0
                            showLabel: true
                            showPinOnHover: true
                            trayItem: modelData
                            shellController: root.shellController
                            parentWindow: root.parentWindow
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }
                    }
                }
            }
        }
    }
}
