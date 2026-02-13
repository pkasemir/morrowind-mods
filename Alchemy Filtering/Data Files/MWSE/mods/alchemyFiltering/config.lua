local EasyMCM = require("easyMCM.EasyMCM")
local strings = require("alchemyFiltering.strings")

local textHeight = 20
local defaultConfig = {
	modEnabled = true,
	chooserHeight = 12 * textHeight,
}

local config = mwse.loadConfig(strings.mcm.modName, defaultConfig)

local function onModConfigReady()
	local template = EasyMCM.createTemplate(strings.mcm.modName)
	template:saveOnClose(strings.mcm.modName, config)
	template:register();

	local page = template:createSideBarPage{label = strings.mcm.settings};
	local settings = page:createCategory(strings.mcm.settings)

	settings:createOnOffButton({
	label = strings.mcm.modEnabled,
	description = strings.mcm.modEnabledDesc,
	variable = EasyMCM.createTableVariable {
		id = "modEnabled",
		table = config
	}
	})

	settings:createSlider({
	label = strings.mcm.chooserHeight,
	min = 80,
	max = 300,
	description = strings.mcm.chooserHeightDesc,
	variable = EasyMCM.createTableVariable {
		id = "chooserHeight",
		table = config
	}
	})
end

event.register("modConfigReady", onModConfigReady)

return config
