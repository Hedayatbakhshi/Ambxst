import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.globals
import qs.config

// Componente para la barra de filtros de tipo de archivo
Item {
    id: root

    // Propiedades públicas
    property var activeFilters: []

    // Asegurar que activeFilters siempre sea un array válido
    readonly property var safeFilters: activeFilters || []

    // Señales
    signal filterToggled(string filterType)

    // Propiedad para rastrear si el scrollbar está siendo presionado
    property bool scrollBarPressed: false

    // Configuración del Flickable
    height: 32 + 4 + scrollBar.implicitHeight

    Flickable {
        id: flickable
        width: parent.width
        height: 32
        contentWidth: filterRow.width
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        // Modelo de filtros
        ListModel {
            id: filterModel
            ListElement {
                label: "Images"
                type: "image"
            }
            ListElement {
                label: "GIF"
                type: "gif"
            }
            ListElement {
                label: "Videos"
                type: "video"
            }
        }

        // Función para actualizar filtros dinámicamente
        function updateFilters() {
            console.log("Updating filters in FilterBar");
            // Limpiar filtros de subcarpetas existentes
            for (var i = filterModel.count - 1; i >= 3; i--) {
                filterModel.remove(i);
            }

            // Agregar filtros de subcarpetas
            if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager.subfolderFilters) {
                var subfolders = GlobalStates.wallpaperManager.subfolderFilters;
                console.log("Adding subfolder filters:", subfolders);
                for (var j = 0; j < subfolders.length; j++) {
                    filterModel.append({
                        label: subfolders[j],
                        type: "subfolder_" + subfolders[j]
                    });
                }
            }
            console.log("Filter model now has", filterModel.count, "items");
        }

        // Actualizar filtros cuando cambien las subcarpetas
        Connections {
            target: GlobalStates.wallpaperManager
            function onSubfolderFiltersChanged() {
                flickable.updateFilters();
            }
        }

        Component.onCompleted: {
            flickable.updateFilters();
        }

        // Actualizar filtros cuando cambie el directorio de wallpapers
        Connections {
            target: GlobalStates.wallpaperManager
            function onWallpaperDirChanged() {
                flickable.updateFilters();
            }
        }

        Row {
            id: filterRow
            spacing: 4

            Repeater {
                model: filterModel
                delegate: Rectangle {
                    property bool isActive: root.activeFilters.includes(model.type)

                    // Ancho dinámico: incluye icono solo cuando está activo
                    width: filterText.width + 24 + (isActive ? filterIcon.width + 4 : 0)
                    height: 32
                    color: isActive ? Colors.surfaceBright : Colors.surface
                    radius: Math.max(0, Config.roundness - 8)

                    Item {
                        anchors.fill: parent
                        anchors.margins: 8

                        Row {
                            anchors.centerIn: parent
                            spacing: isActive ? 4 : 0

                            // Icono con animación de revelación
                            Item {
                                width: filterIcon.visible ? filterIcon.width : 0
                                height: filterIcon.height
                                clip: true

                                Text {
                                    id: filterIcon
                                    text: Icons.accept
                                    font.family: Icons.font
                                    font.pixelSize: 16
                                    color: Colors.primary
                                    visible: isActive
                                    opacity: isActive ? 1 : 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Config.animDuration / 3
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Config.animDuration / 3
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Text {
                                id: filterText
                                text: model.label
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                color: isActive ? Colors.primary : Colors.overBackground

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 3
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const index = root.activeFilters.indexOf(model.type);
                            if (index > -1) {
                                root.activeFilters.splice(index, 1);
                            } else {
                                root.activeFilters.push(model.type);
                            }
                            root.activeFilters = root.activeFilters.slice();  // Trigger update
                            root.filterToggled(model.type);
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Config.animDuration / 3
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        id: scrollBar
        anchors.top: flickable.bottom
        anchors.topMargin: 4
        Layout.preferredHeight: 4
        width: flickable.width
        height: implicitHeight
        orientation: Qt.Horizontal
        visible: flickable.contentWidth > flickable.width

        position: flickable.contentX / flickable.contentWidth
        size: flickable.width / flickable.contentWidth

        background: Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            color: Colors.surface
            radius: Config.roundness
        }

        contentItem: Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            color: Colors.primary
            radius: Config.roundness
        }

        onPressedChanged: {
            scrollBarPressed = pressed;
        }

        onPositionChanged: {
            if (scrollBarPressed && flickable.contentWidth > flickable.width) {
                flickable.contentX = position * flickable.contentWidth;
            }
        }
    }
}
