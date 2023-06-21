local function CreateBetterVendorBuyPopUp()
    -- Create the frame
    local frame = CreateFrame("Frame", "BetterVendorBuyPopUp", UIParent, "BackdropTemplate")
    frame:SetSize(250, 105)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    frame:SetBackdropColor(0, 0, 0, 1)

    -- Create the item icon texture
    local iconTexture = frame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(40, 40)
    iconTexture:SetPoint("TOPLEFT", 10, -10)
    -- Set the item icon texture using an item's texture path
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    iconTexture:EnableMouse(true)

    -- Create the item name fontstring
    local itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemName:SetPoint("TOPLEFT", iconTexture, "TOPRIGHT", 10, 0)
    itemName:SetText("Item Name")

    -- Create the max stack size fontstring
    local maxStackSize = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maxStackSize:SetPoint("TOPLEFT", itemName, "BOTTOMLEFT", 0, -6)
    maxStackSize:SetText("Max Stack: 20")

    -- Create the input field
    local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    input:SetSize(120, 20)
    input:SetPoint("TOPLEFT", maxStackSize, "BOTTOMLEFT", 6, -6)
    input:SetNumeric(true) -- Allow only numeric input

    -- Create the accept button
    local acceptButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    acceptButton:SetSize(80, 22)
    acceptButton:SetPoint("TOPLEFT", input, "BOTTOMLEFT", -7, -6)
    acceptButton:SetText("Okay")

    -- Create the cancel button
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 22)
    cancelButton:SetPoint("BOTTOMLEFT", acceptButton, "BOTTOMRIGHT", 10, 0)
    cancelButton:SetText("Cancel")

    local currentItemId = nil
    iconTexture:SetScript("OnEnter", function(self)
        if currentItemId ~= nil then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetItemByID(currentItemId)
        end
    end)
    iconTexture:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local function HideAndClear()
        AcceptHandler = nil
        frame:Hide()
    end

    local function Cancel()
        HideAndClear()
    end

    local AcceptHandler = nil

    local function OnAccept(handler)
        AcceptHandler = handler
    end

    local function Accept()
        local amount = tonumber(input:GetText())
        AcceptHandler(amount)
        HideAndClear()
    end

    local function Activate(name, texture, stackSize, ID)
        itemName:SetText(name)
        iconTexture:SetTexture(texture)
        maxStackSize:SetText(string.format("Max Stack: %d", stackSize))
        currentItemId = ID

        frame:Show()
    end

    HideAndClear()
    cancelButton:SetScript("OnClick", Cancel)
    acceptButton:SetScript("OnClick", Accept)
    input:SetScript("OnEscapePressed", Cancel)
    input:SetScript("OnEnterPressed", Accept)

    return {
        frame = frame,
        Activate = Activate,
        Cancel = Cancel,
        OnAccept = OnAccept
    }
end

local function CreateBetterVendorProgressBar()
    -- Create the frame
    local frame = CreateFrame("Frame", "MyProgressBarFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 30)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:Hide()

    -- Create the progress bar texture
    local progressBar = frame:CreateTexture(nil, "ARTWORK")
    progressBar:SetSize(193, 24)
    progressBar:SetPoint("LEFT", frame, "LEFT", 4, 0)
    progressBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetVertexColor(0.6, 0.6, 0.6) -- Green color
    progressBar:SetTexCoord(0, 1, 0.25, 0.75) -- Crop the texture to show progress
    progressBar:SetWidth(0.1) -- Start with a width of 0

    -- Create the progress text
    local progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER", frame)
    progressText:SetText("")

    -- Variables
    local value = 1
    local total = 100

    -- Update the progress bar
    local function UpdateProgressBar()
        progressBar:SetWidth(193 / total * max(value, 0.0001)) -- Adjust the width of the progress bar
        progressText:SetText(format("%.0f / %.0f", value, total)) -- Display the remaining time
    end

    -- Start the progress bar
    local function StartProgressBar(maxValue)
        total = maxValue
        value = 0

        frame:SetScript("OnUpdate", UpdateProgressBar)
        UpdateProgressBar()
        frame:Show()
    end

    -- Stop the progress bar
    local function StopProgressBar()
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
        progressBar:SetWidth(0.1) -- Set the progress bar width to 0 to hide it
        progressText:SetText("")
    end

    local function Advance(step)
        if step == nil then
            value = value + 1
        else
            value = value + step
        end
    end

    return {
        Frame = frame,
        Start = StartProgressBar,
        Stop = StopProgressBar,
        Advance = Advance
    }
end

local instance = CreateBetterVendorBuyPopUp()
local progressBar = CreateBetterVendorProgressBar()

local function BetterVendorMerchantItemButton_OnClick(self, button)
    if IsAltKeyDown() then
        local ID = self:GetID()
        local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost = GetMerchantItemInfo(
            ID)
        local stackSize = GetMerchantItemMaxStack(ID)
        local itemId = GetMerchantItemID(ID)

        if not isPurchasable or numAvailable == nil then
            return
        end

        instance.Activate(name, texture, stackSize, itemId)

        instance.OnAccept(function(amount)
            if amount > 0 then
                local maxStackSize = min(stackSize, 200)
                local ticks = ceil(amount / maxStackSize)
                local duration = 0.33
                local tickerInstance

                progressBar.Start(amount)

                tickerInstance = C_Timer.NewTicker(duration, function()
                    if not MerchantFrame:IsVisible() then
                        if tickerInstance then
                            tickerInstance:Cancel()
                            C_Timer.After(0.1, progressBar.Stop)
                        end

                        return
                    end
                    if amount > maxStackSize then
                        BuyMerchantItem(ID, maxStackSize)
                        progressBar.Advance(maxStackSize)
                        amount = amount - maxStackSize
                    elseif amount > 0 then
                        BuyMerchantItem(ID, amount)
                        progressBar.Advance(amount)
                        amount = 0

                        C_Timer.After(0.1, progressBar.Stop)
                    end
                end, ticks)
            end
        end)
    elseif IsShiftKeyDown() then
        -- Shift + Click on vendor item
        -- Perform your custom action here
        -- print("Shift + Click on vendor item")
    end
end

local function RegisterBetterVendorMerchantItemClickHandlers()
    local i = 1

    while _G["MerchantItem" .. i .. "ItemButton"] ~= nil do
        local button = _G["MerchantItem" .. i .. "ItemButton"]
        button:HookScript("OnClick", BetterVendorMerchantItemButton_OnClick)
        i = i + 1
    end

    print(string.format("BetterVendor: Registered %d Merchant Item", i - 1))
end

RegisterBetterVendorMerchantItemClickHandlers()
