pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
pragma ComponentBehavior: Bound

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00

    signal sinkProtectionTriggered(string reason);

    PwObjectTracker {
        objects: [sink, source]
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
