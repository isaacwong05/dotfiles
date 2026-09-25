import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    readonly property var chineseNumerals: ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    property int workspaceId: 1
    /* Desktop N lives on workspace N (eDP-1) and N+10 (HDMI-A-1); mirror the
       laptop half so the external monitor shows 一..十, not 11..20. */
    readonly property int displayWorkspaceId: workspaceId > 10 ? workspaceId - 10 : workspaceId
    property string displayText: displayWorkspaceId >= 1 && displayWorkspaceId <= 10
        ? chineseNumerals[displayWorkspaceId] : String(workspaceId)
    property var configSource: null
    readonly property var activeConfig: configSource || userConfig
    property string textFontFamily: activeConfig.textFontFamily
    property bool showCondition: false
    property int textPixelSize: userConfig.bodyFontSize
    property string slideDirection: "none"
    property bool animateVisibility: true
    property real transitionProgress: 0
    property real horizontalPadding: 14
    property real hiddenLeftPadding: 16
    property real hiddenRightPadding: 16

    readonly property real clampedProgress: slideDirection === "right"
        ? Math.max(0, Math.min(1, transitionProgress))
        : (slideDirection === "left"
            ? Math.max(0, Math.min(1, -transitionProgress))
            : 0)
    readonly property real revealProgress: slideDirection === "none" ? 1 : (1 - clampedProgress)
    readonly property real textWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real centeredX: horizontalPadding
    readonly property real hiddenLeftX: -textWidth - hiddenLeftPadding
    readonly property real hiddenRightX: width + hiddenRightPadding
    readonly property real labelX: slideDirection === "right"
        ? centeredX + (hiddenRightX - centeredX) * clampedProgress
        : (slideDirection === "left"
            ? centeredX + (hiddenLeftX - centeredX) * clampedProgress
            : centeredX)

    anchors.fill: parent
    clip: true
    opacity: showCondition ? (animateVisibility ? revealProgress : 1) : 0

    Behavior on opacity {
        enabled: animateVisibility

        NumberAnimation {
            duration: showCondition ? 300 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Text {
        x: labelX
        width: textWidth
        anchors.verticalCenter: parent.verticalCenter
        text: displayText
        color: "white"
        opacity: revealProgress
        font.pixelSize: textPixelSize
        font.family: textFontFamily
        font.weight: Font.DemiBold
        font.letterSpacing: -0.15
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }
}
