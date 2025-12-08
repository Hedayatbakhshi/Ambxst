pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    required property PwNode node
    property string icon: ""
    property bool isMainDevice: false

    implicitHeight: 48

    PwObjectTracker {
        objects: [root.node]
    }

    readonly property bool isMuted: root.node?.audio?.muted ?? false
    readonly property real volume: root.node?.audio?.volume ?? 0

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Mute button with icon
        Button {
            id: muteButton
            flat: true
            implicitWidth: 36
            implicitHeight: 36

            background: StyledRect {
                variant: muteButton.hovered ? "focus" : "common"
                radius: Styling.radius(4)
            }

            contentItem: Item {
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (root.icon) return root.icon;
                        // For app nodes, try to get an appropriate icon
                        return Icons.speakerHigh;
                    }
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: root.isMuted ? Colors.outline : Colors.overBackground
                    opacity: root.isMuted ? 0.5 : 1

                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 2 }
                    }
                }

                // Mute indicator overlay
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -4
                    visible: root.isMuted
                    text: Icons.cancel
                    font.family: Icons.font
                    font.pixelSize: 12
                    color: Colors.error
                }
            }

            onClicked: {
                if (root.node?.audio) {
                    root.node.audio.muted = !root.node.audio.muted;
                }
            }

            StyledToolTip {
                visible: muteButton.hovered
                tooltipText: root.isMainDevice 
                    ? (root.isMuted ? "Unmute" : "Mute")
                    : Audio.appNodeDisplayName(root.node)
            }
        }

        // Volume slider
        StyledSlider {
            Layout.fillWidth: true
            Layout.fillHeight: true
            value: root.volume
            progressColor: root.isMuted ? Colors.outline : Colors.primary
            resizeParent: false

            onValueChanged: {
                if (root.node?.audio) {
                    root.node.audio.volume = value;
                }
            }
        }

        // Volume percentage
        Text {
            Layout.preferredWidth: 40
            text: `${Math.round(root.volume * 100)}%`
            font.family: Config.theme.font
            font.pixelSize: Config.theme.fontSize - 2
            color: Colors.overSurfaceVariant
            horizontalAlignment: Text.AlignRight
        }
    }
}
