local metricsDisplays = require("metricsDisplays")
local component = require("component")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local widgetsAreUs = require("widgetsAreUs")
local event = require("event")
local c = require("gimp_colors")
local sleeps = require("sleepDurations")

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end

--------------------------------------------------
---Variables and Forward Declarations for Module

local has_been_sorted = false -- Flag to indicate if the proxies have been sorted, or needs resorting
local active_group_name = nil -- Flag to indicate the name of the active group, I dont think this is necessary anymore

local machinesManager = {}
-- This table holds groups functions, such as init, and the groupings table for arrays of proxies
machinesManager.groups = {}
machinesManager.groups.groupings = {}
--[[ This table will be populated with the following structure:  
machinesManager.groups.groupings = {
    ["group_name_1"] = {proxy1, proxy2, proxy3}, 
    ["group_name_2"] = {proxy4, proxy5, proxy6},
    etc
    }
According to groups.config file
]]
machinesManager.display = nil -- This will be a PagedWindow object for displaying elements
machinesManager.buttons = {} -- This table will hold buttons for the displayed elements
machinesManager.individuals = {} -- probably doesnt need to be a table as it only holds one function and no data

local saveData -- Function to save new names for machines

--------------------------------------------------
---Proxies and Sorting

local function getProxies()
    print("machinesManager - Line 31: Getting component proxies.")
    local gt_machine_proxies = {}
    local components_to_proxy = component.list("gt_machine")
    for address, _ in pairs(components_to_proxy) do
        print("machinesManager - Line 35: Adding proxy for component:", tostring(address))
        table.insert(gt_machine_proxies, component.proxy(address))
        os.sleep(sleeps.yield)
    end
    print("machinesManager - Line 39: Total proxies retrieved:", tostring(#gt_machine_proxies))
    return gt_machine_proxies
end
  
local function sortProxies()
    print("machinesManager - Line 26: Sorting component proxies.")
    local success, err = pcall(function()
        local unsorted_gt_machines = getProxies()
        os.sleep(sleeps.yield)  -- Yield execution after getting proxies
  
        local config = gimpHelper.loadTable("/home/programData/groups.config")
        print("machinesManager - Line 30: Loaded configuration data:", tostring(config))
  
        local groupname
        machinesManager.groups.groupings = {}
        for e = #unsorted_gt_machines, 1, -1 do
        
            local proxies = {}
            for k, v in ipairs(config) do
                print("machinesManager - Line 34: Processing group:", tostring(v.name))
                groupname = v.name
  
            
                local i = unsorted_gt_machines[e]
                local x, y, z = i.getCoordinates()
                print("machinesManager - Line 39: Checking proxy coordinates: (", tostring(x), ",", tostring(y), ",", tostring(z), ")")
          
                os.sleep(sleeps.yield)  -- Yield execution within inner loop
                if v.start.x < x and x < v.ending.x and v.start.z < z and z < v.ending.z then
                    print("machinesManager - Line 43: Proxy in range for group:", groupname)
                    table.insert(proxies, i)
                    table.remove(unsorted_gt_machines, e)
                end
            end
  
            print("machinesManager - Line 47: Total proxies for group", groupname, ":", tostring(#proxies))
            machinesManager.groups.groupings[groupname] = proxies
        end
  
        has_been_sorted = true
    end)
  
    if not success then
        print("machinesManager - Line 55: Error in sortProxies: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

--------------------------------------------------
---Initialization (occurs whenever the machines tab is clicked in overlay)

function machinesManager.init()
    print("machinesManager - Line 154: Initializing machinesManager.")
    local success, err = pcall(function()
        machinesManager.buttons.left = widgetsAreUs.symbolBox(10, 225, "<", c.navbutton)
        machinesManager.buttons.right = widgetsAreUs.symbolBox(750, 225, ">", c.navbutton)
        machinesManager.background = widgetsAreUs.createBox(70, 70, 640, 430, c.background, 0.8)
        
        machinesManager.groups.init()
    end)
  
    if not success then
        print("machinesManager - Line 162: Error in machinesManager.init: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function machinesManager.groups.init()
    print("machinesManager - Line 61: Initializing groups.")
    local success, err = pcall(function()
        if not has_been_sorted then
            sortProxies()
        end
  
        local args = {}
        local args2 = {}
        for group_name, array_of_proxies in pairs(machinesManager.groups.groupings) do
            print("machinesManager - Line 69: Adding group", tostring(group_name))
            table.insert(args, group_name)
            table.insert(args2, array_of_proxies)
        end
  
        machinesManager.display = PagedWindow.new(args2, 107, 75, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 15, metricsDisplays.machineGroups.createElement, args)
        machinesManager.display:displayItems()
        active = "groups"

        --below might need to be removed, as updating should be done consistently in overlay.onClick instead of in individual modules for initial update of UI elements
        --event.push("update_overlay")
    end)
  
    if not success then
        print("machinesManager - Line 80: Error in machinesManager.groups.init: " .. tostring(err))
    end
    print("Done initializing groups.")
    print("") -- Blank line for readability
end

--------------------------------------------------
--- Sub-page initializing (occurs whenever a group is right clicked)

function machinesManager.individuals.init(machinesTable, active_group)
    print("machinesManager - Line 99: Initializing individuals with header =", tostring(active_group))

    gimp_globals.initializing_lock = true
    print("machinesManager - Line 109: Initializing lock enabled in individuals.init")
    local success, err = pcall(function()
        active_group_name = active_group
        --Below should be swapped out for symbolBox or something so that the boxes function can be indicated to users
        machinesManager.buttons.back = widgetsAreUs.createBox(720, 75, 50, 25, c.navbutton, 0.7)
        
        --clear displayed items from groups, which is being navigated away from
        machinesManager.display:clearDisplayedItems()
        machinesManager.display = nil

        --initialize the display for the machines in the selected group
        machinesManager.display = PagedWindow.new(machinesTable, 85, 34, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 7, metricsDisplays.machine.create)
        machinesManager.display:displayItems()
        
        -- Dont think this is necessary anymore
        --individualHeader = header
  
        -- Set the names of the displayed items to their default names returned by proxy.getName()
        for k, v in ipairs(machinesManager.display.currentlyDisplayed) do
            print("machinesManager - Line 115: Setting name for displayed item.")
            v.setName()
        end

        -- Check if there are any saved names for the machines in the group
        local savedNames = gimpHelper.loadTable("/home/programData/" .. active_group_name .. ".data")
        if not savedNames then
            savedNames = {}
        end
        --set the names of the displayed items to the saved names if they exist
        for k, v in pairs(savedNames) do
            for j, i in pairs(machinesManager.display.currentlyDisplayed) do
                local xyzCheck = {}
                xyzCheck.x, xyzCheck.y, xyzCheck.z = i.getCoords()
                if v.xyz.x == xyzCheck.x and v.xyz.y == xyzCheck.y and v.xyz.z == xyzCheck.z then
                    print("machinesManager - Line 128: Matching saved name found, setting name.")
                    i.setName(v.newName)
                    break
                end
            end
        end
    end)
  
    if not success then
      print("machinesManager - Line 134: Error in machinesManager.individuals.init: " .. tostring(err))
    end

    print("machinesManager - Line 113: Initializing lock disabled.")
    gimp_globals.initializing_lock = false
    event.push("update_overlay")
    print("Done initializing individuals.") 
    print("") -- Blank line for readability
end

--------------------------------------------------
--- UI functions

function machinesManager.onClick(x, y, button)
    print("machinesManager - Line 143: Processing click at (", tostring(x), ",", tostring(y), ")")
    local success, err = pcall(function()
        if machinesManager.buttons.left then
            if widgetsAreUs.isPointInBox(x, y, machinesManager.buttons.left.box) then
                print("machinesManager - Line 147: Clicked on left button.")
                machinesManager.display:previousPage()
                return
            end
        end

        if machinesManager.buttons.right then
            if widgetsAreUs.isPointInBox(x, y, machinesManager.buttons.right.box) then
                print("machinesManager - Line 153: Clicked on right button.")
                machinesManager.display:nextPage()
                return
            end
        end

        if machinesManager.buttons.back then
            if widgetsAreUs.isPointInBox(x, y, machinesManager.buttons.back) then
                print("machinesManager - Line 159: Clicked on back button.")
                machinesManager.remove()
                machinesManager.init()
                return
            end
        end

        for k, v in ipairs(machinesManager.display.currentlyDisplayed) do
            if widgetsAreUs.isPointInBox(x, y, v.background) then
                print("machinesManager - Line 167: Clicked on a displayed item.")
                v.onClick(button)
                return
            end
        end
    end)

    if not success then
        print("machinesManager - Line 174: Error in machinesManager.onClick: " .. tostring(err))
    end
    print("onClick event processed.")
    print("") -- Blank line for readability
end

function machinesManager.remove()
    print("machinesManager - Line 180: Removing machinesManager display.")
    local success, err = pcall(function()
        machinesManager.display:clearDisplayedItems()
        machinesManager.display = nil
        for k, v in pairs(machinesManager.buttons) do
            v.remove()
        end
        machinesManager.background.remove()
    end)
    print("machinesManager - Line 187: Removed machinesManager display.")
end

function machinesManager.update()
    print("machinesManager - Line 183: Updating machinesManager display.")
    local success, err = pcall(function()
        for k, v in ipairs(machinesManager.display.currentlyDisplayed) do
            v.update()
            os.sleep(sleeps.yield)
        end
    end)
    print("machinesManager - Line 189: Updated machinesManager display.")
end

function machinesManager.setVisible(visible)
    print("machinesManager - Line 230: Setting visibility to", tostring(visible))
    local success, err = pcall(function()
        machinesManager.background.setVisible(visible)
        
        if machinesManager.buttons.back then
            machinesManager.buttons.back.setVisible(visible)
        end

        for k, v in ipairs(machinesManager.display.currentlyDisplayed) do
            v.setVisible(visible)
        end

        for k, v in pairs(machinesManager.buttons) do
            v.setVisible(visible)
        end
    end)
end

--------------------------------------------------
--- Save New Names for Machines

saveData = function(_, newName, xyz)
    print("machinesManager - Line 249: Saving data for machine with newName =", tostring(newName))
    local success, err = pcall(function()
        local tbl = gimpHelper.loadTable("/home/programData/" .. active_group_name .. ".data") or {}
        if not tbl then
            tbl = {}
        end
  
        local data = {}
        local str = newName:gsub("^[\0-\31\127]+", "")
        data.newName = str
        data.xyz = {}
        data.xyz.x = xyz.x
        data.xyz.y = xyz.y
        data.xyz.z = xyz.z
        data.groupName = active_group_name
  
        for k, v in ipairs(tbl) do
            if v.xyz.x == xyz.x and v.xyz.y == xyz.y and v.xyz.z == xyz.z then
            table.remove(tbl, k)
            end
        end
  
        if data.newName and data.xyz and data.xyz.z and data.groupName then
            table.insert(tbl, data)
            gimpHelper.saveTable(tbl, "/home/programData/" .. active_group_name .. ".data")
            event.push("machine_named", data, data.xyz)
            print("machinesManager - Line 273: Data saved successfully.")
        else
            print("machinesManager - Line 275: Error in saveData: Data is incomplete.")
        end
    end)
  
    if not success then
        print("machinesManager - Line 279: Error in saveData: " .. tostring(err))
    end
    print("machinesManager - Finished Saving Data")
    print("") -- Blank line for readability
end

function machinesManager.reproxy(componentType)
        sortProxies()
end

--------------------------------------------------
--- Event Listeners

event.listen("nameSet", saveData)

--------------------------------------------------
--- Return Module

return machinesManager