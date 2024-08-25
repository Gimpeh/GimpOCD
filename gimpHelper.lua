local event = require("event")

local gimpHelper = {}

function gimpHelper.handleTextInput(textLabel)
    print("gimpHelper - Line 5: handleTextInput called")
    textLabel.setText("")
    while true do
        local _, _, _, character = event.pull("hud_keyboard")
        print("gimpHelper - Line 9: Character received:", tostring(character))
        if character == 13 then  -- Enter key
            print("gimpHelper - Line 11: Enter key detected, breaking loop")
            break
        elseif character == 8 then  -- Backspace key
            textLabel.setText(textLabel.getText():sub(1, -2))
            print("gimpHelper - Line 14: Backspace detected, updated textLabel:", textLabel.getText())
        else
            textLabel.setText(textLabel.getText() .. string.char(character))
            print("gimpHelper - Line 17: Character added to textLabel:", textLabel.getText())
        end
    end
    local trimmedText = tostring(gimpHelper.trim(textLabel.getText()))
    print("gimpHelper - Line 21: Final trimmed text:", trimmedText)
    print("")  -- Blank line for readability
    return trimmedText
end

function gimpHelper.removeCommas(str)
    print("gimpHelper - Line 26: removeCommas called with str =", tostring(str))
    local result = string.gsub(str, ",", "")
    print("gimpHelper - Line 28: Commas removed:", result)
    print("")  -- Blank line for readability
    return result
end

function gimpHelper.extractNumbers(str)
    print("gimpHelper - Line 33: extractNumbers called with str =", tostring(str))
    local numbers = {}
    for num in string.gmatch(str, "%d[,%d]*") do 
        num = string.gsub(num, ",", "")
        print("gimpHelper - Line 37: Number extracted and commas removed:", num)
        table.insert(numbers, tonumber(num))
    end
    print("gimpHelper - Line 40: Extracted numbers:", table.concat(numbers, ", "))
    print("")  -- Blank line for readability
    return numbers
end

function gimpHelper.shorthandNumber(numberToConvert)
    print("gimpHelper - Line 45: shorthandNumber called with numberToConvert =", tostring(numberToConvert))
    local num = numberToConvert
    local units = {"", "k", "M", "B", "T", "Qua", "E", "Z", "Y"}
    local unitIndex = 1
    while num >= 1000 and unitIndex < #units do
        num = num / 1000
        unitIndex = unitIndex + 1
    end
    local convertedNumber = string.format("%.2f%s", num, units[unitIndex])
    print("gimpHelper - Line 54: Converted number:", convertedNumber)
    print("")  -- Blank line for readability
    return convertedNumber
end

function gimpHelper.distanceApartXZ(coordsOne, coordsTwo)
    print("gimpHelper - Line 59: distanceApartXZ called with coordsOne =", tostring(coordsOne), "coordsTwo =", tostring(coordsTwo))
    local distanceX = math.abs((math.ceil(coordsOne.x) + 100000) - (math.ceil(coordsTwo.x) + 100000)) + 1
    local distanceZ = math.abs((math.ceil(coordsOne.z) + 100000) - (math.ceil(coordsTwo.z) + 100000)) + 1

    local distance = math.sqrt((distanceX^2) + (distanceZ^2))
    print("gimpHelper - Line 64: Calculated distance:", tostring(distance))
    print("")  -- Blank line for readability
    return distance
end

function gimpHelper.cleanBatteryStorageString(numberStr)
    print("gimpHelper - Line 69: cleanBatteryStorageString called with numberStr =", tostring(numberStr))
    local cleanStr = numberStr:gsub(",", ""):gsub("EU Stored: ", ""):gsub("EU", "")
    local result = tonumber(cleanStr)
    print("gimpHelper - Line 72: Cleaned battery storage string:", tostring(result))
    print("")  -- Blank line for readability
    return result
end

function gimpHelper.calculatePercentage(currentAmountStr, maxAmount)
    print("gimpHelper - Line 77: calculatePercentage called with currentAmountStr =", tostring(currentAmountStr), "maxAmount =", tostring(maxAmount))
    local currentAmount = gimpHelper.cleanBatteryStorageString(currentAmountStr)
    local maxAmountNum = tonumber(maxAmount)

    if currentAmount >= maxAmountNum then
        currentAmount = math.floor(currentAmount / 1e8)
        maxAmountNum = math.floor(maxAmountNum / 1e8)
        print("gimpHelper - Line 84: Numbers too large, reduced precision. New currentAmount =", tostring(currentAmount), "maxAmountNum =", tostring(maxAmountNum))
    end

    local percentage = (currentAmount / maxAmountNum) * 100
    print("gimpHelper - Line 88: Calculated percentage:", tostring(percentage))
    print("")  -- Blank line for readability
    return percentage
end

function gimpHelper.saveTable(tblToSave, filename)
    print("gimpHelper - Line 94: saveTable called with filename =", tostring(filename))
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
        print("gimpHelper - Error opening file for writing:", tostring(err))
        print("")  -- Blank line for readability
        return false, "Unable to open file for writing"
    end

    file:write("return " .. serialize(tblToSave))
    file:close()
    print("gimpHelper - Line 114: Table saved successfully to", filename)
    print("")  -- Blank line for readability
    return true
end

function gimpHelper.loadTable(filename)
    print("gimpHelper - Line 119: loadTable called with filename =", tostring(filename))
    local file, err = io.open(filename, "r")
    if not file then
        print("gimpHelper - Error opening file for reading:", tostring(err))
        print("")  -- Blank line for readability
        return nil, "Unable to open file for reading"
    end

    local content = file:read("*a")
    file:close()
    local func = load(content)
    if not func or type(func) ~= "function" then
        print("gimpHelper - Line 129: Unable to load file content")
        print("")  -- Blank line for readability
        return nil, "Unable to load file content"
    end
    local tbl = func()
    print("gimpHelper - Line 133: Table loaded successfully from", filename)
    print("")  -- Blank line for readability
    return tbl
end

function gimpHelper.trim(s)
    print("gimpHelper - Line 138: trim called with s =", tostring(s))
    local trimmed = (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")
    print("gimpHelper - Line 140: Trimmed string:", trimmed)
    print("")  -- Blank line for readability
    return trimmed
end

function gimpHelper.capitalizeWords(str)
    print("gimpHelper - Line 145: capitalizeWords called with str =", tostring(str))
    local capitalized = str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    print("gimpHelper - Line 148: Capitalized string:", capitalized)
    print("")  -- Blank line for readability
    return capitalized
end

return gimpHelper