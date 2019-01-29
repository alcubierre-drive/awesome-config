-- TODO does not correctly identify the current screen. Why?
-- TODO not as lockscreen.
-- TODO use two wiboxes, lower one with trasparency / blur; upper one with just
-- the clock / controls.

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
local mousegrabber = mousegrabber

module("shortcuts")

local settings = {
    hours = '#ff6300',
    minutes = '#ff6300',
    seconds = '#ff0000',
    bg = {1,1,1,0.2},
    widget_background = '#00000000',
    hours_width = 6,
    minutes_width = 4,
    seconds_width = 2,
    hours_factor = 0.6,
    minutes_factor = 0.9,
    seconds_factor = 1.0,
    update_interval = 0.5,
    show_digital = true,
    show_hours = true,
    show_minutes = true,
    show_seconds = true,
    -- the first element of the table is displayed (and its first char is used 
    -- as the shortcut key), if the second element is not `nil`, a function is 
    -- expected that will be run instead of the first element as 
    -- `awful.spwan.easy_async()`.
    shortcuts = {
        {'firefox', nil},
        {'xterm', nil},
        {'spotify', nil},
        {'thunderbird', nil},
        {'l – cash', function () awful.spawn.easy_async(
            os.getenv('HOME') .. '/.scripts/cash', function() end
            ) end
        },
        {'pcmanfm', nil},
        {'garfield', function () awful.spawn.easy_async(
            os.getenv('HOME') .. '/.scripts/garfield',
            function () end
            ) end },
        {'calvin', function () awful.spawn.easy_async(
            os.getenv('HOME') .. '/.scripts/garfield -c',
            function () end
            ) end },
        {'kill services', function ()
            awful.spawn.easy_async(
                "killall telegram-deskto thunderbird " ..
                "owncloud blueman-applet nm-applet applet.py",
                function () end
            )
        end }
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

local function get_bgimg(settings, show_shortcuts, myscreen)
    local usescreen = myscreen
    if myscreen == nil then
        usescreen = screen[mouse.screen]
    end
    local mywidth = usescreen.geometry.width
    local myheight = usescreen.geometry.height

    local surface = Cairo.ImageSurface(Cairo.Format.ARGB32,mywidth,myheight)
    local cr = Cairo.Context.create(surface)

    lengths_x = divide_length_add_delta(mywidth,4)
    lengths_y = divide_length_add_delta(myheight,4)

    -- background
    cr:set_source_rgba(settings.bg[1],settings.bg[2],settings.bg[3],settings.bg[4])
    cr:rectangle(0,0,mywidth,myheight)
    cr:fill()

    -- clock hour strokes
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

    -- paint the clock (hours, minutes, seconds)
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

    -- paint the shortcuts info
    -- TODO add red first letter.
    if show_shortcuts == true then
        cr:set_source_rgb(0,0,0)
        cr:set_font_size(20)
        cr:move_to(mywidth*(1/2+1/6),myheight*(1/2-1/6))
        for idx, short in pairs(settings.shortcuts) do
            cr:show_text(short[1])
            cr:move_to(mywidth*(1/2+1/6),myheight*(1/2-1/6)+idx*(20+5))
        end
    end

    -- paint the digital clock
    if settings.show_digital == true then
        cr:set_source_rgb(0,0,0)
        cr:set_font_size(30)
        cr:move_to(mywidth*(1/2-1/3),myheight*(1/2)-3)
        cr:show_text(os.date("%H:%M:%S"))
        cr:move_to(mywidth*(1/2-1/3),myheight*(1/2)+33)
        local mycurrentdate = os.date("%A, %d. %B %Y")
        cr:show_text(mycurrentdate)
        if show_shortcuts == false then
            -- show choice about password / fingerprint authentification.
            local dateextent = cr:text_extents(mycurrentdate)
            local blue = {0,0.54,1}
            local red = {1,0.39,0}
            cr:set_font_size(15)

            local passwdextent = cr:text_extents("Password")
            cr:set_source_rgb(blue[1],blue[2],blue[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-passwdextent.width,
                myheight*(1/2)-18)
            cr:show_text("Password")
            cr:set_source_rgb(red[1],red[2],red[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-passwdextent.width,
                myheight*(1/2)-18)
            cr:show_text("P")

            local fprintextent = cr:text_extents("Fingerprint")
            cr:set_source_rgb(blue[1],blue[2],blue[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-fprintextent.width,
                myheight*(1/2)-3)
            cr:show_text("Fingerprint")
            cr:set_source_rgb(red[1],red[2],red[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-fprintextent.width,
                myheight*(1/2)-3 )
            cr:show_text("F")
        end
    end

    return surface
end

function get_auth_img(settings, fprint, myscreen)
    local usescreen = myscreen
    if myscreen == nil then
        usescreen = screen[mouse.screen]
    end
    local mywidth = usescreen.geometry.width
    local myheight = usescreen.geometry.height

    local surface = Cairo.ImageSurface(Cairo.Format.ARGB32,mywidth,myheight)
    local cr = Cairo.Context.create(surface)

    lengths_x = divide_length_add_delta(mywidth,4)
    lengths_y = divide_length_add_delta(myheight,4)

    -- background
    cr:set_source_rgba(settings.bg[1],settings.bg[2],settings.bg[3],settings.bg[4])
    cr:rectangle(0,0,mywidth,myheight)
    cr:fill()

    -- clock hour strokes
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

    -- paint the clock (hours, minutes, seconds)
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

    -- paint the digital clock
    if settings.show_digital == true then
        cr:set_source_rgb(0,0,0)
        cr:set_font_size(30)
        cr:move_to(mywidth*(1/2-1/3),myheight*(1/2)-3)
        cr:show_text(os.date("%H:%M:%S"))
        cr:move_to(mywidth*(1/2-1/3),myheight*(1/2)+33)
        local mycurrentdate = os.date("%A, %d. %B %Y")
        cr:show_text(mycurrentdate)

        local dateextent = cr:text_extents(mycurrentdate)
        local blue = {0,0.54,1}
        local red = {1,0.39,0}
        cr:set_font_size(15)

        if fprint then
            local fprintextent = cr:text_extents("Fingerprint")
            local textextent = cr:text_extents("scan fingerprint")
            cr:set_source_rgb(blue[1],blue[2],blue[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-fprintextent.width,
                myheight*(1/2)-3)
            cr:show_text("Fingerprint")
            cr:set_source_rgb(red[1],red[2],red[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-textextent.width,
                myheight*(1/2)-18 )
            cr:show_text("scan fingerprint")
        else
            local passwdextent = cr:text_extents("Password")
            local textextent = cr:text_extents("type password")
            cr:set_source_rgb(blue[1],blue[2],blue[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-passwdextent.width,
                myheight*(1/2)-18)
            cr:show_text("Password")
            cr:set_source_rgb(red[1],red[2],red[3])
            cr:move_to( mywidth*(1/2-1/3)+dateextent.width-textextent.width,
                myheight*(1/2)-3)
            cr:show_text("type password")
        end

    end

    return surface
end

-- wrapper to show the clock; not the lock.
local function show_clock_face(settings, show_shortcuts, myscreen)
    local usescreen = myscreen
    if myscreen == nil then
        usescreen = screen[mouse.screen]
    end

    local mywidth = usescreen.geometry.width
    local myheight = usescreen.geometry.height
    mybox = wibox {
        ontop = true,
        visible = true,
        bg = settings.widget_background,
        border_width = 0,
        width = mywidth,
        height = myheight,
        screen = usescreen,
        x = 0,
        y = 0,
    }

    mybox.bgimage = get_bgimg(settings, show_shortcuts, usescreen)
    return mybox
end

-- grab the keys for shortcuts
function grab_keys()
    -- here we want some shortcuts.
    local preview_wbox = show_clock_face(settings, true, nil)
    local locktimer = gears.timer {
            timeout = settings.update_interval,
            autostart = true,
            callback = function ()
                preview_wbox.bgimage = get_bgimg(settings, true, nil)
            end
        }
    grabber = awful.keygrabber.run(function(mod, key, event)
        if event == 'release' then
            return
        end
        for idx, short_tab in pairs(settings.shortcuts) do
            short = short_tab[1]
            extra = short_tab[2]
            if key == short:sub(1,1) then
                preview_wbox.visible = false
                --awful.spawn.easy_async(short, function () end)
                if extra ~= nil then
                    extra()
                else
                    awful.spawn.easy_async(short, function () end)
                end
            end
        end
        preview_wbox.visible = false
        locktimer:stop()
        awful.keygrabber.stop(grabber)
    end)
end

-- lockscreen
function lock()
    local preview_wboxes = {}
    for s = 1,screen.count() do
        preview_wboxes[s] = show_clock_face(settings, false, screen[s])
    end

    function edit_wboxes(visible, auth)
        if visible == true then
            if auth == "fp" then
                for s = 1, screen.count() do
                    preview_wboxes[s].bgimage = get_auth_img(settings, true, screen[s])
                end
            else
                if auth == "pw" then
                    for s = 1, screen.count() do
                        preview_wboxes[s].bgimage = get_auth_img(settings, false, screen[s])
                    end
                else
                    for s = 1, screen.count() do
                        preview_wboxes[s].bgimage = get_bgimg(settings, false, screen[s])
                    end
                end
            end
        else
            for s = 1, screen.count() do
                preview_wboxes[s].visible = false
            end
        end
    end

    local locktimer = gears.timer {
            timeout = settings.update_interval,
            autostart = true,
            callback = function ()
                edit_wboxes(true, false)
            end
        }

    local fptimer = gears.timer {
            timeout = settings.update_interval,
            autostart = false,
            callback = function ()
                edit_wboxes(true, "fp")
            end
        }

    local pwtimer = gears.timer {
            timeout = settings.update_interval,
            autostart = false,
            callback = function ()
                edit_wboxes(true, "pw")
            end
        }

    function makeauth(fprintauth)
        awful.keygrabber.stop(grabber)
        mousegrabber.stop()
        if fprintauth == true then
            locktimer:stop()
            fptimer:start()
            awful.spawn.easy_async('xtrlock-pam', function (stdout, stderr, reason, exit_code)
                fptimer:stop()
                edit_wboxes(false)
                naughty.resume()
            end)
        else
            locktimer:stop()
            pwtimer:start()
            awful.spawn.easy_async('xtrlock-pam -f', function (stdout, stderr, reason, exit_code)
                pwtimer:stop()
                edit_wboxes(false)
                naughty.resume()
            end)
        end
    end

    naughty.suspend()

    if mousegrabber.isrunning() then
        print("Mousegrabber already running.")
    else
        mousegrabber.run(
        function(mouse)
            return true
        end,
        "dot")
    end

    grabber = awful.keygrabber.run(function(mod, key, event)
        if event == 'release' then
            return
        end
        if key == 'p' then
            makeauth(false)
        end
        if key == 'f' then
            makeauth(true)
        end
        if key == 'Return' then
            makeauth(false)
        end
    end)
end

return {grab = grab_keys, settings = settings, lock = lock}
-- TODO add unlock() function to release keygrabber if in locked state.
