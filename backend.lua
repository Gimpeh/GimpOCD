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
    local configs = gimpHelper.loadTable("/home/programData/generalConfig.data")
    if not configs and configs.highlightDisabled then
        return
    end
    local config = configs.highlightDisabled
    if config == "false" then
        return
    end
    while true do
        for k, v in ipairs(table_of_highlighers) do
            v.remove()
            table.remove(table_of_highlighers, table_of_highlighers[k])
        end
        for group_name, proxy_table in pairs(machinesManager.groups.groupings) do
            local group_of_machines = machinesManager.groups.groupings[group_name]
            for index, machine in ipairs(group_of_machines) do
                os.sleep(sleeps.yield)
                if not machine.isWorkAllowed() then
                    local x, y, z = machine.getCoordinates()
                    local xyzMod = gimpHelper.calc_modified_coords({x = x, y = y, z = z}, gimp_globals.glasses_controller_coords)
                    table.insert(table_of_highlighers, widgetsAreUs.beacon(xyzMod.x, xyzMod.y, xyzMod.z, c.alertnotification))
                end
            end
        end
        for k, v in ipairs(table_of_highlighers) do
            v.setScale(2.5)
        end
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
    local function hasProblems(sensor_info)
		for _, line in ipairs(sensor_info) do
            os.sleep(sleeps.yield)
			if line:match("Problems: §c%d+§r") then
				local problems = tonumber(line:match("Problems: §c(%d+)§r"))
				if problems > 0 then
					return true
				end
			end
		end
		return false
	end

    local configs = gimpHelper.loadTable("/home/programData/generalConfig.data")
    if configs and configs.alertDisconnectedReconnected then
        if configs.alertDisconnectedReconnected == "true" then
            gimp_globals.alert_DC = true
        else
            gimp_globals.alert_DC = false
        end
    end

    if not configs or configs.highlightMaintenance then
        return
    end
    local config = configs.highlightMaintenance
    if config == "false" then
        return
    end

    while true do
        for k, v in pairs(maintenance_problems) do
            v.remove()
            maintenance_problems[k] = nil
        end
        os.sleep(sleeps.yield)
        for group_name, proxy_table in pairs(machinesManager.groups.groupings) do
            for _, machine in ipairs(proxy_table) do
                os.sleep(sleeps.yield)
                local sensor_info = machine.getSensorInformation()
                if hasProblems(sensor_info) then
                    local x, y, z = machine.getCoordinates()
                    local xyzMod = gimpHelper.calc_modified_coords({x = x, y = y, z = z}, gimp_globals.glasses_controller_coords)
                    table.insert(maintenance_problems, widgetsAreUs.beacon(xyzMod.x, xyzMod.y, xyzMod.z, c.dangerbutton))
                    os.sleep(sleeps.yield)
                end
            end
        end
        os.sleep(sleeps.thirty)
    end
end

local maintenance_thread

local function maintenance_thread_init()
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
        os.sleep(1)
    end
end

event.listen("updated_configs", updated_configs_handler)
event.listen("alert_notification", notifier)
event.listen("update_overlay", onUpdate)

threadManager = thread.create(manageThreads)
threadManager:resume()

return backend