local widgetsAreUs = require("widgetsAreUs")
local PagedWindow = require("PagedWindow")
local component = require("component")
local itemElements = require("itemElements")
local event = require("event")
local gimpHelper = require("gimpHelper")
local s = require("serialization")

local itemWindow = {}
itemWindow.elements = {}
itemWindow.elements.mainStorage = {}
itemWindow.elements.reverseLevelMaintainer = {}
itemWindow.elements.levelMaintainer = {}
itemWindow.elements.monitoredItems = {}

local addTo = nil

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")
end

local function handleKeyboard(character)
    if trim(itemWindow.searchText.getText()) == "Search" then
        itemWindow.searchText.setText("")
    end
    if character == 13 then  -- Enter key                        
        if itemWindow.elements.mainStorage.display then                  
            itemWindow.elements.mainStorage.display:clearDisplayedItems()
        end
        itemWindow.elements.mainStorage.display = nil

        local trimmedStr =  trim(itemWindow.searchText.getText())
        local items = component.me_interface.getItemsInNetwork({label = trimmedStr})
        itemWindow.elements.mainStorage.display = PagedWindow.new(items, 120, 40, {x1=25, y1=83, x2=320, y2=403}, 5, itemElements.itemBox.create)
        itemWindow.elements.mainStorage.display:displayItems()
    elseif character == 8 then  -- Backspace key
        local currentText = itemWindow.searchText.getText()
        itemWindow.searchText.setText(currentText:sub(1, -2))
    else
        local letter = string.char(character)
        local currentText = itemWindow.searchText.getText()
        itemWindow.searchText.setText(currentText .. letter)
    end
end

local function handleKeyboardWrapper(_, _, _, character, _)
    local success, error = pcall(handleKeyboard, character)
end

function itemWindow.init()
    itemWindow.elements.mainStorage.background = widgetsAreUs.createBox(20, 78, 275, 325, {0.5, 0.5, 0.5}, 1.0)
    local items = component.me_interface.getItemsInNetwork()
    itemWindow.elements.mainStorage.display = PagedWindow.new(items, 120, 40, {x1=25, y1=83, x2=320, y2=403}, 5, itemElements.itemBox.create)
    itemWindow.elements.mainStorage.display:displayItems()
    itemWindow.elements.mainStorage.previousButton = widgetsAreUs.createBox(150, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.mainStorage.nextButton = widgetsAreUs.createBox(150, 405, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.elements.reverseLevelMaintainer.background = widgetsAreUs.createBox(330, 78, 160, 160, {1.0, 0.0, 0.0}, 0.8)
    itemWindow.elements.reverseLevelMaintainer.previousButton = widgetsAreUs.createBox(400, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.reverseLevelMaintainer.nextButton = widgetsAreUs.createBox(400, 241, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.elements.levelMaintainer.background = widgetsAreUs.createBox(500, 78, 160, 160, {0.0, 1.0, 0.0}, 0.8)
    itemWindow.elements.levelMaintainer.previousButton = widgetsAreUs.createBox(565, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.levelMaintainer.nextButton = widgetsAreUs.createBox(565, 241, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.elements.monitoredItems.background = widgetsAreUs.createBox(350, 265, 285, 161, {1.0, 1.0, 0.0}, 1.0)
    itemWindow.elements.monitoredItems.previousButton = widgetsAreUs.createBox(320, 340, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.monitoredItems.nextButton = widgetsAreUs.createBox(640, 340, 20, 20, {0, 1, 0.3}, 0.8)
    local monItemsData = gimpHelper.loadTable("/home/programData/monitoredItems")
    if monItemsData and monItemsData[1] then
        itemWindow.elements.monitoredItems.itemList = monItemsData
        itemWindow.elements.monitoredItems.display = PagedWindow.new(monItemsData, 120, 40, {x1=355, y1=270, x2=630, y2=421}, 5, itemElements.itemBox.create)
    end

    itemWindow.searchBox = widgetsAreUs.createBox(25, 55, 120, 20, {1, 1, 1}, 1.0)
    itemWindow.searchText = component.glasses.addTextLabel()
    itemWindow.searchText.setPosition(29, 60)
    itemWindow.searchText.setScale(1)
    itemWindow.searchText.setText("Search")
    event.listen("hud_keyboard", handleKeyboardWrapper)
end

function itemWindow.setVisible(visible)
    itemWindow.elements.mainStorage.background.setVisible(visible)
    itemWindow.elements.reverseLevelMaintainer.background.setVisible(visible)
    itemWindow.elements.levelMaintainer.background.setVisible(visible)
    itemWindow.elements.monitoredItems.background.setVisible(visible)
    itemWindow.searchBox.setVisible(visible)

    for k, v in pairs(itemWindow.elements) do
        v.previousButton.setVisible(visible)
        v.nextButton.setVisible(visible)
    end
    for k, v in pairs(itemWindow.elements.mainStorage.display.currentlyDisplayed) do
        v.setVisible(visible)
    end
end

function itemWindow.remove()
    component.glasses.removeObject(itemWindow.searchBox.getID())
    itemWindow.searchBox = nil
    for i, j in pairs(itemWindow.elements) do
        if itemWindow.elements[i].display then
            for k, v in pairs(itemWindow.elements[i].display.currentlyDisplayed) do
                v.remove()
            end
            itemWindow.elements[i].display = nil
        end
    end
    for k, v in pairs(itemWindow.elements) do
        component.glasses.removeObject(v.background.getID())
        component.glasses.removeObject(v.previousButton.getID())
        component.glasses.removeObject(v.nextButton.getID())
        v.previousButton = nil
        v.nextButton = nil
        v.background = nil
    end
    event.ignore("hud_keyboard", handleKeyboardWrapper)
end

function itemWindow.onClick(x, y, button)
    for k, v in pairs(itemWindow.elements) do
        if widgetsAreUs.isPointInBox(x, y, v.previousButton) then
            v.display:prevPage()
            return
        elseif widgetsAreUs.isPointInBox(x, y, v.nextButton) then
            v.display:nextPage()
            return
        end
    end
    for k, v in pairs(itemWindow.elements.mainStorage.display.currentlyDisplayed) do
        if widgetsAreUs.isPointInBox(x, y, v.background) then
            if not addTo then
                if button == 0 then
                    itemWindow.elements.monitoredItems.display:clearDisplayedItems()
                    itemWindow.elements.monitoredItems.display = nil
                    local tbl = gimpHelper.loadTable("/home/programData/monitoredItems") or {}
                    table.insert(tbl, v.item)
                    gimpHelper.saveTable(tbl, "/home/programData/monitoredItems")
                    itemWindow.elements.monitoredItems.display = PagedWindow.new(monItemsData, 120, 40, {x1=355, y1=270, x2=630, y2=421}, 5, itemElements.itemBox.create)
                    itemWindow.elements.monitoredItems.display:displayItems()
                elseif button == 1 then
                    component.modem.open(300)
                    component.modem.broadcast(300, s.serialize(v.item))
                    component.modem.close(300)
                end
            else

            end
        end
    end
end

function itemWindow.update()
    for k, v in pairs(itemWindow.elements) do
        if v.display then
            for i, j in pairs(v.display.currentlyDisplayed) do
                j.update()
            end
        end
    end
end

return itemWindow