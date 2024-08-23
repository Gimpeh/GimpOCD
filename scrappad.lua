--scrappad.lua
local widgetsAreUs = require("widgetsAreUs")
local gimpHelper = require("gimpHelper")

local scrappad = {}

function scrappad.numberBox(x, y, key, titleText)
    local title = widgetsAreUs.textBox(x, y, 55, 25, {0.8, 0.8, 0.8}, 0.8, titleText, 1, 5, 5)
    local option = widgetsAreUs.textBox(x+55, y, 25, 25, {1, 1, 1}, 0.9, "num", 1, 5, 5)
    local value
    local function setValue(newValue)
        option.text.setText(newValue)
        value = newValue
    end
    return widgetsAreUs.attachCoreFunctions({title = title, key = key, value = value, option = option, setValue = setValue,
    getValue = function()
        return value
    end,
    onClick = function()
        setValue(gimpHelper.handleTextInput(option.text))
    end})
end

function scrappad.longerNumberBox(x, y, key, titleText)
    local title = widgetsAreUs.textBox(x, y, 55, 25, {0.8, 0.8, 0.8}, 0.8, titleText, 1, 0, 0)
    local option = widgetsAreUs.textBox(x + 55, y, 55, 25, {1, 1, 1}, 0.9, "num", 1, 0, 0)
    local value
    local function setValue(newValue)
        option.text.setText(newValue)
        value = newValue
    end
    return widgetsAreUs.attachCoreFunctions({box = option.box, title = title, key = key, value = value, option = option, setValue = setValue,
    getValue = function()
        return value
    end,
    onClick = function()
        setValue(gimpHelper.handleTextInput(option.text))
    end})
end

function scrappad.checkboxFullLine(x, y, key, titleText)
    local title = widgetsAreUs.textBox(x, y, 135, 25, {0.8, 0.8, 0.8}, 0.8, titleText, 1, 0, 0)
    local check = widgetsAreUs.check(x + 135, y)
    local value
    local function setValue()
        if gimpHelper.trim(check.check.getText()) == "" then
            check.check.setText("X")
        else
            check.check.setText("")
        end
        value = gimpHelper.trim(check.check.getText())
    end
    return widgetsAreUs.attachCoreFunctions({box = check.box, title = title, key = key, value = value, check = check, setValue = setValue,
    getValue = function()
        return value
    end,
    onClick = function()
        setValue()
    end})
end

return scrappad