local widgetsAreUs = require("widgetsAreUs")
local PagedWindow = require("PagedWindow")
local component = require("component")
local event = require("event")
local gimpHelper = require("gimpHelper")
local s = require("serialization")

-----------------------------------------
---itemWindow layout

--itemWindow table layout
local itemWindow = {}
itemWindow.elements = {}

--each of these tables contain a display object, a background object, and a previous and next button
itemWindow.elements.mainStorage = {}
itemWindow.elements.reverseLevelMaintainer = {}
itemWindow.elements.levelMaintainer = {}
itemWindow.elements.monitoredItems = {}

itemWindow.searchBox = nil
itemWindow.searchText = nil

-----------------------------------------
---Other Forward Declarations

--lazy variables
local lm
local rlm

--other
local addTo = nil

-----------------------------------------
---Helper Functions

--helper function to lazily rename the batch subtitle to "Speed" for reverseLevelMaintainer
    local function renameBatch()
        for k, v in ipairs(rlm.display.currentlyDisplayed) do
            v.batchText.text.setText("Speed")
        end
    end

-----------------------------------------
---Event Handlers

    --keyboard event handler
local function handleKeyboard(character)
    if trim(itemWindow.searchText.getText()) == "Search" then
        itemWindow.searchText.setText("")
    end
    if character == 13 then  -- Enter key                        
        if itemWindow.elements.mainStorage.display then                  
            itemWindow.elements.mainStorage.display:clearDisplayedItems()
        end
        itemWindow.elements.mainStorage.display = nil
        local items
        local trimmedStr =  trim(itemWindow.searchText.getText())
        if trimmedStr == "" then 
            items = component.me_interface.getItemsInNetwork()
        else
            items = component.me_interface.getItemsInNetwork({label = trimmedStr})
        end
        itemWindow.elements.mainStorage.display = PagedWindow.new(items, 120, 40, {x1=25, y1=83, x2=320, y2=403}, 5, widgetsAreUs.itemBox)
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

--pcall wrapper for keyboard event handler
local function handleKeyboardWrapper(_, _, _, character, _)
    print("keyboard event : " .. character)
    local success, error = pcall(handleKeyboard, character)
end

-----------------------------------------
---Inits

function itemWindow.init()
    itemWindow.elements.mainStorage.background = widgetsAreUs.createBox(20, 78, 275, 325, {0.5, 0.5, 0.5}, 0.7)
    local items = component.me_interface.getItemsInNetwork()
    itemWindow.elements.mainStorage.display = PagedWindow.new(items, 120, 40, {x1=25, y1=83, x2=320, y2=403}, 5, widgetsAreUs.itemBox)
    itemWindow.elements.mainStorage.display:displayItems()
    itemWindow.elements.mainStorage.previousButton = widgetsAreUs.createBox(150, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.mainStorage.nextButton = widgetsAreUs.createBox(150, 405, 20, 20, {0, 1, 0.3}, 0.8)

    itemWindow.elements.reverseLevelMaintainer.background = widgetsAreUs.createBox(330, 78, 160, 160, {1.0, 0.0, 0.0}, 0.7)
    itemWindow.elements.reverseLevelMaintainer.previousButton = widgetsAreUs.createBox(400, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.reverseLevelMaintainer.nextButton = widgetsAreUs.createBox(400, 241, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.reverseLevelMaintainer.addButton = widgetsAreUs.createBox(460, 55, 20, 20, {1, 1, 0.6}, 0.8)
    rlm = itemWindow.elements.reverseLevelMaintainer
    local rvlvlmaint = gimpHelper.loadTable("/home/programData/reverseLevelMaintainer.data")
    if rvlvlmaint and rvlvlmaint[1] then
        rlm.display = PagedWindow.new(rvlvlmaint, 150, 30, {x1=335, y1=83, x2=490, y2=238}, 5, widgetsAreUs.levelMaintainer)
        rlm.display:displayItems()
        renameBatch()
    end

    itemWindow.elements.levelMaintainer.background = widgetsAreUs.createBox(500, 78, 160, 160, {0.0, 1.0, 0.0}, 0.7)
    itemWindow.elements.levelMaintainer.previousButton = widgetsAreUs.createBox(565, 55, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.levelMaintainer.nextButton = widgetsAreUs.createBox(565, 241, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.levelMaintainer.addButton = widgetsAreUs.createBox(635, 55, 20, 20, {1, 1, 0.6}, 0.8)
    lm = itemWindow.elements.levelMaintainer
    local lvlmaint = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    if lvlmaint and lvlmaint[1] then
        lm.display = PagedWindow.new(lvlmaint, 150, 30, {x1=505, y1= 83, x2= 660, y2=238}, 5, widgetsAreUs.levelMaintainer)
        lm.display:displayItems()
    end

    itemWindow.elements.monitoredItems.background = widgetsAreUs.createBox(350, 265, 285, 161, {1.0, 1.0, 0.0}, 0.7)
    itemWindow.elements.monitoredItems.previousButton = widgetsAreUs.createBox(320, 340, 20, 20, {0, 1, 0.3}, 0.8)
    itemWindow.elements.monitoredItems.nextButton = widgetsAreUs.createBox(640, 340, 20, 20, {0, 1, 0.3}, 0.8)
    local monItemsData = gimpHelper.loadTable("/home/programData/monitoredItems")
    if monItemsData and monItemsData[1] then
        itemWindow.elements.monitoredItems.display = PagedWindow.new(monItemsData, 120, 40, {x1=355, y1=270, x2=630, y2=421}, 5, widgetsAreUs.itemBox)
        itemWindow.elements.monitoredItems.display:displayItems()
    end

    itemWindow.searchBox = widgetsAreUs.createBox(25, 55, 120, 20, {1, 1, 1}, 1.0)
    itemWindow.searchText = component.glasses.addTextLabel()
    itemWindow.searchText.setPosition(29, 60)
    itemWindow.searchText.setScale(1)
    itemWindow.searchText.setText("Search")
    event.listen("hud_keyboard", handleKeyboardWrapper)
end

-----------------------------------------
---UI Functions

function itemWindow.setVisible(visible)
    itemWindow.searchBox.setVisible(visible)
    itemWindow.searchText.setVisible(visible)
    lm.addButton.setVisible(visible)
    rlm.addButton.setVisible(visible)

    for k, v in pairs(itemWindow.elements) do
        v.previousButton.setVisible(visible)
        v.nextButton.setVisible(visible)
        v.background.setVisible(visible)
        if v.display then
            for i, j in ipairs(v.display.currentlyDisplayed) do
                j.setVisible(visible)
            end
        end
    end
end

function itemWindow.remove()
    component.glasses.removeObject(itemWindow.searchBox.getID())
    component.glasses.removeObject(itemWindow.searchText.getID())
    itemWindow.searchBox = nil

    component.glasses.removeObject(lm.addButton.getID())
    component.glasses.removeObject(rlm.addButton.getID())
    rlm.addButton = nil
    lm.addButton = nil

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
        itemWindow.elements[k].previousButton = nil
        itemWindow.elements[k].nextButton = nil
        itemWindow.elements[k].background = nil
    end
    event.ignore("hud_keyboard", handleKeyboardWrapper)
end

--rework the fuck out of this... this is just terrible... almost 200 lines for onClick....
-- and its not even remotely optimized...
function itemWindow.onClick(x, y, button)
    for k, v in pairs(itemWindow.elements) do
        os.sleep(0)
        if widgetsAreUs.isPointInBox(x, y, v.previousButton) then
            v.display:prevPage()
            return
        elseif widgetsAreUs.isPointInBox(x, y, v.nextButton) then
            v.display:nextPage()
            return
        end
    end

    if itemWindow.elements.mainStorage.background.contains(x, y) then
        for k, v in pairs(itemWindow.elements.mainStorage.display.currentlyDisplayed) do
            os.sleep(0)
            if widgetsAreUs.isPointInBox(x, y, v.box) then
                if not addTo then
                    if button == 0 then
                        if itemWindow.elements.monitoredItems.display then
                            itemWindow.elements.monitoredItems.display:clearDisplayedItems()
                            itemWindow.elements.monitoredItems.display = nil
                        end
                        local tbl = gimpHelper.loadTable("/home/programData/monitoredItems")
                        if tbl and not tbl[1] or not tbl then
                            tbl = {}
                        end
                        table.insert(tbl, v.itemStack)
                        gimpHelper.saveTable(tbl, "/home/programData/monitoredItems")
                        event.push("add_index", "/home/programData/itemConfig.data")
                        itemWindow.elements.monitoredItems.display = PagedWindow.new(tbl, 120, 40, {x1=355, y1=270, x2=630, y2=421}, 5, widgetsAreUs.itemBox)
                        itemWindow.elements.monitoredItems.display:displayItems()
                        return
                    elseif button == 1 then
                        component.modem.open(300)
                        component.modem.broadcast(300, s.serialize(v.item))
                        component.modem.close(300)
                       return
                    end
                elseif addTo == "reverseLevelMaintainer" then
                    if rlm.display then
                        rlm.display:clearDisplayedItems()
                        rlm.display = nil
                    end
                    local rvlvlmaint = gimpHelper.loadTable("/home/programData/reverseLevelMaintainer.data")
                    if not rvlvlmaint or not rvlvlmaint[1] then
                        rvlvlmaint = {}
                    end
                    table.insert(rvlvlmaint, {itemStack = v.itemStack, batch = 0, amount = 0})
                    gimpHelper.saveTable(rvlvlmaint, "/home/programData/reverseLevelMaintainer.data")
                    rlm.display = PagedWindow.new(rvlvlmaint, 150, 30, {x1=335, y1=83, x2=490, y2=238}, 5, widgetsAreUs.levelMaintainer)
                    rlm.display:displayItems()
                    renameBatch()
                elseif addTo == "levelMaintainer" then
                    if lm.display then
                        lm.display:clearDisplayedItems()
                        lm.display = nil
                    end
                    local lvlmaint = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
                    if not lvlmaint or not lvlmaint[1] then
                        lvlmaint = {}
                    end
                    table.insert(lvlmaint, {itemStack = v.itemStack, batch = 0, amount = 0})
                    gimpHelper.saveTable(lvlmaint, "/home/programData/levelMaintainer.data")
                    lm.display = PagedWindow.new(lvlmaint, 150, 30, {x1=505, y1=83, x2=665, y2=238}, 5, widgetsAreUs.levelMaintainer)
                    lm.display:displayItems()
                    event.push("add_index", "/home/programData/levelMaintainerConfig.data")
                end
            end
        end
    end

    if itemWindow.elements.monitoredItems.background.contains(x, y) then
        for k, v in ipairs(itemWindow.elements.monitoredItems.display.currentlyDisplayed) do
            os.sleep(0)
            if widgetsAreUs.isPointInBox(x, y, v.box) then
                if not addTo then
                    if itemWindow.elements.monitoredItems.display then
                        itemWindow.elements.monitoredItems.display:clearDisplayedItems()
                        itemWindow.elements.monitoredItems.display = nil
                    end
                    local tbl = gimpHelper.loadTable("/home/programData/monitoredItems")
                    table.remove(tbl, k)
                    gimpHelper.saveTable(tbl, "/home/programData/monitoredItems")
                    itemWindow.elements.monitoredItems.display = PagedWindow.new(tbl, 120, 40, {x1=355, y1=270, x2=630, y2=421}, 5, widgetsAreUs.itemBox)
                    itemWindow.elements.monitoredItems.display:displayItems()  
                    event.push("remove_index", "/home/programData/itemConfig.data", k)
                    return 
                end 
            end
        end
    end

    if widgetsAreUs.isPointInBox(x, y, itemWindow.elements.levelMaintainer.addButton) then
        if not addTo or addTo ~= "levelMaintainer" then
            addTo = "levelMaintainer"
            print(addTo)
            return
        elseif addTo == "levelMaintainer" then
            addTo = nil
            print(addTo)
            return
        end
    elseif widgetsAreUs.isPointInBox(x, y, itemWindow.elements.reverseLevelMaintainer.addButton) then
        if not addTo or addTo ~= "reverseLevelMaintainer" then
            addTo = "reverseLevelMaintainer"
            print(addTo)
            return
        elseif addTo == "reverseLevelMaintainer" then
            addTo = nil
            print(addTo)
            return
        end
    end

    if lm.background.contains(x, y) then
        for k, v in ipairs(lm.display.currentlyDisplayed) do
            os.sleep(0)
            if widgetsAreUs.isPointInBox(x, y, v.box) then
                if button == 0 then
                    if widgetsAreUs.isPointInBox(x, y, v.amountText.box) then
                        event.ignore("hud_keyboard", handleKeyboardWrapper)
                        local args = v.amount.onClick()
                        local tbl = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
                        tbl[args.location].amount=args.amount
                        gimpHelper.saveTable(tbl, "/home/programData/levelMaintainer.data")
                        event.listen("hud_keyboard", handleKeyboardWrapper)
                        return
                   elseif widgetsAreUs.isPointInBox(x, y, v.batchText.box) then
                        event.ignore("hud_keyboard", handleKeyboardWrapper)
                        local args = v.batch.onClick()
                        local tbl = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
                        tbl[args.location].batch=args.batch
                        gimpHelper.saveTable(tbl, "/home/programData/levelMaintainer.data")
                        event.listen("hud_keyboard", handleKeyboardWrapper)
                        return
                   end
                elseif button == 1 then

                elseif button == 2 then
                    local tbl = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
                    table.remove(tbl, k)
                    event.push("remove_index", "/home/programData/levelMaintainerConfig.data", k)
                    lm.display:clearDisplayedItems()
                    lm.display = nil
                    gimpHelper.saveTable(tbl, "/home/programData/levelMaintainer.data")
                    if tbl[1] then
                        lm.display = PagedWindow.new(tbl, 150, 30, {x1=330, y1=71, x2=490, y2=238}, 5, widgetsAreUs.levelMaintainer)
                        lm.display:displayItems()
                    end
                end
            end
        end
    end

    if rlm.background.contains(x, y) then
        for k, v in ipairs(rlm.display.currentlyDisplayed) do
            os.sleep(0)
            if widgetsAreUs.isPointInBox(x, y, v.box) then
                if button == 0 then
                    if widgetsAreUs.isPointInBox(x, y, v.amountText.box) then
                        event.ignore("hud_keyboard", handleKeyboardWrapper)
                        local args = v.amount.onClick()
                        local tbl = gimpHelper.loadTable("/home/programData/reverseLevelMaintainer.data")
                        tbl[args.location].amount=args.amount
                        gimpHelper.saveTable(tbl, "/home/programData/reverseLevelMaintainer.data")
                        event.listen("hud_keyboard", handleKeyboardWrapper)
                        return
                    elseif widgetsAreUs.isPointInBox(x, y, v.batchText.box) then
                        event.ignore("hud_keyboard", handleKeyboardWrapper)
                        local args = v.batch.onClick()
                        local tbl = gimpHelper.loadTable("/home/programData/reverseLevelMaintainer.data")
                        tbl[args.location].batch=args.batch
                        gimpHelper.saveTable(tbl, "/home/programData/reverseLevelMaintainer.data")
                        event.listen("hud_keyboard", handleKeyboardWrapper)
                        return
                    end
                elseif button == 1 then

                elseif button == 2 then
                    local tbl = gimpHelper.loadTable("/home/programData/reverseLevelMaintainer.data")
                    table.remove(tbl, k)
                    rlm.display:clearDisplayedItems()
                    rlm.display = nil
                    gimpHelper.saveTable(tbl, "/home/programData/reverseLevelMaintainer.data")
                    if tbl[1] then
                        rlm.display = PagedWindow.new(tbl, 150, 30, {x1=335, y1=83, x2=490, y2=238}, 5, widgetsAreUs.levelMaintainer)
                        rlm.display:displayItems()
                    end
                end
            end
        end
    end
end

function itemWindow.update()
    for k, v in pairs(itemWindow.elements) do
        if v.display then
            for i, j in pairs(v.display.currentlyDisplayed) do
                os.sleep(0)
                j.update()
            end
        end
    end
end

return itemWindow