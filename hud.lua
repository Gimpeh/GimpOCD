

























































































local widgetsAreUs = require("widgetsAreUs")
local event = require("event")
local metricsDisplays = require("metricsDisplays")

local maintenanceTimer
local displayMaint = true
local highlighters = {}

local hud = {}
hud.elements = {}
hud.elements.battery = nil
hud.elements.maintenanceAlert = nil

hud.hide = nil
hud.show = nil

local initMessages = {}
function hud.init()
	table.insert(initMessages, widgetsAreUs.initText:new(250, 162, "Left or Right click to set location"))
	table.insert(initMessages, widgetsAreUs.initText:new(250, 182, "Middle click to accept"))
	hud.elements.battery = metricsDisplays.battery.create(1, 1)
	while true do
		local eventType, _, _, x, y, button = event.pull(nil, "hud_click")
		if eventType == "hud_click" then
			if button == 0 then
				if hud.elements.battery then
					hud.elements.battery:remove()
					hud.elements.battery = nil
				end
				hud.elements.battery = metricsDisplays.create(x, y)
				os.sleep(1)
			elseif button == 1 then
				if hud.elements.battery then
					hud.elements.battery:remove()
					hud.elements.battery = nil
				end
				local xModified = x - 203
				local yModified = y - 183
				hud.elements.battery = metricsDisplays.create(xModified, yModified)
			elseif button == 2 then
				break
			end
		end
		os.sleep(0.3)
	end
	hud.elements.maintenanceAlert = widgetsAreUs.maintenanceAlert(1, 1, 200, 50)
	while true do
		local eventType, _, _, x, y, button = event.pull(nil, "hud_click")
		if eventType == "hud_click" then
			if button == 0 then
				hud.elements.maintenanceAlert.remove()
				hud.elements.maintenanceAlert = nil
				os.sleep(0.1)
				hud.elements.maintenanceAlert = widgetsAreUs.maintenanceAlert(x, y, 200, 50)
			elseif button == 1 then
				hud.elements.maintenanceAlert.remove()
				hud.elements.maintenanceAlert = nil
				os.sleep(0.1)

				local xModifier = x - 200
				local yModifier = y - 50
				hud.elements.maintenanceAlert = widgetsAreUs.maintenanceAlert(xModifier, yModifier, 200, 50)
			elseif button == 2 then
				break
			end
		end
		os.sleep(0.3)
	end
	hud.elements.maintenanceAlert.hide()
	hud.hide()

	for _, v in ipairs(initMessages) do
		v:remove()
	end
	initMessages = nil
end

local function removeHighligher()
	for _, v in ipairs(highlighters) do
		v.remove()
	end
		highlighters = {}
		hud.elements.maintenanceAlert.hide()
end

local function maintenanceBeaconer(xyzTable)
	local beacon = widgetsAreUs.maintenanceBeacon(xyzTable.x, xyzTable.y, xyzTable.z)

	table.insert(highlighters, beacon)
end

function hud.modemMessageHandler(port, message)
	if port == 202 then
		local unserializedTable = s.unserialize(message)
		hud.elements.battery:update(unserializedTable)
	elseif port == 201 then
		hud.elements.fluidBar.update(message)
	elseif port == 250 then
		pcall(event.cancel, maintenanceTimer)
		local unserializedTable = s.unserialize(message)
		if displayMaint == true then
			hud.elements.maintenanceAlert.show("Maintenance at" .. tostring(unserializedTable[1].x) .. " " .. tostring(unserializedTable[1].y) .. " " .. (unserializedTable[1].z))
		end
		for i = 1, #unserializedTable do
			maintenanceBeaconer(unserializedTable[i])
		end
		maintenanceTimer = event.timer(60, removeHighligher)
	end
end

function hud.hide()
	hud.elements.battery:setVisible(false)
	displayMaint = false
	hud.elements.maintenanceAlert.hide()
end

function hud.show()
	hud.elements.battery:setVisible(true)
	displayMaint = true
end

return hud