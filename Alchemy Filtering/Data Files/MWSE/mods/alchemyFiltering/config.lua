local EasyMCM = require("easyMCM.EasyMCM")
local i18n = mwse.loadTranslations("alchemyFiltering")

local textHeight = 20
local defaultConfig = {
    modEnabled = true,
    chosenEffectSticky = true,
    sortSticky = true,
    chooserHeight = 12 * textHeight,
}

local configFilename = "Alchemy Filtering"

local config = mwse.loadConfig(configFilename, defaultConfig)

local function onModConfigReady()
    local template = EasyMCM.createTemplate(strings.mcm.modName)
    template:saveOnClose(configFilename, config)
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

    settings:createOnOffButton({
        label = strings.mcm.chosenEffectSticky,
        description = strings.mcm.chosenEffectStickyDesc,
        variable = EasyMCM.createTableVariable {
            id = "chosenEffectSticky",
            table = config
        }
    })

    settings:createOnOffButton({
        label = strings.mcm.sortSticky,
        description = strings.mcm.sortStickyDesc,
        variable = EasyMCM.createTableVariable {
            id = "sortSticky",
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
