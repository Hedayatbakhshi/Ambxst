import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: root
    property int count: 1
    property bool expanded: false
    property real fontSize: 12
    
    visible: count > 1
    width: 20
    height: 20
    
    background: Rectangle {
        color: root.pressed ? "#e0e0e0" : (root.hovered ? "#f5f5f5" : "transparent")
        radius: 10
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    contentItem: Text {
        text: root.expanded ? "−" : "+"
        font.pixelSize: root.fontSize
        color: "#757575"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}