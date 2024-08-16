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



function itemWindow.init()
    itemWindow.elements.mainStorage.background = widgetsAreUs.createBox(20, 78, 275, 325, {0.5, 0.5, 0.5}, 1.0)
    local items = component.me_interface.getItemsInNetwork()
    itemWindow.elements.mainStorage.display = PagedWindow.new(items, 120, 40, {x1=25, y1=83, x2=320, y2=403}, 5, itemElements.itemBox.create)
    itemWindow.elements.mainStorage.display:displayItems()
    --itemWindow.elements.mainStorage.previousButton = widgetsAreUs.createBox()

    itemWindow.elements.reverseLevelMaintainer.background = widgetsAreUs.createBox(330, 78, 160, 160, {1.0, 0.0, 0.0}, 0.8)

    itemWindow.elements.levelMaintainer.background = widgetsAreUs.createBox(500, 78, 160, 160, {0.0, 1.0, 0.0}, 0.8)

    itemWindow.elements.monitoredItems.background = widgetsAreUs.createBox(350, 265, 285, 161, {1.0, 1.0, 0.0}, 1.0)

    itemWindow.elements.searchBox = widgetsAreUs.createBox(25, 55, 120, 20, {0.1, 0.1, 0.1}, 1.0)
end

function itemWindow.setVisible(visible)
    itemWindow.elements.mainStorage.background.setVisible(visible)
    itemWindow.elements.reverseLevelMaintainer.background.setVisible(visible)
    itemWindow.elements.levelMaintainer.background.setVisible(visible)
    itemWindow.elements.monitoredItems.background.setVisible(visible)
    itemWindow.elements.searchBox.setVisible(visible)

    for k, v in pairs(itemWindow.elements.mainStorage.display.displayedItems) do
        v.setVisible(visible)
    end
end

function itemWindow.remove()
    component.glasses.removeObject(itemWindow.elements.mainStorage.background.getID())
    component.glasses.removeObject(itemWindow.elements.reverseLevelMaintainer.background.getID())
    component.glasses.removeObject(itemWindow.elements.levelMaintainer.background.getID())
    component.glasses.removeObject(itemWindow.elements.monitoredItems.background.getID())
    component.glasses.removeObject(itemWindow.elements.searchBox.getID())
    for k, v in pairs(itemWindow.elements.mainStorage.display.displayedItems) do
        v.remove()
    end

    itemWindow.elements.mainStorage.background = nil
    itemWindow.elements.mainStorage.display = nil
    itemWindow.elements.reverseLevelMaintainer.background = nil
    itemWindow.elements.levelMaintainer.background = nil
    itemWindow.elements.monitoredItems.background = nil
    itemWindow.elements.searchBox = nil
end



return itemWindow