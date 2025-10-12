pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.modules.theme
import qs.modules.components

/**
 * Simplified slider inspired by CompactPlayer position control.
 */

Item {
    id: root

    implicitHeight: 4

    property real value: 0
    property bool isDragging: false
    property real dragPosition: 0.0
    property int dragSeparation: 4
    property real progressRatio: isDragging ? dragPosition : value
    property string tooltipText: `${Math.round(value * 100)}%`
    property color progressColor: Colors.primary
    property color backgroundColor: Colors.surfaceBright
    property bool wavy: false

    Rectangle {
        anchors.right: parent.right
        width: (1 - root.progressRatio) * parent.width - root.dragSeparation
        height: parent.height
        radius: height / 2
        color: root.backgroundColor
        z: 0
    }

    WavyLine {
        id: wavyFill
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        frequency: 8
        color: root.progressColor
        amplitudeMultiplier: 0.8
        height: parent.height * 8
        width: Math.max(0, parent.width * root.progressRatio - root.dragSeparation)
        lineWidth: parent.height
        fullLength: parent.width
        visible: root.wavy
        opacity: 1.0
        z: 1

        FrameAnimation {
            running: wavyFill.visible && wavyFill.opacity > 0
            onTriggered: wavyFill.requestPaint()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width * root.progressRatio - root.dragSeparation)
        height: parent.height
        radius: height / 2
        color: root.progressColor
        visible: !root.wavy
        z: 1
    }

    Rectangle {
        id: dragHandle
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.progressRatio - width / 2))
        width: root.isDragging ? 4 : 4
        height: root.isDragging ? 20 : 16
        radius: width / 2
        color: Colors.whiteSource
        z: 2

        Behavior on width {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: 3
        onClicked: mouse => {
            root.value = mouse.x / width;
        }
        onPressed: {
            root.isDragging = true;
            root.dragPosition = Math.min(Math.max(0, mouseX / width), 1);
        }
        onReleased: {
            root.value = root.dragPosition;
            root.isDragging = false;
        }
        onPositionChanged: {
            if (root.isDragging) {
                root.dragPosition = Math.min(Math.max(0, mouseX / width), 1);
                root.value = root.dragPosition;
            }
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.value = Math.min(1, root.value + 0.05);
            } else {
                root.value = Math.max(0, root.value - 0.05);
            }
        }
    }

    ToolTip {
        visible: root.isDragging
        text: root.tooltipText
        x: dragHandle.x + dragHandle.width / 2 - width / 2
        y: dragHandle.y - height - 5
    }

    onValueChanged:
    // Override in usage
    {}
}
