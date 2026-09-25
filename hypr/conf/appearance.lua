-- minimal monochrome appearance, blur, and fast non-sliding animations.
hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 0,
		col = {
			active_border = "rgba(ffffffff)",
			inactive_border = "rgba(0f0f0fff)",
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 0,
		rounding_power = 2,
		active_opacity = 0.95,
		inactive_opacity = 0.80,
		shadow = {
			enabled = false,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},
		blur = {
			enabled = true,
			size = 15,
			passes = 3,
			vibrancy = 0.08,
			noise = 0.01,
		},
	},
	animations = { enabled = true },
	dwindle = { preserve_split = true },
	master = { new_status = "master" },
	scrolling = { fullscreen_on_one_column = true },
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
	-- h/l focus moves between windows; hit the screen edge → hop monitors.
	binds = {
		window_direction_monitor_fallback = true,
	},
})

hl.curve("defaultBezier", { type = "bezier", points = { { 0.1, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "defaultBezier", style = "popin 97%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default", style = "popin 97%" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "defaultBezier" })

-- scratchpad (special workspace): slide up from the bottom, ease in/out.
hl.curve("scratchpadBezier", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "scratchpadBezier", style = "slidevert" })

hl.animation({ leaf = "fade", enabled = false })
hl.animation({ leaf = "fadeIn", enabled = false })
hl.animation({ leaf = "fadeOut", enabled = false })
hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "layersIn", enabled = false })
hl.animation({ leaf = "layersOut", enabled = false })
hl.animation({ leaf = "fadeLayersIn", enabled = false })
hl.animation({ leaf = "fadeLayersOut", enabled = false })
hl.animation({ leaf = "zoomFactor", enabled = false })
