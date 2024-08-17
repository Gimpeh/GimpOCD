--widgetsAreUs.lua
local component = require("component")
local event = require("event")
local gimpHelper = require("gimpHelper")

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

function widgetsAreUs.titleBox(x, y, width, height, color, alpha, titleText, textScale)
    local background = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local title = component.glasses.addTextLabel()
    title.setScale(textScale)
    title.setPosition(x+3, y+2)
    title.setText(titleText)

    return {
        background = background,
        title = title,
        onClick = function()
            print("reassign me")
        end,
        setVisible = function(visible)
            background.setVisible(visible)
            title.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(title.getID())
            background = nil
            title = nil
        end
    }
end

function widgetsAreUs.levelMaintainer(x, y, argsTable, arrayIndex)
    local itemStack = argsTable.itemStack
    local background = widgetsAreUs.titleBox(x, y, 150, 30, {1, 0.2, 1}, 0.8, itemStack.label, 0.9)

    local batch = widgetsAreUs.titleBox(x+5, y+10, 60, 20, {1, 1, 1}, 0.8, "Batch", 0.7)
    local batchText
    batch.onClick = function()
        while true do
            if batchText.getText == "0" then batchText.setText("") end
            local _, _, _, character, _ = event.pull("hud_keyboard")
            if character == 13 then  -- Enter key
                if batchText.getText == ""  then batchText.setText("0") end
                break
            elseif character == 8 then  -- Backspace key
                local currentText = batchText.getText()
                batchText.setText(currentText:sub(1, -2))
            else
                local letter = string.char(character)
                local currentText = batchText.getText()
                batchText.setText(currentText .. letter)
            end
        end
        return {
            location = arrayIndex,
            batch = tonumber(batchText.getText())
        }
    end
    batchText = component.glasses.addTextLabel()
    batchText.setScale(0.9)
    batchText.setPosition(x+10, y+20)
    batchText.setText(tostring(argsTable.batch))
    local amount = widgetsAreUs.titleBox(x+70, y+10, 75, 20, {1, 1, 1}, 0.8, "Amount", 0.7)
    local option
    amount.onClick = function()
        while true do
            if option.getText == "0" then option.setText("") end
            local _, _, _, character, _ = event.pull("hud_keyboard")
            if character == 13 then  -- Enter key
                if option.getText == ""  then option.setText("0") end
                break
            elseif character == 8 then  -- Backspace key
                local currentText = option.getText()
                option.setText(currentText:sub(1, -2))
            else
                local letter = string.char(character)
                local currentText = option.getText()
                option.setText(currentText .. letter)
            end
        end
        return {
            location = arrayIndex,
            amount = tonumber(option.getText())
        }
    end
    option = component.glasses.addTextLabel()
    option.setScale(0.9)
    option.setPosition(x+70, y+20)
    option.setText(tostring(argsTable.amount))

    return {
        background = background,
        batch = batch,
        amount = amount,
        getBatch = function()
            return batchText.getText()
        end,
        getAmount = function()
            return option.getText()
        end,
        setBatch = function(num)
            batchText.setText(tostring(num))
        end,
        setAmount = function (num)
            option.setText(tostring(num))
        end,
        getItemStack = function()
            return itemStack
        end,
        setVisible = function(visible)
            background.setVisible(visible)
            batch.setVisible(visible)
            batchText.setVisible(visible)
            amount.setVisible(visible)
            option.setVisible(visible)
        end,
        remove = function()
            amount.remove()
            background.remove()
            batch.remove()
            component.glasses.removeObject(batchText.getID())
            component.glasses.removeObject(option.getID())
            amount = nil
            background = nil
            batch = nil
            batchText = nil
            option = nil
        end
    }
end

function widgetsAreUs.configSingleString(x, y, width, titleText)
    local background = widgetsAreUs.createBox(x, y, width, 60, {0.6, 0.6, 0.6}, 0.8)
    local title = component.glasses.addTextLabel()
    title.setScale(1.2)
    title.setPosition(x+15, y+4)
    title.setText(titleText)

    local option = component.glasses.addTextLabel()
    option.setScale(1.5)
    option.setPosition(x+5, y+32)
    option.setText("Set to unlock functionality")

    return {
        background = background,
        master = title,
        option = option,
        setVisible = function(visible)
            background.setVisible(visible)
            title.setVisible(visible)
            option.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(title.getID())
            component.glasses.removeObject(option.getID())
            background = nil
            title = nil
            option = nil
        end,
        onClick = function()
            background.setColor(1, 1, 1)
            option.setText("")
            while true do
                local _, _, _, character, _ = event.pull("hud_keyboard")
                if character == 13 then  -- Enter key
                    if gimpHelper.trim(option.getText()) == ""  then option.setText("Set me or I won't go") end
                    background.setColor(0.6, 0.6, 0.6)
                    local name = gimpHelper.trim(title.getText())
                    local str = gimpHelper.trim(option.getText())
                    event.push("config_set", name, str)
                    break
                elseif character == 8 then  -- Backspace key
                    local currentText = option.getText()
                    option.setText(currentText:sub(1, -2))
                else
                    local letter = string.char(character)
                    local currentText = option.getText()
                    option.setText(currentText .. letter)
                end
            end
        end,
        load = function(tbl)
            local master = gimpHelper.trim(title.getText())
            if tbl[master] then
                option.setText(tbl[master])
            end
        end
    }
end

function widgetsAreUs.configCheck(x, y, master)
    local background = widgetsAreUs.createBox(x, y, 22, 22, {0, 0, 0}, 0.8)
    local backgroundInterior = widgetsAreUs.createBox(x+3, y+3, 16, 16, {1, 1, 1}, 0.8)
    local check = component.glasses.addTextLabel()
    check.setScale(1.0)
    check.setPosition(x+2, y+2)
    check.setText("")
    return {
        background = background,
        master = master,
        option = gimpHelper.trim(check.getText()),
        setVisible = function(visible)
            background.setVisible(visible)
            backgroundInterior.setVisible(visible)
            check.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(backgroundInterior.getID())
            component.glasses.removeObject(check.getID())
            background = nil
            backgroundInterior = nil
            check = nil
        end,
        onClick = function()
            if gimpHelper.trim(check.getText()) == "" then
                check.setText("X")
                event.push("config_set", master, true)
            else
                check.setText("")
                event.push("config_set", master, false)
            end
        end,
        load = function (tbl)
            if tbl[master] then
                check.setText(tbl[master])
            end
        end
    }
end

function widgetsAreUs.configEntryOnly(x, y, width, master)
    local background = widgetsAreUs.createBox(x, y, width, 60, {0.6, 0.6, 0.6}, 0.8)

    local option = component.glasses.addTextLabel()
    option.setScale(1.5)
    option.setPosition(x+5, y+32)
    option.setText("Set to unlock functionality")

    return {
        background = background,
        master = master,
        option = option,
        setVisible = function(visible)
            background.setVisible(visible)
            option.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(option.getID())
            background = nil
            option = nil
        end,
        onClick = function()
            background.setColor(1, 1, 1)
            option.setText("")
            while true do
                local _, _, _, character, _ = event.pull("hud_keyboard")
                if character == 13 then  -- Enter key
                    if gimpHelper.trim(option.getText()) == ""  then option.setText("Set me or I won't go") end
                    background.setColor(0.6, 0.6, 0.6)
                    local str = gimpHelper.trim(option.getText())
                    event.push("config_set", master, str)
                    break
                elseif character == 8 then  -- Backspace key
                    local currentText = option.getText()
                    option.setText(currentText:sub(1, -2))
                else
                    local letter = string.char(character)
                    local currentText = option.getText()
                    option.setText(currentText .. letter)
                end
            end
        end,
        load = function(tbl)
            if tbl[master] then
                option.setText(tbl[master])
            end
        end
    }
end

function widgetsAreUs.staticText(x, y, textToDisplay, scale)
    local text = component.glasses.addTextLabel()
    text.setScale(scale)
    text.setPosition(x, y)
    text.setText(textToDisplay)

    return {
        setVisible = function(visible)
            text.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(text.getID())
            text = nil
        end
    }
end

function widgetsAreUs.symbolBox(x, y, symbolText, colorOrGreen)
    if not colorOrGreen then colorOrGreen = {0, 0, 1} end
    local background = widgetsAreUs.createBox(x, y, 20, 20, colorOrGreen, 0.8)
    local symbol = component.glasses.addTextLabel()
    symbol.setText(symbolText)
    symbol.setScale(2)
    symbol.setPosition(x+3, y+3)
    return background
end

return widgetsAreUs