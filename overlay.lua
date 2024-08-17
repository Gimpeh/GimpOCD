--overlay.tabs
--Should store the active overlay.tabs, so that it can be opened and closed without starting overlay.tabs
local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local machinesManager = require("machinesManager")
local itemWindow = require("itemWindow")
local configurations = require("configurations")

-----------------------------------------
---forward declarations

local overlay = {}
overlay.tabs = {}
local active

-----------------------------------------
----Initialization and Swap Functions

function overlay.tabs.loadTab(tab)
    if active and active.remove then pcall(active.remove) end
    overlay.tabs[tab].init()
    local tbl = {tab = tab}
    gimpHelper.saveTable(tbl, "/home/programData/overlay.data")
end

function overlay.init()
	overlay.tabs.itemWindow = {}
	overlay.tabs.itemWindow.box = widgetsAreUs.createBox(10, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.itemWindow.title = component.glasses.addTextLabel()
	overlay.tabs.itemWindow.title.setPosition(20, 20)
	overlay.tabs.itemWindow.title.setText("Storage")
	overlay.tabs.itemWindow.init = function()
		itemWindow.init()
		active = itemWindow
	end
	overlay.tabs.machines = {}
	overlay.tabs.machines.box = widgetsAreUs.createBox(160, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.machines.title = component.glasses.addTextLabel()
	overlay.tabs.machines.title.setPosition(170,20)
	overlay.tabs.machines.title.setText("Machines")
	overlay.tabs.machines.init = function()
		machinesManager.init()
		active = machinesManager
	end
	overlay.tabs.options = {}
	overlay.tabs.options.box = widgetsAreUs.createBox(310, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.options.title = component.glasses.addTextLabel()
	overlay.tabs.options.title.setPosition(320, 20)
	overlay.tabs.options.title.setText("Options")
	overlay.tabs.options.init = function()
		configurations.init()
		active = configurations
	end
	overlay.tabs.textEditor = {}
	overlay.tabs.textEditor.box = widgetsAreUs.createBox(460, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.textEditor.title = component.glasses.addTextLabel()
	overlay.tabs.textEditor.title.setPosition(470, 20)
	overlay.tabs.textEditor.title.setText("Text Editor")
	overlay.tabs.textEditor.init = function()
		print("text editor tab init called")
		active = "text editor not set yet"
	end

	overlay.boxes = {textEditor = overlay.tabs.textEditor.box, options = overlay.tabs.options.box, machines = overlay.tabs.machines.box, itemWindow = overlay.tabs.itemWindow.box}

	local success, config = pcall(gimpHelper.loadTable, "/home/programData/overlay.data")
	if success and config then
		local tab = config.tab
		overlay.tabs.loadTab(tab)
	else
		overlay.tabs.machines.init()
	end
	overlay.hide()
end

-----------------------------------------
---element functionality

function overlay.tabs.setVisible(visible)
	for k, v in pairs(overlay.tabs) do
		v.box.setVisible(visible)
		v.title.setVisible(visible)
	end
end

function overlay.hide()
	overlay.tabs.setVisible(false)
	if active and active.setVisible then
		active.setVisible(false)
	end
end

function overlay.show()
	overlay.tabs.setVisible(true)
	if active and active.setVisible then
		active.setVisible(true)
	end
end

-------------------

function overlay.onClick(x, y, button)
	for k, v in pairs(overlay.boxes) do
		if widgetsAreUs.isPointInBox(x, y, v) then
			return overlay.tabs.loadTab(k)
		end
	end
	active.onClick(x, y, button)
end

function overlay.update()
	if active and active.update then
		active.update()
	end
end

return overlay