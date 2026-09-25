-- per-window and layer-surface behavior rules.
-- keep generic quickshell overlays crisp. the voice indicator is intentionally
-- just a small card; blurring its full-width layer surface dims the entire top
-- of the active monitor.
hl.layer_rule({
    name = "quickshell-no-full-width-blur",
    match = { namespace = "^quickshell$" },
    blur = false,
})

-- walker is a translucent overlay surface; let hyprland blur the desktop
-- behind it while retaining its sharp monochrome content.
hl.layer_rule({
    name = "blur-walker",
    match = { namespace = "^walker$" },
    blur = true,
    xray = false,
})

-- native hyprland blur for the quickshell notification layer. the lua api
-- emits the current `layerrule = blur, match:namespace ...` syntax and the
-- alpha threshold keeps the tinted cards in the blur pass.
hl.layer_rule({
    name = "blur-notifications",
    match = { namespace = "^notifications$" },
    blur = true,
    ignore_alpha = 0.5,
    xray = false,
})

-- make vesktop itself translucent so css glass can reveal hyprland's blurred backdrop.
hl.window_rule({
    name = "vesktop-glass",
    match = { class = "^vesktop$" },
    opacity = "0.92 override 0.88 override 0.88 override",
})

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "float-mission-center",
    match = { class = "^io\\.missioncenter\\.MissionCenter$" },
    float = true,
    size = { 1200, 800 },
    center = true,
})

hl.window_rule({
    name = "float-tailtui",
    match = { class = "^io\\.github\\.phundahl\\.tailtui$" },
    float = true,
    size = { 1200, 800 },
    center = true,
})

hl.window_rule({
    name = "fullscreen-omarchy-screensaver",
    match = { class = "^org\\.omarchy\\.screensaver$" },
    fullscreen = true,
    no_focus = false,
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})
