-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Set the size of windows tagged `floating-window`.
local width = hl.get_active_monitor().width
local height = hl.get_active_monitor().height

o.window(
    { tag = "floating-window" },
    { size = { width * 0.75, height * 0.75 } }
)


-- default scrolling for special workspaces
-- Special workspaces use the scrolling layout.
hl.workspace_rule({ workspace = "special:acomms", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:bnotes", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:cmedia", layout = "scrolling" })
