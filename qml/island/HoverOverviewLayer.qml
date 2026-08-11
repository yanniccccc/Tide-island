import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property string currentTime: "00:00"
    property string currentDateLabel: "Mon, Jan 01"
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property bool showCondition: false

    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1 : 0.96

    Behavior on opacity {
        NumberAnimation { duration: root.showCondition ? 180 : 100; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: root.showCondition ? 220 : 120; easing.type: Easing.OutBack }
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentTime
            color: StyleTokens.textPrimaryBright
            font.family: root.heroFontFamily
            font.pixelSize: 38
            font.weight: Font.Bold
            font.letterSpacing: -1
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentDateLabel
            color: StyleTokens.textSecondary
            font.family: root.textFontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }
}
