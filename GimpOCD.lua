--GimpOCD (Overseeing, Controlling, Directing) main v0.0.1
local event = require("event")
local overlay = require("overlay")
local component = require("component")
component.glasses.removeAll()
overlay.init()
local overlayUpdateEvent

local function updateOverlay()
	overlay.update()
end

local function handleClick(_, _, _, x, y, button)
    local success, error = pcall(overlay.onClick, x, y, button)
	if not success then print(error) end
end

local function onOverlayEvent(eventType, ...)
	if eventType == "overlay_opened" then
		event.listen("hud_click", handleClick)
		overlay.show()
		overlay.update()
		overlayUpdateEvent = event.timer(20, updateOverlay, math.huge)
	elseif eventType == "overlay_closed" then
		event.ignore("hud_click", handleClick)
		overlay.hide()
		event.cancel(overlayUpdateEvent)
	end
end

event.listen("overlay_opened", onOverlayEvent)
event.listen("overlay_closed", onOverlayEvent)
--event.listen("modem_message", onModemMessage)

while true do
	os.sleep(5)
end