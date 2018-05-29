local wibox = require("wibox")
local awful = require("awful")

volume_widget = wibox.widget.textbox()
volume_widget:set_align("right")

notification = false

function update_volume(widget)
   -- TODO probably rewrite this with easy_async, but requires a lot of work 
   -- (forking easy_async?)
   --https://github.com/stefano-m/lua-pulseaudio_dbus
   local fd = io.popen('pactl list sinks')
   local volume = fd:read("*all")
   fd:close()
   -- get volume
   idx = 0
   for word in string.gmatch(volume,"%d+%%") do
       idx = idx + 1
       if idx == 4 then
           my_volume = word
       end
   end
   idx = string.find(volume,"Mute: yes")
   if idx == nil then
       my_mute = false
   else
       my_mute = true
   end
   if my_mute == true then
       volume = "<span color='orange'> ♪ " .. my_volume .. " </span>"
   else
      if tonumber(my_volume:sub(1,-2)) >= 101 then
         volume = "<span color='red'> ♪ " .. my_volume .. " </span>"
         if not notification then
            naughty.notify(
            {
                title = "Caution",
                text="Volume over 100%"
            }
            )
            notification = true
        end
      else
         volume = "<span> ♪ " .. my_volume .. " </span>"
         notification = false
      end
   end
   -- volume = " vol: " .. volume .. " "
   widget:set_markup(volume)
end

update_volume(volume_widget)

function change_volume(x)
    local str = 'pactl set-sink-volume 1 '
    if tonumber(x) > 0 then
        str = str .. "+"
    end
    local muell = io.popen(str .. tonumber(x) .. '%')
    muell:close()
end

mytimer = gears.timer({ timeout = 0.5 })
mytimer:connect_signal("timeout", function () update_volume(volume_widget) end)
mytimer:start()

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
        assert(io.popen("/usr/bin/pavucontrol"))
    end)
))
