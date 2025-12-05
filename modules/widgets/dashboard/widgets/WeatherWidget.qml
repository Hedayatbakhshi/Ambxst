import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

StyledRect {
    id: root
    variant: "pane"
    Layout.fillHeight: true
    implicitWidth: parent.width
    color: Colors.surface
    radius: Styling.radius(0)

    visible: WeatherService.dataAvailable

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Item {
            Layout.fillHeight: true
        }

        // Weather emoji
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 56
            text: WeatherService.weatherSymbol
            font.pixelSize: 56
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        // Current temperature
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(WeatherService.currentTemp) + "°"
            color: Colors.overSurface
            font.family: Config.theme.font
            font.pixelSize: Config.theme.fontSize + 6
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            color: Colors.surfaceBright
            radius: Styling.radius(0)
        }

        // Max/Min temps
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            // Max temp
            Text {
                text: Math.round(WeatherService.maxTemp) + "°"
                color: Colors.yellow
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
            }

            // Temperature icon
            Text {
                text: Icons.temperature
                color: Colors.outline
                font.family: Icons.font
                font.pixelSize: Config.theme.fontSize + 2
            }

            // Min temp
            Text {
                text: Math.round(WeatherService.minTemp) + "°"
                color: Colors.blue
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
            }
        }

        // Wind speed
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            visible: WeatherService.windSpeed > 0

            Text {
                text: "💨"
                font.pixelSize: Config.theme.fontSize
            }
            Text {
                text: Math.round(WeatherService.windSpeed) + " km/h"
                color: Colors.outline
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
