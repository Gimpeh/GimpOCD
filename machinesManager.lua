--machinesManager
local metricsDisplays = require("metricsDisplays")
local component = require("component")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local widgetsAreUs = require("widgetsAreUs")
local event = require("event")

local has_been_sorted = false
local saveData
local activeIndividualPage
local individualHeader
local active = "groups"

local machinesManager = {}
machinesManager.groups = {}
machinesManager.individuals = {}

local function getProxies()
  local tbl = {}
  local theList = component.list("gt_machine")
  for k, v in pairs(theList) do
    table.insert(tbl, component.proxy(k))
  end
  return tbl
end

local function sortProxies()
  local success, err = pcall(function()
    local unsorted = getProxies()
    local config = gimpHelper.loadTable("/home/programData/groups.config")
    machinesManager.groups.groupings = {}
    for k, v in ipairs(config) do
      local proxies = {}
      local groupname = v.name
      for e = #unsorted, 1, -1 do
        local i = unsorted[e]
        local x, y, z = i.getCoordinates()
        if v.start.x < x and x < v.ending.x and v.start.z < z and z < v.ending.z then
          table.insert(proxies, i)
          table.remove(unsorted, e)
        end
      end
      machinesManager.groups.groupings[groupname] = proxies
    end
    has_been_sorted = true
  end)
  if not success then
    print("Error in sortProxies: " .. err)
  end
end

function machinesManager.groups.init()
  local success, err = pcall(function()
    if not has_been_sorted then
      sortProxies()
    end
    local args = {}
    local args2 = {}
    for k, v in pairs(machinesManager.groups.groupings) do
      table.insert(args, k)
      table.insert(args2, v)
    end
    machinesManager.groups.background = widgetsAreUs.createBox(70, 70, 640, 430, {1, 1, 1}, 0.8)
    os.sleep(0.1)
    machinesManager.groups.display = PagedWindow.new(args2, 107, 75, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 15, metricsDisplays.machineGroups.createElement, args)
    machinesManager.groups.display:displayItems()
    active = "groups"
    machinesManager.update()
  end)
  if not success then
    print("Error in machinesManager.groups.init: " .. err)
  end
end

function machinesManager.groups.remove()
  local success, err = pcall(function()
    machinesManager.groups.display:clearDisplayedItems()
    machinesManager.groups.display = nil
    component.glasses.removeObject(machinesManager.groups.background.getID())
    machinesManager.groups.background = nil
  end)
  if not success then
    print("Error in machinesManager.groups.remove: " .. err)
  end
end

function machinesManager.individuals.init(machinesTable, header)
  local success, err = pcall(function()
    if not machinesTable then
      machinesTable = activeIndividualPage
    end
    machinesManager.individuals.background = widgetsAreUs.createBox(70, 70, 640, 430, {1, 1, 1}, 0.7)
    machinesManager.individuals.back = widgetsAreUs.createBox(720, 75, 50, 25, {1, 0, 0}, 0.7)
    machinesManager.individuals.display = PagedWindow.new(machinesTable, 85, 34, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 7, metricsDisplays.machine.create)
    machinesManager.individuals.display:displayItems()
    active = "individuals"
    activeIndividualPage = machinesTable
    individualHeader = header

    for k, v in pairs(machinesManager.individuals.display.currentlyDisplayed) do
      v.setName()
    end
    local savedNames = gimpHelper.loadTable("/home/programData/" .. header .. ".data")
    if not savedNames then
      savedNames = {}
    end
    for k, v in pairs(savedNames) do
      for j, i in pairs(machinesManager.individuals.display.currentlyDisplayed) do
        local xyzCheck = {}
        xyzCheck.x, xyzCheck.y, xyzCheck.z = i.getCoords()
        if v.xyz.x == xyzCheck.x and v.xyz.y == xyzCheck.y and v.xyz.z == xyzCheck.z then
          i.setName(v.newName)
        end
      end
    end
    machinesManager.update()
  end)
  if not success then
    print("Error in machinesManager.individuals.init: " .. err)
  end
end

function machinesManager.individuals.remove()
  local success, err = pcall(function()
    machinesManager.individuals.display:clearDisplayedItems()
    component.glasses.removeObject(machinesManager.individuals.background.getID())
    component.glasses.removeObject(machinesManager.individuals.back.getID())
    machinesManager.individuals.background = nil
  end)
  if not success then
    print("Error in machinesManager.individuals.remove: " .. err)
  end
end

function machinesManager.init()
  local success, err = pcall(function()
    machinesManager.left = widgetsAreUs.createBox(10, 225, 20, 20, {0, 1, 0}, 0.7)
    machinesManager.right = widgetsAreUs.createBox(750, 225, 20, 20, {0, 1, 0}, 0.7)
    machinesManager[active].init()
  end)
  if not success then
    print("Error in machinesManager.init: " .. err)
  end
end

function machinesManager.remove()
  local success, err = pcall(function()
    saveData()
    machinesManager[active].remove()
    component.glasses.removeObject(machinesManager.left.getID())
    component.glasses.removeObject(machinesManager.right.getID())
    machinesManager.left = nil
  end)
  if not success then
    print("Error in machinesManager.remove: " .. err)
  end
end

function machinesManager.update()
  local success, err = pcall(function()
    for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
      os.sleep(0)
      v.update()
    end
  end)
  if not success then
    print("Error in machinesManager.update: " .. err)
  end
end

function machinesManager.onClick(x, y, button)
  local success, err = pcall(function()
    if widgetsAreUs.isPointInBox(x, y, machinesManager.left) then
      machinesManager[active].display:prevPage()
      return
    elseif widgetsAreUs.isPointInBox(x, y, machinesManager.right) then
      machinesManager[active].display:nextPage()
      return
    end
    if machinesManager.individuals.back then
      if widgetsAreUs.isPointInBox(x, y, machinesManager.individuals.back) then
        machinesManager.individuals.remove()
        machinesManager.groups.init()
        return
      end
    end
    for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
      if widgetsAreUs.isPointInBox(x, y, v.background) then
        v.onClick(button, v, individualHeader)
        return
      end
    end
  end)
  if not success then
    print("Error in machinesManager.onClick: " .. err)
  end
end

function machinesManager.setVisible(visible)
  local success, err = pcall(function()
    machinesManager[active].background.setVisible(visible)
    if active == "individuals" then
      machinesManager.individuals.back.setVisible(visible)
    end
    for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
      v.setVisible(visible)
    end
    machinesManager.left.setVisible(visible)
    machinesManager.right.setVisible(visible)
  end)
  if not success then
    print("Error in machinesManager.setVisible: " .. err)
  end
end

saveData = function(_, newName, xyz)
  local success, err = pcall(function()
    local tbl = gimpHelper.loadTable("/home/programData/" .. individualHeader .. ".data") or {}
    if not tbl then
      tbl = {}
    end
    local data = {}
    local str = newName:gsub("^[\0-\31\127]+", "")
    data.newName = str
    data.xyz = xyz
    data.groupName = individualHeader
    for k, v in ipairs(tbl) do
      if v.xyz.x == xyz.x and v.xyz.y == xyz.y and v.xyz.z == xyz.z then
        table.remove(tbl, k)
      end
    end

    if data.newName and data.xyz and data.groupName then
      table.insert(tbl, data)
      gimpHelper.saveTable(tbl, "/home/programData/" .. individualHeader .. ".data")
      event.push("machine_named", tbl)
    else
      print("Line: 217  |  Error in machinesManager saveData function: data is missing")
    end
  end)
  if not success then
    print("Error in saveData: " .. err)
  end
end

event.listen("nameSet", saveData)

return machinesManager