import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../theme"

Item {
    id: root

    required property var bar

    height: parent.height
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 36

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            SysTrayItem {
                required property SystemTrayItem modelData

                bar: root.bar
                item: modelData
            }
        }
    }
}
