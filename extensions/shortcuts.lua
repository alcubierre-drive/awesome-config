function show_shortcuts(mytext)
    local mywidth = 300
    local myheight = 300

    local infobox = wibox({
        border_width = 0,
        width = mywidth,
        height = myheight,
        x = 10,
        y = 10,
        ontop = true,
        visible = true,
        opacity = 0.8,
    })
    local infotext = wibox.widget.textbox(mytext, false)
    infobox.widget = infotext
    return infobox
end
function grab_keys()
    local preview_wbox = show_shortcuts("<span color='red'>Test</span>")
    grabber = awful.keygrabber.run(function(mod, key, event)
        if event == 'release' then
            return
        end
        if key == 'f' then
            preview_wbox.visible = false
            io.popen("firefox")
        elseif key == 't' then
            preview_wbox.visible = false
            io.popen("thunderbird")
        elseif key == 's' then
            preview_wbox.visible = false
            io.popen("spotify")
        elseif key == 'x' then
            preview_wbox.visible = false
            io.popen("xterm")
        else
            preview_wbox.visible = false
            awful.keygrabber.stop(grabber)
        end
    end)
end
