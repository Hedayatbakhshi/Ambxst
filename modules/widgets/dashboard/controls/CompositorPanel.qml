pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    // Available color names for color picker
    readonly property var colorNames: Colors.availableColorNames

    // Color picker state
    property bool colorPickerActive: false
    property var colorPickerColorNames: []
    property string colorPickerCurrentColor: ""
    property string colorPickerDialogTitle: ""
    property var colorPickerCallback: null

    function openColorPicker(colorNames, currentColor, dialogTitle, callback) {
        colorPickerColorNames = colorNames;
        colorPickerCurrentColor = currentColor;
        colorPickerDialogTitle = dialogTitle;
        colorPickerCallback = callback;
        colorPickerActive = true;
    }

    function closeColorPicker() {
        colorPickerActive = false;
        colorPickerCallback = null;
    }

    function handleColorSelected(color) {
        if (colorPickerCallback) {
            colorPickerCallback(color);
        }
        colorPickerCurrentColor = color;
    }

    // Inline component for toggle rows
    component ToggleRow: RowLayout {
        id: toggleRowRoot
        property string label: ""
        property bool checked: false
        signal toggled(bool value)

        // Track if we're updating from external binding
        property bool _updating: false

        onCheckedChanged: {
            if (!_updating && toggleSwitch.checked !== checked) {
                _updating = true;
                toggleSwitch.checked = checked;
                _updating = false;
            }
        }

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: toggleRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.fillWidth: true
        }

        Switch {
            id: toggleSwitch
            checked: toggleRowRoot.checked

            onCheckedChanged: {
                if (!toggleRowRoot._updating && checked !== toggleRowRoot.checked) {
                    toggleRowRoot.toggled(checked);
                }
            }

            indicator: Rectangle {
                implicitWidth: 40
                implicitHeight: 20
                x: toggleSwitch.leftPadding
                y: parent.height / 2 - height / 2
                radius: height / 2
                color: toggleSwitch.checked ? Colors.primary : Colors.surfaceBright
                border.color: toggleSwitch.checked ? Colors.primary : Colors.outline

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }

                Rectangle {
                    x: toggleSwitch.checked ? parent.width - width - 2 : 2
                    y: 2
                    width: parent.height - 4
                    height: width
                    radius: width / 2
                    color: toggleSwitch.checked ? Colors.background : Colors.overSurfaceVariant

                    Behavior on x {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                    }
                }
            }
            background: null
        }
    }

    // Inline component for number input rows
    component NumberInputRow: RowLayout {
        id: numberInputRowRoot
        property string label: ""
        property int value: 0
        property int minValue: 0
        property int maxValue: 100
        property string suffix: ""
        signal valueEdited(int newValue)

        Layout.fillWidth: true
        spacing: 8
        opacity: enabled ? 1.0 : 0.5

        Text {
            text: numberInputRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.fillWidth: true
        }

        StyledRect {
            variant: "common"
            Layout.preferredWidth: 60
            Layout.preferredHeight: 32
            radius: Styling.radius(-2)

            TextInput {
                id: numberTextInput
                anchors.fill: parent
                anchors.margins: 8
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
                selectByMouse: true
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                validator: IntValidator { bottom: numberInputRowRoot.minValue; top: numberInputRowRoot.maxValue }

                // Sync text when external value changes
                readonly property int configValue: numberInputRowRoot.value
                onConfigValueChanged: {
                    if (!activeFocus && text !== configValue.toString()) {
                        text = configValue.toString();
                    }
                }
                Component.onCompleted: text = configValue.toString()

                onEditingFinished: {
                    let newVal = parseInt(text);
                    if (!isNaN(newVal)) {
                        newVal = Math.max(numberInputRowRoot.minValue, Math.min(numberInputRowRoot.maxValue, newVal));
                        numberInputRowRoot.valueEdited(newVal);
                    }
                }
            }
        }

        Text {
            text: numberInputRowRoot.suffix
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overSurfaceVariant
            visible: suffix !== ""
        }
    }

    // Inline component for decimal input rows
    component DecimalInputRow: RowLayout {
        id: decimalInputRowRoot
        property string label: ""
        property real value: 0.0
        property real minValue: 0.0
        property real maxValue: 1.0
        property string suffix: ""
        signal valueEdited(real newValue)

        Layout.fillWidth: true
        spacing: 8
        opacity: enabled ? 1.0 : 0.5

        Text {
            text: decimalInputRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.fillWidth: true
        }

        StyledRect {
            variant: "common"
            Layout.preferredWidth: 60
            Layout.preferredHeight: 32
            radius: Styling.radius(-2)

            TextInput {
                id: decimalTextInput
                anchors.fill: parent
                anchors.margins: 8
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
                selectByMouse: true
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator { bottom: decimalInputRowRoot.minValue; top: decimalInputRowRoot.maxValue; decimals: 2 }

                // Sync text when external value changes
                readonly property real configValue: decimalInputRowRoot.value
                onConfigValueChanged: {
                    if (!activeFocus) {
                        // Check if roughly equal to avoid formatting loops
                        if (Math.abs(parseFloat(text) - configValue) > 0.001 || text === "")
                            text = configValue.toFixed(1); // Default format
                    }
                }
                Component.onCompleted: text = configValue.toFixed(1)

                onEditingFinished: {
                    let newVal = parseFloat(text);
                    if (!isNaN(newVal)) {
                        newVal = Math.max(decimalInputRowRoot.minValue, Math.min(decimalInputRowRoot.maxValue, newVal));
                        decimalInputRowRoot.valueEdited(newVal);
                    }
                }
            }
        }

        Text {
            text: decimalInputRowRoot.suffix
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overSurfaceVariant
            visible: suffix !== ""
        }
    }

    // Main content
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.colorPickerActive

        // Horizontal slide + fade animation
        opacity: root.colorPickerActive ? 0 : 1
        transform: Translate {
            x: root.colorPickerActive ? -30 : 0

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            // Header wrapper
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titlebar.height

                PanelTitlebar {
                    id: titlebar
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    title: "Compositor"
                    // statusText can be added if we track unsaved changes
                }
            }

            // Tabs Switch
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                
                SegmentedSwitch {
                    anchors.centerIn: parent
                    options: [
                        { label: "Hyprland", value: "hyprland", icon: Icons.layout },
                        { label: "Coming Soon", value: "placeholder", icon: Icons.clock }
                    ]
                    currentIndex: 0
                    onIndexChanged: (index) => stackLayout.currentIndex = index
                }
            }

            // Stack for content
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: stackLayout.height

                    StackLayout {
                        id: stackLayout
                        width: root.contentWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: currentIndex === 0 ? hyprlandPage.implicitHeight : placeholderPage.implicitHeight
                        currentIndex: 0

                    // ═══════════════════════════════════════════════════════════════
                    // HYPRLAND TAB
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        id: hyprlandPage
                        Layout.fillWidth: true
                        spacing: 16

                        // General Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "General"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        // Layout Selector
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "Layout"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                                color: Colors.overBackground
                                Layout.fillWidth: true
                            }
                            SegmentedSwitch {
                                options: [
                                    { label: "Dwindle", value: "dwindle" },
                                    { label: "Master", value: "master" }
                                ]
                                currentIndex: Config.hyprland.layout === "master" ? 1 : 0
                                onIndexChanged: index => {
                                    Config.hyprland.layout = index === 1 ? "master" : "dwindle";
                                }
                            }
                        }

                        ToggleRow {
                            label: "Sync Border Size"
                            checked: Config.hyprland.syncBorderWidth ?? false
                            onToggled: value => Config.hyprland.syncBorderWidth = value
                        }

                        NumberInputRow {
                            label: "Border Size"
                            value: Config.hyprland.borderSize ?? 2
                            minValue: 0
                            maxValue: 10
                            suffix: "px"
                            enabled: !Config.hyprland.syncBorderWidth
                            onValueEdited: newValue => {
                                Config.hyprland.borderSize = newValue;
                            }
                        }

                        ToggleRow {
                            label: "Sync Rounding"
                            checked: Config.hyprland.syncRoundness ?? true
                            onToggled: value => Config.hyprland.syncRoundness = value
                        }

                        NumberInputRow {
                            label: "Rounding"
                            value: Config.hyprland.rounding ?? 16
                            minValue: 0
                            maxValue: 30
                            suffix: "px"
                            enabled: !Config.hyprland.syncRoundness
                            onValueEdited: newValue => {
                                Config.hyprland.rounding = newValue;
                            }
                        }

                        NumberInputRow {
                            label: "Gaps In"
                            value: Config.hyprland.gapsIn ?? 5
                            minValue: 0
                            maxValue: 50
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.hyprland.gapsIn = newValue;
                            }
                        }

                        NumberInputRow {
                            label: "Gaps Out"
                            value: Config.hyprland.gapsOut ?? 10
                            minValue: 0
                            maxValue: 50
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.hyprland.gapsOut = newValue;
                            }
                        }

                        NumberInputRow {
                            label: "Border Angle"
                            value: Config.hyprland.borderAngle ?? 45
                            minValue: 0
                            maxValue: 360
                            suffix: "deg"
                            onValueEdited: newValue => Config.hyprland.borderAngle = newValue
                        }

                        NumberInputRow {
                            label: "Inactive Angle"
                            value: Config.hyprland.inactiveBorderAngle ?? 45
                            minValue: 0
                            maxValue: 360
                            suffix: "deg"
                            onValueEdited: newValue => Config.hyprland.inactiveBorderAngle = newValue
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // Colors Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Colors"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        ToggleRow {
                            label: "Sync Border Color"
                            checked: Config.hyprland.syncBorderColor ?? false
                            onToggled: value => Config.hyprland.syncBorderColor = value
                        }

                        // Active Border Color
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            enabled: !Config.hyprland.syncBorderColor
                            opacity: enabled ? 1.0 : 0.5

                            Text {
                                text: "Active Border"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                                color: Colors.overBackground
                                Layout.preferredWidth: 100
                            }

                            ColorButton {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                colorNames: root.colorNames
                                currentColor: (Config.hyprland.activeBorderColor && Config.hyprland.activeBorderColor.length > 0) ? Config.hyprland.activeBorderColor[0] : "primary"
                                dialogTitle: "Active Border Color"
                                compact: false

                                onOpenColorPicker: (names, cur, title) => {
                                    root.openColorPicker(names, cur, title, function(color) {
                                        Config.hyprland.activeBorderColor = [color];
                                    });
                                }
                            }
                        }

                         // Inactive Border Color
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Inactive Border"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                                color: Colors.overBackground
                                Layout.preferredWidth: 100
                            }

                            ColorButton {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                colorNames: root.colorNames
                                currentColor: (Config.hyprland.inactiveBorderColor && Config.hyprland.inactiveBorderColor.length > 0) ? Config.hyprland.inactiveBorderColor[0] : "surface"
                                dialogTitle: "Inactive Border Color"
                                compact: false

                                onOpenColorPicker: (names, cur, title) => {
                                    root.openColorPicker(names, cur, title, function(color) {
                                        Config.hyprland.inactiveBorderColor = [color];
                                    });
                                }
                            }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // Shadows Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Shadows"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        ToggleRow {
                            label: "Enabled"
                            checked: Config.hyprland.shadowEnabled ?? true
                            onToggled: value => {
                                Config.hyprland.shadowEnabled = value;
                            }
                        }

                        ToggleRow {
                            label: "Sync Color"
                            checked: Config.hyprland.syncShadowColor ?? false
                            onToggled: value => Config.hyprland.syncShadowColor = value
                        }

                        ToggleRow {
                            label: "Sync Opacity"
                            checked: Config.hyprland.syncShadowOpacity ?? false
                            onToggled: value => Config.hyprland.syncShadowOpacity = value
                        }

                        NumberInputRow {
                            label: "Range"
                            value: Config.hyprland.shadowRange ?? 4
                            minValue: 0
                            maxValue: 100
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.hyprland.shadowRange = newValue;
                            }
                        }

                        NumberInputRow {
                            label: "Render Power"
                            value: Config.hyprland.shadowRenderPower ?? 3
                            minValue: 1
                            maxValue: 4
                            onValueEdited: newValue => Config.hyprland.shadowRenderPower = newValue
                        }

                        DecimalInputRow {
                            label: "Scale"
                            value: Config.hyprland.shadowScale ?? 1.0
                            minValue: 0.0
                            maxValue: 1.0
                            onValueEdited: newValue => Config.hyprland.shadowScale = newValue
                        }

                        DecimalInputRow {
                            label: "Opacity"
                            value: Config.hyprland.shadowOpacity ?? 0.5
                            minValue: 0.0
                            maxValue: 1.0
                            enabled: !Config.hyprland.syncShadowOpacity
                            onValueEdited: newValue => Config.hyprland.shadowOpacity = newValue
                        }

                        ToggleRow {
                            label: "Sharp"
                            checked: Config.hyprland.shadowSharp ?? false
                            onToggled: value => Config.hyprland.shadowSharp = value
                        }

                        ToggleRow {
                            label: "Ignore Window"
                            checked: Config.hyprland.shadowIgnoreWindow ?? true
                            onToggled: value => Config.hyprland.shadowIgnoreWindow = value
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // Blur Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Blur"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        ToggleRow {
                            label: "Enabled"
                            checked: Config.hyprland.blurEnabled ?? true
                            onToggled: value => {
                                Config.hyprland.blurEnabled = value;
                            }
                        }

                        NumberInputRow {
                            label: "Size"
                            value: Config.hyprland.blurSize ?? 8
                            minValue: 0
                            maxValue: 20
                            onValueEdited: newValue => {
                                Config.hyprland.blurSize = newValue;
                            }
                        }

                        NumberInputRow {
                            label: "Passes"
                            value: Config.hyprland.blurPasses ?? 1
                            minValue: 0
                            maxValue: 4
                            onValueEdited: newValue => {
                                Config.hyprland.blurPasses = newValue;
                            }
                        }

                        ToggleRow {
                            label: "Xray"
                            checked: Config.hyprland.blurXray ?? false
                            onToggled: value => Config.hyprland.blurXray = value
                        }

                        ToggleRow {
                            label: "New Optimizations"
                            checked: Config.hyprland.blurNewOptimizations ?? true
                            onToggled: value => Config.hyprland.blurNewOptimizations = value
                        }

                        ToggleRow {
                            label: "Ignore Opacity"
                            checked: Config.hyprland.blurIgnoreOpacity ?? true
                            onToggled: value => Config.hyprland.blurIgnoreOpacity = value
                        }

                        DecimalInputRow {
                            label: "Noise"
                            value: Config.hyprland.blurNoise ?? 0.01
                            minValue: 0.0
                            maxValue: 1.0
                            onValueEdited: newValue => Config.hyprland.blurNoise = newValue
                        }

                        DecimalInputRow {
                            label: "Contrast"
                            value: Config.hyprland.blurContrast ?? 0.89
                            minValue: 0.0
                            maxValue: 2.0
                            onValueEdited: newValue => Config.hyprland.blurContrast = newValue
                        }

                        DecimalInputRow {
                            label: "Brightness"
                            value: Config.hyprland.blurBrightness ?? 0.81
                            minValue: 0.0
                            maxValue: 2.0
                            onValueEdited: newValue => Config.hyprland.blurBrightness = newValue
                        }
                        
                        DecimalInputRow {
                            label: "Vibrancy"
                            value: Config.hyprland.blurVibrancy ?? 0.17
                            minValue: 0.0
                            maxValue: 1.0
                            onValueEdited: newValue => Config.hyprland.blurVibrancy = newValue
                        }
                    }
                    
                    // Bottom Padding
                    Item { Layout.fillWidth: true; Layout.preferredHeight: 16 }
                }

                    // ═══════════════════════════════════════════════════════════════
                    // COMING SOON TAB
                    // ═══════════════════════════════════════════════════════════════
                    Item {
                        id: placeholderPage
                        Layout.fillWidth: true
                        implicitHeight: 300

                        ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 16

                        Text {
                            text: Icons.clock
                            font.family: Icons.font
                            font.pixelSize: 64
                            color: Colors.surfaceVariant
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Coming Soon"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(2)
                            font.bold: true
                            color: Colors.overBackground
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Support for more compositors\nis planned for future updates."
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            color: Colors.overSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
    }

    // Color picker view (shown when colorPickerActive)
    Item {
        id: colorPickerContainer
        anchors.fill: parent
        clip: true

        // Horizontal slide + fade animation (enters from right)
        opacity: root.colorPickerActive ? 1 : 0
        transform: Translate {
            x: root.colorPickerActive ? 0 : 30

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        // Prevent interaction when hidden
        enabled: root.colorPickerActive

        // Block interaction with elements behind when active
        MouseArea {
            anchors.fill: parent
            enabled: root.colorPickerActive
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: event => event.accepted = true
            onReleased: event => event.accepted = true
            onWheel: event => event.accepted = true
        }

        ColorPickerView {
            id: colorPickerContent
            anchors.fill: parent
            anchors.leftMargin: root.sideMargin
            anchors.rightMargin: root.sideMargin
            colorNames: root.colorPickerColorNames
            currentColor: root.colorPickerCurrentColor
            dialogTitle: root.colorPickerDialogTitle

            onColorSelected: color => root.handleColorSelected(color)
            onClosed: root.closeColorPicker()
        }
    }
}
