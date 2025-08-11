-- CETVars.lua
-- Variable management and SavedVariables handling for CET addon

CETVars = CETVars or {}
CETSaved = CETSaved or {}

-- Current addon version
CETVars.version = CETDefaults.version

-- Runtime variables - these are reset on each reload
CETVars.channelSettings = CETDefaults.deepCopy(CETDefaults.defaultChannelSettings)
CETVars.translationDirection = CETDefaults.defaultTranslationDirection
CETVars.apiKey = CETDefaults.defaultApiKey
CETVars.debugMode = CETDefaults.defaultDebugMode
CETVars.showOriginalText = CETDefaults.defaultShowOriginalText
CETVars.translationPrefix = CETDefaults.defaultTranslationPrefix
CETVars.ignoreList = CETDefaults.deepCopy(CETDefaults.defaultIgnoreList)

-- DLL communication state
CETVars.dllInitialized = false
CETVars.translatorReady = false

-- Helper function to set saved variables with fallback to defaults
local function setSavedVariable(savedVar, defaultVar, savedName)
    if savedVar ~= nil then
        return savedVar
    else
        local fallbackValue = defaultVar or ""
        CETSaved[savedName] = fallbackValue
        return fallbackValue
    end
end

-- Load saved variables or initialize defaults
function CETVars.LoadSavedVariables()
    -- Ensure the root table exists
    CETSaved = CETSaved or {}
    
    -- Load channel settings (simple boolean values)
    if CETSaved.channelSettings and type(CETSaved.channelSettings) == "table" then
        CETVars.channelSettings = {}
        -- Copy saved settings
        for channelType, enabled in pairs(CETSaved.channelSettings) do
            CETVars.channelSettings[channelType] = enabled
        end
        -- Ensure all default channels exist
        for channelType, defaultValue in pairs(CETDefaults.defaultChannelSettings) do
            if CETVars.channelSettings[channelType] == nil then
                CETVars.channelSettings[channelType] = defaultValue
            end
        end
    else
        CETVars.channelSettings = CETDefaults.deepCopy(CETDefaults.defaultChannelSettings)
        CETSaved.channelSettings = CETVars.channelSettings
    end
    
    -- Load translation direction (simple string)
    if CETSaved.translationDirection and CETDefaults.translationDirections[CETSaved.translationDirection] then
        CETVars.translationDirection = CETSaved.translationDirection
    else
        CETVars.translationDirection = CETDefaults.defaultTranslationDirection
        CETSaved.translationDirection = CETVars.translationDirection
    end
    
    -- Load other settings
    CETVars.apiKey = setSavedVariable(CETSaved.apiKey, CETDefaults.defaultApiKey, "apiKey")
    CETVars.debugMode = setSavedVariable(CETSaved.debugMode, CETDefaults.defaultDebugMode, "debugMode")
    CETVars.showOriginalText = setSavedVariable(CETSaved.showOriginalText, CETDefaults.defaultShowOriginalText, "showOriginalText")
    CETVars.translationPrefix = setSavedVariable(CETSaved.translationPrefix, CETDefaults.defaultTranslationPrefix, "translationPrefix")
    
    -- Load ignore list
    if CETSaved.ignoreList and type(CETSaved.ignoreList) == "table" then
        CETVars.ignoreList = CETDefaults.deepCopy(CETSaved.ignoreList)
    else
        CETVars.ignoreList = CETDefaults.deepCopy(CETDefaults.defaultIgnoreList)
        CETSaved.ignoreList = CETVars.ignoreList
    end
end

-- Save current runtime variables to saved variables
function CETVars.SaveVariables()
    CETSaved.channelSettings = CETDefaults.deepCopy(CETVars.channelSettings)
    CETSaved.translationDirection = CETDefaults.deepCopy(CETVars.translationDirection)
    CETSaved.apiKey = CETVars.apiKey
    CETSaved.debugMode = CETVars.debugMode
    CETSaved.showOriginalText = CETVars.showOriginalText
    CETSaved.translationPrefix = CETVars.translationPrefix
    CETSaved.ignoreList = CETDefaults.deepCopy(CETVars.ignoreList)
end

-- Toggle a channel's enabled state
function CETVars.ToggleChannel(channelType)
    if CETVars.channelSettings[channelType] ~= nil then
        CETVars.channelSettings[channelType] = not CETVars.channelSettings[channelType]
        CETVars.SaveVariables()
        return CETVars.channelSettings[channelType]
    end
    return false
end

-- Set translation direction
function CETVars.SetTranslationDirection(fromLang, toLang)
    if CETDefaults.isValidLanguageCode(fromLang) and CETDefaults.isValidLanguageCode(toLang) then
        CETVars.translationDirection.from = fromLang
        CETVars.translationDirection.to = toLang
        CETVars.SaveVariables()
        return true
    end
    return false
end

-- Set API key
function CETVars.SetAPIKey(key)
    CETVars.apiKey = key or ""
    CETVars.SaveVariables()
end

-- Get channel status for display
function CETVars.GetChannelStatus(channelType)
    local enabled = CETVars.channelSettings[channelType]
    if enabled == nil then
        return "Unknown"
    end
    
    return enabled and "Enabled" or "Disabled"
end

-- Reset all settings to defaults
function CETVars.ResetToDefaults()
    CETVars.channelSettings = CETDefaults.deepCopy(CETDefaults.defaultChannelSettings)
    CETVars.translationDirection = CETDefaults.defaultTranslationDirection
    CETVars.apiKey = CETDefaults.defaultApiKey
    CETVars.debugMode = CETDefaults.defaultDebugMode
    CETVars.showOriginalText = CETDefaults.defaultShowOriginalText
    CETVars.translationPrefix = CETDefaults.defaultTranslationPrefix
    CETVars.ignoreList = CETDefaults.deepCopy(CETDefaults.defaultIgnoreList)
    CETVars.SaveVariables()
end

-- Ignore list management functions
function CETVars.AddToIgnoreList(playerName)
    if not playerName or playerName == "" then
        return false
    end
    
    -- Normalize player name (remove server name if present)
    local normalizedName = string.gsub(playerName, "%-.*", "")
    
    -- Check if already in list
    for _, name in pairs(CETVars.ignoreList) do
        if string.lower(name) == string.lower(normalizedName) then
            return false -- Already exists
        end
    end
    
    table.insert(CETVars.ignoreList, normalizedName)
    return true
end

function CETVars.RemoveFromIgnoreList(playerName)
    if not playerName or playerName == "" then
        return false
    end
    
    local normalizedName = string.gsub(playerName, "%-.*", "")
    
    for i, name in pairs(CETVars.ignoreList) do
        if string.lower(name) == string.lower(normalizedName) then
            table.remove(CETVars.ignoreList, i)
            return true
        end
    end
    return false
end

function CETVars.IsPlayerIgnored(playerName)
    if not playerName or playerName == "" then
        return false
    end
    
    local normalizedName = string.gsub(playerName, "%-.*", "")
    
    for _, name in pairs(CETVars.ignoreList) do
        if string.lower(name) == string.lower(normalizedName) then
            return true
        end
    end
    return false
end

function CETVars.GetIgnoreListAsString()
    if not CETVars.ignoreList or table.getn(CETVars.ignoreList) == 0 then
        return ""
    end
    
    local result = ""
    for i, name in pairs(CETVars.ignoreList) do
        if i > 1 then
            result = result .. "\n"
        end
        result = result .. name
    end
    return result
end

function CETVars.SetIgnoreListFromString(listText)
    CETVars.ignoreList = {}
    
    if not listText or listText == "" then
        return
    end
    
    -- Split by newlines and add each valid name
    local lines = {}
    for line in string.gfind(listText, "[^\n]+") do
        line = string.gsub(line, "^%s*(.-)%s*$", "%1") -- Trim whitespace
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    
    for _, name in pairs(lines) do
        CETVars.AddToIgnoreList(name)
    end
end
