local metricsDisplays = require("metricsDisplays")
local component = require("component")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local widgetsAreUs = require("widgetsAreUs")
local event = require("event")
local c = require("gimp_colors")

local has_been_sorted = false
local saveData
local activeIndividualPage
local individualHeader
local active = "groups"

local machinesManager = {}
machinesManager.groups = {}
machinesManager.individuals = {}

local function getProxies()
  print("machinesManager - Line 17: Getting component proxies.")
  local tbl = {}
  local theList = component.list("gt_machine")
  for k, v in pairs(theList) do
    print("machinesManager - Line 21: Adding proxy for component:", tostring(k))
    table.insert(tbl, component.proxy(k))
    os.sleep(0)  -- Yield execution to avoid high CPU usage
  end
  print("machinesManager - Line 24: Total proxies retrieved:", tostring(#tbl))
  return tbl
end

local function sortProxies()
  print("machinesManager - Line 26: Sorting component proxies.")
  local success, err = pcall(function()
    local unsorted = getProxies()
    os.sleep(0)  -- Yield execution after getting proxies

    local config = gimpHelper.loadTable("/home/programData/groups.config")
    print("machinesManager - Line 30: Loaded configuration data:", tostring(config))

    machinesManager.groups.groupings = {}
    for k, v in ipairs(config) do
      print("machinesManager - Line 34: Processing group:", tostring(v.name))
      local proxies = {}
      local groupname = v.name

      for e = #unsorted, 1, -1 do
        local i = unsorted[e]
        local x, y, z = i.getCoordinates()
        print("machinesManager - Line 39: Checking proxy coordinates: (", tostring(x), ",", tostring(y), ",", tostring(z), ")")
        
        os.sleep(0)  -- Yield execution within inner loop
        if v.start.x < x and x < v.ending.x and v.start.z < z and z < v.ending.z then
          print("machinesManager - Line 43: Proxy in range for group:", groupname)
          table.insert(proxies, i)
          table.remove(unsorted, e)
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

function machinesManager.groups.init()
  print("machinesManager - Line 61: Initializing groups.")
  local success, err = pcall(function()
    local initlock = false
    if gimp_globals.initializing_lock then
      initlock = true
    else
      gimp_globals.initializing_lock = true
      print("machinesManager - Line 79: Initializing lock enabled.")
    end
    if not has_been_sorted then
      sortProxies()
    end

    local args = {}
    local args2 = {}
    for k, v in pairs(machinesManager.groups.groupings) do
      print("machinesManager - Line 69: Adding group", tostring(k))
      table.insert(args, k)
      table.insert(args2, v)
      os.sleep(0)  -- Yield execution during initialization
    end

    machinesManager.groups.background = widgetsAreUs.createBox(70, 70, 640, 430, c.background, 0.8)
    os.sleep(0.1)  -- Short sleep to allow UI element creation
    machinesManager.groups.display = PagedWindow.new(args2, 107, 75, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 15, metricsDisplays.machineGroups.createElement, args)
    machinesManager.groups.display:displayItems()
    active = "groups"
    event.push("update_overlay")
    if not initlock then
      gimp_globals.initializing_lock = false
      print("machinesManager - Line 83: Initializing lock disabled.")
    end
  end)

  if not success then
    print("machinesManager - Line 80: Error in machinesManager.groups.init: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.groups.remove()
  print("machinesManager - Line 86: Removing groups display.")
  local success, err = pcall(function()
    machinesManager.groups.display:clearDisplayedItems()
    os.sleep(0)  -- Yield execution after clearing items

    machinesManager.groups.display = nil
    component.glasses.removeObject(machinesManager.groups.background.getID())
    machinesManager.groups.background = nil
  end)

  if not success then
    print("machinesManager - Line 93: Error in machinesManager.groups.remove: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.individuals.init(machinesTable, header)
  print("machinesManager - Line 99: Initializing individuals with header =", tostring(header))
  local initlock = false
  if gimp_globals.initializing_lock then
    initlock = true
  else
    gimp_globals.initializing_lock = true
    print("machinesManager - Line 109: Initializing lock enabled.")
  end
  local success, err = pcall(function()
    if not machinesTable then
      machinesTable = activeIndividualPage
    end
    if not header then
      header = individualHeader
    end
    os.sleep(0)  -- Yield execution before creating UI elements

    machinesManager.individuals.background = widgetsAreUs.createBox(70, 70, 640, 430, c.background, 0.7)
    machinesManager.individuals.back = widgetsAreUs.createBox(720, 75, 50, 25, c.navbutton, 0.7)
    machinesManager.individuals.display = PagedWindow.new(machinesTable, 85, 34, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 7, metricsDisplays.machine.create)
    machinesManager.individuals.display:displayItems()
    active = "individuals"
    activeIndividualPage = machinesTable
    individualHeader = header

    for k, v in pairs(machinesManager.individuals.display.currentlyDisplayed) do
      print("machinesManager - Line 115: Setting name for displayed item.")
      v.setName()
      os.sleep(0)  -- Yield execution during loop
    end

    local savedNames = gimpHelper.loadTable("/home/programData/" .. header .. ".data")
    if not savedNames then
      savedNames = {}
    end

    for k, v in pairs(savedNames) do
      for j, i in pairs(machinesManager.individuals.display.currentlyDisplayed) do
        os.sleep(0)  -- Yield execution within nested loop
        local xyzCheck = {}
        xyzCheck.x, xyzCheck.y, xyzCheck.z = i.getCoords()
        if v.xyz.x == xyzCheck.x and v.xyz.y == xyzCheck.y and v.xyz.z == xyzCheck.z then
          print("machinesManager - Line 128: Matching saved name found, setting name.")
          i.setName(v.newName)
        end
      end
    end
    if not initlock then
      gimp_globals.initializing_lock = false
      print("machinesManager - Line 113: Initializing lock disabled.")
    end
    event.push("update_overlay")
  end)

  if not success then
    print("machinesManager - Line 134: Error in machinesManager.individuals.init: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.individuals.remove()
  print("machinesManager - Line 140: Removing individuals display.")
  local success, err = pcall(function()
    machinesManager.individuals.display:clearDisplayedItems()
    os.sleep(0)  -- Yield execution after clearing items

    component.glasses.removeObject(machinesManager.individuals.background.getID())
    component.glasses.removeObject(machinesManager.individuals.back.getID())
    machinesManager.individuals.background = nil
  end)

  if not success then
    print("machinesManager - Line 148: Error in machinesManager.individuals.remove: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.init()
  print("machinesManager - Line 154: Initializing machinesManager.")
  local success, err = pcall(function()
    machinesManager.left = widgetsAreUs.symbolBox(10, 225, "<", c.navbutton)
    machinesManager.right = widgetsAreUs.symbolBox(750, 225, ">", c.navbutton)
    os.sleep(0)  -- Yield execution after creating navigation symbols

    machinesManager[active].init()
  end)

  if not success then
    print("machinesManager - Line 162: Error in machinesManager.init: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.remove()
  print("machinesManager - Line 168: Removing machinesManager.")
  local success, err = pcall(function()
    saveData()
    os.sleep(0)  -- Yield execution after saving data

    machinesManager[active].remove()
    component.glasses.removeObject(machinesManager.left.getID())
    component.glasses.removeObject(machinesManager.right.getID())
    machinesManager.left = nil
  end)

  if not success then
    print("machinesManager - Line 177: Error in machinesManager.remove: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.update()
  print("machinesManager - Line 183: Updating machinesManager display.")
  local success, err = pcall(function()
    for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
      v.update()
      os.sleep(0)  -- Yield execution during update loop
    end
  end)

  if not success then
    print("machinesManager - Line 189: Error in machinesManager.update: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.onClick(x, y, button)
  print("machinesManager - Line 195: Handling onClick event at (", tostring(x), ",", tostring(y), ") with button", tostring(button))
  local success, err = pcall(function()
    if widgetsAreUs.isPointInBox(x, y, machinesManager.left) then
      print("machinesManager - Line 199: Clicked on left navigation button.")
      machinesManager[active].display:prevPage()
      return
    elseif widgetsAreUs.isPointInBox(x, y, machinesManager.right) then
      print("machinesManager - Line 203: Clicked on right navigation button.")
      machinesManager[active].display:nextPage()
      return
    end

    if machinesManager.individuals.back then
      if widgetsAreUs.isPointInBox(x, y, machinesManager.individuals.back) then
        print("machinesManager - Line 209: Clicked on back button.")
        machinesManager.individuals.remove()
        machinesManager.groups.init()
        return
      end
    end

    for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
      os.sleep(0)  -- Yield execution during onClick processing
      if widgetsAreUs.isPointInBox(x, y, v.background) then
        print("machinesManager - Line 217: Clicked on a displayed item.")
        v.onClick(button, v, individualHeader)
        return
      end
    end
  end)

  if not success then
    print("machinesManager - Line 224: Error in machinesManager.onClick: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

function machinesManager.setVisible(visible)
  print("machinesManager - Line 230: Setting visibility to", tostring(visible))
  local success, err = pcall(function()
    machinesManager[active].background.setVisible(visible)
    os.sleep(0)  -- Yield execution after setting background visibility

    if active == "individuals" then
      machinesManager.individuals.back.setVisible(visible)
      os.sleep(0)  -- Yield execution after setting back visibility
    end

    for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
      v.setVisible(visible)
      os.sleep(0)  -- Yield execution during visibility loop
    end

    machinesManager.left.setVisible(visible)
    machinesManager.right.setVisible(visible)
  end)

  if not success then
    print("machinesManager - Line 243: Error in machinesManager.setVisible: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

saveData = function(_, newName, xyz)
  print("machinesManager - Line 249: Saving data for machine with newName =", tostring(newName))
  local success, err = pcall(function()
    local tbl = gimpHelper.loadTable("/home/programData/" .. individualHeader .. ".data") or {}
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
    data.groupName = individualHeader

    for k, v in ipairs(tbl) do
      if v.xyz.x == xyz.x and v.xyz.y == xyz.y and v.xyz.z == xyz.z then
        table.remove(tbl, k)
      end
      os.sleep(0)  -- Yield execution during data processing loop
    end

    if data.newName and data.xyz and data.xyz.z and data.groupName then
      table.insert(tbl, data)
      gimpHelper.saveTable(tbl, "/home/programData/" .. individualHeader .. ".data")
      event.push("machine_named", data, data.xyz)
      print("machinesManager - Line 273: Data saved successfully.")
    else
      print("machinesManager - Line 275: Error in saveData: Data is incomplete.")
    end
  end)

  if not success then
    print("machinesManager - Line 279: Error in saveData: " .. tostring(err))
  end
  print("") -- Blank line for readability
end

event.listen("nameSet", saveData)

return machinesManager