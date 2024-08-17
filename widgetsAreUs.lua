--widgetsAreUs.lua
local component = require("component")
local event = require("event")
local gimpHelper = require("gimpHelper")

local glasses = component.glasses

local widgetsAreUs = {}

-----------------------------------------
---Factory Functions

function widgetsAreUs.attachCoreFunctions(obj)
    obj.remove = function()
        for k, v in pairs(obj) do
            component.glasses.removeObject(v.getID())
            v = nil
        end
    end
    obj.setVisible = function(visible)
        for k, v in pairs(obj) do
            if type(v) == "table" and v.setVisible then
                v.setVisible(visible)
            end
        end
    end
    return obj
end

function widgetsAreUs.attachOnClick(obj, func)
    obj.onClick = func
    return obj
end

function widgetsAreUs.attachUpdate(obj, func)
    obj.update = func
    return obj
end

-----------------------------------------
---Abstract

function widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local box = glasses.addRect()

    box.setSize(height, width)
    box.setPosition(x, y)
    box.setColor(table.unpack(color))
    if alpha then box.setAlpha(alpha) end

    box.x = x box.x2 = x+width box.y = y box.y2 = y+height
    function box.contains(px, py)
        return px >= x and px <= box.x2 and py >= y and py <= box.y2
    end
    return widgetsAreUs.attachCoreFunctions(box)
end

function widgetsAreUs.text(x, y, text, scale)
    local text = glasses.addTextLabel()
    text.setPosition(x, y)
    text.setScale(scale)
    text.setText(text)
    return widgetsAreUs.attachCoreFunctions(text)
end

function widgetsAreUs.textBox(x, y, width, height, color, alpha, text, textScale, xOffset, yOffset)
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + (xOffset or 5), y + (yOffset or 5), text, textScale or 1.5)
    return widgetsAreUs.attachCoreFunctions{box = box, text = text}
end

-----------------------------------------
---Specific Abstractions

function widgetsAreUs.check(x, y, index, keyName)
    local box = widgetsAreUs.createBox(x, y, 22, 22, {0, 0, 0}, 0.8)
    local backgroundInterior = widgetsAreUs.createBox(x+3, y+3, 16, 16, {1, 1, 1}, 0.8)
    local check = component.glasses.addTextLabel()
    check.setScale(1.0)
    check.setPosition(x+2, y+2)
    check.setText("")
    return widgetsAreUs.attachCoreFunctions({box = box, check = check, backgroundInterior = backgroundInterior, 
    onClick = function()
        if gimpHelper.trim(check.getText()) == "" then
            check.setText("X")
        else
            check.setText("")
        end
    end})    
end

function widgetsAreUs.symbolBox(x, y, symbolText, colorOrGreen, func)
    if not colorOrGreen then colorOrGreen = {0, 0, 1} end
    local box = widgetsAreUs.createBox(x, y, 20, 20, colorOrGreen, 0.8)
    local symbol = component.glasses.addTextLabel()
    symbol.setText(symbolText)
    symbol.setScale(2)
    symbol.setPosition(x+3, y+3)
    return widgetsAreUs.attachCoreFunctions{box = box, symbol = symbol}
end

function widgetsAreUs.titleBox(x, y, width, height, color, alpha, text)
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + 20, y + 2, text, 0.9)
    return widgetsAreUs.attachCoreFunctions{box = box, text = text}
end

-----------------------------------------
---Pop-up stuff

function widgetsAreUs.alertMessage(color, message, timer)
    local box = widgetsAreUs.createBox(100, 100, 200, 100, color, 0.6)

    local text = widgetsAreUs.text(110, 110, message, 1.2)

    local function remove() component.glasses.removeObject(box.getID()) component.glasses.removeObject(text.getID()) text = nil box = nil end
    event.timer(timer, remove)

    return {remove = remove}
end

function widgetsAreUs.beacon(x, y, z, color)
	local element = component.glasses.addDot3D()
    -- -5.5, -46.5, -13.5
    element.set3DPos(x, y, z)
    element.setColor(255, 0, 0)
    element.setViewDistance(500)
    element.setScale(1)
	return widgetsAreUs.attachCoreFunctions({ beacon = element })
end

-----------------------------------------
---Specific

function widgetsAreUs.levelMaintainer(x, y, argsTable, arrayIndex)
    local itemStack = argsTable.itemStack
    local box = widgetsAreUs.titleBox(x, y, 150, 30, {1, 0.2, 1}, 0.8, itemStack.label)

    local batchText = widgetsAreUs.titleBox(x + 5, y + 5, 60, 20, {1, 1, 1}, 0.8, "Batch")
    local batch = widgetsAreUs.text(x + 5, y + 15, tostring(argsTable.batch), 0.9)
    batch.onClick = function()
        return { location = arrayIndex, batch = gimpHelper.handleTextInput(batch) }
    end

    local amountText = widgetsAreUs.titleBox(x + 70, y + 10, 75, 20, {1, 1, 1}, 0.8, "Amount")
    local amount = widgetsAreUs.text(x + 70, y + 20, tostring(argsTable.amount), 0.9)
    amount.onClick = function()
        return { location = arrayIndex, amount = gimpHelper.handleTextInput(amount) }
    end
    return widgetsAreUs.attachCoreFunctions({box = box, batch = batch, amount = amount, itemStack = itemStack})
end

function widgetsAreUs.machineConfig(x, y, tbl, index)
	local background = widgetsAreUs.createBox(x, y, 85, 12, {1, 1, 1}, 0.6)
	local name = widgetsAreUs.staticText(x+4, y+4, tbl.newMachineName, 1)

	return widgetsAreUs.attachCoreFunctions({box = background, name = name})
end

function widgetsAreUs.itemOptions(x, y, itemStack, index)
    local background = widgetsAreUs.createBox(x, y, 120, 40, {1, 0.8, 0.5}, 0.8)
    local name = widgetsAreUs.text(x+2, y+2, itemStack.label, 0.9)

    local icon = component.glasses.addItem()
    icon.setPosition(x, y+6)
    if component.database then
        component.database.clear(1)
        component.database.set(1, itemStack.name, itemStack.damage, itemStack.tag)
        icon.setItem(component.database.address, 1)
    end

    return widgetsAreUs.attachCoreFunctions({box = background, name = name, icon = icon,})
end

function widgetsAreUs.ItemBox(x, y, itemStack)
    local background = widgetsAreUs.createBox(x, y, 120, 40, {1, 0.8, 0.5}, 0.8)

    local name = widgetsAreUs.text(x+2, y+2, itemStack.label, 0.9)

    local icon = component.glasses.addItem()
    icon.setPosition(x, y+6)
    if component.database then
        component.database.clear(1)
        component.database.set(1, itemStack.name, itemStack.damage, itemStack.tag)
        icon.setItem(component.database.address, 1)
    end

    local amount = widgetsAreUs.text(x+30, y+18, tostring(itemStack.size), 1)

    return widgetsAreUs.attachCoreFunctions({background = background, name = name, icon = icon, amount = amount, 
    update = function()
        local updatedItemStack = component.me_interface.getItemsInNetwork(itemStack)[1]
        amount.setText(tostring(updatedItemStack.size))
    end})
end

return widgetsAreUs