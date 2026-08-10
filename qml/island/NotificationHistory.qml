import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import IslandBackend
import "../controlcenter"

Item {
    id: root

    signal notificationActivated(var notificationId)
    signal notificationDismissed(var notificationId)

    readonly property var userConfig: UserConfig

    property var notificationModel: null
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property var notificationGroups: []
    property var expandedGroups: ({})

    readonly property real headerHeight: 28
    readonly property real listTopGap: 9
    readonly property real groupHeaderHeight: 34
    readonly property real cardHeight: 52
    readonly property real cardRadius: 16
    readonly property real cardGap: 7
    readonly property real groupGap: 9
    readonly property real stackOffset: 4
    readonly property int itemCount: notificationModel ? notificationModel.count : 0
    readonly property bool hasNotifications: itemCount > 0
    readonly property real preferredContentHeight: root.headerHeight
        + root.listTopGap
        + (root.hasNotifications ? groupList.contentHeight : 0)

    function normalizedAppKey(appName) {
        const normalized = String(appName || "Notification").trim().toLowerCase();
        return normalized !== "" ? normalized : "notification";
    }

    function rebuildGroups() {
        const source = notificationModel;
        if (!source) {
            notificationGroups = [];
            return;
        }

        const buckets = {};
        const orderedGroups = [];
        for (let index = 0; index < source.count; index++) {
            const row = source.get(index);
            const appName = String(row.appName || "Notification");
            const key = normalizedAppKey(appName);
            let group = buckets[key];
            if (!group) {
                group = {
                    key: key,
                    appName: appName,
                    entries: []
                };
                buckets[key] = group;
                orderedGroups.push(group);
            }

            group.entries.push({
                notificationId: row.notificationId,
                appName: appName,
                appIcon: String(row.appIcon || ""),
                actionable: row.actionable === true,
                summary: String(row.summary || "Notification"),
                body: String(row.body || "")
            });
        }

        notificationGroups = orderedGroups;
    }

    function groupExpanded(key, count) {
        return count <= 1 || expandedGroups[key] === true;
    }

    function toggleGroup(key) {
        const nextState = Object.assign({}, expandedGroups);
        nextState[key] = nextState[key] !== true;
        expandedGroups = nextState;
    }

    onNotificationModelChanged: rebuildGroups()

    Connections {
        target: root.notificationModel

        function onCountChanged() {
            Qt.callLater(root.rebuildGroups);
        }
    }

    Component.onCompleted: rebuildGroups()

    Item {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.headerHeight

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            spacing: 8

            Item {
                width: 18
                height: 18

                Shape {
                    width: 24
                    height: 24
                    scale: 0.75
                    transformOrigin: Item.TopLeft
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: StyleTokens.transparent
                        strokeColor: "#c5c5c8"
                        strokeWidth: 1.8
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        PathSvg {
                            path: "M3.7 8.2V3.9 M3.7 3.9H8 M3.7 3.9l3 3 M4 12a8.3 8.3 0 1 0 2.7-6.1"
                        }
                    }

                    ShapePath {
                        fillColor: StyleTokens.transparent
                        strokeColor: "#c5c5c8"
                        strokeWidth: 1.8
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        PathSvg {
                            path: "M12 7.5V12l3 1.8"
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                textFormat: Text.PlainText
                color: StyleTokens.textPrimaryBright
                font.pixelSize: 15
                font.family: root.textFontFamily
                font.weight: Font.Bold
                font.letterSpacing: 0.1
            }
        }
    }

    Item {
        id: listViewport

        anchors.top: header.bottom
        anchors.topMargin: root.listTopGap
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true

        Text {
            visible: !root.hasNotifications
            anchors.centerIn: parent
            text: "No notifications"
            textFormat: Text.PlainText
            color: StyleTokens.textMuted
            font.pixelSize: 10
            font.family: root.textFontFamily
            font.weight: Font.Medium
        }

        ListView {
            id: groupList

            anchors.fill: parent
            visible: root.hasNotifications
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            model: root.notificationGroups
            currentIndex: -1
            spacing: root.groupGap

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 180
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.96
                        to: 1
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            ScrollBar.vertical: ScrollBar {
                active: groupList.moving || groupList.dragging
                policy: ScrollBar.AsNeeded
                width: 3

                contentItem: Rectangle {
                    radius: 1.5
                    color: StyleTokens.textSubtle
                }

                background: Rectangle {
                    color: StyleTokens.transparent
                }
            }

            delegate: Item {
                id: groupDelegate

                required property var modelData
                readonly property bool expanded: root.groupExpanded(modelData.key, modelData.entries.length)
                readonly property int stackDepth: expanded
                    ? 0
                    : Math.min(2, Math.max(0, modelData.entries.length - 1))
                readonly property int visibleEntryCount: expanded ? modelData.entries.length : 1

                width: groupList.width
                height: root.groupHeaderHeight
                    + visibleEntryCount * root.cardHeight
                    + Math.max(0, visibleEntryCount - 1) * root.cardGap
                    + stackDepth * root.stackOffset

                Behavior on height {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: groupHeader

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: root.groupHeaderHeight

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 8
                        color: StyleTokens.cardFillActive

                        Text {
                            anchors.centerIn: parent
                            text: String(groupDelegate.modelData.appName || "N").charAt(0).toUpperCase()
                            color: StyleTokens.accent
                            font.pixelSize: 12
                            font.family: root.heroFontFamily
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.right: countBadge.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: groupDelegate.modelData.appName
                        textFormat: Text.PlainText
                        color: StyleTokens.textPrimary
                        font.pixelSize: 12
                        font.family: root.textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: countBadge

                        anchors.right: chevron.left
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(20, countLabel.implicitWidth + 10)
                        height: 18
                        radius: 9
                        color: StyleTokens.buttonFill

                        Text {
                            id: countLabel
                            anchors.centerIn: parent
                            text: groupDelegate.modelData.entries.length
                            color: StyleTokens.textSecondary
                            font.pixelSize: 9
                            font.family: root.textFontFamily
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        id: chevron

                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"
                        color: StyleTokens.textSecondary
                        font.pixelSize: 18
                        font.family: root.textFontFamily
                        rotation: groupDelegate.expanded ? 90 : 0
                        visible: groupDelegate.modelData.entries.length > 1

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: groupDelegate.modelData.entries.length > 1
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.toggleGroup(groupDelegate.modelData.key)
                    }
                }

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        required property int index

                        readonly property real layerInset: (index + 1) * root.stackOffset
                        readonly property bool layerPresent: index < Math.min(
                            2,
                            Math.max(0, groupDelegate.modelData.entries.length - 1)
                        )

                        x: layerInset
                        y: root.groupHeaderHeight + (groupDelegate.expanded ? 0 : layerInset)
                        z: groupDelegate.stackDepth - index
                        width: groupDelegate.width - layerInset * 2
                        height: root.cardHeight
                        radius: root.cardRadius
                        color: index === 0 ? StyleTokens.cardFillActive : StyleTokens.buttonFill
                        border.width: 1
                        border.color: index === 0 ? "#20ffffff" : "#12ffffff"
                        opacity: layerPresent && !groupDelegate.expanded
                            ? (index === 0 ? 0.92 : 0.72)
                            : 0

                        Behavior on y {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 170
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }

                Repeater {
                    model: groupDelegate.modelData.entries

                    delegate: Item {
                        id: notificationCard

                        required property var modelData
                        required property int index

                        readonly property bool shown: groupDelegate.expanded || index === 0
                        property bool dismissing: false

                        function dismissWithAnimation() {
                            if (dismissing)
                                return;
                            dismissing = true;
                            dismissTimer.restart();
                        }

                        x: dismissing ? 38 : 0
                        y: groupDelegate.expanded
                            ? root.groupHeaderHeight + index * (root.cardHeight + root.cardGap)
                            : root.groupHeaderHeight + Math.min(index, 2) * root.stackOffset
                        z: 5
                        width: groupDelegate.width
                        height: root.cardHeight
                        visible: opacity > 0.001
                        opacity: shown && !dismissing ? 1 : 0
                        scale: dismissing ? 0.94 : (shown ? 1 : 0.965)

                        Behavior on x {
                            NumberAnimation {
                                duration: 190
                                easing.type: Easing.InCubic
                            }
                        }

                        Behavior on y {
                            NumberAnimation {
                                duration: 220 + Math.min(notificationCard.index, 6) * 24
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: notificationCard.dismissing
                                    ? 180
                                    : 180 + Math.min(notificationCard.index, 6) * 18
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Timer {
                            id: dismissTimer
                            interval: 195
                            repeat: false
                            onTriggered: root.notificationDismissed(notificationCard.modelData.notificationId)
                        }

                        MatteSurface {
                            anchors.fill: parent
                            radius: root.cardRadius
                            hovered: cardMouse.containsMouse
                            pressed: cardMouse.pressed
                        }

                        Item {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            anchors.rightMargin: 40
                            anchors.top: parent.top
                            anchors.topMargin: 4
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6

                            Text {
                                anchors.top: parent.top
                                width: parent.width
                                height: 19
                                text: notificationCard.modelData.summary
                                textFormat: Text.PlainText
                                color: StyleTokens.textPrimaryBright
                                font.pixelSize: 14
                                font.family: root.textFontFamily
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 17
                                text: notificationCard.modelData.body
                                textFormat: Text.PlainText
                                color: StyleTokens.textSecondary
                                font.pixelSize: 12
                                font.family: root.textFontFamily
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cardMouse

                            anchors.fill: parent
                            enabled: notificationCard.shown && !notificationCard.dismissing
                            hoverEnabled: true
                            cursorShape: (!groupDelegate.expanded && groupDelegate.modelData.entries.length > 1)
                                || notificationCard.modelData.actionable
                                ? Qt.PointingHandCursor
                                : Qt.ArrowCursor
                            onClicked: {
                                if (!groupDelegate.expanded && groupDelegate.modelData.entries.length > 1)
                                    root.toggleGroup(groupDelegate.modelData.key);
                                else if (notificationCard.modelData.actionable)
                                    root.notificationActivated(notificationCard.modelData.notificationId);
                            }
                        }

                        Rectangle {
                            id: closeButton

                            z: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: 13
                            color: closeMouse.containsMouse ? StyleTokens.buttonFillHover : StyleTokens.buttonFill
                            opacity: cardMouse.containsMouse || closeMouse.containsMouse ? 1 : 0
                            scale: closeMouse.pressed ? 0.9 : 1

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 100
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -1
                                text: "×"
                                color: StyleTokens.textPrimaryBright
                                font.pixelSize: 17
                                font.family: root.textFontFamily
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: closeMouse

                                anchors.fill: parent
                                enabled: closeButton.opacity > 0.01
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    mouse.accepted = true;
                                    notificationCard.dismissWithAnimation();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
