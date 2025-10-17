import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme

Item {
    id: root

    required property var bar

    // Orientación derivada de la barra
    property bool vertical: bar.orientation === "vertical"

     // Estado de hover para activar wavy
     property bool isHovered: false
     property bool mainHovered: false
     property bool iconHovered: false
     property bool externalVolumeChange: false

    HoverHandler {
        onHoveredChanged: {
            root.mainHovered = hovered;
            root.isHovered = root.mainHovered || root.iconHovered;
        }
    }

    // Tamaño basado en hover para BgRect con animación
    implicitWidth: root.vertical ? 4 : 80
    implicitHeight: root.vertical ? 80 : 4
    Layout.preferredWidth: root.vertical ? 4 : 80
    Layout.preferredHeight: root.vertical ? 80 : 4

    states: [
         State {
             name: "hovered"
             when: root.isHovered || volumeSlider.isDragging || root.externalVolumeChange
            PropertyChanges {
                target: root
                implicitWidth: root.vertical ? 4 : 128
                implicitHeight: root.vertical ? 128 : 4
                Layout.preferredWidth: root.vertical ? 4 : 128
                Layout.preferredHeight: root.vertical ? 128 : 4
            }
        }
    ]

    transitions: Transition {
        NumberAnimation {
            properties: "implicitWidth,implicitHeight,Layout.preferredWidth,Layout.preferredHeight"
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Layout.fillWidth: root.vertical
    Layout.fillHeight: !root.vertical

    Component.onCompleted: volumeSlider.value = Audio.sink?.audio?.volume ?? 0

    BgRect {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                root.mainHovered = true;
                root.isHovered = root.mainHovered || root.iconHovered;
            }
            onExited: {
                root.mainHovered = false;
                root.isHovered = root.mainHovered || root.iconHovered;
            }
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
            anchors.rightMargin: root.vertical ? 8 : 16
            anchors.topMargin: root.vertical ? 16 : 8
            vertical: root.vertical
            // size: (root.isHovered || volumeSlider.isDragging) ? 128 : 80ered || volumeSlider.isDragging) ? 128 : 80
            smoothDrag: true
            value: 0
            resizeParent: false
            wavy: true
            wavyAmplitude: (root.isHovered || volumeSlider.isDragging) ? (Audio.sink?.audio?.muted ? 0.5 : 1.5 * value) : 0
            wavyFrequency: (root.isHovered || volumeSlider.isDragging) ? (Audio.sink?.audio?.muted ? 1.0 : 8.0 * value) : 0
            iconPos: root.vertical ? "end" : "start"
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
                     root.externalVolumeChange = true;
                     externalChangeTimer.restart();
                 }
             }

            Connections {
                target: volumeSlider
                function onIconHovered(hovered) {
                    root.iconHovered = hovered;
                    root.isHovered = root.mainHovered || root.iconHovered;
             }
         }

         Timer {
             id: externalChangeTimer
             interval: 1000
             onTriggered: root.externalVolumeChange = false
         }
     }
 }
}
