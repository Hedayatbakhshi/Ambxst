import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.services
import qs.modules.theme
import qs.config

Item {
    id: root

    required property ShellScreen targetScreen
    property bool hasFullscreenWindow: false

    // These properties are now handled by parent ScreenFrame
    // but we can expose aliases or simple properties for drawing
    
    // We expect the parent to set these, but we can't 'required property' them 
    // easily if they are not passed in instantiation inside ScreenFrame.
    // However, ScreenFrame DOES instantiate this.
    // But in QML scope, 'ScreenFrame' properties are accessible if we are a child.
    
    // Let's rely on parent properties injection or direct access if needed, 
    // but better to keep it clean.
    
    // Actually, ScreenFrame.qml defines 'frameContent' inside it.
    // We can just use parent properties or aliases.
    
    // BUT to keep it standalone-ish or at least type-safe:
    // We will re-read Config here OR rely on parent.
    // Ideally, we shouldn't duplicate logic.
    
    readonly property bool frameEnabled: Config.bar?.frameEnabled ?? false
    
    // Use the same thickness logic as ScreenFrame to ensure consistency
    readonly property int thickness: {
        if (hasFullscreenWindow) return 0;
        const value = Config.bar?.frameThickness;
        if (typeof value !== "number")
            return 6;
        return Math.max(1, Math.min(Math.round(value), 40));
    }

    readonly property bool containBar: Config.bar?.containBar ?? false
    readonly property string barPos: Config.bar?.position ?? "top"

    // Reference the bar content to get dynamic size
    readonly property var barPanel: Visibilities.barPanels[targetScreen.name]
    readonly property int barSize: {
        if (!barPanel) return 44; // Fallback
        const isHoriz = barPos === "top" || barPos === "bottom";
        return isHoriz ? barPanel.barTargetHeight : barPanel.barTargetWidth;
    }

    property bool barReveal: true

    property real _barAnimProgress: barReveal ? 1.0 : 0.0
    Behavior on _barAnimProgress {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration / 2
            easing.type: Easing.OutCubic
        }
    }

    // This must match ScreenFrame.qml logic EXACTLY
    // ScreenFrame: barExpansion = barSize + thickness
    readonly property int barExpansion: Math.round((barSize + thickness) * _barAnimProgress)

    readonly property int topThickness: thickness + ((containBar && barPos === "top") ? barExpansion : 0)
    readonly property int bottomThickness: thickness + ((containBar && barPos === "bottom") ? barExpansion : 0)
    readonly property int leftThickness: thickness + ((containBar && barPos === "left") ? barExpansion : 0)
    readonly property int rightThickness: thickness + ((containBar && barPos === "right") ? barExpansion : 0)

    readonly property int actualFrameSize: frameEnabled ? thickness : 0

    readonly property int borderWidth: Config.theme.srBg.border[1]
    readonly property int innerRadius: Styling.radius(4 + borderWidth)

    // Visual part
    StyledRect {
        id: frameFill
        anchors.fill: parent
        variant: "bg"
        radius: 0
        enableBorder: false
        visible: root.frameEnabled
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: frameMask
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: frameMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            id: maskRect
            x: root.leftThickness
            y: root.topThickness
            width: parent.width - (root.leftThickness + root.rightThickness)
            height: parent.height - (root.topThickness + root.bottomThickness)
            radius: root.innerRadius
            color: "white"
            visible: width > 0 && height > 0
        }
    }
}
