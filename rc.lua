-- libs
gears = require("gears")
awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
wibox = require("wibox")
vicious = require("vicious")
beautiful = require("beautiful")
naughty = require("naughty")

-- custom extensions
menubar = require("mymenubar")
-- switcher = require("awesome-switcher")
-- external module, found on github.
shortcuts = require("shortcuts")
require("volume")
cal = require("cal")
clock = require("clock")

menubar.show_categories = false
menubar.cache_entries = true
menubar.geometry = {height = 19}

-- define extensions dir
themingdir = "~/.config/awesome/standard/"

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

-- THEMING
beautiful.init(themingdir .. "theme.lua")
    -- "hack" to change spotify notifications.
    naughty.config.presets.spotify = {
        callback = function(args)
            return true
        end,
        icon_size = 64
    }
    table.insert(naughty.dbus.config.mapping, {{appname = "Spotify"},
        naughty.config.presets.spotify})

-- WALLPAPER
require("wallpaper")

-- layouts, order relevant
layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.fair,
    --awful.layout.suit.corner.nw,
    awful.layout.suit.magnifier

}

-- create tags on every screen (from 1 to 9)
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9}, s, layouts[1])
    -- TODO give tag names, maybe?
end

-- WIDGETS
-- clockwidget
datewidget = wibox.widget.textbox()
vicious.register(datewidget, vicious.widgets.date, "%H:%M", 10)
cal.register(datewidget,'<span color="#ffff00"><b><u>%s</u></b></span>')
-- Systraywidget
mysystray = wibox.widget.systray()
-- Cpuwidget, memwidget, swapwidget
cpuwidget = wibox.widget.graph()
cpuwidget:set_width(20)
cpuwidget:set_background_color(beautiful.widget_colors['background'])
cpuwidget:set_color( {
    type = "linear",
    from = { 0, 0 },
    to = { 15,0 },
    stops = beautiful.widget_colors['cpu']
} )
-- start htop upon click
cpuwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function()
        awful.spawn.easy_async("xterm -e htop", function () end)
    end)
))
--mensa = require('extensions/mensa') -- mensa @ cpu
--mensa.register(cpuwidget)
vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 2)
memwidget = wibox.widget.graph()
memwidget:set_width(15)
memwidget:set_background_color(beautiful.widget_colors['background'])
memwidget:set_color( {
    type = "linear",
    from = { 0, 0 },
    to = { 15,0 },
    stops = beautiful.widget_colors['mem']
} )
-- start htop upon click
memwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function()
        awful.spawn.easy_async("xterm -e htop", function () end)
    end)
))
vicious.register(memwidget, vicious.widgets.mem, "$1", 2)
-- thermal
thermalwidget = wibox.widget.textbox()
vicious.register(
    thermalwidget,
    vicious.widgets.thermal,
    --" ♨ $1°C ",
    function (widget, args)
        if args[1] >= 50 then
            if args[1] >= 65 then
                my_color = '<span color="red">'
            else
                my_color = '<span color="orange">'
            end
        else
            my_color = '<span>'
        end
        --return my_color .. " ϑ " .. args[1] .. "°C " .. "</span>"
        return my_color .. " T " .. args[1] .. "°C " .. "</span>"
    end,
    2,
    'thermal_zone0'
)
-- battery widget
batwidget = wibox.widget.textbox()
vicious.register(batwidget, vicious.widgets.bat,
    function (widget, args)
        if args[1] == '+' then
            my_color = "<span color='#87FF00'>"
        else
            if args[2] <= 15 then
                my_color = "<span color='red'>"
                naughty.notify({
                    preset = naughty.config.presets.critical,
                    title = "CAUTION: Low battery",
                    text = "Only " .. args[2] .. "% remain"
                })
            elseif args[2] <= 30 then
                my_color = "<span color='orange'>"
            else
                my_color = "<span>"
            end
        end
        return my_color .. '⚡ ' .. args[2] .. '% ' .. '</span>'
    end,
    10, 'BAT0')
-- keyboard layout
kbdwidget = awful.widget.keyboardlayout:new()
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

-- add wibox and clocks to each screen
myclocks = {}
for s = 1, screen.count() do
    mypromptbox[s] = awful.widget.prompt()
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
    mywibox[s] = awful.wibar({ position = "bottom", screen = s })
    myclocks[s] = clock.clock:create(s,'hours')
    -- Widgets that are aligned to the left
    left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])
    right_layout = wibox.layout.fixed.horizontal()
    --right_layout:add(volume_widget)
    right_layout:add(batwidget)
    right_layout:add(thermalwidget)
    right_layout:add(volume_widget)
    right_layout:add(cpuwidget)
    right_layout:add(memwidget)
    right_layout:add(wibox.container.margin(mysystray,1,1,1,1))
    right_layout:add(kbdwidget)
    right_layout:add(datewidget)
    layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)
    mywibox[s]:set_widget(layout)
end
-- timer for the clocks.
gears.timer {
    timeout = 30,
    autostart = true,
    callback = function()
        for s = 1, screen.count() do
            myclocks[s]:update()
        end
    end
}

-- KEYS / MOUSE
-- mouse
wp_timer:emit_signal("timeout")
root.buttons(awful.util.table.join(
    -- next random wallpaper
    awful.button({ }, 3, function () 
        local now_wallpaper = random_wallpaper
        if now_wallpaper == 'cycle' then
            random_wallpaper = 'random'
        end
        wp_timer:emit_signal("timeout")
        if now_wallpaper == 'cycle' then
            random_wallpaper = 'cycle'
        end
        wp_timer:again()
    end),
    -- next wallpaper
    awful.button({ }, 1, function ()
        local now_wallpaper = random_wallpaper
        if now_wallpaper == 'random' then
            random_wallpaper = 'cycle'
        end
        wp_timer:emit_signal("timeout")
        if now_wallpaper == 'random' then
            random_wallpaper = 'random'
        end
        wp_timer:again()
    end),
    -- toggle random
    awful.button({ 'Shift'}, 1, function ()
        if random_wallpaper == 'random' then
            random_wallpaper = 'cycle'
        else
            random_wallpaper = 'random'
        end
    naughty.notify( {title = "Info", text="Wallpaper mode changed to '" .. random_wallpaper .. "'"} )
    end),
    -- show info
    awful.button({ 'Shift'}, 3, function()
        if set_directories == true then
            my_dir_infos = "shown"
        else
            my_dir_infos = "hidden"
        end
        if show_hidden_files == true then
            my_dir_infos_plus = "yes"
        else
            my_dir_infos_plus = "no"
        end
        local text_not = "Filename: " .. wp_files[wp_index] .. "<br>Index: " .. wp_index  .. " / " .. #wp_files .. "<br>Mode: " .. random_wallpaper .. "<br>Files: " .. my_dir_infos .. "<br>Hidden files: " .. my_dir_infos_plus
        naughty.notify( {title="Info", text=text_not} )
    end),
    awful.button({ }, 2, function()
        local my_notification_string = "on"
        if set_directories == true then
            set_directories = false
            my_notification_string = "off"
        else
            set_directories = true
        end
        local my_rand = random_wallpaper
        random_wallpaper = 'static'
        wp_notification = false
        wp_timer:emit_signal("timeout")
        random_wallpaper = my_rand
        wp_timer:again()
        wp_notification = true
        naughty.notify(
            {
                title = "Info",
                text="Desktop files on Wallpaper: " .. my_notification_string
            }
        )
    end),
    awful.button({ 'Shift' }, 2, function()
        local my_notification_string = "on"
        if show_hidden_files == true then
            show_hidden_files = false
            my_notification_string = "off"
        else
            show_hidden_files = true
        end
        local my_rand = random_wallpaper
        random_wallpaper = 'static'
        wp_notification = false
        wp_timer:emit_signal("timeout")
        random_wallpaper = my_rand
        wp_timer:again()
        wp_notification = true
        naughty.notify(
            {
                title = "Info",
                text="Show hidden files: " .. my_notification_string
            }
        )
    end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- keys
globalkeys = awful.util.table.join(
    -- switcher
    awful.key({ "Mod1"            }, "Tab",
      function ()
          switcher.switch( 1, "Mod1", "Alt_L", "Shift", "Tab")
      end),
    awful.key({ "Mod1", "Shift"   }, "Tab",
      function ()
          switcher.switch( 1, "Mod1", "Alt_L", "Shift", "Tab")
      end),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),
    awful.key({ modkey,           }, "i",
        function ()
            for s = 1, screen.count() do
                if mywibox[s].visible then
                    mywibox[s].visible =  false
                else
                    mywibox[s].visible = true
                end
            end
        end),
    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "0", awesome.quit),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey,           }, "u",     function () awful.client.incwfact( 0.05)    end),
    awful.key({ modkey,           }, "o",     function () awful.client.incwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Control" }, "n", awful.client.restore),
    -- prompt / custom
    -- awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey },            "r",     function () io.popen(
        'dmenu_run -nb "#222222" -nf "#0088dd" -sb "#00aaff" -sf "#333333" -fn "Droid Sans Mono-10" -p run'
        ) end),
    awful.key({ modkey },            "e",     function () io.popen(
        'networkmanager_dmenu -nb "#222222" -nf "#0088dd" -sb "#00aaff" -sf "#333333" -fn "Droid Sans Mono-10" -p net'
        ) end),
    awful.key({},                    "Print", function () io.popen("bash -c 'import ~/Desktop/$(date +\"%s\").png'") end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),
    -- toggle clock around the screen
    awful.key({ modkey }, "c", function()
        for s = 1,screen.count() do
            myclocks[s]:toggle()
        end
    end),
    -- Launchers
    awful.key({ modkey }, "g", shortcuts.grab),
    awful.key({ modkey, "Shift" }, "g", shortcuts.lock)
)
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey, "Shift"   }, "o",      function (c) c:move_to_screen()               end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end)
)

-- bind keynumbers to tags
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                              -- awful.tag.viewtoggle(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end
clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)

-- rules for new clients
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false} },
    { rule = { class = "Thunderbird" },
      properties = { tag = tags[1][9] } },
    { rule = { class = "TelegramDesktop" },
      properties = { tag = tags[1][8] } },
    { rule = { class = "Caprine" },
      properties = { tag = tags[1][8] } },
    { rule = { class = "Whatsie" },
      properties = { tag = tags[1][8] } },
    -- { rule = { class = "gimp" },
    --   properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}

-- signal function to execute when a new client appears
client.connect_signal("manage", function (c, startup)
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)
    c:move_to_screen(awful.screen.focused())
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

-- autostart
function run_once(cmd)
    if cmd[2] == nil then
        findme = cmd[1]
    else
        findme = cmd[2]
    end
    firstspace = findme:find(" ")
    if firstspace then
        findme = findme:sub(0, firstspace-1)
    end
    if #findme > 15 then
        -- avoid pgrep throwing warnings.
        findme = findme:sub(0,15)
    end
    awful.spawn.with_shell("bash -c 'pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd[1] .. ")'", function () end)
end

commands = {
    {"nm-applet", nil},
    {"blueman-applet", nil},
    {"alltray thunderbird", "thunderbird"},
    {"owncloud", nil},
    -- " -startintray"
    {"telegram-desktop", nil},
    -- " --minimize"
    --{"caprine", nil},
    {"whatsie", nil},
    {"system-config-printer-applet", "applet.py"}
}

for i = 1, #commands do
    run_once(commands[i])
end

