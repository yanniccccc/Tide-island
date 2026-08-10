import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property int workspaceId: 1
    property string displayText: "Workspace " + workspaceId
    property var configSource: null
    readonly property var activeConfig: configSource || userConfig
    property string textFontFamily: activeConfig.textFontFamily
    property bool showCondition: false
    property bool attentionMode: false
    property int textPixelSize: userConfig.bodyFontSize
    property string slideDirection: "none"
    property bool animateVisibility: true
    property real transitionProgress: 0
    property real horizontalPadding: 14
    property real hiddenLeftPadding: 16
    property real hiddenRightPadding: 16
    readonly property int activeWorkspaceIndex: workspaceId > 0
        ? ((workspaceId - 1) % 5) + 1
        : 1

    readonly property real clampedProgress: slideDirection === "right"
        ? Math.max(0, Math.min(1, transitionProgress))
        : (slideDirection === "left"
            ? Math.max(0, Math.min(1, -transitionProgress))
            : 0)
    readonly property real revealProgress: slideDirection === "none" ? 1 : (1 - clampedProgress)
    readonly property real textWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real centeredX: horizontalPadding
    readonly property real hiddenLeftX: -textWidth - hiddenLeftPadding
    readonly property real hiddenRightX: width + hiddenRightPadding
    readonly property real labelX: slideDirection === "right"
        ? centeredX + (hiddenRightX - centeredX) * clampedProgress
        : (slideDirection === "left"
            ? centeredX + (hiddenLeftX - centeredX) * clampedProgress
            : centeredX)

    anchors.fill: parent
    clip: true
    opacity: showCondition ? (animateVisibility ? revealProgress : 1) : 0

    Behavior on opacity {
        enabled: animateVisibility

        NumberAnimation {
            duration: showCondition ? 300 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Item {
        x: labelX
        width: textWidth
        height: parent.height
        opacity: revealProgress

        Row {
            id: indicatorRow
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: 5

                Rectangle {
                    required property int index
                    readonly property bool active: index + 1 === root.activeWorkspaceIndex

                    width: active ? 12 : 9
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: active
                        ? (root.attentionMode ? StyleTokens.accent : StyleTokens.textPrimaryBright)
                        : StyleTokens.transparent
                    border.width: active ? 0 : 1.5
                    border.color: StyleTokens.textSecondary
                    scale: active ? 1 : 0.92

                    Behavior on width {
                        SpringAnimation {
                            spring: 9
                            damping: 0.48
                            mass: 0.7
                            epsilon: 0.05
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Behavior on scale {
                        SpringAnimation {
                            spring: 9
                            damping: 0.45
                            mass: 0.7
                            epsilon: 0.01
                        }
                    }

                    Rectangle {
                        id: attentionRing

                        visible: parent.active && root.attentionMode
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        radius: 10
                        color: StyleTokens.transparent
                        border.width: 1.5
                        border.color: StyleTokens.accent

                        SequentialAnimation on scale {
                            running: attentionRing.visible
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0.62
                                to: 1.18
                                duration: 650
                                easing.type: Easing.OutCubic
                            }
                            PauseAnimation { duration: 120 }
                        }

                        SequentialAnimation on opacity {
                            running: attentionRing.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.9; to: 0; duration: 650 }
                            PauseAnimation { duration: 120 }
                        }
                    }
                }
            }
        }
    }
}
