-- Hyprland Lua entrypoint. Keep this file limited to load order.
-- Each category below receives the global `hl` API from Hyprland.
require("conf.monitors")
require("conf.environment")
require("conf.startup")
require("conf.appearance")
require("conf.input")
require("conf.workspaces")
require("conf.keybinds")
require("conf.window-rules")

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
dofile((os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua")
pcall(require, "/home/isaac/.config/hypr/openwhispr-binds.lua")
