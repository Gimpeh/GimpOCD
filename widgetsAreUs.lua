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
    function box.remove()
        glasses.removeObject(box.getID())
        box = nil
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
    local box = glasses.addRect()
    box.setSize(height, width)
    box.setPosition(x, y)
    box.setColor(100, 100, 100)

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
            box.setVisible(visible)
            bar.setVisible(visible)
            titleText.setVisible(visible)
            text.setVisible(visible)
        end,
		remove = function()
			glasses.removeObject(box.getID())
			glasses.removeObject(bar.getID())
			glasses.removeObject(titleText.getID())
			glasses.removeObject(text.getID())
			box = nil
			bar = nil
			titleText = nil
			text = nil
		end
    }
end

function widgetsAreUs.maintenanceAlert(x, y, width, height)
    local box = glasses.addRect()
    box.setSize(height, width)
    box.setPosition(x, y)
    box.setColor(255, 0, 0)  -- Red
    box.setAlpha(0.5)  -- Semi-transparent

    local text = glasses.addTextLabel()
    text.setPosition(x + 10, y + 10)
    text.setColor(255, 255, 255)
    text.setScale(1.2)

    return {
        show = function(message)
            box.setVisible(true)
            text.setText(message)
            text.setVisible(true)
        end,
        hide = function()
            box.setVisible(false)
            text.setVisible(false)
        end,
		remove = function()
			glasses.removeObject(box.getID())
			glasses.removeObject(text.getID())
			box = nil
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
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local title = component.glasses.addTextLabel()
    title.setScale(textScale)
    title.setPosition(x+3, y+2)
    title.setText(titleText)

    return {
        box = box,
        title = title,
        onClick = function()
            print("reassign me")
        end,
        setVisible = function(visible)
            box.setVisible(visible)
            title.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(box.getID())
            component.glasses.removeObject(title.getID())
            box = nil
            title = nil
        end
    }
end

function widgetsAreUs.levelMaintainer(x, y, argsTable, arrayIndex)
    local itemStack = argsTable.itemStack
    local box = widgetsAreUs.titleBox(x, y, 150, 30, {1, 0.2, 1}, 0.8, itemStack.label, 0.9)

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
        box = box,
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
            box.setVisible(visible)
            batch.setVisible(visible)
            batchText.setVisible(visible)
            amount.setVisible(visible)
            option.setVisible(visible)
        end,
        remove = function()
            amount.remove()
            box.remove()
            batch.remove()
            component.glasses.removeObject(batchText.getID())
            component.glasses.removeObject(option.getID())
            amount = nil
            box = nil
            batch = nil
            batchText = nil
            option = nil
        end
    }
end

function widgetsAreUs.configSingleString(x, y, width, titleText)
    local box = widgetsAreUs.createBox(x, y, width, 20, {0.6, 0.6, 0.6}, 0.8)
    local title = component.glasses.addTextLabel()
    title.setScale(1.2)
    title.setPosition(x+15, y+4)
    title.setText(titleText)

    local option = component.glasses.addTextLabel()
    option.setScale(1.5)
    option.setPosition(x+5, y+32)
    option.setText("Set Me")

    return {
        box = box,
        option = option,
        setVisible = function(visible)
            box.setVisible(visible)
            title.setVisible(visible)
            option.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(box.getID())
            component.glasses.removeObject(title.getID())
            component.glasses.removeObject(option.getID())
            box = nil
            title = nil
            option = nil
        end,
        onClick = function()
            box.setColor(1, 1, 1)
            option.setText("")
            while true do
                local _, _, _, character, _ = event.pull("hud_keyboard")
                if character == 13 then  -- Enter key
                    if gimpHelper.trim(option.getText()) == ""  then option.setText("Set me or I won't go") end
                    box.setColor(0.6, 0.6, 0.6)
                    local str = gimpHelper.trim(option.getText())
                    event.push("config_change")
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
    }
end

function widgetsAreUs.configCheck(x, y, index, keyName)
    local box = widgetsAreUs.createBox(x, y, 22, 22, {0, 0, 0}, 0.8)
    local backgroundInterior = widgetsAreUs.createBox(x+3, y+3, 16, 16, {1, 1, 1}, 0.8)
    local check = component.glasses.addTextLabel()
    check.setScale(1.0)
    check.setPosition(x+2, y+2)
    check.setText("")
    return {
        box = box,
        option = check,
        setVisible = function(visible)
            box.setVisible(visible)
            backgroundInterior.setVisible(visible)
            check.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(box.getID())
            component.glasses.removeObject(backgroundInterior.getID())
            component.glasses.removeObject(check.getID())
            box = nil
            backgroundInterior = nil
            check = nil
        end,
        onClick = function()
            if gimpHelper.trim(check.getText()) == "" then
                check.setText("X")
                event.push("config_change")
            else
                check.setText("")
                event.push("config_change")
            end
        end
    }
end

function widgetsAreUs.staticText(x, y, textToDisplay, scale)
    local box = widgetsAreUs.createBox(x, y, 0, 0, {0.6, 0.6, 0.6}, 0.0)
    local text = component.glasses.addTextLabel()
    text.setScale(scale)
    text.setPosition(x, y)
    text.setText(textToDisplay)

    return {
        box = box,
        setText = function(newText)
            text.setText(newText)
        end,
        setVisible = function(visible)
            text.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(text.getID())
            text = nil
        end,
        onClick = function()
            print("I'm a static text box")
        end
    }
end

function widgetsAreUs.symbolBox(x, y, symbolText, colorOrGreen, func)
    if not colorOrGreen then colorOrGreen = {0, 0, 1} end
    local box = widgetsAreUs.createBox(x, y, 20, 20, colorOrGreen, 0.8)
    local symbol = component.glasses.addTextLabel()
    symbol.setText(symbolText)
    symbol.setScale(2)
    symbol.setPosition(x+3, y+3)
    return {
        box = box,
        remove = function()
            component.glasses.removeObject(box.getID())
            component.glasses.removeObject(symbol.getID())
            box = nil
            symbol = nil
        end,
        setVisible = function(visible)
            box.setVisible(visible)
            symbol.setVisible(visible)
        end,
        onclick = func
    }
end

function widgetsAreUs.levelMaintainerOptions(x, y, tbl, index)
    local box = widgetsAreUs.titleBox(x, y, 150, 30, {1, 0.2, 1}, 0.8, tbl.itemStack.label, 0.9)
    local batch = widgetsAreUs.staticText(x+5, y+10, "Batch: " .. tostring(tbl.batch), 0.7)
    local amount = widgetsAreUs.staticText(x+70, y+10, "Amount: " .. tostring(tbl.amount), 0.7)

    return {
        box = box,
        onClick = function()
            local configurations = require("configurations")
            configurations.createLevelMaintainerConfig()
            
            event.push("load_config", "/home/programData/levelMaintainerConfig.data", index)
        end,
        setVisible = function(visible)
            box.setVisible(visible)
            batch.setVisible(visible)
            amount.setVisible(visible)
        end,
        remove = function()
            box.remove()
            batch.remove()
            amount.remove()
            box = nil
            batch = nil
            amount = nil
        end
    }
end

function widgetsAreUs.textBox(x, y, width, height, text, index, keyName)
    local box = widgetsAreUs.createBox(x, y, width, height, {0.6, 0.6, 0.6}, 0.8)
    local textLabel = component.glasses.addTextLabel()
    textLabel.setPosition(x+5, y+5)
    textLabel.setText(text)

    return {
        box = box,
        option = textLabel,
        setText = function(newText)
            textLabel.setText(newText)
        end,
        setVisible = function(visible)
            box.setVisible(visible)
            textLabel.setVisible(visible)
        end,
        remove = function()
            component.glasses.removeObject(box.getID())
            component.glasses.removeObject(textLabel.getID())
            box = nil
            textLabel = nil
        end,
        onClick = function()
            local configurations = require("configurations")
            local derp = initText:new(100, 100, "Click all the way to the right")
            _, _, _, x, y = event.pull("hud_click")
            configurations.gc.screenSizeWidth.setText(x)
            derp:remove()
            derp = initText:new(100, 100, "Click all the way to the bottom")
            _, _, _, x, y = event.pull("hud_click")
            configurations.gc.screenSizeHeight.setText(y)
            derp:remove()
            derp = nil
            event.push("config_change")
        end
    }
end

return widgetsAreUs