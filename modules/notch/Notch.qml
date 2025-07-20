import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import "../theme"
import "../launcher"

Rectangle {
    id: notchContainer

    property Component defaultViewComponent
    property Component launcherViewComponent
    property Component dashboardViewComponent
    property var stackView: stackViewInternal
    property bool isExpanded: stackViewInternal.currentItem !== stackViewInternal.initialItem

    implicitWidth: Math.max(stackContainer.width, 250)
    implicitHeight: Math.max(stackContainer.height, 40)

    color: Colors.surface
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: 36
    bottomRightRadius: 36

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 0
        radius: 8
        samples: 16
        color: Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 1)
        transparentBorder: true
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: isExpanded ? Easing.OutBack : Easing.OutQuart
            easing.overshoot: isExpanded ? 1.2 : 1.0
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: isExpanded ? Easing.OutBack : Easing.OutQuart
            easing.overshoot: isExpanded ? 1.2 : 1.0
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
                    from: 0.8
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
                    duration: 250
                    easing.type: Easing.OutQuart
                }
                PropertyAnimation {
                    property: "scale"
                    from: 1
                    to: 1.05
                    duration: 250
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
