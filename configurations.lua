---@diagnostic disable: unused-function
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local event = require("event")
local metricsDisplays = require("metricsDisplays")
local scrappad = require("scrappad")

local configurations = {}
configurations.panel = {}
local activeConfigs = {}
configurations.panel.lm = {}
configurations.panel.im = {}
configurations.panel.gc = {}
configurations.panel.mm = {}

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

local function saveConfigs()
    local tbl = gimpHelper.loadTable("/home/programData/levelMaintainerConfig.data")
    local derp = {}
    for k, v in pairs(activeConfigs.configurations.panel.lm.elements) do
        if v.option then
            derp[k] = v.option.getText()
        end
    end
    tbl[activeConfigs.configurations.panel.lm.index] = derp
    gimpHelper.saveTable(tbl, "/home/programData/levelMaintainerConfig.data")
    tbl = nil
    os.sleep(0)
    tbl = gimpHelper.loadTable("/home/programData/itemConfig.data")
    derp = {}
    for k, v in pairs(activeConfigs.configurations.panel.im.elements) do
        if v.option then
            derp[k] = v.option.getText()
        end
    end
    tbl[activeConfigs.configurations.panel.im.index] = derp
    gimpHelper.saveTable(tbl, "/home/programData/itemConfig.data")
    tbl = nil
    os.sleep(0)
    tbl = gimpHelper.loadTable("/home/programData/machineConfig.data")
    derp = {}
    for k, v in pairs(activeConfigs.configurations.panel.mm.elements) do
        if v.option then
            derp[k] = v.option.getText()
        end
    end
    tbl[activeConfigs.configurations.panel.mm.index] = derp
    gimpHelper.saveTable(tbl, "/home/programData/machineConfig.data")
    tbl = nil
    os.sleep(0)
    tbl = gimpHelper.loadTable("/home/programData/generalConfig.data")
    derp = {}
    for k, v in pairs(activeConfigs.configurations.panel.gc.elements) do
        if v.option then
            derp[k] = v.option.getText()
        end
    end
    tbl[activeConfigs.configurations.panel.gc.index] = derp
    gimpHelper.saveTable(tbl, "/home/programData/generalConfig.data")
    tbl = nil
    os.sleep(0)
end

local function loadConfig(_, path, index)
    local tbl = gimpHelper.loadTable(path)
    if not tbl then
        tbl = {}
    end
    os.sleep(0)
    if table[index] and table[index] ~= "placeholder" then
        for k, v in pairs(tbl[index].derp) do
            os.sleep(0)
            for i, j in pairs(activeConfigs) do
                for b, m in pairs(j.elements) do
                    os.sleep(0)
                    if b == k then
                        m.option.setText(v)
                    end
                end
            end
        end
    end
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

local function addIndex(_, path)
    local tbl = gimpHelper.loadTable(path)
    if not tbl then
        os.sleep(0)
        tbl = {}
    end
    table.insert(tbl, "placeholder")
    gimpHelper.saveTable(tbl, path)
end

----------------------------------------------------------
---event listeners

event.listen("add_index", addIndex)
event.listen("remove_index", removeIndex)
event.listen("config_change", saveConfigs)
event.listen("machine_named", stockPileData)
event.listen("load_config", loadConfig)

----------------------------------------------------------
---forward declarations

local generateHelperTable
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
    local tbl = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    if tbl and tbl[1] then
        displays.levelMaintainer = PagedWindow.new(tbl, 150, 30, {x1=25, x2=175, y1=85, y2=195}, 5,widgetsAreUs.levelMaintainer)
        displays.levelMaintainer:displayItems()
        for k, v in ipairs(displays.levelMaintainer.currentlyDisplayed) do
           displays.levelMaintainer.currentlyDisplayed[k] = widgetsAreUs.attachOnClick(v, function()
                configurations.createLevelMaintainerConfig(192, 80, k)
            end)
        end
    end
    tbl = nil
    os.sleep(0)
    tbl = gimpHelper.loadTable("/home/programData/monitoredItems")
    if tbl and tbl[1] then
        displays.itemManager = PagedWindow.new(tbl, 120, 40, {x1=390, x2=540, y1=65, y2=305}, 5, widgetsAreUs.itemBox)
        displays.itemManager:displayItems()
    end
    tbl = nil
    os.sleep(0)
    tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
    if tbl and tbl[1] then
        displays.machineManager = PagedWindow.new(tbl, 150, 30, {x1=45, x2=295, y1=320, y2=460}, 5, metricsDisplays.machine.create)
        displays.machineManager:displayItems()
    end
    tbl = nil
end

function configurations.init()
    local success, error = pcall(configurations.initBoxes)
    if not success then print(error) end

    local success, error = pcall(configurations.initButtons)
    if not success then print(error) end 

    os.sleep(0)

    local success, error = pcall(configurations.initDisplays)
    if not success then print(error) end

    generateHelperTable()
end

----------------------------------------------------------
---configs factory

local function removeConfig(activeConfigsIndex)
    for k, v in pairs(activeConfigs[activeConfigsIndex].elements) do
        if v.remove then
            v.remove()
        end
    end
    activeConfigs[activeConfigsIndex].elements = nil
end

function configurations.createLevelMaintainerConfig(x, y, index)
    pcall(removeConfig, "lm")
    configurations.panel.lm = {}
    configurations.panel.lm.priority = scrappad.numberBox(x, y, "priority", "Priority:")
    configurations.panel.lm.maxInstances = scrappad.numberBox(x + 80, y, "maxCrafters", "Max Conc:")

    configurations.panel.lm.minCPU = scrappad.numberBox(x, y+30, "minCpu", "Min CPU:")
    configurations.panel.lm.maxCPU = scrappad.numberBox(x+80, y+30, "maxCpu", "Max CPU:")

    os.sleep(0)
    --[[
    configurations.panel.lm.alertStalled = widgetsAreUs.configCheck(x+100, y+105)
    configurations.panel.lm.alertStalledName = widgetsAreUs.text(x+5, y+105, "Alert Stalled", 1.3)
    configurations.panel.lm.alertResources = widgetsAreUs.configCheck(x+100, y+130, index)
    os.sleep(0)
    configurations.panel.lm.alertResourcesName = widgetsAreUs.text(x+5, y+130, "Alert Can't Craft", 1.3)
    ]]
    activeConfigs["lm"] = {index = index, elements = configurations.panel.lm}
end

function configurations.createMachineManagerConfig(x, y, tbl, index)
    pcall(removeConfig, "mm")
    --[[
    configurations.panel.mm = {}
    configurations.panel.mm.name = widgetsAreUs.configSingleString(335, 310, 90, "Name")
    configurations.panel.mm.name.option.setText(tbl.newName)
    configurations.panel.mm.group = widgetsAreUs.configSingleString(355, 335, 90, "Group")
    os.sleep(0)
    configurations.panel.mm.group.option.setText(tbl.groupName)
    configurations.panel.mm.autoTurnOn = widgetsAreUs.configSingleString(355, 360, 120, "Auto On Min")
    configurations.panel.mm.autoTurnOff = widgetsAreUs.configSingleString(480, 360, 120, "Auto Off Min")
    configurations.panel.mm.alertIdle = widgetsAreUs.configSingleString(355, 385, 120, "Alert Idle Min")
    configurations.panel.mm.alertDisabled = widgetsAreUs.configCheck(455, 410, index)
    configurations.panel.mm.alertDisabledName = widgetsAreUs.text(355, 410, "Alert Disabled", 1.3)
    configurations.panel.mm.alertEnabled = widgetsAreUs.configCheck(555, 435, index)
    os.sleep(0)
    configurations.panel.mm.alertEnabledName = widgetsAreUs.text(460, 435, "Alert Enabled", 1.3)
    configurations.panel.mm.trackMetrics = widgetsAreUs.configCheck(455, 460, index)
    configurations.panel.mm.trackMetricsName = widgetsAreUs.text(355, 460, "Track Metrics", 1.3)
    configurations.panel.mm.xyz = tbl.xyz
]]
    activeConfigs["mm"] = {index = index, elements = configurations.panel.mm}
end

local function createGeneralConfig()
    --[[
    configurations.panel.gc.showHelp = widgetsAreUs.configCheck(590, 320, 99)
    configurations.panel.gc.showHelpName = widgetsAreUs.text(525, 320, "Show Help", 1.3)
    configurations.panel.gc.ResetHUD = widgetsAreUs.configCheck(650, 345, 99)
    configurations.panel.gc.screenSize = widgetsAreUs.textBox(525, 345, 75, 25, "Set Screen Dim")
    configurations.panel.gc.screenSizeWidth = widgetsAreUs.textBox(600, 345, 40, 25, "click set")
    configurations.panel.gc.screenSizeHeight = widgetsAreUs.textBox(670, 345, 40, 25, "click set")
    os.sleep(0)
    configurations.panel.gc.highlightDisabled = widgetsAreUs.configCheck(600, 370, 99)
    configurations.panel.gc.highlightDisabledName = widgetsAreUs.text(525, 370, "Highlight Disabled", 1.3)
    configurations.panel.gc.maintenanceBeacons = widgetsAreUs.configCheck(700, 395, 99)
    configurations.panel.gc.maintenanceBeaconsName = widgetsAreUs.text(625, 395, "Maintenance Beacons", 1.3)
    configurations.panel.gc.spazIntensity = widgetsAreUs.configSingleString(525, 420, 80, "SPAZ Intensity", 99)
    configurations.panel.gc.alertDisconnected = widgetsAreUs.configCheck(720, 445, 99, "alertDisconnected")
    os.sleep(0)
    configurations.panel.gc.alertDisconnectedName = widgetsAreUs.text(630, 445, "Disconnected", 1.3)
    configurations.panel.gc.alertReconnected = widgetsAreUs.configCheck(610, 445, 99, "alertReconnected")
    configurations.panel.gc.alertReconnectedName = widgetsAreUs.text(525, 445, "Connected", 1.3)
    --**************MaxGlobalCPU usage for level maintainers needs to be set88888888**************
]]
    activeConfigs["gc"] = {index = 1, elements = configurations.panel.gc}
end

----------------------------------------------------------
---got tired of typing everything 10,000 times

local helperTable = {}

generateHelperTable = function()
    helperTable = {}
    for k, v in pairs(boxes) do
        os.sleep(0)
        table.insert(helperTable, v)
    end
    for k, v in pairs(buttons) do
        os.sleep(0)
        table.insert(helperTable, v)
    end
    for k, v in pairs(displays) do
        os.sleep(0)
        for i, j in pairs(v.currentlyDisplayed) do
            table.insert(helperTable, j)
        end
    end
    for k, v in pairs(configurations.panel.gc) do
        os.sleep(0)
        table.insert(helperTable, v)
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
            v.setVisible(visible)
            os.sleep(0)
        end
    end
    for k, v in pairs(activeConfigs) do
        for i, j in pairs(v.elements) do
            if j.setVisible then
                j.setVisible(visible)
            end
        end
    end
end
function configurations.remove()
    generateHelperTable()
    for k, v in pairs(helperTable) do
        if v.remove then
            v.remove()
            os.sleep(0)
        end
    end
    for k, v in pairs(activeConfigs) do
        for i, j in pairs(v.elements) do
            if j.remove then
                j.remove()
            end
        end
    end
end
function configurations.onClick(x, y, button)
    generateHelperTable()
    for k, v in pairs(helperTable) do
        if v.box and v.box.contains(x, y) and v.onClick then
            v.onClick(x, y, button)
            os.sleep(0)
            return
        elseif v.contains and v.contains(x, y) and v.onClick then
            v.onClick(x, y, button)
            os.sleep(0)
            return
        end
    end
    for k, v in pairs(configurations.panel) do
        for i, j in pairs(configurations.panel[k]) do
            if j.contains and j.contains(x, y) and j.onClick then
                j.onClick(x, y, button)
            elseif j.box and widgetsAreUs.isPointInBox(x, y, j.box) and j.onClick then
                j.onClick(x, y, button)
            end
        end
    end
end

----------------------------------------------------------

return configurations