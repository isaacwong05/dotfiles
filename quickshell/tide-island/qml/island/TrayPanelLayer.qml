import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import IslandBackend
import "../controlcenter"

Item {
    id: trayPanel

    signal executionTriggered()

    readonly property var userConfig: UserConfig
    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily

    readonly property int itemCount: trayGrid.count
    readonly property int columns: Math.max(1, Math.min(6, itemCount))
    readonly property real cellSize: 56
    readonly property real gridPadding: 14
    readonly property int rowCount: Math.max(1, Math.ceil(itemCount / columns))
    readonly property real contentHeight: itemCount > 0
        ? gridPadding * 2 + rowCount * cellSize
        : gridPadding * 2 + 40

    anchors.fill: parent
    enabled: showCondition
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? StyleTokens.durationStandard : StyleTokens.durationFast
            easing.type: Easing.InOutQuad
        }
    }

    function needsAttention(item) {
        if (!item)
            return false
        const status = String(item.status).toLowerCase()
        return item.status === 2 || status.indexOf("needsattention") >= 0
    }

    function isPassive(item) {
        if (!item)
            return false
        const status = String(item.status).toLowerCase()
        return item.status === 0 || status.indexOf("passive") >= 0
    }

    function tooltipText(item) {
        if (!item)
            return ""
        const title = item.tooltipTitle || item.title || ""
        const description = item.tooltipDescription || ""
        return description ? (title ? title + "\n" + description : description) : title
    }

    function fallbackIconSource(item) {
        const source = item && item.icon ? String(item.icon) : ""
        const id = item && item.id ? String(item.id).toLowerCase() : ""
        if (id === "udiskie" || source.indexOf("drive-removable-media-usb-pendrive") >= 0)
            return "file:///usr/share/icons/Adwaita/scalable/devices/drive-removable-media.svg"
        return Quickshell.iconPath("application-x-executable")
    }

    function normalizedIconSource(item) {
        const source = item && item.icon ? String(item.icon) : ""
        const id = item && item.id ? String(item.id).toLowerCase() : ""
        return id === "udiskie" || source.indexOf("drive-removable-media-usb-pendrive") >= 0
            ? fallbackIconSource(item) : source
    }

    function displayMenu(item, source, x, y) {
        if (!item || !item.hasMenu)
            return
        const point = source.mapToItem(trayPanel, x, y)
        item.display(trayPanel, Math.round(point.x), Math.round(point.y))
    }

    Text {
        anchors.centerIn: parent
        visible: trayPanel.itemCount === 0
        text: "No tray apps"
        color: StyleTokens.textDim
        font.family: trayPanel.textFontFamily
        font.pixelSize: 14
    }

    GridView {
        id: trayGrid

        anchors.fill: parent
        anchors.margins: trayPanel.gridPadding
        visible: trayPanel.itemCount > 0
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: trayPanel.cellSize
        cellHeight: trayPanel.cellSize
        model: SystemTray.items

        delegate: Item {
            id: trayDelegate

            required property var modelData
            readonly property string tooltip: trayPanel.tooltipText(modelData)
            readonly property bool attention: trayPanel.needsAttention(modelData)
            readonly property bool passive: trayPanel.isPassive(modelData)
            property bool useFallbackIcon: false

            width: trayPanel.cellSize
            height: trayPanel.cellSize
            opacity: passive ? 0.72 : 1

            MatteSurface {
                anchors.fill: parent
                anchors.margins: 4
                radius: 14
                hovered: trayMouse.containsMouse
                pressed: trayMouse.pressed
            }

            IconImage {
                id: trayIcon

                anchors.centerIn: parent
                width: 24
                height: 24
                asynchronous: true
                source: trayDelegate.useFallbackIcon
                    ? trayPanel.fallbackIconSource(trayDelegate.modelData)
                    : trayPanel.normalizedIconSource(trayDelegate.modelData)

                onStatusChanged: {
                    if (status === Image.Error && !trayDelegate.useFallbackIcon)
                        trayDelegate.useFallbackIcon = true
                }
            }

            Connections {
                target: trayDelegate.modelData

                function onIconChanged() {
                    trayDelegate.useFallbackIcon = false
                }
            }

            Rectangle {
                visible: trayDelegate.attention
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 7
                anchors.topMargin: 7
                width: 8
                height: 8
                radius: 4
                color: StyleTokens.accent
                border.width: 1
                border.color: StyleTokens.black
            }

            MouseArea {
                id: trayMouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                ToolTip.visible: containsMouse && trayDelegate.tooltip !== ""
                ToolTip.text: trayDelegate.tooltip
                ToolTip.delay: 450
                ToolTip.timeout: 5000

                onClicked: (mouse) => {
                    const item = trayDelegate.modelData
                    if (!item)
                        return

                    if (mouse.button === Qt.RightButton) {
                        trayPanel.displayMenu(item, trayMouse, mouse.x, mouse.y)
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate()
                        trayPanel.executionTriggered()
                    } else if (item.onlyMenu && item.hasMenu) {
                        trayPanel.displayMenu(item, trayMouse, mouse.x, mouse.y)
                    } else {
                        item.activate()
                        trayPanel.executionTriggered()
                    }
                }

                onWheel: (wheel) => {
                    const item = trayDelegate.modelData
                    const xDelta = wheel.angleDelta.x || wheel.pixelDelta.x
                    const yDelta = wheel.angleDelta.y || wheel.pixelDelta.y
                    const horizontal = Math.abs(xDelta) > Math.abs(yDelta)
                    const delta = horizontal ? xDelta : yDelta
                    if (item && delta !== 0) {
                        item.scroll(delta, horizontal)
                        wheel.accepted = true
                    } else {
                        wheel.accepted = false
                    }
                }
            }
        }
    }
}
