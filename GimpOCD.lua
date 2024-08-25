--GimpOCD (Overseeing, Controlling, Directing) main v0.0.2
local event = require("event")
local overlay = require("overlay")
local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local hud = require("hud")

-----------------------------------------
--start up

component.modem.open(202)
component.glasses.removeAll()
overlay.init()
hud.init()

-----------------------------------------
---forward declarations

local overlayUpdateEvent
local highlighters = {}
local onModemMessage

-----------------------------------------
---event handlers

local function updateOverlay()
    os.sleep(0)
    local success, error = pcall(overlay.update)
    if not success then print("Error in updateOverlay: " .. error) end
    os.sleep(0)
end

local function handleClick(_, _, _, x, y, button)
    local success, error = pcall(overlay.onClick, x, y, button)
    if not success then print("Error in handleClick: " .. error) end
    os.sleep(0)
end

local function onOverlayEvent(eventType, ...)
    local success, error = pcall(function()
        if eventType == "overlay_opened" then
            event.ignore("modem_message", onModemMessage)
            event.listen("hud_click", handleClick)
            hud.hide()
            overlay.show()
            os.sleep(0)
            overlay.update()
            os.sleep(0)
            overlayUpdateEvent = event.timer(3000, updateOverlay, math.huge)
        elseif eventType == "overlay_closed" then
            event.ignore("hud_click", handleClick)
            overlay.hide()
            hud.show()
            event.cancel(overlayUpdateEvent)
            os.sleep(0)
            event.listen("modem_message", onModemMessage)
        end
    end)
    if not success then print("Error in onOverlayEvent: " .. error) end
end

local function onHighlightActual(xyz)
    local success, error = pcall(function()
        for k, v in ipairs(highlighters) do
            if v.x == xyz.x and v.y == xyz.y and v.z == xyz.z then
                os.sleep(0)
                v.remove()
                table.remove(highlighters, k)
                return
            end
        end
        local beacon = widgetsAreUs.beacon(xyz.x, xyz.y, xyz.z)
        beacon.beacon.setColor(0, 1, 1)
        table.insert(highlighters, beacon)
        os.sleep(0)
    end)
    if not success then print("Error in onHighlightActual: " .. error) end
end

local function onHighlight(_, xyz)
    local success, error = pcall(onHighlightActual, xyz)
    if not success then print("Error in onHighlight: " .. error) end
    os.sleep(0)
end

onModemMessage = function(_, _, _, port, _, message1)
    local success, error = pcall(function()
        if port == 202 then
            local success_message, error_message = pcall(hud.modemMessageHandler, port, message1)
            if not success_message then print("Error in hud.modemMessageHandler: " .. error_message) end
        end
        os.sleep(0)
    end)
    if not success then print("Error in onModemMessage: " .. error) end
end

local function onHudReset()
    local success, error = pcall(function()
        event.ignore("modem_message", onModemMessage)
        event.ignore("highlight", onHighlight)	
        event.ignore("overlay_opened", onOverlayEvent)
        event.ignore("overlay_closed", onOverlayEvent)
        event.cancel(overlayUpdateEvent)

        hud.show()
        overlay.hide()
        hud.init()

        event.listen("modem_message", onModemMessage)
        event.listen("highlight", onHighlight)
        event.listen("overlay_opened", onOverlayEvent)
        event.listen("overlay_closed", onOverlayEvent)
    end)
    if not success then print("Error in onHudReset: " .. error) end
end

-------------------------------------------------------
---event listeners

event.listen("reset_hud", onHudReset)
event.listen("highlight", onHighlight)
event.listen("modem_message", onModemMessage)
event.listen("overlay_opened", onOverlayEvent)
event.listen("overlay_closed", onOverlayEvent)

-------------------------------------------------------
---Break me to play games on the side

while true do
    os.sleep(5)
end