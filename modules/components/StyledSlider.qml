pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.modules.theme
import qs.modules.components

/**
 * Simplified slider inspired by CompactPlayer position control.
 */

 RowLayout {
     id: root

     Layout.fillHeight: true
     implicitHeight: 4
     spacing: 4

    signal iconClicked

    property string icon: ""
    property real value: 0
    property bool isDragging: false
    property real dragPosition: 0.0
    property int dragSeparation: 4
    property real progressRatio: isDragging ? dragPosition : value
    property string tooltipText: `${Math.round(value * 100)}%`
    property color progressColor: Colors.primary
    property color backgroundColor: Colors.surfaceBright
    property bool wavy: false
    property real wavyAmplitude: 0.8
    property real wavyFrequency: 8
    property real heightMultiplier: 8
    property bool resizeAnim: true
     property bool scroll: true
     property bool tooltip: true
     property bool updateOnRelease: false

    Behavior on wavyAmplitude {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Behavior on wavyFrequency {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Behavior on heightMultiplier {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Text {
        id: iconText
        visible: root.icon !== ""
        text: root.icon
        font.family: Icons.font
        font.pixelSize: 20
        color: Colors.overBackground
        Layout.fillHeight: true

         MouseArea {
             anchors.fill: parent
             hoverEnabled: true
             cursorShape: Qt.PointingHandCursor
             z: 4
             onEntered: iconText.color = Colors.primary
             onExited: iconText.color = Colors.overBackground
             onClicked: root.iconClicked()
         }
     }

     MouseArea {
         id: mouseArea
         anchors.fill: root
         cursorShape: Qt.PointingHandCursor
         z: 3
         onClicked: mouse => {
             const relativeX = mouse.x - sliderItem.x;
             root.value = Math.max(0, Math.min(1, relativeX / sliderItem.width));
         }
         onPressed: mouse => {
             root.isDragging = true;
             const relativeX = mouse.x - sliderItem.x;
             root.dragPosition = Math.max(0, Math.min(1, relativeX / sliderItem.width));
         }
         onReleased: {
             root.value = root.dragPosition;
             root.isDragging = false;
         }
         onPositionChanged: mouse => {
             if (root.isDragging) {
                 const relativeX = mouse.x - sliderItem.x;
                 root.dragPosition = Math.max(0, Math.min(1, relativeX / sliderItem.width));
                 if (!root.updateOnRelease) {
                     root.value = root.dragPosition;
                 }
             }
         }
         onWheel: wheel => {
             if (root.scroll) {
                 if (wheel.angleDelta.y > 0) {
                     root.value = Math.min(1, root.value + 0.1);
                 } else {
                     root.value = Math.max(0, root.value - 0.1);
                 }
             }
         }
     }

     Item {
        id: sliderItem
        Layout.fillWidth: true
        Layout.preferredHeight: 4
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.right: parent.right
            width: (1 - root.progressRatio) * parent.width - root.dragSeparation
            height: parent.height
            radius: height / 2
            color: root.backgroundColor
            z: 0

            Behavior on width {
                enabled: root.resizeAnim
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
        }

        WavyLine {
            id: wavyFill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            frequency: root.wavyFrequency
            color: root.progressColor
            amplitudeMultiplier: root.wavyAmplitude
            height: parent.height * heightMultiplier
            width: Math.max(0, parent.width * root.progressRatio - root.dragSeparation)
            lineWidth: parent.height
            fullLength: parent.width
            visible: root.wavy
            opacity: 1.0
            z: 1

            Behavior on width {
                enabled: root.resizeAnim
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

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

            Behavior on width {
                enabled: root.resizeAnim
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
        }

        Rectangle {
            id: dragHandle
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, parent.width * root.progressRatio - width / 2))
            width: root.isDragging ? 2 : 4
            height: root.isDragging ? 20 : 16
            radius: width / 2
            color: Colors.overBackground
            z: 2

            Behavior on x {
                enabled: root.resizeAnim
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on width {
                enabled: root.resizeAnim
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on height {
                enabled: root.resizeAnim
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
         }

         StyledToolTip {
            tooltipText: root.tooltipText
            visible: root.isDragging && root.tooltip
            x: dragHandle.x + dragHandle.width / 2 - width / 2
            y: dragHandle.y - height - 5
        }
    }

    onValueChanged:
    // Override in usage
    {}
}
