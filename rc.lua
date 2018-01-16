-- libs
gears = require("gears")
awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
wibox = require("wibox")
vicious = require("vicious")
beautiful = require("beautiful")
naughty = require("naughty")
menubar = require("menubar")
menubar.show_categories = false

-- define extensions dir
extensiondir = "INSERT_FULL_PATH_TO_extensions/"
themingdir = "INSERT_FULL_PATH_TO_THEME/"

-- setup X: the script file needs to be linked to ~/.config/awesome/X_setup.sh
-- io.popen(extensiondir .. "X_setup.sh")
-- to use the laptop monitor, edit /etc/X11/xorg.conf.d/30-monitor.conf

-- errors
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,title = "ERROR: During startup",text = awesome.startup_errors })
end
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,title = "ERROR:",text = err })
        in_error = false
    end)
end

-- variables
terminal = "uxterm"
-- terminal = 'st -f "DejaVu Sans Mono:pixelsize=15"'
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

-- theming to file
beautiful.init(themingdir .. "theme.lua")

-- wallpapers that are changing with time
dofile(extensiondir .. "wallpaper.lua")

-- layouts, order relevant
layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.magnifier
}

-- create tags on every screen (from 1 to 9)
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end

-- widgets to file
dofile(extensiondir .. "widgets.lua")

-- mouse and keys to file
dofile(extensiondir .. "keys.lua")

-- signal function to execute when a new client appears
client.connect_signal("manage", function (c, startup)
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)
    awful.client.movetoscreen(c, awful.screen.focused())
    if not startup then
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.connect_signal(
    "focus",
    function(c)
        c.border_color = beautiful.border_focus
        --c.opacity = 1
    end)
client.connect_signal(
    "unfocus",
    function(c)
        c.border_color = beautiful.border_normal
        --c.opacity = 0.8
    end)

-- autostart to file
dofile(extensiondir .. "autostart.lua")
