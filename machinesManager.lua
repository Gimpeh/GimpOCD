--machinesManager
local metricsDisplays = require("metricsDisplays")
local component = require("component")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local widgetsAreUs = require("widgetsAreUs")

local has_been_sorted = false
local activeIndividualPage
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
end

function machinesManager.groups.init()
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
end

function machinesManager.groups.remove()
	machinesManager.groups.display:clearDisplayedItems()
	machinesManager.groups.display = nil
	component.glasses.removeObject(machinesManager.groups.background.getID())
	machinesManager.groups.background = nil
end

function machinesManager.individuals.init(machinesTable)
	if not machinesTable then
		machinesTable = activeIndividualPage
	end
	machinesManager.individuals.background = widgetsAreUs.createBox(70, 70, 640, 430, {1, 1, 1}, 0.7)
	machinesManager.individuals.back = widgetsAreUs.createBox(720, 75, 50, 25, {1, 0, 0}, 0.7)
	machinesManager.individuals.display = PagedWindow.new(machinesTable, 60, 34, {x1 = 80, y1 = 80, x2 = 700, y2 = 500}, 7, metricsDisplays.machine.create)
	machinesManager.individuals.display:displayItems()
	active = "individuals"
	activeIndividualPage = machinesTable
end

function machinesManager.individuals.remove()
	machinesManager.individuals.display:clearDisplayedItems()
	component.glasses.removeObject(machinesManager.individuals.background.getID())
	component.glasses.removeObject(machinesManager.individuals.back.getID())
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
	if machinesManager.individuals.back then
		if widgetsAreUs.isPointInBox(x, y, machinesManager.individuals.back) then
			machinesManager.individuals.remove()
			machinesManager.groups.init()
		end
	end
	for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
		if widgetsAreUs.isPointInBox(x, y, v.background) then
			v.onClick(button, v)
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
	machinesManager[active].background.setVisible(visible)
	for k, v in ipairs(machinesManager[active].display.currentlyDisplayed) do
		v.setVisible(visible)
	end
end

return machinesManager