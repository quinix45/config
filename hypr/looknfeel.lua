hl.config({
    general = {
        -- No gaps between windows or borders.
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
    },
})

hl.config({
    decoration = {
        dim_inactive = true,
        dim_strength = 0.15,
    },
})

-- Make all windows fully opaque.
o.window(".*", { opacity = "1 1" })

-- revert workspace slide animation
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide bottom" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "easeInOutCubic", style = "slide top" })

-- animations
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "quick", style = "slide" })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
