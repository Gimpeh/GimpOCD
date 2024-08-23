---@diagnostic disable: unused-function
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local event = require("event")
local metricsDisplays = require("metricsDisplays")

----------------------------------------------------------
---event handlers

--This function should really be moved into machinesManager.
--It's not a configuration, it's a persistance file for machinesManager.
local function stockPileData(_, config)
    local tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
    if not tbl then
        os.sleep(0)
        tbl = {}
    end
    if tbl[1] then
        for k, v in ipairs(tbl) do
            os.sleep(0)
            if v.xyz.x == config.xyz.x and v.xyz.y == config.xyz.y and v.xyz.z == config.xyz.z then
                table.remove(tbl, k)
            end
        end
    end
    table.insert(tbl, config)
    gimpHelper.saveTable(tbl, "/home/programData/machinesNamed.data")
    os.sleep(0)
end

local function removeIndex(_, path, index)
    local tbl = gimpHelper.loadTable(path)
    if not tbl then
        tbl = {}
    end
    os.sleep(0)
    if tbl[index] then
        table.remove(tbl, index)
    end
    gimpHelper.saveTable(tbl, path)
    os.sleep(0)
end

----------------------------------------------------------
---event listeners

event.listen("remove_index", removeIndex)
event.listen("machine_named", stockPileData)
----------------------------------------------------------
---forward declarations

local configurations = {}
configurations.panel = {}
configurations.panel.lm = {}
configurations.panel.im = {}
configurations.panel.gc = {}
configurations.panel.mm = {}

local currentlyDisplayedConfigs = {}

local createGeneralConfig
local generateHelperTable
local saveConfigData
local loadConfigData
local boxes = {}
local buttons = {}
local displays = {}

----------------------------------------------------------
---initalization

function configurations.initBoxes()
    boxes.background = widgetsAreUs.createBox(10, 50, 750, 400, {0.2, 0.2, 0.2}, 0.8)
    boxes.levelMaintainer = widgetsAreUs.createBox(20, 80, 160, 200, {0.6, 1, 0.6}, 1)
    boxes.levelMaintainerConfig = widgetsAreUs.createBox(192, 80, 160, 200, {1, 1, 1}, 1)
    boxes.itemManager = widgetsAreUs.createBox(385, 60, 160, 240, {1, 1, 0.6}, 1)
    boxes.machineManager = widgetsAreUs.createBox(35, 310, 290, 150, {0.6, 0.6, 1}, 1)
    boxes.machineManagerConfig = widgetsAreUs.createBox(355, 310, 160, 160, {255, 255, 255}, 1)
    boxes.generalConfig = widgetsAreUs.createBox(520, 310, 230, 160, {255, 255, 255}, 1)
    boxes.itemMangerConfig = widgetsAreUs.createBox(580, 80, 160, 200, {255, 255, 255}, 1)
    os.sleep(0)
end

function configurations.initButtons()
    buttons.levelMaintainerPrev = widgetsAreUs.symbolBox(85, 58, "^", nil, function ()
        displays.levelMaintainer:prevPage()
    end)
    buttons.levelMaintainerNext = widgetsAreUs.symbolBox(85, 283, "v", nil, function ()
        displays.levelMaintainer:nextPage()
    end)
    buttons.itemManagerPrev = widgetsAreUs.symbolBox(363, 160, "<", nil, function ()
        displays.itemManager:prevPage()
    end)
    buttons.itemManagerNext = widgetsAreUs.symbolBox(548, 160, ">", nil, function ()
        displays.itemManager:nextPage()
    end)
    buttons.machineManagerPrev = widgetsAreUs.symbolBox(8, 378, "<", nil, function ()
        displays.machineManager:prevPage()
    end)
    buttons.machineManagerNext = widgetsAreUs.symbolBox(328, 378, ">", nil, function ()
        displays.machineManager:nextPage()
    end)
    os.sleep(0)
end

function configurations.initDisplays()
    local function loadAndDisplayTable(path, width, height, coords, callback, widget)
        local tbl = gimpHelper.loadTable(path)
        if tbl and tbl[1] then
            local display = PagedWindow.new(tbl, width, height, coords, 5, widget)
            display:displayItems()
            for k, v in ipairs(display.currentlyDisplayed) do
                display.currentlyDisplayed[k] = widgetsAreUs.attachOnClick(v, function()
                    callback(k)
                end)
            end
        end
        tbl = nil
        os.sleep(0)
    end

    loadAndDisplayTable("/home/programData/levelMaintainer.data", 150, 30, {x1=25, x2=175, y1=85, y2=195}, function(k)
        configurations.createLevelMaintainerConfig(192, 80, k)
    end, widgetsAreUs.levelMaintainer)
    
    loadAndDisplayTable("/home/programData/monitoredItems", 120, 40, {x1=390, x2=540, y1=65, y2=305}, function(k)
        configurations.createItemManagerConfig(580, 80, k)
    end, widgetsAreUs.itemBox)
    
    loadAndDisplayTable("/home/programData/machinesNamed.data", 150, 30, {x1=45, x2=295, y1=320, y2=460}, function(k)
        configurations.createMachineManagerConfig(355, 310, k)
    end, metricsDisplays.machine.create)
end

function configurations.init()
    local success, error = pcall(configurations.initBoxes)
    if not success then print(error) end

    local success, error = pcall(configurations.initButtons)
    if not success then print(error) end 

    local success, error = pcall(configurations.initDisplays)
    if not success then print(error) end

    createGeneralConfig(525, 320)

    generateHelperTable()
end

----------------------------------------------------------
---configs factory

local function removeConfigDisplay(activeConfigsIndex)
    for k, v in pairs(currentlyDisplayedConfigs[activeConfigsIndex].elements) do
        if v.remove then
            local success, error = pcall(v.remove)
            if not success then print(error) end
        end
    end
    currentlyDisplayedConfigs[activeConfigsIndex].elements = nil
end

saveConfigData = function(activeConfigsConfigKey, path, activeConfigsIndex)
    local tbl = gimpHelper.loadTable(path)
    if not tbl then
        tbl = {}
    end
    local derp = {}
    for k, v in pairs(currentlyDisplayedConfigs[activeConfigsConfigKey].elements) do
        if v.option then
            derp[v.key] = gimpHelper.trim(v.option.text.getText())
        end
    end
    tbl[activeConfigsIndex] = derp
    gimpHelper.saveTable(tbl, path)
end


loadConfigData = function(currentlyDisplayedConfigsRef, path, configIndex)
    local tbl = gimpHelper.loadTable(path)
    if tbl and tbl[configIndex] then
        for k, v in pairs(currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements) do
            for i, j in pairs(tbl[configIndex]) do
                if v.key == i then
                    currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue(j)
                end
            end
        end
    end
end

function configurations.createLevelMaintainerConfig(x, y, index)
    if currentlyDisplayedConfigs["lm"] and currentlyDisplayedConfigs["lm"].index then
        local success, error = pcall(saveConfigData, "lm", "/home/programData/levelMaintainerConfig.data", currentlyDisplayedConfigs["lm"].index) --saves the currently displayed config
        if not success then print(error) end
        local success, error = pcall(removeConfigDisplay, "lm")    --deletes the currently displayed config
        if not success then print(error) end
    end
    configurations.panel.lm = {} --table for specific references
    configurations.panel.lm.priority = widgetsAreUs.numberBox(x, y, "priority", "Priority:")
    configurations.panel.lm.maxInstances = widgetsAreUs.numberBox(x + 80, y, "maxCrafters", "Max Conc:")
    configurations.panel.lm.minCPU = widgetsAreUs.numberBox(x, y+30, "minCpu", "Min CPU")
    configurations.panel.lm.minCpuTitle2 = widgetsAreUs.text(x+5, y+45, "Available:", 0.9)
    configurations.panel.lm.maxCPU = widgetsAreUs.numberBox(x+80, y+30, "maxCpu", "Max CPU")
    configurations.panel.lm.maxCpuTitle2 = widgetsAreUs.text(x+90, y+45, "Usage:", 1)
    configurations.panel.lm.alertStalled = widgetsAreUs.checkboxFullLine(x, y+60, "alertStalled", "Alert Stalled")
    configurations.panel.lm.alertResources = widgetsAreUs.checkboxFullLine(x, y+90, "alertResources", "Alert Can't Craft")
    os.sleep(0)

    currentlyDisplayedConfigs["lm"] = {index = index, elements = configurations.panel.lm} --lm short for level maintainer
    pcall(loadConfigData, "lm", "/home/programData/levelMaintainerConfig.data", index)
end

function configurations.createMachineManagerConfig(x, y, index)
    if currentlyDisplayedConfigs["mm"] and currentlyDisplayedConfigs["mm"].index then
        local success, error = pcall(saveConfigData, "mm", "/home/programData/machineManagerConfig.data", currentlyDisplayedConfigs["mm"].index)
        if not success then print(error) end
        local success, error = pcall(removeConfigDisplay, "mm")
        if not success then print(error) end
    end
    configurations.panel.mm = {}
    configurations.panel.mm.name = widgetsAreUs.textBoxWithTitle(x, y, "name", "Name")
    configurations.panel.mm.group = widgetsAreUs.textBoxWithTitle(x, y+30, "group", "Group") os.sleep(0)
    configurations.panel.mm.autoTurnOn = widgetsAreUs.numberBox(x, y+60, "autoTurnOn", "Auto On")
    configurations.panel.mm.autoTurnOff = widgetsAreUs.numberBox(x+80, y+60, "autoTurnOff", "Auto Off")
    configurations.panel.mm.alertIdle = widgetsAreUs.longerNumberBox(x, y+120, "alertIdle", "Alert Idle Timer")
    configurations.panel.mm.alertDisabled = widgetsAreUs.checkboxFullLine(x, y+150, "alertDisabled", "Alert Disabled")
    configurations.panel.mm.alertEnabled = widgetsAreUs.checkboxFullLine(x+80, y+150, "alertEnabled", "Alert Enabled")
    currentlyDisplayedConfigs["mm"] = {index = index, elements = configurations.panel.mm}
    pcall(loadConfigData, "mm", "/home/programData/machineManagerConfig.data", index)
end

function configurations.createItemManagerConfig(x, y, index)
    if currentlyDisplayedConfigs["im"] and currentlyDisplayedConfigs["im"].index then
        local success, error = pcall(saveConfigData, "im", "/home/programData/itemManagerConfig.data", currentlyDisplayedConfigs["im"].index)
        if not success then print(error) end
        local success, error = pcall(removeConfigDisplay, "im")
        if not success then print(error) end
    end
    configurations.panel.im = {}
    configurations.panel.im.alertAbove = widgetsAreUs.longerNumberBox(x, y, "alertAbove", "Alert Above")
    configurations.panel.im.alertBelow = widgetsAreUs.longerNumberBox(x, y+30, "alertBelow", "Alert Below")
    configurations.panel.im.showOnHud = widgetsAreUs.checkboxFullLine(x, y+60, "showOnHud", "Show On HUD")
    --configurations.panel.im.monitorMetrics = widgetsAreUs.checkboxFullLine(x, y+90, "monitorMetrics", "Monitor Metrics on Slave")
    currentlyDisplayedConfigs["im"] = {index = index, elements = configurations.panel.im}
    pcall(loadConfigData, "im", "/home/programData/itemManagerConfig.data", index)
end

createGeneralConfig = function(x, y)

    configurations.panel.gc = {}
    configurations.panel.gc.showHelp = widgetsAreUs.checkboxFullLine(x, y, "showHelp", "Show Help")
    configurations.panel.gc.resetHud = widgetsAreUs.configsButtonLong(x, y+30, "Reset HUD", "Reset", {0.8, 0, 0}, function()
        event.push("reset_hud")
    end) os.sleep(0)
    configurations.panel.gc.highlightDisabled = widgetsAreUs.checkboxFullLine(x, y+60, "highlightDisabled", "Highlight Disabled Mach's")
    configurations.panel.gc.maintenanceBeacons = widgetsAreUs.checkboxFullLine(x, y+90, "maintenanceBeacons", "Maintenance Beacons")
    configurations.panel.gc.alertDisconnected = widgetsAreUs.checkboxFullLine(x, y+120, "alertDisconnected", "Alert Disconnected")
    configurations.panel.gc.alertReconnected = widgetsAreUs.checkboxFullLine(x, y+150, "alertReconnected", "Alert Reconnected")
    configurations.panel.gc.maxCpusAllLevelMaintainers = widgetsAreUs.numberBoxLongerText(x, y+180, "maxCpusAllLevelMaintainers", "Max CPUs for Maintainers")
    currentlyDisplayedConfigs["gc"] = {index = 1, elements = configurations.panel.gc}
    pcall(loadConfigData, "gc", "/home/programData/generalConfig.data", 1)
end

----------------------------------------------------------
---got tired of typing everything 10,000 times

local helperTable = {}

generateHelperTable = function()
    helperTable = {}
    for k, v in pairs(boxes) do os.sleep(0) table.insert(helperTable, v) end
    for k, v in pairs(buttons) do os.sleep(0) table.insert(helperTable, v) end
    for k, v in pairs(displays) do os.sleep(0) --second loop contained below, every group of displayed objects, then every object in display
        for i, j in pairs(v.currentlyDisplayed) do table.insert(helperTable, j) end
    end
    for k, v in pairs(configurations.panel) do os.sleep(0) 
        for i, j in pairs(configurations.panel[k]) do table.insert(helperTable, j) end
    end
end

----------------------------------------------------------
---element functionality

function configurations.update()
    os.sleep(0)
    print("configurations.update(hard_reset)")
end

function configurations.setVisible(visible)
    generateHelperTable()
    for k, v in pairs(helperTable) do
        if v.setVisible then
            v.setVisible(visible) os.sleep(0)
        end
    end
end
function configurations.remove()
    generateHelperTable()
    if currentlyDisplayedConfigs["lm"] and currentlyDisplayedConfigs["lm"].index then
        saveConfigData("lm", "/home/programData/levelMaintainerConfig.data", currentlyDisplayedConfigs["lm"].index)
    end
    if currentlyDisplayedConfigs["mm"] and currentlyDisplayedConfigs["mm"].index then
        saveConfigData("mm", "/home/programData/machineManagerConfig.data", currentlyDisplayedConfigs["mm"].index)
    end
    if currentlyDisplayedConfigs["im"] and currentlyDisplayedConfigs["im"].index then
        saveConfigData("im", "/home/programData/itemManagerConfig.data", currentlyDisplayedConfigs["im"].index)
    end
    if currentlyDisplayedConfigs["gc"] and currentlyDisplayedConfigs["gc"].index then
        saveConfigData("gc", "/home/programData/generalConfig.data", currentlyDisplayedConfigs["gc"].index)
    end
    for k, v in pairs(helperTable) do
        if v.remove then
            v.remove() os.sleep(0)
        end
    end
end
function configurations.onClick(x, y, button)
    generateHelperTable()
    for k, v in pairs(helperTable) do
        if v.box and v.box.contains(x, y) and v.onClick then
            v.onClick(x, y, button) os.sleep(0)
            return
        elseif v.contains and v.contains(x, y) and v.onClick then
            v.onClick(x, y, button) os.sleep(0)
            return
        elseif v.option and v.option.box and v.option.box.contains(x, y) and v.onClick then
            v.onClick(x, y, button) os.sleep(0)
            return
        end
    end
end

----------------------------------------------------------

return configurations