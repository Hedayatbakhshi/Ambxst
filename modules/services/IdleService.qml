pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

Singleton {
    id: root

    // General Idle Settings
    property string lockCmd: Config.system.idle.general.lock_cmd ?? "ambxst lock"
    property string beforeSleepCmd: Config.system.idle.general.before_sleep_cmd ?? "loginctl lock-session"
    property string afterSleepCmd: Config.system.idle.general.after_sleep_cmd ?? "ambxst screen on"
    
    // Login Lock Daemon
    // Helper script that listens to Lock signal and executes lockCmd from config
    Process {
        id: loginLockProc
        running: true
        command: ["bash", Qt.resolvedUrl("../../scripts/loginlock.sh").toString().replace("file://", "")]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("loginlock.sh exited with code " + exitCode + ". Restarting...");
                loginLockRestartTimer.start()
            }
        }
    }
    
    Timer {
        id: loginLockRestartTimer
        interval: 1000
        repeat: false
        onTriggered: loginLockProc.running = true
    }

    // Sleep Monitor Daemon
    // Helper script that listens to PrepareForSleep signal and executes sleep commands from config
    Process {
        id: sleepMonitorProc
        running: true
        command: ["bash", Qt.resolvedUrl("../../scripts/sleep_monitor.sh").toString().replace("file://", "")]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("sleep_monitor.sh exited with code " + exitCode + ". Restarting...");
                sleepMonitorRestartTimer.start()
            }
        }
    }

    Timer {
        id: sleepMonitorRestartTimer
        interval: 1000
        repeat: false
        onTriggered: sleepMonitorProc.running = true
    }

    // Dynamic Listeners
    Instantiator {
        model: Config.system.idle.listeners
        
        delegate: QtObject {
            id: listenerObject
            required property var modelData
            
            property int timeoutVal: modelData.timeout || 60
            property string onTimeoutCmd: modelData.onTimeout || ""
            property string onResumeCmd: modelData.onResume || ""

            property var monitor: IdleMonitor {
                timeout: listenerObject.timeoutVal * 1000 // Convert seconds to ms
                
                onIsIdleChanged: {
                    if (isIdle) {
                        if (listenerObject.onTimeoutCmd) {
                            console.log("Idle timeout reached (" + listenerObject.timeoutVal + "s): executing " + listenerObject.onTimeoutCmd);
                            timeoutProc.running = true;
                        }
                    } else {
                        if (listenerObject.onResumeCmd) {
                            console.log("Idle resume (" + listenerObject.timeoutVal + "s): executing " + listenerObject.onResumeCmd);
                            resumeProc.running = true;
                        }
                    }
                }
            }
            
            property var timeoutProc: Process {
                command: ["sh", "-c", listenerObject.onTimeoutCmd]
            }

            property var resumeProc: Process {
                command: ["sh", "-c", listenerObject.onResumeCmd]
            }
        }
    }
}
