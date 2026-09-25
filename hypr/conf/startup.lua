-- Wallpaper, notifications, and the Dynamic Island are managed by enabled user
-- services (awww restores its cached wallpaper).
hl.on("hyprland.start", function()
	hl.dsp.exec_cmd("awww-daemon &")
	hl.dsp.exec_cmd("gnome-keyring-daemon --start --components=secrets &")
	hl.dsp.exec_cmd("hyprscratch init &")
	hl.dsp.exec_cmd("nohup /home/isaac/.config/hypr/scripts/rotate-screen --watch >/dev/null 2>&1 &")
	-- Start the paired displays on desktop 1 (1 on eDP-1, 11 on HDMI-A-1).
	hl.dsp.exec_cmd("hyprctl dispatch workspace 1; hyprctl monitors -j | grep -q '\"name\": \"HDMI-A-1\"' && hyprctl dispatch workspace 11")
	hl.dsp.exec_cmd("ghostty -e nvim ~/.config/hypr/hyprland.lua")
	-- walker's backend is elephant.service; this duplicate --gapplication-service
	-- always lost the GApplication race and never persisted. Removing it.
end)
