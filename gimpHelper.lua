local gimpHelper = {}

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

    print(content)
    local func = load(content)  -- Execute the file's contents as Lua code
    local tbl = func()
    return tbl
end

return gimpHelper