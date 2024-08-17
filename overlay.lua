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
	os.sleep(0)
end

function overlay.init()
	overlay.tabs.itemWindow = {}
	overlay.tabs.itemWindow.box = widgetsAreUs.createBox(10, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.itemWindow.title = widgetsAreUs.text(20, 20, "Storage", 1)
	overlay.tabs.itemWindow.init = function()
		itemWindow.init()
		os.sleep(0)
		active = itemWindow
	end
	overlay.tabs.machines = {}
	overlay.tabs.machines.box = widgetsAreUs.createBox(160, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.machines.title = widgetsAreUs.text(170, 20, "Machines", 1)
	overlay.tabs.machines.init = function()
		machinesManager.init()
		os.sleep(0)
		active = machinesManager
	end
	os.sleep(0)
	overlay.tabs.options = {}
	overlay.tabs.options.box = widgetsAreUs.createBox(310, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.options.title = widgetsAreUs.text(320, 20, "Options", 1)
	overlay.tabs.options.init = function()
		configurations.init()
		os.sleep(0)
		active = configurations
	end

	overlay.tabs.textEditor = {}
	overlay.tabs.textEditor.box = widgetsAreUs.createBox(460, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.textEditor.title = widgetsAreUs.text(470, 20, "Text Editor", 1)
	overlay.tabs.textEditor.init = function()
		print("text editor tab init called")
		os.sleep(0)
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
	os.sleep(0)
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

---------

function overlay.onClick(x, y, button)
	for k, v in pairs(overlay.boxes) do
		if widgetsAreUs.isPointInBox(x, y, v) then
			os.sleep(0)
			return overlay.tabs.loadTab(k)
		end
	end
	active.onClick(x, y, button)
	os.sleep(0)
end

function overlay.update()
	if active and active.update then
		os.sleep(0)
		active.update()
	end
end

return overlay