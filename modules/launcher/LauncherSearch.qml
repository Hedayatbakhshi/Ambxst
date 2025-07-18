import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../../services"

Rectangle {
    id: root

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    signal itemSelected

    implicitWidth: 500
    implicitHeight: mainLayout.implicitHeight + 16
    color: Colors.surface
    radius: 24
    border.color: Colors.outline
    border.width: 0

    Behavior on height {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Search input
        Rectangle {
            id: searchInputContainer
            Layout.fillWidth: true
            implicitHeight: 48
            color: Colors.surfaceContainerLowest
            radius: 16
            border.color: searchInput.activeFocus ? Colors.primary : Colors.outline
            border.width: 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    text: ""
                    font.pixelSize: 20
                    color: Colors.primary
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search applications..."
                    placeholderTextColor: Colors.surfaceBright
                    font.pixelSize: 14
                    color: Colors.foreground
                    background: null

                    onTextChanged: {
                        root.searchText = text;
                        // Auto-highlight first app when text is entered
                        if (text.length > 0) {
                            root.selectedIndex = 0;
                            resultsList.currentIndex = 0;
                        } else {
                            root.selectedIndex = -1;
                            resultsList.currentIndex = -1;
                        }
                    }

                    onAccepted: {
                        if (root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                            let selectedApp = resultsList.model[root.selectedIndex];
                            if (selectedApp) {
                                selectedApp.execute();
                                root.itemSelected();
                            }
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.itemSelected();
                        } else if (event.key === Qt.Key_Down) {
                            if (resultsList.count > 0) {
                                if (root.selectedIndex < resultsList.count - 1) {
                                    root.selectedIndex++;
                                    resultsList.currentIndex = root.selectedIndex;
                                } else if (root.selectedIndex === -1) {
                                    // When no search text and nothing selected, start at first item
                                    root.selectedIndex = 0;
                                    resultsList.currentIndex = 0;
                                }
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (root.selectedIndex > 0) {
                                root.selectedIndex--;
                                resultsList.currentIndex = root.selectedIndex;
                            } else if (root.selectedIndex === 0 && root.searchText.length === 0) {
                                // When no search text, allow going back to no selection
                                root.selectedIndex = -1;
                                resultsList.currentIndex = -1;
                            }
                            event.accepted = true;
                        }
                    }
                }
            }
        }

        // Results list
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: 5 * 48
            visible: true
            clip: true

            model: root.searchText.length > 0 ? AppSearch.fuzzyQuery(root.searchText) : AppSearch.getAllApps()
            currentIndex: root.selectedIndex

            // Sync currentIndex with selectedIndex
            onCurrentIndexChanged: {
                if (currentIndex !== root.selectedIndex) {
                    root.selectedIndex = currentIndex;
                }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: resultsList.width
                height: 48
                color: mouseArea.containsMouse ? Colors.surfaceVariant : "transparent"
                radius: 16

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        root.selectedIndex = index;
                        resultsList.currentIndex = index;
                    }
                    onClicked: {
                        modelData.execute();
                        root.itemSelected();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        source: "image://icon/" + modelData.icon
                        fillMode: Image.PreserveAspectFit

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Colors.outline
                            border.width: parent.status === Image.Error ? 1 : 0
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                text: "?"
                                visible: parent.parent.status === Image.Error
                                color: Colors.foreground
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Colors.foreground
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }
            }

            highlight: Rectangle {
                color: Colors.surfaceBright
                radius: 16
                visible: root.selectedIndex >= 0
            }

            highlightMoveDuration: 50
            highlightMoveVelocity: -1
        }
    }

    Component.onCompleted: {
        searchInput.forceActiveFocus();
    }
}
