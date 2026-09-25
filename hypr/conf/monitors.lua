-- physical monitor layout. positions use hyprland logical coordinates.
hl.monitor({
	output = "eDP-1",
	mode = "2560x1440@240",
	position = "0x0",
	scale = 1.5,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@144",
	-- edp-1 is 1600 logical pixels wide at hyprland's effective 1.6 scale.
	position = "1600x0",
	scale = 1,
})
