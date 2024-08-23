local widgetsAreUs = require("widgetsAreUs")
local event = require("event")
local metricsDisplays = require("metricsDisplays")
local s = require("serialization")

local hud = {}
hud.elements = {}
hud.elements.battery = nil

hud.hide = nil
hud.show = nil

local initMessages = {}
function hud.init()
	table.insert(initMessages, widgetsAreUs.initText(250, 162, "Left or Right click to set location"))
	table.insert(initMessages, widgetsAreUs.initText(250, 182, "Middle click to accept"))
	hud.elements.battery = metricsDisplays.battery.create(1, 1)
	while true do
		local eventType, _, _, x, y, button = event.pull(nil, "hud_click")
		if eventType == "hud_click" then
			if button == 0 then
				if hud.elements.battery then
					hud.elements.battery.remove()
					os.sleep(0.1)
					hud.elements.battery = nil
				end
				hud.elements.battery = metricsDisplays.battery.create(x, y)
				os.sleep(1)
			elseif button == 1 then
				if hud.elements.battery then
					hud.elements.battery.remove()
					os.sleep(0.1)
					hud.elements.battery = nil
				end
				local xModified = x - 203
				local yModified = y - 183
				hud.elements.battery = metricsDisplays.battery.create(xModified, yModified)
			elseif button == 2 then
				break
			end
		end
		os.sleep(0.3)
	end

	hud.hide()
	for _, v in ipairs(initMessages) do
		v.remove()
	end
	initMessages = nil
	os.sleep(100)
end

function hud.hide()
	hud.elements.battery.setVisible(false)
end

function hud.show()
	hud.elements.battery.setVisible(true)
end

function hud.modemMessageHandler(port, message)
	if port == 202 then
		local unserializedTable = s.unserialize(message)
		hud.elements.battery.update(unserializedTable)
	end
end

return hud