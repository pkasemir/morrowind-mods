local log = mwse.Logger.new()
log.level = "DEBUG"

local common = {}

function common:getVisibleEffectsCount()
    local skill = tes3.mobilePlayer.alchemy.current
    local gmst = tes3.findGMST(tes3.gmst.fWortChanceValue)
    return math.clamp(math.floor(skill / gmst.value), 0, 4)
end

--- Split the string in two at the first instance of the delimiter
local function splitString(str, delimiter)
    local startIndex, endIndex = string.find(str, delimiter, 1, true)

    if startIndex then
        -- Extract the part before the delimiter (from 1 to start_index - 1)
        local part1 = string.sub(str, 1, startIndex - 1)
        -- Extract the part after the delimiter (from end_index + 1 to the end)
        local part2 = string.sub(str, endIndex + 1)
        return part1, part2
    else
        -- Delimiter not found
        return str, nil
    end
end

--- Get a set of effects which also have additional IDs,
--- such as Attributes or Skills
local function getCompoundEffects(effectType)
	local effects = {}
	for name, effect in pairs(tes3.effect) do
		if string.match(name, effectType) then
			effects[effect] = true
		end
	end
	return effects
end

local attributeEffects = getCompoundEffects("Attribute")
local skillEffects = getCompoundEffects("Skill")

local FullEffect = {}
FullEffect.__index = FullEffect
common.FullEffect = FullEffect

function FullEffect:new(effectId, attributeId, skillId)
	local effect = {}
	setmetatable(effect, self)
	effect.effectId = effectId
	effect.attributeId = attributeId
	effect.skillId = skillId
	effect.id = effectId

	effect.magicEffect = tes3.getMagicEffect(effectId)

	effect.name1, effect.name2 = splitString(effect.magicEffect.name, " ")
	if effect.name2 then
		if attributeEffects[effectId] then
			effect.name2 = tes3.attributeName[attributeId]
			effect.id = effect.id + attributeId * 1000000
		elseif skillEffects[effectId] then
			effect.name2 = tes3.skillName[skillId]
			effect.id = effect.id + skillId * 1000000
		end
		effect.name2 = effect.name2:gsub("^%l", string.upper)
		effect.name = effect.name1 .. " " .. effect.name2
	else
		effect.name = effect.magicEffect.name
	end
	return effect
end

function FullEffect:fromIngredient(ingredient, i)
	return FullEffect:new(ingredient.effects[i], ingredient.effectAttributeIds[i], ingredient.effectSkillIds[i])
end

function FullEffect.ingredientIter(ingredient, state)
	state.i = state.i + 1
	if state.i > state.visibleCount then
		return nil
	end
	if ingredient.effects[state.i] < 0 then
		return nil
	end

	return state, FullEffect:fromIngredient(ingredient, state.i)
end

function FullEffect:visibleEffects(ingredient)
	if ingredient then
		return FullEffect.ingredientIter, ingredient, {i = 0, visibleCount = common:getVisibleEffectsCount()}
	else
		return function() return nil end
	end
end

IconText = {}
IconText.__index = IconText
common.IconText = IconText

--- Create a new block holing Icon and Text elements
---
--- The argument is a table holding various settings
--- * parent -  (required) the block in which the IconText will created
--- * textId - (optional) the registerd ID of the text element
--- * isLabel - (optional) if true, the text element is a Label, otherwise a TextSelect
--- * path - (optional) the path to the Icon
--- * text - (optional) the text of the text element
function IconText:create(args)
	local element = {}
	setmetatable(element, self)
	element.block = args.parent:createBlock()
	element.block.autoHeight = true
	element.block.autoWidth = true
	element.block.flowDirection = tes3.flowDirection.leftToRight
	element.icon = element.block:createImage()
	if args.isLabel then
		element.text = element.block:createLabel{id = args.textId}
	else
		element.text = element.block:createTextSelect{id = args.textId}
	end

	element:setPath(args.path)
	element:setText(args.text)
	return element
end

--- Sets the path to the Icon
---
--- If path is nil, then the Icon is hidden. The border will be updated
--- appropriately to maintain text alignment
function IconText:setPath(path)
	if path then
		self.icon.contentPath = "Icons\\" .. path
		self.icon.visible = true
		self.text.borderLeft = 10
	else
		self.icon.visible = false
		self.text.borderLeft = 10 + 16
	end
end

--- Sets the text to be displayed
---
--- Also sets the text of the block, which is not visible, but allows
--- for the block itself to be sorted based on the text value.
function IconText:setText(text)
	self.block.text = text
	self.text.text = text
end

--- Print out all the children recursively to examine the arrangement of UI elements
function common:logTree(parent, indent)
	indent = indent or ""
	for _, c in ipairs(parent.children) do
		local t = c.text or "_"
		local p = c.contentPath or "_"
		local ty = c.type
		log:debug("" .. indent .. ty .. " " .. c.name .. " " .. c.id .. " " .. t .. " " .. p)

		for _, k in pairs({"name", "absolutePosAlignX", "absolutePosAlignY", "autoHeight", "autoWidth",
						    "height", "width", "flowDirection", "minHeight", "minWidth", "maxHeight", "maxWidth",
							"ignoreLayoutX", "ignoreLayoutY", "heightProportional", "widthProportional",
						    "childAlignX", "childAlignY", "childOffsetX", "childOffsetY", "paddingAllSides",
							"paddingBottom", "paddingLeft", "paddingRight", "paddingTop",
							"borderAllSides", "borderBottom", "borderLeft", "borderRight", "borderTop"}) do
			if c[k] then
				-- log:debug("  " .. indent .. "child[" .. k .. "] = " .. tostring(c[k]))
			end
		end

		self:logTree(c, indent .. "  ")
	end
end

return common
