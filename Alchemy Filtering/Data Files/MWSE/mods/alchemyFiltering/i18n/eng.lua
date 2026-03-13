local translations = {
    chooseEffects = "Choose Effects",
    chosenEffect = "Chosen Effect:",

    sortBy = "Sort By:",
    sortName = "Name",
    sortCount = "Count",
    sortWeight = "Weight",
    sortValue = "Value",

    filterBy = "Filter By:",
    filterNone = "None",
    filterMatching = "Matching",
}

translations.mcm = {
    modName = "Alchemy Filtering",
    settings  = "Settings",

    modEnabled = {
        label = "Mod Status",
        desc = "Enabling and disabling the mod and all its functionality",
    },

    chosenEffectSticky = {
        label = "Chosen Effect is Sticky",
        desc = "Enabling this will make the previously chosen effect be selected when the Alchemy Menu is opened again",
    },

    sortSticky = {
        label = "Sort Order is Sticky",
        desc = "Enabling this will make the previous sorting order in the inventory select menu be used when the parent menu is opened again",
    },

    chooserHeight = {
        label = "Choose Effects Pane Height",
        desc = "Set the height in pixels for the choose effects pane that appears after clicking the " ..
            translations.chooseEffects .. " button",
    },
}

return translations
