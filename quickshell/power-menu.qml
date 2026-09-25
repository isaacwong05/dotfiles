import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Standalone power menu. It is launched on demand by Hyprland, not autostarted.
ShellRoot {
    PanelWindow {
        id: panel
        visible: true
        anchors { left: true; right: true; top: true; bottom: true }
        exclusiveZone: 0
        color: "transparent"
        focusable: true

        function run(command) {
            Quickshell.execDetached(command)
            Qt.quit()
        }

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: "#66000000"
            focus: true
            Component.onCompleted: forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }

            Rectangle {
                id: menu
                width: 700
                height: 136
                anchors.centerIn: parent
                radius: 14
                color: "#b80b0b0b"
                border.width: 1
                border.color: "#55ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 0

                    PowerButton {
                        icon: "⏻"
                        label: "Power"
                        onTriggered: panel.run(["systemctl", "poweroff"])
                    }
                    PowerButton {
                        icon: "↻"
                        label: "Restart"
                        onTriggered: panel.run(["systemctl", "reboot"])
                    }
                    PowerButton {
                        icon: "⇥"
                        label: "Log out"
                        onTriggered: panel.run(["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""])
                    }
                    PowerButton {
                        icon: "⌁"
                        label: "UEFI"
                        onTriggered: panel.run(["systemctl", "reboot", "--firmware-setup"])
                    }
                    PowerButton {
                        icon: "✦"
                        label: "Screensaver"
                        onTriggered: panel.run(["/home/isaac/.local/bin/omarchy-launch-screensaver", "force"])
                    }
                }
            }

            Keys.onEscapePressed: {
                event.accepted = true
                Qt.quit()
            }
        }
    }

    component PowerButton: Rectangle {
        id: button
        required property string icon
        required property string label
        signal triggered()
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 11
        color: mouse.containsMouse ? "#30ffffff" : "transparent"

        // Fixed slots make every icon and label share the same baseline,
        // regardless of the glyph's font metrics.
        Item {
            anchors.centerIn: parent
            width: parent.width
            height: 78

            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 46
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: button.icon
                color: "white"
                font.pixelSize: 38
                font.weight: Font.Light
            }
            Text {
                anchors.top: parent.top
                anchors.topMargin: 57
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: button.label
                color: "white"
                font.pixelSize: 14
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
