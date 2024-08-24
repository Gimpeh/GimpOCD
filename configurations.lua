local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local event = require("event")
local s = require("serialization")

----------------------------------------------------------
---event handlers

local function stockPileData(derp, machineValues)
    print("Line 10: stockPileData called with derp =", derp, "and machineValues =", machineValues)
    local success, err = pcall(function()
        print("Line 12: Inside pcall of stockPileData")
        local tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
        if not tbl then
            os.sleep(0)
            tbl = {}
        end
        if tbl[1] then
            for k, v in ipairs(tbl) do
                os.sleep(0)
                if v.xyz.x == machineValues.xyz.x and v.xyz.y == machineValues.xyz.y and v.xyz.z == machineValues.xyz.z then
                    print("Line 23: Removing item from table at index", k)
                    table.remove(tbl, k)
                end
            end
        end
        print("Line 27: Inserting machineValues into table")
        table.insert(tbl, machineValues)
        gimpHelper.saveTable(tbl, "/home/programData/machinesNamed.data")
        os.sleep(0)
    end)
    if not success then
        print("Error in stockPileData: " .. err)
    end
end

local function removeIndex(_, path, index)
    print("Line 36: removeIndex called with path =", path, "and index =", index)
    local success, err = pcall(function()
        print("Line 38: Inside pcall of removeIndex")
        local tbl = gimpHelper.loadTable(path)
        if not tbl then
            tbl = {}
        end
        os.sleep(0)
        if tbl[index] then
            print("Line 44: Removing item from table at index", index)
            table.remove(tbl, index)
        end
        gimpHelper.saveTable(tbl, path)
        os.sleep(0)
    end)
    if not success then
        print("Error in removeIndex: " .. err)
    end
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
---initialization

function configurations.initBoxes()
    print("Line 66: Initializing boxes")
    local success, err = pcall(function()
        boxes.background = widgetsAreUs.createBox(10, 50, 750, 400, {0.2, 0.2, 0.2}, 0.8)
        boxes.levelMaintainer = widgetsAreUs.createBox(20, 80, 160, 200, {0.6, 1, 0.6}, 1)
        boxes.levelMaintainerConfig = widgetsAreUs.createBox(192, 80, 160, 200, {1, 1, 1}, 1)
        boxes.itemManager = widgetsAreUs.createBox(385, 60, 160, 240, {1, 1, 0.6}, 1)
        boxes.machineManager = widgetsAreUs.createBox(35, 310, 290, 150, {0.6, 0.6, 1}, 1)
        boxes.machineManagerConfig = widgetsAreUs.createBox(355, 310, 160, 160, {255, 255, 255}, 1)
        boxes.generalConfig = widgetsAreUs.createBox(520, 310, 230, 160, {255, 255, 255}, 1)
        boxes.itemMangerConfig = widgetsAreUs.createBox(580, 80, 160, 200, {255, 255, 255}, 1)
        os.sleep(0)
    end)
    if not success then
        print("Error in configurations.initBoxes: " .. err)
    end
end

function configurations.initButtons()
    print("Line 86: Initializing buttons")
    local success, err = pcall(function()
        buttons.levelMaintainerPrev = widgetsAreUs.symbolBox(85, 58, "^", nil, function()
            displays.levelMaintainer:prevPage()
        end)
        buttons.levelMaintainerNext = widgetsAreUs.symbolBox(85, 283, "v", nil, function()
            displays.levelMaintainer:nextPage()
        end)
        buttons.itemManagerPrev = widgetsAreUs.symbolBox(363, 160, "<", nil, function()
            displays.itemManager:prevPage()
        end)
        buttons.itemManagerNext = widgetsAreUs.symbolBox(548, 160, ">", nil, function()
            displays.itemManager:nextPage()
        end)
        buttons.machineManagerPrev = widgetsAreUs.symbolBox(8, 378, "<", nil, function()
            displays.machineManager:prevPage()
        end)
        buttons.machineManagerNext = widgetsAreUs.symbolBox(328, 378, ">", nil, function()
            displays.machineManager:nextPage()
        end)
        os.sleep(0)
    end)
    if not success then
        print("Error in configurations.initButtons: " .. err)
    end
end

function configurations.initDisplays()
    print("Line 108: Initializing displays")
    local success, err = pcall(function()
        local function loadAndDisplayTable(path, width, height, coords, callback, widget)
            print("Line 112: loadAndDisplayTable called with path =", path)
            local tbl = gimpHelper.loadTable(path)
            local display = nil
            if tbl and tbl[1] then
                display = PagedWindow.new(tbl, width, height, coords, 5, widget)
                display:displayItems()
                for k, v in ipairs(display.currentlyDisplayed) do
                    local index = k
                    display.currentlyDisplayed[k] = widgetsAreUs.attachOnClick(v, function()
                        callback(index)
                    end)
                end
            end
            tbl = nil
            os.sleep(0)
            return display
        end

        displays.levelMaintainer = loadAndDisplayTable("/home/programData/levelMaintainer.data", 150, 30, {x1=25, x2=175, y1=85, y2=195}, function(index)
            print("Line 127: levelMaintainer callback called with index =", index)
            configurations.createLevelMaintainerConfig(192, 80, index)
        end, widgetsAreUs.levelMaintainer)

        displays.itemManager = loadAndDisplayTable("/home/programData/monitoredItems", 120, 40, {x1=390, x2=540, y1=65, y2=305}, function(index)
            print("Line 131: itemManager callback called with index =", index)
            configurations.createItemManagerConfig(580, 80, index)
        end, widgetsAreUs.itemBox)

        displays.machineManager = loadAndDisplayTable("/home/programData/machinesNamed.data", 120, 34, {x1=45, x2=295, y1=320, y2=460}, function(index)
            print("Line 135: machineManager callback called with index =", index)
            configurations.createMachineManagerConfig(355, 310, index)
        end, widgetsAreUs.machineElementConfigEdition)
    end)
    if not success then
        print("Error in configurations.initDisplays: " .. err)
    end
end

function configurations.init()
    print("Line 141: Initializing configurations")
    local success, error = pcall(configurations.initBoxes)
    if not success then print("Error in configurations.initBoxes: " .. error) end

    success, error = pcall(configurations.initButtons)
    if not success then print("Error in configurations.initButtons: " .. error) end

    success, error = pcall(configurations.initDisplays)
    if not success then print("Error in configurations.initDisplays: " .. error) end

    success, error = pcall(function ()
        print("Line 150: Creating general config and generating helper table")
        createGeneralConfig(525, 320, 1)
        generateHelperTable()
    end)
    if not success then print("Error in configurations.init: " .. error) end
end

----------------------------------------------------------
---configs factory

local function removeConfigDisplay(activeConfigsIndex)
    print("Line 160: removeConfigDisplay called with activeConfigsIndex =", activeConfigsIndex)
    local success, err = pcall(function()
        for k, v in pairs(currentlyDisplayedConfigs[activeConfigsIndex].elements) do
            if v.remove then
                local success_remove, error_remove = pcall(v.remove)
                if not success_remove then print("Error removing element: " .. error_remove) end
            end
        end
        currentlyDisplayedConfigs[activeConfigsIndex].elements = nil
    end)
    if not success then
        print("Error in removeConfigDisplay: " .. err)
    end
end

saveConfigData = function(activeConfigsConfigKey, path, activeConfigsIndex)
    print("Line 214: saveConfigData called with activeConfigsConfigKey =", activeConfigsConfigKey, "path =", path, "activeConfigsIndex =", activeConfigsIndex)

    local success, err = pcall(function()
        print("Line 216: Entering pcall block")
        print("Line 217: activeConfigsConfigKey =", activeConfigsConfigKey, "path =", path, "activeConfigsIndex =", activeConfigsIndex)

        local tbl = gimpHelper.loadTable(path)
        print("Line 220: Loaded tbl from gimpHelper.loadTable(path) =", s.serialize(tbl))

        if not tbl then
            print("Line 222: tbl is nil, initializing as empty table")
            tbl = {}
        end

        local derp = {}
        print("Line 225: Initialized empty table derp =", s.serialize(derp))

        for k, v in pairs(currentlyDisplayedConfigs[activeConfigsConfigKey].elements) do
            print("Line 227: Iterating currentlyDisplayedConfigs elements, k =", k, "v =", s.serialize(v))

            if v.getValue then
                local value = tostring(v.getValue())
                print("Line 229: v.getValue() =", value)

                if value ~= "num" and value ~= "string" then
                    print("Line 231: Saving config for k =", k, "v.key =", v.key, "v.getValue() =", value)
                    derp[v.key] = value
                else
                    print("Line 233: Skipping save for k =", k, "v.key =", v.key, "v.getValue() =", value)
                end
            else
                print("Line 235: v.getValue is nil for k =", k)
            end
        end

        tbl[activeConfigsIndex] = derp
        print("Line 238: Updated tbl[activeConfigsIndex] =", s.serialize(tbl[activeConfigsIndex]))

        print("Line 240: Saving updated table to path =", path)
        gimpHelper.saveTable(tbl, path)
        print("Line 242: Table saved successfully")

    end)

    if not success then
        print("Error in saveConfigData: " .. err)
    else
        print("Line 245: saveConfigData completed successfully")
    end
end

loadConfigData = function(currentlyDisplayedConfigsRef, path, configIndex)
    print("Line 236: loadConfigData called with currentlyDisplayedConfigsRef =", currentlyDisplayedConfigsRef, "path =", path, "configIndex =", configIndex)
    -- local success, err = pcall(function()
        print("Line 238: Entering pcall block")
        print("Line 239: currentlyDisplayedConfigsRef =", currentlyDisplayedConfigsRef, "path =", path, "configIndex =", configIndex)

        local tbl = gimpHelper.loadTable(path)
        print("Line 242: tbl loaded from gimpHelper.loadTable(path) =", tbl)

        if tbl and tbl[configIndex] then
            print("Line 244: tbl and tbl[configIndex] are valid")
            for k, v in pairs(currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements) do
                print("Line 246: Iterating currentlyDisplayedConfigs elements, k =", k, "v =", v)
                for i, j in pairs(tbl[configIndex]) do
                    print("Line 248: Iterating tbl[configIndex], i =", i, "j =", j)

                    if v.key and v.key == i then
                        print("Line 250: Found matching key in currentlyDisplayedConfigs element, key =", v.key)

                        if j and tostring(j) == "true" then
                            print("Line 252: j is 'true', setting value to 'X'")
                            currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue("X")
                        elseif j and tostring(j) == "false" then
                            print("Line 254: j is 'false', setting value to ' ' (space)")
                            currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue(" ")
                        elseif j then
                            print("Line 256: j has a different value, setting value to j =", j)
                            currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue(j)
                        else
                            print("Line 258: j is nil or false")
                        end
                    else
                        print("Line 260: No matching key found or v.key is nil")
                    end
                end
            end
        else
            print("Line 263: tbl or tbl[configIndex] is nil or false")
        end
    --end)

    if not success then
        print("Error in loadConfigData: " .. err)
    else
        print("Line 267: loadConfigData completed successfully")
    end
end

function configurations.createLevelMaintainerConfig(x, y, index)
    print("Line 217: createLevelMaintainerConfig called with x =", x, "y =", y, "index =", index)
    local success, err = pcall(function()
        if currentlyDisplayedConfigs["lm"] and currentlyDisplayedConfigs["lm"].index then
            local success_save, error_save = pcall(saveConfigData, "lm", "/home/programData/levelMaintainerConfig.data", currentlyDisplayedConfigs["lm"].index)
            if not success_save then print("Error saving config data: " .. error_save) end

            local success_remove, error_remove = pcall(removeConfigDisplay, "lm")
            if not success_remove then print("Error removing config display: " .. error_remove) end
        end
        configurations.panel.lm = {}
        configurations.panel.lm.priority = widgetsAreUs.numberBox(x, y, "priority", "Priority:")
        configurations.panel.lm.maxInstances = widgetsAreUs.numberBox(x + 80, y, "maxCrafters", "Max Conc:")
        configurations.panel.lm.minCPU = widgetsAreUs.numberBox(x, y+30, "minCpu", "Min CPU")
        configurations.panel.lm.minCpuTitle2 = widgetsAreUs.text(x+5, y+45, "Available:", 0.9)
        configurations.panel.lm.maxCPU = widgetsAreUs.numberBox(x+80, y+30, "maxCpu", "Max CPU")
        configurations.panel.lm.maxCpuTitle2 = widgetsAreUs.text(x+90, y+45, "Usage:", 1)
        configurations.panel.lm.alertStalled = widgetsAreUs.checkboxFullLine(x, y+60, "alertStalled", "Alert Stalled")
        configurations.panel.lm.alertResources = widgetsAreUs.checkboxFullLine(x, y+90, "alertResources", "Alert Can't Craft")
        os.sleep(0)

        currentlyDisplayedConfigs["lm"] = {index = index, elements = configurations.panel.lm}
        local success_load, error_load = pcall(loadConfigData, "lm", "/home/programData/levelMaintainerConfig.data", index)
        if not success_load then print("Error loading config data: " .. error_load) end
    end)
    if not success then
        print("Error in configurations.createLevelMaintainerConfig: " .. err)
    end
end

function configurations.createMachineManagerConfig(x, y, index)
    print("Line 248: createMachineManagerConfig called with x =", x, "y =", y, "index =", index)
    local success, err = pcall(function()
        if currentlyDisplayedConfigs["mm"] and currentlyDisplayedConfigs["mm"].index then
            local success_save, error_save = pcall(saveConfigData, "mm", "/home/programData/machineManagerConfig.data", currentlyDisplayedConfigs["mm"].index)
            if not success_save then print("Error saving config data: " .. error_save) end

            local success_remove, error_remove = pcall(removeConfigDisplay, "mm")
            if not success_remove then print("Error removing config display: " .. error_remove) end
        end
        configurations.panel.mm = {}
        configurations.panel.mm.name = widgetsAreUs.textBoxWithTitle(x, y, "name", "Name")
        configurations.panel.mm.group = widgetsAreUs.textBoxWithTitle(x, y+30, "group", "Group") os.sleep(0)
        configurations.panel.mm.autoTurnOn = widgetsAreUs.numberBox(x, y+60, "autoTurnOn", "Auto On")
        configurations.panel.mm.autoTurnOff = widgetsAreUs.numberBox(x+80, y+60, "autoTurnOff", "Auto Off")
        configurations.panel.mm.alertIdle = widgetsAreUs.longerNumberBox(x, y+90, "alertIdle", "A: Idle Timer")
        configurations.panel.mm.alertDisabled = widgetsAreUs.checkBoxHalf(x, y+120, "alertDisabled", "A: Disabled")
        configurations.panel.mm.alertEnabled = widgetsAreUs.checkBoxHalf(x+80, y+120, "alertEnabled", "A: Enabled")
        currentlyDisplayedConfigs["mm"] = {index = index, elements = configurations.panel.mm}
        local success_load, error_load = pcall(loadConfigData, "mm", "/home/programData/machineManagerConfig.data", index)
        if not success_load then print("Error loading config data: " .. error_load) end
    end)
    if not success then
        print("Error in configurations.createMachineManagerConfig: " .. err)
    end
end

function configurations.createItemManagerConfig(x, y, index)
    print("Line 276: createItemManagerConfig called with x =", x, "y =", y, "index =", index)
    local success, err = pcall(function()
        if currentlyDisplayedConfigs["im"] and currentlyDisplayedConfigs["im"].index then
            local success_save, error_save = pcall(saveConfigData, "im", "/home/programData/itemManagerConfig.data", currentlyDisplayedConfigs["im"].index)
            if not success_save then print("Error saving config data: " .. error_save) end

            local success_remove, error_remove = pcall(removeConfigDisplay, "im")
            if not success_remove then print("Error removing config display: " .. error_remove) end
        end
        configurations.panel.im = {}
        configurations.panel.im.alertAbove = widgetsAreUs.longerNumberBox(x, y, "alertAbove", "Alert Above")
        configurations.panel.im.alertBelow = widgetsAreUs.longerNumberBox(x, y+30, "alertBelow", "Alert Below")
        configurations.panel.im.showOnHud = widgetsAreUs.checkboxFullLine(x, y+60, "showOnHud", "Show On HUD")
        --configurations.panel.im.monitorMetrics = widgetsAreUs.checkboxFullLine(x, y+90, "monitorMetrics", "Monitor Metrics on Slave")
        currentlyDisplayedConfigs["im"] = {index = index, elements = configurations.panel.im}
        local success_load, error_load = pcall(loadConfigData, "im", "/home/programData/itemManagerConfig.data", index)
        if not success_load then print("Error loading config data: " .. error_load) end
    end)
    if not success then
        print("Error in configurations.createItemManagerConfig: " .. err)
    end
end

createGeneralConfig = function(x, y)
    print("Line 301: createGeneralConfig called with x =", x, "y =", y)
    local success, err = pcall(function()
        configurations.panel.gc = {}
        configurations.panel.gc.showHelp = widgetsAreUs.checkBoxHalf(x, y, "showHelp", "Show Help")
        configurations.panel.gc.resetHud = widgetsAreUs.configsButtonHalf(x+80, y, "Reset HUD", "Reset", {0.8, 0, 0}, function()
            event.push("reset_hud")
        end)
        os.sleep(0)
        configurations.panel.gc.highlightDisabled = widgetsAreUs.checkboxFullLine(x, y+30, "highlightDisabled", "Highlight Disabled Mach's")
        configurations.panel.gc.maintenanceBeacons = widgetsAreUs.checkboxFullLine(x, y+60, "maintenanceBeacons", "Maintenance Beacons")
        configurations.panel.gc.alertDisconnected = widgetsAreUs.checkboxFullLine(x, y+90, "alertDisconnectedReconnected", "Alert DC'd/Reconnected")
        configurations.panel.gc.maxCpusAllLevelMaintainers = widgetsAreUs.numberBoxLongerText(x, y+120, "maxCpusAllLevelMaintainers", "Max CPUs for Maintainers")
        currentlyDisplayedConfigs["gc"] = {index = 1, elements = configurations.panel.gc}
        local success_load, error_load = pcall(loadConfigData, "gc", "/home/programData/generalConfig.data", 1)
        if not success_load then print("Error loading general config data: " .. error_load) end
    end)
    if not success then
        print("Error in createGeneralConfig: " .. err)
    end
end

----------------------------------------------------------
---got tired of typing everything 10,000 times

local helperTable = {}

generateHelperTable = function()
    print("Line 326: generateHelperTable called")
    local success, err = pcall(function()
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
            for i, j in ipairs(displays[k].currentlyDisplayed) do
                table.insert(helperTable, displays[k].currentlyDisplayed[i])
            end
        end
        for k, v in pairs(configurations.panel) do
            os.sleep(0)
            for i, j in pairs(configurations.panel[k]) do
                table.insert(helperTable, configurations.panel[k][i])
            end
        end
    end)
    if not success then
        print("Error in generateHelperTable: " .. err)
    end
end

----------------------------------------------------------
---element functionality

function configurations.update()
    print("Line 347: configurations.update called")
    local success, err = pcall(function()
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
    end)
    if not success then
        print("Error in configurations.update: " .. err)
    end
end

function configurations.setVisible(visible)
    print("Line 364: configurations.setVisible called with visible =", visible)
    local success, err = pcall(function()
        generateHelperTable()
        for k, v in pairs(helperTable) do
            if v.setVisible then
                v.setVisible(visible)
                os.sleep(0)
            end
        end
    end)
    if not success then
        print("Error in configurations.setVisible: " .. err)
    end
end

function configurations.remove()
    print("Line 376: configurations.remove called")
    local success, err = pcall(function()
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
                v.remove()
                os.sleep(0)
            end
        end
    end)
    if not success then
        print("Error in configurations.remove: " .. err)
    end
end

function configurations.onClick(x, y, button)
    print("Line 402: configurations.onClick called with x =", x, "y =", y, "button =", button)
    local success, err = pcall(function()
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
            elseif v.option and v.option.box and v.option.box.contains(x, y) and v.onClick then
                v.onClick(x, y, button)
                os.sleep(0)
                return
            end
        end
    end)
    if not success then
        print("Error in configurations.onClick: " .. err)
    end
end

----------------------------------------------------------

return configurations