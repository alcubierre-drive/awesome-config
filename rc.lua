-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
beautiful = require("beautiful")
beautiful.init( "~/.config/awesome/theme.lua")
-- Notification library
local naughty = require("naughty")

local os = require("os")

-- enable alt-tab style switching. from github
-- local switcher = require("awesome-switcher")
local menubar = require("mymenubar")
local shortcuts = require("shortcuts")
local custom_widgets = require("custom_widgets")

local custom_wallpaper = require("custom_wallpaper")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- commands that are automatically started at awesomewm startup. the second
-- value is the string to search for in pgrep in order to only start a cmd once
local autostart_commands = {
    {"nm-applet", nil},
    {"blueman-applet", nil},
    {"alltray thunderbird", "thunderbird"},
    {"owncloud", nil},
    -- " -startintray"
    {"alltray telegram-desktop", 'telegram-deskto'},
    -- " --minimize"
    {"system-config-printer-applet", "applet.py"}
}

-- spotify icon size.
naughty.config.presets.spotify = {
    callback = function(args)
        return true
    end,
    icon_size = 64
}
table.insert(naughty.dbus.config.mapping, {{appname = "Spotify"},
    naughty.config.presets.spotify})

terminal = "uxterm"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

-- wallpaper settings.
local wp_settings = {
    path = os.getenv("HOME") .. "/Wallpapers/" ,
    notification = true,
    timeout  = 3600*5,
    random = 'random',
    show_files = true,
    show_hidden = false,
    show_fontsize = 14,
    show_path = os.getenv("HOME") .. "/Desktop/"
}
AllWallPaperClass = custom_wallpaper.mod:setup(wp_settings)

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.fair,
    --awful.layout.suit.corner.nw,
    awful.layout.suit.magnifier
}

menubar.show_categories = false
menubar.cache_entries = true
menubar.geometry = {height = 19}
menubar.utils.terminal = terminal

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
                              if client.focus then
                                  client.focus:move_to_tag(t)
                              end
                          end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
                              if client.focus then
                                  client.focus:toggle_tag(t)
                              end
                          end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end) )

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function (c)
                             if c == client.focus then
                                 c.minimized = true
                             else
                                 -- Without this, the following
                                 -- :isvisible() makes no sense
                                 c.minimized = false
                                 if not c:isvisible() and c.first_tag then
                                     c.first_tag:view_only()
                                 end
                                 -- This will also un-minimize
                                 -- the client, if needed
                                 client.focus = c
                                 c:raise()
                             end
                         end),
    awful.button({ }, 4, function ()
                             awful.client.focus.byidx(1)
                         end),
    awful.button({ }, 5, function ()
                             awful.client.focus.byidx(-1)
                         end) )

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry",
    function() AllWallPaperClass:set(s) end )

awful.screen.connect_for_each_screen(function(s)
    -- add wallpapers
    AllWallPaperClass:set(s)

    awful.tag( { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s,
        awful.layout.layouts[1] )
    s.mytaglist = awful.widget.taglist( s, awful.widget.taglist.filter.all,
        taglist_buttons )
    s.mytasklist = awful.widget.tasklist( s,
        awful.widget.tasklist.filter.currenttags, tasklist_buttons )
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", screen = s })

    -- Add widgets to the wibox (mostly from custom_widgets)
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
            { layout = wibox.layout.fixed.horizontal,
                s.mytaglist },
            s.mytasklist,
            { layout = wibox.layout.fixed.horizontal,
                custom_widgets.ip, custom_widgets.bat, custom_widgets.thermal,
                custom_widgets.vol, custom_widgets.cpu, custom_widgets.mem,
                wibox.widget.systray(), custom_widgets.kbd, custom_widgets.date }
            }
    -- add clocks
    s.clock = custom_widgets.clock:create(s,'hours')
    s.clocktimer = gears.timer.weak_start_new( 30,
        function () s.clock:update(); return true end )
    s.clocktimer:start()
end)

AllWallPaperClass:set_timer()

-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    -- mostly wallpaper settings.
    awful.button({ }, 3, function ()
        AllWallPaperClass:set_next_random()
    end),
    awful.button({ }, 1, function()
        AllWallPaperClass:set_next_cycle()
    end),
    -- toggle random
    awful.button({ 'Shift'}, 1, function ()
        AllWallPaperClass:set_toggle_mode()
    end),
    -- show info
    awful.button({ 'Shift'}, 3, function()
        AllWallPaperClass:show_info()
    end),
    -- toggle files
    awful.button({ }, 2, function()
        AllWallPaperClass:set_toggle_files()
    end),
    -- toggle hidden
    awful.button({ 'Shift' }, 2, function()
        AllWallPaperClass:set_toggle_hidden()
    end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
    -- insert wp buttons
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    -- switcher
    awful.key({ "Mod1"            }, "Tab",
      function ()
          switcher.switch( 1, "Mod1", "Alt_L", "Shift", "Tab")
      end),
    awful.key({ "Mod1", "Shift"   }, "Tab",
      function ()
          switcher.switch( 1, "Mod1", "Alt_L", "Shift", "Tab")
      end),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore ),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end
    ),
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
                if screen[s].mywibox.visible then
                    screen[s].mywibox.visible = false
                else
                    screen[s].mywibox.visible = true
                end
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "0", awesome.quit),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end),
    awful.key({ modkey,           }, "u",     function () awful.client.incwfact( 0.05)    end),
    awful.key({ modkey,           }, "o",     function () awful.client.incwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end),
    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end),
    -- Prompt
    awful.key({ modkey },            "r",     function () io.popen(
        'dmenu_run -nb "#222222" -nf "#0088dd" -sb "#00aaff" -sf "#333333" -fn "Droid Sans Mono-10" -p run'
        ) end),
    awful.key({},                    "Print", function () io.popen("bash -c 'import ~/Desktop/$(date +\"%s\").png'") end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),
    -- Launchers
    awful.key({ modkey }, "g", shortcuts.grab),
    awful.key({ modkey, "Shift" }, "g", shortcuts.lock)
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end),
    awful.key({ modkey, "Shift"   }, "c",
    function (c)
        -- option to keep thunderbird alive
        if c.nokill then
            naughty.notify({text = "Not killing '" .. c.name .. "', use 'kill " .. c.pid .. "' instead.", title= "Info"})
        else
            c:kill()
        end
    end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),
    awful.key({ modkey, "Control" }, "Return", function (c)
        c:swap(awful.client.getmaster()) end),
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
        end),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap +
                        awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Floating clients.
    { rule_any = {
        class = { "Arandr", "Gpick", "Pavucontrol", "Nm-connection-editor" },
        role = { "AlarmWindow", "pop-up" } }, properties = { floating = true,
        placement = awful.placement.centered }},

    { rule = { class = "Thunderbird" },
      properties = { tag = "9", screen = 1, nokill=true } },
    { rule = { class = "TelegramDesktop" },
      properties = { tag = "8", screen = 1, nokill=true } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    else
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

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

for i = 1, #autostart_commands do
    run_once(autostart_commands[i])
end
