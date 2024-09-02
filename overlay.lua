--overlay.tabs
--Should store the active overlay.tabs, so that it can be opened and closed without starting overlay.tabs
local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local machinesManager = require("machinesManager")
local itemWindow = require("itemWindow")
local configurations = require("configurations")
local c = require("gimp_colors")

-----------------------------------------
---forward declarations

local overlay = {}
overlay.tabs = {}
local active

-----------------------------------------
----Initialization and Swap Functions

function overlay.loadTab(tab)
    print("overlay.tabs - Line 22: Loading tab", tostring(tab))
    while gimp_globals.initializing_lock do
        print("overlay load Tab: waiting on init lock")
        os.sleep(500)
    end
    gimp_globals.initializing_lock = true
    print("\n overlay.tabs - Line 24: init lock enabled \n")
    local success, err = pcall(function()
        if active and active.remove then 
            local success_remove, error_remove = pcall(active.remove) 
            if not success_remove then
                print("overlay.tabs - Line 29: Error removing active tab: " .. tostring(error_remove))
            end
        end
        overlay.tabs[tab].init()
        local tbl = {tab = tab}
        local success_save, error_save = pcall(gimpHelper.saveTable, tbl, "/home/programData/overlay.data")
        if not success_save then
            print("overlay.tabs - Line 36: Error saving overlay tab state: " .. tostring(error_save))
        end
        os.sleep(0)
    end)
    if not success then
        print("overlay.tabs - Line 41: Error in overlay.loadTab: " .. tostring(err))
    end
    print("") -- Blank line for readability
    gimp_globals.initializing_lock = false
    overlay.update()
    print("\n overlay.tabs - Line 45: init lock disabled \n")
end

function overlay.init()
    print("overlay.tabs - Line 50: init lock enabled")
    print("overlay.tabs - Line 51: Initializing overlay.")
    local success, err = pcall(function()
        overlay.tabs.itemWindow = {}
        overlay.tabs.itemWindow.box = widgetsAreUs.createBox(10, 10, 140, 40, c.tabs, 0.7)
        overlay.tabs.itemWindow.title = widgetsAreUs.text(20, 20, "Storage", 1)
        overlay.tabs.itemWindow.init = function()
            local success_itemWindow, error_itemWindow = pcall(function()
                print("overlay.tabs - Line 58: Initializing itemWindow tab.")
                itemWindow.init()
                os.sleep(0)
                active = itemWindow
            end)
            if not success_itemWindow then
                print("overlay.tabs - Line 64: Error in itemWindow.init: " .. tostring(error_itemWindow))
            end
        end

        overlay.tabs.machines = {}
        overlay.tabs.machines.box = widgetsAreUs.createBox(160, 10, 140, 40, c.tabs, 0.7)
        overlay.tabs.machines.title = widgetsAreUs.text(170, 20, "Machines", 1)
        overlay.tabs.machines.init = function()
            local success_machines, error_machines = pcall(function()
                print("overlay.tabs - Line 73: Initializing machines tab.")
                machinesManager.init()
                os.sleep(0)
                active = machinesManager
            end)
            if not success_machines then
                print("overlay.tabs - Line 79: Error in machinesManager.init: " .. tostring(error_machines))
            end
        end

        overlay.tabs.options = {}
        overlay.tabs.options.box = widgetsAreUs.createBox(310, 10, 140, 40, c.tabs, 0.7)
        overlay.tabs.options.title = widgetsAreUs.text(320, 20, "Options", 1)
        overlay.tabs.options.init = function()
            local success_options, error_options = pcall(function()
                print("overlay.tabs - Line 88: Initializing options tab.")
                configurations.init()
                os.sleep(0)
                active = configurations
            end)
            if not success_options then
                print("overlay.tabs - Line 94: Error in configurations.init: " .. tostring(error_options))
            end
        end

        overlay.tabs.textEditor = {}
        overlay.tabs.textEditor.box = widgetsAreUs.createBox(460, 10, 140, 40, c.tabs, 0.7)
        overlay.tabs.textEditor.title = widgetsAreUs.text(470, 20, "Text Editor", 1)
        overlay.tabs.textEditor.init = function()
            local success_textEditor, error_textEditor = pcall(function()
                print("overlay.tabs - Line 103: Initializing text editor tab.")
                os.sleep(0)
                active = "text editor not set yet"
            end)
            if not success_textEditor then
                print("overlay.tabs - Line 108: Error in textEditor.init: " .. tostring(error_textEditor))
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
            print("overlay.tabs - Line 122: Loading saved tab", tostring(tab))
            overlay.loadTab(tab)
        else
            print("overlay.tabs - Line 125: Initializing default tab (machines).")
            overlay.tabs.machines.init()
        end
        overlay.hide()
        os.sleep(0)
    end)
    if not success then
        print("overlay.tabs - Line 132: Error in overlay.init: " .. tostring(err))
    end
    print("\n overlay.tabs - Line 135: init lock disabled \n")
    print("") -- Blank line for readability
end

-----------------------------------------
---element functionality

function overlay.setVisible(visible)
    print("overlay.tabs - Line 143: Setting visibility to", tostring(visible))
    print("overlay - 144 : waiting on init lock")
    while gimp_globals.initializing_lock do
        os.sleep(10)
    end
    print("overlay - 148 : done waiting on init lock")
    local success, err = pcall(function()
        for k, v in pairs(overlay.tabs) do
            v.box.setVisible(visible)
            v.title.setVisible(visible)
        end
    end)
    if not success then
        print("overlay.tabs - Line 156: Error in overlay.setVisible: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function overlay.hide()
    print("overlay.tabs - Line 162: Hiding overlay.")
    print("waiting on init lock")
    while gimp_globals.initializing_lock do
        os.sleep(10)
    end
    print("done waiting on init lock")
    local success, err = pcall(function()
        overlay.setVisible(false)
        if active and active.setVisible then
            active.setVisible(false)
        end
    end)
    if not success then
        print("overlay.tabs - Line 175: Error in overlay.hide: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function overlay.show()
    print("overlay.tabs - Line 181: Showing overlay.")
    print("waiting on init lock")
    while gimp_globals.initializing_lock do
        os.sleep(10)
    end
    print("done waiting on init lock")
    local success, err = pcall(function()
        overlay.setVisible(true)
        if active and active.setVisible then
            active.setVisible(true)
        end
    end)
    if not success then
        print("overlay.tabs - Line 194: Error in overlay.show: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

function overlay.onClick(x, y, button)
    print("overlay.tabs - Line 200: Handling onClick event at (", tostring(x), ",", tostring(y), ") with button", tostring(button))
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
        if active and active.update then
            active.update()
        end
    end)
    if not success then
        print("overlay.tabs - Line 214: Error in overlay.onClick: " .. tostring(err))
    end
    print("Overlay.onClick - Line 216: Done handling onClick event.")
    print("") -- Blank line for readability
end

function overlay.update()
    print("overlay - 220 : waiting on init lock")
    while gimp_globals.initializing_lock do
        print("overlay - 222 : still waiting on init lock")
        os.sleep(1200)
    end
    print("overlay - 225 : done waiting on init lock")
    print("overlay.tabs - Line 226: Updating overlay.")
    local success, err = pcall(function()
        if active and active.update then
            os.sleep(0)
            active.update()
        end
    end)
    if not success then
        print("overlay.tabs - Line 234: Error in overlay.update: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

return overlay