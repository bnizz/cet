-- CETDefaults.lua
-- Default configuration values for Chat Event Trigger (CET) addon

CETDefaults = CETDefaults or {}

-- Current addon version
CETDefaults.version = "1.0.0"

-- Default channel settings - which chat channels to monitor for translation
CETDefaults.defaultChannelSettings = {
    SAY = false,
    WHISPER = false,
    PARTY = false,
    RAID = false,
    GUILD = false,
    YELL = false,
    -- Channel system for custom channels
    CHANNEL = false
}

-- Default translation directions - simplified two-option system
-- "cn_to_en" = Chinese to English inbound, English to Chinese outbound  
-- "en_to_cn" = English to Chinese inbound, Chinese to English outbound
CETDefaults.defaultTranslationDirection = "cn_to_en"

-- Available translation directions
CETDefaults.translationDirections = {
    cn_to_en = "CN → EN (Inbound) / EN → CN (Outbound)",
    en_to_cn = "EN → CN (Inbound) / CN → EN (Outbound)"
}

-- Default API configuration
CETDefaults.defaultApiKey = ""
CETDefaults.defaultApiEndpoint = "https://translation.googleapis.com/language/translate/v2"

-- Default UI settings
CETDefaults.defaultDebugMode = false
CETDefaults.defaultShowOriginalText = true
CETDefaults.defaultTranslationPrefix = "[T]"

-- Default player ignore list for translation
CETDefaults.defaultIgnoreList = {}

-- Default performance settings
CETDefaults.defaultTranslationTimeout = 10000 -- 10 seconds
CETDefaults.defaultCacheExpiration = 3600 -- 1 hour
CETDefaults.defaultMaxCacheSize = 1000

-- Deep copy utility for default settings
function CETDefaults.deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in pairs(original) do
            copy[key] = CETDefaults.deepCopy(value)
        end
    else
        copy = original
    end
    return copy
end

-- Get default settings for a specific channel type
function CETDefaults.getChannelDefaults(channelType)
    return CETDefaults.defaultChannelSettings[channelType] or false
end

-- Validate language codes
function CETDefaults.isValidLanguageCode(code)
    local validCodes = {
        "zh", "zh-cn", "zh-tw", "en", "ja", "ko", "es", "fr", "de", "ru", "pt", "it", "ar",
        "hi", "th", "vi", "id", "ms", "tl", "nl", "sv", "no", "da", "fi", "pl", "cs", "hu",
        "bg", "hr", "sr", "sk", "sl", "et", "lv", "lt", "ro", "el", "tr", "he", "fa", "ur"
    }
    
    for _, validCode in ipairs(validCodes) do
        if code == validCode then
            return true
        end
    end
    return false
end
