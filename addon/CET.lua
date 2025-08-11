-- CET.lua
-- Main addon file for Chat Event Trigger (CET)
-- Combines chat event handling with real-time translation via DLL communication

CET = CET or {}

-- Chat event mappings for WoW 1.12.1
local CHAT_EVENT_MAPPINGS = {
    SAY = "CHAT_MSG_SAY",
    WHISPER = {"CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM"},
    PARTY = "CHAT_MSG_PARTY",
    RAID = "CHAT_MSG_RAID",
    GUILD = "CHAT_MSG_GUILD",
    YELL = "CHAT_MSG_YELL",
    -- Channel events handled by CHAT_MSG_CHANNEL
}

-- Create main frame for event handling
local eventFrame = CreateFrame("Frame", "CETFrame")

-- Print function with addon prefix
function CET.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF96[CET]|r " .. message)
end

-- Debug print function
local function DebugPrint(message)
    if CETVars.debugMode then
        CET.Print("|cFFFFFF00[DEBUG]|r " .. message)
    end
end

-- DLL communication wrapper - uses UnitXP interface
local function CallCET(...)
    if UnitXP then
        return UnitXP("CET", unpack(arg))
    else
        return "UnitXP not available - CET.dll required"
    end
end

-- Hook outgoing chat messages for translation
local originalSendChatMessage = SendChatMessage
local function HookedSendChatMessage(msg, chatType, language, channel)
    DebugPrint("HookedSendChatMessage called: '" .. tostring(msg) .. "', type: " .. tostring(chatType or "nil"))
    
    -- Handle nil chatType (WoW 1.12.1 compatibility)
    if not chatType then
        DebugPrint("chatType is nil, sending original message")
        originalSendChatMessage(msg, chatType, language, channel)
        return
    end
    
    -- Check if we should translate this outgoing message
    local shouldTranslate = false
    
    -- Map chat types to our channel settings
    if chatType == "SAY" then
        shouldTranslate = CETVars.channelSettings.SAY
    elseif chatType == "WHISPER" then
        shouldTranslate = CETVars.channelSettings.WHISPER
    elseif chatType == "PARTY" then
        shouldTranslate = CETVars.channelSettings.PARTY
    elseif chatType == "RAID" then
        shouldTranslate = CETVars.channelSettings.RAID
    elseif chatType == "GUILD" then
        shouldTranslate = CETVars.channelSettings.GUILD
    elseif chatType == "YELL" then
        shouldTranslate = CETVars.channelSettings.YELL
    elseif chatType == "CHANNEL" then
        shouldTranslate = CETVars.channelSettings.CHANNEL
    end
    
    DebugPrint("Channel " .. tostring(chatType) .. " translation enabled: " .. tostring(shouldTranslate))
    
    if shouldTranslate and CETVars.translatorReady and msg and msg ~= "" then
        -- Determine translation direction for outbound (always outbound here)
        local actualTranslationDirection
        if CETVars.translationDirection == "cn_to_en" then
            -- CN → EN (Inbound) / EN → CN (Outbound)
            actualTranslationDirection = "en_to_cn"
        else -- en_to_cn
            -- EN → CN (Inbound) / CN → EN (Outbound)  
            actualTranslationDirection = "cn_to_en"
        end
        
        -- Map to actual language codes for translation
        local fromLang, toLang
        if actualTranslationDirection == "cn_to_en" then
            fromLang = "zh"
            toLang = "en"
        else -- en_to_cn
            fromLang = "en"
            toLang = "zh"
        end
        
        DebugPrint("Translating outbound message: " .. actualTranslationDirection .. " (" .. tostring(fromLang) .. " -> " .. tostring(toLang) .. ")")
        
        -- Attempt translation
        local translatedMsg = CET.TranslateText(msg, fromLang, toLang)
        
        if translatedMsg and translatedMsg ~= msg then
            DebugPrint("Sending translated message: '" .. tostring(translatedMsg) .. "'")
            originalSendChatMessage(translatedMsg, chatType, language, channel)
            return
        else
            DebugPrint("Translation failed or unchanged, sending original")
        end
    end
    
    -- Send original message if translation not enabled or failed
    originalSendChatMessage(msg, chatType, language, channel)
end

-- Initialize DLL communication and translator
function CET.InitializeDLL()
    if not UnitXP then
        CET.Print("|cFFFF0000Error:|r UnitXP function not available. CET.dll must be loaded.")
        return false
    end
    
    DebugPrint("Testing DLL communication...")
    local success, result = pcall(CallCET, "ping")
    
    if success and result and string.find(result, "CET") then
        CETVars.dllInitialized = true
        DebugPrint("DLL communication established: " .. result)
        
        -- Initialize translator if API key is available
        if CETVars.apiKey and CETVars.apiKey ~= "" then
            CET.InitializeTranslator()
        end
        
        return true
    else
        CET.Print("|cFFFF0000Error:|r Failed to establish DLL communication: " .. tostring(result))
        return false
    end
end

-- Install outgoing message hook
function CET.InstallMessageHook()
    if SendChatMessage ~= HookedSendChatMessage then
        DebugPrint("Installing SendChatMessage hook...")
        SendChatMessage = HookedSendChatMessage
        DebugPrint("SendChatMessage hook installed successfully")
    else
        DebugPrint("SendChatMessage hook already installed")
    end
end

-- Remove outgoing message hook
function CET.RemoveMessageHook()
    if SendChatMessage == HookedSendChatMessage then
        DebugPrint("Removing SendChatMessage hook...")
        SendChatMessage = originalSendChatMessage
        DebugPrint("SendChatMessage hook removed")
    else
        DebugPrint("SendChatMessage hook not currently installed")
    end
end

-- Initialize the translator with current API key
function CET.InitializeTranslator()
    if not CETVars.dllInitialized then
        CET.Print("|cFFFF0000Error:|r DLL not initialized")
        return false
    end
    
    if not CETVars.apiKey or CETVars.apiKey == "" then
        CET.Print("|cFFFF0000Error:|r No API key configured. Use /cet apikey <your_key>")
        return false
    end
    
    DebugPrint("Initializing translator with API key...")
    local success, result = pcall(CallCET, "init_translator", CETVars.apiKey)
    
    if success and result and string.find(result, "successfully") then
        CETVars.translatorReady = true
        CET.Print("Translator initialized successfully")
        DebugPrint(result)
        return true
    else
        CET.Print("|cFFFF0000Error:|r Failed to initialize translator: " .. tostring(result))
        return false
    end
end

-- Simple language detection based on character patterns
local function DetectLanguage(text)
    if not text or text == "" then
        return nil
    end
    
    -- Count Chinese characters (CJK range)
    local chineseCount = 0
    local totalChars = string.len(text)
    
    -- Simple heuristic: if more than 30% of characters are in CJK range, likely Chinese
    for i = 1, totalChars do
        local byte = string.byte(text, i)
        -- UTF-8 encoded Chinese characters typically start with bytes in this range
        if byte and byte >= 228 and byte <= 233 then
            chineseCount = chineseCount + 1
        end
    end
    
    local chineseRatio = chineseCount / totalChars
    if chineseRatio > 0.3 then
        return "zh"
    else
        return "en" -- Default to English for non-Chinese text
    end
end

-- Enhanced language detection for translate command with higher threshold
local function DetectLanguageForTranslate(text)
    if not text or text == "" then
        return nil
    end
    
    local totalBytes = string.len(text)
    local chineseBytes = 0
    local alphaCount = 0
    
    -- Count UTF-8 Chinese characters and alphabetic characters
    local i = 1
    while i <= totalBytes do
        local byte = string.byte(text, i)
        
        if byte >= 224 and byte <= 239 then
            -- 3-byte UTF-8 sequence (covers most Chinese characters)
            local byte2 = string.byte(text, i + 1)
            local byte3 = string.byte(text, i + 2)
            
            if byte2 and byte3 then
                -- Check for Chinese/CJK ranges
                if (byte == 228 and byte2 >= 184) or  -- CJK Unified Ideographs start
                   (byte >= 229 and byte <= 233) or   -- CJK Unified Ideographs middle
                   (byte == 234 and byte2 <= 159) then -- CJK Unified Ideographs end
                    chineseBytes = chineseBytes + 3
                end
            end
            i = i + 3
        elseif byte >= 97 and byte <= 122 or byte >= 65 and byte <= 90 then
            -- a-z or A-Z
            alphaCount = alphaCount + 1
            i = i + 1
        else
            i = i + 1
        end
    end
    
    -- Calculate percentages
    local chineseRatio = chineseBytes / totalBytes
    local alphaRatio = alphaCount / totalBytes
    
    -- Use 75% threshold for Chinese detection as requested
    if chineseRatio >= 0.75 then
        return "zh"
    elseif alphaRatio >= 0.5 then
        return "en"
    elseif chineseRatio > alphaRatio then
        return "zh"
    else
        return "en"
    end
end

-- Perform translation
function CET.TranslateText(text, fromLang, toLang)
    DebugPrint("TranslateText called with: '" .. tostring(text) .. "' from " .. tostring(fromLang) .. " to " .. tostring(toLang))
    
    if not CETVars.translatorReady then
        DebugPrint("Translator not ready, skipping translation")
        DebugPrint("DLL initialized: " .. tostring(CETVars.dllInitialized))
        DebugPrint("API key set: " .. tostring(CETVars.apiKey ~= ""))
        return nil
    end
    
    if not text or text == "" then
        DebugPrint("Text is empty, skipping translation")
        return nil
    end
    
    DebugPrint("Calling DLL translate function...")
    local success, result = pcall(CallCET, "translate", text, fromLang, toLang)
    
    DebugPrint("pcall success: " .. tostring(success))
    DebugPrint("pcall result: " .. tostring(result))
    
    if success and result and not string.find(result, "failed") then
        DebugPrint("Translation successful: '" .. result .. "'")
        return result
    else
        DebugPrint("Translation failed: " .. tostring(result))
        return nil
    end
end

-- Check if we should process a chat event
local function ShouldProcessMessage(event, channelString, isOutbound)
    if not event then
        DebugPrint("ShouldProcessMessage: event is nil")
        return false
    end
    
    if string.len(event) < 10 then
        DebugPrint("ShouldProcessMessage: event too short: " .. event)
        return false
    end
    
    local messageType = string.sub(event, 10) -- Remove "CHAT_MSG_" prefix
    DebugPrint("Message type: " .. messageType .. ", isOutbound: " .. tostring(isOutbound))
    
    -- Handle channel messages specially
    if messageType == "CHANNEL" then
        local channelEnabled = CETVars.channelSettings.CHANNEL
        DebugPrint("CHANNEL enabled: " .. tostring(channelEnabled))
        return channelEnabled or false
    end
    
    -- Handle regular chat types - simple boolean check
    local channelEnabled = CETVars.channelSettings[messageType]
    DebugPrint("Channel " .. messageType .. " enabled: " .. tostring(channelEnabled))
    return channelEnabled or false
end

-- Process and potentially translate a chat message
local function ProcessChatMessage(event)
    local message = arg1
    local sender = arg2
    local language = arg3
    local channelString = arg4
    local playerGUID = arg5
    local specialFlags = arg6
    local zoneChannelID = arg7
    local channelIndex = arg8
    local channelName = arg9
    
    DebugPrint("ProcessChatMessage called with event: " .. tostring(event))
    DebugPrint("Message: '" .. tostring(message) .. "' from sender: '" .. tostring(sender) .. "'")
    
    -- Check if player is on ignore list
    if sender and CETVars.IsPlayerIgnored(sender) then
        DebugPrint("Player " .. sender .. " is on ignore list, skipping translation")
        return
    end
    
    -- Determine if this is an inbound or outbound message
    local playerName = UnitName("player")
    local isOutbound = (sender == playerName)
    
    DebugPrint("Player name: " .. tostring(playerName))
    DebugPrint("Message direction: " .. (isOutbound and "Outbound" or "Inbound"))
    
    -- Check if we should process this message type
    local shouldProcess = ShouldProcessMessage(event, channelString, isOutbound)
    DebugPrint("ShouldProcessMessage returned: " .. tostring(shouldProcess))
    if not shouldProcess then
        return
    end
    
    -- Skip empty messages
    if not message or message == "" then
        DebugPrint("Message is empty, skipping")
        return
    end
    
    -- Determine actual translation direction based on message direction
    local actualTranslationDirection
    if CETVars.translationDirection == "cn_to_en" then
        -- CN → EN (Inbound) / EN → CN (Outbound)
        actualTranslationDirection = isOutbound and "en_to_cn" or "cn_to_en"
    else -- en_to_cn
        -- EN → CN (Inbound) / CN → EN (Outbound)  
        actualTranslationDirection = isOutbound and "cn_to_en" or "en_to_cn"
    end
    
    -- Map to actual language codes for translation
    local fromLang, toLang
    if actualTranslationDirection == "cn_to_en" then
        fromLang = "zh"
        toLang = "en"
    else -- en_to_cn
        fromLang = "en"
        toLang = "zh"
    end
    
    DebugPrint("Processing message: '" .. message .. "' from " .. sender)
    DebugPrint("Message direction: " .. (isOutbound and "Outbound" or "Inbound"))
    DebugPrint("Base translation setting: " .. CETVars.translationDirection)
    DebugPrint("Actual translation direction: " .. actualTranslationDirection)
    DebugPrint("Language codes: " .. fromLang .. " -> " .. toLang)
    DebugPrint("Translation ready: " .. tostring(CETVars.translatorReady))
    
    -- Detect the actual language of the message
    local detectedLang = DetectLanguage(message)
    DebugPrint("Detected language: " .. tostring(detectedLang))
    
    -- Skip translation if the message is already in the target language
    if detectedLang == toLang then
        DebugPrint("Message is already in target language (" .. toLang .. "), skipping translation")
        return
    end
    
    -- Skip translation if trying to translate from wrong source language
    if detectedLang ~= fromLang then
        DebugPrint("Message language (" .. tostring(detectedLang) .. ") doesn't match expected source (" .. fromLang .. "), skipping translation")
        return
    end
    
    -- Attempt translation
    local translation = CET.TranslateText(message, fromLang, toLang)
    
    DebugPrint("Translation result: " .. tostring(translation))
    
    if translation and translation ~= message then
        -- Display translated message
        local prefix = CETVars.translationPrefix .. " "
        local translatedDisplay = prefix .. translation
        
        if CETVars.showOriginalText then
            translatedDisplay = translatedDisplay .. " |cFF808080(Original: " .. message .. ")|r"
        end
        
        -- Display in appropriate chat frame with sender info
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF96[" .. sender .. "]|r " .. translatedDisplay)
    end
end

-- Event handler
local function OnEvent()
    if event == "ADDON_LOADED" and arg1 == "CET" then
        -- Load saved variables
        CETVars.LoadSavedVariables()
        
        CET.Print("Chat Event Trigger v" .. CETVars.version .. " loaded")
        
        -- Initialize DLL communication
        CET.InitializeDLL()
        
        -- Install outgoing message hook
        CET.InstallMessageHook()
        
        -- Register chat events
        CET.RegisterChatEvents()
        
    elseif event == "PLAYER_LOGOUT" then
        -- Save variables
        CETVars.SaveVariables()
        
        -- Clean up hook
        CET.RemoveMessageHook()
        
    elseif event and string.find(event, "CHAT_MSG_") then
        -- Process chat messages
        ProcessChatMessage(event)
    end
end

-- Register chat events based on enabled channels
function CET.RegisterChatEvents()
    -- Unregister all chat events first
    for _, eventName in pairs(CHAT_EVENT_MAPPINGS) do
        if type(eventName) == "table" then
            for _, subEvent in ipairs(eventName) do
                eventFrame:UnregisterEvent(subEvent)
            end
        else
            eventFrame:UnregisterEvent(eventName)
        end
    end
    eventFrame:UnregisterEvent("CHAT_MSG_CHANNEL")
    
    -- Register events for enabled channels
    for channelType, enabled in pairs(CETVars.channelSettings) do
        if enabled then
            local events = CHAT_EVENT_MAPPINGS[channelType]
            if events then
                if type(events) == "table" then
                    for _, eventName in ipairs(events) do
                        eventFrame:RegisterEvent(eventName)
                        DebugPrint("Registered event: " .. eventName)
                    end
                else
                    eventFrame:RegisterEvent(events)
                    DebugPrint("Registered event: " .. events)
                end
            elseif channelType == "CHANNEL" then
                eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
                DebugPrint("Registered event: CHAT_MSG_CHANNEL")
            end
        end
    end
end

-- Slash command handler
SLASH_CET1 = "/cet"
SlashCmdList["CET"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, word)
    end
    
    local cmd = args[1] or "help"
    cmd = string.lower(cmd)
    
    if cmd == "help" then
        CET.Print("Commands:")
        CET.Print("/cet status - Show current settings")
        CET.Print("/cet toggle <channel> - Toggle channel (say/whisper/party/raid/guild/yell/channel)")
        CET.Print("/cet direction <direction> - Set translation direction (cn_to_en or en_to_cn)")
        CET.Print("/cet apikey <key> - Set Google Translate API key")
        CET.Print("/cet ui - Open settings UI")
        CET.Print("/cet test - Test DLL communication")
        CET.Print("/cet debug - Toggle debug mode")
        CET.Print("/cet reset - Reset all settings to defaults")
        CET.Print("/cet translate \"message\" - Quick translate a message")
        
    elseif cmd == "status" then
        CET.Print("=== CET Status ===")
        CET.Print("DLL: " .. (CETVars.dllInitialized and "Ready" or "Not Connected"))
        CET.Print("Translator: " .. (CETVars.translatorReady and "Ready" or "Not Ready"))
        CET.Print("Outbound Hook: " .. (SendChatMessage == HookedSendChatMessage and "Active" or "Inactive"))
        CET.Print("Translation: " .. (CETDefaults.translationDirections[CETVars.translationDirection] or CETVars.translationDirection))
        CET.Print("API Key: " .. (CETVars.apiKey ~= "" and "Set" or "Not Set"))
        CET.Print("Debug: " .. (CETVars.debugMode and "On" or "Off"))
        CET.Print("Channels:")
        for channelType, _ in pairs(CETVars.channelSettings) do
            local status = CETVars.GetChannelStatus(channelType)
            CET.Print("  " .. channelType .. ": " .. status)
        end
        
    elseif cmd == "toggle" then
        local channelType = args[2]
        if channelType then
            channelType = string.upper(channelType)
            if CETVars.channelSettings[channelType] then
                local enabled = CETVars.ToggleChannel(channelType)
                CET.Print(channelType .. " channel " .. (enabled and "enabled" or "disabled"))
                CET.RegisterChatEvents() -- Re-register events
            else
                CET.Print("Unknown channel: " .. channelType)
            end
        else
            CET.Print("Usage: /cet toggle <channel>")
        end
        
    elseif cmd == "direction" then
        local direction = args[2]
        if direction then
            if CETDefaults.translationDirections[direction] then
                CETVars.translationDirection = direction
                CETVars.SaveVariables()
                CET.Print("Translation direction set to: " .. CETDefaults.translationDirections[direction])
            else
                CET.Print("Invalid direction. Use: cn_to_en or en_to_cn")
            end
        else
            CET.Print("Usage: /cet direction <direction>")
            CET.Print("Available directions:")
            for key, desc in pairs(CETDefaults.translationDirections) do
                CET.Print("  " .. key .. " - " .. desc)
            end
        end
        
    elseif cmd == "ui" then
        if CETUI and CETUI.ToggleMainFrame then
            CETUI.ToggleMainFrame()
        else
            CET.Print("|cFFFF0000Error:|r UI not available. Try /reload to restart addon.")
        end
        
    elseif cmd == "apikey" then
        local key = args[2]
        if key then
            CETVars.SetAPIKey(key)
            CET.Print("API key set. Reinitializing translator...")
            CET.InitializeTranslator()
        else
            CET.Print("Usage: /cet apikey <your_google_translate_api_key>")
        end
        
    elseif cmd == "test" then
        if not CETVars.dllInitialized then
            CET.Print("DLL not initialized. Attempting to connect...")
            CET.InitializeDLL()
        else
            local success, result = pcall(CallCET, "ping")
            CET.Print("DLL Test: " .. tostring(result))
        end
        
    elseif cmd == "debug" then
        CETVars.debugMode = not CETVars.debugMode
        CETVars.SaveVariables()
        CET.Print("Debug mode " .. (CETVars.debugMode and "enabled" or "disabled"))
        
    elseif cmd == "reset" then
        CETVars.ResetToDefaults()
        CET.RegisterChatEvents()
        CET.Print("All settings reset to defaults")
        
    elseif cmd == "translate" then
        -- Extract message from quotes or use remaining args
        local message = ""
        if string.find(msg, '"') then
            -- Extract text between quotes
            local startQuote = string.find(msg, '"')
            local endQuote = string.find(msg, '"', startQuote + 1)
            if startQuote and endQuote then
                message = string.sub(msg, startQuote + 1, endQuote - 1)
            end
        else
            -- Use everything after "translate "
            local translateStart = string.find(msg, "translate%s+")
            if translateStart then
                message = string.sub(msg, translateStart + 10) -- "translate " is 10 chars
                message = string.gsub(message, "^%s*(.-)%s*$", "%1") -- Trim whitespace
            end
        end
        
        if message == "" then
            CET.Print("Usage: /cet translate \"your message here\"")
            CET.Print("       /cet translate your message here")
            return
        end
        
        if not CETVars.translatorReady then
            CET.Print("|cFFFF0000Error:|r Translator not ready. Set API key and ensure DLL is connected.")
            CET.Print("Use: /cet apikey <your_key>")
            return
        end
        
        -- Auto-detect language and set translation direction accordingly
        local detectedLang = DetectLanguageForTranslate(message)
        local fromLang, toLang
        
        if detectedLang == "zh" then
            -- Chinese detected -> translate to English
            fromLang = "zh"
            toLang = "en"
            CET.Print("Detected Chinese text, translating to English...")
        else
            -- English or other -> translate to Chinese
            fromLang = "en" 
            toLang = "zh"
            CET.Print("Detected English text, translating to Chinese...")
        end
        
        CET.Print("Translating: \"" .. message .. "\" (" .. fromLang .. " → " .. toLang .. ")")
        
        local translation = CET.TranslateText(message, fromLang, toLang)
        if translation and translation ~= message then
            CET.Print("|cFF00FF00Translation:|r " .. translation)
        else
            CET.Print("|cFFFF0000Translation failed.|r Check your API key and network connection.")
        end
        
    else
        CET.Print("Unknown command. Use /cet help for available commands")
    end
end

-- Set up event handling
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", OnEvent)
