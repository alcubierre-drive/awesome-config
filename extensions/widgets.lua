-- widget file
-- clockwidget
datewidget = wibox.widget.textbox()
vicious.register(datewidget, vicious.widgets.date, "%H:%M", 10)
cal = require("extensions/cal")
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
vicious.register(memwidget, vicious.widgets.mem, "$1", 2)
-- volume
require("extensions/volume")
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

for s = 1, screen.count() do
    mypromptbox[s] = awful.widget.prompt()
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
    mywibox[s] = awful.wibar({ position = "bottom", screen = s })
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

-- project: analogue clock around the screen
dofile(extensiondir .. "clock.lua")

