local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local PagedWindow = require("PagedWindow")
local event = require("event")
local s = require("serialization")
local c = require("gimp_colors")

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end

----------------------------------------------------------
---event handlers

local function stockPileData(derp, machineValues, xyz)
    print("configurations - Line 10: stockPileData called with derp =", tostring(derp), "and machineValues =", s.serialize(machineValues))
    local success, err = pcall(function()
        print("configurations - Line 12: Inside pcall of stockPileData")
        machineValues.xyz = xyz
        local tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
        if not tbl then
            os.sleep(0)
            tbl = {}
        end
        if tbl[1] then
            for k, v in ipairs(tbl) do
                os.sleep(0)
                if v.xyz.x == machineValues.xyz.x and v.xyz.y == machineValues.xyz.y and v.xyz.z == machineValues.xyz.z then
                    print("configurations - Line 23: Removing item from table at index", tostring(k))
                    table.remove(tbl, k)
                end
            end
        end
        print("configurations - Line 27: Inserting machineValues into table")
        table.insert(tbl, machineValues)
        gimpHelper.saveTable(tbl, "/home/programData/machinesNamed.data")
        os.sleep(0)
    end)
    if not success then
        print("configurations - Error in stockPileData: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

local function removeIndex(_, path, index)
    print("configurations - Line 36: removeIndex called with path =", tostring(path), "and index =", tostring(index))
    local success, err = pcall(function()
        print("configurations - Line 38: Inside pcall of removeIndex")
        local tbl = gimpHelper.loadTable(path)
        if not tbl then
            tbl = {}
        end
        os.sleep(0)
        if tbl[index] then
            print("configurations - Line 44: Removing item from table at index", tostring(index))
            table.remove(tbl, index)
        end
        gimpHelper.saveTable(tbl, path)
        os.sleep(0)
    end)
    if not success then
        print("configurations - Error in removeIndex: " .. tostring(err))
    end
    print("") -- Blank line after function execution
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
    print("configurations - Line 66: Initializing boxes")
    local success, err = pcall(function()
        boxes.background = widgetsAreUs.createBox(10, 50, 750, 420, c.background, 0.8)
        boxes.levelMaintainer = widgetsAreUs.createBox(20, 80, 160, 200, c.panel, 1)
        boxes.levelMaintainerConfig = widgetsAreUs.createBox(192, 80, 160, 200, c.background2, 1)
        boxes.itemManager = widgetsAreUs.createBox(385, 60, 160, 240, c.panel, 1)
        boxes.machineManager = widgetsAreUs.createBox(35, 310, 290, 150, c.panel, 1)
        boxes.machineManagerConfig = widgetsAreUs.createBox(355, 310, 160, 160, c.background2, 1)
        boxes.generalConfig = widgetsAreUs.createBox(520, 310, 200, 160, c.background2, 1)
        boxes.itemMangerConfig = widgetsAreUs.createBox(580, 80, 160, 200, c.background2, 1)
    end)
    if not success then
        print("configurations - Error in configurations.initBoxes: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

function configurations.initButtons()
    print("configurations - Line 86: Initializing buttons")
    local success, err = pcall(function()
        buttons.levelMaintainerPrev = widgetsAreUs.symbolBox(85, 58, "^", c.navbutton, function()
            displays.levelMaintainer:prevPage()
        end)
        buttons.levelMaintainerNext = widgetsAreUs.symbolBox(85, 283, "v", c.navbutton, function()
            displays.levelMaintainer:nextPage()
        end)
        buttons.itemManagerPrev = widgetsAreUs.symbolBox(363, 160, "<", c.navbutton, function()
            displays.itemManager:prevPage()
        end)
        buttons.itemManagerNext = widgetsAreUs.symbolBox(548, 160, ">", c.navbutton, function()
            displays.itemManager:nextPage()
        end)
        buttons.machineManagerPrev = widgetsAreUs.symbolBox(8, 378, "<", c.navbutton, function()
            displays.machineManager:prevPage()
        end)
        buttons.machineManagerNext = widgetsAreUs.symbolBox(328, 378, ">", c.navbutton, function()
            displays.machineManager:nextPage()
        end)
        buttons.save = widgetsAreUs.attachOnClick(widgetsAreUs.textBox(680, 60, 50, 15, c.dangerbutton, 0.7, "Save", 1.2, 3, 3),
        function()
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

                event.push("updated_configs")
            end)
            if not success then
                print("configurations - Error in configurations.update: " .. tostring(err))
            end
        end)
    end)
    if not success then
        print("configurations - Error in configurations.initButtons: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

function configurations.initDisplays()
    print("configurations - Line 108: Initializing displays")
    local success, err = pcall(function()
        local function loadAndDisplayTable(path, width, height, coords, callback, widget)
            print("configurations - Line 112: loadAndDisplayTable called with path =", tostring(path))
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
            print("") -- Blank line after loop
            return display
        end

        displays.levelMaintainer = loadAndDisplayTable("/home/programData/levelMaintainer.data", 150, 30, {x1=25, x2=175, y1=85, y2=195}, function(index)
            print("configurations - Line 127: levelMaintainer callback called with index =", tostring(index))
            configurations.createLevelMaintainerConfig(192, 80, index)
        end, widgetsAreUs.levelMaintainer)

        displays.itemManager = loadAndDisplayTable("/home/programData/monitoredItems", 120, 40, {x1=390, x2=540, y1=65, y2=305}, function(index)
            print("configurations - Line 131: itemManager callback called with index =", tostring(index))
            configurations.createItemManagerConfig(580, 80, index)
        end, widgetsAreUs.itemBox)

        displays.machineManager = loadAndDisplayTable("/home/programData/machinesNamed.data", 120, 34, {x1=45, x2=295, y1=320, y2=460}, function(index)
            print("configurations - Line 135: machineManager callback called with index =", tostring(index))
            configurations.createMachineManagerConfig(355, 310, index)
        end, widgetsAreUs.machineElementConfigEdition)
    end)
    if not success then
        print("configurations - Error in configurations.initDisplays: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

function configurations.init()
    print("configurations - Line 141: Initializing configurations")
    local success, error = pcall(configurations.initBoxes)
    if not success then print("configurations - Error in configurations.initBoxes: " .. tostring(error)) end

    success, error = pcall(configurations.initButtons)
    if not success then print("configurations - Error in configurations.initButtons: " .. tostring(error)) end

    success, error = pcall(configurations.initDisplays)
    if not success then print("configurations - Error in configurations.initDisplays: " .. tostring(error)) end

    success, error = pcall(function ()
        print("configurations - Line 150: Creating general config and generating helper table")
        createGeneralConfig(525, 320, 1)
        generateHelperTable()
    end)
    if not success then print("configurations - Error in configurations.init: " .. tostring(error)) end
    print("") -- Blank line after function execution
end

----------------------------------------------------------
---configs factory

local function removeConfigDisplay(activeConfigsIndex)
    print("configurations - Line 160: removeConfigDisplay called with activeConfigsIndex =", tostring(activeConfigsIndex))
    local success, err = pcall(function()
        for k, v in pairs(currentlyDisplayedConfigs[activeConfigsIndex].elements) do
            if v.remove then
                local success_remove, error_remove = pcall(v.remove)
                if not success_remove then print("configurations - Error removing element: " .. tostring(error_remove)) end
            end
        end
        currentlyDisplayedConfigs[activeConfigsIndex].elements = nil
        print("") -- Blank line after loop
    end)
    if not success then
        print("configurations - Error in removeConfigDisplay: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

saveConfigData = function(activeConfigsConfigKey, path, activeConfigsIndex)
    print("configurations - Line 214: saveConfigData called with activeConfigsConfigKey =", tostring(activeConfigsConfigKey), "path =", tostring(path), "activeConfigsIndex =", tostring(activeConfigsIndex))
    
    local success, err = pcall(function()
        print("configurations - Line 216: Entering pcall block")
        print("configurations - Line 217: activeConfigsConfigKey =", tostring(activeConfigsConfigKey), "path =", tostring(path), "activeConfigsIndex =", tostring(activeConfigsIndex))

        local tbl = gimpHelper.loadTable(path)
        print("configurations - Line 220: Loaded tbl from gimpHelper.loadTable(path) =", s.serialize(tbl))

        if not tbl then
            print("configurations - Line 222: tbl is nil, initializing as empty table")
            tbl = {}
        end

        local derp = {}
        print("configurations - Line 225: Initialized empty table derp")
        local enabled = false
        for k, v in pairs(currentlyDisplayedConfigs[activeConfigsConfigKey].elements) do
            if type(v) ~= "function" and v.getValue then
                print("configurations - Line 227: Iterating currentlyDisplayedConfigs elements, k =", tostring(k), "v =", tostring(v.getValue()))
            end
            if v.getValue then
                local value = tostring(v.getValue())
                print("configurations - Line 229: v.getValue() =", value)

                if value ~= "num" and value ~= "string" then
                    print("configurations - Line 231: Saving config for k =", tostring(k), "v.key =", tostring(v.key), "v.getValue() =", value)
                    derp[v.key] = value
                    if v.key == "enabled" and value == "X" then
                        enabled = true
                    end 
                else
                    print("configurations - Line 233: Skipping save for k =", tostring(k), "v.key =", tostring(v.key), "v.getValue() =", value)
                end
            else
                print("configurations - Line 235: v.getValue is nil for k =", tostring(k))
            end
        end

        tbl[activeConfigsIndex] = derp
        print("configurations - Line 238: Updated tbl[activeConfigsIndex] =", s.serialize(tbl[activeConfigsIndex]))

        print("configurations - Line 240: Saving updated table to path =", tostring(path))
        gimpHelper.saveTable(tbl, path)
        print("configurations - Line 242: Table saved successfully")
        if enabled then
            event.push("add_level_maint_thread", activeConfigsIndex)
        end
        print("") -- Blank line after function block
    end)

    if not success then
        print("configurations - Error in saveConfigData: " .. tostring(err))
    else
        print("configurations - Line 245: saveConfigData completed successfully")
    end
    print("") -- Blank line after function execution
end

loadConfigData = function(currentlyDisplayedConfigsRef, path, configIndex)
    print("configurations - Line 236: loadConfigData called with currentlyDisplayedConfigsRef =", tostring(currentlyDisplayedConfigsRef), "path =", tostring(path), "configIndex =", tostring(configIndex))
    -- local success, err = pcall(function()
        print("configurations - Line 238: Entering pcall block")
        print("configurations - Line 239: currentlyDisplayedConfigsRef =", tostring(currentlyDisplayedConfigsRef), "path =", tostring(path), "configIndex =", tostring(configIndex))

        local tbl = gimpHelper.loadTable(path)
        print("configurations - Line 242: tbl loaded from gimpHelper.loadTable(path) =", s.serialize(tbl))

        if tbl and tbl[configIndex] then
            print("configurations - Line 244: tbl and tbl[configIndex] are valid")
            for k, v in pairs(currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements) do
                print("configurations - Line 246: Iterating currentlyDisplayedConfigs elements, k =", tostring(k), "v =", tostring(v))
                for i, j in pairs(tbl[configIndex]) do
                    print("configurations - Line 248: Iterating tbl[configIndex], i =", tostring(i), "j =", tostring(j))

                    print(tostring(v.key), tostring(i))
                    if v.key and v.key == i then
                        print("configurations - Line 250: Found matching key in currentlyDisplayedConfigs element, key =", tostring(v.key))

                        if j and tostring(j) == "true" then
                            print("configurations - Line 252: j is 'true', setting value to 'X'")
                            currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue("X")
                        elseif j and tostring(j) == "false" then
                            print("configurations - Line 254: j is 'false', setting value to ' ' (space)")
                            currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue(" ")
                        elseif j then
                            print("configurations - Line 256: j has a different value, setting value to j =", tostring(j))
                            currentlyDisplayedConfigs[currentlyDisplayedConfigsRef].elements[k].setValue(j)
                        else
                            print("configurations - Line 258: j is nil or false")
                        end
                    else
                        print("configurations - Line 260: No matching key found or v.key is nil")
                    end
                end
            end
        else
            print("configurations - Line 263: tbl or tbl[configIndex] is nil or false")
        end
    --[[end)

    if not success then
        print("configurations - Error in loadConfigData: " .. tostring(err))
    else
        print("configurations - Line 267: loadConfigData completed successfully")
    end
    ]]
    print("") -- Blank line after function execution
end

local function enable_level_maintainer(obj)
    local success_save, error_save = pcall(saveConfigData, "lm", "/home/programData/levelMaintainerConfig.data", currentlyDisplayedConfigs["lm"].index)
    if not success_save then print("configurations - Error saving config data: " .. tostring(error_save)) end
    event.push("add_level_maint_thread", currentlyDisplayedConfigs["lm"].index)
end

function configurations.createLevelMaintainerConfig(x, y, index)
    print("configurations - Line 217: createLevelMaintainerConfig called with x =", tostring(x), "y =", tostring(y), "index =", tostring(index))
    local success, err = pcall(function()
        if currentlyDisplayedConfigs["lm"] and currentlyDisplayedConfigs["lm"].index then
            local success_save, error_save = pcall(saveConfigData, "lm", "/home/programData/levelMaintainerConfig.data", currentlyDisplayedConfigs["lm"].index)
            if not success_save then print("configurations - Error saving config data: " .. tostring(error_save)) end

            local success_remove, error_remove = pcall(removeConfigDisplay, "lm")
            if not success_remove then print("configurations - Error removing config display: " .. tostring(error_remove)) end
        end
        configurations.panel.lm = {}
        configurations.panel.lm.priority = widgetsAreUs.numberBox(x, y, "priority", "Priority:")
        configurations.panel.lm.enabled = widgetsAreUs.attachToOnClick(widgetsAreUs.checkBoxHalf(x+80, y, "enabled", "Enabled", c.coral), enable_level_maintainer)
        configurations.panel.lm.minCPU = widgetsAreUs.numberBox(x, y+30, "minCpu", "Min CPU")
        configurations.panel.lm.minCpuTitle2 = widgetsAreUs.text(x+5, y+45, "Available:", 0.9)
        configurations.panel.lm.maxCPU = widgetsAreUs.numberBox(x+80, y+30, "maxCpu", "Max CPU")
        configurations.panel.lm.maxCpuTitle2 = widgetsAreUs.text(x+90, y+45, "Usage:", 1)
        configurations.panel.lm.alertStalled = widgetsAreUs.checkboxFullLine(x, y+60, "alertStalled", "Alert Stalled")
        configurations.panel.lm.alertResources = widgetsAreUs.checkboxFullLine(x, y+90, "alertResources", "Alert Can't Craft")
        os.sleep(0)

        currentlyDisplayedConfigs["lm"] = {index = index, elements = configurations.panel.lm}
        local success_load, error_load = pcall(loadConfigData, "lm", "/home/programData/levelMaintainerConfig.data", index)
        if not success_load then print("configurations - Error loading config data: " .. tostring(error_load)) end
    end)
    if not success then
        print("configurations - Error in configurations.createLevelMaintainerConfig: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

function configurations.createMachineManagerConfig(x, y, index)
    print("configurations - Line 248: createMachineManagerConfig called with x =", tostring(x), "y =", tostring(y), "index =", tostring(index))
    --[[local success, err = pcall(function()
        if currentlyDisplayedConfigs["mm"] and currentlyDisplayedConfigs["mm"].index then
            local success_save, error_save = pcall(saveConfigData, "mm", "/home/programData/machineManagerConfig.data", currentlyDisplayedConfigs["mm"].index)
            if not success_save then print("configurations - Error saving config data: " .. tostring(error_save)) end

            local success_remove, error_remove = pcall(removeConfigDisplay, "mm")
            if not success_remove then print("configurations - Error removing config display: " .. tostring(error_remove)) end
        end
        local tbl = gimpHelper.loadTable("/home/programData/machinesNamed.data")
        configurations.panel.mm = {}
        configurations.panel.mm.name = widgetsAreUs.textBoxWithTitle(x, y, "name", "Name")
        configurations.panel.mm.name.setValue(tbl[index].newName)
        configurations.panel.mm.group = widgetsAreUs.textBoxWithTitle(x, y+30, "group", "Group") os.sleep(0)
        configurations.panel.mm.group.setValue(tbl[index].groupName)
        configurations.panel.mm.autoTurnOn = widgetsAreUs.numberBox(x, y+60, "autoTurnOn", "Auto On")
        configurations.panel.mm.autoTurnOff = widgetsAreUs.numberBox(x+80, y+60, "autoTurnOff", "Auto Off")
        configurations.panel.mm.alertDisabled = widgetsAreUs.checkBoxHalf(x, y+90, "alertDisabled", "A: Disabled")
        configurations.panel.mm.alertEnabled = widgetsAreUs.checkBoxHalf(x+80, y+90, "alertEnabled", "A: Enabled")
        currentlyDisplayedConfigs["mm"] = {index = index, elements = configurations.panel.mm}
        local success_load, error_load = pcall(loadConfigData, "mm", "/home/programData/machineManagerConfig.data", index)
        if not success_load then print("configurations - Error loading config data: " .. tostring(error_load)) end
    end)
    if not success then
        print("configurations - Error in configurations.createMachineManagerConfig: " .. tostring(err))
    end]]
    print("") -- Blank line after function execution
end

function configurations.createItemManagerConfig(x, y, index)
    print("configurations - Line 276: createItemManagerConfig called with x =", tostring(x), "y =", tostring(y), "index =", tostring(index))
    local success, err = pcall(function()
        if currentlyDisplayedConfigs["im"] and currentlyDisplayedConfigs["im"].index then
            local success_save, error_save = pcall(saveConfigData, "im", "/home/programData/itemManagerConfig.data", currentlyDisplayedConfigs["im"].index)
            if not success_save then print("configurations - Error saving config data: " .. tostring(error_save)) end

            local success_remove, error_remove = pcall(removeConfigDisplay, "im")
            if not success_remove then print("configurations - Error removing config display: " .. tostring(error_remove)) end
        end
        configurations.panel.im = {}
        configurations.panel.im.alertAbove = widgetsAreUs.longerNumberBox(x, y, "alertAbove", "Alert Above", c.alertsettingtitle)
        configurations.panel.im.alertBelow = widgetsAreUs.longerNumberBox(x, y+30, "alertBelow", "Alert Below", c.alertsettingtitle)
        configurations.panel.im.showOnHud = widgetsAreUs.checkboxFullLine(x, y+60, "showOnHud", "Show On HUD", c.configsettingtitle)
        --configurations.panel.im.monitorMetrics = widgetsAreUs.checkboxFullLine(x, y+90, "monitorMetrics", "Monitor Metrics on Slave")
        currentlyDisplayedConfigs["im"] = {index = index, elements = configurations.panel.im}
        local success_load, error_load = pcall(loadConfigData, "im", "/home/programData/itemManagerConfig.data", index)
        if not success_load then print("configurations - Error loading config data: " .. tostring(error_load)) end
    end)
    if not success then
        print("configurations - Error in configurations.createItemManagerConfig: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

createGeneralConfig = function(x, y)
    print("configurations - Line 301: createGeneralConfig called with x =", tostring(x), "y =", tostring(y))
    local success, err = pcall(function()
        configurations.panel.gc = {}
        configurations.panel.gc.showHelp = widgetsAreUs.checkBoxHalf(x, y, "showHelp", "Show Help", c.configsettingtitle)
        configurations.panel.gc.resetHud = widgetsAreUs.configsButtonHalf(x+80, y, "Reset HUD", "Reset", c.brightred, function()
            event.push("reset_hud")
            os.sleep(100)
        end)
        os.sleep(0)
        configurations.panel.gc.highlightDisabled = widgetsAreUs.checkboxFullLine(x, y+30, "highlightDisabled", "Highlight Disabled Mach's", c.configsettingtitle)
        configurations.panel.gc.maintenanceBeacons = widgetsAreUs.checkboxFullLine(x, y+60, "maintenanceBeacons", "Maintenance Beacons", c.configsettingtitle)
        configurations.panel.gc.alertDisconnected = widgetsAreUs.checkboxFullLine(x, y+90, "alertDisconnectedReconnected", "A: DC'd/Reconnected", c.alertsettingtitle)
        configurations.panel.gc.maxCpusAllLevelMaintainers = widgetsAreUs.numberBoxLongerText(x, y+120, "maxCpusAllLevelMaintainers", "Max CPUs for Maintainers")
        currentlyDisplayedConfigs["gc"] = {index = 1, elements = configurations.panel.gc}
        local success_load, error_load = pcall(loadConfigData, "gc", "/home/programData/generalConfig.data", 1)
        if not success_load then print("configurations - Error loading general config data: " .. tostring(error_load)) end
    end)
    if not success then
        print("configurations - Error in createGeneralConfig: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

----------------------------------------------------------
---got tired of typing everything 10,000 times

local helperTable = {}

generateHelperTable = function()
    print("configurations - Line 326: generateHelperTable called")
    local success, err = pcall(function()
        helperTable = {}
        for k, v in pairs(boxes) do
            os.sleep(0)
            table.insert(helperTable, v)
        end
        print("") -- Blank line after boxes loop
        for k, v in pairs(buttons) do
            os.sleep(0)
            table.insert(helperTable, v)
        end
        print("") -- Blank line after buttons loop
        for k, v in pairs(displays) do
            os.sleep(0)
            for i, j in ipairs(displays[k].currentlyDisplayed) do
                table.insert(helperTable, displays[k].currentlyDisplayed[i])
            end
        end
        print("") -- Blank line after displays loop
        for k, v in pairs(configurations.panel) do
            os.sleep(0)
            for i, j in pairs(configurations.panel[k]) do
                table.insert(helperTable, configurations.panel[k][i])
            end
        end
        print("") -- Blank line after configurations.panel loop
    end)
    if not success then
        print("configurations - Error in generateHelperTable: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

----------------------------------------------------------
---element functionality

function configurations.update()
    print("configurations - Line 347: configurations.update called")
    print("") -- Blank line after function execution
end

function configurations.setVisible(visible)
    print("configurations - Line 364: configurations.setVisible called with visible =", tostring(visible))
    local success, err = pcall(function()
        generateHelperTable()
        for k, v in pairs(helperTable) do
            if v.setVisible then
                v.setVisible(visible)
                os.sleep(0)
            end
        end
        print("") -- Blank line after loop
    end)
    if not success then
        print("configurations - Error in configurations.setVisible: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

function configurations.remove()
    print("configurations - Line 376: configurations.remove called")
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
        print("") -- Blank line after loop
    end)
    if not success then
        print("configurations - Error in configurations.remove: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

function configurations.onClick(x, y, button)
    print("configurations - Line 402: configurations.onClick called with x =", tostring(x), "y =", tostring(y), "button =", tostring(button))
    local success, err = pcall(function()
        generateHelperTable()
        for k, v in pairs(helperTable) do
            if v.box and v.box.contains(x, y) and v.onClick then
                v.onClick(x, y, button)
                os.sleep(0)
                print("") -- Blank line after condition
                return
            elseif v.contains and v.contains(x, y) and v.onClick then
                v.onClick(x, y, button)
                os.sleep(0)
                print("") -- Blank line after condition
                return
            elseif v.option and v.option.box and v.option.box.contains(x, y) and v.onClick then
                v.onClick(x, y, button)
                os.sleep(0)
                print("") -- Blank line after condition
                return
            end
        end
        print("") -- Blank line after loop
    end)
    if not success then
        print("configurations - Error in configurations.onClick: " .. tostring(err))
    end
    print("") -- Blank line after function execution
end

----------------------------------------------------------

return configurations