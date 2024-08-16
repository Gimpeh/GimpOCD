--widgetsAreUs.lua
local component = require("component")

local glasses = component.glasses

local widgetsAreUs = {}

function widgetsAreUs.convertNumber(numberToConver)
    local num = numberToConver
    local units = {"", "k", "M", "B", "T", "P", "E", "Z", "Y"}
    local unitIndex = 1
	while num >= 1000 and unitIndex < #units do
        num = num / 1000
        unitIndex = unitIndex + 1
    end

	local convertedNumber = string.format("%.1f%s", num, units[unitIndex])
	return convertedNumber
end

function widgetsAreUs.createBox(x, y, width, height, color, alpha)
	local box = glasses.addRect()
	box.setSize(height, width)
	box.setPosition(x, y)
	box.setColor(color[1], color[2], color[3])
	if alpha then
		box.setAlpha(alpha)
	end
	box.position = {xS = x, yS = y}
	box.size = {width = width, height = height}
	--start coordinates
	function box.start()
		return box.position
	end
	--End Coordinates
	function box.ending()
		local endingX = box.position.xS + box.size.width
		local endingY = box.position.yS + box.size.height

		return {endX = endingX, endY = endingY}
	end
	return box
end

local initText = {}
initText.__index = initText

function initText:new(x, y, textToBeDisplayed)
	local obj = setmetatable({}, self)

	obj.box = widgetsAreUs.createBox(x, y, 320, 20, {1, 0, 0}, 0.5)
	obj.message = glasses.addTextLabel()
	obj.message.setPosition(x+2, y+2)
	obj.message.setText(textToBeDisplayed)

	return obj
end

function initText:remove()
	glasses.removeObject(self.box.getID())
	glasses.removeObject(self.message.getID())
	self.box = nil
	self.message = nil
end

widgetsAreUs.initText = initText

function widgetsAreUs.numberFillBar(x, y, width, height, title, maxAmount, color)
    local background = glasses.addRect()
    background.setSize(height, width)
    background.setPosition(x, y)
    background.setColor(100, 100, 100)

    local bar = glasses.addRect()
    bar.setSize(height, 20)
    bar.setPosition(x, y)
    bar.setColor(color[1], color[2], color[3])

    local titleText = glasses.addTextLabel()
    titleText.setPosition(x, y)
    titleText.setText(title)
    titleText.setColor(255, 255, 255)

    local text = glasses.addTextLabel()
    text.setPosition(x + 5, y + height / 2 - 5)
    text.setColor(255, 255, 255)

    return {
        update = function(currentAmount)
            local fillWidth = math.floor(width * (currentAmount / maxAmount))
            bar.setSize(height, fillWidth)

			local convertedNumber = widgetsAreUs.convertNumber(currentAmount)
            text.setText(convertedNumber)
        end,
        setVisible = function(visible)
            background.setVisible(visible)
            bar.setVisible(visible)
            titleText.setVisible(visible)
            text.setVisible(visible)
        end,
		remove = function()
			glasses.removeObject(background.getID())
			glasses.removeObject(bar.getID())
			glasses.removeObject(titleText.getID())
			glasses.removeObject(text.getID())
			background = nil
			bar = nil
			titleText = nil
			text = nil
		end
    }
end

function widgetsAreUs.maintenanceAlert(x, y, width, height)
    local background = glasses.addRect()
    background.setSize(height, width)
    background.setPosition(x, y)
    background.setColor(255, 0, 0)  -- Red
    background.setAlpha(0.5)  -- Semi-transparent

    local text = glasses.addTextLabel()
    text.setPosition(x + 10, y + 10)
    text.setColor(255, 255, 255)
    text.setScale(1.2)

    return {
        show = function(message)
            background.setVisible(true)
            text.setText(message)
            text.setVisible(true)
        end,
        hide = function()
            background.setVisible(false)
            text.setVisible(false)
        end,
		remove = function()
			glasses.removeObject(background.getID())
			glasses.removeObject(text.getID())
			background = nil
			text = nil
		end
    }
end

function widgetsAreUs.maintenanceBeacon(x, y, z)
	local element = component.glasses.addDot3D()
    element.set3DPos(0 - 5.5 + x, 0 - 46.5 + y, 0 - 13.5 + z)
    element.setColor(255, 0, 0)
    element.setViewDistance(500)
    element.setScale(1)

	return {
		beacon = element,
		remove = function()
			component.glasses.removeObject(element.getID())
			element = nil
		end,
        x = x,
        y = y,
        z = z
	}
end

function widgetsAreUs.displayLocation(radarData)
    local name = radarData.name
    local distance = radarData.distance
    local x = radarData.x
    local y = radarData.y
    local z = radarData.z

    local beacon = widgetsAreUs.maintenanceBeacon(x+1, y + 50.5, z + 21)
    beacon.beacon.setColor(1, 1, 1)
    beacon.beacon.setViewDistance(500)

   return {
    name = name,
    distance = distance,
    x = x,
    y = y,
    z = z,
    beacon = beacon,
    remove = function()
        beacon.remove()
    end,
    setDistance = function(distanceNew)
        distance = distanceNew
    end,
    setColor = function(rgb)
        beacon.beacon.setColor(rgb[1], rgb[2], rgb[3])
    end,
    move = function(xyz)
        beacon.beacon.set3DPos(xyz.x, xyz.y +49, xyz.z +20)
    end
   }
end

function widgetsAreUs.isPointInBox(x, y, box)
    local start = box.start()
    local finish = box.ending()
    return x >= start.xS and x <= finish.endX and y >= start.yS and y <= finish.endY
end

return widgetsAreUs