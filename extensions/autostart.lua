-- autostart
function run_once(cmd)
    if cmd[2] == nil then
        findme = cmd[1]
    else
        findme = cmd[2]
    end
    firstspace = findme:find(" ")
    if firstspace then
        findme = findme:sub(0, firstspace-1)
    end
    if #findme > 15 then
        -- avoid pgrep throwing warnings.
        findme = findme:sub(0,15)
    end
    awful.spawn.with_shell("bash -c 'pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd[1] .. ")'")
end

commands = {
    {"nm-applet", nil},
    {"blueman-applet", nil},
    {"thunderbird", nil},
    {"dropbox", nil},
    {"owncloud", nil},
    -- " -startintray"
    {"telegram-desktop", nil},
    -- " --minimize"
    {"caprine", nil},
    {"Whatsapp", "WhatsApp"},
    {"system-config-printer-applet", "applet.py"},
}

for i = 1, #commands do
    run_once(commands[i])
end

