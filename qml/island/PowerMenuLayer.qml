import QtQuick
import IslandBackend

Item {
    id: root

    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: false
    readonly property real preferredHeight: 144
    readonly property var actions: [
        {
            "label": "Shut down",
            "glyph": "\uf011",
            "command": "poweroff",
            "hoverColor": StyleTokens.error
        },
        {
            "label": "Restart",
            "glyph": "\uf2f1",
            "command": "reboot",
            "hoverColor": StyleTokens.accent
        },
        {
            "label": "Sleep",
            "glyph": "\uf186",
            "command": "suspend",
            "hoverColor": "#b7a5ff"
        }
    ]

    signal closeRequested
    signal actionRequested(string action)

    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1 : 0.88
    transformOrigin: Item.Top

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 180 : 100
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        SpringAnimation {
            spring: 9
            damping: showCondition ? 0.48 : 0.78
            mass: 0.68
            epsilon: 0.007
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Item {
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Power menu"
                color: StyleTokens.textPrimaryBright
                font.family: root.textFontFamily
                font.pixelSize: 15
                font.bold: true
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: closeArea.containsMouse ? "#353941" : StyleTokens.transparent

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: StyleTokens.textSecondary
                    font.family: root.textFontFamily
                    font.pixelSize: 18
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Row {
            width: parent.width
            height: parent.height - 38
            spacing: 8

            Repeater {
                model: root.actions

                delegate: Item {
                    id: actionButton

                    required property var modelData
                    readonly property color hoverIconColor: modelData.hoverColor

                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        radius: 17
                        color: actionArea.pressed
                            ? "#414650"
                            : (actionArea.containsMouse ? "#30343d" : StyleTokens.module)

                        Behavior on color {
                            ColorAnimation { duration: StyleTokens.durationFast }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 13
                        text: actionButton.modelData.glyph
                        color: actionArea.containsMouse
                            ? actionButton.hoverIconColor
                            : StyleTokens.textPrimaryBright
                        font.family: root.iconFontFamily
                        font.pixelSize: 24

                        Behavior on color {
                            ColorAnimation { duration: StyleTokens.durationFast }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 11
                        text: actionButton.modelData.label
                        color: actionArea.containsMouse
                            ? StyleTokens.textPrimaryBright
                            : StyleTokens.textSecondary
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium

                        Behavior on color {
                            ColorAnimation { duration: StyleTokens.durationFast }
                        }
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionRequested(actionButton.modelData.command)
                    }
                }
            }
        }
    }
}
