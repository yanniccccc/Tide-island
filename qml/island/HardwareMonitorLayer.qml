import QtQuick
import IslandBackend

Item {
    id: root

    property var hardwareMonitor: null
    property var shellController: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: false
    readonly property real preferredHeight: 412

    signal closeRequested

    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1 : 0.94

    Behavior on opacity { NumberAnimation { duration: root.showCondition ? 240 : 140 } }
    Behavior on scale {
        SpringAnimation {
            spring: 8
            damping: root.showCondition ? 0.45 : 0.76
            mass: 0.7
            epsilon: 0.007
        }
    }

    function isPinned(statId) {
        return shellController && shellController.isHardwareStatPinned
            ? shellController.isHardwareStatPinned(statId) : false;
    }

    function togglePinned(statId) {
        if (shellController && shellController.toggleHardwareStatPinned)
            shellController.toggleHardwareStatPinned(statId);
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Item {
            width: parent.width
            height: 34

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "Hardware monitor"
                    color: StyleTokens.textPrimaryBright
                    font.family: root.textFontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    text: "Pin any reading to keep it beside the tray"
                    color: StyleTokens.textMuted
                    font.family: root.textFontFamily
                    font.pixelSize: 10
                }
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

        Grid {
            id: statGrid
            width: parent.width
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: root.hardwareMonitor ? root.hardwareMonitor.statIds : []

                delegate: Rectangle {
                    required property string modelData
                    readonly property real statValue: root.hardwareMonitor
                        ? root.hardwareMonitor.valueFor(modelData) : -1
                    readonly property bool temperature: modelData.indexOf("_temp") >= 0
                    width: (statGrid.width - statGrid.columnSpacing) / 2
                    height: 82
                    radius: 18
                    color: StyleTokens.module
                    border.width: root.isPinned(modelData) ? 1 : 0
                    border.color: StyleTokens.accent

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * Math.max(0, Math.min(1,
                            temperature ? delegateRoot.statValue / 100.0 : delegateRoot.statValue))
                        radius: parent.radius
                        color: StyleTokens.cardFillActive
                        opacity: 0.32
                    }

                    id: delegateRoot

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 11
                        text: root.hardwareMonitor ? root.hardwareMonitor.labelFor(modelData) : "Hardware"
                        color: StyleTokens.textMuted
                        font.family: root.textFontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 11
                        text: root.hardwareMonitor ? root.hardwareMonitor.textFor(modelData) : "--"
                        color: statValue >= 0 ? StyleTokens.textPrimaryBright : StyleTokens.textDisabled
                        font.family: root.textFontFamily
                        font.pixelSize: statValue >= 0 ? 20 : 12
                        font.bold: true
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        width: 28
                        height: 28
                        radius: 14
                        color: pinMouse.containsMouse || root.isPinned(modelData)
                            ? "#343840" : StyleTokens.transparent

                        Text {
                            anchors.centerIn: parent
                            text: root.isPinned(modelData) ? "×" : "●"
                            color: root.isPinned(modelData) ? StyleTokens.textPrimary : StyleTokens.accent
                            font.family: root.textFontFamily
                            font.pixelSize: root.isPinned(modelData) ? 15 : 9
                        }

                        MouseArea {
                            id: pinMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePinned(modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 64
            radius: 18
            color: StyleTokens.module

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 2 - 18
                spacing: 4

                Text {
                    width: parent.width
                    text: root.hardwareMonitor ? root.hardwareMonitor.cpuName : "Processor"
                    color: StyleTokens.textPrimary
                    elide: Text.ElideRight
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.hardwareMonitor
                        ? root.hardwareMonitor.bytesText(root.hardwareMonitor.memoryUsedKiB)
                            + " / " + root.hardwareMonitor.bytesText(root.hardwareMonitor.memoryTotalKiB)
                        : "Memory unavailable"
                    color: StyleTokens.textMuted
                    font.family: root.textFontFamily
                    font.pixelSize: 10
                }
            }

            Column {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 2 - 18
                spacing: 4

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: root.hardwareMonitor ? root.hardwareMonitor.gpuName : "Graphics"
                    color: StyleTokens.textPrimary
                    elide: Text.ElideLeft
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: root.hardwareMonitor && root.hardwareMonitor.swapTotalKiB > 0
                        ? "Swap " + root.hardwareMonitor.bytesText(root.hardwareMonitor.swapUsedKiB)
                        : "No swap in use"
                    color: StyleTokens.textMuted
                    font.family: root.textFontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}
