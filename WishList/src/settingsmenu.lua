WishList = WishList or {}
local WL = WishList

------------------------------------------------------------------------------------------------------------
-- LibAddonMenu (LAM) Settings panel
------------------------------------------------------------------------------------------------------------

--Function to create a LAM control
local function CreateControl(ref, name, tooltip, data, disabledChecks, getFunc, setFunc, defaultSettings, warning, scrollable)
    scrollable = scrollable or false
    if ref ~= nil then
        if string.find(ref, GetString(WISHLIST_TITLE) .. "_LAM_", 1)  ~= 1 then
            data.reference = GetString(WISHLIST_TITLE) .. "_LAM_" .. ref
        else
            data.reference = ref
        end
    end
    if data.type ~= "description" then
        data.name = name
        if data.type ~= "header" and data.type ~= "submenu" then
            data.tooltip = tooltip
            if data.type ~= "button" then
                data.getFunc = getFunc
                data.setFunc = setFunc
                data.default = defaultSettings
            else
                data.func = setFunc
            end
            if disabledChecks ~= nil then
                data.disabled = disabledChecks
            end
            data.scrollable = scrollable
            data.warning = warning
        end
    end
    return data
end


function WL.buildAddonMenu()
    if WL.addonMenu == nil then return nil end
    --Local "speed up arrays/tables" variables
    local addonVars =       WL.addonVars
    local settings =        WL.data
    local defaults =        WL.defaultSettings
    local defaultSettings = WL.defaultAccSettings
    local accSettings =     WL.accData

    --FCOItemSaver variables
    local FCOISenabled = false
    local fcoisMarkerIconsList = {}
    local fcoisMarkerIconsListValues = {}
    if FCOIS ~= nil and FCOIS.GetLAMMarkerIconsDropdown ~= nil then
        fcoisMarkerIconsList, fcoisMarkerIconsListValues = FCOIS.GetLAMMarkerIconsDropdown("standard", true)
        FCOISenabled = true
    end

    local panelData    = {
        type                = "panel",
        name                = addonVars.settingsName,
        displayName         = addonVars.settingsDisplayName,
        author              = addonVars.addonAuthor,
        version             = tostring(addonVars.addonRealVersion),
        registerForRefresh  = true,
        registerForDefaults = true,
        slashCommand 		= "/wls",
        website             = addonVars.addonWebsite
    }

    local savedVariablesOptions = {
        [1] = GetString(WISHLIST_LAM_SV_EACH_CHAR),
        [2] = GetString(WISHLIST_LAM_SV_ACCOUNT_WIDE),
    }

    --Build the submenu controls (checkboxes) for each LibSets supported language
    local function buildLibSetsSetNameLanguagesCheckboxes()
        local retTable = {}
        local libSets = WL.LibSets
        if libSets and libSets.supportedLanguages then
            local langVars = {}
            for langStr, isEnabled in pairs(libSets.supportedLanguages) do
                if isEnabled then
                    table.insert(langVars, langStr)
                end
            end
            table.sort(langVars)
            --Get the client language
            local clientLang = WL.clientLang
            local clientLangIsSupportedInLibSets = libSets.supportedLanguages[clientLang]
            --If the client language is not supported within LibSets use EN (English) as default
            --Add all other languages now
            for _, langStrVarSorted in ipairs(langVars) do
                --Add the checkbox now
                local name = langStrVarSorted
                local tooltip = tostring(langStrVarSorted)
                local data = { type = "checkbox", width = "half" }
                local disabledFunc = function() return false end
                local getFunc
                local setFunc
                local defaultSettingsCB
                getFunc = function() return settings.useLanguageForSetNames[langStrVarSorted] end
                setFunc = function(value) WL.data.useLanguageForSetNames[langStrVarSorted] = value
                    WL.preventerVars.runSetNameLanguageChecks = true
                end
                defaultSettingsCB     = function()
                    local defValue
                    if defaultSettings.useLanguageForSetNames[langStrVarSorted] then
                        defValue = defaultSettings.useLanguageForSetNames[langStrVarSorted]
                    end
                    --No default value found for the actual language
                    if defValue == nil then
                        --Is the current language the client language?
                        if langStrVarSorted == clientLang then
                            --Is the current language supported within LibSets?
                            if clientLangIsSupportedInLibSets then
                                defValue = true
                            else
                                defValue = false
                            end
                        else
                            defValue = false
                        end
                    end
                    return defValue
                end
                --Create the checkbox now
                local createdTraitCB = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettingsCB, nil)
                if createdTraitCB then
                    table.insert(retTable, createdTraitCB)
                end
            end
        end
        return retTable
    end
    local libSetsSetNameLanguages = buildLibSetsSetNameLanguagesCheckboxes()

    --The options panel data for the LAM settings of this addon
    local optionsData  = {
        {
            type              = "description",
            text              = GetString(WISHLIST_LAM_ADDON_DESC),
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_SAVEDVARIABLES),
        },
        {
            type = 'dropdown',
            name = GetString(WISHLIST_LAM_SV),
            tooltip = GetString(WISHLIST_LAM_SV_TT),
            choices = savedVariablesOptions,
            getFunc = function() return savedVariablesOptions[accSettings.saveMode] end,
            setFunc = function(value)
                for i,v in pairs(savedVariablesOptions) do
                    if v == value then
                        accSettings.saveMode = i
                    end
                end
            end,
            default = function() return defaultSettings.saveMode end,
            --warning = GetString(WISHLIST_WARNING_RELOADUI),
            requiresReload = true,
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_ADD_MAIN_MENU_BUTTON),
            tooltip = GetString(WISHLIST_LAM_ADD_MAIN_MENU_BUTTON_TT),
            getFunc = function() return settings.showMainMenuButton end,
            setFunc = function(value)
                settings.showMainMenuButton = value
            end,
            default = defaults.showMainMenuButton,
        },
        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_FORMAT_OPTIONS),
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_USE_24h_FORMAT),
            tooltip = GetString(WISHLIST_LAM_USE_24h_FORMAT_TT),
            getFunc = function() return accSettings.use24hFormat end,
            setFunc = function(value)
                accSettings.use24hFormat = value
            end,
            default = defaultSettings.use24hFormat,
            disabled = function() return accSettings.useCustomDateFormat ~= "" end
        },
        {
            type = "editbox",
            name = GetString(WISHLIST_LAM_USE_CUSTOM_DATETIME_FORMAT),
            tooltip = GetString(WISHLIST_LAM_USE_CUSTOM_DATETIME_FORMAT_TT),
            getFunc = function() return accSettings.useCustomDateFormat end,
            setFunc = function(value)
                accSettings.useCustomDateFormat = value
            end,
            default = defaultSettings.useCustomDateFormat,
        },

        {
            type = "submenu",
            name = GetString(WISHLIST_LAM_SETNAME_LANGUAGES),
            tooltip = GetString(WISHLIST_LAM_SETNAME_LANGUAGES_TT),
            controls = libSetsSetNameLanguages,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_SCAN),
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_SCAN_ALL_CHARS),
            tooltip = GetString(WISHLIST_LAM_SCAN_ALL_CHARS_TT),
            getFunc = function() return settings.scanAllChars end,
            setFunc = function(value)
                settings.scanAllChars = value
            end,
            default = defaults.scanAllChars,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_ADD_ITEM),
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_PRESELECT_CHAR_ON_ITEM_ADD),
            tooltip = GetString(WISHLIST_LAM_PRESELECT_CHAR_ON_ITEM_ADD_TT),
            getFunc = function() return settings.preSelectLoggedinCharAtItemAddDialog end,
            setFunc = function(value)
                settings.preSelectLoggedinCharAtItemAddDialog = value
            end,
            default = defaults.preSelectLoggedinCharAtItemAddDialog,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_SORT),
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_SORT_USE_TIEBRAKER_NAME),
            tooltip = GetString(WISHLIST_LAM_SORT_USE_TIEBRAKER_NAME_TT),
            getFunc = function() return settings.useSortTiebrakerName end,
            setFunc = function(value)
                settings.useSortTiebrakerName = value
                WL.window:BuildSortKeys()
            end,
            default = defaults.useSortTiebrakerName,
        },
        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_ITEM_FOUND),
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_ITEM_FOUND_USE_CHARACTERNAME),
            tooltip = GetString(WISHLIST_LAM_ITEM_FOUND_USE_CHARACTERNAME_TT),
            getFunc = function() return settings.useItemFoundCharacterName end,
            setFunc = function(value)
                settings.useItemFoundCharacterName = value
            end,
            default = defaults.useItemFoundCharacterName,
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_ITEM_FOUND_USE_CSA),
            tooltip = GetString(WISHLIST_LAM_ITEM_FOUND_USE_CSA_TT),
            getFunc = function() return settings.useItemFoundCSA end,
            setFunc = function(value)
                settings.useItemFoundCSA = value
            end,
            default = defaults.useItemFoundCSA,
        },
        {
            type = "editbox",
            name = GetString(WISHLIST_LAM_ITEM_FOUND_TEXT),
            tooltip = GetString(WISHLIST_LAM_ITEM_FOUND_TEXT_TT),
            isMultiline = false,
            isExtraWide = true,
            getFunc = function() return settings.itemFoundText end,
            setFunc = function(value)
                if value == "" then value = GetString(WISHLIST_LOOT_MSG_STANDARD) end
                settings.itemFoundText = value
            end,
            default = defaults.itemFoundText,
            width = "full",
        },
        --==============================================================================
        {
            type = 'header',
            name = GetString(WISHLIST_LAM_FCOIS),
        },
        {
            type = "checkbox",
            name = GetString(WISHLIST_LAM_FCOIS_MARK_ITEM_AUTO),
            tooltip = GetString(WISHLIST_LAM_FCOIS_MARK_ITEM_AUTO_TT),
            getFunc = function() return settings.fcoisMarkerIconAutoMarkLootedSetPart end,
            setFunc = function(value)
                settings.fcoisMarkerIconAutoMarkLootedSetPart = value
            end,
            default = defaults.fcoisMarkerIconAutoMarkLootedSetPart,
            disabled = function() return not FCOISenabled end,
            width = "half",
        },
        {
            type = 'dropdown',
            name = GetString(WISHLIST_LAM_FCOIS_MARK_ITEM_ICON),
            tooltip = GetString(WISHLIST_LAM_FCOIS_MARK_ITEM_ICON),
            choices = fcoisMarkerIconsList,
            choicesValues = fcoisMarkerIconsListValues,
            scrollable = true,
            getFunc = function() return settings.fcoisMarkerIconLootedSetPart end,
            setFunc = function(value)
                settings.fcoisMarkerIconLootedSetPart = value
            end,
            default = defaults.fcoisMarkerIconLootedSetPart,
            disabled = function() return not FCOISenabled or not settings.fcoisMarkerIconAutoMarkLootedSetPart end,
            width = "half",
        },

    }
    WL.addonMenuPanel = WL.addonMenu:RegisterAddonPanel(addonVars.addonName .. "_SettingsMenu", panelData)
    WL.addonMenu:RegisterOptionControls(addonVars.addonName .. "_SettingsMenu", optionsData)
    WL.preventerVars.addonMenuBuild = true
end

