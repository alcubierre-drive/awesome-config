local lfs = require("lfs")
local math = require("math")
local gears = require("gears")
local cairo = require("lgi").cairo
local os = os
local screen = screen
local table = table
local awful = require('awful')
local naughty = require("naughty")
local string = string
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local setmetatable = setmetatable
local print = print

module("custom_wallpaper")

-- default settings
local settings = {
    path = os.getenv("HOME") .. "/Wallpapers/" ,
    notification = true,
    timeout  = 3600*5,
    random = 'random',
    show_files = true,
    show_hidden = false,
    show_fontsize = 14,
    show_path = os.getenv("HOME") .. "/Desktop/"
}

math.randomseed(os.time())

local function get_wp_files( wp_path )
    local wp_files = {}
    local index_file = 1
    for file in lfs.dir(wp_path) do
        if string.match(file,".png") then
            wp_files[index_file] = file
            index_file = index_file + 1
        end
    end
    return wp_files
end

local function get_desktop_files( my_desktop, show_hidden_files )
    local my_files = ""
    local my_dirs = ""

    -- cycle through files / dirs on the desktop, take care of order.
    local my_filelist = {}
    for file in lfs.dir(my_desktop) do
        table.insert(my_filelist,file)
    end
    table.sort(my_filelist)
    for key, file in pairs(my_filelist) do
        local attributes = lfs.attributes(my_desktop .. file)
        if show_hidden_files then
            if attributes['mode'] == 'directory' then
                if file == '.' or file == '..' then
                else
                    my_dirs = my_dirs .. file .. '/    '
                end
            else
                my_files = my_files .. file .. '    '
            end
        else
            if file:sub(0,1) == '.' then
            else
                if attributes['mode'] == 'directory' then
                    my_dirs = my_dirs .. file .. '/    '
                else
                    my_files = my_files .. file .. '    '
                end
            end
        end
    end

    -- remove last whitespace
    my_files = my_files:sub(1,-5)
    my_dirs = my_dirs:sub(1,-5)
    return my_files, my_dirs
end

local function add_desktop_files( cr, desktop_configuration, off_x, off_y )
    -- dc.show dc.hidden dc.fontsize dc.path

    if desktop_configuration.show == false then
        return cr
    end

    local my_fontsize
    local my_files, my_dirs = get_desktop_files( desktop_configuration.path,
        desktop_configuration.hidden )
    if desktop_configuration.fontsize == nil then
        my_fontsize = 14
    else
        my_fontsize = desktop_configuration.fontsize
    end
    local font_border_alpha = 0.6
    local font_color = 0.1
    local font_border = 0.9
    local font_face = "DejaVu Sans Mono"
    local delta_move = 0.7

    -- selecto font properties of the context
    cr:select_font_face(font_face, cairo.ANTIALIAS)
    cr:set_font_size(my_fontsize)

    -- draw the files
    -- dummy text for the extents, then draw the background rectangle
    cr:move_to(off_x+my_fontsize,off_y+my_fontsize*2)
    cr:text_path(my_files)
    local x1,y1 = cr:get_current_point()
    cr:new_path()
    cr:set_source_rgba(font_border,font_border,font_border,font_border_alpha)
    cr:rectangle( off_x+my_fontsize*0.5, off_y+my_fontsize, x1-off_x,
        y1-my_fontsize*delta_move-off_y )
    cr:fill()
    cr:set_source_rgb(font_color,font_color,font_color)
    cr:move_to(off_x+my_fontsize,off_y+my_fontsize*2)
    cr:text_path(my_files)
    cr:fill()

    -- draw the dirs
    cr:move_to(off_x+my_fontsize,off_y+my_fontsize*(2+1.5))
    cr:text_path(my_dirs)
    local x1,y1 = cr:get_current_point()
    cr:new_path()
    cr:set_source_rgba(font_border,font_border,font_border,font_border_alpha)
    cr:rectangle( off_x+my_fontsize*0.5, off_y+my_fontsize*(3.5-1), x1-off_x,
        y1-my_fontsize*(1.5+delta_move)-off_y )
    cr:fill()
    cr:set_source_rgb(font_color,font_color,font_color)
    cr:move_to(off_x+my_fontsize,off_y+my_fontsize*3.5)
    cr:text_path(my_dirs)
    cr:fill()

    return cr
end

CustomWallpaper = {}
CustomWallpaper.__index = CustomWallpaper
function CustomWallpaper:setup( mysettings )
    result = {}
    setmetatable(result,CustomWallpaper)
    if mysettings == nil then
        result.settings = settings
    else
        result.settings = mysettings
    end
    result.files = get_wp_files( settings.path )
    result.index = math.random( 1, #result.files )
    result.dc = {
        show = settings.show_files,
        hidden = settings.show_hidden,
        fontsize = settings.show_fontsize,
        path = settings.show_path,
    }
    return result
end

function CustomWallpaper:next_wallpaper()
    if self.settings.random == 'random' then
        self.index = math.random( 1, #self.files )
    else
        self.index = (self.index + 1) % #self.files
    end
    if self.index == 0 then
        self.index = #self.files
    end
    if self.settings.notification then
        naughty.notify( { title = "Info",
            text="Wallpaper changed (" .. self.index .. " / " .. #self.files .. ")"
        } )
    end
    self:setall()
end

function CustomWallpaper:toggle_mode()
    if self.settings.random == 'random' then
        self.settings.random = 'cycle'
    else
        self.settings.random = 'random'
    end
end

function CustomWallpaper:set_toggle_mode()
    if self.settings.random == 'random' then
        self.settings.random = 'cycle'
    else
        self.settings.random = 'random'
    end
    if self.settings.notification then
        naughty.notify( { title = "Info", text = "Wallpaper mode changed to '" .. self.settings.random .. "'." } )
    end
end

function CustomWallpaper:set_next_random()
    if self.settings.random ~= 'random' then
        self:toggle_mode()
    end
    self:next_wallpaper( )
    if self.settings.random == 'random' then
        self:toggle_mode()
    end
end

function CustomWallpaper:set_next_cycle()
    if self.settings.random == 'random' then
        self:toggle_mode()
    end
    self:next_wallpaper( )
    if self.settings.random ~= 'random' then
        self:toggle_mode()
    end
end

function CustomWallpaper:show_info()
    local my_dir_infos
    local my_dir_infos_plus
    if self.dc.show then
        my_dir_infos = 'shown'
    else
        my_dir_infos = 'hidden'
    end
    if self.dc.hidden then
        my_dir_infos_plus = 'yes'
    else
        my_dir_infos_plus = 'no'
    end
    if self.settings.notification then
        local text_not = "Filename: " .. self.files[self.index] .. "<br>Index: " .. self.index  .. " / " .. #self.files .. "<br>Mode: " .. self.settings.random .. "<br>Files: " .. my_dir_infos .. "<br>Hidden files: " .. my_dir_infos_plus
        naughty.notify({ title = 'Info', text=text_not})
    end
end

function CustomWallpaper:set_toggle_files()
    local text
    if self.dc.show then
        self.dc.show = false
        text = 'off'
    else
        self.dc.show = true
        text = 'on'
    end
    self:setall()
    if self.settings.notification then
        naughty.notify(
            {
                title = "Info",
                text="Desktop files on Wallpaper: " .. text
            }
        )
    end
end

function CustomWallpaper:set_toggle_hidden()
    local text
    if self.dc.hidden then
        self.dc.hidden = false
        text = 'off'
    else
        self.dc.hidden = true
        text = 'on'
    end
    self:setall()
    if self.settings.notification then
        naughty.notify(
            {
                title = "Info",
                text="Show hidden files: " .. text
            }
        )
    end
end

function CustomWallpaper:set( s )
    local file = self.settings.path .. self.files[self.index]
    local desktop_configuration = self.dc
    local imsurf = cairo.ImageSurface.create_from_png(file)
    local cr_im = cairo.Context.create(imsurf)

    local ix, iy, w, h = cr_im:clip_extents()

    local geom = screen[s].geometry

    local aspect_w = geom.width / w
    local aspect_h = geom.height / h
    aspect_h = math.max(aspect_w, aspect_h)
    aspect_w = math.max(aspect_w, aspect_h)
    cr_im:scale(1/aspect_w, 1/aspect_h)

    local scaled_width = geom.width / aspect_w
    local scaled_height = geom.height / aspect_h
    cr_im:translate((scaled_width - w) / 2, (scaled_height - h) / 2)

    add_desktop_files( cr_im, desktop_configuration,
        -(scaled_width - w) , -(scaled_height - h) )
    gears.wallpaper.maximized( imsurf, s, false, false )
end

function CustomWallpaper:setall()
    for s=1,screen.count() do
        self:set(s)
    end
end

function CustomWallpaper:set_timer()
    local t = gears.timer {
        timeout = self.settings.timeout,
        autostart = true,
        callback = function()
            self:next_wallpaper()
            return true
        end }
    return t
end

return { mod = CustomWallpaper }
