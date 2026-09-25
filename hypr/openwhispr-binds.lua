-- openwhispr keybinds (managed automatically)
-- if you delete this file, also remove the matching load line from your hyprland config.
hl.bind("CTRL + SUPER_L", hl.dsp.exec_cmd("dbus-send --session --type=method_call --dest=com.openwhispr.App /com/openwhispr/App com.openwhispr.App.Toggle"))
