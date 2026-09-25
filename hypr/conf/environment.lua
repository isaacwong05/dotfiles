-- Session environment and application commands.
terminal = "ghostty"
fileManager = "ghostty -e spf"
-- Cairo renderer: NVIDIA GL context creation adds ~270ms to every walker open
-- (client is a fresh GTK4 process each time). The launcher UI is static, so GL gains nothing.
menu = "GSK_RENDERER=cairo walker"

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.env("XCURSOR_THEME", "McMojave Cursors")
hl.env("XCURSOR_SIZE", "18")
hl.env("HYPRCURSOR_SIZE", "18")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("GTK_USE_PORTAL", "1")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
