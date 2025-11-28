import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.corners
import qs.config
import "layout.js" as CalendarLayout

Item {
    id: root

    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayoutData: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    property var calendarLayout: calendarLayoutData.calendar
    property int currentWeekRow: calendarLayoutData.currentWeekRow
    property int currentDayOfWeek: {
        if (monthShift !== 0)
            return -1;
        var now = new Date();
        return (now.getDay() + 6) % 7;
    }
    property var weekDays: [
        {
            day: 'Mo',
            today: 0
        },
        {
            day: 'Tu',
            today: 0
        },
        {
            day: 'We',
            today: 0
        },
        {
            day: 'Th',
            today: 0
        },
        {
            day: 'Fr',
            today: 0
        },
        {
            day: 'Sa',
            today: 0
        },
        {
            day: 'Su',
            today: 0
        }
    ]

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
                    const stopData = calendarPane.gradientStops[0] || ["surface", 0.0]
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
                        text: viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
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
                        const stopData = calendarPane.gradientStops[0] || ["surface", 0.0]
                        const colorValue = stopData[0]
                        return Config.resolveColor(colorValue)
                    }
                }

                Rectangle {
                    id: leftButton
                    radius: leftMouseArea.pressed ? Config.roundness : (leftMouseArea.containsMouse ? (Config.roundness > 4 ? Config.roundness - 4 : 0) : Config.roundness)
                    bottomLeftRadius: Config.roundness
                    color: {
                        if (leftMouseArea.pressed) return Colors.primary
                        if (leftMouseArea.containsMouse) return Colors.surfaceBright
                        const stopData = calendarPane.gradientStops[0] || ["surface", 0.0]
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
                        text: Icons.caretLeft
                        font.pixelSize: 16
                        color: leftMouseArea.pressed ? Colors.overPrimary : Colors.primary

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 4
                            }
                        }
                    }

                    MouseArea {
                        id: leftMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: monthShift--
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.bottomMargin: 4
                radius: rightMouseArea.pressed ? Config.roundness : (rightMouseArea.containsMouse ? (Config.roundness > 4 ? Config.roundness - 4 : 0) : Config.roundness)
                color: {
                    if (rightMouseArea.pressed) return Colors.primary
                    if (rightMouseArea.containsMouse) return Colors.surfaceBright
                    const stopData = calendarPane.gradientStops[0] || ["surface", 0.0]
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
                    text: Icons.caretRight
                    font.pixelSize: 16
                    color: rightMouseArea.pressed ? Colors.overPrimary : Colors.primary

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation {
                            duration: Config.animDuration / 4
                        }
                    }
                }

                MouseArea {
                    id: rightMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: monthShift++
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        StyledRect {
            id: calendarPane
            variant: "pane"
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.surface
            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            topLeftRadius: 0
            clip: true

            StyledRect {
                variant: "internalbg"
                anchors.fill: parent
                anchors.margins: 4
                color: Colors.background
                radius: Config.roundness

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: weekDays
                            delegate: CalendarDayButton {
                                required property int index
                                day: root.weekDays[index].day
                                isToday: root.weekDays[index].today
                                bold: true
                                isCurrentDayOfWeek: index === root.currentDayOfWeek
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        Layout.preferredHeight: 2
                        color: Colors.surface
                        radius: Config.roundness
                    }

                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 28
                            color: (rowIndex === root.currentWeekRow) ? Colors.surface : "transparent"
                            radius: Config.roundness > 0 ? Config.roundness - 4 : 0

                            required property int index
                            property int rowIndex: index

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0

                                Repeater {
                                    model: 7
                                    delegate: CalendarDayButton {
                                        required property int index
                                        day: calendarLayout[rowIndex][index].day
                                        isToday: calendarLayout[rowIndex][index].today
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
