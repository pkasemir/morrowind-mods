local i18n = mwse.loadTranslations("alchemyQuickOpen")

local configFilename = "Alchemy Quick Open"

local config = mwse.loadConfig(configFilename, {})

local function onModConfigReady()
    local template = mwse.mcm.createTemplate{
        name = i18n("mcm.modName"),
        config = config,
    }
    template:register()
    template:saveOnClose(configFilename, config)

    local page = template:createSideBarPage{label = i18n("mcm.settings")};
    local settings = page:createCategory(i18n("mcm.settings"))

    settings:createKeyBinder{
        label = i18n("mcm.keybind.label"),
        description = i18n("mcm.keybind.desc"),
        allowCombinations = true,
        allowMouse = true,
        configKey = "keybind",
        keybindName = i18n("mcm.keybind.name"),
        defaultSetting = {
            keyCode = tes3.scanCode.a,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        showDefaultSetting = true,
    }
end

event.register(tes3.event.modConfigReady, onModConfigReady)

return config
