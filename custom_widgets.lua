local os = os
local io = io
local table = table
local string = string
local tostring = tostring
local tonumber = tonumber
local debug = debug
local pairs = pairs
local unpack = unpack
local socket = require("socket")
local math = require('math')

local awful = require('awful')
local gears = require("gears")
local client = client
awful.client = require('awful.client')
local naughty = require("naughty")
local wibox = require("wibox")
local vicious = require("vicious")

local beautiful = beautiful
local cal = require("cal")
local clock = require("clock")


module("custom_widgets")

local datewidget = wibox.widget.textbox()
vicious.register(datewidget, vicious.widgets.date, "%H:%M", 10)
cal.register(datewidget,'<span color="#ffaa00"><b><u>%s</u></b></span>')
-- Cpuwidget, memwidget, swapwidget
local cpuwidget = wibox.widget.graph()
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
        awful.spawn.easy_async("uxterm -e htop", function () end)
    end)
))
--mensa = require('extensions/mensa') -- mensa @ cpu
--mensa.register(cpuwidget)
vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 2)

local memwidget = wibox.widget.graph()
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
        awful.spawn.easy_async("uxterm -e htop", function () end)
    end)
))
vicious.register(memwidget, vicious.widgets.mem, "$1", 2)

-- thermal
local thermalwidget = wibox.widget.textbox()
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
local batwidget = wibox.widget.textbox()
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
local kbdwidget = awful.widget.keyboardlayout:new()

-- ip addr widget
local function get_ipaddr()
    local myip = socket.dns.toip(socket.dns.gethostname())
    local markup = '<span color="#00ff00">'
    if myip:sub(1,8) == '127.0.0.' then
        markup = '<span color="#ff0000">'
    end
    return markup .. '&#9041; ' .. myip .. '  </span>'
end
local ipwidget = wibox.widget.textbox( get_ipaddr() )
local iptimer = gears.timer {
    timeout = 2,
    autostart = true,
    callback = function()
        ipwidget.markup = get_ipaddr()
    end }

local function get_calm_state()
    local text
    if naughty.is_suspended() then
        text = "<span color='red'><b> -q </b></span> "
    else
        text = "<b> -v </b> "
    end
    return text
end
local calmwidget = wibox.widget.textbox( get_calm_state() )
local calmtimer = gears.timer {
    timeout = 1,
    autostart = true,
    callback = function()
        calmwidget.markup = get_calm_state()
    end }
calmwidget:buttons(awful.util.table.join(
    -- click: start pavucontrol-qt
    awful.button({ }, 1, naughty.toggle)
))

local function get_rwthonline_info()
    local http = require("socket.http")
    local out = http.request("http://ist.rwthonline.online")
    if out == nil then
        return "<span color='orange'> Nicht online </s>"
    elseif out:find("Sieht so aus.") then
        return "<span font_desc='monospace' color='green'> Online </s>"
    else
        return "<span color='orange'> Nicht online </s>"
    end
end
local function rwthonline( mywidget )
    if not tooltip then
        tooltip = awful.tooltip({})
            function tooltip:update()
                tooltip:set_markup(get_rwthonline_info())
            end
        tooltip:update()
    end
    tooltip:add_to_object(mywidget)
    mywidget:connect_signal("mouse::enter",tooltip.update)
end

local volume_widget = wibox.widget.textbox()
volume_widget.notification = false

local function check_volume()
    -- depends on a damon running that saves the volume to
    -- ~/.cache/pa_volume.log
    local f = io.open(os.getenv("HOME").."/.cache/pa_volume.log","r")
    local lines = f:read("*all")
    f:close()
    local volume
    for w in string.gmatch(lines,"%d+") do
        volume = w
    end
    local idx = string.find(lines,"M")
    if idx == nil then
        return tonumber(volume), false
    else
        return tonumber(volume), true
    end
end
local function update_volume(widget)
    local vol
    local mute
    vol, mute = check_volume()
    local color
    if mute then
        color = "color='orange'"
    elseif vol >= 101 then
        color = "color='red'"
    else
        color = ""
    end

    local volstr = "<span " .. color .. "> ♪ " .. tostring(vol) .. "% </span>"

    if vol >= 101 then
        if not volume_widget.notification then
            naughty.notify( { title = "Caution", text="Volume over 100%" } )
            volume_widget.notification = true
        end
    else
        volume_widget.notification = false
    end

    widget.markup = volstr
    widget.font = beautiful.font
end

-- run this once.
update_volume(volume_widget)

local function change_volume(x)
    local str = 'pactl set-sink-volume @DEFAULT_SINK@ '
    if tonumber(x) > 0 then
        str = str .. "+"
    end
    awful.spawn.easy_async(str .. tonumber(x) .. '%', function () end)
end

local volume_timer = gears.timer {
    timeout = 0.5,
    autostart = true,
    callback = function () update_volume(volume_widget) end
}

-- volume decr / incr in %
local step_size = 0.5
volume_widget:buttons(awful.util.table.join(
    -- 4 scroll up
    awful.button({ }, 4, function()
        change_volume(step_size)
    end),
    -- 5 scroll down
    awful.button({ }, 5, function()
        change_volume(-step_size)
    end),
    -- click: start pavucontrol-qt
    awful.button({ }, 1, function()
        awful.spawn.easy_async("/usr/bin/pavucontrol", function () end)
    end)
))

return { date = datewidget, cpu = cpuwidget, mem = memwidget, kbd = kbdwidget,
    vol = volume_widget, vol_timer = volume_timer, thermal = thermalwidget,
    bat = batwidget, ip = ipwidget, ip_timer = iptimer, calm = calmwidget,
    calm_timer = calmtimer, rwth = rwthonline, clock = clock.clock }
