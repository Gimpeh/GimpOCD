local widgetsAreUs = require("widgetsAreUs")
local component = require("component")
local gimpHelper = require("gimpHelper")

local itemElements = {}

local itemBox = {}
function itemBox.create(x, y, itemStack)
    local background = widgetsAreUs.createBox(x, y, 120, 40, {1, 0.8, 0.5}, 0.8)

    local name = component.glasses.addTextLabel()
    name.setPosition(x+2, y+2)
    name.setScale(0.9)
    name.setText(itemStack.label)

    local icon = component.glasses.addItem()
    icon.setPosition(x, y+6)
    if component.database then
        component.database.clear(1)
        component.database.set(1, itemStack.name, itemStack.damage, itemStack.tag)
        icon.setItem(component.database.address, 1)
    end

    local amount = component.glasses.addTextLabel()
    amount.setPosition(x+30, y+18)
    amount.setScale(1)
    amount.setText(tostring(itemStack.size))

    return {
        background = background,
        item = itemStack,
        update = function()
            local updatedItemStack = component.me_interface.getItemsInNetwork(itemStack)[1]
            amount.setText(tostring(updatedItemStack.size))
        end,
        remove = function()
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(name.getID())
            component.glasses.removeObject(amount.getID())
            component.glasses.removeObject(icon.getID())

            background = nil
            name = nil
            icon = nil
            amount = nil
        end,
        setVisible = function(visible)
            background.setVisible(visible)
            name.setVisible(visible)
            icon.setVisible(visible)
            amount.setVisible(visible)
        end
    }
end

function itemBox.itemOptions(x, y, itemStack, index)
    local background = widgetsAreUs.createBox(x, y, 120, 40, {1, 0.8, 0.5}, 0.8)

    local name = component.glasses.addTextLabel()
    name.setPosition(x+2, y+2)
    name.setScale(0.9)
    name.setText(itemStack.label)

    local icon = component.glasses.addItem()
    icon.setPosition(x, y+6)
    if component.database then
        component.database.clear(1)
        component.database.set(1, itemStack.name, itemStack.damage, itemStack.tag)
        icon.setItem(component.database.address, 1)
    end

    return {
        background = background,
        item = itemStack,
        remove = function()
            component.glasses.removeObject(background.getID())
            component.glasses.removeObject(name.getID())
            component.glasses.removeObject(icon.getID())

            background = nil
            name = nil
            icon = nil
        end,
        setVisible = function(visible)
            background.setVisible(visible)
            name.setVisible(visible)
            icon.setVisible(visible)
        end,
        onClick = function(createConfigFunc)
            local config = gimpHelper.loadTable("/home/programData/itemConfig.data")
            if not config then
                config = {}
            end
            if not config[index] then
                config[index] = createConfigFunc()
                gimpHelper.saveTable(config, "/home/programData/itemConfig.data")
            end
            return config[index]
        end
    }
end

itemElements.itemBox = itemBox

return itemElements