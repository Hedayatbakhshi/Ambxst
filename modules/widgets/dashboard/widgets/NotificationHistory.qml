import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.notifications
import qs.modules.corners
import qs.config

Item {
    id: root
    property var cascadeItems: []
    property int cascadeIndex: -1

    function discardAllWithAnimation() {
        const children = notificationList.contentItem.children;
        if (children.length === 0) {
            Notifications.discardAllNotifications();
            return;
        }

        // Capture the current items to avoid issues if they change during animation
        cascadeItems = [];
        for (let i = 0; i < children.length; i++) {
            if (children[i] && children[i].destroyWithAnimation) {
                cascadeItems.push(children[i]);
            }
        }

        if (cascadeItems.length === 0) {
            Notifications.discardAllNotifications();
            return;
        }

        cascadeIndex = cascadeItems.length - 1; // Start from last
        cascadeTimer.restart();
    }

    Timer {
        id: cascadeTimer
        interval: 100 // 0.1 seconds delay between each animation
        repeat: true
        onTriggered: {
            if (cascadeIndex >= 0) {
                const item = cascadeItems[cascadeIndex];
                if (item && item.destroyWithAnimation) {
                    item.destroyWithAnimation(true);
                }
                cascadeIndex--;
            } else {
                // All animations started, schedule final discard
                stop();
                cascadeItems = []; // Clear
                const totalDelay = Config.animDuration + 50;
                discardAllTimer.interval = totalDelay;
                discardAllTimer.restart();
            }
        }
    }

    Timer {
        id: discardAllTimer
        interval: Config.animDuration + 50 // Animation duration + small buffer
        repeat: false
        onTriggered: Notifications.discardAllNotifications()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: {
                    const stopData = notificationPane.gradientStops[0] || ["surface", 0.0]
                    const colorValue = stopData[0]
                    return Config.resolveColor(colorValue)
                }
                topLeftRadius: Config.roundness > 0 ? Config.roundness + 4 : 0
                topRightRadius: Config.roundness > 0 ? Config.roundness + 4 : 0
                StyledRect {
                    variant: "internalbg"
                    anchors.fill: parent
                    anchors.margins: 4
                    anchors.bottomMargin: 0
                    color: Colors.background
                    radius: Config.roundness
                    Text {
                        anchors.centerIn: parent
                        text: "Notifications"
                        font.family: Config.defaultFont
                        font.pixelSize: Config.theme.fontSize
                        font.weight: Font.Bold
                        color: Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.leftMargin: -4
                color: "transparent"

                RoundCorner {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    size: Config.roundness > 0 ? Config.roundness + 4 : 0
                    corner: RoundCorner.CornerEnum.BottomLeft
                    color: {
                        const stopData = notificationPane.gradientStops[0] || ["surface", 0.0]
                        const colorValue = stopData[0]
                        return Config.resolveColor(colorValue)
                    }
                }

                Rectangle {
                    id: dndToggle
                    radius: Notifications.silent ? (Config.roundness > 4 ? Config.roundness - 4 : 0) : Config.roundness
                    bottomLeftRadius: Config.roundness
                    color: {
                        if (Notifications.silent) {
                            return dndHover.containsMouse ? Colors.overBackground : Colors.primary
                        }
                        if (dndHover.containsMouse) return Colors.surfaceBright
                        const stopData = notificationPane.gradientStops[0] || ["surface", 0.0]
                        const colorValue = stopData[0]
                        return Config.resolveColor(colorValue)
                    }
                    width: 36
                    height: 36
                    anchors.top: parent.top
                    anchors.right: parent.right

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation {
                            duration: Config.animDuration / 4
                        }
                    }

                    Behavior on radius {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 4
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Notifications.silent ? Icons.bellZ : Icons.bell
                        textFormat: Text.RichText
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: Notifications.silent ? Colors.overPrimary : Colors.primary

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 4
                            }
                        }
                    }

                    MouseArea {
                        id: dndHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Notifications.silent = !Notifications.silent
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.bottomMargin: 4
                radius: broomHover.pressed ? Config.roundness : (broomHover.containsMouse ? (Config.roundness > 4 ? Config.roundness - 4 : 0) : Config.roundness)
                color: {
                    if (broomHover.pressed) return Colors.error
                    if (broomHover.containsMouse) return Colors.overError
                    const stopData = notificationPane.gradientStops[0] || ["surface", 0.0]
                    const colorValue = stopData[0]
                    return Config.resolveColor(colorValue)
                }

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration / 4
                    }
                }

                Behavior on radius {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 4
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: Icons.broom
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: broomHover.pressed ? Colors.overError : Colors.error

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation {
                            duration: Config.animDuration / 4
                        }
                    }
                }

                MouseArea {
                    id: broomHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: discardAllWithAnimation()
                }
            }
        }

        StyledRect {
            id: notificationPane
            variant: "pane"
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.surface
            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            topLeftRadius: 0
            clip: true

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 4
                color: "transparent"
                radius: Config.roundness
                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: notificationList.contentHeight
                    clip: true

                    ListView {
                        id: notificationList
                        width: parent.width
                        height: contentHeight
                        spacing: 4
                        model: Notifications.appNameList
                        interactive: false
                        cacheBuffer: 200
                        reuseItems: true

                        delegate: NotificationGroup {
                            required property int index
                            required property string modelData
                            width: notificationList.width
                            notificationGroup: Notifications.groupsByAppName[modelData]
                            expanded: false
                            popup: false
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: Notifications.appNameList.length === 0

                Text {
                    text: Icons.bellZ
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 64
                    color: Colors.surfaceBright
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
