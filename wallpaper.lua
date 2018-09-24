-- seperate file for all wallpaper-based stuff
--
-- setting variables
local lfs = require("lfs")
local Cairo = require("lgi").cairo
local os = os
wp_files = {}
wp_path = os.getenv("HOME") .. "/Wallpapers/"
set_directories = true
show_hidden_files = false
wp_notification = true
wp_timeout  = 3600*5
wp_per_screen_offset = {0,100}

function apply_desktop_wallpaper(wp_file, offset)
    -- declare variables
    local my_desktop = os.getenv("HOME") .. "/Desktop/"
    local my_fontsize = 14
    local font_border_alpha = 0.6
    local font_color = 0.1
    local font_border = 0.9
    local font_face = "DejaVu Sans Mono"
    local delta_move = 0.7
    if offset == nil then
        offset = 0
    end

    -- define initial Cairo objects
    local surface = Cairo.ImageSurface.create_from_png(wp_file)
    local cr = Cairo.Context.create(surface)

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

    -- selecto font properties of the context
    cr:select_font_face(font_face, Cairo.ANTIALIAS)
    cr:set_font_size(my_fontsize)

    -- draw the files
    -- dummy text for the extents, then draw the background rectangle
    cr:move_to(offset+my_fontsize,my_fontsize*2)
    cr:text_path(my_files)
    local x1,y1 = cr:get_current_point()
    cr:new_path()
    cr:set_source_rgba(font_border,font_border,font_border,font_border_alpha)
    cr:rectangle(offset+my_fontsize*0.5,my_fontsize,x1-offset,y1-my_fontsize*delta_move)
    cr:fill()
    cr:set_source_rgb(font_color,font_color,font_color)
    cr:move_to(offset+my_fontsize,my_fontsize*2)
    cr:text_path(my_files)
    cr:fill()

    -- draw the dirs
    cr:move_to(offset+my_fontsize,my_fontsize*(2+1.5))
    cr:text_path(my_dirs)
    local x1,y1 = cr:get_current_point()
    cr:new_path()
    cr:set_source_rgba(font_border,font_border,font_border,font_border_alpha)
    cr:rectangle(
        offset+my_fontsize*0.5,my_fontsize*(3.5-1),x1-offset,y1-my_fontsize*(1.5+delta_move)
    )
    cr:fill()
    cr:set_source_rgb(font_color,font_color,font_color)
    cr:move_to(offset+my_fontsize,my_fontsize*3.5)
    cr:text_path(my_dirs)
    cr:fill()

    return cr:get_target()
end

-- getting file list
index_file = 1
for file in lfs.dir(wp_path) do
    if string.match(file,".png") then
        wp_files[index_file] = file
        index_file = index_file + 1
    end
end
index_file = nil
-- get initial index
random_wallpaper = 'random'
math.randomseed(os.time())
wp_index = math.random( 1, #wp_files)
-- timer
wp_timer = gears.timer { timeout = wp_timeout }
wp_timer:connect_signal("timeout", function()
    if random_wallpaper == 'random' then
        wp_index = math.random( 1, #wp_files)
    elseif random_wallpaper == 'static' then
    else
        wp_index = (wp_index + 1) % #wp_files
    end
    if wp_index == 0 then
        wp_index = #wp_files
    end
    if wp_notification == true then
        naughty.notify(
        {
            title = "Info",
            text="Wallpaper changed (" .. wp_index .. " / " .. #wp_files .. ")"
        }
        )
    end
    -- optionally print folder contents
    for s = 1, screen.count() do
        if set_directories == true then
            -- returns a cairo surface
            current_wp = apply_desktop_wallpaper(wp_path .. wp_files[wp_index], wp_per_screen_offset[s])
        else
            -- just the filename of the .png
            current_wp = wp_path .. wp_files[wp_index]
        end
        gears.wallpaper.maximized(current_wp, s)
    end

    -- some timer settings for the changing
    wp_timer:stop()
    wp_timer.timeout = wp_timeout
    wp_timer:start()
end)
-- initial start when rc.lua is first run
wp_timer:start()

