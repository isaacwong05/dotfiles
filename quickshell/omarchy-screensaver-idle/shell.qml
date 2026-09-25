import QtQuick
import Quickshell
import Quickshell.Wayland

// Native Wayland idle monitoring without adding another daemon.
ShellRoot {
    id: root
    property bool launchPending: false

    IdleMonitor {
        id: idleMonitor
        enabled: true
        timeout: 600
        respectInhibitors: true

        onIsIdleChanged: {
            if (isIdle && !root.launchPending) {
                root.launchPending = true
                Quickshell.execDetached(["/home/isaac/.local/bin/omarchy-launch-screensaver", "force"])
            } else if (!isIdle) {
                root.launchPending = false
            }
        }
    }
}
