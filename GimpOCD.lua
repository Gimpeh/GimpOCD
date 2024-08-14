--GimpOCD (Overseeing, Controlling, Directing) main v0.0.1
local event = require("event")
local overlay = require("overlay")
local component = require("component")
component.glasses.removeAll()
overlay.init()

local function handleClick(_, _, _, x, y, button)
    overlay.onClick(x, y, button)
end

local function onOverlayEvent(eventType, ...)
	if eventType == "overlay_opened" then
		event.listen("hud_click", handleClick)
		overlay.show()
	elseif eventType == "overlay_closed" then
		event.ignore("hud_click", handleClick)
		overlay.hide()
	end
end

event.listen("overlay_opened", onOverlayEvent)
event.listen("overlay_closed", onOverlayEvent)
--event.listen("modem_message", onModemMessage)

while true do
	os.sleep(5)
end