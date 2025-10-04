import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.modules.theme
import qs.modules.components

BgRect {
    id: clockContainer

    property string currentTime: ""
    property string weatherText: ""
    property bool weatherVisible: false
    property string currentDayAbbrev: ""

    Layout.preferredWidth: dayDisplay.implicitWidth + (weatherVisible ? weatherDisplay.implicitWidth + sep.implicitWidth : 0) + timeDisplay.implicitWidth + (weatherVisible ? 56 : 40)
    Layout.preferredHeight: 36

    RowLayout {
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: dayDisplay
            text: clockContainer.currentDayAbbrev
            color: Colors.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
        }

        Text {
            id: weatherDisplay
            text: clockContainer.weatherText
            color: Colors.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
            visible: clockContainer.weatherVisible
        }

        Text {
            id: sep
            text: "•"
            color: Colors.outline
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
            visible: clockContainer.weatherVisible
        }

        Text {
            id: timeDisplay
            text: clockContainer.currentTime
            color: Colors.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
        }
    }

    function buildWeatherUrl() {
        var base = "wttr.in/";
        if (Config.weather.location.length > 0) {
            base += Config.weather.location;
        }
        base += "?format=%c+%t";
        if (Config.weather.unit === "C") {
            base += "&m";
        } else if (Config.weather.unit === "F") {
            base += "&u";
        }
        return base;
    }

    function updateWeather() {
        weatherProcess.command = ["curl", buildWeatherUrl()];
        weatherProcess.running = true;
    }

    Process {
        id: weatherProcess
        running: false
        command: ["curl", buildWeatherUrl()]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                clockContainer.weatherText = text.trim().replace(/ /g, '');
                clockContainer.weatherVisible = true;
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                console.log("Weather fetch failed");
                clockContainer.weatherVisible = false;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            clockContainer.currentTime = Qt.formatDateTime(now, "hh:mm:ss");
            clockContainer.currentDayAbbrev = Qt.formatDateTime(now, Qt.locale(), "ddd").slice(0, 3).charAt(0).toUpperCase() + Qt.formatDateTime(now, Qt.locale(), "ddd").slice(1, 3);
        }
    }

    Connections {
        target: Config.weather
        function onLocationChanged() {
            updateWeather();
        }
        function onUnitChanged() {
            updateWeather();
        }
    }

    Timer {
        interval: 600000 // 10 minutes
        running: true
        repeat: true
        onTriggered: {
            updateWeather();
        }
    }

    Component.onCompleted: {
        updateWeather();
        var now = new Date();
        clockContainer.currentDayAbbrev = Qt.formatDateTime(now, "ddd").slice(0, 3);
    }
}
