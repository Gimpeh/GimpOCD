--scrappad.lua
local widgetsAreUs = require("widgetsAreUs")

local scrappad = {}

local function setValue(self, newValue)
    self.option.text.setText(newValue)
    self.value = newValue
end

function scrappad.numberBox(x, y, key, titleText)
    local title = widgetsAreUs.textBox(x, y, 55, 25, {0.8, 0.8, 0.8}, 0.8, titleText, 1, 5, 5)
    local option = widgetsAreUs.textBox(x+55, y, 25, 25, {1, 1, 1}, 0.9, "num", 1, 5, 5)
    local value
    return widgetsAreUs.attachCoreFunctions({title, key = key, value = value, option = option, setValue = function(newValue) option.text.setText(newValue) end })
end

function scrappad.longerNumberBox(x, y, key, titleText)
    local title = widgetsAreUs.textBox(x, y, 55, 25, {0.8, 0.8, 0.8}, 0.8, titleText, 1, 0, 0)
    local option = widgetsAreUs.textBox(x + 55, y, 55, 25, {1, 1, 1}, 0.9, "num", 1, 0, 0)
    local value
    return widgetsAreUs.attachOnClick(widgetsAreUs.attachCoreFunctions({title, key = key, value = value, option = option, setValue = function(newValue) option.text.setText(newValue) end }), setValue)
end

function scrappad.checkboxFullLine(x, y, key, titleText)
    local title = widgetsAreUs.textBox(x, y, 135, 25, {0.8, 0.8, 0.8}, 0.8, titleText, 1, 0, 0)
    local check = widgetsAreUs.check(x + 135, y)
    local value
    return widgetsAreUs.attachCoreFunctions({title, key = key, value = value, check = check, setValue = function(newValue) check.onClick() (newValue) end })
end

return scrappad