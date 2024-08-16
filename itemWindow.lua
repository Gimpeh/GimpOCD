local widgetsAreUs = require("widgetsAreUs")
local PagedWindow = require("PagedWindow")
local component = require("component")
local itemElements = require("itemElements")

local itemWindow = {}
itemWindow.elements = {}
itemWindow.elements.mainStorage = {}
itemWindow.elements.reverseLevelMaintainer = {}
itemWindow.elements.levelMaintainer = {}
itemWindow.elements.monitoredItems = {}

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")
end

local function handleKeyboard(character)
    if character == 13 then  -- Enter key                        
        if itemWindow.elements.mainStorage.display then                  
            itemWindow.elements.mainStorage.display:clearDisplayedItems()
        end
        itemWindow.elements.mainStorage.display = nil

        local trimmedStr =  trim(itemWindow.searchText.getText())
        print(trimmedStr)
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
    event.listen("hud_keyboard", handleKeyboardWrapper)

    itemWindow.elements.reverseLevelMaintainer.background = widgetsAreUs.createBox(330, 78, 160, 160, {1.0, 0.0, 0.0}, 0.8)
    itemWindow.elements.reverseLevelMaintainer.previousButton = widgetsAreUs.createBox(400, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.reverseLevelMaintainer.nextButton = widgetsAreUs.createBox(400, 241, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.elements.levelMaintainer.background = widgetsAreUs.createBox(500, 78, 160, 160, {0.0, 1.0, 0.0}, 0.8)
    itemWindow.elements.levelMaintainer.previousButton = widgetsAreUs.createBox(560, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.levelMaintainer.nextButton = widgetsAreUs.createBox(560, 241, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.elements.monitoredItems.background = widgetsAreUs.createBox(350, 265, 285, 161, {1.0, 1.0, 0.0}, 1.0)
    itemWindow.elements.monitoredItems.previousButton = widgetsAreUs.createBox(320, 340, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.monitoredItems.nextButton = widgetsAreUs.createBox(640, 340, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.searchBox = widgetsAreUs.createBox(25, 55, 120, 20, {0.1, 0.1, 0.1}, 1.0)
    itemWindow.searchText = component.glasses.addTextLabel()
    itemWindow.searchText.setPosition(57, 27)
    itemWindow.searchText.setScale(1)
    itemWindow.searchText.setText("Search")
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
    for k, v in pairs(itemWindow.elements.mainStorage.display.currentlyDisplayed) do
        v.remove()
    end
    itemWindow.elements.mainStorage.display = nil
    for k, v in pairs(itemWindow.elements) do
        component.glasses.removeObject(v.background.getID())
        component.glasses.removeObject(v.previousButton.getID())
        component.glasses.removeObject(v.nextButton.getID())
        v.previousButton = nil
        v.nextButton = nil
        v.background = nil
    end
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
end

return itemWindow