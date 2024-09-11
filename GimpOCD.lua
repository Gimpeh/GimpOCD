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
local gimpHelper = require("gimpHelper")

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

local auto_init_mutex_unlock_timer

local function gimp_globals_auto_init_mutex_unlock()
    print("GimpOCD - Line 12: gimp_globals_auto_init_mutex_unlock called")
    gimp_globals.initializing_lock = false
    print("") -- Blank line after function execution
end

local gimp_globals_meta_table 

gimp_globals = setmetatable({}, gimp_globals_meta_table)
gimp_globals.initializing_lock = false
gimp_globals.configuringHUD_lock = false
gimp_globals.proxy_lock = false
gimp_globals.glasses_controller_coords = {x = 5.5, y = 46, z = 13.5}
gimp_globals.alert_DC = false


local gimp_globals_meta_table = {
    __newindex = function(t, key, value)
        if key == "initializing_lock" then
            if value and t.initializing_lock then
                print("GimpOCD - Line 20: Initializing lock set to true while already true")
                event.cancel(auto_init_mutex_unlock_timer)
                event.timer(sleeps.thirty, gimp_globals_auto_init_mutex_unlock, 1)
            elseif value and not t.initializing_lock then
                print("GimpOCD - Line 24: Initializing lock set to true")
                rawset(t, key, value)
                auto_init_mutex_unlock_timer = event.timer(sleeps.thirty, gimp_globals_auto_init_mutex_unlock, 1)
            elseif not value and t.initializing_lock then
                print("GimpOCD - Line 27: Initializing lock set to false")
                event.cancel(auto_init_mutex_unlock_timer)
                rawset(t, key, value)
            elseif not value and not t.initializing_lock then
                while true do
                    print("GimpOCD - Line 31: Initializing lock set to false while already false")
                    os.sleep(sleeps.yield)
                end
            end
        end
    end
}

overlay.init()
hud.init()

print("GimpOCD - Line 12: Components initialized and modem port 202 opened.")
print("") -- Blank line for readability

-----------------------------------------
--- Forward declarations

local overlayUpdateEvent
local highlighters = {}
local onModemMessage
local onOverlayEvent

-----------------------------------------
--- Event handlers

local function updateOverlay()
    print("GimpOCD - Line 24: updateOverlay called")
    os.sleep(sleeps.yield)
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

local function overlayRedoClosed()
    onOverlayEvent("overlay_closed")
end

local function overlayRedoOpened()
    onOverlayEvent("overlay_opened")
end

onOverlayEvent = function(eventType, ...)
    print("GimpOCD - Line 44: onOverlayEvent called with eventType =", tostring(eventType))
    local success, error = pcall(function()
        if eventType == "overlay_opened" then
            if gimp_globals.initializing_lock then
                event.timer(sleeps.ten/2, overlayRedoOpened, 1)
                return
            end
            print("GimpOCD - Line 47: overlay_opened event detected")
            event.ignore("modem_message", onModemMessage)
            event.listen("hud_click", handleClick)
            hud.hide()
            overlay.show()
            os.sleep(sleeps.yield)
            overlay.update()
            os.sleep(sleeps.yield)
            overlayUpdateEvent = event.timer(sleeps.thirty / 2, updateOverlay, math.huge)
        elseif eventType == "overlay_closed" then
            if gimp_globals.initializing_lock then
                event.timer(sleeps.ten/2, overlayRedoClosed, 1)
                return
            end
            print("GimpOCD - Line 55: overlay_closed event detected")
            event.ignore("hud_click", handleClick)
            overlay.hide()
            hud.show()
            event.cancel(overlayUpdateEvent)
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
        for k, v in pairs(highlighters) do
            print("GimpOCD - Line 70: Checking existing highlighters for match")
            local hXyz = {}
            hXyz.x, hXyz.y, hXyz.z = v.get3DPos()
            if hXyz.x == xyz.x and hXyz.y == xyz.y and hXyz.z == xyz.z then
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
    local xyzMod = {}
    xyzMod = gimpHelper.calc_modified_coords(xyz, gimp_globals.glasses_controller_coords)
    local success, error = pcall(onHighlightActual, xyzMod)
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
        os.sleep(sleeps.one)
        if gimp_globals.initializing_lock then
            event.timer(sleeps.ten/2, onHudReset, 1)
            return
        end
        gimp_globals.initializing_lock = true
        print("GimpOCD - Line 116: HUD and Overlay reset")
        hud.show()
        overlay.hide()

        hud.init()
        gimp_globals.initializing_lock = false
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
        if gimp_globals.proxy_lock then
            return
        end
        gimp_globals.proxy_lock = true
        gimp_globals.initializing_lock = true
        machinesManager.reproxy()
        gimp_globals.initializing_lock = false
        gimp_globals.proxy_lock = false
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
event.push("updated_configs")
-------------------------------------------------------
--- Break me to play games on the side

while true do
    os.sleep(sleeps.sixty)
end