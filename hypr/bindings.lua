local terminal = "omarchy-launch-terminal"
-- launch of focus browser
local browser = [[
sh -c 'desktop=$(env -u BROWSER xdg-settings get default-web-browser); test -n "$desktop" || desktop=$(xdg-mime query default x-scheme-handler/https); exec_name=$(sed -n "s/^Exec=\([^ ]*\).*/\1/p" "$HOME/.local/share/applications/$desktop" "/usr/share/applications/$desktop" 2>/dev/null | head -1); omarchy-launch-or-focus "$(basename "$exec_name" -stable)" "omarchy-launch-browser"'
]]
-- local meet_browser = "omarchy-launch-browser --new-window"

-- Override existing Omarchy bindings.
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + P")
hl.unbind("SUPER + S")
hl.unbind("SUPER + SHIFT + S")
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + P")
hl.unbind("SUPER + SHIFT + F")
hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + T")
hl.unbind("SUPER + SHIFT + O")
hl.unbind("SUPER + C")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + ALT + G")
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("XF86AudioRaiseVolume")
hl.unbind("XF86AudioLowerVolume")

-- Applications
o.bind("SUPER + RETURN", "Terminal", terminal)
o.bind("SUPER + SHIFT + F", "File manager", "omarchy-launch-or-focus nautilus")
o.bind("SUPER + B", "Browser", browser)
o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + T", "Activity", { tui = "btop" })
o.bind("SUPER + R", "Positron", "positron")

-- numpad
--- change focus
o.bind("SUPER + KP_End", "workspace 1", hl.dsp.focus({ workspace = "1" }))
o.bind("SUPER + KP_Down", "workspace 2", hl.dsp.focus({ workspace = "2" }))
o.bind("SUPER + KP_Next", "workspace 3", hl.dsp.focus({ workspace = "3" }))
o.bind("SUPER + KP_Left", "workspace 4", hl.dsp.focus({ workspace = "4" }))
o.bind("SUPER + KP_Begin", "workspace 5", hl.dsp.focus({ workspace = "5" }))
o.bind("SUPER + KP_Right", "workspace 6", hl.dsp.focus({ workspace = "6" }))
o.bind("SUPER + KP_Home", "workspace 7", hl.dsp.focus({ workspace = "7" }))
o.bind("SUPER + KP_Up", "workspace 8", hl.dsp.focus({ workspace = "8" }))
o.bind("SUPER + KP_Prior", "workspace 9", hl.dsp.focus({ workspace = "9" }))
o.bind("SUPER + KP_Insert", "workspace 10", hl.dsp.focus({ workspace = "10" }))

--- Move Window
o.bind("SUPER + SHIFT + KP_End", "move to workspace 1", hl.dsp.window.move({ workspace = "1" }))
o.bind("SUPER + SHIFT + KP_Down", "move to workspace 2", hl.dsp.window.move({ workspace = "2" }))
o.bind("SUPER + SHIFT + KP_Next", "move to workspace 3", hl.dsp.window.move({ workspace = "3" }))
o.bind("SUPER + SHIFT + KP_Left", "move to workspace 4", hl.dsp.window.move({ workspace = "4" }))
o.bind("SUPER + SHIFT + KP_Begin", "move to workspace 5", hl.dsp.window.move({ workspace = "5" }))
o.bind("SUPER + SHIFT + KP_Right", "move to workspace 6", hl.dsp.window.move({ workspace = "6" }))
o.bind("SUPER + SHIFT + KP_Home", "move to workspace 7", hl.dsp.window.move({ workspace = "7" }))
o.bind("SUPER + SHIFT + KP_Up", "move to workspace 8", hl.dsp.window.move({ workspace = "8" }))
o.bind("SUPER + SHIFT + KP_Prior", "move to workspace 9", hl.dsp.window.move({ workspace = "9" }))
o.bind("SUPER + SHIFT + KP_Insert", "move to workspace 10", hl.dsp.window.move({ workspace = "10" }))

-- full screen on scrolling layout

local active_monitor = hl.get_active_monitor()
local width = active_monitor.width
local height = active_monitor.height

o.bind(
    "SUPER + ALT + UP",
    "Maximize window",
    hl.dsp.window.resize({
        x = width,
        y = height,
        relative = false,
    })
)
o.bind(
    "SUPER + ALT + DOWN",
    "Minimize window",
    hl.dsp.window.resize({
        x = width / 2.15,
        y = height,
        relative = false,
    })
)

-- o.bind("SUPER + ALT + UP", "Full Screen",  value = "1")

-- Workspaces
o.bind("SUPER + CTRL + LEFT", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + RIGHT", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

-- Special workspaces


--- communications
o.bind(
    "SUPER + M",
    "Comms Space",
    hl.dsp.workspace.toggle_special("acomms")
)
o.bind(
    "SUPER + SHIFT + M",
    "Move to Comms Space",
    hl.dsp.window.move({ workspace = "special:acomms" })
)

--- notes
o.bind(
    "SUPER + S",
    "Media Space",
    hl.dsp.workspace.toggle_special("bnotes")
)

o.bind(
    "SUPER + SHIFT + S",
    "Move to Media Space",
    hl.dsp.window.move({ workspace = "special:bnotes" })
)

--- players
o.bind(
    "SUPER + P",
    "Media Space",
    hl.dsp.workspace.toggle_special("cmedia")
)
o.bind(
    "SUPER + SHIFT + P",
    "Move to Media Space",
    hl.dsp.window.move({ workspace = "special:cmedia" })
)
