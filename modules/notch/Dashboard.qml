import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../workspaces"

Item {
    id: root

    property var state: QtObject {
        property int currentTab: 0
    }

    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    // Tab buttons
    Row {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.margins: 20

        spacing: 8

        Repeater {
            model: ["Overview", "System", "Quick Settings"]

            Button {
                required property int index
                required property string modelData

                text: modelData
                flat: true

                background: Rectangle {
                    color: root.state.currentTab === index ? Colors.primary : "transparent"
                    radius: 8
                    border.color: Colors.outline
                    border.width: root.state.currentTab === index ? 0 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: root.state.currentTab === index ? Colors.onPrimary : Colors.onSurface
                    font.family: Styling.defaultFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                onClicked: root.state.currentTab = index

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }

                states: State {
                    name: "pressed"
                    when: parent.pressed
                    PropertyChanges {
                        target: parent
                        scale: 0.95
                    }
                }
            }
        }
    }

    // Content area
    Rectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        anchors.topMargin: 12

        radius: 12
        color: Colors.surfaceContainer
        clip: true

        layer.enabled: true
        layer.samples: 4

        Flickable {
            id: view

            readonly property int currentIndex: root.state.currentTab
            readonly property Item currentItem: row.children[currentIndex]

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            implicitWidth: currentItem ? currentItem.implicitWidth : 400
            implicitHeight: currentItem ? currentItem.implicitHeight : 300

            contentX: currentItem ? currentItem.x : 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving)
                    return;

                const x = contentX - (currentItem ? currentItem.x : 0);
                const threshold = (currentItem ? currentItem.implicitWidth : 400) / 2;

                if (x > threshold)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, 2);
                else if (x < -threshold)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
            }

            onDragEnded: {
                const x = contentX - (currentItem ? currentItem.x : 0);
                const threshold = (currentItem ? currentItem.implicitWidth : 400) / 10;

                if (x > threshold)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, 2);
                else if (x < -threshold)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
                else
                    contentX = Qt.binding(() => currentItem ? currentItem.x : 0);
            }

            RowLayout {
                id: row
                spacing: 0

                // Overview Tab
                DashboardPane {
                    sourceComponent: overviewComponent
                }

                // System Tab
                DashboardPane {
                    sourceComponent: systemComponent
                }

                // Quick Settings Tab
                DashboardPane {
                    sourceComponent: quickSettingsComponent
                }
            }

            Behavior on contentX {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    // Component definitions for better performance (defined once, reused)
    Component {
        id: overviewComponent
        OverviewTab {}
    }

    Component {
        id: systemComponent
        SystemTab {}
    }

    Component {
        id: quickSettingsComponent
        QuickSettingsTab {}
    }

    component DashboardPane: Loader {
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: 400
        Layout.preferredHeight: 300

        // Performance optimization: only load when visible or about to be visible
        Component.onCompleted: active = Qt.binding(() => {
            if (!view.visibleArea || !view.contentWidth)
                return false;

            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
            const margin = 50; // Pre-load margin for smoother transitions

            return (vx >= x - margin && vx <= x + width + margin) || (vex >= x - margin && vex <= x + width + margin);
        })

        // Cache loaded items for better performance
        property bool wasLoaded: false
        onActiveChanged: {
            if (active)
                wasLoaded = true;
        }
    }

    component OverviewTab: Rectangle {
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 300

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Date and Time with live updates
            Column {
                width: parent.width
                spacing: 4

                property var currentTime: new Date()

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: parent.currentTime = new Date()
                }

                Text {
                    text: Qt.formatDateTime(parent.currentTime, "dddd, MMMM d")
                    color: Colors.onSurface
                    font.family: Styling.defaultFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Text {
                    text: Qt.formatDateTime(parent.currentTime, "h:mm AP")
                    color: Colors.onSurfaceVariant
                    font.family: Styling.defaultFont
                    font.pixelSize: 14
                }
            }

            // User Info
            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Colors.primary

                    Text {
                        anchors.centerIn: parent
                        text: Quickshell.env("USER").charAt(0).toUpperCase()
                        color: Colors.onPrimary
                        font.family: Styling.defaultFont
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: Quickshell.env("USER")
                        color: Colors.onSurface
                        font.family: Styling.defaultFont
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    Text {
                        text: Quickshell.env("HOSTNAME")
                        color: Colors.onSurfaceVariant
                        font.family: Styling.defaultFont
                        font.pixelSize: 12
                    }
                }
            }

            // Workspaces preview
            Rectangle {
                width: parent.width
                height: 60
                radius: 8
                color: Colors.surface
                border.color: Colors.outline
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: parent.color = Colors.surfaceContainerHigh
                    onExited: parent.color = Colors.surface
                }

                Text {
                    anchors.centerIn: parent
                    text: "Workspaces"
                    color: Colors.onSurfaceVariant
                    font.family: Styling.defaultFont
                    font.pixelSize: 12
                }
            }
        }
    }

    component SystemTab: Rectangle {
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 300

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "System Resources"
                color: Colors.onSurface
                font.family: Styling.defaultFont
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            // CPU Usage placeholder
            SystemCard {
                title: "CPU Usage"
                subtitle: "4 cores • 2.4 GHz"
            }

            // Memory Usage placeholder
            SystemCard {
                title: "Memory Usage"
                subtitle: "8 GB available"
            }

            // Storage placeholder
            SystemCard {
                title: "Storage"
                subtitle: "256 GB SSD"
            }
        }
    }

    component QuickSettingsTab: Rectangle {
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 300

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Quick Settings"
                color: Colors.onSurface
                font.family: Styling.defaultFont
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                Repeater {
                    model: ["WiFi", "Bluetooth", "Night Light", "Do Not Disturb"]

                    QuickSettingCard {
                        title: modelData
                    }
                }
            }
        }
    }

    component SystemCard: Rectangle {
        property string title: ""
        property string subtitle: ""

        width: parent.width
        height: 60
        radius: 8
        color: Colors.surface
        border.color: Colors.outline
        border.width: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: parent.color = Colors.surfaceContainerHigh
            onExited: parent.color = Colors.surface
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: parent.title
                color: Colors.onSurface
                font.family: Styling.defaultFont
                font.pixelSize: 12
                font.weight: Font.Medium
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: parent.subtitle
                color: Colors.onSurfaceVariant
                font.family: Styling.defaultFont
                font.pixelSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    component QuickSettingCard: Rectangle {
        property string title: ""

        width: (parent.width - parent.spacing) / 2
        height: 60
        radius: 8
        color: Colors.surface
        border.color: Colors.outline
        border.width: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: parent.color = Colors.surfaceContainerHigh
            onExited: parent.color = Colors.surface
            onPressed: parent.scale = 0.95
            onReleased: parent.scale = 1.0
        }

        Text {
            anchors.centerIn: parent
            text: parent.title
            color: Colors.onSurfaceVariant
            font.family: Styling.defaultFont
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    }
}
