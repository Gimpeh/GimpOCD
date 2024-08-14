--v.1.0.1
local PagedWindow = {}
PagedWindow.__index = PagedWindow

-- Constructor function
function PagedWindow.new(items, itemWidth, itemHeight, screenBounds, padding, renderItem, array)
    local self = setmetatable({}, PagedWindow)
    self.items = items or {}  -- A table containing all items
    self.itemWidth = itemWidth  -- Width of each item
    self.itemHeight = itemHeight  -- Height of each item
    self.padding = padding or 5  -- Default padding of 5 pixels if not provided
    self.renderItem = renderItem or function() end  -- Function to render an individual item
	if array then
		self.args = array
	end

    -- Define screen bounds from the provided table
    self.screenX1 = screenBounds.x1
    self.screenY1 = screenBounds.y1
    self.screenX2 = screenBounds.x2
    self.screenY2 = screenBounds.y2

    -- Calculate available width and height
    local availableWidth = self.screenX2 - self.screenX1
    local availableHeight = self.screenY2 - self.screenY1

    -- Calculate the number of items per row and column, considering padding
    self.itemsPerRow = math.floor((availableWidth + self.padding) / (itemWidth + self.padding))
    self.itemsPerColumn = math.floor((availableHeight + self.padding) / (itemHeight + self.padding))
    self.itemsPerPage = self.itemsPerRow * self.itemsPerColumn  -- Total items per page

    self.currentPage = 1  -- Start on the first page
    self.currentlyDisplayed = {}  -- Keep track of currently displayed items
    return self
end

-- Function to clear currently displayed items
function PagedWindow:clearDisplayedItems()
    for _, element in ipairs(self.currentlyDisplayed) do
        if element.remove then
            element.remove()  -- Call the remove method of each element if it exists
        end
    end
    self.currentlyDisplayed = {}
end

-- Function to display items for the current page
function PagedWindow:displayItems()
    self:clearDisplayedItems()  -- Clear previously displayed items

    local startIndex = (self.currentPage - 1) * self.itemsPerPage + 1
    local endIndex = math.min(self.currentPage * self.itemsPerPage, #self.items)

    for i = startIndex, endIndex do
        -- Calculate row and column based on dynamic values
        local row = math.floor((i - startIndex) / self.itemsPerRow)
        local col = (i - startIndex) % self.itemsPerRow
        local x = self.screenX1 + col * (self.itemWidth + self.padding)
        local y = self.screenY1 + row * (self.itemHeight + self.padding)
        local item = self.items[i]
		
		if self.args and self.args[i] then
		else
			self.args = {}
			self.args[i] = 0 
		end

        if item then
            -- Call renderItem without the index `i`
            local displayedItem = self.renderItem(x, y, item, self.args[i])
            table.insert(self.currentlyDisplayed, displayedItem)
        end
    end
end

-- Function to go to the next page
function PagedWindow:nextPage()
    local totalPages = math.ceil(#self.items / self.itemsPerPage)
    if self.currentPage < totalPages then
        self.currentPage = self.currentPage + 1
        self:displayItems()
    else
        print("Already on the last page")
    end
end

-- Function to go to the previous page
function PagedWindow:prevPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:displayItems()
    else
        print("Already on the first page")
    end
end

-- Function to update items and refresh the display
function PagedWindow:setItems(items)
    self.items = items
    self.currentPage = 1  -- Reset to the first page when items are updated
    self:displayItems()
end

return PagedWindow