local event = require("event")

local gimpHelper = {}

--import function
--[[
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
end]]

function gimpHelper.handleTextInput(textLabel)
    while true do
        if textLabel.getText() == "0" then textLabel.setText("") end
        local _, _, _, character = event.pull("hud_keyboard")
        if character == 13 then  -- Enter key
            if textLabel.getText() == "" then textLabel.setText("0") end
            break
        elseif character == 8 then  -- Backspace key
            textLabel.setText(textLabel.getText():sub(1, -2))
        else
            textLabel.setText(textLabel.getText() .. string.char(character))
        end
    end
    return tonumber(textLabel.getText())
end


function gimpHelper.removeCommas(str)
  return string.gsub(str, ",", "")
end

function gimpHelper.extractNumbers(str)
  local numbers = {}
  for num in string.gmatch(str, "%d[,%d]*") do 
    num = string.gsub(num, ",", "")
    table.insert(numbers, tonumber(num))
  end
  return numbers
end

function gimpHelper.shorthandNumber(numberToConver)
    local num = numberToConver
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

function gimpHelper.cleanNumberString(numberStr)
    local cleanStr = numberStr:gsub(",", ""):gsub("EU Stored: ", ""):gsub("EU", "")
    return tonumber(cleanStr)
end

function gimpHelper.calculatePercentage(currentAmountStr, maxAmount)
    local currentAmount = gimpHelper.cleanNumberString(currentAmountStr)
    local maxAmountNum = tonumber(maxAmount)

    -- Check if numbers are too large
    if currentAmount >= maxAmountNum then
        -- Drop the least significant 8 digits (safely reduce precision)
        currentAmount = math.floor(currentAmount / 1e8)
        maxAmountNum = math.floor(maxAmountNum / 1e8)
    end

    local percentage = (currentAmount / maxAmountNum) * 100
    return percentage
end


--the table can be loaded via simple require, assuming the file's directory is in a valid library location
function gimpHelper.saveTable(tblToSave, filename)
    local function serialize(tbl)
        local result = "{"
        local first = true
        for k, v in pairs(tbl) do
            if not first then result = result .. ","
            else first = false end

            local key = type(k) == "string" and k or "["..k.."]"
            local value
            if type(v) == "table" then
                value = serialize(v)  -- Recursively serialize tables
            elseif type(v) == "string" then
                value = string.format("%q", v)  -- Format strings with quotes
            else
                value = tostring(v)  -- Convert numbers, booleans to strings
            end
            result = result .. key .. "=" .. value
        end
        return result .. "}"
    end

    local file = io.open(filename, "w")
    if not file then
        return false, "Unable to open file for writing"
    end

    -- Write the serialized table with 'return' so it can be loaded back
    file:write("return " .. serialize(tblToSave))
    file:close()
    return true
end

function gimpHelper.loadTable(filename)
    local file = io.open(filename, "r")
    if not file then
        return nil, "Unable to open file for reading"
    end

    local content = file:read("*a")  -- Read the whole file content
    file:close()
    local func = load(content)  -- Execute the file's contents as Lua code
    if not func or type(func) ~= "function" then
        return nil, "Unable to load file content"
    end
    local tbl = func()
    return tbl
end

--remove whitespace and control characters from the beginning and end of a string
function gimpHelper.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")
end

return gimpHelper