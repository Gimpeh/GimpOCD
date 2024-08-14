--machinesManager
local metricsDisplays = require("metricsDisplays")
local component = require("component")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local widgetsAreUs = require("widgetsAreUs")

local has_been_sorted = false
local tbl = gimpHelper.loadTable("/home/programData/machinesManager.data")
local tbl = gimpHelper.loadTable("/home/programData/machinesManager.data")
local active

local status, result = pcall(function() return tbl and tbl.active end)
if status then
  active = result or "groups"
else
  active = "groups"
end

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
	local unsorted = getProxies()
	local config = gimpHelper.loadTable("/home/programData/groups.config")
	machinesManager.groups.groupings = {}
	for k, v in ipairs(config) do
		local proxies = {}
		local groupname = v.name
		for e = #unsorted, 1, -1 do
			local i = unsorted[e]
			local x, y, z = i.getCoordinates()
			if v.start.x < x and x < v.ending.x and v.start.y < y and y < v.ending.y and v.start.z < z and z < v.ending.z then
				table.insert(proxies, i)
				table.remove(unsorted, e)
			end
		end
		machinesManager.groups.groupings[groupname] = proxies
	end
	has_been_sorted = true
end

function machinesManager.init()
	local success, config = pcall(gimpHelper.loadTable, "/home/programData/machines.config")
	if success then
		machinesManager[config.active].init()
	else
		machinesManager.groups.init()
	end
end

function machinesManager.groups.init()
	if not has_been_sorted then
		sortProxies()
	end
	local args = {}
	for k, v in ipairs(machinesManager.groups.groupings) do
		table.insert(args, k)
	end
	machinesManager.groups.background = widgetsAreUs.createBox(90, 30, 720, 465, {1, 1, 1}, 0.8)
	machinesManager.groups.display = PagedWindow.new(machinesManager.groups.groupings, 107, 75, {x1 = 100, y1 = 40, x2 = 700, y2 = 430}, 15, metricsDisplays.machineGroups.createElement, args)
	machinesManager.groups.display:displayItems()
	active = "groups"
end

function machinesManager.groups.remove()
	machinesManager.groups.display:clearDisplayedItems()
	machinesManager.groups.display = nil
	component.glasses.removeObject(machinesManager.groups.background.getID())
	machinesManager.groups.background = nil
end

function machinesManager.individuals.init(machinesTable)
	machinesManager.individuals.background = widgetsAreUs.createBox(70, 70, 640, 430, {1, 1, 1}, 0.7)
	machinesManager.individuals.display = PagedWindow.new(machinesTable, 60, 34, {x1 = 80, y1 = 80, x2 = 700, y2 = 400}, 7, metricsDisplays.machine.create)
	machinesManager.individuals.display:displayItems()
	active = "individuals"
end

function machinesManager.individuals.remove()
	machinesManager.individuals.display:clearDisplayedItems()
	component.glasses.removeObject(machinesManager.individuals.background.getID())
	machinesManager.individuals.background = nil
end

--machinesManager.onClick()
--machinesManager.update()
--machinesManager.setVisible()
--machinesManager.prev()
--machinesManager.next()

function machinesManager.init()
	machinesManager[active].init()
end

function machinesManager.remove()
	machinesManager[active].remove()
end

function machinesManager.update()
	for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
		v.update()
	end
end

function machinesManager.onClick(x, y, button)
	for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
		if widgetsAreUs.isPointInBox(x, y, v.background) then
			v.onClick(button)
		end
	end
end

function machinesManager.left()
	machinesManager[active].display:prevPage()
end

function machinesManager.right()
	machinesManager[active].display:nextPage()
end

function machinesManager.setVisible(visible)
	for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
		v.setVisible(visible)
	end
end

return machinesManager