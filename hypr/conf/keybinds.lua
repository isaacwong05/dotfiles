-- application, window-management, workspace, mouse, and media keybindings.
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(
	mainMod .. " + BACKSLASH",
	hl.dsp.exec_cmd("/home/isaac/.local/bin/tuxedo-open"),
	{ description = "Open Tuxedo" }
)
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(
	"SUPER + GRAVE",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call island toggle")
)
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("GSK_RENDERER=cairo walker -m menus:power-profiles"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("/home/isaac/.local/bin/power-menu"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot"))
hl.bind(mainMod .. " + BACKSPACE", hl.dsp.exec_cmd("ghostty -e nvim ~/.config/hypr/hyprland.lua"))
-- sonora as a scratchpad: hyprscratch spawns it if needed, else toggles the
-- special workspace it lives on — summoned/hidden from any workspace.
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/sonora-scratch"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/tailtui-scratch"))
hl.bind(
	"CTRL + SHIFT + ESCAPE",
	hl.dsp.exec_cmd("pgrep -x hyprscratch >/dev/null || (hyprscratch init & sleep 1); hyprscratch 'Mission Center' /usr/sbin/missioncenter special")
)
hl.bind(
	mainMod .. " + F",
	hl.dsp.exec_cmd(
		"brave-origin --ozone-platform=wayland --enable-features=VaapiVideoDecoder --enable-zero-copy --ignore-gpu-blocklist"
	)
)
-- rotate the focused monitor 180deg; second press flips it back.
hl.bind(mainMod .. " + SHIFT + BACKSLASH", hl.dsp.exec_cmd("~/.config/hypr/scripts/rotate-screen"))

-- voice typing is push-to-talk: hold super+d to record, release d to stop.
-- push mode waits until the key is released before typing, preserving focus in
-- the original window rather than updating it while the shortcut is held.
-- hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("/home/isaac/.local/bin/dusky_trigger --start --push"), {
-- description = "start voice typing",
-- hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("/home/isaac/.local/bin/dusky_trigger --stop"), {
-- release = true,
-- description = "finish voice typing",

-- vim-style focus movement; at a monitor edge the fallback hops to the next
-- monitor (see binds.window_direction_monitor_fallback in appearance.lua).
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- alt+hjkl swaps the focused window in that direction.
hl.bind("ALT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind("ALT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind("ALT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind("ALT + L", hl.dsp.window.move({ direction = "right" }))

-- open the local open webui app and the coding-agent launcher.
hl.bind(mainMod .. " + DOWN", hl.dsp.exec_cmd("gtk-launch open-webui"))
hl.bind(mainMod .. " + UP", hl.dsp.exec_cmd("ghostty -e herdr"))

-- -- notification center: toggled by the quickshell notification daemon shell.
-- hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/hypr/scripts/notification-center toggle"), {
-- description = "toggle notification center",
hl.bind(
	"SUPER + N",
	hl.dsp.exec_cmd(
		"/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide toggleNotificationCenter"
	)
)

-- tide/island panel: workspace overview + wallpaper picker only. the rest of
-- the default tide binds stay unmapped -- the existing shortcuts own those keys.
hl.bind(
	mainMod .. " + TAB",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call overview toggle")
)
hl.bind(
	"ALT + W",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide toggleWallpaperPicker")
)

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace-pair switch " .. i))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace-pair move " .. i))
end

-- scratchpad: avoid super+shift+s, which is reserved for screenshots.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/media-osd volume-up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/media-osd volume-down"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/media-osd volume-mute"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/media-osd brightness-up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/media-osd brightness-down"),
	{ locked = true, repeating = true }
)
-- mpris already exposes spotify's cover art and browser media thumbnails.
-- show a matching notification after a media-key action instead of building a
-- second playback osd.
local mediaNotify = "~/.local/bin/media-notify"
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next; " .. mediaNotify), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause; " .. mediaNotify), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause; " .. mediaNotify), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous; " .. mediaNotify), { locked = true })
