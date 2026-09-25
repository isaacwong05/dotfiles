-- wallpaper, notifications, and the dynamic island are managed by enabled user
-- services (awww restores its cached wallpaper).
hl.on("hyprland.start", function()
	hl.dsp.exec_cmd("awww-daemon &")
	hl.dsp.exec_cmd("gnome-keyring-daemon --start --components=secrets &")
	hl.dsp.exec_cmd("hyprscratch init &")
	hl.dsp.exec_cmd("nohup /home/isaac/.config/hypr/scripts/rotate-screen --watch >/dev/null 2>&1 &")
	-- start the paired displays on desktop 1 (1 on edp-1, 11 on hdmi-a-1).
	hl.dsp.exec_cmd("hyprctl dispatch workspace 1; hyprctl monitors -j | grep -q '\"name\": \"HDMI-A-1\"' && hyprctl dispatch workspace 11")
	hl.dsp.exec_cmd("ghostty -e nvim ~/.config/hypr/hyprland.lua")
	-- walker's backend is elephant.service; this duplicate --gapplication-service
	-- always lost the gapplication race and never persisted. removing it.
end)
