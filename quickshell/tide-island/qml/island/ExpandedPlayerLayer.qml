import QtQuick
import IslandBackend
import Quickshell.Services.Mpris
import Quickshell.Widgets

Item {
    id: root

    signal controlPressed()
    signal backgroundClicked()
    signal closeRequested()
    signal keyboardFocusRequested()
    signal keyboardFocusReleased()
    signal previousRequested()

    readonly property var userConfig: UserConfig

    property bool showCondition: false
    property string currentArtUrl: ""
    property string currentTrack: ""
    property string currentArtist: ""
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"
    property real trackProgress: 0
    property var activePlayer: null
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property real visualizerPhase: 0
    property int currentPage: 0
    property int pendingPage: -1
    readonly property int pageCount: 2
    property real pageProgress: 0
    readonly property real clampedPageProgress: Math.max(0, Math.min(1, pageProgress))
    readonly property real pageSlideDistance: Math.max(1, viewport.width + 24)

    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

    function visualizerLevel(index) {
        const phase = visualizerPhase + index * 0.78;
        const primary = (Math.sin(phase) + 1) * 0.5;
        const secondary = (Math.sin(phase * 2 + index * 0.95) + 1) * 0.5;
        return 0.22 + primary * 0.42 + secondary * 0.24;
    }

    function pausedVisualizerLevel(index) {
        const levels = [0.34, 0.58, 0.82, 0.58, 0.34];
        return levels[index] || 0.4;
    }

    function togglePlayback() {
        if (!activePlayer || !activePlayer.canControl) return;

        if (activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying();
            return;
        }

        if (activePlayer.playbackState === MprisPlaybackState.Playing) {
            if (activePlayer.canPause) activePlayer.pause();
            return;
        }

        if (activePlayer.canPlay) activePlayer.play();
    }

    function showPage(page) {
        settlePage(page);
    }

    function settlePage(page) {
        const targetPage = Math.max(0, Math.min(pageCount - 1, page));
        pendingPage = -1;
        pageSettleAnimation.stop();
        pageStrip.interactive = false;
        pendingPage = targetPage;
        pageSettleAnimation.startProgress = clampedPageProgress;
        pageSettleAnimation.endProgress = targetPage;

        if (Math.abs(clampedPageProgress - targetPage) < 0.001) {
            pageProgress = targetPage;
            finishPageSettle();
            return;
        }

        pageSettleAnimation.restart();
    }

    function finishPageSettle() {
        if (pendingPage < 0)
            return;

        currentPage = pendingPage;
        pendingPage = -1;
        pageProgress = currentPage;
        updateKeyboardFocusForPage();
    }

    function updateKeyboardFocusForPage() {
        if (showCondition)
            keyboardFocusRequested();
        else
            keyboardFocusReleased();
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
    }

    function openTrayPage() {
        showPage(1);
    }

    anchors.fill: parent
    focus: showCondition
    opacity: showCondition ? 1 : 0

    Keys.onEscapePressed: event => {
        root.closeRequested();
        event.accepted = true;
    }

    onShowConditionChanged: {
        if (!showCondition) {
            pendingPage = -1;
            pageSettleAnimation.stop();
            currentPage = 0;
            pageProgress = 0;
        }
        updateKeyboardFocusForPage();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 300 : 100
            easing.type: Easing.InOutQuad
        }
    }

    SequentialAnimation {
        id: pageSettleAnimation

        property real startProgress: 0
        property real endProgress: 0

        NumberAnimation {
            target: root
            property: "pageProgress"
            from: pageSettleAnimation.startProgress
            to: pageSettleAnimation.endProgress
            duration: 220
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.finishPageSettle()
        }
    }

    Timer {
        interval: 64
        repeat: true
        running: showCondition && isPlaying && currentPage === 0
        onTriggered: {
            visualizerPhase += 0.18;
            if (visualizerPhase > Math.PI * 2) visualizerPhase -= Math.PI * 2;
        }
    }

    Item {
        id: viewport

        anchors.fill: parent
        clip: true

        MouseArea {
            id: pageSwipeArea

            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.LeftButton
            preventStealing: false

            property real startX: 0
            property int startPage: 0
            property real startProgress: 0
            property bool moved: false

            onPressed: (mouse) => {
                root.pendingPage = -1;
                pageSettleAnimation.stop();
                startX = mouse.x;
                startPage = root.currentPage;
                startProgress = root.clampedPageProgress;
                moved = false;
                pageStrip.interactive = true;
                root.pageProgress = startProgress;
                mouse.accepted = true;
            }

            onPositionChanged: (mouse) => {
                if (!pressed || viewport.width <= 0)
                    return;

                const deltaX = mouse.x - startX;
                root.pageProgress = Math.max(0, Math.min(1, startProgress + deltaX / root.pageSlideDistance));
                moved = moved || Math.abs(deltaX) > 8;
            }

            onReleased: {
                if (!moved || viewport.width <= 0) {
                    root.settlePage(startPage);
                    return;
                }

                const progress = root.clampedPageProgress;
                let targetPage = startPage;

                if (startPage === 0 && progress > 0.22)
                    targetPage = 1;
                else if (startPage === 1 && progress < 0.78)
                    targetPage = 0;

                root.settlePage(targetPage);
            }

            onCanceled: root.settlePage(startPage)
            onClicked: if (!moved) root.backgroundClicked()
        }

        Item {
            id: pageStrip

            z: 1
            property bool interactive: false

            width: viewport.width
            height: viewport.height
            x: 0

            onWidthChanged: {
                if (!interactive && !pageSettleAnimation.running)
                    root.pageProgress = root.currentPage;
            }

            Item {
                id: musicPage

                width: viewport.width
                height: viewport.height
                x: root.clampedPageProgress * root.pageSlideDistance
                opacity: 1 - root.clampedPageProgress
                enabled: opacity > 0.001

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Item {
                        width: parent.width
                        height: 60

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16

                            ClippingRectangle {
                                width: 60
                                height: 60
                                radius: 10
                                color: "#2c2c2e"
                                antialiasing: true

                                Image {
                                    anchors.fill: parent
                                    source: currentArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    visible: source.toString() !== ""
                                    sourceSize: Qt.size(120, 120)
                                    smooth: true
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: currentTrack
                                    color: "white"
                                    font.pixelSize: userConfig.bodyFontSize
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: -0.15
                                    width: 180
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: currentArtist
                                    color: "#8e8e93"
                                    font.pixelSize: userConfig.bodyFontSize - 2
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                    width: 200
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Item {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 22

                            Row {
                                anchors.centerIn: parent
                                height: parent.height
                                spacing: 4

                                Repeater {
                                    model: 5

                                    delegate: Rectangle {
                                        width: 4
                                        height: isPlaying
                                            ? 6 + (parent.height - 6) * visualizerLevel(index)
                                            : 6 + (parent.height - 6) * pausedVisualizerLevel(index)
                                        radius: 2
                                        color: isPlaying ? "#b56cff" : "#5f4b72"
                                        anchors.verticalCenter: parent.verticalCenter

                                        Behavior on height {
                                            NumberAnimation {
                                                duration: isPlaying ? 120 : 260
                                                easing.type: Easing.InOutQuad
                                            }
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: isPlaying ? 140 : 280
                                                easing.type: Easing.InOutQuad
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 16

                        Text {
                            id: timeL
                            anchors.left: parent.left
                            text: timePlayed
                            color: "#8e8e93"
                            font.pixelSize: userConfig.bodyFontSize - 4
                            font.family: textFontFamily
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: timeL.right
                            anchors.right: timeR.left
                            anchors.margins: 12
                            height: 6
                            radius: 3
                            color: "#333333"

                            Rectangle {
                                height: parent.height
                                radius: 3
                                color: "white"
                                width: parent.width * trackProgress

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Text {
                            id: timeR
                            anchors.right: parent.right
                            text: timeTotal
                            color: "#8e8e93"
                            font.pixelSize: userConfig.bodyFontSize - 4
                            font.family: textFontFamily
                            font.weight: Font.Medium
                        }
                    }

                    Item {
                        width: parent.width
                        height: 36

                        Row {
                            anchors.centerIn: parent
                            spacing: 50

                            Item {
                                width: 28
                                height: 28
                                scale: prevArea.pressed ? 0.8 : 1.0

                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }

                                Canvas {
                                    anchors.fill: parent
                                    property color fillColor: prevArea.pressed ? "#888" : "white"

                                    onFillColorChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = fillColor;
                                        ctx.strokeStyle = fillColor;
                                        ctx.lineJoin = "round";
                                        ctx.lineWidth = 2;
                                        ctx.beginPath();
                                        ctx.rect(3, 5, 3, 18);
                                        ctx.moveTo(14, 5);
                                        ctx.lineTo(6, 14);
                                        ctx.lineTo(14, 23);
                                        ctx.closePath();
                                        ctx.moveTo(23, 5);
                                        ctx.lineTo(15, 14);
                                        ctx.lineTo(23, 23);
                                        ctx.closePath();
                                        ctx.fill();
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    id: prevArea
                                    anchors.fill: parent
                                    anchors.margins: -15
                                    preventStealing: true
                                    onPressed: (mouse) => {
                                        controlPressed();
                                        mouse.accepted = true;
                                    }
                                    onClicked: root.previousRequested()
                                }
                            }

                            Item {
                                width: 28
                                height: 28
                                scale: playArea.pressed ? 0.8 : 1.0

                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    visible: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

                                    Rectangle { width: 6; height: 20; radius: 2; color: playArea.pressed ? "#888" : "white" }
                                    Rectangle { width: 6; height: 20; radius: 2; color: playArea.pressed ? "#888" : "white" }
                                }

                                Canvas {
                                    anchors.fill: parent
                                    visible: !activePlayer || activePlayer.playbackState !== MprisPlaybackState.Playing
                                    property color fillColor: playArea.pressed ? "#888" : "white"

                                    onFillColorChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = fillColor;
                                        ctx.strokeStyle = fillColor;
                                        ctx.lineJoin = "round";
                                        ctx.lineWidth = 2;
                                        ctx.beginPath();
                                        ctx.moveTo(8, 4);
                                        ctx.lineTo(24, 14);
                                        ctx.lineTo(8, 24);
                                        ctx.closePath();
                                        ctx.fill();
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    anchors.margins: -15
                                    preventStealing: true
                                    onPressed: (mouse) => {
                                        controlPressed();
                                        mouse.accepted = true;
                                    }
                                    onClicked: togglePlayback()
                                }
                            }

                            Item {
                                width: 28
                                height: 28
                                scale: nextArea.pressed ? 0.8 : 1.0

                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }

                                Canvas {
                                    anchors.fill: parent
                                    property color fillColor: nextArea.pressed ? "#888" : "white"

                                    onFillColorChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = fillColor;
                                        ctx.strokeStyle = fillColor;
                                        ctx.lineJoin = "round";
                                        ctx.lineWidth = 2;
                                        ctx.beginPath();
                                        ctx.moveTo(5, 5);
                                        ctx.lineTo(13, 14);
                                        ctx.lineTo(5, 23);
                                        ctx.closePath();
                                        ctx.moveTo(14, 5);
                                        ctx.lineTo(22, 14);
                                        ctx.lineTo(14, 23);
                                        ctx.closePath();
                                        ctx.rect(22, 5, 3, 18);
                                        ctx.fill();
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    id: nextArea
                                    anchors.fill: parent
                                    anchors.margins: -15
                                    preventStealing: true
                                    onPressed: (mouse) => {
                                        controlPressed();
                                        mouse.accepted = true;
                                    }
                                    onClicked: if (activePlayer) activePlayer.next()
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: trayPage

                x: -(1 - root.clampedPageProgress) * root.pageSlideDistance
                width: viewport.width
                height: viewport.height
                opacity: root.clampedPageProgress
                enabled: opacity > 0.001

                TrayPanelLayer {
                    anchors.fill: parent
                    showCondition: trayPage.enabled
                    textFontFamily: root.textFontFamily
                    onExecutionTriggered: root.closeRequested()
                }
            }
        }
    }

}
