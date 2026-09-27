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
-- Overrides Omarchy's default { 875, 600 } rule, which is registered earlier and
-- would otherwise win. Rules are applied in registration order, last match wins.
-- width/height are physical pixels, so divide by scale to get logical pixels.
local function size_floating_windows(monitor)
  if not monitor then
    return
  end

  local scale = monitor.scale or 1

  o.window(
    { tag = "floating-window" },
    { size = { monitor.width / scale * 0.75, monitor.height / scale * 0.75 } }
  )
end

-- Monitors are already available while the config loads, so register the rule
-- immediately. Relying on monitor.added alone left the rule unregistered after
-- any config reload, silently reverting to the default size.
size_floating_windows(hl.get_active_monitor())

-- Hotplugged monitors may have a different resolution or scale.
hl.on("monitor.added", size_floating_windows)

-- default scrolling for special workspaces
-- Special workspaces use the scrolling layout.
hl.workspace_rule({ workspace = "special:acomms", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:bnotes", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:cmedia", layout = "scrolling" })
