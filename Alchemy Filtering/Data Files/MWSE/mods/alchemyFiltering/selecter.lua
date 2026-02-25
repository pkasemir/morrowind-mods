local log = mwse.Logger.new()
log.level = "DEBUG"
local strings = require("alchemyFiltering.strings")
local config = require("alchemyFiltering.config")
local common = require("alchemyFiltering.common")

local IconText = common.IconText
local FullEffect = common.FullEffect

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
    GUI_ID.inventory_filter_block = tes3ui.registerID("AF:MenuInventorySelect_filter_block")
    GUI_ID.inventory_filter_none_button = tes3ui.registerID("AF:MenuInventorySelect_filter_none_button")
    GUI_ID.inventory_filter_matching_button = tes3ui.registerID("AF:MenuInventorySelect_filter_matching_button")
    GUI_ID.inventory_filter_chosen_effect_button = tes3ui.registerID("AF:MenuInventorySelect_chosen_effect_button")

    GUI_ID.loaded = true
end

function selecter:compare(ascending, a, b)
    if ascending then
        return a < b
    else
        return b < a
    end
end

function selecter.getSortValueForName(ingredient, child)
    return ingredient.name
end

function selecter.getSortValueForCount(ingredient, child)
    return child:getPropertyInt(GUI_ID.property_inventory_count)
end

function selecter.getSortValueForWeight(ingredient, child)
    return ingredient.weight
end

function selecter.getSortValueForValue(ingredient, child)
    return ingredient.value
end

local function compareInventoryIngredients(a, b)
    local aIngredient = a:getPropertyObject(GUI_ID.property_inventory_object) -- tes3ingredient
    local bIngredient = b:getPropertyObject(GUI_ID.property_inventory_object) -- tes3ingredient

    for _, sortBy in ipairs(selecter.sorting) do
        local sortInfo = selecter.sortInfo[sortBy]
        local aValue = sortInfo.getSortValue(aIngredient, a)
        local bValue = sortInfo.getSortValue(bIngredient, b)
        if aValue ~= bValue then
            return selecter:compare(sortInfo.ascending, aValue, bValue)
        end
    end

    -- Always fallback to sort by name
    return selecter:compare(true, aIngredient.name, bIngredient.name)
end

function selecter:doSort()
    self.scrollpane:getContentElement():sortChildren(compareInventoryIngredients)
    self.menu:updateLayout()
end

function selecter:updateSortUI()
    -- Set default state for all buttons
    for _, button in pairs(self.sortButtons) do
        button.widget.state = tes3.uiState.normal
        button.text = self.sortInfo[button.id].baseName
    end

    -- Activate the active button
    local activeButton = self.sortButtons[self.sorting[1]]
    if activeButton then
        activeButton.widget.state = tes3.uiState.active
        local upDown = " V"
        if self.sortInfo[self.sorting[1]].ascending then
            upDown = " ^"
        end
        activeButton.text = activeButton.text .. upDown
    end

    self:doSort()
end

function selecter:onSortByClick(button)
    local sortInfo = self.sortInfo[button.id]
    if button.id == self.sorting[1] then
        -- Already sorting by this button, so toggle ascending
        sortInfo.ascending = not sortInfo.ascending
    end
    local newSorting = {button.id}
    for _, sortBy in ipairs(self.sorting) do
        if sortBy ~= button.id then
            table.insert(newSorting, sortBy)
        end
    end
    self.sorting = newSorting

    self:updateSortUI()
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

function selecter:isItemVisible(item, filterEffects)
    if filterEffects then
        for _, filterEffect in pairs(filterEffects) do
            for _, itemEffect in FullEffect:visibleEffects(item) do
                log:trace("  " .. itemEffect.name .. " " .. filterEffect.id .. " " .. itemEffect.id)
                if filterEffect.id == itemEffect.id then
                    return true
                end
            end
        end
        return false
    end
    return true
end

function selecter:doFiltering()
    local filterEffects = nil
    if self.filtering == self.filterByMatching then
        filterEffects = self.chooser.selectedEffects
    elseif self.filtering == self.filterByChosen then
        if self.chooser.chosenEffect then
            filterEffects = {self.chooser.chosenEffect}
        end
    end

    for _, child in pairs(self.scrollpane:getContentElement().children) do
        local ingredient = child:getPropertyObject(GUI_ID.property_inventory_object) -- tes3ingredient
        child.visible = self:isItemVisible(ingredient, filterEffects)
    end
    self.menu:updateLayout()
end

function selecter:updateFilterUI()
    if self.filterButtons then
        -- Set default state for all buttons
        for _, button in pairs(self.filterButtons) do
            button.widget.state = tes3.uiState.normal
        end

        -- Activate the active button
        local activeButton = self.filterButtons[self.filtering]
        if activeButton then
            activeButton.widget.state = tes3.uiState.active
        end
    end

    self:doFiltering()
end

function selecter:onFilterByClick(button)
    self.filtering = button.id
    self:updateFilterUI()
end

local function onFilterByClick(e)
    selecter:onFilterByClick(e.source)
end

--- Create a filterBy button and add it to the filterButtons variable
---
--- Args:
--- * id - (required) the id of the button
--- * text - (optional) the text in the button
---     * does nothing if effect parameter is given
--- * effect - (optional) a FullEffect object which creates an IconText style button
function selecter:createFilterButton(args)
    local button
    if args.effect then
        button = IconText:create{parent = self.filterBlock, id = args.id, isButton = true,
            text = args.effect.name, path = args.effect.magicEffect.icon}
    else
        button = self.filterBlock:createButton{id = args.id, text = args.text}
    end
    button:register("mouseClick", onFilterByClick)
    self.filterButtons[args.id] = button
    return button
end

function selecter:mergeWithMenuInventorySelect(menu)
    if not menu then return end
    self.menu = menu
    -- Menu seems to be set to specific width which may be too small for some
    -- effects. We keep the original size as minimum, but re-enable autoWidth
    self.menu.minWidth = self.menu.width
    self.menu.autoWidth = true
    self.menu:register("destroy", function() self:uiDestroyed() end)
    self.scrollpane = self.menu:findChild(GUI_ID.inventory_scrollpane)
    self.sortBlock = self.scrollpane.parent:createBlock{id = GUI_ID.inventory_sort_block}
    self.sortBlock.autoHeight = true
    self.sortBlock.autoWidth = true
    self.sortBlock.childAlignY = 0.5
    self.sortBlock:reorder{before = self.scrollpane}

    self.sortBlock:createLabel{text = strings.sortBy}
    self.sortButtons = {}
    self:createSortButton(GUI_ID.inventory_sort_name_button)
    self:createSortButton(GUI_ID.inventory_sort_count_button)
    self:createSortButton(GUI_ID.inventory_sort_weight_button)
    self:createSortButton(GUI_ID.inventory_sort_value_button)

    self.filtering = self.filterByNone
    if self.chooser.selectedEffects or self.chooser.chosenEffect then
        self.filterBlock = self.scrollpane.parent:createBlock{id = GUI_ID.inventory_filter_block}
        self.filterBlock.autoHeight = true
        self.filterBlock.autoWidth = true
        self.filterBlock.childAlignY = 0.5
        self.filterBlock:reorder{before = self.scrollpane}
        self.filterBlock:createLabel{text = strings.filterBy}
        self.filterButtons = {}
        self:createFilterButton{id = GUI_ID.inventory_filter_none_button, text = strings.filterNone}

        if self.chooser.selectedEffects then
            self:createFilterButton{id = GUI_ID.inventory_filter_matching_button, text = strings.filterMatching}
            self.filtering = self.filterByMatching
        end

        if self.chooser.chosenEffect then
            self:createFilterButton{id = GUI_ID.inventory_filter_chosen_effect_button,
                effect = self.chooser.chosenEffect}
            self.filtering = self.filterByChosen
        end
        self:updateFilterUI()
    end

    self:updateSortUI()
end

function selecter:detachFromMenuInventorySelect()
    common:destroyAll{
        self.sortBlock,
        self.filterBlock,
    }

    selecter:reset()
    if self.menu then
        self:doSort()
        self:doFiltering()
    end

    self:uiDestroyed()
end

function selecter:uiDestroyed()
    self.menu = nil
    self.scrollpane = nil
    self.sortBlock = nil
    self.sortButtons = nil
    self.filterBlock = nil
    self.filterButtons = nil
end

function selecter:menuAlchemyDestroyed()
    if not config.sortSticky then
        self:reset()
    end
end

local function onMenuInventorySelect(e)
    if not config.modEnabled then return end
    if not e.newlyCreated then return end
    selecter:mergeWithMenuInventorySelect(e.element)
end

function selecter:onModConfigEntryClosed()
    if config.modEnabled then
        if not self.menu then
            self.chooser:getSelectedEffects()
            self:mergeWithMenuInventorySelect(tes3ui.findMenu("MenuInventorySelect"))
        end
    else
        self:detachFromMenuInventorySelect()
    end
end

function selecter:reset()
    self.sorting = {self.sortByName}
    self.filtering = self.filterByNone

    for _, info in pairs(self.sortInfo) do
        info.ascending = info.defaultAscending
    end
end

function selecter:init(chooser)
    if not GUI_ID.loaded then
        event.register("uiActivated", onMenuInventorySelect, {filter = "MenuInventorySelect"})
    end
    registerGUI()

    self.chooser = chooser

    self.sortByName = GUI_ID.inventory_sort_name_button
    self.sortByCount = GUI_ID.inventory_sort_count_button
    self.sortByWeight = GUI_ID.inventory_sort_weight_button
    self.sortByValue = GUI_ID.inventory_sort_value_button

    self.filterByNone = GUI_ID.inventory_filter_none_button
    self.filterByMatching = GUI_ID.inventory_filter_matching_button
    self.filterByChosen = GUI_ID.inventory_filter_chosen_effect_button

    self.sortInfo = {
        [self.sortByName] = {
            baseName = strings.sortName,
            getSortValue = self.getSortValueForName,
            defaultAscending = true,
        },
        [self.sortByCount] = {
            baseName = strings.sortCount,
            getSortValue = self.getSortValueForCount,
            defaultAscending = false,
        },
        [self.sortByWeight] = {
            baseName = strings.sortWeight,
            getSortValue = self.getSortValueForWeight,
            defaultAscending = false,
        },
        [self.sortByValue] = {
            baseName = strings.sortValue,
            getSortValue = self.getSortValueForValue,
            defaultAscending = true,
        }
    }

    self:reset()
end

return selecter
