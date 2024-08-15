--metricsDisplays V1.0

local component = require("component")
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")
local s = require("serialization")
local event = require("event")

local glasses = component.glasses
local modem = component.modem

modem.open(888)

local metricsDisplays = {}

-- Table to hold all metrics and relevant UI elements
local batteryMetrics = {}

function batteryMetrics.create(x, y)
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
    header.setText("Power Station")
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

			euInText.setText(gimpHelper.shorthandNumber(euin))
			euOutText.setText(gimpHelper.shorthandNumber(out))

			local euStored = unserializedTable.stored
			local powerMax = unserializedTable.max

			local percent = gimpHelper.calculatePercentage(euStored, powerMax)
			storedNumber.setText(gimpHelper.shorthandNumber(gimpHelper.cleanNumberString(euStored)))

			local fillWidth = math.ceil(74 * (percent / 100))
			fillBarForeground.setSize(20, fillWidth)
			percentPower.setText(string.format("%.2f%%", tostring(percent)))
		end,
		setVisible = function(visible)
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
  local machinesTable = machineTable

  local background = widgetsAreUs.createBox(x, y, 107, 75, {0, 0, 0}, 0.8)

  local backgroundInterior = glasses.addRect()
    backgroundInterior.setPosition(x + 5, y + 5)
    backgroundInterior.setSize(65, 97)
    backgroundInterior.setColor(13, 255, 255)
    backgroundInterior.setAlpha(0.7)

  local headerText = glasses.addTextLabel()
    headerText.setScale(1.2)
    headerText.setText(header)
    headerText.setPosition(x + 10, y + 10)

  local numberOfMachines = glasses.addTextLabel()
  numberOfMachines.setPosition(x+42, y+50)
  numberOfMachines.setText(" ")

  local canRunTitle = glasses.addTextLabel()
  canRunTitle.setText("Allowed:")
  canRunTitle.setPosition(x+10, y+30)
  canRunTitle.setScale(1.5)

  local canRun = glasses.addTextLabel()
  canRun.setText(" ")
  canRun.setPosition(x+70, y+50)
  canRun.setScale(1.5)

  local workAllowed = true

  return {
    background = background,
    machines = machinesTable,
    update = function()
      numberOfMachines.setText(tostring(#machinesTable))
	  local allowedToWork = 0
	  for k, v in ipairs(machinesTable) do
		if v.isWorkAllowed() then
			allowedToWork = allowedToWork +1
		end
	  end
      local allowed = allowedToWork
      if allowed == 0 then
        background.setColor(255, 0, 0)
        workAllowed = false
      elseif allowed > 0 and allowed < metricsGroup.amountOfMachines then
        background.setColor(1, 0, 1)
      else
        background.setColor(0, 0, 0)
        workAllowed = true
      end
      canRun.setText(tostring(allowed))
    end,
    setVisible = function(visible)
      background.setVisible(visible)
      backgroundInterior.setVisible(visible)
      headerText.setVisible(visible)
      numberOfMachines.setVisible(visible)
      canRunTitle.setVisible(visible)
      canRun.setVisible(visible)
    end,
    onClick = function(button)
		if button == 0 then
			for _, machine in ipairs(machinesTable) do
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
		elseif button == 1 then
			local machinesManager = require("machinesManager")
			machinesManager.groups.remove()
			machinesManager.individuals.init(machinesTable)
		end
    end,
	remove = function()
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
	local machine = individualProxy

	local background = widgetsAreUs.createBox(x, y, 60, 34, {1, 1, 1}, 0.6)

	local name = glasses.addTextLabel()
	name.setPosition(x+4, y+4)
	name.setText("updating")
	name.setScale(1)

	local name2 = glasses.addTextLabel()
	name2.setPosition(x+4, y+12)
	name2.setText(" ")
	name2.setScale(1)

	local state = glasses.addTextLabel()
	state.setScale(1.2)
	state.setText(" ")
	state.setPosition(x+22, y+30)

	local machineInterface = {
		background = background,
		setVisible = function(visible)
			background.setVisible(visible)
			name.setVisible(visible)
			name2.setVisible(visible)
			state.setVisible(visible)
		end,
		setName = function(newName)
			if newName then
				name.setText(newName)
			else
				local firstPart, secondPart = string.match(machine.getName(), "([^%]+)%.([^%.]+)")
				name.setText(firstPart)
				name2.setText(secondPart)
			end
		end,
		getCoords = function()
			return machine.getCoordinates()
		end,
		getState = function()
			local machineState = machine.isMachineActive()
			if machineState	then
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
			return allowed
		end,
		setState = function(machineInterface)
			local allowed = machineInterface.getState()
			if allowed then
				machine.setWorkAllowed(false)
			else
				machine.setWorkAllowed(true)
			end

			return machineInterface.getState()
		end,
		onClick = function(button, machinesInterface)
			if button == 0 then -- left click
				machineInterface.setState(machineInterface)
			elseif button == 1 then --right click
				local xyz = {}
				xyz.x, xyz.y, xyz.z = machine.getCoordinates()
				modem.broadcast(888, "manual", s.serialize(xyz))
			elseif button == 2 then
				name.setText(" ")
				name2.setText(" ")
				local newText = ""

				local helpMessage = widgetsAreUs.initText:new(250, 162, "Input New Name")
				while true do
					local _, _, _, character = event.pull("hud_keyboard")
					if character == 13 then -- enter key
						local xyz = {}
						xyz.x, xyz.y, xyz.z = machine.getCoordinates()

						machineInterface.setName(newText)
						modem.broadcast(888, "rename", s.serialize(xyz), newText)

						helpMessage:remove()
						break
					elseif character == 8 then --backspace
						newText = newText:sub(1, -2)
					else
						local letter = string.char(character)
						newText = newText .. letter
					end
				end
			end
		end,
		remove = function(machineInterface)
			component.glasses.removeObject(background.getID())
			component.glasses.removeObject(name.getID())
			component.glasses.removeObject(name2.getID())
			component.glasses.removeObject(state.getID())
		
			background = nil
			name = nil
			name2 = nil
			state = nil
		
			machineInterface = nil
		end,
	}

	return machineInterface
end

metricsDisplays.machine = machineIndividual

return metricsDisplays