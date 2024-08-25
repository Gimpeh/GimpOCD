local configurations = require("configurations")
local overlay = require("overlay")
local hud = require("hud")
local itemWindow = require("itemWindow")
local machinesManager = require("machinesManager")
local event = require("event")

local thread = require("thread")

local threadManager
local updateThread = nil

local function manageThreads()
    print("backend - line 21: manageThreads called")
    os.sleep(0)
    if (gimp_globals.configuringHUD_lock or gimp_globals.initializing_lock) and updateThread and not updateThread:status() == "dead" then
        print("backend - line 24: Killing updateThread due to existing lock", tostring(gimp_globals.configuringHUD_lock), tostring(gimp_globals.initializing_lock))
        updateThread:kill()
    end
    os.sleep(0)
    return manageThreads()
end

local function update()
    while true do
        print("backend - line 33: update called")
        os.sleep(0)
        local success, error = pcall(overlay.update)
        if not success then
            print("backend - line 37: overlay.update call failed with error : " .. tostring(error))
        end
    end
end

local function onUpdate()
    print("backend - line 43: onUpdate called")
    if updateThread and not updateThread:status() == "dead" then
        print("backend - line 45: Killing updateThread due to it existing")
        updateThread:kill()
    end
    print("backend - line 48: Creating new updateThread")
    updateThread = thread.create(update)
    print("backend - line 50: waiting for locks to clear")
    while gimp_globals.initializing_lock or gimp_globals.configuringHUD_lock do
        os.sleep(20)
    end
    print("backend - line 53: Starting updateThread")
    updateThread:start()
end

event.listen("update_overlay", onUpdate)

threadManager = thread.create(manageThreads)
threadManager:start()

