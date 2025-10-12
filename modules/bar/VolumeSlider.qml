import QtQuick
import QtQuick.Layouts
import qs.modules.bar
import qs.modules.services
import qs.modules.components
import qs.modules.theme

Item {
    Layout.preferredWidth: 128
    Layout.fillHeight: true

    BgRect {
        anchors.fill: parent
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                id: volumeIcon
                text: Icons.speakerHigh
                font.family: Icons.font
                font.pixelSize: 20
                color: Colors.overBackground
            }

            StyledSlider {
                id: volumeSlider
                Layout.fillWidth: true
                height: 4
                value: Audio.sink?.audio?.volume ?? 0

                onValueChanged: {
                    if (Audio.sink?.audio) {
                        Audio.sink.audio.volume = value;
                    }
                }
            }
        }
    }
}
