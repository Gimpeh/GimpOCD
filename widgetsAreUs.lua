local component = require("component")
local event = require("event")
local gimpHelper = require("gimpHelper")
local c = require("gimp_colors")

local glasses = component.glasses

local widgetsAreUs = {}

local verbosity = false
local print = print

if not verbosity then
    print = function()
        return false
    end
end

-----------------------------------------
---Factory Functions

function widgetsAreUs.attachCoreFunctions(obj)
    print("widgetsAreUs - Line 11: Attaching core functions.")
    if obj.getID then
        print("widgetsAreUs - Line 13: Object has getID, attaching remove function.")
        obj.remove = function()
            component.glasses.removeObject(obj.getID())
            obj = nil
        end
    elseif type(obj) == "table" then
        print("widgetsAreUs - Line 19: Object is a table, attaching recursive remove function.")
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
        print("widgetsAreUs - Line 33: Attaching setVisible function.")
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
    print("widgetsAreUs - Line 44: Attaching onClick function.")
    obj.onClick = function(...)
        return func(obj, ...)
    end
    return obj
end

function widgetsAreUs.attachToOnClick(obj, func)
    local currentOnClick = obj.onClick
    print("widgetsAreUs - Line 44: Attaching onClick function.")
    obj.onClick = function(...)
        if currentOnClick then
            currentOnClick()
        end
        return func(obj, ...)
    end
    return obj
end

function widgetsAreUs.attachUpdate(obj, func)
    print("widgetsAreUs - Line 51: Attaching update function.")
    obj.update = function(...)
        return func(obj, ...)
    end
    return obj
end

-----------------------------------------
---Helper Functions

function widgetsAreUs.flash(obj, color, timer)
    if not color then color = c.clicked end
    if not timer then timer = 0.2 end
    print("widgetsAreUs - Line 61: Flashing object.")
    local originalColor = {obj.getColor()}
    obj.setColor(table.unpack(color))
    event.timer(timer, function()
        obj.setColor(table.unpack(originalColor))
    end)
end

function widgetsAreUs.isPointInBox(x, y, box)
    print("widgetsAreUs - Line 60: Checking if point is in box.")
    return x >= box.x and x <= box.x2 and y >= box.y and y <= box.y2
end

-----------------------------------------
---Abstract

function widgetsAreUs.createBox(x, y, width, height, color, alpha)
    print("widgetsAreUs - Line 66: Creating a box.")
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
    print("widgetsAreUs - Line 82: Creating a text label.")
    local text = glasses.addTextLabel()
    text.setPosition(x, y)
    text.setScale(scale)
    text.setText(text1)
    return widgetsAreUs.attachCoreFunctions(text)
end

function widgetsAreUs.textBox(x, y, width, height, color, alpha, text, textScale, xOffset, yOffset)
    print("widgetsAreUs - Line 91: Creating a text box.")
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + (xOffset or 5), y + (yOffset or 5), text, textScale or 1.5)
    return widgetsAreUs.attachCoreFunctions{box = box, text = text}
end

-----------------------------------------
---Specific Abstractions

function widgetsAreUs.check(x, y)
    print("widgetsAreUs - Line 101: Creating a checkbox.")
    local box = widgetsAreUs.createBox(x, y, 25, 25, {0.784, 0.902, 0.788}, 0.8)
    local check = component.glasses.addTextLabel()
    check.setScale(1.0)
    check.setPosition(x+10, y+10)
    check.setText("")
    return widgetsAreUs.attachCoreFunctions({box = box, check = check, 
    onClick = function()
        if gimpHelper.trim(check.getText()) == "" then
            check.setText("X")
        else
            check.setText("")
        end
    end})    
end

function widgetsAreUs.symbolBox(x, y, symbolText, colorOrGreen, func)
    print("widgetsAreUs - Line 118: Creating a symbol box.")
    if not colorOrGreen then colorOrGreen = c.lime end
    local box = widgetsAreUs.createBox(x, y, 20, 20, colorOrGreen, 0.8)
    local symbol = widgetsAreUs.text(x+3, y+3, symbolText, 2)
    return widgetsAreUs.attachCoreFunctions{box = box, symbol = symbol, onClick = func}
end

function widgetsAreUs.titleBox(x, y, width, height, color, alpha, text1)
    print("widgetsAreUs - Line 127: Creating a title box.")
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + 20, y + 2, text1, 0.9)
    return widgetsAreUs.attachCoreFunctions{box = box, text = text}
end

-----------------------------------------
---Pop-up stuff

function widgetsAreUs.alertMessage(color, message, timer)
    print("widgetsAreUs - Line 136: Creating an alert message.")
    local box = widgetsAreUs.createBox(100, 100, 200, 100, color or c.brightred, 0.6)

    local text = widgetsAreUs.text(110, 110, message, 1.2)

    local function remove() component.glasses.removeObject(box.getID()) component.glasses.removeObject(text.getID()) text = nil box = nil end
    event.timer(timer, remove)

    return {remove = remove}
end

function widgetsAreUs.beacon(x, y, z, color)
    print("widgetsAreUs - Line 147: Creating a beacon.")
    local element = component.glasses.addDot3D()
    element.set3DPos(x, y, z)
    element.setColor(color or c.azure)
    element.setViewDistance(500)
    element.setScale(1)
    return widgetsAreUs.attachCoreFunctions({ beacon = element })
end

-----------------------------------------
---Specific

function widgetsAreUs.levelMaintainer(x, y, argsTable)
    print("widgetsAreUs - Line 157: Creating a level maintainer widget.")
    local itemStack = argsTable.itemStack
    local box = widgetsAreUs.titleBox(x, y, 150, 30, c.object, 0.8, itemStack.label)

    local batchText = widgetsAreUs.titleBox(x + 5, y + 10, 60, 20, c.configsetting, 0.8, "Batch")
    local batch = widgetsAreUs.text(x + 5, y + 20, tostring(argsTable.batch), 0.9)
    batch.onClick = function()
        batch.setText(tostring(gimpHelper.handleTextInput(batch)))
        local args = {batch = gimpHelper.trim(batch.getText()), location = argsTable.location}
        return args
    end

    local amountText = widgetsAreUs.titleBox(x + 70, y + 10, 75, 20, c.configsetting, 0.8, "Amount")
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
    print("widgetsAreUs - Line 197: Creating an item box.")
    local background = widgetsAreUs.createBox(x, y, 120, 40, c.object, 0.8)

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
        local updatedItemStack = component.me_interface.getItemsInNetwork({label = itemStack.label, name = itemStack.name, damage = itemStack.damage})[1]
        amount.setText(tostring(updatedItemStack.size))
    end})
end

function widgetsAreUs.initText(x, y, text1)
    print("widgetsAreUs - Line 222: Initializing text.")
    local text = widgetsAreUs.text(x+10, y+10, text1, 1.5)
    local box = widgetsAreUs.createBox(x, y, 400, 25, {1, 1, 1}, 0.7)
    return widgetsAreUs.attachCoreFunctions({text = text, box = box})
end

-----------------
---config widgets

function widgetsAreUs.machineElementConfigEdition(x, y, theData, index)
    print("widgetsAreUs - Line 231: Creating machine element config edition.")
    local box = widgetsAreUs.createBox(x, y, 120, 34, c.object, 0.8)
    local name = widgetsAreUs.text(x+5, y+5, theData.newName, 1)
    local xyzTitle = widgetsAreUs.titleBox(x + 3, y + 14, 55, 20, c.objectinfo, 0.8, "XYZ")
    local xyzText = widgetsAreUs.text(x+5, y+26, theData.xyz.x .. ", " .. theData.xyz.y .. ", " .. theData.xyz.z, 0.9)
    local groupText = widgetsAreUs.text(x+60, y + 16, theData.groupName, 0.8)
    return widgetsAreUs.attachCoreFunctions({box = box, name = name, xyzText = xyzText, groupText = groupText, xyzTitle = xyzTitle})
end

-----------------------------------------
---Configs Value Widgets

function widgetsAreUs.numberBox(x, y, key, titleText)
    print("widgetsAreUs - Line 244: Creating number box.")
    local title = widgetsAreUs.textBox(x, y, 55, 25, c.configsettingtitle, 0.8, titleText, 1, 5, 5)
    local option = widgetsAreUs.textBox(x+55, y, 25, 25, c.configsetting, 0.9, "num", 1, 5, 5)
    local function setValue(newValue)
        option.text.setText(newValue)
    end
    return widgetsAreUs.attachCoreFunctions({title = title, key = key, option = option, setValue = setValue,
    onClick = function()
        setValue(gimpHelper.handleTextInput(option.text))
    end,
    getValue = function()
        return gimpHelper.trim(option.text.getText())
    end})
end

function widgetsAreUs.longerNumberBox(x, y, key, titleText, color)
    print("widgetsAreUs - Line 261: Creating longer number box.")
    local title = widgetsAreUs.textBox(x, y, 65, 25, color or c.configsettingtitle, 0.8, titleText, 1, 2, 10)
    local option = widgetsAreUs.textBox(x + 65, y, 95, 25, c.configsetting, 0.9, "num", 1, 2, 10)
    local function setValue(newValue)
        option.text.setText(newValue)
    end
    return widgetsAreUs.attachCoreFunctions({title = title, key = key, option = option, setValue = setValue,
    onClick = function()
       setValue(gimpHelper.handleTextInput(option.text))
    end,
    getValue = function()
        return gimpHelper.trim(option.text.getText())
    end})
end

function widgetsAreUs.checkboxFullLine(x, y, key, titleText, color)
    print("widgetsAreUs - Line 278: Creating checkbox full line.")
    local title = widgetsAreUs.textBox(x, y, 135, 25, color or c.alertsettingtitle, 0.8, titleText, 1, 0, 0)
    local option = widgetsAreUs.check(x + 135, y)
    local function setValue(absoluteValue)
        if absoluteValue then
            option.check.setText(absoluteValue)
        elseif gimpHelper.trim(option.check.getText()) == "" then
            option.check.setText("X")
        else
            option.check.setText("")
        end
    end
    return widgetsAreUs.attachCoreFunctions({title = title, key = key, option = option, setValue = setValue,
    onClick = function()
        setValue()
    end,
    getValue = function()
        return tostring(gimpHelper.trim(option.check.getText()) == "X")
    end})
end

function widgetsAreUs.checkBoxHalf(x, y, key, titleText, color)
    print("widgetsAreUs - Line 295: Creating checkbox half line.")
    local title = widgetsAreUs.textBox(x, y, 55, 25, color or c.alertsettingtitle, 0.8, titleText, 0.8, 5, 5)
    local option = widgetsAreUs.check(x + 55, y)
    local function setValue(absoluteValue)
        if absoluteValue then
            option.check.setText(absoluteValue)
        elseif gimpHelper.trim(option.check.getText()) == "" then
            option.check.setText("X")
        else
            option.check.setText("")
        end
    end
    return widgetsAreUs.attachCoreFunctions({title = title, key = key, option = option, setValue = setValue,
    onClick = function()
        setValue()
    end,
    getValue = function()
        return tostring(gimpHelper.trim(option.check.getText()) == "X")
    end})
end

function widgetsAreUs.textBoxWithTitle(x, y, key, titleText)
    print("widgetsAreUs - Line 312: Creating text box with title.")
    local title = widgetsAreUs.titleBox(x, y, 160, 25, c.configsetting, 0.8, titleText)
    local option = widgetsAreUs.text(x + 10, y+10, "string", 1)
    local function setValue(newValue)
        option.setText(newValue)
    end
    return widgetsAreUs.attachCoreFunctions({box = title.box, title = title.text, key = key, option = option, setValue = setValue,
    onClick = function()
        setValue(gimpHelper.handleTextInput(option))
    end,
    getValue = function()
        return gimpHelper.trim(option.getText())
    end})
end

function widgetsAreUs.configsButtonHalf(x, y, text1, text2, color, func)
    print("widgetsAreUs - Line 329: Creating configs button half.")
    local title = widgetsAreUs.textBox(x, y, 60, 25, c.orange, 0.8, text1, 1, 5, 5)
    local button = widgetsAreUs.textBox(x + 60, y, 42, 25, color, 0.9, text2, 1, 5, 5)
    return widgetsAreUs.attachCoreFunctions({title = title, option = button, onClick = func})
end

function widgetsAreUs.numberBoxLongerText(x, y, key, titleText)
    print("widgetsAreUs - Line 339: Creating number box longer text.")
    local title = widgetsAreUs.textBox(x, y, 140, 25, c.configsettingtitle, 0.8, titleText, 1, 0, 5)
    local option = widgetsAreUs.textBox(x+140, y, 20, 25, c.configsetting, 0.9, "num", 1, 5, 5)
    local function setValue(newValue)
        option.text.setText(newValue)
    end
    return widgetsAreUs.attachCoreFunctions({title = title, key = key, option = option, setValue = setValue,
    onClick = function()
        setValue(gimpHelper.handleTextInput(option.text))
    end,
    getValue = function()
        return gimpHelper.trim(option.text.getText())
    end})
end

print("widgetsAreUs - Line 351: Loaded widgetsAreUs module successfully.")

return widgetsAreUs