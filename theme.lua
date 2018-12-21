theme = {}
theme.font          = "sans 10"
-- font colors
theme.fg_normal     = "#0088dd"
theme.fg_focus      = "#00AAff"
theme.fg_urgent     = "#2ac1ed"
theme.fg_minimize   = "#0077cc"
-- other colors
theme.bg_normal     = "#222222"
theme.bg_focus      = "#333333"
theme.bg_urgent     = "#111111"
theme.bg_minimize   = "#000000"
-- systray
theme.bg_systray    = theme.bg_normal
-- border colors
theme.border_width  = 2
theme.border_normal = "#444444"
theme.border_focus  = "#008aff"
theme.border_marked = "#19b0dc"

theme.tooltip_border_width = 2
theme.tooltip_border_color = "#008aff"

theme.menu_fg_focus = "#333333"
theme.menu_bg_focus = "#00AAFF"
theme.menu_fg_normal = "#0088dd"
theme.menu_bg_normal = "#222222"
--
theme.taglist_squares_sel   = "~/.config/awesome/theme_taglist_full.png"
theme.taglist_squares_unsel = "~/.config/awesome/theme_taglist_empt.png"

theme.taglist_squares       = "true"
theme.titlebar_close_button = "true"
theme.menu_height           = 19
theme.menu_width            = 300

-- theme.useless_gap = 20

theme.widget_colors = {}
theme.widget_colors['cpu'] = {{0, "#0088DD"},{1, "#0088DD"}}
theme.widget_colors['mem']= {{0, "#00AAFF"},{1, "#00AAFF"}}
theme.widget_colors['background'] = "#4d4d4d"

return theme
