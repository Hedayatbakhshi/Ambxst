pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.services

Item {
    id: playerColors

    property string assetsPath: Qt.resolvedUrl("../../assets/matugen/")

    FileView {
        id: spotifyColors
        path: Quickshell.cachePath("spotify_colors.json")
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property color background: "#1a1111"
            property color overBackground: "#f1dedd"
            property color overPrimary: "#571d1c"
            property color primary: "#ffb3ae"
            property color shadow: "#000000"
            property color sourceColor: "#7f2424"
        }
    }

    FileView {
        id: firefoxColors
        path: Quickshell.cachePath("firefox_colors.json")
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property color background: "#1a1111"
            property color overBackground: "#f1dedd"
            property color overPrimary: "#571d1c"
            property color primary: "#ffb3ae"
            property color shadow: "#000000"
            property color sourceColor: "#7f2424"
        }
    }

    FileView {
        id: chromiumColors
        path: Quickshell.cachePath("chromium_colors.json")
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property color background: "#1a1111"
            property color overBackground: "#f1dedd"
            property color overPrimary: "#571d1c"
            property color primary: "#ffb3ae"
            property color shadow: "#000000"
            property color sourceColor: "#7f2424"
        }
    }

    FileView {
        id: genericColors
        path: Quickshell.cachePath("generic_colors.json")
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property color background: "#1a1111"
            property color overBackground: "#f1dedd"
            property color overPrimary: "#571d1c"
            property color primary: "#ffb3ae"
            property color shadow: "#000000"
            property color sourceColor: "#7f2424"
        }
    }

    property color spotifyBackground: spotifyColors.adapter.background
    property color spotifyOverBackground: spotifyColors.adapter.overBackground
    property color spotifyOverPrimary: spotifyColors.adapter.overPrimary
    property color spotifyPrimary: spotifyColors.adapter.primary
    property color spotifyShadow: spotifyColors.adapter.shadow
    property color spotifySourceColor: spotifyColors.adapter.sourceColor

    property color firefoxBackground: firefoxColors.adapter.background
    property color firefoxOverBackground: firefoxColors.adapter.overBackground
    property color firefoxOverPrimary: firefoxColors.adapter.overPrimary
    property color firefoxPrimary: firefoxColors.adapter.primary
    property color firefoxShadow: firefoxColors.adapter.shadow
    property color firefoxSourceColor: firefoxColors.adapter.sourceColor

    property color chromiumBackground: chromiumColors.adapter.background
    property color chromiumOverBackground: chromiumColors.adapter.overBackground
    property color chromiumOverPrimary: chromiumColors.adapter.overPrimary
    property color chromiumPrimary: chromiumColors.adapter.primary
    property color chromiumShadow: chromiumColors.adapter.shadow
    property color chromiumSourceColor: chromiumColors.adapter.sourceColor

    property color genericBackground: genericColors.adapter.background
    property color genericOverBackground: genericColors.adapter.overBackground
    property color genericOverPrimary: genericColors.adapter.overPrimary
    property color genericPrimary: genericColors.adapter.primary
    property color genericShadow: genericColors.adapter.shadow
    property color genericSourceColor: genericColors.adapter.sourceColor

    property string lastProcessedArtUrl: ""
    property string lastProcessedPlayerType: ""

    function getPlayerType(player) {
        if (!player)
            return "generic";

        const dbusName = (player.dbusName || "").toLowerCase();
        const desktopEntry = (player.desktopEntry || "").toLowerCase();
        const identity = (player.identity || "").toLowerCase();

        if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
            return "spotify";
        if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
            return "chromium";
        if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
            return "firefox";
        return "generic";
    }

    function getColorsForPlayer(player) {
        const playerType = getPlayerType(player);
        switch (playerType) {
        case "spotify":
            return {
                background: spotifyBackground,
                overBackground: spotifyOverBackground,
                overPrimary: spotifyOverPrimary,
                primary: spotifyPrimary,
                shadow: spotifyShadow,
                sourceColor: spotifySourceColor
            };
        case "firefox":
            return {
                background: firefoxBackground,
                overBackground: firefoxOverBackground,
                overPrimary: firefoxOverPrimary,
                primary: firefoxPrimary,
                shadow: firefoxShadow,
                sourceColor: firefoxSourceColor
            };
        case "chromium":
            return {
                background: chromiumBackground,
                overBackground: chromiumOverBackground,
                overPrimary: chromiumOverPrimary,
                primary: chromiumPrimary,
                shadow: chromiumShadow,
                sourceColor: chromiumSourceColor
            };
        default:
            return {
                background: genericBackground,
                overBackground: genericOverBackground,
                overPrimary: genericOverPrimary,
                primary: genericPrimary,
                shadow: genericShadow,
                sourceColor: genericSourceColor
            };
        }
    }

    function runMatugen(artworkUrl, playerType) {
        if (!artworkUrl || artworkUrl === "" || !playerType)
            return;

        if (artworkUrl === lastProcessedArtUrl && playerType === lastProcessedPlayerType)
            return;

        lastProcessedArtUrl = artworkUrl;
        lastProcessedPlayerType = playerType;

        const configPath = assetsPath.replace("file://", "") + playerType + ".toml";

        if (artworkUrl.startsWith("http://") || artworkUrl.startsWith("https://")) {
            const cachePath = Quickshell.cachePath(`${playerType}_artwork.jpg`);
            downloadProcess.command = ["curl", "-sL", "-o", cachePath, artworkUrl];
            downloadProcess.running = true;
        } else {
            const artPath = artworkUrl.replace("file://", "");
            matugenProcess.command = ["matugen", "image", artPath, "-c", configPath];
            matugenProcess.running = true;
        }
    }

    Process {
        id: downloadProcess
        running: false
        
        onExited: function(code) {
            if (code === 0) {
                const cachePath = Quickshell.cachePath(`${lastProcessedPlayerType}_artwork.jpg`);
                const configPath = assetsPath.replace("file://", "") + lastProcessedPlayerType + ".toml";
                matugenProcess.command = ["matugen", "image", cachePath, "-c", configPath];
                matugenProcess.running = true;
            }
        }
    }

    Process {
        id: matugenProcess
        running: false
    }

    property var artworkConnections: null

    Component {
        id: artworkConnectionsComponent
        Connections {
            function onTrackArtUrlChanged() {
                if (target && target.trackArtUrl) {
                    const playerType = playerColors.getPlayerType(target);
                    playerColors.runMatugen(target.trackArtUrl, playerType);
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
                    const playerType = playerColors.getPlayerType(MprisController.activePlayer);
                    playerColors.runMatugen(MprisController.activePlayer.trackArtUrl, playerType);
                }
            }
        }
    }

    Component.onCompleted: {
        if (MprisController.activePlayer) {
            artworkConnections = artworkConnectionsComponent.createObject(playerColors, {
                target: MprisController.activePlayer
            });

            if (MprisController.activePlayer.trackArtUrl) {
                const playerType = getPlayerType(MprisController.activePlayer);
                runMatugen(MprisController.activePlayer.trackArtUrl, playerType);
            }
        }
    }
}
