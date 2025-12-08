pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 * Provides volume control, mute toggling, and access to app nodes and devices.
 */
Singleton {
    id: root

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00
    property real value: sink?.audio?.volume ?? 0

    signal sinkProtectionTriggered(string reason);

    PwObjectTracker {
        objects: [sink, source]
    }

    // Helper functions
    function friendlyDeviceName(node) {
        return (node?.nickname || node?.description || "Unknown");
    }

    function appNodeDisplayName(node) {
        return (node?.properties?.["application.name"] || node?.description || node?.name || "Unknown");
    }

    // Filter functions for nodes
    function correctType(node, isSink) {
        return (node?.isSink === isSink) && node?.audio;
    }

    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => {
            return root.correctType(node, isSink) && node.isStream;
        });
    }

    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream;
        });
    }

    // Filtered lists for output and input
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Control functions
    function toggleMute() {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }

    function toggleMicMute() {
        if (source?.audio) {
            source.audio.muted = !source.audio.muted;
        }
    }

    function incrementVolume() {
        if (sink?.audio) {
            const currentVolume = sink.audio.volume;
            const step = currentVolume < 0.1 ? 0.01 : 0.02;
            sink.audio.volume = Math.min(1, sink.audio.volume + step);
        }
    }

    function decrementVolume() {
        if (sink?.audio) {
            const currentVolume = sink.audio.volume;
            const step = currentVolume < 0.1 ? 0.01 : 0.02;
            sink.audio.volume = Math.max(0, sink.audio.volume - step);
        }
    }

    function setVolume(volume: real) {
        if (sink?.audio) {
            sink.audio.volume = Math.max(0, Math.min(hardMaxValue, volume));
        }
    }

    function setMicVolume(volume: real) {
        if (source?.audio) {
            source.audio.volume = Math.max(0, Math.min(hardMaxValue, volume));
        }
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Volume icon helper
    function volumeIcon(volume: real, muted: bool): string {
        if (muted) return Icons.speakerX;
        if (volume <= 0) return Icons.speakerNone;
        if (volume < 0.33) return Icons.speakerLow;
        return Icons.speakerHigh;
    }

    Connections {
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (sink.ready && (isNaN(sink.audio.volume) || sink.audio.volume === undefined || sink.audio.volume === null)) {
                sink.audio.volume = 0;
            }
        }
    }
}
