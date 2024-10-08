local configurations = require("configurations")
local overlay = require("overlay")
local hud = require("hud")
local itemWindow = require("itemWindow")
local machinesManager = require("machinesManager")
local event = require("event")
local thread = require("thread")
local gimpHelper = require("gimpHelper")
local s = require("serialization")
local component = require("component")
local levelMaintainer = require("levelMaintainer")
local sleeps = require("sleepDurations")
local widgetsAreUs = require("widgetsAreUs")
local c = require("gimp_colors")

local me = component.me_interface

local backend = {}

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end


----------------------------------------------
--- Update Thread Functions


local threadManager
local updateThread = nil

local function manageThreads()
    print("backend - line 21: manageThreads called")
    os.sleep(sleeps.ten)
    if (gimp_globals.configuringHUD_lock or gimp_globals.initializing_lock) and updateThread and updateThread:status() ~= "dead" then
        print("backend - line 24: Killing updateThread due to existing lock")
        updateThread:kill()
    end
    os.sleep(sleeps.ten)
    return manageThreads()
end

local function update()
    print("backend - line 33: update called")
    os.sleep(sleeps.yield)
    local success, error = pcall(overlay.update)
    if not success then
        print("backend - line 37: overlay.update call failed with error : " .. tostring(error))
    end
end

local function onUpdate()
    print("backend - line 43: onUpdate called")
    if updateThread and updateThread:status() ~= "dead" then
        print("backend - line 45: Killing updateThread due to it existing")
        updateThread:kill()
    end
    print("backend - line 48: Creating new updateThread")
    updateThread = thread.create(update)
    print("backend - line 50: waiting for locks to clear")
    while gimp_globals.initializing_lock or gimp_globals.configuringHUD_lock do
        print("backend - line 52: Still waiting for locks to clear")
        os.sleep(sleeps.one)
    end
    print("backend - line 53: Starting updateThread")
    updateThread:resume()
end

local function notifier(_, notification_subject, ...)
    local notification_message
    if notification_subject == "alertResources" then
        local first = select(1, ...)
        notification_message = widgetsAreUs.alert_notification(c.alertnotification, first  .. " Can't be crafted!", 700)
        return notification_message
    elseif notification_subject == "alertStalled" then
        local first = select(1, ...)
        if first then
            notification_message = widgetsAreUs.alert_notification(c.alertnotification, first  .. " Stalled!", 500)
        --[[else
            notification_message = widgetsAreUs.alert_notification(c.alertnotification, "A recipe has stalled!", 500)]]
        return notification_message
        end
    end
end

local table_of_highlighers = {}

local function highlight_disabled_machines()
    print("backend - line 77: highlight_disabled_machines initiated")
    local configs = gimpHelper.loadTable("/home/programData/generalConfig.data")
    print("backend - line 79: configs loaded")
    if not configs or not configs[1] or not configs[1].highlightDisabled then
        print("backend - line 81: no configs found, returning")
        return
    end
    local config = configs[1].highlightDisabled
    if config == "false" then
        print("backend - line 85: config set to false, returning")
        return
    end
    while true do
        print("backend - line 89: starting highlight loop")
        for k, v in pairs(table_of_highlighers) do
            print("backend - line 91: removing beacon")
            v.remove()
            table_of_highlighers[k] = nil
        end
        for group_name, proxy_table in pairs(machinesManager.groups.groupings) do
            print("backend - line 95: checking group", group_name)
            os.sleep(sleeps.yield)
            local group_of_machines = machinesManager.groups.groupings[group_name]
            for index, machine in ipairs(group_of_machines) do
                print("backend - line 98: checking machine", machine.getName())
                os.sleep(sleeps.yield)
                if not machine.isWorkAllowed() then
                    print("backend - line 101: machine not allowed to work")
                    local x, y, z = machine.getCoordinates()
                    os.sleep(sleeps.yield)
                    local xyzMod = gimpHelper.calc_modified_coords({x = x, y = y, z = z}, gimp_globals.glasses_controller_coords)
                    table.insert(table_of_highlighers, widgetsAreUs.beacon(xyzMod.x, xyzMod.y, xyzMod.z, c.alertnotification))
                end
            end
        end
        print("backend - line 107: about to set highlighter scale")
        for k, v in ipairs(table_of_highlighers) do
            v.setScale(2.5)
        end
        print("backend - line 111: highlighter going to sleep")
        os.sleep(sleeps.thirty)
    end
end

local highlighter_thread

local function highligher_thread_init()
    if highlighter_thread and highlighter_thread:status() ~= "dead" then
        highlighter_thread:kill()
        highlighter_thread = nil
    end
    highlighter_thread = thread.create(highlight_disabled_machines)
    highlighter_thread:detach()
    highlighter_thread:resume()
end

local maintenance_problems = {}

local function highlight_maintenance()
    print("backend - line 126: highlight_maintenance initiated")
    local function hasProblems(sensor_info)
        print("backend - line 129: checking for problems")
		for _, line in ipairs(sensor_info) do
            os.sleep(sleeps.yield)
			if line:match("Problems: §c%d+§r") then
                print("backend - line 133: problems line found")
				local problems = tonumber(line:match("Problems: §c(%d+)§r"))
				if problems > 0 then
                    print("backend - line 136: problems found")
					return true
				end
			end
		end
		return false
	end

    local configBase = gimpHelper.loadTable("/home/programData/generalConfig.data")
    if not configBase and configBase[1] then
        return
    end
    local configs = configBase[1]
    if configs and configs.alertDisconnectedReconnected then
        if configs.alertDisconnectedReconnected == "true" then
            gimp_globals.alert_DC = true
        else
            gimp_globals.alert_DC = false
        end
    end

    print("backend - line 151: checking configs")
    if not configs or not configs.maintenanceBeacons then
        print("backend - line 153: no configs found")
        return
    end
    local config = configs.maintenanceBeacons
    if config == "false" then
        print("backend - line 157: maintenance beacon config set to false")
        return
    end

    while true do
        print("backend - line 162: starting maintenance loop")
        for k, v in pairs(maintenance_problems) do
            print("backend - line 164: removing maintenance beacon")
            v.remove()
            maintenance_problems[k] = nil
        end
        print("backend - line 167: done removing maintenance beacons")
        os.sleep(sleeps.yield)
        for group_name, proxy_table in pairs(machinesManager.groups.groupings) do
            print("backend - line 170: checking group", group_name)
            for _, machine in ipairs(proxy_table) do
                print("backend - line 172: checking machine", machine.getName())
                os.sleep(sleeps.yield)
                local sensor_info = machine.getSensorInformation()
                print("backend - line 175: sensor info retrieved")
                if hasProblems(sensor_info) then
                    print("backend - line 177: problems found")
                    local x, y, z = machine.getCoordinates()
                    print("backend - line 179: machine coords", x, y, z)
                    local xyzMod = gimpHelper.calc_modified_coords({x = x, y = y, z = z}, gimp_globals.glasses_controller_coords)
                    table.insert(maintenance_problems, widgetsAreUs.beacon(xyzMod.x, xyzMod.y, xyzMod.z, c.dangerbutton))
                    os.sleep(sleeps.yield)
                    print("backend - line 183: beacon added")
                end
            end
        end
        print("backend - line 186: maintenance going to sleep")
        os.sleep(sleeps.thirty)
        print("backend - line 188: maintenance waking up")
    end
end

local maintenance_thread

local function maintenance_thread_init()
    if maintenance_problems then
        for k, v in pairs(maintenance_problems) do
            v.remove()
            maintenance_problems[k] = nil
        end
    end
    if maintenance_thread and maintenance_thread:status() ~= "dead" then
        maintenance_thread:kill()
        maintenance_thread = nil
    end
    maintenance_thread = thread.create(highlight_maintenance)
    maintenance_thread:detach()
    maintenance_thread:resume()
end

local function updated_configs_handler()
    highligher_thread_init()
    maintenance_thread_init()
    
    local configs = gimpHelper.loadTable("levelMaintainerConfig.data")
    if not configs then
        return
    end
    for i = 1, #configs do
        event.push("add_level_maint_thread", i)
        os.sleep(sleeps.yield)
    end
end

event.listen("updated_configs", updated_configs_handler)
event.listen("alert_notification", notifier)
event.listen("update_overlay", onUpdate)

threadManager = thread.create(manageThreads)
threadManager:resume()

return backend