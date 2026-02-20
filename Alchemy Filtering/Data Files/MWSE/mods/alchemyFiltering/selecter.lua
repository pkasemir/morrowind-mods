local log = mwse.Logger.new()
log.level = "DEBUG"
local strings = require("alchemyFiltering.strings")
local config = require("alchemyFiltering.config")

GUI_ID = {}
local selecter = {}

local function registerGUI()
    if GUI_ID.loaded then return end

    -- Standard MenuInventorySelect registered names
    GUI_ID.inventory_scrollpane = tes3ui.registerID("MenuInventorySelect_scrollpane")
    -- GUI_ID.PartHelpMenu_brick = tes3ui.registerID("PartHelpMenu_brick")
    -- GUI_ID.inventory_shadow_brick = tes3ui.registerID("MenuInventorySelect_shadow_brick")
    -- GUI_ID.inventory_icon_brick = tes3ui.registerID("MenuInventorySelect_icon_brick")
    -- GUI_ID.inventory_count_brick = tes3ui.registerID("MenuInventorySelect_count_brick")
    -- GUI_ID.inventory_item_brick = tes3ui.registerID("MenuInventorySelect_item_brick")
    -- GUI_ID.inventory_button_cancel = tes3ui.registerID("MenuInventorySelect_button_cancel")

    -- Property names (found using uiElement.properties which have type tes3uiProperty)
    -- GUI_ID.property_inventory_extra = tes3ui.registerID("MenuInventorySelect_extra") -- type:object
    GUI_ID.property_inventory_count = tes3ui.registerID("MenuInventorySelect_count") -- type:int
    -- GUI_ID.property_inventory_equiped = tes3ui.registerID("MenuInventorySelect_equiped") -- type:bool
    GUI_ID.property_inventory_object = tes3ui.registerID("MenuInventorySelect_object") --type:object

    -- Mod MenuInventorySelect registered names
    GUI_ID.inventory_sort_block = tes3ui.registerID("AF:MenuInventorySelect_sort_block")
    GUI_ID.inventory_sort_name_button = tes3ui.registerID("AF:MenuInventorySelect_sort_name_button")
    GUI_ID.inventory_sort_count_button = tes3ui.registerID("AF:MenuInventorySelect_sort_count_button")
    GUI_ID.inventory_sort_weight_button = tes3ui.registerID("AF:MenuInventorySelect_sort_weight_button")
    GUI_ID.inventory_sort_value_button = tes3ui.registerID("AF:MenuInventorySelect_sort_value_button")

    GUI_ID.loaded = true
end

function selecter:compare(a, b)
    if self.sortAscending then
        return a < b
    else
        return b < a
    end
end

local function compareInventoryIngredients(a, b)
    local aIngredient = a:getPropertyObject(GUI_ID.property_inventory_object) -- tes3ingredient
    local bIngredient = b:getPropertyObject(GUI_ID.property_inventory_object) -- tes3ingredient

    if selecter.sorting == selecter.sortByCount then
        local aCount = a:getPropertyInt(GUI_ID.property_inventory_count)
        local bCount = b:getPropertyInt(GUI_ID.property_inventory_count)
        if aCount ~= bCount then
            return selecter:compare(aCount, bCount)
        end
    elseif selecter.sorting == selecter.sortByWeight then
        if aIngredient.weight ~= bIngredient.weight then
            return selecter:compare(aIngredient.weight, bIngredient.weight)
        end
    elseif selecter.sorting == selecter.sortByValue then
        if aIngredient.value ~= bIngredient.value then
            return selecter:compare(aIngredient.value, bIngredient.value)
        end
    end

    -- Always fallback to sort by name
    return selecter:compare(aIngredient.name, bIngredient.name)
end

function selecter:doSort()
    self.scrollpane:getContentElement():sortChildren(compareInventoryIngredients)
    selecter.menu:updateLayout()
end

function selecter:updateUI()
    -- Set default state for all buttons
    for _, button in pairs(self.sortButtons) do
        button.widget.state = tes3.uiState.normal
        button.text = self.sortInfo[button.id].baseName
    end

    -- Activate the active button
    local activeButton = self.sortButtons[self.sorting]
    if activeButton then
        activeButton.widget.state = tes3.uiState.active
        local upDown = " V"
        if self.sortAscending then
            upDown = " ^"
        end
        activeButton.text = activeButton.text .. upDown
    end

    self:doSort()
end

function selecter:onSortByClick(button)
    if button.id == self.sorting then
        -- Already sorting by this button, so toggle ascending
        self.sortAscending = not self.sortAscending
    else
        self.sortAscending = self.sortInfo[button.id].defaultAscending
    end
    self.sorting = button.id

    selecter:updateUI()
end

local function onSortByClick(e)
    selecter:onSortByClick(e.source)
end

function selecter:createSortButton(id)
    local button = self.sortBlock:createButton{id = id}
    button:register("mouseClick", onSortByClick)
    self.sortButtons[id] = button
    return button
end

function selecter:mergeWithMenuInventorySelect(menu)
    if not menu then return end
    self.menu = menu
    self.menu:register("destroy", function() self:uiDestroyed() end)
    self.scrollpane = self.menu:findChild(GUI_ID.inventory_scrollpane)
    self.sortBlock = self.scrollpane.parent:createBlock{id = GUI_ID.inventory_sort_block}
    self.sortBlock.autoHeight = true
    self.sortBlock.autoWidth = true
    self.sortBlock:reorder{before = self.scrollpane}

    self.sortBlock:createLabel{text = strings.sortBy}
    self.sortButtons = {}
    self.sortNameButton = self:createSortButton(GUI_ID.inventory_sort_name_button)
    self.sortCountButton = self:createSortButton(GUI_ID.inventory_sort_count_button)
    self.sortWeightButton = self:createSortButton(GUI_ID.inventory_sort_weight_button)
    self.sortNameButton = self:createSortButton(GUI_ID.inventory_sort_value_button)

    self:updateUI()
end

function selecter:detachFromMenuInventorySelect()
    if self.sortBlock then self.sortBlock:destroy() end

    if self.menu then
        self.sorting = self.sortByName
        self.sortAscending = true
        self:doSort()
    end

    self:uiDestroyed()
end

function selecter:uiDestroyed()
    self.menu = nil
    self.scrollpane = nil
    self.sortBlock = nil
    self.sortButtons = nil
    self.sortNameButton = nil
    self.sortCountButton = nil
    self.sortWeightButton = nil
    self.sortValueButton = nil
end

local function onMenuInventorySelect(e)
    if not config.modEnabled then return end
    if not e.newlyCreated then return end
    selecter:mergeWithMenuInventorySelect(e.element)
end

function selecter:onModConfigEntryClosed()
    if config.modEnabled then
        if not self.menu then
            self:mergeWithMenuInventorySelect(tes3ui.findMenu("MenuInventorySelect"))
        end
    else
        self:detachFromMenuInventorySelect()
    end
end

function selecter:init()
    if not GUI_ID.loaded then
        event.register("uiActivated", onMenuInventorySelect, {filter = "MenuInventorySelect"})
    end
    registerGUI()
    self.sortByName = GUI_ID.inventory_sort_name_button
    self.sortByCount = GUI_ID.inventory_sort_count_button
    self.sortByWeight = GUI_ID.inventory_sort_weight_button
    self.sortByValue = GUI_ID.inventory_sort_value_button

    self.sortInfo = {
        [self.sortByName] = {
            baseName = strings.sortName,
            defaultAscending = true,
        },
        [self.sortByCount] = {
            baseName = strings.sortCount,
            defaultAscending = false,
        },
        [self.sortByWeight] = {
            baseName = strings.sortWeight,
            defaultAscending = false,
        },
        [self.sortByValue] = {
            baseName = strings.sortValue,
            defaultAscending = true,
        }
    }
    self.sorting = self.sortByName
    self.sortAscending = true
end

return selecter
