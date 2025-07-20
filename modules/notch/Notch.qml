import QtQuick
import QtQuick.Controls
import Quickshell
import "../theme"
import "../launcher"

Rectangle {
    id: notchContainer

    property Component defaultViewComponent
    property Component launcherViewComponent
    property var stackView: stackViewInternal

    implicitWidth: Math.max(stackContainer.width, 140)
    implicitHeight: Math.max(stackContainer.height, 40)

    color: Colors.surface
    radius: 20

    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: stackContainer
        anchors.centerIn: parent
        width: stackViewInternal.currentItem ? stackViewInternal.currentItem.width : 0
        height: stackViewInternal.currentItem ? stackViewInternal.currentItem.height : 0

        StackView {
            id: stackViewInternal
            anchors.fill: parent
            initialItem: defaultViewComponent

            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 250
                    easing.type: Easing.OutQuart
                }
                PropertyAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                    easing.type: Easing.OutQuart
                }
                PropertyAnimation {
                    property: "scale"
                    from: 1
                    to: 1.05
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }

            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 250
                    easing.type: Easing.OutQuart
                }
                PropertyAnimation {
                    property: "scale"
                    from: 1.05
                    to: 1
                    duration: 250
                    easing.type: Easing.OutQuart
                }
            }

            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                    easing.type: Easing.OutQuart
                }
                PropertyAnimation {
                    property: "scale"
                    from: 1
                    to: 0.95
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }
        }
    }
}
