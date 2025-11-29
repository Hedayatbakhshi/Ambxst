import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config

Item {
    id: root
    property bool schemeListExpanded: false
    readonly property var schemeDisplayNames: ["Content", "Expressive", "Fidelity", "Fruit Salad", "Monochrome", "Neutral", "Rainbow", "Tonal Spot"]
    readonly property var schemeInternalNames: ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot"]
    property bool scrollBarPressed: false
    property int selectedSchemeIndex: -1
    property bool keyboardNavigationActive: false

    signal schemeSelectorClosed()
    signal escapePressedOnScheme()
    signal tabPressed()
    signal shiftTabPressed()

    function openAndFocus() {
        schemeListExpanded = true;
        updateSelectedIndex();
        keyboardNavigationActive = true;
        schemeButton.forceActiveFocus();
        // Posicionar el ListView en el item seleccionado después de que se expanda
        positionTimer.restart();
    }
    
    function positionAtSelectedScheme() {
        if (selectedSchemeIndex >= 0 && selectedSchemeIndex < schemeInternalNames.length) {
            schemeListView.positionViewAtIndex(selectedSchemeIndex, ListView.Center);
        }
    }
    
    Timer {
        id: positionTimer
        interval: 50
        repeat: false
        onTriggered: {
            positionAtSelectedScheme();
        }
    }

    function closeAndSignal() {
        keyboardNavigationActive = false;
        schemeListExpanded = false;
        schemeSelectorClosed();
    }

    Connections {
        target: GlobalStates.wallpaperManager
        function onCurrentMatugenSchemeChanged() {
            // Update selected index to match current scheme
            updateSelectedIndex();
        }
    }

    function updateSelectedIndex() {
        if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager.currentMatugenScheme) {
            selectedSchemeIndex = schemeInternalNames.indexOf(GlobalStates.wallpaperManager.currentMatugenScheme);
        }
    }

    Component.onCompleted: {
        updateSelectedIndex();
    }

    function getSchemeDisplayName(scheme) {
        const map = {
            "scheme-content": "Content",
            "scheme-expressive": "Expressive",
            "scheme-fidelity": "Fidelity",
            "scheme-fruit-salad": "Fruit Salad",
            "scheme-monochrome": "Monochrome",
            "scheme-neutral": "Neutral",
            "scheme-rainbow": "Rainbow",
            "scheme-tonal-spot": "Tonal Spot"
        };
        return map[scheme] || scheme;
    }

    Layout.fillWidth: true
    Layout.preferredHeight: schemeListExpanded ? 40 + 4 + (40 * 3) + 8 : 48

    Behavior on Layout.preferredHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    StyledRect {
        variant: keyboardNavigationActive && schemeButton.activeFocus ? "focus" : "pane"
        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.fill: parent

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            // Top row with scheme button and dark/light button
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Button {
                    id: schemeButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: GlobalStates.wallpaperManager && GlobalStates.wallpaperManager.currentMatugenScheme ? getSchemeDisplayName(GlobalStates.wallpaperManager.currentMatugenScheme) : "Selecciona esquema"
                    focus: true
                    
                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            keyboardNavigationActive = false;
                            if (schemeListExpanded) {
                                schemeListExpanded = false;
                            }
                        }
                    }
                    
                    onClicked: {
                        keyboardNavigationActive = false;
                        schemeListExpanded = !schemeListExpanded;
                        if (schemeListExpanded) {
                            updateSelectedIndex();
                            positionTimer.restart();
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            if (keyboardNavigationActive) {
                                keyboardNavigationActive = false;
                                if (schemeListExpanded) {
                                    schemeListExpanded = false;
                                }
                                if (event.modifiers & Qt.ShiftModifier) {
                                    shiftTabPressed();
                                } else {
                                    tabPressed();
                                }
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Space) {
                            schemeListExpanded = !schemeListExpanded;
                            if (schemeListExpanded) {
                                updateSelectedIndex();
                                positionTimer.restart();
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            Config.theme.lightMode = true;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            Config.theme.lightMode = false;
                            event.accepted = true;
                        } else if (!schemeListExpanded) {
                            return;
                        } else if (event.key === Qt.Key_Down) {
                            if (selectedSchemeIndex < schemeInternalNames.length - 1) {
                                selectedSchemeIndex++;
                                schemeListView.currentIndex = selectedSchemeIndex;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (selectedSchemeIndex > 0) {
                                selectedSchemeIndex--;
                                schemeListView.currentIndex = selectedSchemeIndex;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (selectedSchemeIndex >= 0 && GlobalStates.wallpaperManager) {
                                GlobalStates.wallpaperManager.setMatugenScheme(schemeInternalNames[selectedSchemeIndex]);
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            keyboardNavigationActive = false;
                            schemeButton.focus = false;
                            if (schemeListExpanded) {
                                schemeListExpanded = false;
                            }
                            escapePressedOnScheme();
                            event.accepted = true;
                        }
                    }

                    background: Rectangle {
                        color: Colors.background
                        radius: Config.roundness
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Colors.overSurface
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                }

                Switch {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 40
                    checked: Config.theme.lightMode
                    focusPolicy: Qt.NoFocus
                    
                    onCheckedChanged: {
                        Config.theme.lightMode = checked;
                    }

                    indicator: Rectangle {
                        implicitWidth: 72
                        implicitHeight: 40
                        radius: Config.roundness
                        color: Colors.background

                        Text {
                            z: 1
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.sun
                            color: Config.theme.lightMode ? Config.resolveColor(Config.theme.srPrimary.itemColor) : Colors.overBackground
                            font.family: Icons.font
                            font.pixelSize: 20
                        }

                        Text {
                            z: 1
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.moon
                            color: Config.theme.lightMode ? Colors.overBackground : Config.resolveColor(Config.theme.srPrimary.itemColor)
                            font.family: Icons.font
                            font.pixelSize: 20
                        }

                        StyledRect {
                            variant: "primary"
                            z: 0
                            width: 36
                            height: 36
                            radius: Math.max(0, (Config.roundness - 2))
                            x: Config.theme.lightMode ? 2 : 36
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on x {
                                enabled: Config.animDuration > 0
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: schemeListExpanded ? 40 * 3 : 0
                    Layout.topMargin: schemeListExpanded ? 4 : 0
                    color: Colors.background
                    radius: Config.roundness
                    opacity: schemeListExpanded ? 1 : 0

                    ListView {
                        id: schemeListView
                        anchors.fill: parent
                        clip: true
                        model: schemeInternalNames
                        currentIndex: selectedSchemeIndex
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        highlightFollowsCurrentItem: true
                        highlightRangeMode: ListView.ApplyRange
                        preferredHighlightBegin: 0
                        preferredHighlightEnd: height

                        onCurrentIndexChanged: {
                            if (currentIndex !== selectedSchemeIndex) {
                                selectedSchemeIndex = currentIndex;
                            }
                        }

                        delegate: Button {
                            required property string modelData
                            required property int index

                            width: schemeListView.width
                            height: 40
                            text: schemeDisplayNames[index]

                            onClicked: {
                                if (GlobalStates.wallpaperManager) {
                                    GlobalStates.wallpaperManager.setMatugenScheme(modelData);
                                    schemeListExpanded = false;
                                }
                            }

                            background: Rectangle {
                                color: "transparent"
                            }

                            contentItem: Text {
                                text: parent.text
                                color: selectedSchemeIndex === index ? Config.resolveColor(Config.theme.srPrimary.itemColor) : Colors.overSurface
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: selectedSchemeIndex === index ? Font.Bold : Font.Normal
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8

                                Behavior on color {
                                    enabled: Config.animDuration > 0
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: {
                                    selectedSchemeIndex = index;
                                    schemeListView.currentIndex = index;
                                }
                                onClicked: {
                                    if (GlobalStates.wallpaperManager) {
                                        GlobalStates.wallpaperManager.setMatugenScheme(modelData);
                                        schemeListExpanded = false;
                                    }
                                }
                            }
                        }

                        highlight: StyledRect {
                            variant: "primary"
                            radius: Config.roundness
                            visible: selectedSchemeIndex >= 0
                            z: -1
                        }

                        highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                        highlightMoveVelocity: -1
                        highlightResizeDuration: Config.animDuration / 2
                        highlightResizeVelocity: -1
                    }

                    // Animate topMargin for ClippingRectangle
                    Behavior on Layout.topMargin {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    Behavior on Layout.preferredHeight {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                ScrollBar {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: schemeListExpanded ? (40 * 3) - 32 : 0
                    Layout.alignment: Qt.AlignVCenter
                    orientation: Qt.Vertical
                    visible: schemeListView.contentHeight > schemeListView.height

                    position: schemeListView.contentY / schemeListView.contentHeight
                    size: schemeListView.height / schemeListView.contentHeight

                    background: Rectangle {
                        color: Colors.background
                        radius: Config.roundness
                    }

                    contentItem: StyledRect {
                        variant: "primary"
                        radius: Config.roundness
                    }

                    onPressedChanged: {
                        scrollBarPressed = pressed;
                    }

                    onPositionChanged: {
                        if (scrollBarPressed && schemeListView.contentHeight > schemeListView.height) {
                            schemeListView.contentY = position * schemeListView.contentHeight;
                        }
                    }
                }
            }
        }
    }
}
