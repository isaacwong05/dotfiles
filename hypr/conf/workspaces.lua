-- A numbered desktop is a pair of workspaces: IDs 1–10 on eDP-1 and their
-- 11–20 counterparts on HDMI-A-1. The paired-workspace script switches both
-- displays together and moves a window to its matching monitor workspace.
-- The HDMI half only exists while an external monitor is actually attached:
-- binding persistent workspaces 11–20 to a dead output lets them leak onto
-- eDP-1 (they showed up as the active workspace after an unplug).
local external = false
for _, m in ipairs(hl.get_monitors()) do
    if m.name == "HDMI-A-1" then
        external = true
        break
    end
end

local names = { "一", "二", "三", "四", "五", "六", "七", "八", "九", "十" }
for i = 1, 10 do
    hl.workspace_rule({ workspace = i, monitor = "eDP-1", persistent = true, default_name = names[i] })
    if external then
        hl.workspace_rule({ workspace = i + 10, monitor = "HDMI-A-1", persistent = true, default_name = names[i] })
    end
end

-- Re-evaluate the gate when the external comes or goes: workspace rules only
-- apply at config source time, so a hotplug mid-session needs a reload.
hl.on("monitor.added", function() hl.dsp.exec_cmd("hyprctl reload") end)
hl.on("monitor.removed", function() hl.dsp.exec_cmd("hyprctl reload") end)