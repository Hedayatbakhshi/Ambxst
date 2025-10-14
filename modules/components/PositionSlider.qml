import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.config

 Item {
     id: root

     Layout.fillHeight: true

     required property MprisPlayer player

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    property real position: player?.position ?? 0.0
    property real length: player?.length ?? 1.0
    property bool hasArtwork: (player?.trackArtUrl ?? "") !== ""
    property var playerColors: hasArtwork ? PlayerColors.getColorsForPlayer(player) : null

    property alias value: slider.value
    property alias isDragging: slider.isDragging

    StyledSlider {
        id: slider
        anchors.fill: parent

        value: root.length > 0 ? Math.min(1.0, root.position / root.length) : 0
        progressColor: root.hasArtwork && root.playerColors ? root.playerColors.primary : Colors.primaryFixed
        backgroundColor: root.hasArtwork && root.playerColors ? root.playerColors.shadow : Colors.shadow
        wavy: true
        wavyAmplitude: root.isPlaying ? 1 : 0.0
        wavyFrequency: root.isPlaying ? 4 : 0
        heightMultiplier: root.player ? 8 : 4
        resizeAnim: false
        scroll: false
        tooltip: false
        updateOnRelease: true

        onValueChanged: {
            if (isDragging && root.player && root.player.canSeek) {
                root.player.position = value * root.length;
            }
        }
    }
}
