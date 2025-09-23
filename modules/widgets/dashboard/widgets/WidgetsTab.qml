import QtQuick
import qs.modules.theme
import qs.config

Rectangle {
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 300

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: Config.theme.roundness

        Text {
            anchors.centerIn: parent
            text: "Widgets"
            color: Colors.adapter.overSurfaceVariant
            font.family: Config.theme.font
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }
}
