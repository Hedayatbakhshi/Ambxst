import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../theme"
import "./notification_utils.js" as NotificationUtils

Rectangle {
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property var image: ""
    property real scale: 1
    property real size: 45 * scale
    property real materialIconScale: 0.57
    property real appIconScale: 0.7
    property real smallAppIconScale: 0.49
    property real materialIconSize: size * materialIconScale
    property real appIconSize: size * appIconScale
    property real smallAppIconSize: size * smallAppIconScale

    implicitWidth: size
    implicitHeight: size
    radius: 22.5 // Full radius for circular appearance
    color: "#f3f3f3" // Light surface color

    Loader {
        id: materialSymbolLoader
        active: root.appIcon == ""
        anchors.fill: parent
        sourceComponent: Text {
            text: NotificationUtils.findSuitableMaterialSymbol(root.summary)
            anchors.fill: parent
            color: (root.urgency == NotificationUrgency.Critical) ? "#d32f2f" : "#424242"
            font.pixelSize: root.materialIconSize
            font.family: "Material Symbols Outlined"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    Loader {
        id: appIconLoader
        active: root.image == "" && root.appIcon != ""
        anchors.centerIn: parent
        sourceComponent: Image {
            id: appIconImage
            width: root.appIconSize
            height: root.appIconSize
            source: root.appIcon ? "image://icon/" + root.appIcon : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }
    
    Loader {
        id: notifImageLoader
        active: root.image != ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            clip: true
            
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                clip: true
                
                Image {
                    id: notifImage
                    anchors.fill: parent
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }
            
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: Image {
                    width: root.smallAppIconSize
                    height: root.smallAppIconSize
                    source: root.appIcon ? "image://icon/" + root.appIcon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }
        }
    }
}