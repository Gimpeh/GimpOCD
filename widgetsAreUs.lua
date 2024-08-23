--widgetsAreUs.lua
local component = require("component")
local event = require("event")
local gimpHelper = require("gimpHelper")

local glasses = component.glasses

local widgetsAreUs = {}

-----------------------------------------
---Factory Functions

function widgetsAreUs.attachCoreFunctions(obj)
    if obj.getID then
        obj.remove = function()
            component.glasses.removeObject(obj.getID())
            obj = nil
        end
    elseif type(obj) == "table" then
        obj.remove = function()
            for k, v in pairs(obj) do
                if type(v) == "table" and v.remove then
                    v.remove()
                    obj[k] = nil
                elseif type(v) == "table" and v.getID then
                    component.glasses.removeObject(v.getID())
                    obj[k] = nil
                else
                    obj[k] = nil
                end
            end
            obj = nil
        end
    end
    if not obj.setVisible then
        obj.setVisible = function(visible)
            for k, v in pairs(obj) do
                if type(v) == "table" and v.setVisible then
                    v.setVisible(visible)
                end
            end
        end
    end
    return obj
end

function widgetsAreUs.attachOnClick(obj, func)
    obj.onClick = function(...)
        return func(obj, ...)
    end
    return obj
end

function widgetsAreUs.attachUpdate(obj, func)
    obj.update = function(...)
        return func(obj, ...)
    end
    return obj
end

-----------------------------------------
---Deprecated, use element.box.contains(x, y) instead

function widgetsAreUs.isPointInBox(x, y, box)
    return x >= box.x and x <= box.x2 and y >= box.y and y <= box.y2
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

function widgetsAreUs.text(x, y, text1, scale)
    local text = glasses.addTextLabel()
    text.setPosition(x, y)
    text.setScale(scale)
    text.setText(text1)
    return widgetsAreUs.attachCoreFunctions(text)
end

function widgetsAreUs.textBox(x, y, width, height, color, alpha, text, textScale, xOffset, yOffset)
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + (xOffset or 5), y + (yOffset or 5), text, textScale or 1.5)
    return widgetsAreUs.attachCoreFunctions{box = box, text = text}
end

-----------------------------------------
---Specific Abstractions

function widgetsAreUs.check(x, y)
    local box = widgetsAreUs.createBox(x, y, 25, 25, {0, 0, 0}, 0.8)
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
    local symbol = widgetsAreUs.text(x+3, y+3, symbolText, 2)
    return widgetsAreUs.attachCoreFunctions{box = box, symbol = symbol, onClick = func}
end

function widgetsAreUs.titleBox(x, y, width, height, color, alpha, text1)
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + 20, y + 2, text1, 0.9)
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

function widgetsAreUs.levelMaintainer(x, y, argsTable)
    local itemStack = argsTable.itemStack
    local box = widgetsAreUs.titleBox(x, y, 150, 30, {1, 0.2, 1}, 0.8, itemStack.label)

    local batchText = widgetsAreUs.titleBox(x + 5, y + 10, 60, 20, {1, 1, 1}, 0.8, "Batch")
    local batch = widgetsAreUs.text(x + 5, y + 20, tostring(argsTable.batch), 0.9)
    batch.onClick = function()
        batch.setText(tostring(gimpHelper.handleTextInput(batch)))
        local args = {batch = gimpHelper.trim(batch.getText()), location = argsTable.location}
        return args
    end

    local amountText = widgetsAreUs.titleBox(x + 70, y + 10, 75, 20, {1, 1, 1}, 0.8, "Amount")
    local amount = widgetsAreUs.text(x + 70, y + 20, tostring(argsTable.amount), 0.9)
    amount.onClick = function()
        amount.setText(tostring(gimpHelper.handleTextInput(amount)))
        local args = {amount = gimpHelper.trim(amount.getText()), location = argsTable.location}
        return args
    end

    return widgetsAreUs.attachCoreFunctions({box = box.box, boxText = box.text, batch = batch, amount = amount, itemStack = itemStack, batchText = batchText, amountText = amountText, onClick = function(x1, y1)
        if batchText.box.contains(x1, y1) then
            batch.onClick()
        elseif amountText.box.contains(x1, y1) then
            amount.onClick()
        end
    end,
    update = function(index)
        local args = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
        if args and args[index] then
            batch.setText(tostring(args[index].batch))
            amount.setText(tostring(args[index].amount))
        end
    end})
end

function widgetsAreUs.itemBox(x, y, itemStack)
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

    return widgetsAreUs.attachCoreFunctions({box = background, name = name, icon = icon, amount = amount, itemStack = itemStack,
    update = function()
        local updatedItemStack = component.me_interface.getItemsInNetwork(itemStack)[1]
        amount.setText(tostring(updatedItemStack.size))
    end})
end

function widgetsAreUs.initText(x, y, text1)
    local text = widgetsAreUs.text(x+5, y+5, text1, 1.5)
    local box = widgetsAreUs.createBox(x, y, 400, 200, {0.8, 0, 0}, 0.7)
    return widgetsAreUs.attachCoreFunctions({text = text, box = box})
end

return widgetsAreUs