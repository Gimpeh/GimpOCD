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

function overlay.loadTab(tab)
    local success, err = pcall(function()
        if active and active.remove then 
            local success_remove, error_remove = pcall(active.remove) 
            if not success_remove then
                print("Error removing active tab: " .. error_remove)
            end
        end
        overlay.tabs[tab].init()
        local tbl = {tab = tab}
        local success_save, error_save = pcall(gimpHelper.saveTable, tbl, "/home/programData/overlay.data")
        if not success_save then
            print("Error saving overlay tab state: " .. error_save)
        end
        os.sleep(0)
    end)
    if not success then
        print("Error in overlay.loadTab: " .. err)
    end
end

function overlay.init()
    local success, err = pcall(function()
        overlay.tabs.itemWindow = {}
        overlay.tabs.itemWindow.box = widgetsAreUs.createBox(10, 10, 140, 40, {0, 0, 1}, 0.7)
        overlay.tabs.itemWindow.title = widgetsAreUs.text(20, 20, "Storage", 1)
        overlay.tabs.itemWindow.init = function()
            local success_itemWindow, error_itemWindow = pcall(function()
                itemWindow.init()
                os.sleep(0)
                active = itemWindow
            end)
            if not success_itemWindow then
                print("Error in itemWindow.init: " .. error_itemWindow)
            end
        end

        overlay.tabs.machines = {}
        overlay.tabs.machines.box = widgetsAreUs.createBox(160, 10, 140, 40, {0, 0, 1}, 0.7)
        overlay.tabs.machines.title = widgetsAreUs.text(170, 20, "Machines", 1)
        overlay.tabs.machines.init = function()
            local success_machines, error_machines = pcall(function()
                machinesManager.init()
                os.sleep(0)
                active = machinesManager
            end)
            if not success_machines then
                print("Error in machinesManager.init: " .. error_machines)
            end
        end

        overlay.tabs.options = {}
        overlay.tabs.options.box = widgetsAreUs.createBox(310, 10, 140, 40, {0, 0, 1}, 0.7)
        overlay.tabs.options.title = widgetsAreUs.text(320, 20, "Options", 1)
        overlay.tabs.options.init = function()
            local success_options, error_options = pcall(function()
                configurations.init()
                os.sleep(0)
                active = configurations
            end)
            if not success_options then
                print("Error in configurations.init: " .. error_options)
            end
        end

        overlay.tabs.textEditor = {}
        overlay.tabs.textEditor.box = widgetsAreUs.createBox(460, 10, 140, 40, {0, 0, 1}, 0.7)
        overlay.tabs.textEditor.title = widgetsAreUs.text(470, 20, "Text Editor", 1)
        overlay.tabs.textEditor.init = function()
            local success_textEditor, error_textEditor = pcall(function()
                print("text editor tab init called")
                os.sleep(0)
                active = "text editor not set yet"
            end)
            if not success_textEditor then
                print("Error in textEditor.init: " .. error_textEditor)
            end
        end

        overlay.boxes = {
            textEditor = overlay.tabs.textEditor.box, 
            options = overlay.tabs.options.box, 
            machines = overlay.tabs.machines.box, 
            itemWindow = overlay.tabs.itemWindow.box
        }

        local success_load, config = pcall(gimpHelper.loadTable, "/home/programData/overlay.data")
        if success_load and config then
            local tab = config.tab
            overlay.loadTab(tab)
        else
            overlay.tabs.machines.init()
        end
        overlay.hide()
        os.sleep(0)
    end)
    if not success then
        print("Error in overlay.init: " .. err)
    end
end

-----------------------------------------
---element functionality

function overlay.setVisible(visible)
    local success, err = pcall(function()
        for k, v in pairs(overlay.tabs) do
            v.box.setVisible(visible)
            v.title.setVisible(visible)
        end
    end)
    if not success then
        print("Error in overlay.setVisible: " .. err)
    end
end

function overlay.hide()
    local success, err = pcall(function()
        overlay.setVisible(false)
        if active and active.setVisible then
            active.setVisible(false)
        end
    end)
    if not success then
        print("Error in overlay.hide: " .. err)
    end
end

function overlay.show()
    local success, err = pcall(function()
        overlay.setVisible(true)
        if active and active.setVisible then
            active.setVisible(true)
        end
    end)
    if not success then
        print("Error in overlay.show: " .. err)
    end
end

---------

function overlay.onClick(x, y, button)
    local success, err = pcall(function()
        for k, v in pairs(overlay.boxes) do
            if v.contains(x, y, v) then
                os.sleep(0)
                return overlay.loadTab(k)
            end
        end
        if active and active.onClick then
            active.onClick(x, y, button)
        end
        os.sleep(0)
    end)
    if not success then
        print("Error in overlay.onClick: " .. err)
    end
end

function overlay.update()
    local success, err = pcall(function()
        if active and active.update then
            os.sleep(0)
            active.update()
        end
    end)
    if not success then
        print("Error in overlay.update: " .. err)
    end
end

return overlay