--GimpOCD (Overseeing, Controlling, Directing) main v0.0.1
local event = require("event")
local overlay = require("overlay")
local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local hud = require("hud")

component.modem.open(202)

component.glasses.removeAll()
overlay.init()
hud.init()
local overlayUpdateEvent
local highlighters = {}

local function updateOverlay()
	local success, error = pcall(overlay.update)
	if not success then print(error) end
end

local function handleClick(_, _, _, x, y, button)
    local success, error = pcall(overlay.onClick, x, y, button)
	if not success then print(error) end
end

local function onOverlayEvent(eventType, ...)
	if eventType == "overlay_opened" then
		event.listen("hud_click", handleClick)
		hud.hide()
		overlay.show()
		overlay.update()
		overlayUpdateEvent = event.timer(20, updateOverlay, math.huge)
	elseif eventType == "overlay_closed" then
		event.ignore("hud_click", handleClick)
		overlay.hide()
		hud.show()
		event.cancel(overlayUpdateEvent)
	end
end

local function onHighlightActual(xyz)
	for k,v in ipairs(highlighters) do
		if v.x == xyz.x and v.y == xyz.y and v.z == xyz.z then
			v.remove()
			table.remove(highlighters, k)
			return
		end
	end
	local beacon = widgetsAreUs.maintenanceBeacon(xyz.x, xyz.y, xyz.z)
	beacon.beacon.setColor(0, 1, 1)
	table.insert(highlighters, beacon)
end

local function onHighlight(_, xyz)
	local success, error = pcall(onHighlightActual, xyz)
	if not success then print(error) end
end

local function onModemMessage(_, _, _, port, _, message1)
	if port == 202 then
		local success, error = pcall(hud.modemMessageHandler(port, message1))
		if not success then print(error) end
	end
end

event.listen("highlight", onHighlight)
event.listen("modem_message", onModemMessage)
event.listen("overlay_opened", onOverlayEvent)
event.listen("overlay_closed", onOverlayEvent)
--event.listen("modem_message", onModemMessage)

while true do
	os.sleep(5)
end