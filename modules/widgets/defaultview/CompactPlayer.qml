import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Item {
    id: compactPlayer

    required property MprisPlayer player
    required property bool notchHovered

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    property real position: player?.position ?? 0.0
    property real length: player?.length ?? 1.0
    property bool hasArtwork: (player?.trackArtUrl ?? "") !== ""
    property var playerColors: hasArtwork ? PlayerColors.getColorsForPlayer(player) : null

    Timer {
        running: compactPlayer.isPlaying
        interval: 1000
        repeat: true
        onTriggered: compactPlayer.player?.positionChanged()
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0
        color: Colors.surface

        Image {
            id: backgroundArt
            anchors.fill: parent
            source: compactPlayer.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: backgroundArt
            brightness: -0.25
            contrast: -0.75
            saturation: -0.5
            blurEnabled: true
            blurMax: 32
            blur: 0.75
            opacity: (compactPlayer.player?.trackArtUrl ?? "") !== "" ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
        }

        Item {
            id: artworkContainer
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            visible: compactPlayer.player !== null

            ClippingRectangle {
                anchors.fill: parent
                radius: compactPlayer.isPlaying ? (Config.roundness > 0 ? Math.max(Config.roundness - 8, 0) : 0) : (Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0)
                color: compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overPrimary : Colors.overPrimaryFixed

                Behavior on radius {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }

                Image {
                    id: artworkImage
                    anchors.fill: parent
                    source: compactPlayer.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: artworkImage
                    brightness: -0.15
                    contrast: -0.5
                    saturation: -0.25
                    blurMax: 32
                    blur: 0.75
                    opacity: (compactPlayer.player?.trackArtUrl ?? "") !== "" ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                Text {
                    id: playPauseBtn
                    anchors.centerIn: parent
                    text: compactPlayer.isPlaying ? Icons.pause : Icons.play
                    textFormat: Text.RichText
                    color: playPauseHover.hovered ? (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed) : (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overBackground : Colors.whiteSource)
                    font.pixelSize: 16
                    font.family: Icons.font
                    opacity: compactPlayer.player?.canPause ?? false ? 1.0 : 0.3
                    scale: 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }

                    HoverHandler {
                        id: playPauseHover
                        enabled: compactPlayer.player !== null
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: compactPlayer.player ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: compactPlayer.player !== null
                        onClicked: {
                            playPauseBtn.scale = 1.1;
                            compactPlayer.player?.togglePlaying();
                            playPauseScaleTimer.restart();
                        }
                    }

                    Timer {
                        id: playPauseScaleTimer
                        interval: 100
                        onTriggered: playPauseBtn.scale = 1.0
                    }
                }
            }
        }

        Row {
            id: controlButtons
            anchors.left: artworkContainer.right
            anchors.leftMargin: compactPlayer.notchHovered ? 8 : 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: compactPlayer.notchHovered ? 4 : 0
            opacity: compactPlayer.player ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on spacing {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Text {
                id: previousBtn
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.previous
                textFormat: Text.RichText
                color: previousHover.hovered ? (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed) : (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overBackground : Colors.whiteSource)
                font.pixelSize: 16
                font.family: Icons.font
                opacity: compactPlayer.player?.canGoPrevious ?? false ? 1.0 : 0.3
                visible: compactPlayer.notchHovered && opacity > 0
                clip: true
                scale: 1.0

                readonly property real naturalWidth: implicitWidth
                width: compactPlayer.notchHovered ? naturalWidth : 0

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }

                HoverHandler {
                    id: previousHover
                    enabled: compactPlayer.player?.canGoPrevious ?? false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: compactPlayer.player?.canGoPrevious ?? false ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: compactPlayer.player?.canGoPrevious ?? false
                    onClicked: {
                        previousBtn.scale = 1.5;
                        compactPlayer.player?.previous();
                        previousScaleTimer.restart();
                    }
                }

                Timer {
                    id: previousScaleTimer
                    interval: 100
                    onTriggered: previousBtn.scale = 1.0
                }
            }
        }

        Item {
            id: positionControl
            anchors.left: compactPlayer.player ? controlButtons.right : parent.left
            anchors.right: compactPlayer.player ? rightControls.left : parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: (compactPlayer.player && compactPlayer.notchHovered) ? 8 : 4
            anchors.rightMargin: compactPlayer.player ? 8 : 4
            height: 4
            clip: false

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on anchors.rightMargin {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            property bool isDragging: false
            property real dragPosition: 0.0
            property int dragSeparation: 4

            property real progressRatio: isDragging ? dragPosition : (compactPlayer.length > 0 ? Math.min(1.0, compactPlayer.position / compactPlayer.length) : 0)

            Rectangle {
                anchors.right: parent.right
                width: (1 - positionControl.progressRatio) * parent.width - positionControl.dragSeparation
                height: parent.height
                radius: height / 2
                color: compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.shadow : Colors.shadow
                visible: compactPlayer.player !== null
                z: 0
            }

            WavyLine {
                id: wavyFill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                frequency: 8
                color: compactPlayer.player ? (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed) : Colors.outline
                amplitudeMultiplier: 0.8
                height: compactPlayer.player ? positionControl.height * 8 : positionControl.height * 4
                width: compactPlayer.player ? Math.max(0, positionControl.width * positionControl.progressRatio - positionControl.dragSeparation) : positionControl.width
                lineWidth: positionControl.height
                fullLength: positionControl.width
                visible: compactPlayer.isPlaying || !compactPlayer.player
                opacity: visible ? 1.0 : 0.0
                z: 1

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                FrameAnimation {
                    running: wavyFill.visible && wavyFill.opacity > 0
                    onTriggered: wavyFill.requestPaint()
                }
            }

            Rectangle {
                anchors.left: parent.left
                width: Math.max(0, positionControl.width * positionControl.progressRatio - positionControl.dragSeparation)
                height: positionControl.height
                radius: height / 2
                color: compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed
                visible: !compactPlayer.isPlaying && compactPlayer.player
                opacity: visible ? 1.0 : 0.0
                z: 1
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            Rectangle {
                id: dragHandle
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(positionControl.width - width, positionControl.width * positionControl.progressRatio - width / 2))
                width: positionControl.isDragging ? 4 : 4
                height: positionControl.isDragging ? 20 : 16
                radius: width / 2
                color: compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overBackground : Colors.whiteSource
                visible: compactPlayer.player !== null
                z: 2

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: compactPlayer.player?.canSeek ?? false ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: compactPlayer.player?.canSeek ?? false
                z: 3
                onClicked: mouse => {
                    if (compactPlayer.player && compactPlayer.player.canSeek) {
                        compactPlayer.player.position = (mouse.x / width) * compactPlayer.length;
                    }
                }
                onPressed: {
                    positionControl.isDragging = true;
                    positionControl.dragPosition = Math.min(Math.max(0, mouseX / width), 1);
                }
                onReleased: {
                    if (compactPlayer.player && compactPlayer.player.canSeek) {
                        compactPlayer.player.position = positionControl.dragPosition * compactPlayer.length;
                    }
                    positionControl.isDragging = false;
                }
                onPositionChanged: {
                    if (positionControl.isDragging) {
                        positionControl.dragPosition = Math.min(Math.max(0, mouseX / width), 1);
                    }
                }
            }
        }

        Row {
            id: rightControls
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: compactPlayer.notchHovered ? 4 : 0
            opacity: compactPlayer.player ? 1.0 : 0.0
            visible: opacity > 0
            layoutDirection: Qt.RightToLeft

            Behavior on spacing {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Text {
                id: playerIcon
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!compactPlayer.player)
                        return Icons.player;
                    const dbusName = (compactPlayer.player.dbusName || "").toLowerCase();
                    const desktopEntry = (compactPlayer.player.desktopEntry || "").toLowerCase();
                    const identity = (compactPlayer.player.identity || "").toLowerCase();

                    if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
                        return Icons.spotify;
                    if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
                        return Icons.chromium;
                    if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
                        return Icons.firefox;
                    return Icons.player;
                }
                textFormat: Text.RichText
                color: playerIconHover.hovered ? (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed) : (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overBackground : Colors.whiteSource)
                font.pixelSize: 20
                font.family: Icons.font
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                HoverHandler {
                    id: playerIconHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            MprisController.cyclePlayer(1);
                        } else if (mouse.button === Qt.RightButton) {
                            MprisController.cyclePlayer(-1);
                        }
                    }
                }
            }

            Text {
                id: modeBtn
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (MprisController.hasShuffle)
                        return Icons.shuffle;
                    switch (MprisController.loopState) {
                    case MprisLoopState.Track:
                        return Icons.repeatOnce;
                    case MprisLoopState.Playlist:
                        return Icons.repeat;
                    default:
                        return Icons.shuffle;
                    }
                }
                textFormat: Text.RichText
                color: modeHover.hovered ? (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed) : (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overBackground : Colors.whiteSource)
                font.pixelSize: 16
                font.family: Icons.font
                opacity: {
                    if (!(MprisController.shuffleSupported || MprisController.loopSupported))
                        return 0.3;
                    if (!MprisController.hasShuffle && MprisController.loopState === MprisLoopState.None)
                        return 0.3;
                    return 1.0;
                }
                clip: true
                scale: 1.0

                readonly property real naturalWidth: implicitWidth
                width: compactPlayer.notchHovered ? naturalWidth : 0

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }

                HoverHandler {
                    id: modeHover
                    enabled: MprisController.shuffleSupported || MprisController.loopSupported
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: MprisController.shuffleSupported || MprisController.loopSupported
                    onClicked: {
                        modeBtn.scale = 1.1;
                        if (MprisController.hasShuffle) {
                            MprisController.setShuffle(false);
                            MprisController.setLoopState(MprisLoopState.Playlist);
                        } else if (MprisController.loopState === MprisLoopState.Playlist) {
                            MprisController.setLoopState(MprisLoopState.Track);
                        } else if (MprisController.loopState === MprisLoopState.Track) {
                            MprisController.setLoopState(MprisLoopState.None);
                        } else {
                            MprisController.setShuffle(true);
                        }
                        modeScaleTimer.restart();
                    }
                }

                Timer {
                    id: modeScaleTimer
                    interval: 100
                    onTriggered: modeBtn.scale = 1.0
                }
            }

            Text {
                id: nextBtn
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.next
                textFormat: Text.RichText
                color: nextHover.hovered ? (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.primary : Colors.primaryFixed) : (compactPlayer.hasArtwork && compactPlayer.playerColors ? compactPlayer.playerColors.overBackground : Colors.whiteSource)
                font.pixelSize: 16
                font.family: Icons.font
                opacity: compactPlayer.player?.canGoNext ?? false ? 1.0 : 0.3
                visible: opacity > 0
                clip: true
                scale: 1.0

                readonly property real naturalWidth: implicitWidth
                width: compactPlayer.notchHovered ? naturalWidth : 0

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }

                HoverHandler {
                    id: nextHover
                    enabled: compactPlayer.player?.canGoNext ?? false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: compactPlayer.player?.canGoNext ?? false ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: compactPlayer.player?.canGoNext ?? false
                    onClicked: {
                        nextBtn.scale = 1.1;
                        compactPlayer.player?.next();
                        nextScaleTimer.restart();
                    }
                }

                Timer {
                    id: nextScaleTimer
                    interval: 100
                    onTriggered: nextBtn.scale = 1.0
                }
            }
        }
    }
}
