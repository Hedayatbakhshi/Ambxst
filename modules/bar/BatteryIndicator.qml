pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.config

Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    // Popup visibility state
    property bool popupOpen: batteryPopup.isOpen

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    // Main button with circular progress
    StyledRect {
        id: buttonBg
        variant: root.popupOpen ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        // Background highlight on hover
        Rectangle {
            anchors.fill: parent
            color: Colors.primary
            opacity: root.popupOpen ? 0 : (root.isHovered ? 0.25 : 0)
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        // Circular progress indicator (only if battery available)
        Item {
            id: progressCanvas
            anchors.centerIn: parent
            width: 32
            height: 32
            visible: Battery.available

            property real angle: Battery.percentage * 360
            property real radius: 12
            property real lineWidth: 3

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();

                    let centerX = width / 2;
                    let centerY = height / 2;
                    let radius = progressCanvas.radius;
                    let lineWidth = progressCanvas.lineWidth;

                    ctx.lineCap = "round";

                    // Base start angle (top)
                    let baseStartAngle = -Math.PI / 2;
                    let progressAngleRad = progressCanvas.angle * Math.PI / 180;

                    // Draw background track
                    ctx.strokeStyle = Colors.outlineVariant;
                    ctx.lineWidth = lineWidth;
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
                    ctx.stroke();

                    // Draw progress
                    if (progressCanvas.angle > 0) {
                        ctx.strokeStyle = Colors.green;
                        ctx.lineWidth = lineWidth;
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, baseStartAngle, baseStartAngle + progressAngleRad, false);
                        ctx.stroke();
                    }
                }

                Connections {
                    target: progressCanvas
                    function onAngleChanged() {
                        canvas.requestPaint();
                    }
                }
                
                Connections {
                    target: Battery
                    function onPercentageChanged() {
                        canvas.requestPaint();
                    }
                }
            }

            Behavior on angle {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Central icon (Lightning/Plug for battery, PowerProfile icon otherwise)
        Text {
            anchors.centerIn: parent
            text: Battery.available ? (Battery.isCharging ? Icons.plug : Icons.lightning) : PowerProfile.getProfileIcon(PowerProfile.currentProfile)
            font.family: Icons.font
            font.pixelSize: Battery.available ? 14 : 18
            color: root.popupOpen ? buttonBg.itemColor : Colors.overBackground
            
            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation { duration: Config.animDuration / 2 }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: batteryPopup.toggle()
        }

        StyledToolTip {
            visible: root.isHovered && !root.popupOpen
            tooltipText: Battery.available ? ("Battery: " + Math.round(Battery.percentage * 100) + "%" + (Battery.isCharging ? " (Charging)" : "")) : ("Power Profile: " + PowerProfile.getProfileDisplayName(PowerProfile.currentProfile))
        }
    }

    // Battery popup with Power Profiles
    BarPopup {
        id: batteryPopup
        anchorItem: buttonBg
        bar: root.bar

        contentWidth: profilesRow.implicitWidth + batteryPopup.popupPadding * 2
        contentHeight: 36 + batteryPopup.popupPadding * 2

        Row {
            id: profilesRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: PowerProfile.availableProfiles

                delegate: StyledRect {
                    id: profileButton
                    required property string modelData
                    required property int index

                    readonly property bool isSelected: PowerProfile.currentProfile === modelData
                    readonly property bool isFirst: index === 0
                    readonly property bool isLast: index === PowerProfile.availableProfiles.length - 1
                    property bool buttonHovered: false

                    readonly property real defaultRadius: Styling.radius(0)
                    readonly property real selectedRadius: Styling.radius(0) / 2

                    variant: isSelected ? "primary" : (buttonHovered ? "focus" : "common")
                    enableShadow: false
                    width: profileLabel.implicitWidth + 48
                    height: 36
                    
                    topLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                    bottomLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                    topRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius
                    bottomRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: PowerProfile.getProfileIcon(profileButton.modelData)
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: profileButton.itemColor
                        }

                        Text {
                            id: profileLabel
                            text: PowerProfile.getProfileDisplayName(profileButton.modelData)
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            font.bold: true
                            color: profileButton.itemColor
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: profileButton.buttonHovered = true
                        onExited: profileButton.buttonHovered = false

                        onClicked: {
                            PowerProfile.setProfile(profileButton.modelData);
                        }
                    }
                }
            }
        }
    }
}
