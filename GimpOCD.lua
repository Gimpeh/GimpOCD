-- GimpOCD (Overseeing, Controlling, Directing) main v0.0.2
local event = require("event")
local overlay = require("overlay")
local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local hud = require("hud")
local sleeps = require("sleepDurations")
local machinesManager = require("machinesManager")
local c = require("gimp_colors")
local s = require("serialization")

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end

-----------------------------------------
-- Start up

component.modem.open(202)
component.glasses.removeAll()
print("modem port 202 not opened!!! re-enable when ready")

gimp_globals = {}
gimp_globals.initializing_lock = false
gimp_globals.configuringHUD_lock = false
gimp_globals.glasses_controller_coords = {x = 5.5, y = 46, z = 13.5}
gimp_globals.alert_DC = false

overlay.init()
hud.init()

print("GimpOCD - Line 12: Components initialized and modem port 202 opened.")
print("") -- Blank line for readability

-----------------------------------------
--- Forward declarations

local overlayUpdateEvent
local highlighters = {}
local onModemMessage

-----------------------------------------
--- Event handlers

local function updateOverlay()
    print("GimpOCD - Line 24: updateOverlay called")
    os.sleep(0)
    --[[local success, error = pcall(overlay.update)
    if not success then
        print("GimpOCD - Error in updateOverlay: " .. tostring(error))
    end
    os.sleep(0)]]
    event.push("update_overlay")
    print("") -- Blank line after function execution
end

local function handleClick(_, _, _, x, y, button)
    print("GimpOCD - Line 34: handleClick called with x =", tostring(x), "y =", tostring(y), "button =", tostring(button))
    if gimp_globals.initializing_lock then
        return
    end
    local success, error = pcall(overlay.onClick, x, y, button)
    if not success then
        print("GimpOCD - Error in handleClick: " .. tostring(error))
    end
    os.sleep(sleeps.yield)
    print("") -- Blank line after function execution
end

local function onOverlayEvent(eventType, ...)
    print("GimpOCD - Line 44: onOverlayEvent called with eventType =", tostring(eventType))
    local success, error = pcall(function()
        if eventType == "overlay_opened" then
            print("GimpOCD - Line 47: overlay_opened event detected")
            event.ignore("modem_message", onModemMessage)
            event.listen("hud_click", handleClick)
            hud.hide()
            overlay.show()
            os.sleep(sleeps.yield)
            overlay.update()
            os.sleep(sleeps.yield)
            overlayUpdateEvent = event.timer(2500, updateOverlay, math.huge)
        elseif eventType == "overlay_closed" then
            print("GimpOCD - Line 55: overlay_closed event detected")
            event.ignore("hud_click", handleClick)
            os.sleep(sleeps.yield)
            overlay.hide()
            hud.show()
            event.cancel(overlayUpdateEvent)
            os.sleep(sleeps.yield)
            event.listen("modem_message", onModemMessage)
        end
    end)
    if not success then
        print("GimpOCD - Error in onOverlayEvent: " .. tostring(error))
    end
    print("") -- Blank line after function execution
end

local function onHighlightActual(xyz)
    print("GimpOCD - Line 67: onHighlightActual called with xyz =", s.serialize(xyz))
    local success, error = pcall(function()
        for k, v in ipairs(highlighters) do
            if v.x == xyz.x and v.y == xyz.y and v.z == xyz.z then
                print("GimpOCD - Line 71: Found existing beacon at xyz, removing it")
                os.sleep(sleeps.yield)
                v.remove()
                table.remove(highlighters, k)
                print("") -- Blank line after removal
                return
            end
        end
        local beacon = widgetsAreUs.beacon(xyz.x, xyz.y, xyz.z, {0, 1, 1})
        table.insert(highlighters, beacon)
        print("GimpOCD - Line 78: New beacon created and added to highlighters.")
        os.sleep(sleeps.yield)
    end)
    if not success then
        print("GimpOCD - Error in onHighlightActual: " .. tostring(error))
    end
    print("") -- Blank line after function execution
end

local function onHighlight(_, xyz)
    print("GimpOCD - Line 86: onHighlight called with xyz =", tostring(xyz))
    local success, error = pcall(onHighlightActual, xyz)
    if not success then
        print("GimpOCD - Error in onHighlight: " .. tostring(error))
    end
    os.sleep(sleeps.yield)
    print("") -- Blank line after function execution
end

onModemMessage = function(_, _, _, port, _, message1)
    local success, error = pcall(function()
        if port == 202 then
            local success_message, error_message = pcall(hud.modemMessageHandler, port, message1)
            if not success_message then
                print("GimpOCD - Error in hud.modemMessageHandler: " .. tostring(error_message))
            end
        end
        os.sleep(sleeps.yield)
    end)
    if not success then
        print("GimpOCD - Error in onModemMessage: " .. tostring(error))
    end
end

local function onHudReset()
    print("GimpOCD - Line 109: onHudReset called")
        event.ignore("modem_message", onModemMessage)
        event.ignore("highlight", onHighlight)
        event.ignore("overlay_opened", onOverlayEvent)
        event.ignore("overlay_closed", onOverlayEvent)
        event.cancel(overlayUpdateEvent)

        print("GimpOCD - Line 116: HUD and Overlay reset")
        hud.show()
        overlay.hide()
        while gimp_globals.initializing_lock do
            os.sleep(10)
        end
        hud.init()
        while gimp_globals.configuringHUD_lock do
            os.sleep(10)
        end

        event.listen("modem_message", onModemMessage)
        event.listen("highlight", onHighlight)
        event.listen("overlay_opened", onOverlayEvent)
        event.listen("overlay_closed", onOverlayEvent)
    print("") -- Blank line after function execution
end

local function on_components_changed(addedOrRemoved, _, componentType)
    if gimp_globals.alert_DC then
        widgetsAreUs.alertMessage(c.alertMessage, componentType .. " : " .. addedOrRemoved, 5)
    end
    if componentType == "gt_machine" then
        machinesManager.reproxy()
    end
end

-------------------------------------------------------
--- Event listeners

event.listen("component_removed", on_components_changed)
event.listen("component_added", on_components_changed)
event.listen("reset_hud", onHudReset)
event.listen("highlight", onHighlight)
event.listen("modem_message", onModemMessage)
event.listen("overlay_opened", onOverlayEvent)
event.listen("overlay_closed", onOverlayEvent)

print("GimpOCD - Event listeners registered.")
local backend = require("backend")
print("") -- Blank line for readability

-------------------------------------------------------
--- Break me to play games on the side

while true do
    os.sleep(sleeps.sixty)
end