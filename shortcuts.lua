local Cairo = require("lgi").cairo
local os = os
local mouse = mouse
local screen = screen
local wibox = require('wibox')
local table = table
local keygrabber = keygrabber
local math = require('math')
local awful = require('awful')
local gears = require("gears")
local client = client
awful.client = require('awful.client')
local naughty = require("naughty")
local string = string
local tostring = tostring
local tonumber = tonumber
local debug = debug
local pairs = pairs
local unpack = unpack

module("shortcuts")

local settings = {
    hours = '#aa0000',
    minutes = '#aa0000',
    seconds = '#000000',
    hours_width = 6,
    minutes_width = 4,
    seconds_width = 2,
    hours_factor = 0.6,
    minutes_factor = 0.9,
    seconds_factor = 1.0,
    show_hours = true,
    show_minutes = true,
    show_seconds = false,
    shortcuts = {
        'firefox',
        'xterm',
        'spotify',
        'thunderbird',
        'inkscape',
        'libreoffice',
        'gimp',
        'pcmanfm',
        'chromium',
        'virtualbox'
    },
    below_add = 0
}

local function get_my_coords(norm_quant, width, height)
    part = (norm_quant*8) % 1
    num = math.floor(norm_quant *8)
    directions = {}
    directions[1] = {{width/2, 0}, {width/2,0}}
    directions[2] = {{width, 0}, {0,height/2}}
    directions[3] = {{width, height/2}, {0,height/2}}
    directions[4] = {{width, height} , {-width/2,0}}
    directions[5] = {{width/2, height}, {-width/2,0}}
    directions[6] = {{0,height}, {0,-height/2}}
    directions[7] = {{0,height/2}, {0,-height/2}}
    directions[8] = {{0,0}, {width/2,0}}
    coord_null = directions[num+1][1]
    coord_delta = directions[num+1][2]
    return {coord_null[1]+coord_delta[1]*part, coord_null[2]+coord_delta[2]*part}
end

local function get_coordinates(width, height)
    local hours = os.date("%I")
    local minutes = os.date("%M")
    local seconds = os.date("%S")
    hours = hours + minutes/60.0 + seconds/3600.0
    minutes = minutes + seconds/60.0
    hours = (hours/12) % 1
    minutes = (minutes/60) % 1
    seconds = (seconds/60) % 1
    return
        get_my_coords(hours, width, height),
        get_my_coords(minutes, width, height),
        get_my_coords(seconds, width, height)
end

local function change_with_difference(center, edge, factor)
    dx = edge[1]-center[1]
    dy = edge[2]-center[2]
    return center[1]+dx*factor, center[2]+dy*factor
end

local function divide_length_add_delta (length, delta)
    middle = length / 2
    add = (length - middle) / 1.5
    first = middle-add-delta
    second = middle-delta
    third = middle+add-delta
    return {first,second,third}
end

local function show_clock_face(settings)
    local mywidth = screen[mouse.screen].geometry.width
    local myheight = screen[mouse.screen].geometry.height
    mybox = wibox {
        ontop = true,
        visible = true,
        opacity = 0.6,
        border_width = 0,
        width = mywidth,
        height = myheight,
        x = 0,
        y = 0,
    }
    local surface = Cairo.ImageSurface(Cairo.Format.ARGB32,mywidth,myheight)
    local cr = Cairo.Context.create(surface)
    lengths_x = divide_length_add_delta(mywidth,4)
    lengths_y = divide_length_add_delta(myheight,4)
    cr:set_source_rgb(1,1,1)
    cr:rectangle(0,0,mywidth,myheight)
    cr:fill()
    cr:set_source_rgb(0,0,0)
    for j=1,3 do
        cr:rectangle(lengths_x[j],0,8,20)
        cr:fill()
        cr:rectangle(lengths_x[j],myheight-(20+settings.below_add),8,
            20+settings.below_add)
        cr:fill()
        cr:rectangle(0,lengths_y[j],20,8)
        cr:fill()
        cr:rectangle(mywidth-20,lengths_y[j],20,8)
        cr:fill()
    end
    cr:rectangle(mywidth/2-5,myheight/2-5,10,10)
    cr:fill()

    local hours, minutes, seconds = get_coordinates(mywidth, myheight)
    if settings.show_hours == true then
        cr:move_to(mywidth/2,myheight/2)
        cr:set_line_width(settings.hours_width)
        cr:set_source_rgb(gears.color.parse_color(settings.hours))
        cr:line_to(change_with_difference({mywidth/2,myheight/2},hours,
            settings.hours_factor))
        cr:stroke()
    end

    if settings.show_minutes == true then
        cr:move_to(mywidth/2,myheight/2)
        cr:set_line_width(settings.minutes_width)
        cr:set_source_rgb(gears.color.parse_color(settings.minutes))
        cr:line_to(change_with_difference({mywidth/2,myheight/2},minutes,
            settings.minutes_factor))
        cr:stroke()
    end

    if settings.show_seconds == true then
        cr:move_to(mywidth/2,myheight/2)
        cr:set_line_width(settings.seconds_width)
        cr:set_source_rgb(gears.color.parse_color(settings.seconds))
        cr:line_to(change_with_difference({mywidth/2,myheight/2},seconds,
            settings.seconds_factor))
        cr:stroke()
    end

    cr:set_source_rgb(0,0,0)
    cr:set_font_size(20)
    cr:move_to(mywidth*(1/2+1/6),myheight*(1/2-1/6))
    for idx, short in pairs(settings.shortcuts) do
        cr:show_text(short)
        cr:move_to(mywidth*(1/2+1/6),myheight*(1/2-1/6)+idx*(20+5))
    end
        --cr:fill()

    mybox.bgimage = surface
    return mybox
end

function grab_keys()
    local preview_wbox = show_clock_face(settings)
    grabber = awful.keygrabber.run(function(mod, key, event)
        if event == 'release' then
            return
        end
        for idx, short in pairs(settings.shortcuts) do
            if key == short:sub(1,1) then
                preview_wbox.visible = false
                awful.spawn.easy_async(short, function () end)
            end
        end
        preview_wbox.visible = false
        awful.keygrabber.stop(grabber)
    end)
end

return {grab = grab_keys, settings = settings}
