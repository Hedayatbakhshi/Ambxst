pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.services
import qs.modules.globals
import qs.config

// --- CAMBIO ESTRUCTURAL: Usamos un 'Item' como raíz para contener la lógica y el FileView ---
Item {
    id: playerColors

    property string assetsPath: Qt.resolvedUrl("../../assets/matugen/")
    property string lastProcessedArtUrl: ""
    property string lastProcessedScheme: ""
    property var artworkConnections: null

    // Este FileView ahora solo se encarga de leer el JSON. Le damos un ID interno.
    FileView {
        id: colorsView
        path: Quickshell.dataPath("player_colors.json")
        preload: true
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property color background: "#1a1111"
            property color blue: "#cebdfe"
            property color blueContainer: "#4c3e76"
            property color cyan: "#84d5c4"
            property color cyanContainer: "#005045"
            property color error: "#ffb4ab"
            property color errorContainer: "#93000a"
            property color green: "#b7d085"
            property color greenContainer: "#3a4d10"
            property color inverseOnSurface: "#382e2d"
            property color inversePrimary: "#904a46"
            property color inverseSurface: "#f1dedd"
            property color magenta: "#fcb0d5"
            property color magentaContainer: "#6c3353"
            property color overBackground: "#f1dedd"
            property color overBlue: "#35275e"
            property color overBlueContainer: "#e8ddff"
            property color overCyan: "#00382f"
            property color overCyanContainer: "#9ff2e0"
            property color overError: "#690005"
            property color overErrorContainer: "#ffdad6"
            property color overGreen: "#253600"
            property color overGreenContainer: "#d3ec9e"
            property color overMagenta: "#521d3c"
            property color overMagentaContainer: "#ffd8e8"
            property color overPrimary: "#571d1c"
            property color overPrimaryContainer: "#ffdad7"
            property color overRed: "#561e19"
            property color overRedContainer: "#ffdad6"
            property color overSecondary: "#442928"
            property color overSecondaryContainer: "#ffdad7"
            property color overSurface: "#f1dedd"
            property color overSurfaceVariant: "#d8c2c0"
            property color overTertiary: "#402d04"
            property color overTertiaryContainer: "#ffdea7"
            property color outline: "#a08c8b"
            property color outlineVariant: "#534342"
            property color primary: "#ffb3ae"
            property color primaryContainer: "#733331"
            property color red: "#ffb4ab"
            property color redContainer: "#73332e"
            property color scrim: "#000000"
            property color secondary: "#e7bdb9"
            property color secondaryContainer: "#5d3f3d"
            property color shadow: "#000000"
            property color surface: "#1a1111"
            property color surfaceBright: "#423736"
            property color surfaceContainer: "#271d1d"
            property color surfaceContainerHigh: "#322827"
            property color surfaceContainerHighest: "#3d3231"
            property color surfaceContainerLow: "#231919"
            property color surfaceContainerLowest: "#140c0c"
            property color surfaceDim: "#1a1111"
            property color surfaceTint: "#ffb3ae"
            property color surfaceVariant: "#534342"
            property color tertiary: "#e2c28c"
            property color tertiaryContainer: "#594319"
            property color sourceColor: "#7f2424"
        }
    }

    // --- Las propiedades de color ahora están en el 'Item' raíz y leen desde 'colorsView.adapter' ---
    function applyOpacity(hexColor) {
        var c = Qt.color(hexColor);
        return Qt.rgba(c.r, c.g, c.b, Config.opacity);
    }

    property color background: Config.oledMode ? Qt.rgba(0, 0, 0, Config.opacity) : applyOpacity(colorsView.adapter.background)
    property color surface: applyOpacity(Qt.tint(background, Qt.rgba(colorsView.adapter.overBackground.r, colorsView.adapter.overBackground.g, colorsView.adapter.overBackground.b, 0.1)))
    property color surfaceBright: applyOpacity(Qt.tint(background, Qt.rgba(colorsView.adapter.overBackground.r, colorsView.adapter.overBackground.g, colorsView.adapter.overBackground.b, 0.2)))
    property color surfaceContainer: applyOpacity(colorsView.adapter.surfaceContainer)
    property color surfaceContainerHigh: applyOpacity(colorsView.adapter.surfaceContainerHigh)
    property color surfaceContainerHighest: applyOpacity(colorsView.adapter.surfaceContainerHighest)
    property color surfaceContainerLow: applyOpacity(colorsView.adapter.surfaceContainerLow)
    property color surfaceContainerLowest: applyOpacity(colorsView.adapter.surfaceContainerLowest)
    property color surfaceDim: applyOpacity(colorsView.adapter.surfaceDim)
    property color surfaceTint: applyOpacity(colorsView.adapter.surfaceTint)
    property color surfaceVariant: applyOpacity(colorsView.adapter.surfaceVariant)

    // Propiedades directas del adapter
    property color blue: colorsView.adapter.blue
    property color blueContainer: colorsView.adapter.blueContainer
    property color cyan: colorsView.adapter.cyan
    property color cyanContainer: colorsView.adapter.cyanContainer
    property color error: colorsView.adapter.error
    property color errorContainer: colorsView.adapter.errorContainer
    property color green: colorsView.adapter.green
    property color greenContainer: colorsView.adapter.greenContainer
    property color inverseOnSurface: colorsView.adapter.inverseOnSurface
    property color inversePrimary: colorsView.adapter.inversePrimary
    property color inverseSurface: colorsView.adapter.inverseSurface
    property color magenta: colorsView.adapter.magenta
    property color magentaContainer: colorsView.adapter.magentaContainer
    property color overBackground: colorsView.adapter.overBackground
    property color overBlue: colorsView.adapter.overBlue
    property color overBlueContainer: colorsView.adapter.overBlueContainer
    property color overCyan: colorsView.adapter.overCyan
    property color overCyanContainer: colorsView.adapter.overCyanContainer
    property color overError: colorsView.adapter.overError
    property color overErrorContainer: colorsView.adapter.overErrorContainer
    property color overGreen: colorsView.adapter.overGreen
    property color overGreenContainer: colorsView.adapter.overGreenContainer
    property color overMagenta: colorsView.adapter.overMagenta
    property color overMagentaContainer: colorsView.adapter.overMagentaContainer
    property color overPrimary: colorsView.adapter.overPrimary
    property color overPrimaryContainer: colorsView.adapter.overPrimaryContainer
    property color overRed: colorsView.adapter.overRed
    property color overRedContainer: colorsView.adapter.overRedContainer
    property color overSecondary: colorsView.adapter.overSecondary
    property color overSecondaryContainer: colorsView.adapter.overSecondaryContainer
    property color overSurface: colorsView.adapter.overSurface
    property color overSurfaceVariant: colorsView.adapter.overSurfaceVariant
    property color overTertiary: colorsView.adapter.overTertiary
    property color overTertiaryContainer: colorsView.adapter.overTertiaryContainer
    property color outline: colorsView.adapter.outline
    property color outlineVariant: colorsView.adapter.outlineVariant
    property color primary: colorsView.adapter.primary
    property color primaryContainer: colorsView.adapter.primaryContainer
    property color red: colorsView.adapter.red
    property color redContainer: colorsView.adapter.redContainer
    property color scrim: colorsView.adapter.scrim
    property color secondary: colorsView.adapter.secondary
    property color secondaryContainer: colorsView.adapter.secondaryContainer
    property color shadow: colorsView.adapter.shadow
    property color tertiary: colorsView.adapter.tertiary
    property color tertiaryContainer: colorsView.adapter.tertiaryContainer
    property color sourceColor: colorsView.adapter.sourceColor

    // --- Toda la lógica está ahora dentro del 'Item' raíz ---
    function runMatugen(artworkUrl) {
        if (!artworkUrl || artworkUrl === "")
            return;
        const currentScheme = GlobalStates.wallpaperManager ? GlobalStates.wallpaperManager.currentMatugenScheme : "scheme-tonal-spot";
        if (artworkUrl === lastProcessedArtUrl && currentScheme === lastProcessedScheme)
            return;
        lastProcessedArtUrl = artworkUrl;
        lastProcessedScheme = currentScheme;
        const configPath = assetsPath.replace("file://", "") + "player.toml";
        const cachePath = Quickshell.dataPath("player_artwork.jpg");
        if (artworkUrl.startsWith("http://") || artworkUrl.startsWith("https://")) {
            downloadProcess.command = ["curl", "-sL", "-o", cachePath, artworkUrl];
            downloadProcess.running = true;
        } else if (artworkUrl.startsWith("data:image/")) {
            const base64Data = artworkUrl.split(",")[1];
            base64Process.command = ["bash", "-c", `echo "${base64Data}" | base64 -d > "${cachePath}"`];
            base64Process.running = true;
        } else {
            const artPath = artworkUrl.replace("file://", "");
            matugenProcess.command = ["matugen", "image", artPath, "-c", configPath, "-t", currentScheme];
            matugenProcess.running = true;
        }
    }

    Process {
        id: downloadProcess
        running: false
        onExited: function (code) {
            if (code === 0) {
                const cachePath = Quickshell.dataPath("player_artwork.jpg");
                const configPath = assetsPath.replace("file://", "") + "player.toml";
                matugenProcess.command = ["matugen", "image", cachePath, "-c", configPath, "-t", lastProcessedScheme];
                matugenProcess.running = true;
            } else {
                console.warn("PlayerColors: Failed to download artwork, curl exit code:", code);
            }
        }
    }

    Process {
        id: base64Process
        running: false
        onExited: function (code) {
            if (code === 0) {
                const cachePath = Quickshell.dataPath("player_artwork.jpg");
                const configPath = assetsPath.replace("file://", "") + "player.toml";
                matugenProcess.command = ["matugen", "image", cachePath, "-c", configPath, "-t", lastProcessedScheme];
                matugenProcess.running = true;
            } else {
                console.warn("PlayerColors: Failed to decode base64 artwork, exit code:", code);
            }
        }
    }

    Process {
        id: matugenProcess
        running: false
        onExited: function (code) {
            if (code !== 0) {
                console.warn("PlayerColors: matugen failed with code:", code);
            }
        }
    }

    Component {
        id: artworkConnectionsComponent
        Connections {
            function onTrackArtUrlChanged() {
                if (target && target.trackArtUrl) {
                    playerColors.runMatugen(target.trackArtUrl);
                }
            }
        }
    }

    Connections {
        target: MprisController
        function onActivePlayerChanged() {
            if (playerColors.artworkConnections) {
                playerColors.artworkConnections.destroy();
                playerColors.artworkConnections = null;
            }
            if (MprisController.activePlayer) {
                playerColors.artworkConnections = artworkConnectionsComponent.createObject(playerColors, {
                    target: MprisController.activePlayer
                });
                if (MprisController.activePlayer.trackArtUrl) {
                    playerColors.runMatugen(MprisController.activePlayer.trackArtUrl);
                }
            }
        }
    }

    Connections {
        target: GlobalStates.wallpaperManager
        function onCurrentMatugenSchemeChanged() {
            if (MprisController.activePlayer && MprisController.activePlayer.trackArtUrl) {
                lastProcessedArtUrl = "";
                runMatugen(MprisController.activePlayer.trackArtUrl);
            }
        }
    }

    Component.onCompleted: {
        if (MprisController.activePlayer) {
            artworkConnections = artworkConnectionsComponent.createObject(playerColors, {
                target: MprisController.activePlayer
            });
            if (MprisController.activePlayer.trackArtUrl) {
                runMatugen(MprisController.activePlayer.trackArtUrl);
            }
        }
    }
}
