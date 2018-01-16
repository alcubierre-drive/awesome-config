-- mensawidget
local mensa = {}

local tooltip = awful.tooltip({})

function get_meal(days,meal)
	local args = 'd' .. days .. ' ' .. 'm' .. meal
	local file = assert(io.popen(extensiondir .. '/mensa.py ' .. args))
	bold = true
	final_string = ''
	for line in file:lines() do
		if bold then
			final_string = '<b>' .. line .. '</b>\n'
		else
			final_string = final_string .. line
		end
		bold = false
	end
	file:close()
	return final_string
end

local curr_meal = 3
local curr_day = 0

function tooltip:update()
	result = get_meal(curr_day,curr_meal)
	tooltip:set_markup(string.format('<span>%s</span>',result))
end

function switch_meal(amount)
	amount = amount + curr_meal
	while amount < 0 do
		amount = amount + 13
	end
	curr_meal = amount
	tooltip:set_markup(string.format('<span>%s</span>',get_meal(curr_day,curr_meal)))
end

function switch_day(amount)
	curr_day = curr_day + amount
	tooltip:set_markup(string.format('<span>%s</span>',get_meal(curr_day,curr_meal)))
end

function mensa.register(widget)
	tooltip:update()
	tooltip:add_to_object(widget)
	widget:connect_signal("mouse::enter",tooltip.update)
	widget:buttons(awful.util.table.join(
	-- essen vorher
	awful.button({ }, 1, function()
		switch_meal(-1)
	end),
	-- essen nachher
	awful.button({ }, 3, function()
		switch_meal(1)
	end),
	-- tag vorher
	awful.button({ 'Shift' }, 1, function()
		switch_day(-1)
	end),
	-- tag nachher
	awful.button({ 'Shift' }, 3, function()
		switch_day(1)
	end),
	-- reset 
	awful.button({ }, 2, function()
		curr_meal = 3
		curr_day = 0
	end)
	))
end

return mensa
