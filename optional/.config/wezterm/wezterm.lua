local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font({ family = "Adwaita Sans" })
config.font_size = 12.0
config.color_scheme = "Noctalia"

return config
