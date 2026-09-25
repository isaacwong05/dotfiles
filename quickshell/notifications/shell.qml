import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

// QuickShell notification daemon + macOS-style Notification Center.
//
// Registers as org.freedesktop.Notifications (replacing Mako), renders frosted
// banner cards in the top-right corner, and a Notification Center panel
// (Super+N) with grouped history and clear-all.
//
// Hyprland blur for this shell is enabled in
// ~/.config/hypr/conf/window-rules.lua via the "notifications" layer
// namespace (keep this PanelWindow namespace aligned with that rule).

ShellRoot {
    id: root

    // ---- palette ----------------------------------------------------------
    // Dark macOS notification material: near-black glass, bright type and one
    // restrained hairline. The opaque-enough fill keeps text readable while
    // Hyprland provides the wallpaper blur underneath.
    readonly property string uiFont: "SF Pro Text"
    readonly property color fgPrimary: "#ffffff"
    readonly property color fgSecondary: "#c5c5c5"
    readonly property color fgMuted: "#8e8e93"
    readonly property color fgFaint: "#707078"
    readonly property color accent: "#f5f5f7"
    readonly property color danger: "#ff657a"
    // Frosted material: Hyprland's notification layerrule blurs the wallpaper
    // behind the card while the dark tint keeps text readable on light wallpapers.
    readonly property color glass: "#981b1b1f"
    readonly property color hairline: "#26ffffff"
    readonly property color hoverWash: "#1fffffff"
    readonly property string dashboardIconBase: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/"

    // Noto Sans falls back to Noto Color Emoji through Fontconfig. The Apple
    // logo is a private-use glyph and no installed Linux font provides it, so
    // use its readable name rather than rendering a missing-glyph square.
    function displayText(text) {
        return String(text || "").replace(/\uf8ff/g, "Apple")
    }

    // Command notifications sometimes use the Herdr workspace path as their
    // body (for example `~/1`). Show a useful completion message instead, and
    // keep real command output short enough for the card.
    function notificationDescription(notification) {
        if (!notification)
            return ""

        const body = root.displayText(notification.body).replace(/\s+/g, " ").trim()
        const sender = String(notification.appName || "").toLowerCase()
        const summary = String(notification.summary || "").toLowerCase()
        const isPi = sender === "pi" || sender === "pi-mono"
            || (sender === "notify-send" && summary.startsWith("pi "))
        const isWorkspaceMarker = /^~\/(?:\d+(?:\/.*)?|\.pi(?:\/.*)?)$/.test(body)

        if (isWorkspaceMarker || (isPi && body === ""))
            return "Command finished"
        if (body.length > 140)
            return body.slice(0, 137).trim() + "…"
        return body
    }

    // ---- state -------------------------------------------------------------
    property bool centerOpen: false
    property string centerTime: ""
    property string centerDate: ""
    // id -> Notification. The tracked-notifications model only inserts objects
    // on the next event-loop tick, so delegates resolve from this cache first.
    property var notifCache: ({})
    property var receivedAt: ({})

    // All banners use the same five-second lifetime. Apps frequently request
    // long/persistent timeouts, which previously made the dot timer appear on
    // only a subset of notifications.
    function bannerTimeoutFor(notification) {
        return notification ? 5000 : 0
    }

    // ---- notifications service ---------------------------------------------
    NotificationServer {
        id: server
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true
    }

    ListModel {
        id: bannerModel
    }

    // ---- IPC control (Hyprland keybind -> echo ... > control file) ---------
    Process {
        id: controlProcess
        command: ["sh", "-c", "f=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-notifications/control\"; if [ -r \"$f\" ]; then cat \"$f\"; : > \"$f\"; fi"]
        stdout: SplitParser {
            onRead: line => root.handleControl(line.trim())
        }
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!controlProcess.running)
                controlProcess.running = true
        }
    }

    function handleControl(command) {
        switch (command) {
        case "toggle":
            root.centerOpen ? closeCenter() : openCenter()
            break
        case "open":
            openCenter()
            break
        case "close":
            closeCenter()
            break
        case "clear":
            clearAll()
            break
        }
    }

    // ---- notification handling ---------------------------------------------
    // Keep it alive: tracked notifications survive in the center until
    // dismissed, instead of being destroyed after this handler runs.
    function onNotification(notification) {
        if (!notification)
            return

        notification.tracked = true
        root.notifCache[notification.id] = notification
        if (root.receivedAt[notification.id] === undefined)
            root.receivedAt[notification.id] = Date.now()

        // Purge any stale banner entry if the sender closes it on its own.
        notification.closed.connect(() => {
            // Keep cached data through the exit animation; cleanup happens when
            // finishBannerExit actually removes the ListModel row.
            root.startBannerExit(notification.id)
        })

        // Shown in the panel; a banner appears only when the center is closed.
        if (!root.centerOpen)
            root.pushBanner(notification)
    }

    // The banner model holds only ids; the live object is resolved in the
    // delegate. Storing Notification objects in ListModel rows crashes
    // Quickshell 0.3.1 when rows are removed mid-render.
    function pushBanner(notification) {
        // A replacement is a data update, not a dismissal: remove the old row
        // immediately so the replacement can animate in without a duplicate.
        root.dropBannerEntry(notification.id)
        bannerModel.insert(0, { nid: notification.id, leaving: false })

        while (bannerModel.count > 3)
            bannerModel.remove(bannerModel.count - 1)
    }

    function dropBannerEntry(id) {
        for (let i = 0; i < bannerModel.count; i++) {
            if (bannerModel.get(i).nid === id) {
                bannerModel.remove(i, 1)
                return
            }
        }
    }

    // Keep the model row alive through its exit animation. Removing it only in
    // finishBannerExit gives the ListView room to animate the remaining cards.
    function startBannerExit(id) {
        for (let i = 0; i < bannerModel.count; i++) {
            const row = bannerModel.get(i)
            if (row.nid === id) {
                if (!row.leaving)
                    bannerModel.setProperty(i, "leaving", true)
                return
            }
        }
    }

    function finishBannerExit(id) {
        for (let i = 0; i < bannerModel.count; i++) {
            const row = bannerModel.get(i)
            if (row.nid === id && row.leaving) {
                bannerModel.remove(i, 1)
                delete root.notifCache[id]
                delete root.receivedAt[id]
                return
            }
        }
    }

    // Banner auto-expired: hide it after its exit; transient notifications are
    // dismissed from the server at the same time but their row stays alive.
    function expireBanner(notification) {
        root.startBannerExit(notification.id)
        if (notification.transient)
            notification.dismiss()
    }

    // X button or a click with no actions: fully dismiss.
    function dismissNotification(notification) {
        if (!notification)
            return
        root.startBannerExit(notification.id)
        notification.dismiss()
    }

    // Clicking a card/entry invokes the sender's default action, or closes
    // the notification when there is none.
    function activate(notification) {
        if (!notification)
            return
        root.startBannerExit(notification.id)
        if (notification.actions.length > 0)
            notification.actions[0].invoke()
        else if (notification.transient)
            notification.dismiss()
    }

    // The standard card is sized around its 46 px icon; only optional controls
    // add height. This keeps ordinary banners as compact as macOS alerts.
    function bannerExtraHeight(notification) {
        if (!notification)
            return 0
        let extra = 0
        if (notification.actions.length > 0)
            extra += 38
        if (notification.hasInlineReply)
            extra += 40
        if (typeof notification.hints["value"] === "number")
            extra += 9
        return extra
    }
    function timeLabel(notification) {
        const received = root.receivedAt[notification.id]
        if (!received || Date.now() - received < 60000)
            return "now"
        const date = new Date(received)
        const today = new Date()
        if (date.toDateString() === today.toDateString())
            return Qt.formatDateTime(date, "h:mm AP")
        const yesterday = new Date(today)
        yesterday.setDate(today.getDate() - 1)
        if (date.toDateString() === yesterday.toDateString())
            return "Yesterday, " + Qt.formatDateTime(date, "h:mm AP")
        return Qt.formatDateTime(date, "MMM d, h:mm AP")
    }

    function findNotification(id) {
        const cached = root.notifCache[id]
        if (cached)
            return cached
        const all = server.trackedNotifications.values
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === id)
                return all[i]
        }
        return null
    }

    // ---- center panel -------------------------------------------------------
    function openCenter() {
        root.centerOpen = true
    }

    function closeCenter() {
        root.centerOpen = false
    }

    function clearAll() {
        const all = server.trackedNotifications.values.slice()
        for (let i = 0; i < all.length; i++)
            all[i].dismiss()
    }

    Timer {
        // Live clock for the panel header.
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            root.centerTime = Qt.formatDateTime(now, "h:mm AP")
            root.centerDate = Qt.formatDate(now, "dddd, MMMM d")
        }
    }

    // ==========================================================================
    // Banner strip (top-right)
    // ==========================================================================
    // WlrLayershell (not PanelWindow): PanelWindow has no namespace property and
    // would land in the default "quickshell" namespace, which window-rules.lua
    // explicitly excludes from blur.
    WlrLayershell {
        namespace: "notifications"
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.None
        anchors { top: true; right: true }
        implicitWidth: 360
        visible: bannerModel.count > 0 && !root.centerOpen
        implicitHeight: bannerList.height + 16
        color: "transparent"

        Behavior on implicitHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // ListView sizes itself via contentHeight; a Column+Repeater collapses
        // because Repeater reports no implicit size. Entrance animation lives
        // inside BannerCard, so no ListView transitions are needed.
        ListView {
            id: bannerList
            anchors { top: parent.top; topMargin: 16; right: parent.right; rightMargin: 16 }
            width: 344
            height: contentHeight
            spacing: 10
            interactive: false
            clip: false

            model: bannerModel
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
            }
            // The wrapper reads `model` in the delegate context; inline
            // components cannot see the delegate's context properties.
            delegate: Item {
                id: bannerDelegate
                width: bannerList.width
                // Keep each delegate exactly as tall as its card. The old
                // decorative sheets extended beneath this bound and overlapped
                // the following delegate, producing the dark bottom overlay.
                height: bannerCardItem.implicitHeight
                property var bannerNid: model.nid
                property bool leaving: model.leaving

                BannerCard {
                    id: bannerCardItem
                    width: parent.width
                    notification: root.findNotification(bannerDelegate.bannerNid)

                    // Entrance: slide in from the right with a spring pop.
                    Component.onCompleted: startEntrance()
                }

                onLeavingChanged: {
                    if (leaving)
                        exitAnimation.restart()
                }

                ParallelAnimation {
                    id: exitAnimation
                    NumberAnimation { target: bannerCardItem; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: bannerCardItem; property: "x"; to: 28; duration: 200; easing.type: Easing.InCubic }
                    onFinished: root.finishBannerExit(bannerDelegate.bannerNid)
                }
            }
        }
    }

    // ==========================================================================
    // Notification Center panel (right edge, Super+N)
    // ==========================================================================
    WlrLayershell {
        namespace: "notifications"
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.Exclusive
        anchors { top: true; right: true; bottom: true }
        implicitWidth: 400
        visible: root.centerOpen
        color: "transparent"

        Item {
            id: centerRoot
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.closeCenter()
            Component.onCompleted: forceActiveFocus()

            // Clicking the transparent strip left of the panel closes it.
            MouseArea {
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                width: 10
                onClicked: root.closeCenter()
            }

            Rectangle {
                id: panelCard
                anchors { top: parent.top; topMargin: 10; bottom: parent.bottom; bottomMargin: 10 }
                width: 380
                radius: 18
                color: root.glass
                border.width: 1
                border.color: root.hairline
                clip: true

                x: root.centerOpen ? 10 : 434
                Behavior on x {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                // ---- header ----------------------------------------------------
                ColumnLayout {
                    id: panelHeader
                    anchors { top: parent.top; topMargin: 22; left: parent.left; leftMargin: 22; right: parent.right; rightMargin: 22 }
                    spacing: 6

                    RowLayout {
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: root.centerDate.toUpperCase()
                            color: fgMuted
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Clear All"
                            color: server.trackedNotifications.values.length > 0 ? accent : fgFaint
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            opacity: 0.9
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: server.trackedNotifications.values.length > 0
                                onClicked: root.clearAll()
                            }
                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }
                        }
                    }

                    Text {
                        text: root.centerTime
                        color: fgPrimary
                        font.pixelSize: 30
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    anchors { left: parent.left; leftMargin: 22; right: parent.right; rightMargin: 22 }
                    y: 104
                    height: 1
                    color: "#10ffffff"
                }

                // ---- list -------------------------------------------------------
                ListView {
                    id: centerList
                    z: 1
                    anchors { top: parent.top; topMargin: 116; bottom: parent.bottom; bottomMargin: 14; left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12 }
                    spacing: 10
                    clip: true
                    // The tracked-notifications ObjectModel is the supported
                    // reactive source; its single role is modelData.
                    model: server.trackedNotifications

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160 }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
                    }

                    delegate: Item {
                        id: centerRow
                        width: centerList.width
                        height: 82

                        property bool hovered: false

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: centerRow.hovered ? Qt.lighter(root.glass, 1.12) : root.glass
                            border.width: 1
                            border.color: root.hairline
                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: centerRow.hovered = true
                                onExited: centerRow.hovered = false
                                onClicked: root.activate(modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors { leftMargin: 12; rightMargin: 10 }
                                spacing: 10

                                AppIcon {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    Layout.alignment: Qt.AlignVCenter
                                    notification: modelData
                                    tileRadius: 10
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        visible: modelData.appName !== ""
                                        text: modelData.appName
                                        color: fgMuted
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary
                                        color: fgPrimary
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: root.notificationDescription(modelData) !== ""
                                        text: root.notificationDescription(modelData)
                                        color: fgSecondary
                                        font.pixelSize: 13
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    }
                                }

                                Item {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignVCenter
                                    opacity: centerRow.hovered ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 120 }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: fgSecondary
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.dismissNotification(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: centerList
                    visible: server.trackedNotifications.values.length === 0
                    text: "No Notifications"
                    color: fgFaint
                    font.pixelSize: 12
                }
            }
        }
    }

    // ==========================================================================
    // Components
    // ==========================================================================

    // App icon: Dashboard Icons -> notification image/theme icon -> initial avatar.
    component AppIcon: Item {
        id: iconBox
        required property var notification
        property int tileRadius: 10

        readonly property string name: String(iconBox.notification.appName || "")
        readonly property string letter: iconBox.name
            ? iconBox.name.charAt(0).toUpperCase()
            : "?"
        readonly property color fallbackColor: {
            const colors = ["#0a84ff", "#bf5af2", "#ff9f0a", "#30d158", "#ff453a"]
            let hash = 0
            for (let i = 0; i < iconBox.name.length; i++)
                hash = ((hash << 5) - hash + iconBox.name.charCodeAt(i)) | 0
            return colors[Math.abs(hash) % colors.length]
        }
        readonly property string iconSource: {
            const image = String(iconBox.notification.image || "")
            const appIcon = String(iconBox.notification.appIcon || "")
            const desktopEntry = String(iconBox.notification.desktopEntry || "")
            // Notification image hints are direct data/URLs or local paths.
            if (image.startsWith("data:") || image.startsWith("file:") || image.startsWith("qrc:"))
                return image
            if (image.startsWith("/"))
                return "file://" + image
            // notify-send -i <absolute path> arrives as appIcon, not image.
            if (appIcon.startsWith("file:") || appIcon.startsWith("qrc:"))
                return appIcon
            if (appIcon.startsWith("/"))
                return "file://" + appIcon

            // Fall back to the installed icon theme when Dashboard Icons has
            // no matching logo or the network is unavailable.
            const candidates = [
                appIcon,
                desktopEntry.replace(/\.desktop$/, ""),
                iconBox.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
            ]
            for (let i = 0; i < candidates.length; i++) {
                const candidate = candidates[i]
                if (candidate && Quickshell.hasThemeIcon(candidate))
                    return Quickshell.iconPath(candidate, true)
            }
            return ""
        }
        function addDashboardSlug(slugs, value) {
            const raw = String(value || "").trim().toLowerCase()
            if (!raw || raw.startsWith("/") || raw.includes("://") || raw.startsWith("data:"))
                return

            const slug = raw.replace(/\.desktop$/, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
            if (!slug || slug === "notify-send")
                return

            const aliases = {
                "teams": "microsoft-teams",
                "teams-for-linux": "microsoft-teams",
                "microsoft-teams-for-linux": "microsoft-teams",
                "brave-browser": "brave",
                "brave-desktop": "brave",
                "brave-origin": "brave",
                "google-chrome-stable": "google-chrome",
                "chromium-browser": "chromium",
                "signal-desktop": "signal",
                "telegram-desktop": "telegram",
                "org-telegram-desktop": "telegram",
                "discord-canary": "discord",
                "discord-ptb": "discord",
                "spotify-client": "spotify",
                "com-mitchellh-ghostty": "ghostty",
                "onlyoffice-desktopeditors": "onlyoffice",
                "p3x-onenote": "microsoft-onenote",
                "pi": "pi-coding-agent",
                "pi-mono": "pi-coding-agent"
            }
            const variants = [slug]
            const withoutPrefix = slug.replace(/^(org|com|io|net)-/, "")
            const withoutSuffix = slug.replace(/-(for-linux|desktop|app|client|browser|stable|origin|notification|notifications)$/, "")
            if (withoutPrefix !== slug)
                variants.push(withoutPrefix)
            if (withoutSuffix !== slug)
                variants.push(withoutSuffix)

            for (let i = 0; i < variants.length; i++) {
                const candidate = aliases[variants[i]] || variants[i]
                if (slugs.indexOf(candidate) === -1)
                    slugs.push(candidate)
            }
        }

        readonly property var dashboardIconCandidates: {
            const slugs = []
            const summary = String(iconBox.notification.summary || "").toLowerCase()
            const body = String(iconBox.notification.body || "").toLowerCase()
            const name = iconBox.name.toLowerCase()
            // Pi currently arrives through notify-send, so identify it from
            // the notification content instead of branding every notify-send
            // message as Pi.
            if (name === "pi" || name === "pi-mono"
                    || (name === "notify-send" && (summary.startsWith("pi ") || body.includes(".pi"))))
                addDashboardSlug(slugs, "pi-coding-agent")

            // Sender-provided identifiers are more reliable than display names.
            addDashboardSlug(slugs, iconBox.notification.appIcon)
            addDashboardSlug(slugs, iconBox.notification.desktopEntry)
            addDashboardSlug(slugs, iconBox.name)
            return slugs.map(slug => root.dashboardIconBase + slug + ".svg")
        }
        property int dashboardIconIndex: 0
        onDashboardIconCandidatesChanged: dashboardIconIndex = 0


        Rectangle {
            anchors.fill: parent
            radius: iconBox.tileRadius
            color: iconBox.fallbackColor
            visible: !dashboardIcon.visible && !iconImage.visible
        }

        Image {
            id: dashboardIcon
            z: 2
            anchors.fill: parent
            anchors.margins: 1
            source: iconBox.dashboardIconCandidates.length > iconBox.dashboardIconIndex
                ? iconBox.dashboardIconCandidates[iconBox.dashboardIconIndex]
                : ""
            sourceSize { width: 96; height: 96 }
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            asynchronous: true
            visible: status === Image.Ready
            onStatusChanged: {
                if (status === Image.Error && iconBox.dashboardIconIndex < iconBox.dashboardIconCandidates.length - 1)
                    iconBox.dashboardIconIndex++
            }
        }

        Image {
            id: iconImage
            z: 1
            anchors.fill: parent
            anchors.margins: 1
            source: iconBox.iconSource
            sourceSize { width: 96; height: 96 }
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            asynchronous: true
            // An empty/Error/Loading source never paints; the avatar remains.
            visible: iconSource !== "" && status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !dashboardIcon.visible && !iconImage.visible
            text: iconBox.letter
            color: "white"
            font.family: root.uiFont
            font.pixelSize: parent.width * 0.42
            font.weight: Font.Bold
        }
    }

    // Banner card: frosted glass, icon, title/body, hover close, optional
    // actions, inline reply, and progress rendering.
    component BannerCard: Rectangle {
        id: bannerCard
        required property var notification

        readonly property bool critical: bannerCard.notification.urgency >= 2
        readonly property bool hovered: hoverArea.containsMouse

        radius: 16
        color: root.glass
        border.width: 1
        border.color: bannerCard.critical ? "#80ff657a" : root.hairline

        // Two text rows plus 12 px vertical padding need 68 px; the previous
        // 64 px floor let dense banners visually collide with the next card.
        implicitHeight: Math.max(58 + root.bannerExtraHeight(bannerCard.notification), 68)
        opacity: 0
        // x is offset by the entrance animation; y stays layout-driven.
        visible: bannerCard.notification != null

        readonly property real cardPadding: 12

        // Lifespan of this banner in ms; 0 = persistent (critical or
        // sender-requested). Shared by the dismiss timer and the countdown
        // frame so both stay in sync.
        readonly property real lifespan: root.bannerTimeoutFor(bannerCard.notification)

        // One shared clock drives both the dot matrix and automatic close.
        // Pausing this animation on hover pauses the close timeout too.
        property real remaining: 1
        onRemainingChanged: {
            if (remaining <= 0)
                root.expireBanner(bannerCard.notification)
        }
        NumberAnimation on remaining {
            running: bannerCard.lifespan > 0
            paused: bannerCard.hovered
            from: 1
            to: 0
            duration: Math.max(1, bannerCard.lifespan)
            easing.type: Easing.Linear
        }

        // Slide in from the right with a spring pop, macOS-style.
        function startEntrance() {
            entrance.restart()
        }

        SequentialAnimation {
            id: entrance
            ParallelAnimation {
                NumberAnimation { target: bannerCard; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: bannerCard; property: "x"; from: 24; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
            PauseAnimation { duration: 80 }
        }

        // Draining countdown border: the hairline recedes clockwise as the
        // auto-dismiss countdown runs (paused while hovered, like the timer).
        Canvas {
            id: countdownFrame
            anchors.fill: parent
            visible: bannerCard.lifespan > 0
            renderStrategy: Canvas.Cooperative
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (!countdownFrame.visible)
                    return
                const sw = 1
                const o = sw / 2
                const w = width - sw
                const h = height - sw
                const rad = Math.max(0, Math.min(bannerCard.radius, w / 2, h / 2))
                const perim = 2 * (w - 2 * rad) + 2 * (h - 2 * rad) + 2 * Math.PI * rad
                const drawn = Math.max(0, Math.min(perim, bannerCard.remaining * perim))
                ctx.beginPath()
                ctx.moveTo(o + w / 2, o)
                ctx.lineTo(o + w - rad, o)
                ctx.arcTo(o + w, o, o + w, o + rad, rad)
                ctx.lineTo(o + w, o + h - rad)
                ctx.arcTo(o + w, o + h, o + w - rad, o + h, rad)
                ctx.lineTo(o + rad, o + h)
                ctx.arcTo(o, o + h, o, o + h - rad, rad)
                ctx.lineTo(o, o + rad)
                ctx.arcTo(o, o, o + rad, o, rad)
                ctx.lineTo(o + w / 2, o)
                ctx.lineWidth = sw
                // Keep the countdown subordinate to the 1 px hairline rather
                // than turning the entire card into a bright outline.
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.15)
                ctx.lineCap = "butt"
                ctx.setLineDash([drawn, perim + 1])
                ctx.stroke()
            }
            Connections {
                target: bannerCard
                function onRemainingChanged() { countdownFrame.requestPaint() }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate(bannerCard.notification)
        }

        RowLayout {
            id: contentRow
            anchors.fill: parent
            // Keep the timestamp close to the card edge; the dismiss control
            // only appears on hover and overlays this small reserved gutter.
            anchors { leftMargin: bannerCard.cardPadding; rightMargin: bannerCard.cardPadding + 8; topMargin: bannerCard.cardPadding; bottomMargin: bannerCard.cardPadding }
            spacing: 11

            AppIcon {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                notification: bannerCard.notification
                tileRadius: 10
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 4

                // A common baseline keeps the smaller timestamp optically
                // aligned with the sender/title, not merely centered beside it.
                Item {
                    Layout.fillWidth: true
                    // Make room for the five-dot countdown below the time.
                    Layout.preferredHeight: Math.max(titleLabel.implicitHeight, timestampLabel.implicitHeight + 6)

                    Text {
                        id: titleLabel
                        anchors { left: parent.left; right: timestampLabel.left; rightMargin: 8 }
                        text: root.displayText(bannerCard.notification.summary)
                        color: root.fgPrimary
                        font.family: root.uiFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        id: timestampLabel
                        anchors { right: parent.right; baseline: titleLabel.baseline }
                        text: root.timeLabel(bannerCard.notification)
                        color: root.fgMuted
                        font.family: root.uiFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    // Small dot-matrix timer: it drains over the automatic
                    // lifetime and pauses while the card is hovered.
                    Row {
                        anchors { right: parent.right; top: timestampLabel.bottom; topMargin: 2 }
                        visible: bannerCard.lifespan > 0
                        spacing: 2

                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                width: 2
                                height: 2
                                radius: 1
                                color: root.fgMuted
                                // Five visible steps: one dot goes dim each
                                // second for the default five-second timeout.
                                opacity: index < Math.ceil(bannerCard.remaining * 5) ? 0.9 : 0.18
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.notificationDescription(bannerCard.notification) !== ""
                    text: root.notificationDescription(bannerCard.notification)
                    color: root.fgSecondary
                    font.family: root.uiFont
                    font.pixelSize: 13
                    maximumLineCount: bannerCard.critical ? 3 : 2
                    elide: Text.ElideRight
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }
        }

        Item {
            anchors { top: parent.top; right: parent.right; topMargin: 10; rightMargin: 10 }
            width: 18
            height: 18
            opacity: bannerCard.hovered ? 1 : 0
            visible: bannerCard.hovered
            scale: bannerCard.hovered ? 1 : 0.6
            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }
            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutBack }
            }

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: hoverClose.containsMouse ? root.hoverWash : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: root.fgSecondary
                font.family: root.uiFont
                font.pixelSize: 10
            }

            MouseArea {
                id: hoverClose
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissNotification(bannerCard.notification)
            }
        }

        ColumnLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: bannerCard.cardPadding; rightMargin: bannerCard.cardPadding; bottomMargin: bannerCard.cardPadding }
            spacing: 4
            visible: bannerCard.notification.actions.length > 0 || bannerCard.notification.hasInlineReply || (bannerCard.notification.hints && typeof bannerCard.notification.hints["value"] === "number")

            // Optional progress (hints: value/maximumValue, e.g. downloads).
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                visible: bannerCard.notification.hints && typeof bannerCard.notification.hints["value"] === "number"
                radius: 2
                color: "#26ffffff"

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, bannerCard.notification.hints.value / Math.max(1, bannerCard.notification.hints["maximum-value"] || 100)))
                    height: parent.height
                    radius: parent.radius
                    color: root.fgPrimary
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }

            // Action buttons, e.g. "Reply" / "Mark as read".
            RowLayout {
                Layout.fillWidth: true
                visible: bannerCard.notification.actions.length > 0
                spacing: 6

                Repeater {
                    model: bannerCard.notification.actions

                    Rectangle {
                        required property var modelData
                        Layout.preferredHeight: 28
                        radius: 9
                        border.width: 1
                        border.color: root.hairline
                        color: actionHover.containsMouse ? root.hoverWash : "transparent"
                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Text {
                            anchors.centerIn: parent
                            anchors { leftMargin: 12; rightMargin: 12 }
                            text: modelData.text
                            color: modelData.identifier === "default" ? root.accent : root.fgSecondary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: actionHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke()
                                root.removeBannerEntry(bannerCard.notification.id)
                            }
                        }
                    }
                }
            }

            // Inline reply (quick reply).
            RowLayout {
                Layout.fillWidth: true
                visible: bannerCard.notification.hasInlineReply
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 9
                    color: "#08ffffff"
                    border.width: 1
                    border.color: replyField.activeFocus ? "#3dffffff" : root.hairline

                    TextInput {
                        id: replyField
                        anchors.fill: parent
                        anchors { leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: Text.AlignVCenter
                        color: root.fgPrimary
                        font.pixelSize: 12
                        clip: true
                        text: ""

                        Keys.onReturnPressed: sendReply()
                        Keys.onEnterPressed: sendReply()
                    }

                    // Placeholder: TextInput has no stylable placeholder color here.
                    Text {
                        anchors.fill: replyField
                        anchors { leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: Text.AlignVCenter
                        visible: replyField.text === "" && !replyField.activeFocus
                        text: bannerCard.notification.inlineReplyPlaceholder || "Reply…"
                        color: root.fgFaint
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: "Send"
                    color: replyField.text !== "" ? root.accent : root.fgFaint
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.3
                    opacity: replyField.text !== "" ? 1 : 0.6

                    MouseArea {
                        anchors.fill: parent
                        enabled: replyField.text !== ""
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sendReply()
                    }
                }
            }
        }

        function sendReply() {
            if (replyField.text.trim() === "")
                return
            bannerCard.notification.sendInlineReply(replyField.text.trim())
            root.removeBannerEntry(bannerCard.notification.id)
        }
    }

    // ---- wiring -------------------------------------------------------------
    Component.onCompleted: {
        root.centerTime = Qt.formatDateTime(new Date(), "h:mm AP")
        root.centerDate = Qt.formatDate(new Date(), "dddd, MMMM d")
    }

    Connections {
        target: server
        function onNotification(notification) {
            root.onNotification(notification)
        }
    }
}