import QtQuick
import QtQuick.Effects
import Quickshell.Services.SystemTray
import IslandBackend

Item {
    id: root

    property var shellController: null
    property var parentWindow: null
    property var hardwareMonitor: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property real railHeight: 34
    property bool showCondition: true
    property bool barMode: false
    property color adaptiveForeground: StyleTokens.textPrimaryBright
    readonly property var trayItems: SystemTray.items.values
    readonly property bool railHovered: dockHover.hovered
    readonly property int pinnedHardwareCount: shellController && shellController.pinnedHardwareStatIds
        ? shellController.pinnedHardwareStatIds.length : 0
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

    implicitWidth: dockRow.implicitWidth + 10
    implicitHeight: railHeight
    visible: showCondition
    opacity: showCondition ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 180 } }

    HoverHandler {
        id: dockHover
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: height / 2
        color: "#28000000"
        opacity: root.barMode ? 0 : (root.railHovered ? 0.72 : 0.52)

        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Rectangle {
        id: statusRail
        anchors.fill: parent
        radius: height / 2
        opacity: root.barMode ? 0 : 1
        border.width: 1
        border.color: root.railHovered ? "#30ffffff" : "#1cffffff"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.railHovered ? "#761d2026" : "#5c1a1d22"
            }
            GradientStop {
                position: 1
                color: root.railHovered ? "#82101217" : "#68101216"
            }
        }

        Behavior on border.color { ColorAnimation { duration: 160 } }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            height: 1
            radius: 1
            color: root.railHovered ? "#26ffffff" : "#18ffffff"

            Behavior on color { ColorAnimation { duration: 160 } }
        }
    }

    Row {
        id: dockRow
        z: 1
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        opacity: root.barMode ? 1 : (root.railHovered ? 0.96 : 0.72)

        Behavior on opacity { NumberAnimation { duration: 160 } }

        Repeater {
            model: root.shellController && root.shellController.pinnedHardwareStatIds
                ? root.shellController.pinnedHardwareStatIds : []

            delegate: Item {
                id: hardwareTag
                required property string modelData
                width: hardwareTagRow.implicitWidth + 8
                height: 30
                scale: statMouse.pressed ? 0.91 : (statMouse.containsMouse ? 1.04 : 1)

                Behavior on scale {
                    NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                }

                Item {
                    id: hardwareTagComposite
                    anchors.centerIn: parent
                    width: hardwareTagRow.implicitWidth
                    height: 20

                    Row {
                        id: hardwareTagRow
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.hardwareMonitor
                                ? root.hardwareMonitor.componentLabelFor(hardwareTag.modelData) : "HW"
                            color: root.barMode ? root.adaptiveForeground : StyleTokens.textPrimaryBright
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.hardwareMonitor
                                ? root.hardwareMonitor.shortTextFor(hardwareTag.modelData) : "--"
                            color: root.barMode ? root.adaptiveForeground : StyleTokens.textPrimaryBright
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }
                }

                MouseArea {
                    id: statMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.parentWindow && root.parentWindow.toggleHardwareMonitorWindow)
                            root.parentWindow.toggleHardwareMonitorWindow();
                    }
                }
            }
        }

        Item {
            visible: root.pinnedHardwareCount > 0
            width: 7
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 16
                radius: 1
                color: root.barMode
                    ? Qt.rgba(root.adaptiveForeground.r, root.adaptiveForeground.g,
                              root.adaptiveForeground.b, root.railHovered ? 0.34 : 0.24)
                    : (root.railHovered ? "#38ffffff" : "#24ffffff")

                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }

        Repeater {
            model: root.trayItems

            delegate: SystemTrayItemButton {
                required property var modelData
                readonly property bool itemPinned: root.shellController
                    && root.shellController.isTrayItemPinned
                    ? root.shellController.isTrayItemPinned(modelData)
                    : false

                visible: itemPinned
                width: visible ? 26 : 0
                height: 26
                compact: true
                compactIconSize: 16
                showPinOnHover: true
                trayItem: modelData
                shellController: root.shellController
                parentWindow: root.parentWindow
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                barMode: root.barMode
            }
        }

        Item {
            id: launcher
            width: 28
            height: 28
            scale: launcherMouse.pressed ? 0.9 : (launcherMouse.containsMouse ? 1.06 : 1)

            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.barMode
                    ? StyleTokens.transparent
                    : (launcherMouse.containsMouse || (root.parentWindow && root.parentWindow.systemTrayOpen)
                        ? "#343840" : StyleTokens.transparent)
                border.width: !root.barMode && root.parentWindow
                    && root.parentWindow.systemTrayOpen ? 1 : 0
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
                        width: 5
                        height: 5
                        radius: 2.5
                        color: root.barMode ? StyleTokens.transparent : "#c9000000"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 3
                            height: 3
                            radius: 1.5
                            color: root.barMode ? root.adaptiveForeground : StyleTokens.textPrimaryBright
                        }
                    }
                }
            }

            MultiEffect {
                anchors.fill: launcherGlyph
                source: launcherGlyph
                autoPaddingEnabled: true
                shadowEnabled: !root.barMode
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
