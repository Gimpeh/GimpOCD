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
    print("hud - Line 15: Initializing HUD.")
    local success, err = pcall(function()
        table.insert(initMessages, widgetsAreUs.initText(200, 162, "Left or Right click to set location"))
        table.insert(initMessages, widgetsAreUs.initText(250, 212, "Middle click to accept"))
        hud.elements.battery = metricsDisplays.battery.create(1, 1)

        while true do
            local eventType, _, _, x, y, button = event.pull(nil, "hud_click")
            if eventType == "hud_click" then
                if button == 0 then  -- Left click
                    print("hud - Line 25: Left click detected, setting battery location.")
                    if hud.elements.battery then
                        hud.elements.battery.remove()
                        os.sleep(0.1)
                        hud.elements.battery = nil
                    end
                    os.sleep(1)
                    hud.elements.battery = metricsDisplays.battery.create(x, y)
                    os.sleep(1)
                elseif button == 1 then  -- Right click
                    print("hud - Line 34: Right click detected, adjusting battery location.")
                    if hud.elements.battery then
                        hud.elements.battery.remove()
                        os.sleep(0.1)
                        hud.elements.battery = nil
                    end
                    os.sleep(1)
                    local xModified = x - 203
                    local yModified = y - 183
                    hud.elements.battery = metricsDisplays.battery.create(xModified, yModified)
                elseif button == 2 then  -- Middle click
                    print("hud - Line 44: Middle click detected, finalizing battery location.")
                    break
                end
            end
            os.sleep(0.3)
        end

        print("hud - Line 51: Hiding HUD and removing initialization messages.")
        hud.hide()
        for _, v in ipairs(initMessages) do
            v.remove()
        end
        initMessages = nil
        os.sleep(100)
    end)
    if not success then
        print("hud - Line 59: Error in hud.init: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function hud.hide()
    print("hud - Line 65: Hiding HUD elements.")
    local success, err = pcall(function()
        hud.elements.battery.setVisible(false)
    end)
    if not success then
        print("hud - Line 69: Error in hud.hide: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function hud.show()
    print("hud - Line 74: Showing HUD elements.")
    local success, err = pcall(function()
        hud.elements.battery.setVisible(true)
    end)
    if not success then
        print("hud - Line 78: Error in hud.show: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function hud.modemMessageHandler(port, message)
    print("hud - Line 83: Handling modem message on port", tostring(port))
    local success, err = pcall(function()
        if port == 202 then
            print("hud - Line 86: Port 202 detected, processing message.")
            local unserializedTable = s.unserialize(message)
            hud.elements.battery.update(unserializedTable)
        end
    end)
    if not success then
        print("hud - Line 91: Error in hud.modemMessageHandler: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

return hud