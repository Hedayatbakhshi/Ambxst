import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme

Item {
    Layout.preferredWidth: 128
    Layout.fillHeight: true

    Component.onCompleted: volumeSlider.value = Audio.sink?.audio?.volume ?? 0

    BgRect {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    volumeSlider.value = Math.min(1, volumeSlider.value + 0.1);
                } else {
                    volumeSlider.value = Math.max(0, volumeSlider.value - 0.1);
                }
            }
        }

        StyledSlider {
            id: volumeSlider
            anchors.fill: parent
            anchors.margins: 8
            value: 0
            wavy: true
            wavyAmplitude: Audio.sink?.audio?.muted ? 0.5 : 2.0 * value
            wavyFrequency: Audio.sink?.audio?.muted ? 1.0 : 10.0 * value
            icon: {
                if (Audio.sink?.audio?.muted)
                    return Icons.speakerSlash;
                const vol = Audio.sink?.audio?.volume ?? 0;
                if (vol < 0.01)
                    return Icons.speakerX;
                if (vol < 0.19)
                    return Icons.speakerNone;
                if (vol < 0.49)
                    return Icons.speakerLow;
                return Icons.speakerHigh;
            }
            progressColor: Audio.sink?.audio?.muted ? Colors.outline : Colors.primary

            onValueChanged: {
                if (Audio.sink?.audio) {
                    Audio.sink.audio.volume = value;
                }
            }

            onIconClicked: {
                if (Audio.sink?.audio) {
                    Audio.sink.audio.muted = !Audio.sink.audio.muted;
                }
            }

            Connections {
                target: Audio.sink?.audio
                function onVolumeChanged() {
                    volumeSlider.value = Audio.sink.audio.volume;
                }
            }
        }
    }
}
