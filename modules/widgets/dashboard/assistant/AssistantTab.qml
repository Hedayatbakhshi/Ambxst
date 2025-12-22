import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.config
import qs.modules.components
import qs.modules.services
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: 800
    implicitHeight: 600
    
    property bool sidebarExpanded: false
    property real sidebarWidth: 250
    property var slashCommands: [
        { name: "model", description: "Switch AI model" },
        { name: "help", description: "Show help" },
        { name: "clear", description: "Clear chat history" },
        { name: "key", description: "Set API key" },
        { name: "prompt", description: "Set system prompt" }
    ]
    
    // Sidebar Animation
    Behavior on sidebarExpanded {
        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // ============================================
        // SIDEBAR
        // ============================================
        Item {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: root.sidebarExpanded ? root.sidebarWidth : 56
            Layout.maximumWidth: root.sidebarWidth
            Layout.minimumWidth: 56
            clip: true
            
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
            }
            
            StyledRect {
                anchors.fill: parent
                anchors.margins: 4
                variant: "pane"
                radius: root.sidebarExpanded ? Styling.radius(8) : Styling.radius(0)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    // Toggle Button
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        flat: true
                        leftPadding: 0
                        rightPadding: 0
                        
                        contentItem: RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            
                            Item {
                                Layout.preferredWidth: 40
                                Layout.fillHeight: true
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.list
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Colors.overSurface
                                }
                            }
                            
                            Text {
                                text: "Menu"
                                color: Colors.overSurface
                                font.family: Config.theme.font
                                font.pixelSize: 14
                                visible: root.sidebarExpanded
                                opacity: root.sidebarExpanded ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Layout.fillWidth: true
                            }
                        }
                        
                        background: StyledRect {
                            variant: "focus"
                            radius: root.sidebarExpanded ? Styling.radius(4) : Styling.radius(-4)
                            opacity: parent.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Config.animDuration / 4 } }
                        }
                        
                        onClicked: root.sidebarExpanded = !root.sidebarExpanded
                    }

                    // New Chat
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        flat: true
                        leftPadding: 0
                        rightPadding: 0
                        
                        contentItem: RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            
                            Item {
                                Layout.preferredWidth: 40
                                Layout.fillHeight: true
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.edit
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Colors.primary
                                }
                            }
                            
                            Text {
                                text: "New Chat"
                                color: Colors.overSurface
                                font.family: Config.theme.font
                                font.pixelSize: 14
                                visible: root.sidebarExpanded
                                opacity: root.sidebarExpanded ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Layout.fillWidth: true
                            }
                        }
                        
                        background: StyledRect {
                            variant: "focus"
                            radius: root.sidebarExpanded ? Styling.radius(4) : Styling.radius(-4)
                            opacity: parent.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Config.animDuration / 4 } }
                        }
                        
                        onClicked: {
                            Ai.createNewChat();
                            if (root.sidebarExpanded && root.implicitWidth < 800) root.sidebarExpanded = false; 
                        }
                    }
                    
                    Separator {
                        Layout.fillWidth: true
                        vert: false
                        visible: root.sidebarExpanded
                    }
                    
                    // History List (Visible only when expanded)
                    ListView {
                        id: historyList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        visible: root.sidebarExpanded
                        opacity: root.sidebarExpanded ? 1 : 0
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        
                        model: Ai.chatHistory
                        spacing: 4
                        
                        delegate: Button {
                            width: historyList.width
                            height: 36
                            flat: true
                            
                            contentItem: RowLayout {
                                anchors.fill: parent
                                spacing: 4
                                
                                Text {
                                    text: {
                                        let date = new Date(parseInt(modelData.id));
                                        return date.toLocaleString(Qt.locale(), "MM-dd hh:mm");
                                    }
                                    color: Ai.currentChatId === modelData.id ? Colors.primary : Colors.overSurface
                                    font.family: Config.theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                Button {
                                    visible: parent.parent.hovered
                                    flat: true
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    Layout.rightMargin: 4
                                    
                                    contentItem: Text {
                                        text: Icons.trash
                                        font.family: Icons.font
                                        color: parent.hovered ? Colors.error : Colors.surfaceDim
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    background: null
                                    onClicked: Ai.deleteChat(modelData.id)
                                }
                            }
                            
                            background: StyledRect {
                                variant: Ai.currentChatId === modelData.id ? "focus" : "transparent"
                                radius: Styling.radius(4)
                                border.width: 0 
                            }
                            
                            onClicked: {
                                Ai.loadChat(modelData.id);
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; visible: !root.sidebarExpanded } // Spacer when contracted

                     // Settings (Bottom)
                    Button {
                        Layout.alignment: Qt.AlignBottom
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        flat: true
                        leftPadding: 0
                        rightPadding: 0
                        
                        contentItem: RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            
                            Item {
                                Layout.preferredWidth: 40
                                Layout.fillHeight: true
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.dotsThree
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Colors.overSurface
                                }
                            }
                            
                            Text {
                                text: "Settings"
                                color: Colors.overSurface
                                font.family: Config.theme.font
                                font.pixelSize: 14
                                visible: root.sidebarExpanded
                                opacity: root.sidebarExpanded ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Layout.fillWidth: true
                            }
                        }
                        
                        background: StyledRect {
                            variant: "focus"
                            radius: root.sidebarExpanded ? Styling.radius(4) : Styling.radius(-4)
                            opacity: parent.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Config.animDuration / 4 } }
                        }
                        
                        // onClicked: openSettings() // Future
                    }
                }
            }
        }
        
        // ============================================
        // MAIN CHAT AREA
        // ============================================
        Item {
            id: mainChatArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            property string username: ""

            Process {
                running: true
                command: ["whoami"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let user = text.trim();
                        if (user) {
                            mainChatArea.username = user.charAt(0).toUpperCase() + user.slice(1);
                        }
                    }
                }
            }
            property bool isWelcome: Ai.currentChat.length === 0

            // Welcome Screen
            ColumnLayout {
                anchors.centerIn: parent
                // Offset slightly up to make room for centered input
                anchors.verticalCenterOffset: -50
                visible: mainChatArea.isWelcome
                spacing: 8
                
                Text {
                    text: "Hello, <font color='" + Colors.primary + "'>" + mainChatArea.username + "</font>."
                    font.family: Config.theme.font
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    textFormat: Text.StyledText
                    Layout.alignment: Qt.AlignHCenter
                    color: Colors.overBackground
                }
                
                // Simplified Gradient Text using standard coloring for now to avoid complexity without LinearGradient check



            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 40
                    
                // Hamburger menu moved to sidebar

                    
                    Text {
                        text: Ai.currentModel.name
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                        visible: false // Moved to typing indicator in footer
                }
                
                // Messages
                ListView {
                    id: chatView
                    visible: !mainChatArea.isWelcome
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: Ai.currentChat
                    spacing: 16
                    displayMarginBeginning: 40
                    displayMarginEnd: 40
                    
                    // Add bottom margin to avoid input overlap
                    // Default height of input is around 48-150, plus margins. Safety buffer 180.
                    bottomMargin: mainChatArea.isWelcome ? 0 : 180
                    
                    // Auto scroll to bottom
                    onCountChanged: {
                        Qt.callLater(() => {
                            positionViewAtEnd();
                        });
                    }
                    
                    delegate: Item {
                        width: chatView.width
                        height: bubble.height + 20
                        
                        property bool isUser: modelData.role === "user"
                        property bool isSystem: modelData.role === "system"
                        
                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            layoutDirection: (isUser && !isSystem) ? Qt.RightToLeft : Qt.LeftToRight
                            spacing: 12
                            
                            // Icon
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: isSystem ? Colors.surfaceDim : (isUser ? Colors.primary : Colors.secondary)
                                visible: !isSystem
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: isUser ? Icons.user : Icons.assistant
                                    font.family: Icons.font
                                    color: isUser ? Colors.overPrimary : Colors.overSecondary
                                }
                            }
                            
                            // Bubble
                            StyledRect {
                                id: bubble
                                variant: isSystem ? "surface" : (isUser ? "primaryContainer" : "surfaceVariant")
                                radius: Styling.radius(12)
                                border.width: isSystem ? 1 : 0
                                border.color: Colors.surfaceDim
                                
                                // Auto-sizing logic
                                width: Math.min(Math.max(msgContent.implicitWidth + 24, 100), chatView.width * (isSystem ? 0.9 : 0.7))
                                height: msgContent.implicitHeight + 24
                                
                                TextEdit {
                                    id: msgContent
                                    anchors.centerIn: parent
                                    width: parent.width - 24
                                    text: modelData.content
                                    textFormat: Text.MarkdownText
                                    color: isSystem ? Colors.outline : (isUser ? Colors.overPrimaryContainer : Colors.overSurfaceVariant)
                                    font.family: Config.theme.font
                                    font.pixelSize: 14
                                    wrapMode: Text.Wrap
                                    readOnly: true
                                    selectByMouse: true
                                    
                                    // Markdown styling overrides if needed could go here
                                }
                            }
                        }
                    }
                    
                    footer: Item {
                        width: chatView.width
                        height: 40
                        visible: Ai.isLoading
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: Colors.primary
                                    opacity: 0.5
                                    
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: Ai.isLoading
                                        
                                        PauseAnimation { duration: index * 200 }
                                        PropertyAnimation { to: 1; duration: 400 }
                                        PropertyAnimation { to: 0.5; duration: 400 }
                                        PauseAnimation { duration: 400 - (index * 200) }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // The original Input Area was here, now it's moved outside this ColumnLayout
            }
            
            // Input Area (Floating)
            Item {
                id: inputContainer
                height: Math.min(150, Math.max(48, inputField.contentHeight + 24))
                
                // State-based anchors
                anchors.bottom: parent.bottom
                // Calculate center position for bottom margin: (parent height / 2) - (input height / 2)
                property real centerMargin: (parent.height / 2) - (height / 2)
                anchors.bottomMargin: mainChatArea.isWelcome ? centerMargin : 20
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Keep width compact as requested (600px max)
                width: Math.min(600, parent.width - 40)
                
                Behavior on anchors.bottomMargin { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
                
                StyledRect {
                    anchors.fill: parent
                    variant: "pane"
                    radius: Styling.radius(4) // Constant radius as requested
                    enableShadow: true
                    
                    // Suggestions Popup
                    Popup {
                        id: suggestionsPopup
                        parent: inputContainer
                        y: -height - 8
                        x: 0
                        width: parent.width
                        // Limit height to 3 items if welcome (approx 40px*3=120) or 5 items if chat active (200)
                        height: Math.min(suggestionsList.contentHeight, mainChatArea.isWelcome ? 120 : 200)
                        padding: 0
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        visible: inputField.text.startsWith("/") && suggestionsModel.count > 0
                        
                        background: StyledRect {
                            variant: "popup"
                            radius: Styling.radius(8)
                            enableShadow: true
                        }
                        
                        function selectNext() {
                            suggestionsList.currentIndex = (suggestionsList.currentIndex + 1) % suggestionsModel.count;
                        }
                        
                        function selectPrevious() {
                            suggestionsList.currentIndex = (suggestionsList.currentIndex - 1 + suggestionsModel.count) % suggestionsModel.count;
                        }
                        
                        function executeSelection() {
                            if (suggestionsList.currentIndex >= 0 && suggestionsList.currentIndex < suggestionsModel.count) {
                                let item = suggestionsModel.get(suggestionsList.currentIndex);
                                inputField.text = "/" + item.name + " ";
                                inputField.cursorPosition = inputField.text.length;
                                inputField.forceActiveFocus();
                            }
                        }
                        
                        ListView {
                            id: suggestionsList
                            anchors.fill: parent
                            clip: true
                            model: ListModel { id: suggestionsModel }
                            highlight: Rectangle { color: Colors.surface; opacity: 0.5 }
                            highlightMoveDuration: 0
                            
                            delegate: Button {
                                width: suggestionsList.width
                                height: 40
                                flat: true
                                highlighted: ListView.isCurrentItem
                                
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8
                                    
                                    Text {
                                        text: "/" + model.name
                                        font.family: Config.theme.font
                                        font.weight: Font.Bold
                                        color: highlighted ? Colors.primary : Colors.text
                                    }
                                    
                                    Text {
                                        text: model.description
                                        font.family: Config.theme.font
                                        color: highlighted ? Colors.text : Colors.surfaceDim
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                                
                                background: Rectangle {
                                    color: (parent.highlighted || parent.hovered) ? Colors.surfaceBright : "transparent"
                                }
                                
                                onClicked: {
                                    suggestionsList.currentIndex = index;
                                    suggestionsPopup.executeSelection();
                                }
                            }
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16 // Balanced padding
                        
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            TextArea {
                                id: inputField
                                placeholderText: mainChatArea.isWelcome ? "Ask AI or type /help..." : "Message AI..."
                                placeholderTextColor: Colors.outline
                                font.pixelSize: 14
                                color: Colors.overBackground
                                wrapMode: TextEdit.Wrap
                                
                                onTextChanged: {
                                    if (text.startsWith("/")) {
                                        const query = text.substring(1).toLowerCase();
                                        suggestionsModel.clear();
                                        root.slashCommands.forEach(cmd => {
                                            if (cmd.name.startsWith(query)) {
                                                suggestionsModel.append(cmd);
                                            }
                                        });
                                    } else {
                                        suggestionsModel.clear();
                                    }
                                }
                                
                                background: null
                                
                                Keys.onPressed: (event) => {
                                    if (suggestionsPopup.visible) {
                                        if (event.key === Qt.Key_Up) {
                                            suggestionsPopup.selectPrevious();
                                            event.accepted = true;
                                            return;
                                        } else if (event.key === Qt.Key_Down) {
                                            suggestionsPopup.selectNext();
                                            event.accepted = true;
                                            return;
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab) {
                                            suggestionsPopup.executeSelection();
                                            event.accepted = true;
                                            return;
                                        }
                                    }
                                    // Regular return behavior
                                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                         if (text.trim().length > 0) {
                                            Ai.sendMessage(text.trim());
                                            text = "";
                                        }
                                        event.accepted = true;
                                    }
                                }

                                Component.onCompleted: forceActiveFocus()
                            }
                        }
                        
                        Button {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            flat: true
                            visible: inputField.text.length > 0
                            
                            contentItem: Text {
                                text: Icons.arrowRight
                                font.family: Icons.font
                                font.pixelSize: 20
                                color: Colors.primary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                color: parent.hovered ? Colors.surfaceBright : "transparent"
                                radius: 16
                            }
                            
                            onClicked: {
                                if (inputField.text.trim().length > 0) {
                                    Ai.sendMessage(inputField.text.trim());
                                    inputField.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}