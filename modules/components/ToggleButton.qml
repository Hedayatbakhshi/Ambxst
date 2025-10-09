import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.globals
import qs.config

Button {
    id: root

    required property string buttonIcon
    required property string tooltipText
    required property var onToggle

    implicitWidth: 36
    implicitHeight: 36

    background: BgRect {
        Rectangle {
            anchors.fill: parent
            color: Colors.primary
            opacity: root.pressed ? 0.5 : (root.hovered ? 0.25 : 0)
            radius: parent.radius

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }
    }

    contentItem: Text {
        text: root.buttonIcon
        textFormat: Text.RichText
        font.family: Icons.font
        font.pixelSize: 20
        color: root.pressed ? Colors.background : Colors.primary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    onClicked: root.onToggle()

    ToolTip.visible: false
    ToolTip.text: root.tooltipText
    ToolTip.delay: 1000
}
