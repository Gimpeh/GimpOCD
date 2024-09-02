local event = require("event")

local gimpHelper = {}

function gimpHelper.handleTextInput(textLabel)
    print("gimpHelper - Line 5: handleTextInput called")
    textLabel.setText("")
    while true do
        local _, _, _, character = event.pull("hud_keyboard")
        if character == 13 then  -- Enter key
            break
        elseif character == 8 then  -- Backspace key
            textLabel.setText(textLabel.getText():sub(1, -2))
        else
            textLabel.setText(textLabel.getText() .. string.char(character))
        end
    end
    local trimmedText = tostring(gimpHelper.trim(textLabel.getText()))
    return trimmedText
end

function gimpHelper.removeCommas(str)
    local result = string.gsub(str, ",", "")
    return result
end

function gimpHelper.extractNumbers(str)
    local numbers = {}
    for num in string.gmatch(str, "%d[,%d]*") do 
        num = string.gsub(num, ",", "")
        table.insert(numbers, tonumber(num))
    end
    return numbers
end

function gimpHelper.shorthandNumber(numberToConvert)
    local num = tonumber(numberToConvert)
    local units = {"", "k", "M", "B", "T", "Qua", "E", "Z", "Y"}
    local unitIndex = 1
    while num >= 1000 and unitIndex < #units do
        num = num / 1000
        unitIndex = unitIndex + 1
    end
    local convertedNumber = string.format("%.2f%s", num, units[unitIndex])
    return convertedNumber
end

function gimpHelper.distanceApartXZ(coordsOne, coordsTwo)
    local distanceX = math.abs((math.ceil(coordsOne.x) + 100000) - (math.ceil(coordsTwo.x) + 100000)) + 1
    local distanceZ = math.abs((math.ceil(coordsOne.z) + 100000) - (math.ceil(coordsTwo.z) + 100000)) + 1

    local distance = math.sqrt((distanceX^2) + (distanceZ^2))
    return distance
end

function gimpHelper.cleanBatteryStorageString(numberStr)
    local cleanStr = tostring(numberStr):gsub(",", ""):gsub("EU Stored: ", ""):gsub("EU", "")
    local result = tonumber(cleanStr)
    return result
end

function gimpHelper.calculatePercentage(currentAmountStr, maxAmount)
    local currentAmount = gimpHelper.cleanBatteryStorageString(currentAmountStr)
    local maxAmountNum = tonumber(maxAmount)

    if currentAmount >= maxAmountNum then
        currentAmount = math.floor(currentAmount / 1e8)
        maxAmountNum = math.floor(maxAmountNum / 1e8)
    end

    local percentage = (currentAmount / maxAmountNum) * 100
    return percentage
end

function gimpHelper.saveTable(tblToSave, filename)
    local function serialize(tbl)
        local result = "{"
        local first = true
        for k, v in pairs(tbl) do
            if not first then 
                result = result .. ","
            else 
                first = false 
            end

            local key = type(k) == "string" and k or "["..k.."]"
            local value
            if type(v) == "table" then
                value = serialize(v)
            elseif type(v) == "string" then
                value = string.format("%q", v)
            else
                value = tostring(v)
            end
            result = result .. key .. "=" .. value
        end
        return result .. "}"
    end

    local file, err = io.open(filename, "w")
    if not file then
        return false, "Unable to open file for writing"
    end

    file:write("return " .. serialize(tblToSave))
    file:close()
    return true
end

function gimpHelper.loadTable(filename)
    local file, err = io.open(filename, "r")
    if not file then
        return nil, "Unable to open file for reading"
    end

    local content = file:read("*a")
    file:close()
    local func = load(content)
    if not func or type(func) ~= "function" then
        return nil, "Unable to load file content"
    end
    local tbl = func()
    return tbl
end

function gimpHelper.trim(s)
    local trimmed = (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")

    return trimmed
end

function gimpHelper.capitalizeWords(str)
    print("gimpHelper - Line 145: capitalizeWords called with str =", tostring(str))
    local capitalized = str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest
    end)
    return capitalized
end

return gimpHelper