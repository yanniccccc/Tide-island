import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property string currentTrack: ""
    property string currentArtist: ""
    property string currentArtUrl: ""
    property string textFontFamily: userConfig.textFontFamily
    property string iconFontFamily: userConfig.iconFontFamily
    property bool showCondition: false
    readonly property string metadataText: {
        const title = String(currentTrack || "").trim();
        const artist = String(currentArtist || "").trim();
        if (artist === "" || artist.toLowerCase() === "unknown")
            return title;
        return title + "  ·  " + artist;
    }
    readonly property real preferredWidth: Math.max(
        240,
        Math.min(520, metadataMetrics.advanceWidth + 72)
    )

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 160 : 90
            easing.type: Easing.OutCubic
        }
    }

    TextMetrics {
        id: metadataMetrics
        text: root.metadataText
        font.family: root.textFontFamily
        font.pixelSize: userConfig.bodyFontSize
        font.weight: Font.DemiBold
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Item {
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: "#292c33"
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: root.currentArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: albumArt.status !== Image.Ready
                    text: ""
                    color: StyleTokens.textPrimaryBright
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                }
            }
        }

        Text {
            width: parent.width - 36
            anchors.verticalCenter: parent.verticalCenter
            text: root.metadataText
            color: StyleTokens.textPrimaryBright
            font.family: root.textFontFamily
            font.pixelSize: userConfig.bodyFontSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.NoWrap
        }
    }
}
