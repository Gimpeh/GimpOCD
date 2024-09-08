local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local s = require("serialization")
local event = require("event")
local c = require("gimp_colors")

local glasses = component.glasses
local modem = component.modem

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end

modem.open(888)

local metricsDisplays = {}

-- Table to hold all metrics and relevant UI elements
local batteryMetrics = {}

function batteryMetrics.create(x, y)
    print("metricsDisplays - Line 15: Creating battery metrics display at position (", x, ",", y, ").")

    -- Store UI elements and state in the table
    local backgroundBox = widgetsAreUs.createBox(x, y, 203, 183, {0, 0, 0}, 0.8)

    local backgroundInterior = glasses.addRect()
    backgroundInterior.setPosition(x + 5, y + 5)
    backgroundInterior.setSize(173, 193)
    backgroundInterior.setColor(13, 255, 255)
    backgroundInterior.setAlpha(0.7)

    local ampsLabel = glasses.addTextLabel()
    ampsLabel.setText("Stored")
    ampsLabel.setPosition(x + 20, y + 105)
    ampsLabel.setScale(2)

    local storedNumber = glasses.addTextLabel()
    storedNumber.setText("")
    storedNumber.setPosition(x + 103, y + 105)
    storedNumber.setScale(2)

    local fillBarBackground = glasses.addRect()
    fillBarBackground.setPosition(x + 108, y + 138)
    fillBarBackground.setSize(20, 80)

    local euOutText = glasses.addTextLabel()
    euOutText.setScale(2)
    euOutText.setText(" ")
    euOutText.setPosition(x + 103, y + 69)

    local euOutLabel = glasses.addTextLabel()
    euOutLabel.setText("EU OUT:")
    euOutLabel.setPosition(x + 15, y + 68)
    euOutLabel.setScale(2)

    local euInText = glasses.addTextLabel()
    euInText.setPosition(x + 103, y + 45)
    euInText.setText(" ")
    euInText.setScale(2)

    local euInLabel = glasses.addTextLabel()
    euInLabel.setText("EU IN :")
    euInLabel.setPosition(x + 23, y + 43)
    euInLabel.setScale(2)

    local header = glasses.addTextLabel()
    header.setScale(2)
    header.setText("Power Metrics")
    header.setPosition(x + 33, y + 10)

    local fillBarForeground = glasses.addRect()
    fillBarForeground.setPosition(x + 108, y + 138)
    fillBarForeground.setSize(20, 1)
    fillBarForeground.setColor(1, 1, 0)

    local percentPower = glasses.addTextLabel()
    percentPower.setPosition(x + 33, y + 138)
    percentPower.setText(" ")
    percentPower.setScale(2)

    return {
        update = function(unserializedTable)
            local euin = unserializedTable.powerIn
            local out = unserializedTable.powerOut
			os.sleep(0)
            euInText.setText(gimpHelper.shorthandNumber(euin))
            euOutText.setText(gimpHelper.shorthandNumber(out))
			os.sleep(0)
            local euStored = unserializedTable.stored
            local powerMax = unserializedTable.max
			os.sleep(0)
            local percent = gimpHelper.calculatePercentage(euStored, powerMax)
            storedNumber.setText(gimpHelper.shorthandNumber(gimpHelper.cleanBatteryStorageString(euStored)))
			os.sleep(0)
            local fillWidth = math.ceil(74 * (percent / 100))
            fillBarForeground.setSize(20, fillWidth)
            percentPower.setText(string.format("%.2f%%", tonumber(percent)))
        end,
        setVisible = function(visible)
            print("metricsDisplays - Line 73: Setting visibility of battery metrics display to", tostring(visible))
            backgroundBox.setVisible(visible)
            backgroundInterior.setVisible(visible)
            ampsLabel.setVisible(visible)
            fillBarBackground.setVisible(visible)
            euOutText.setVisible(visible)
            euOutLabel.setVisible(visible)
            euInText.setVisible(visible)
            euInLabel.setVisible(visible)
            header.setVisible(visible)
            fillBarForeground.setVisible(visible)
            percentPower.setVisible(visible)
            storedNumber.setVisible(visible)
        end,
        remove = function()
            print("metricsDisplays - Line 87: Removing battery metrics display.")
            glasses.removeObject(backgroundBox.getID())
            glasses.removeObject(backgroundInterior.getID())
            glasses.removeObject(ampsLabel.getID())
            glasses.removeObject(fillBarBackground.getID())
            glasses.removeObject(euOutText.getID())
            glasses.removeObject(euOutLabel.getID())
            glasses.removeObject(euInText.getID())
            glasses.removeObject(euInLabel.getID())
            glasses.removeObject(header.getID())
            glasses.removeObject(fillBarForeground.getID())
            glasses.removeObject(percentPower.getID())
            glasses.removeObject(storedNumber.getID())

            -- Set all references to nil
            backgroundBox = nil
            backgroundInterior = nil
            ampsLabel = nil
            fillBarBackground = nil
            euOutText = nil
            euOutLabel = nil
            euInText = nil
            euInLabel = nil
            header = nil
            fillBarForeground = nil
            percentPower = nil
            storedNumber = nil
        end
    }
end

metricsDisplays.battery = batteryMetrics

local machinesMetricsElement = {}

function machinesMetricsElement.createElement(x, y, machineTable, header)
    print("metricsDisplays - Line 115: Creating machine metrics element at position (", x, ",", y, ").")
    local machinesTable = machineTable

    local background = widgetsAreUs.createBox(x, y, 107, 75, {0, 0, 0}, 0.8)

    local backgroundInterior = glasses.addRect()
    backgroundInterior.setPosition(x + 5, y + 5)
    backgroundInterior.setSize(65, 97)
    backgroundInterior.setColor(table.unpack(c.object))
    backgroundInterior.setAlpha(0.7)

    local headerText = glasses.addTextLabel()
    headerText.setScale(1.2)
    headerText.setText(header)
    headerText.setPosition(x + 10, y + 10)

    local numberOfMachines = glasses.addTextLabel()
    numberOfMachines.setPosition(x+70, y+50)
    numberOfMachines.setText(" ")

    local canRunTitle = glasses.addTextLabel()
    canRunTitle.setText("Allowed:")
    canRunTitle.setPosition(x+10, y+30)
    canRunTitle.setScale(1.5)

    local canRun = glasses.addTextLabel()
    canRun.setText(" ")
    canRun.setPosition(x+42, y+50)
    canRun.setScale(1.5)

    local workAllowed = true

    return {
        background = background,
        machines = machinesTable,
        update = function()
            print("metricsDisplays - Line 142: Updating machine metrics element.")
            numberOfMachines.setText(tostring(#machinesTable))
            local allowedToWork = 0
            for k, v in ipairs(machinesTable) do
                if v.isWorkAllowed() then
                    allowedToWork = allowedToWork + 1
                    os.sleep(0)
                end
            end
            local allowed = allowedToWork
            if allowed == 0 then
                background.setColor(255, 0, 0)
                workAllowed = false
            elseif allowed > 0 and allowed < #machinesTable then
                background.setColor(1, 0, 1)
            else
                background.setColor(0, 0, 0)
                workAllowed = true
            end
            canRun.setText(tostring(allowed))
        end,
        setVisible = function(visible)
            print("metricsDisplays - Line 160: Setting visibility of machine metrics element to", tostring(visible))
            background.setVisible(visible)
            backgroundInterior.setVisible(visible)
            headerText.setVisible(visible)
            numberOfMachines.setVisible(visible)
            canRunTitle.setVisible(visible)
            canRun.setVisible(visible)
        end,
        onClick = function(button)
            print("metricsDisplays - Line 169: Handling onClick for machine metrics element with button", tostring(button))
			local normalColor = table.pack(backgroundInterior.getColor())
			backgroundInterior.setColor(table.unpack(c.clicked))
            print("checking button")
            if button == 0 then
                print("metricsDisplays - Line 173: Sifting through machines table")
                for _, machine in ipairs(machinesTable) do
                    os.sleep(0)
                    if workAllowed == true then
                        machine.setWorkAllowed(false)
                    else
                        machine.setWorkAllowed(true)
                    end
                end
                if workAllowed == true then
                    workAllowed = false
                    background.setColor(255, 0, 0)
                else
                    workAllowed = true
                    background.setColor(255, 255, 255)
                end
                local machinesManager = require("machinesManager")
                machinesManager.update()
            elseif button == 1 then
                print("metricsDisplays - Line 191: Initializing individuals")
                local machinesManager = require("machinesManager")
                machinesManager.individuals.init(machinesTable, header)
            end
			backgroundInterior.setColor(table.unpack(normalColor))
        end,
        remove = function()
            print("metricsDisplays - Line 189: Removing machine metrics element.")
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(backgroundInterior.getID())
            component.glasses.removeObject(headerText.getID())
            component.glasses.removeObject(numberOfMachines.getID())
            component.glasses.removeObject(canRunTitle.getID())
            component.glasses.removeObject(canRun.getID())

            background = nil
            backgroundInterior = nil
            headerText = nil
            numberOfMachines = nil
            canRunTitle = nil
            canRun = nil
        end
    }
end

metricsDisplays.machineGroups = machinesMetricsElement

local machineIndividual = {}

function machineIndividual.create(x, y, individualProxy)
    print("metricsDisplays - Line 207: Creating individual machine element at position (", x, ",", y, ").")
    local machine = individualProxy
    local highlighted = false

    local background = widgetsAreUs.createBox(x, y, 85, 34, c.object, 0.6)

    local name = glasses.addTextLabel()
    name.setPosition(x+4, y+4)
    name.setText("updating")
    name.setScale(1)

    local name2 = glasses.addTextLabel()
    name2.setPosition(x+4, y+12)
    name2.setText(" ")
    name2.setScale(0.9)

    local state = glasses.addTextLabel()
    state.setScale(1.2)
    state.setText(" ")
    state.setPosition(x+22, y+24)

    local highlightedIndicator = glasses.addRect()
    highlightedIndicator.setPosition(x+78, y+27)
    highlightedIndicator.setSize(0, 0)
    highlightedIndicator.setColor(table.unpack(c.brightred))

    local xyz

    local setName = function(newName)
        print("metricsDisplays - Line 232: Setting name for individual machine element to", tostring(newName))
        if newName then
            name.setText(newName)
            name2.setText(" ")
            xyz = {}
            xyz.x, xyz.y, xyz.z = machine.getCoordinates()
            event.push("nameSet", newName, xyz)
        else
            local firstPart, secondPart = string.match(machine.getName(), "([^%.]+)%.([^%.]+)%.?.*")
            name.setText(firstPart)
            name2.setText(secondPart)
        end
    end

    local machineInterface = {
        background = background,
        setVisible = function(visible)
            print("metricsDisplays - Line 246: Setting visibility of individual machine element to", tostring(visible))
            background.setVisible(visible)
            name.setVisible(visible)
            name2.setVisible(visible)
            state.setVisible(visible)
            highlightedIndicator.setVisible(visible)
        end,
        setName = setName,
        getCoords = function()
            return machine.getCoordinates()
        end,
        update = function()
            print("metricsDisplays - Line 256: Updating individual machine element state.")
            local machineState = machine.isMachineActive()
            if machineState then
                state.setText("On")
            else
                state.setText("Idle")
            end

            local allowed = machine.isWorkAllowed()
            if allowed then
                background.setColor(1, 1, 1)
            else
                background.setColor(1, 0, 0)
            end
        end,
        setState = function()
            print("metricsDisplays - Line 270: Toggling work state for individual machine element.")
            local allowed = machine.isWorkAllowed()
            if allowed then
                machine.setWorkAllowed(false)
                background.setColor(1, 0, 0)
            else
                machine.setWorkAllowed(true)
                background.setColor(1, 1, 1)
            end
        end,
        onClick = function(button, machinesInterface)
            print("metricsDisplays - Line 279: Handling onClick for individual machine element with button", tostring(button))
			local normalColor = table.pack(background.getColor())
			background.setColor(table.unpack(c.clicked))
            if button == 0 then -- left click
                machinesInterface.setState(machinesInterface)
            elseif button == 1 then -- right click
                local xyz = {}
                xyz.x, xyz.y, xyz.z = machine.getCoordinates()
                event.push("highlight", xyz)
                if highlighted then
                    highlightedIndicator.setSize(0, 0)
                    highlighted = false
                else
                    highlightedIndicator.setSize(5, 5)
                    highlighted = true
                end
            elseif button == 2 then
                name.setText(" ")
                name2.setText(" ")
                local helpMessage = widgetsAreUs.initText(250, 162, "Input New Name")
                setName(gimpHelper.handleTextInput(name))
                helpMessage.remove()
            end
			background.setColor(table.unpack(normalColor))
        end,
        remove = function()
            print("metricsDisplays - Line 302: Removing individual machine element.")
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(name.getID())
            component.glasses.removeObject(name2.getID())
            component.glasses.removeObject(state.getID())
            component.glasses.removeObject(highlightedIndicator.getID())

            background = nil
            name = nil
            name2 = nil
            state = nil
            highlightedIndicator = nil
        end
    }

    return machineInterface
end

metricsDisplays.machine = machineIndividual

return metricsDisplays