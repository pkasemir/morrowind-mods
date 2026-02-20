local log = mwse.Logger.new()
log.level = "DEBUG"
local strings = require("alchemyFiltering.strings")
local config = require("alchemyFiltering.config")
local chooser = require("alchemyFiltering.chooser")
local selecter = require("alchemyFiltering.selecter")

-- This isn't actually needed for the mod to work, but it is useful for
-- debugging when your character gains alchemy skill causing more effects
-- to be visible, thus repopulating the chooser panes
local function onAlchemyRaised()
	if not config.modEnabled then return end
	log:debug("Alchemy raised")

	-- log:debug("Bump to skill 61")
	-- tes3.mobilePlayer.alchemy.current = 61
end

local function onModConfigEntryClosed()
	if config.modEnabled then
		local menuAlchemy = tes3ui.findMenu("MenuAlchemy")
		if not menuAlchemy and not config.chosenEffectSticky then
			chooser.chosenEffect = nil
		end
		if not chooser.menu then
			chooser:mergeWithMenuAlchemy(menuAlchemy)
		end
		if not selecter.menu then
			selecter:mergeWithMenuInventorySelect(tes3ui.findMenu("MenuInventorySelect"))
		end
	else
		chooser.data.active = false
		chooser:detachFromMenuAlchemy()
		selecter:detachFromMenuInventorySelect()
	end
end

local function onInitialized(e)
	chooser:init()
	selecter:init()
	if config.modEnabled then
		log:debug("enabled")
	else
		log:debug("disabled")
		chooser.data.active = false
	end
	event.register("modConfigEntryClosed", onModConfigEntryClosed, {filter = strings.mcm.modName})
	-- event.register("skillRaised", onAlchemyRaised, {filter = tes3.skill.alchemy})
end

event.register("initialized", onInitialized)
