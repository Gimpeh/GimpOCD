--overlay.tabs
--Should store the active overlay.tabs, so that it can be opened and closed without starting overlay.tabs
local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local machinesManager = require("machinesManager")

local overlay = {}
overlay.tabs = {}
local active

function overlay.tabs.loadTab(tab)
	pcall(active.remove)
	overlay.tabs[tab].init()
	local tbl = {tab = tab}
	gimpHelper.saveTable(tbl, "/home/programData/overlay.data")
end

function overlay.init()
	machinesManager

	overlay.tabs.itemWindow = {}
	overlay.tabs.itemWindow.background = widgetsAreUs.createBox(10, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.itemWindow.title = component.glasses.addTextLabel()
	overlay.tabs.itemWindow.title.setPosition(20, 20)
	overlay.tabs.itemWindow.title.setText("Storage")
	overlay.tabs.itemWindow.init = function()
		print("item window init called")
		active = "item window not ready yet"
	end
	overlay.tabs.machines = {}
	overlay.tabs.machines.background = widgetsAreUs.createBox(160, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.machines.title = component.glasses.addTextLabel()
	overlay.tabs.machines.title.setPosition(170,20)
	overlay.tabs.machines.title.setText("Machines")
	overlay.tabs.machines.init = function()
		machinesManager.init()
		active = machinesManager
	end
	overlay.tabs.options = {}
	overlay.tabs.options.background = widgetsAreUs.createBox(310, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.options.title = component.glasses.addTextLabel()
	overlay.tabs.options.title.setPosition(320, 20)
	overlay.tabs.options.title.setText("Options")
	overlay.tabs.options.init = function()
		print("options tab init called")
		active = "options not set yet"
	end
	overlay.tabs.textEditor = {}
	overlay.tabs.textEditor.background = widgetsAreUs.createBox(460, 10, 140, 40, {0, 0, 1}, 0.7)
	overlay.tabs.textEditor.title = component.glasses.addTextLabel()
	overlay.tabs.textEditor.title.setPosition(470, 20)
	overlay.tabs.textEditor.title.setText("Text Editor")
	overlay.tabs.textEditor.title.init = function()
		print("text editor tab init called")
		active = "text editor not set yet"
	end
	overlay.tabs.left = widgetsAreUs.createBox(10, 225, 20, 20, {0, 1, 0}, 0.7)
	overlay.tabs.right = widgetsAreUs.createBox(750, 225, 20, 20, {0, 1, 0}, 0.7)

	overlay.boxes = {left = overlay.tabs.left, right = overlay.tabs.right, textEditor = overlay.tabs.textEditor.background, options = overlay.tabs.options.background}

	local success, config = pcall(gimpHelper.loadTable, "/home/programData/overlay.data")
	if success and config then
		local tab = config.currentTab
		overlay.tabs.loadTab(tab)
	else
		overlay.tabs.machines.init()
	end
	overlay.hide()
end

function overlay.tabs.setVisible(visible)
	overlay.tabs.itemWindow.background.setVisible(visible)
	overlay.tabs.itemWindow.title.setVisible(visible)
	overlay.tabs.machines.background.setVisible(visible)
	overlay.tabs.machines.title.setVisible(visible)
	overlay.tabs.options.background.setVisible(visible)
	overlay.tabs.options.title.setVisible(visible)
end

function overlay.hide()
	overlay.tabs.setVisible(false)
	machinesManager.setVisible(false)
end

function overlay.show()
	overlay.tabs.setVisible(true)
	machinesManager.setVisible(true)
end

function overlay.onClick(x, y, button)
	for k, v in pairs(overlay.boxes) do
		if widgetsAreUs.isPointInBox(x, y, v) then
			if k ~= "left" and k ~="right" then
				return overlay.tabs.loadTab(k)
			elseif k == "left" then
				return pcall(active.left)
			elseif k == "right" then
				return pcall(active.right)
			end
		end
	end
	active.onClick(x, y, button)
end

return overlay