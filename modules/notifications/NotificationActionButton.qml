import QtQuick
import QtQuick.Controls
import Quickshell.Services.Notifications
import "../theme"

Button {
    id: root
    property string buttonText: ""
    property var urgency: NotificationUrgency.Normal
    
    text: buttonText
    
    background: Rectangle {
        color: root.pressed ? "#e0e0e0" : (root.hovered ? "#f5f5f5" : "transparent")
        border.color: (root.urgency == NotificationUrgency.Critical) ? "#d32f2f" : "#757575"
        border.width: 1
        radius: 8
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    contentItem: Text {
        text: root.text
        font.pixelSize: 12
        color: (root.urgency == NotificationUrgency.Critical) ? "#d32f2f" : "#424242"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}