
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

-- animations  
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "quick", style = "slide" })