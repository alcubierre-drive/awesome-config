-- script to make nice looking shortcuts with keygrabbing etc.
-- dofile(extensiondir .. "shortcuts.lua")
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
    -- TODO: Write function that sends client to next / prev screen, same
    -- TODO  workspace!
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
    awful.key({},                    "Print", function () io.popen("import ~/Desktop/Screenshot.png") end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),
    -- toggle clock around the screen
    awful.key({ modkey }, "c", function()
        for s = 1,screen.count() do
            AllMyClocks[s]:toggle()
        end
    end)
    -- Launchers
    --awful.key({ modkey }, "g", grab_keys)
)
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey, "Shift"   }, "o",      awful.client.movetoscreen                        ),
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
    { rule = { class = "whatsapp-desktop" },
      properties = { tag = tags[1][8] } },
    -- { rule = { class = "gimp" },
    --   properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}

