pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import QtQuick.Effects
import qs.modules.components
import qs.modules.services
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 300
    // 0: Network, 1: Bluetooth, 2: Mixer, 3: Effects, 4: Theme, 5: Binds, 6: System, 7: Shell
    
    property int currentSection: 0 
    property int selectedIndex: 0
    property string searchQuery: ""

    onFilteredSectionsChanged: selectedIndex = 0

    // Timer to restore focus after panel transitions
    Timer {
        id: focusRestoreTimer
        interval: 50
        onTriggered: searchInput.focusInput()
    }

    onSelectedIndexChanged: {
        if (filteredSections && selectedIndex >= 0 && selectedIndex < filteredSections.length) {
            const item = filteredSections[selectedIndex];
            root.currentSection = item.section;
            // Automatically show subsection preview when navigating search results
            root.dispatchSubSection(item.section, item.subSection);
            root.scrollSidebarToSelection();
            // Use timer to ensure focus is restored AFTER any panel focus-stealing
            focusRestoreTimer.restart();
        }
    }

    // Focus the search input (called from parent Dashboard)
    function focusSearchInput() {
        searchInput.focusInput();
    }

    SettingsIndex { id: searchIndex }

    function dispatchSubSection(sectionId, subSectionId) {
        if (!subSectionId || subSectionId === "") return;
        
        if (sectionId === 4) themePanel.currentSection = subSectionId;
        if (sectionId === 6) systemPanel.currentSection = subSectionId;
        if (sectionId === 7) compositorPanel.currentSection = subSectionId;
        if (sectionId === 8) shellPanel.currentSection = subSectionId;
    }

    // Scroll sidebar to ensure visible selection
    function scrollSidebarToSelection() {
        if (sidebarFlickable.height <= 0) return;
        
        const tabHeight = 40;
        const tabSpacing = 4;
        const itemY = root.selectedIndex * (tabHeight + tabSpacing);
        
        // Check bounds and scroll if needed
        if (itemY < sidebarFlickable.contentY) {
            sidebarFlickable.contentY = itemY;
        } else if (itemY + tabHeight > sidebarFlickable.contentY + sidebarFlickable.height) {
            sidebarFlickable.contentY = itemY + tabHeight - sidebarFlickable.height + 4; // +4 for bottom padding feeling
        }
    }



    // Fuzzy match: checks if all characters of query appear in order in target
    function fuzzyMatch(query, target) {
        if (query.length === 0) return true;
        if (target.length === 0) return false;
        const lowerQuery = query.toLowerCase();
        const lowerTarget = target.toLowerCase();
        let queryIndex = 0;
        for (let i = 0; i < lowerTarget.length && queryIndex < lowerQuery.length; i++) {
            if (lowerTarget[i] === lowerQuery[queryIndex]) {
                queryIndex++;
            }
        }
        return queryIndex === lowerQuery.length;
    }

    // Score a fuzzy match (higher is better)
    function fuzzyScore(query, target) {
        if (query.length === 0) return 0;
        if (target.length === 0) return -1;
        const lowerQuery = query.toLowerCase();
        const lowerTarget = target.toLowerCase();

        // Exact match gets highest score
        if (lowerTarget.includes(lowerQuery)) return 1000 + (100 - target.length);

        // Fuzzy scoring
        let queryIndex = 0, score = 0, consecutive = 0, maxConsecutive = 0;
        for (let i = 0; i < lowerTarget.length && queryIndex < lowerQuery.length; i++) {
            if (lowerTarget[i] === lowerQuery[queryIndex]) {
                queryIndex++;
                consecutive++;
                maxConsecutive = Math.max(maxConsecutive, consecutive);
                if (i === 0 || " -_".includes(lowerTarget[i - 1])) score += 10;
            } else {
                consecutive = 0;
            }
        }
        return queryIndex === lowerQuery.length ? score + maxConsecutive * 5 : -1;
    }

    // Original sections model
    readonly property var sectionModel: [
        { icon: Icons.wifiHigh, label: "Network", section: 0, isIcon: true },
        { icon: Icons.bluetooth, label: "Bluetooth", section: 1, isIcon: true },
        { icon: Icons.faders, label: "Mixer", section: 2, isIcon: true },
        { icon: Icons.waveform, label: "Effects", section: 3, isIcon: true },
        { icon: Icons.paintBrush, label: "Theme", section: 4, isIcon: true },
        { icon: Icons.keyboard, label: "Binds", section: 5, isIcon: true },
        { icon: Icons.circuitry, label: "System", section: 6, isIcon: true },
        { icon: Icons.compositor, label: "Compositor", section: 7, isIcon: true },
        { icon: Qt.resolvedUrl("../../../../assets/ambxst/ambxst-icon.svg"), label: "Ambxst", section: 8, isIcon: false }
    ]

    // Filtered sections based on search query
    readonly property var filteredSections: {
        if (searchQuery.length === 0) return sectionModel;
        
        const query = searchQuery.toLowerCase();
        return searchIndex.items.filter(item => {
             return fuzzyMatch(query, item.label) || (item.keywords && item.keywords.includes(query));
        }).map(item => ({ 
            label: item.label,
            section: item.section,
            subSection: item.subSection || "",
            subLabel: item.subLabel || "",
            icon: item.icon,
            isIcon: item.isIcon !== undefined ? item.isIcon : true,
            score: fuzzyScore(query, item.label) 
        })).sort((a, b) => b.score - a.score);
    }

    // Find the index of current section in filtered list
    function getFilteredIndex(sectionId) {
        for (let i = 0; i < filteredSections.length; i++) {
            if (filteredSections[i].section === sectionId) return i;
        }
        return -1;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Sidebar container with background
        StyledRect {
            id: sidebarContainer
            variant: "common"
            Layout.preferredWidth: 200
            Layout.maximumWidth: 200
            Layout.fillHeight: true
            Layout.fillWidth: false

            Column {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                // Search input at the top
                SearchInput {
                    id: searchInput
                    width: parent.width
                    height: 36
                    placeholderText: "Search..."
                    iconText: Icons.magnifyingGlass
                    clearOnEscape: true

                    onSearchTextChanged: text => {
                        root.searchQuery = text;
                    }
                    // ESC to escape dashboard
                    onEscapePressed: {
                        searchInput.focus = false;
                        root.forceActiveFocus();
                    }

                    onAccepted: {
                        // If single result, select it; if multiple, select top one
                        if (root.filteredSections.length > 0) {
                            const item = root.filteredSections[root.selectedIndex];
                            // Ensure section is synced (should be via binding, but force to be safe if dispatching immediately)
                            root.currentSection = item.section;
                            root.dispatchSubSection(item.section, item.subSection);
                        }
                    }

                    onDownPressed: {
                        // Navigate to next filtered section
                        if (root.selectedIndex < root.filteredSections.length - 1) {
                            root.selectedIndex++;
                        } else {
                            // Loop to top? Or stop? User said "move up down arrow key doesn't work normally".
                            // Usually stopping at bottom is standard, or looping. 
                            // Previous code looped to 0. Let's loop.
                            root.selectedIndex = 0;
                        }
                    }

                    onUpPressed: {
                        // Navigate to previous filtered section
                        if (root.selectedIndex > 0) {
                            root.selectedIndex--;
                        } else {
                            // Loop to bottom
                            root.selectedIndex = root.filteredSections.length - 1;
                        }
                    }
                }

                Flickable {
                    id: sidebarFlickable
                    width: parent.width
                    height: parent.height - searchInput.height - 4
                    contentWidth: width
                    contentHeight: sidebar.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // Sliding highlight behind tabs
                    StyledRect {
                        id: tabHighlight
                        variant: "focus"
                        width: parent.width
                        height: 40
                        radius: Styling.radius(-6)
                        z: 0

                        readonly property int tabHeight: 40
                        readonly property int tabSpacing: 4

                        x: 0
                        y: {
                            const idx = root.selectedIndex;
                            return idx >= 0 ? idx * (tabHeight + tabSpacing) : 0;
                        }
                        visible: root.selectedIndex >= 0 && root.selectedIndex < root.filteredSections.length

                        Behavior on y {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Column {
                        id: sidebar
                        width: parent.width
                        spacing: 4
                        z: 1

                        Repeater {
                            model: root.filteredSections

                            delegate: Button {
                                id: sidebarButton
                                required property var modelData
                                required property int index

                                width: sidebar.width
                                height: 40
                                flat: true
                                hoverEnabled: true

                                property bool isActive: index === root.selectedIndex

                                background: Rectangle {
                                    color: "transparent"
                                }

                                contentItem: Row {
                                    spacing: 8

                                    // Icon on the left (font icon)
                                    Text {
                                        id: iconText
                                        text: sidebarButton.modelData.isIcon ? sidebarButton.modelData.icon : ""
                                        font.family: Icons.font
                                        font.pixelSize: 20
                                        color: sidebarButton.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")
                                        anchors.verticalCenter: parent.verticalCenter
                                        leftPadding: 10
                                        visible: sidebarButton.modelData.isIcon && (root.searchQuery.length === 0 || !sidebarButton.modelData.subSection)

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    // SVG icon
                                    Item {
                                        width: 30
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !sidebarButton.modelData.isIcon && (root.searchQuery.length === 0 || !sidebarButton.modelData.subSection)

                                        Image {
                                            id: svgIcon
                                            width: 20
                                            height: 20
                                            anchors.centerIn: parent
                                            anchors.horizontalCenterOffset: 5
                                            source: !sidebarButton.modelData.isIcon ? sidebarButton.modelData.icon : ""
                                            sourceSize: Qt.size(width * 2, height * 2)
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            asynchronous: true
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                brightness: 1.0
                                                colorization: 1.0
                                                colorizationColor: sidebarButton.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")
                                            }
                                        }
                                    }

                                    // Text
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Text {
                                            text: sidebarButton.modelData.label
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            font.weight: sidebarButton.isActive ? Font.Bold : Font.Normal
                                            color: sidebarButton.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")

                                            Behavior on color {
                                                enabled: Config.animDuration > 0
                                                ColorAnimation {
                                                    duration: Config.animDuration
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                        
                                        Text {
                                            visible: !!sidebarButton.modelData.subLabel
                                            text: sidebarButton.modelData.subLabel || ""
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-2)
                                            color: Colors.overSurfaceVariant
                                        }
                                    }
                                }

                                onClicked: {
                                    root.selectedIndex = index;
                                    // currentSection updates via binding on selectedIndex
                                    root.dispatchSubSection(sidebarButton.modelData.section, sidebarButton.modelData.subSection);
                                }
                            }
                        }
                    }

                    // Scroll wheel navigation between sections
                    WheelHandler {
                        enabled: sidebarFlickable.contentHeight <= sidebarFlickable.height
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            if (event.angleDelta.y > 0 && root.selectedIndex > 0) {
                                root.selectedIndex--;
                            } else if (event.angleDelta.y < 0 && root.selectedIndex < root.filteredSections.length - 1) {
                                root.selectedIndex++;
                            }
                        }
                    }
                }
            }
        }

        // Content area with animated transitions
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            property int previousSection: 0
            readonly property int maxContentWidth: 480

            // Track section changes for animation direction
            onVisibleChanged: {
                if (visible) {
                    contentArea.previousSection = root.currentSection;
                }
            }

            Connections {
                target: root
                function onCurrentSectionChanged() {
                    contentArea.previousSection = root.currentSection;
                }
            }

            // WiFi Panel
            WifiPanel {
                id: wifiPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 0 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 0 ? 0 : (root.currentSection > 0 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Bluetooth Panel
            BluetoothPanel {
                id: bluetoothPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 1 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 1 ? 0 : (root.currentSection > 1 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Audio Mixer Panel
            AudioMixerPanel {
                id: audioPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 2 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 2 ? 0 : (root.currentSection > 2 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // EasyEffects Panel
            EasyEffectsPanel {
                id: effectsPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 3 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 3 ? 0 : (root.currentSection > 3 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Theme Panel
            ThemePanel {
                id: themePanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 4 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 4 ? 0 : (root.currentSection > 4 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Binds Panel
            BindsPanel {
                id: bindsPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 5 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 5 ? 0 : (root.currentSection > 5 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // System Panel
            SystemPanel {
                id: systemPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 6 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 6 ? 0 : (root.currentSection > 6 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Compositor Panel
            CompositorPanel {
                id: compositorPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 7 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 7 ? 0 : (root.currentSection > 7 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Shell Panel
            ShellPanel {
                id: shellPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 8 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 8 ? 0 : (root.currentSection > 8 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
