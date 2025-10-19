pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.modules.theme
import qs.modules.components

Item {
    id: root

    Layout.fillHeight: !resizeParent || vertical
    Layout.fillWidth: !resizeParent || !vertical
    implicitHeight: resizeParent ? (vertical ? size : 4) : 0
    implicitWidth: resizeParent ? (!vertical ? size : 4) : 0

    onWidthChanged: if (!resizeParent && !vertical)
        size = width
    onHeightChanged: if (!resizeParent && vertical)
        size = height

    signal iconClicked
    signal iconHovered(bool hovered)

    property bool vertical: false
    property string icon: ""
    property real value: 0
    property bool isDragging: false
    property real dragPosition: 0.0
    property real progressRatio: isDragging ? dragPosition : value
    property string tooltipText: `${Math.round(value * 100)}%`
    property color progressColor: Colors.primary
    property color backgroundColor: Colors.surfaceBright
    property bool wavy: false
    property real wavyAmplitude: 0.8
    property real wavyFrequency: 8
    property real heightMultiplier: 8
    property bool smoothDrag: true
    property bool scroll: true
    property bool tooltip: true
    property bool updateOnRelease: false
    property string iconPos: "start"
    property real size: 100
    property real thickness: 4
    property color iconColor: Colors.overBackground
    property real handleSpacing: 4
    property bool resizeParent: true
    property real iconRotation: 0
    property real iconScale: 1

    property real animatedProgress: progressRatio
    Behavior on animatedProgress {
        enabled: root.smoothDrag
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

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
    Behavior on size {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    // Horizontal Layout
    RowLayout {
        id: horizontalLayout
        visible: !root.vertical
        anchors.fill: parent
        anchors.leftMargin: root.iconPos === "start" && root.icon !== "" ? iconText.width + spacing : 0
        anchors.rightMargin: root.iconPos === "end" && root.icon !== "" ? iconText.width + spacing : 0
        spacing: 4

        Item {
            id: hSliderItem
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: hDragHandle
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * root.animatedProgress - width / 2
                width: root.isDragging ? 2 : 4
                height: root.isDragging ? Math.max(20, root.thickness + 12) : Math.max(16, root.thickness + 8)
                radius: Config.roundness
                color: Colors.overBackground
                z: 2
                Behavior on width {
                    enabled: root.smoothDrag
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on height {
                    enabled: root.smoothDrag
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            Rectangle {
                anchors.left: hDragHandle.right
                anchors.leftMargin: root.handleSpacing
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: root.thickness
                radius: Config.roundness / 4
                color: root.backgroundColor
                z: 0
            }

            WavyLine {
                id: hWavyFill
                anchors.left: parent.left
                anchors.right: hDragHandle.left
                anchors.rightMargin: root.handleSpacing
                anchors.verticalCenter: parent.verticalCenter
                frequency: root.wavyFrequency
                color: root.progressColor
                amplitudeMultiplier: root.wavyAmplitude
                height: parent.height * heightMultiplier
                lineWidth: root.thickness
                fullLength: parent.width
                visible: root.wavy
                z: 1
                FrameAnimation {
                    running: visible
                }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: hDragHandle.left
                anchors.rightMargin: root.handleSpacing
                anchors.verticalCenter: parent.verticalCenter
                height: root.thickness
                radius: Config.roundness / 4
                color: root.progressColor
                visible: !root.wavy
                z: 1
            }

            StyledToolTip {
                tooltipText: root.tooltipText
                visible: root.isDragging && root.tooltip && !root.vertical
                x: hDragHandle.x + hDragHandle.width / 2 - width / 2
                y: hDragHandle.y - height - 5
            }
        }
    }

    // Vertical Layout
    ColumnLayout {
        id: verticalLayout
        visible: root.vertical
        anchors.fill: parent
        anchors.topMargin: root.iconPos === "start" && root.icon !== "" ? iconText.height + spacing : 0
        anchors.bottomMargin: root.iconPos === "end" && root.icon !== "" ? iconText.height + spacing : 0
        spacing: 4

        Item {
            id: vSliderItem
            Layout.fillHeight: true
            Layout.preferredWidth: 4
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: vDragHandle
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * (1 - root.animatedProgress) - height / 2
                height: root.isDragging ? 2 : 4
                width: root.isDragging ? Math.max(20, root.thickness + 12) : Math.max(16, root.thickness + 8)
                radius: Config.roundness
                color: iconColor
                z: 2
                Behavior on width {
                    enabled: root.smoothDrag
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on height {
                    enabled: root.smoothDrag
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: vDragHandle.top
                anchors.bottomMargin: root.handleSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.thickness
                radius: Config.roundness / 4
                color: root.backgroundColor
                z: 0
            }

            Item {
                anchors.top: vDragHandle.bottom
                anchors.topMargin: root.handleSpacing
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * heightMultiplier
                visible: root.wavy
                WavyLine {
                    id: vWavyFill
                    anchors.centerIn: parent
                    rotation: -90
                    frequency: root.wavyFrequency
                    color: root.progressColor
                    amplitudeMultiplier: root.wavyAmplitude
                    height: parent.width
                    width: parent.height
                    lineWidth: root.thickness
                    fullLength: vSliderItem.height
                    z: 1
                    FrameAnimation {
                        running: visible
                    }
                }
            }
            Rectangle {
                anchors.top: vDragHandle.bottom
                anchors.topMargin: root.handleSpacing
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.thickness
                radius: Config.roundness / 4
                color: root.progressColor
                visible: !root.wavy
                z: 1
            }

            StyledToolTip {
                tooltipText: root.tooltipText
                visible: root.isDragging && root.tooltip && root.vertical
                x: vDragHandle.x + vDragHandle.width + 5
                y: vDragHandle.y + vDragHandle.height / 2 - height / 2
            }
        }
    }

    Text {
        id: iconText
        visible: root.icon !== ""
        text: root.icon
        font.family: Icons.font
        font.pixelSize: 20
        color: Colors.overBackground
        rotation: root.iconRotation
        scale: root.iconScale
        x: !root.vertical ? (root.iconPos === "start" ? 0 : parent.width - width) : (parent.width - width) / 2
        y: root.vertical ? (root.iconPos === "start" ? 0 : parent.height - height) : (parent.height - height) / 2
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 4
            onEntered: {
                iconColor = Colors.primary;
                root.iconHovered(true);
            }
            onExited: {
                iconColor = Colors.overBackground;
                root.iconHovered(false);
            }
            onClicked: root.iconClicked()
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: 3
        property var activeLayout: !root.vertical ? horizontalLayout : verticalLayout
        property real layoutStart: !root.vertical ? activeLayout.x : activeLayout.y
        property real layoutSize: !root.vertical ? activeLayout.width : activeLayout.height

        function isInIconArea(mouseX, mouseY) {
            if (iconText.visible) {
                if (!root.vertical) {
                    return (root.iconPos === "start" && mouseX < iconText.width + horizontalLayout.spacing) || (root.iconPos === "end" && mouseX > parent.width - iconText.width - horizontalLayout.spacing);
                } else {
                    return (root.iconPos === "start" && mouseY < iconText.height + verticalLayout.spacing) || (root.iconPos === "end" && mouseY > parent.height - iconText.height - verticalLayout.spacing);
                }
            }
            return false;
        }

        function calculatePosition(mouseX, mouseY) {
            const mousePos = !root.vertical ? mouseX : mouseY;
            const relativePos = mousePos - layoutStart;
            let ratio = Math.max(0, Math.min(1, relativePos / layoutSize));
            if (root.vertical) {
                ratio = 1 - ratio; // Invert for vertical
            }
            return ratio;
        }

        onPressed: mouse => {
            if (isInIconArea(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }
            root.isDragging = true;
            root.dragPosition = calculatePosition(mouse.x, mouse.y);
            if (!root.updateOnRelease) {
                root.value = root.dragPosition;
            }
        }

        onPositionChanged: mouse => {
            if (root.isDragging) {
                root.dragPosition = calculatePosition(mouse.x, mouse.y);
                if (!root.updateOnRelease) {
                    root.value = root.dragPosition;
                }
            }
        }

        onReleased: mouse => {
            if (root.isDragging) {
                if (root.updateOnRelease) {
                    root.value = root.dragPosition;
                }
                root.isDragging = false;
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
}
