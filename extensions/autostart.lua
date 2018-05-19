-- autostart
function run_once(cmd)
    findme = cmd
    firstspace = cmd:find(" ")
    if firstspace then
        findme = cmd:sub(0, firstspace-1)
    end
    if #findme > 15 then
        -- avoid pgrep throwing warnings.
        findme = findme:sub(0,15)
    end
    awful.spawn.with_shell("bash -c 'pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")'")
end

commands = {
    "nm-applet",
    "blueman-applet",
    "thunderbird",
    "dropbox",
    "owncloud",
    --"telegram-desktop -startintray",
    "telegram-desktop",
    --"caprine --minimize",
    "caprine",
    --"Whatsapp",
    "system-config-printer-applet"
}

for i = 1, #commands do
    run_once(commands[i])
end

