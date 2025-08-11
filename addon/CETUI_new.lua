-- CETUI.lua
-- User interface for Chat Event Trigger (CET) addon

CETUI = CETUI or {}

-- Local references
local mainFrame
local scrollChild
local optionYOffset = -30  -- Starting vertical offset
local checkboxes = {}
local apiKeyEditBox

-- Spacing constants for better layout
local SECTION_SPACING = 40   -- Space between major sections
local OPTION_SPACING = 25    -- Space between individual options  
local LABEL_SPACING = 20     -- Space between label and input
local OPTION_LABEL_LEFT_MARGIN = 10  -- Left margin for labels

-- UI Creation helpers
local function CreateCheckbox(parent, text, checked, onClickHandler)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    checkbox:SetChecked(checked)
    
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(text)
    
    if onClickHandler then
        checkbox:SetScript("OnClick", onClickHandler)
    end
    
    return checkbox
end

local function CreateEditBox(parent, width, height, text)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetWidth(width)
    editBox:SetHeight(height)
    editBox:SetText(text or "")
    editBox:SetAutoFocus(false)
    
    -- Add styling
    local backdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    }
    editBox:SetBackdrop(backdrop)
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    editBox:SetTextInsets(6, 3, 3, 3)
    
    -- Add highlight effects
    editBox:SetScript("OnEditFocusGained", function()
        this:SetBackdropBorderColor(0.4, 0.4, 0.5, 1.0)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        this:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    end)
    
    return editBox
end

local function CreateLabel(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(text)
    return label
end

local function CreateSectionHeader(parent, text)
    local headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", OPTION_LABEL_LEFT_MARGIN, optionYOffset)
    headerFrame:SetHeight(20)
    
    -- Create the header text
    local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetAllPoints(headerFrame)
    header:SetText(text)
    header:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    header:SetTextColor(0.9, 0.9, 1.0, 1.0)  -- Blue-tinted header color
    header:SetJustifyH("LEFT")
    
    -- Set width based on actual text width plus padding
    headerFrame:SetWidth(header:GetStringWidth() + 40)
    
    -- Create a separator line
    local separator = parent:CreateTexture(nil, "BACKGROUND")
    separator:SetHeight(1)
    separator:SetWidth(450)
    separator:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", -5, -5)
    separator:SetTexture(1, 1, 1, 0.2)
    
    -- Adjust optionYOffset to account for header and separator
    optionYOffset = optionYOffset - 45
    
    return headerFrame
end

-- Position element and update optionYOffset
local function PositionElement(element, offsetX, offsetY)
    element:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", offsetX or OPTION_LABEL_LEFT_MARGIN, optionYOffset)
    optionYOffset = optionYOffset - (offsetY or OPTION_SPACING)
end

-- Create all UI elements
local function CreateSettingsUI()
    optionYOffset = -30  -- Start with proper offset
    
    -- Channel Settings Section
    optionYOffset = optionYOffset - SECTION_SPACING
    local channelHeader = CreateSectionHeader(scrollChild, "Chat Channels")
    
    local channelLabel = CreateLabel(scrollChild, "Select which chat channels to monitor:")
    PositionElement(channelLabel, OPTION_LABEL_LEFT_MARGIN, 5)
    
    -- Create checkboxes for each channel
    local channels = {"SAY", "WHISPER", "PARTY", "RAID", "GUILD", "YELL", "CHANNEL"}
    
    -- Calculate checkbox starting position
    local checkboxStartY = optionYOffset - 10
    
    for i, channel in ipairs(channels) do
        local displayName = channel
        local checked = CETVars.channelSettings[channel] or false
        
        -- Create a closure that captures the current channel value
        local function createCheckboxHandler(channelName)
            return function()
                local isChecked = this:GetChecked()
                CETVars.channelSettings[channelName] = (isChecked == 1)
                -- Don't auto-save, let the Save button handle it
            end
        end
        
        local checkbox = CreateCheckbox(scrollChild, displayName, checked, createCheckboxHandler(channel))
        
        -- Position checkboxes in two columns
        local column = math.mod((i - 1), 2)
        local row = math.floor((i - 1) / 2)
        checkbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", OPTION_LABEL_LEFT_MARGIN + (column * 200), checkboxStartY - (row * 25))
        
        checkboxes[channel] = checkbox
    end
    
    -- Update optionYOffset for the checkboxes
    optionYOffset = checkboxStartY - (math.ceil(table.getn(channels) / 2) * 25) - 10
    
    -- Translation Direction Section
    optionYOffset = optionYOffset - SECTION_SPACING
    local translationHeader = CreateSectionHeader(scrollChild, "Translation Direction")
    
    local directionLabel = CreateLabel(scrollChild, "Translation direction:")
    PositionElement(directionLabel, OPTION_LABEL_LEFT_MARGIN, 5)
    
    -- Create direction checkboxes
    local cn_to_en_checkbox = CreateCheckbox(scrollChild, "Chinese to English (Inbound)", 
        CETVars.translationDirection == "cn_to_en", function()
        if this:GetChecked() then
            CETVars.translationDirection = "cn_to_en"
            checkboxes.en_to_cn:SetChecked(false)
        end
    end)
    PositionElement(cn_to_en_checkbox, OPTION_LABEL_LEFT_MARGIN, 5)
    checkboxes.cn_to_en = cn_to_en_checkbox
    
    local en_to_cn_checkbox = CreateCheckbox(scrollChild, "English to Chinese (Inbound)", 
        CETVars.translationDirection == "en_to_cn", function()
        if this:GetChecked() then
            CETVars.translationDirection = "en_to_cn"
            checkboxes.cn_to_en:SetChecked(false)
        end
    end)
    PositionElement(en_to_cn_checkbox, OPTION_LABEL_LEFT_MARGIN, 5)
    checkboxes.en_to_cn = en_to_cn_checkbox
    
    -- API Key Section
    optionYOffset = optionYOffset - SECTION_SPACING
    local apiHeader = CreateSectionHeader(scrollChild, "Google Translate API")
    
    local apiLabel = CreateLabel(scrollChild, "API Key:")
    PositionElement(apiLabel, OPTION_LABEL_LEFT_MARGIN, 5)
    
    apiKeyEditBox = CreateEditBox(scrollChild, 400, 20, CETVars.apiKey)
    PositionElement(apiKeyEditBox, OPTION_LABEL_LEFT_MARGIN, 5)
    
    -- Debug Mode Section
    optionYOffset = optionYOffset - SECTION_SPACING
    local debugHeader = CreateSectionHeader(scrollChild, "Debug Settings")
    
    local debugCheckbox = CreateCheckbox(scrollChild, "Enable Debug Mode", CETVars.debugMode, function()
        CETVars.debugMode = (this:GetChecked() == 1)
        -- Don't auto-save, let the Save button handle it
    end)
    PositionElement(debugCheckbox, OPTION_LABEL_LEFT_MARGIN, 5)
    checkboxes.DEBUG = debugCheckbox
    
    -- Update scroll child height
    optionYOffset = optionYOffset - 30
    scrollChild:SetHeight(620)
end

-- Refresh UI with current values
local function RefreshUI()
    -- Update checkboxes
    for channel, checkbox in pairs(checkboxes) do
        if channel == "DEBUG" then
            checkbox:SetChecked(CETVars.debugMode)
        elseif channel == "cn_to_en" then
            checkbox:SetChecked(CETVars.translationDirection == "cn_to_en")
        elseif channel == "en_to_cn" then
            checkbox:SetChecked(CETVars.translationDirection == "en_to_cn")
        else
            local enabled = CETVars.channelSettings[channel] or false
            checkbox:SetChecked(enabled)
        end
    end
    
    -- Update API key
    if apiKeyEditBox then
        apiKeyEditBox:SetText(CETVars.apiKey or "")
    end
end

-- Frame event handlers
function CETUI_OnLoad()
    mainFrame = CETFrame
    scrollChild = CETFrameScrollFrameScrollChild
    
    -- Set up the frame
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:RegisterForDrag("LeftButton")
    
    -- Set title
    CETFrameTitle:SetText("CET Settings")
    
    -- Set up buttons
    CETFrameSaveButton:SetText("Save")
    CETFrameSaveButton:SetScript("OnClick", function()
        -- Save API key changes
        if apiKeyEditBox then
            CETVars.apiKey = apiKeyEditBox:GetText()
        end
        
        -- Save all settings
        CETVars.SaveVariables()
        
        -- Reinitialize translator if needed
        if CETVars.apiKey and CETVars.apiKey ~= "" then
            CET.InitializeTranslator()
        end
        
        -- Re-register events
        CET.RegisterChatEvents()
        
        CET.Print("Settings saved")
        mainFrame:Hide()
    end)
    
    CETFrameResetButton:SetText("Reset")
    CETFrameResetButton:SetScript("OnClick", function()
        CETVars.ResetToDefaults()
        RefreshUI()
        CET.Print("Settings reset to defaults")
    end)
    
    CETFrameCancelButton:SetText("Cancel")
    CETFrameCancelButton:SetScript("OnClick", function()
        mainFrame:Hide()
    end)
    
    -- Create the settings UI
    CreateSettingsUI()
end

function CETUI_OnShow()
    RefreshUI()
end

function CETUI_OnHide()
    -- Settings are only saved when the Save button is clicked
end

-- Public API
function CETUI.ToggleMainFrame()
    if mainFrame then
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    else
        CET.Print("|cFFFF0000Error:|r CET UI not loaded. Try /reload to restart addon.")
    end
end

-- Slash command for UI
SLASH_CETUI1 = "/cetui"
SlashCmdList["CETUI"] = function(msg)
    CETUI.ToggleMainFrame()
end
