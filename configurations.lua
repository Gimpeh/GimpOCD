---@diagnostic disable: unused-function
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local event = require("event")
local itemElements = require("itemElements")
local metricsDisplays = require("metricsDisplays")

local configurations = {}

----------------------------------------------------------

local function stockPileData(_, config)
    local tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
    if not tbl then
        tbl = {}
    end
    if tbl[1] then
        for k, v in ipairs(tbl) do
            if v.xyz.x == config.xyz.x and v.xyz.y == config.xyz.y and v.xyz.z == config.xyz.z then
                table.remove(tbl, k)
            end
        end
    end
    table.insert(tbl, config)
    gimpHelper.saveTable(tbl, "/home/programData/machinesNamed.data")
end


event.listen("machine_named", stockPileData)

----------------------------------------------------------

local boxes = {}
local buttons = {}
local displays = {}

function configurations.initBoxes()
    boxes.background = widgetsAreUs.createBox(10, 70, 700, 430, {0.2, 0.2, 0.2}, 0.5)
    boxes.levelMaintainer = widgetsAreUs.createBox(20, 80, 160, 200, {0.6, 1, 0.6}, 1)
    boxes.levelMaintainerConfig = widgetsAreUs.createBox(192, 80, 160, 200, {1, 1, 1}, 1)
    boxes.itemManager = widgetsAreUs.createBox(385, 60, 160, 240, {1, 1, 0.6}, 1)
    boxes.machineManager = widgetsAreUs.createBox(35, 310, 290, 150, {0.6, 0.6, 1}, 1)
    boxes.machineManagerConfig = widgetsAreUs.createBox(355, 310, 160, 160, {255, 255, 255}, 1)
    boxes.generalConfig = widgetsAreUs.createBox(520, 310, 230, 160, {255, 255, 255}, 1)
    boxes.itemMangerConfig = widgetsAreUs.createBox(580, 80, 160, 200, {255, 255, 255}, 1)
end

function configurations.initButtons()
    buttons.levelMaintainerPrev = widgetsAreUs.symbolBox(85, 58, "^")
    buttons.levelMaintainerNext = widgetsAreUs.symbolBox(85, 283, "v")
    buttons.itemManagerPrev = widgetsAreUs.symbolBox(363, 160, "<")
    buttons.itemManagerNext = widgetsAreUs.symbolBox(548, 160, ">")
    buttons.machineManagerPrev = widgetsAreUs.symbolBox(8, 378, "<")
    buttons.machineManagerNext = widgetsAreUs.symbolBox(328, 378, ">")
end

function configurations.initDisplays()
    local tbl = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    displays.levelMaintainer = PagedWindow.new(tbl, 150, 30, {x1=25, x2=175, y1=85, y2=195}, 5, widgetsAreUs.levelMaintainerOptions)
    displays.levelMaintainer:displayItems()
    tbl = nil

    tbl = gimpHelper.loadTable("/home/programData/monitoredItems")
    displays.itemManager = PagedWindow.new(tbl, 120, 30, {x1=390, x2=540, y1=65, y2=305}, 5, itemElements.itemBox.itemOptions)
    displays.itemManager:displayItems()
    tbl = nil

    tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
    displays.machineManager = PagedWindow.new(tbl, 150, 30, {x1=45, x2=295, y1=320, y2=460}, 5, metricsDisplays.machine.machineConfig)
    displays.machineManager:displayItems()
    tbl = nil
end

function configurations.init()
    configurations.initBoxes()
    configurations.initButtons()
    configurations.initDisplays()
end

----------------------------------------------------------

local function createLevelMaintainerConfig(x, y, index)
    local lm = {}
    lm.priority = widgetsAreUs.configSingleString(x+5, y+5, 50, "Priority", index)

    lm.minCPU = widgetsAreUs.configSingleString(x+5, y+30, 60, "Min CPU", index)
    lm.maxCPU = widgetsAreUs.configSingleString(x+70, y+30, 60, "Max CPU", index)

    lm.maxInstances = widgetsAreUs.configSingleString(x+5, y+55, 80, "Max Instances", index)
 
    lm.alertBelow = widgetsAreUs.configSingleString(x+5, y+80, 80, "Alert Below", index)
    lm.alertStalled = widgetsAreUs.configCheck(x+100, y+105, index)
    lm.alertStalledName = widgetsAreUs.staticText(x+5, y+105, "Alert Stalled", 1.3)
    lm.alertResources = widgetsAreUs.configCheck(x+100, y+130, index)
    lm.alertResourcesName = widgetsAreUs.staticText(x+5, y+130, "Alert Can't Craft", 1.3)

    return lm, index
end

local function createItemManagerConfig(x, y, index)
    local im = {}
    im.alertAbove = widgetsAreUs.configSingleString(390, 310, 80, "Alert Above", index)
    im.alertBelow = widgetsAreUs.configSingleString(390, 335, 80, "Alert Below", index)
    im.showOnHUD = widgetsAreUs.configCheck(470, 360, index)
    im.showOnHudName = widgetsAreUs.staticText(390, 360, "Show on HUD", 1.3)
    im.trackMetrics = widgetsAreUs.configCheck(470, 385, index)
    im.trackMetricsName = widgetsAreUs.staticText(390, 385, "Track Metrics", 1.3)

    return im, index
end

local function createMachineManagerConfig(x, y, tbl, index)
    local mm = {}
    mm.name = widgetsAreUs.configSingleString(335, 310, 90, "Name", index)
    mm.name.option.setText(tbl.newName) 
    mm.group = widgetsAreUs.configSingleString(355, 335, 90, "Group", index)
    mm.group.option.setText(tbl.groupName)
    mm.autoTurnOn = widgetsAreUs.configSingleString(355, 360, 120, "Auto On Min", index)
    mm.autoTurnOff = widgetsAreUs.configSingleString(480, 360, 120, "Auto Off Min", index)
    mm.alertIdle = widgetsAreUs.configSingleString(355, 385, 120, "Alert Idle Min", index)
    mm.alertDisabled = widgetsAreUs.configCheck(455, 410, index)
    mm.alertDisabledName = widgetsAreUs.staticText(355, 410, "Alert Disabled", 1.3)
    mm.alertEnabled = widgetsAreUs.configCheck(555, 435, index)
    mm.alertEnabledName = widgetsAreUs.staticText(460, 435, "Alert Enabled", 1.3)
    mm.trackMetrics = widgetsAreUs.configCheck(455, 460, index)
    mm.trackMetricsName = widgetsAreUs.staticText(355, 460, "Track Metrics", 1.3)
    mm.xyz = tbl.xyz
    return mm, index
end

local function createGeneralConfig()
    local gc = {}
    gc.showHelp = widgetsAreUs.configCheck(590, 320, 99)
    gc.showHelpName = widgetsAreUs.staticText(525, 320, "Show Help", 1.3)
    gc.ResetHUD = widgetsAreUs.configCheck(650, 345, 99)
    gc.screenSize = widgetsAreUs.textBox(525, 345, 75, 25, "Set Screen Dim")
    gc.screenSizeWidth = widgetsAreUs.textBox(600, 345, 40, 25, "click set")
    gc.screenSizeHeight = widgetsAreUs.textBox(670, 345, 40, 25, "click set")
    gc.highlightDisabled = widgetsAreUs.configCheck(600, 370, 99)
    gc.highlightDisabledName = widgetsAreUs.staticText(525, 370, "Highlight Disabled", 1.3)
    gc.maintenanceBeacons = widgetsAreUs.configCheck(700, 395, 99)
    gc.maintenanceBeaconsName = widgetsAreUs.staticText(625, 395, "Maintenance Beacons", 1.3)
    gc.spazIntensity = widgetsAreUs.configSingleString(525, 420, 80, "SPAZ Intensity", 99)
    gc.alertDisconnected = widgetsAreUs.configCheck(720, 445, 99)
    gc.alertDisconnectedName = widgetsAreUs.staticText(630, 445, "Disconnected", 1.3)
    gc.alertReconnected = widgetsAreUs.configCheck(610, 445, 99)
    gc.alertReconnectedName = widgetsAreUs.staticText(525, 445, "Connected", 1.3)
    --[[
        Alert when no crafting progress in this amount of time
    ]]
    return gc
end

return configurations