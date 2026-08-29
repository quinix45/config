local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

hl.monitor({
    output = "",
    mode = "2880x1800@120",
    position = "0x0",
    scale = omarchy_monitor_scale,
})