import QtQuick
import QtQuick.Controls
import qs.modules.theme
import qs.config

Menu {
    id: root
    
    // Propiedades principales
    property var items: []
    property int menuWidth: 140
    property int itemHeight: 36
    
    // Propiedades de estilo del menú
    property color backgroundColor: Colors.background
    property color borderColor: Colors.surfaceBright
    property int borderWidth: 2
    property int menuRadius: Config.roundness
    
    // Propiedades de highlight por defecto
    property color defaultHighlightColor: Colors.adapter.primary
    property color defaultTextColor: Colors.adapter.overPrimary
    property color normalTextColor: Colors.adapter.overBackground
    
    // Propiedades internas
    property int hoveredIndex: -1
    
    // Configuración del menú
    width: menuWidth
    padding: 8
    spacing: 0
    
    // Estilo del menú principal
    background: Item {
        implicitWidth: root.menuWidth
        
        // Fondo principal
        Rectangle {
            anchors.fill: parent
            color: root.backgroundColor
            radius: root.menuRadius
            border.width: root.borderWidth
            border.color: root.borderColor
        }
        
        // Highlight animado que sigue al hover
        Rectangle {
            id: menuHighlight
            width: parent.width - 16 // Accounting for padding
            height: root.itemHeight
            color: {
                if (root.hoveredIndex === -1) return root.defaultHighlightColor;
                let item = root.items[root.hoveredIndex];
                return item && item.highlightColor !== undefined ? item.highlightColor : root.defaultHighlightColor;
            }
            radius: root.menuRadius > 6 ? root.menuRadius - 6 : 0
            visible: root.hoveredIndex !== -1
            opacity: visible ? 1.0 : 0
            
            x: 8 // Padding offset
            y: {
                if (root.hoveredIndex === -1) return 8;
                return 8 + (root.hoveredIndex * root.itemHeight);
            }
            
            Behavior on y {
                NumberAnimation {
                    duration: Config.animDuration / 3
                    easing.type: Easing.OutQuart
                }
            }
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDuration / 4
                    easing.type: Easing.OutQuart
                }
            }
            
            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration / 4
                    easing.type: Easing.OutQuart
                }
            }
        }
    }
    
    // Generar MenuItems dinámicamente
    Instantiator {
        model: root.items
        delegate: MenuItem {
            id: menuItem
            property int itemIndex: index
            property var itemData: modelData
            
            text: itemData.text || ""
            width: root.width
            height: root.itemHeight
            
            // Fondo transparente ya que el highlight se maneja externamente
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: root.menuRadius > 6 ? root.menuRadius - 6 : 0
            }
            
            // Manejo del hover
            onHoveredChanged: {
                if (hovered) {
                    root.hoveredIndex = itemIndex;
                } else {
                    Qt.callLater(() => {
                        if (root.hoveredIndex === itemIndex) {
                            root.hoveredIndex = -1;
                        }
                    });
                }
            }
            
            // Contenido del item
            contentItem: Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                
                // Icono (opcional)
                Text {
                    text: itemData.icon || ""
                    visible: text !== ""
                    color: {
                        if (root.hoveredIndex === itemIndex) {
                            return itemData.textColor !== undefined ? itemData.textColor : root.defaultTextColor;
                        }
                        return root.normalTextColor;
                    }
                    font.family: Icons.font
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                
                // Texto
                Text {
                    text: itemData.text || ""
                    color: {
                        if (root.hoveredIndex === itemIndex) {
                            return itemData.textColor !== undefined ? itemData.textColor : root.defaultTextColor;
                        }
                        return root.normalTextColor;
                    }
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutQuart
                        }
                    }
                }
            }
            
            // Acción al hacer click
            onTriggered: {
                if (itemData.onTriggered) {
                    itemData.onTriggered();
                }
            }
        }
        
        onObjectAdded: (index, object) => {
            root.addItem(object);
        }
        
        onObjectRemoved: (index, object) => {
            root.removeItem(object);
        }
    }
}
