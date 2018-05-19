local math = require("math")
local os = os
local glib = require("lgi").GLib
local DateTime = glib.DateTime
local TimeZone = glib.TimeZone

local settings = {
    fg = { am = '#55a300', pm = '#a38d00' },
    bg = { am = '#050505', pm = '#050505' },
    width = 3
}

local function create_wibar (position, screen)
    local mybar = awful.wibar( {
        position = position,
        border_width = 0,
        stretch = true,
        height = settings.width,
        width = settings.width,
        screen = screen,
    } )
    return mybar
end

local function get_time ()
    local currtime = os.date("%I")+os.date("%M")/60.0+os.date("%S")/3600.0
    local pm = string.lower(os.date("%p"))
    return currtime, pm
end

local function get_progressbar(direction)
    local pbar = wibox.widget {
        {
            max_value = 12/8,
            paddings = 0,
            border_width = 0,
            widget = wibox.widget.progressbar,
        },
        direction = direction,
        layout = wibox.container.rotate,
    }
    return pbar
end

local function assemble_wibar(bar, direction)
    if (direction == 'east') or (direction == 'west') then
        mycols = 1
        myrows = 2
    else
        mycols = 2
        myrows = 1
    end
    bar.widget = wibox.widget {
        get_progressbar(direction),
        get_progressbar(direction),
        forced_num_cols = mycols,
        forced_num_rows = myrows,
        homogeneous = true,
        expand = true,
        layout = wibox.layout.grid,
    }
    pbars = {}
    for k,v in pairs(bar.widget:get_children()) do
        pbars[k] = v:get_children()[1]
    end
    return pbars
end

local function list_pbars(pbars)
    all_pbars_flat = {}
    all_pbars_flat[1] = pbars.top[2]
    all_pbars_flat[2] = pbars.right[1]
    all_pbars_flat[3] = pbars.right[2]
    all_pbars_flat[4] = pbars.bottom[2]
    all_pbars_flat[5] = pbars.bottom[1]
    all_pbars_flat[6] = pbars.left[2]
    all_pbars_flat[7] = pbars.left[1]
    all_pbars_flat[8] = pbars.top[1]
    return all_pbars_flat
end

local function get_pbar_info(currtime)
    --angle = currtime / 6*math.pi
    --pbar_number = math.floor(currtime/(12/8))
    --pbar_fill = 12/8*(1-math.tan((angle-math.pi/2) % (math.pi/4)))
    pbar_fill = currtime % (12/8)
    pbar_number = math.floor(currtime/(12/8))
    return pbar_fill,pbar_number
end

local function set_time(all_pbars, currtime, am_pm_str)
    pbar_fill, pbar_number = get_pbar_info(currtime)
    for i = 1,pbar_number do
        all_pbars[i].color = settings.fg[am_pm_str]
        all_pbars[i].background_color = settings.bg[am_pm_str]
        all_pbars[i]:set_value(12/8)
    end
    all_pbars[pbar_number+1].color = settings.fg[am_pm_str]
    all_pbars[pbar_number+1].background_color = settings.bg[am_pm_str]
    all_pbars[pbar_number+1]:set_value(pbar_fill)
    for i = pbar_number+2,8 do
        all_pbars[i]:set_value(0)
        all_pbars[i].color = settings.fg[am_pm_str]
        all_pbars[i].background_color = settings.bg[am_pm_str]
    end
end

local function toggle_all_wibars(mywibars)
    for index, bar in pairs(mywibars) do
        bar.visible = not bar.visible
    end
end

ScreenClock = {}
ScreenClock.__index = ScreenClock
function ScreenClock:create(screen)
    local mywibars = { }
    mywibars.top = create_wibar('top',screen)
    mywibars.bottom = create_wibar('bottom',screen)
    mywibars.left = create_wibar('left',screen)
    mywibars.right = create_wibar('right',screen)

    local mypbars = { }
    mypbars.top = assemble_wibar(mywibars.top,'north')
    mypbars.bottom = assemble_wibar(mywibars.bottom,'south')
    mypbars.left = assemble_wibar(mywibars.left,'east')
    mypbars.right = assemble_wibar(mywibars.right,'west')


    local my_ordered_pbars = list_pbars(mypbars)

    local time, pm = get_time()
    set_time(my_ordered_pbars, time, pm)

    myclock = {}
    setmetatable(myclock,ScreenClock)
    myclock.wibars = mywibars
    myclock.ordered_pbars = my_ordered_pbars
    return myclock
end

function ScreenClock:toggle()
    toggle_all_wibars(self.wibars)
end

function ScreenClock:update()
    local time, pm = get_time()
    set_time(self.ordered_pbars, time, pm)
end

-- reference implementation
AllMyClocks = {}
for s = 1,screen.count() do
    AllMyClocks[s] = ScreenClock:create(s)
    gears.timer {
        timeout = 30,
        autostart = true,
        callback = function() AllMyClocks[s]:update() end
    }
end