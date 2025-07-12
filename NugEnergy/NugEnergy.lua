NugEnergy = CreateFrame("Frame", "NugEnergy")
media = LibStub("LibSharedMedia-3.0")

NugEnergy:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

NugEnergy:RegisterEvent("ADDON_LOADED")
function NugEnergy.ADDON_LOADED(_, _, addonName)
    if addonName ~= "NugEnergy" then
        return
    end

    NugEnergyDB = NugEnergyDB or {}
    NugEnergyDB.posX = NugEnergyDB.posX or 0
    NugEnergyDB.posY = NugEnergyDB.posY or 0
    NugEnergyDB.align = NugEnergyDB.align or "CENTER"
    NugEnergyDB.visibility = NugEnergyDB.visibility or "Always"
    NugEnergyDB.font = NugEnergyDB.font or "Emblem"
    NugEnergyDB.fontSize = NugEnergyDB.fontSize or 35
    NugEnergyDB.energyColor = NugEnergyDB.energyColor or {1, 0.5, 0.1}
    NugEnergyDB.rageColor = NugEnergyDB.rageColor or {1, 0.2, 0.2}

    NugEnergyDB.ticker = NugEnergyDB.ticker or {}
    NugEnergyDB.ticker.color = NugEnergyDB.ticker.color or {1, 0.8, 0.1}
    NugEnergyDB.ticker.alphaBG = NugEnergyDB.ticker.alphaBG or 0.5
    NugEnergyDB.ticker.offsetX = NugEnergyDB.ticker.offsetX or 0
    NugEnergyDB.ticker.offsetY = NugEnergyDB.ticker.offsetY or -20
    NugEnergyDB.ticker.width = NugEnergyDB.ticker.width or 60
    NugEnergyDB.ticker.height = NugEnergyDB.ticker.height or 10
    NugEnergyDB.ticker.texture = NugEnergyDB.ticker.texture or "Aluminium"

    _, NugEnergy.class = UnitClass("player")

    if NugEnergy.class == "ROGUE" then
        NugEnergy.color = NugEnergyDB.energyColor
        NugEnergy.frame, NugEnergy.text = NugEnergy.CreateFrame(60, 50, "NugEnergyFrame")
        NugEnergy.ticker = NugEnergy.CreateTickerFrame("NugEnergyTicker")
        NugEnergy:RegisterEvent("UNIT_ENERGY")

    elseif NugEnergy.class == "WARRIOR" then
        NugEnergy.color = NugEnergyDB.rageColor
        NugEnergy.frame, NugEnergy.text = NugEnergy.CreateFrame(60, 50, "NugEnergyFrame")
        NugEnergy:RegisterEvent("UNIT_RAGE")
        NugEnergy.UNIT_RAGE = NugEnergy.UNIT_ENERGY

    elseif NugEnergy.class == "DRUID" then
        NugEnergy.color = NugEnergyDB.energyColor
        NugEnergy.frame, NugEnergy.text = NugEnergy.CreateFrame(60, 50, "NugEnergyFrame")
        NugEnergy.ticker = NugEnergy.CreateTickerFrame("NugEnergyTicker")
        NugEnergy.UNIT_RAGE = NugEnergy.UNIT_ENERGY

    else
        return
    end

    NugEnergy.UpdateBehavior(NugEnergyDB.visibility)
    NugEnergy:RegisterEvent("PLAYER_ENTERING_WORLD")
    NugEnergy.PLAYER_ENTERING_WORLD = NugEnergy.UNIT_ENERGY
    NugEnergy.MakeOptions()
end

function NugEnergy.UNIT_ENERGY()
    NugEnergy.text:SetText(UnitMana("player"))
    local newEnergy = UnitMana("player")

    if newEnergy > NugEnergy.currentEnergy then
        if newEnergy >= NugEnergy.currentEnergy + 19 and newEnergy <= NugEnergy.currentEnergy + 21 then
            NugEnergy.lastTime = GetTime()
        end
    end

    NugEnergy.currentEnergy = UnitMana("player")
end

function NugEnergy.UpdateBehavior(state)
    if NugEnergy.class == "WARRIOR" and state == "Stealth" then
        state = "Combat"
    end

    if NugEnergy.class == "DRUID" then
        if state == "Combat" then
            state = "Stealth"

        elseif state == "Always" then
            NugEnergy:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
            NugEnergy.UPDATE_SHAPESHIFT_FORM()
            return
        end
    end

    if state == "Stealth" then
        NugEnergy:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        NugEnergy:RegisterEvent("PLAYER_REGEN_ENABLED")
        NugEnergy:RegisterEvent("PLAYER_REGEN_DISABLED")

    elseif state == "Combat" then
        NugEnergy:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        NugEnergy:RegisterEvent("PLAYER_REGEN_ENABLED")
        NugEnergy:RegisterEvent("PLAYER_REGEN_DISABLED")

    elseif state == "Always" then
        NugEnergy:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        NugEnergy:UnregisterEvent("PLAYER_REGEN_ENABLED")
        NugEnergy:UnregisterEvent("PLAYER_REGEN_DISABLED")
        NugEnergy.frame:Show()
        NugEnergyTicker:Show()
    end
end

function NugEnergy.UpdateHide(state)
    local show = function()
        if NugEnergy.class == "DRUID" then
            local _, _, bear_active, _ = GetShapeshiftFormInfo(1)
            local _, _, cat_active, _ = GetShapeshiftFormInfo(3)

            if bear_active == 1 then
                if not NugEnergy.frame:IsVisible() then
                    NugEnergy.frame:Show()
                    NugEnergyTicker:Hide()
                end

            elseif cat_active == 1 then
                if not NugEnergy.frame:IsVisible() then
                    NugEnergy.frame:Show()
                    NugEnergyTicker:Show()
                end

            else
                NugEnergy.frame:Hide()
                NugEnergyTicker:Hide()
            end

        else
            if not NugEnergy.frame:IsVisible() then
                NugEnergy.frame:Show()

                if NugEnergyTicker then
                    NugEnergyTicker:Show()
                end
            end
        end
    end

    if state == "Stealth" and (NugEnergy.stealth or NugEnergy.combat) then
        show()
        return true

    elseif state == "Combat" and NugEnergy.combat then
        show()
        return true

    elseif state == "Always" then
        show()
        return true

    else
        NugEnergy.frame:Hide()

        if NugEnergyTicker then
            NugEnergyTicker:Hide()
        end
    end
    return nil
end

function NugEnergy.UPDATE_SHAPESHIFT_FORM()
    if NugEnergy.class == "ROGUE" then
        local _, _, active, _ = GetShapeshiftFormInfo(1)

        if active == 1 then
            NugEnergy.stealth = true
        else
            NugEnergy.stealth = false
        end

        NugEnergy.UpdateHide(NugEnergyDB.visibility)

    elseif NugEnergy.class == "DRUID" then
        local _, _, bear_active, _ = GetShapeshiftFormInfo(1)
        local _, _, cat_active, _ = GetShapeshiftFormInfo(2)

        if bear_active == 1 then
            NugEnergy:RegisterEvent("UNIT_RAGE")
            NugEnergy:UnregisterEvent("UNIT_ENERGY")
            NugEnergy:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            NugEnergy.color = NugEnergyDB.rageColor
            NugEnergy.text:SetVertexColor(unpack(NugEnergy.color))
            NugEnergy.UNIT_ENERGY()
            NugEnergy.UpdateHide(NugEnergyDB.visibility)

        elseif cat_active == 1 then
            NugEnergy:UnregisterEvent("UNIT_RAGE")
            NugEnergy:RegisterEvent("UNIT_ENERGY")
            NugEnergy:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            NugEnergy.lastTime = GetTime()
            NugEnergy.currentEnergy = UnitMana("player")
            NugEnergy.color = NugEnergyDB.energyColor
            NugEnergy.text:SetVertexColor(unpack(NugEnergy.color))
            NugEnergy.UNIT_ENERGY()
            NugEnergy.UpdateHide(NugEnergyDB.visibility)

        else
            NugEnergy:UnregisterEvent("UNIT_RAGE")
            NugEnergy:UnregisterEvent("UNIT_ENERGY")
            NugEnergy:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            NugEnergy.UpdateHide(NugEnergyDB.visibility)
        end
    end
end

function NugEnergy.PLAYER_REGEN_ENABLED()
    NugEnergy.combat = false
    NugEnergy.UpdateHide(NugEnergyDB.visibility)
end

function NugEnergy.PLAYER_REGEN_DISABLED()
    NugEnergy.combat = true
    NugEnergy.UpdateHide(NugEnergyDB.visibility)
end

function NugEnergy.COMBAT_LOG_EVENT_UNFILTERED(_, _, _, eventType, _, _, _, _, _, dstFlags, _, spellName, _, auraType)
    local isDestPlayer = (bit.band(dstFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER)

    if not isDestPlayer then
        return
    end

    if auraType == "BUFF" and string.find(spellName, "Prowl") ~= nil then
        if eventType == "SPELL_AURA_APPLIED" then
            NugEnergy.stealth = true
        end

        if  eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_DISPELLED" then
            NugEnergy.stealth = false
        end

        NugEnergy.UpdateHide(NugEnergyDB.visibility)
    end
end

function NugEnergy.MakeOptions(self)
    local alignValues = {
        ["LEFT"] = "Left",
        ["CENTER"] = "Center",
        ["RIGHT"] = "Right",
    }
    local visibilityValues = {
        ["Stealth"] = "Stealth",
        ["Combat"] = "Combat",
        ["Always"] = "Always",
    }

    local fonts,bars = {}, {}

    for _, v in pairs(media:List('font')) do
        fonts[v] = v
    end

    for _, v in pairs(media:List('statusbar')) do
        bars[v] = v
    end

    media.RegisterCallback(NugEnergy, "LibSharedMedia_Registered",
        function(_, mediatype, key)
            if mediatype == "font" then
                fonts[key] = key

                if key == NugEnergyDB.font then
                    NugEnergy.text:SetFont(media:Fetch("font", NugEnergyDB.font), NugEnergyDB.fontSize)
                end

            elseif mediatype == "statusbar" then
                bars[key] = key

                if key == NugEnergyDB.ticker.texture then
                    if NugEnergyTickerBar then 
                        NugEnergyTickerBar:SetTexture(media:Fetch("statusbar", NugEnergyDB.ticker.texture))
                    end
                end
            end
        end)

    local opt = {
		type = "group",
        name = "NugEnergy",
        args = {},
	}

    opt.args.general = {
        type = "group",
        name = "General",
        order = 1,
        args = {
            showPositon = {
                type = "group",
                name = "Frame Position",
                guiInline = true,
                order = 1,
                args = {
                    posX = {
                        name = "Pos X",
                        type = "range",
                        desc = "Horizontal position, relative to center",
                        get = function(info) return NugEnergyDB.posX end,
                        set = function(info, s) NugEnergyDB.posX = s; NugEnergy.frame:SetPoint("CENTER", UIParent, "CENTER", NugEnergyDB.posX, NugEnergyDB.posY); end,
                        min = -900,
                        max = 900,
                        step = 5
                    },
                    posY = {
                        name = "Pos Y",
                        type = "range",
                        desc = "Vertical position, relative to center",
                        get = function(info) return NugEnergyDB.posY end,
                        set = function(info, s) NugEnergyDB.posY = s; NugEnergy.frame:SetPoint("CENTER", UIParent, "CENTER", NugEnergyDB.posX, NugEnergyDB.posY); end,
                        min = -700,
                        max = 700,
                        step = 5
                    }
                }
            },
            showScale = {
                type = "group",
                name = "Scale & Font",
                guiInline = true,
                order = 2,
                args = {
                    align = {
                        type = "select",
                        name = "Align",
                        desc = "Align of text",
                        values = alignValues,
                        get = function()
                            return NugEnergyDB.align
                        end,
                        set = function(_, s)
                            NugEnergyDB.align = s
                            NugEnergy.text:SetJustifyH(NugEnergyDB.align)
                        end
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        desc = "Choose font",
                        values = fonts,
                        order = 1,
                        get = function()
                            return NugEnergyDB.font
                        end,
                        set = function(_, s)
                            NugEnergyDB.font = s
                            NugEnergy.text:SetFont(media:Fetch("font", NugEnergyDB.font),NugEnergyDB.fontSize)
                        end
                    },
                    fontSize = {
                        name = "Font Size",
                        type = "range",
                        order = 2,
                        get = function()
                            return NugEnergyDB.fontSize
                        end,
                        set = function(_, s)
                            NugEnergyDB.fontSize = s
                            NugEnergy.text:SetFont(media:Fetch("font", NugEnergyDB.font),NugEnergyDB.fontSize)
                        end,
                        min = 5,
                        max = 35,
                        step = 1
                    },
                    visibility = {
                        type = "select",
                        name = "Visible when...",
                        desc = "",
                        values = visibilityValues,
                        get = function()
                            return NugEnergyDB.visibility
                        end,
                        set = function(_, s)
                            NugEnergyDB.visibility = s
                            NugEnergy.UpdateBehavior(NugEnergyDB.visibility)
                        end
                    }
                }
            },
            showColors = {
                type = "group",
                name = "Colors",
                guiInline = true,
                order = 3,
                args = {
                    energyColor = {
                        name = "Energy Color",
                        type = "color",
                        desc = "energy color",
                        order = 1,
                        get = function()
                            local r, g, b = unpack(NugEnergyDB.energyColor)
                            return r, g, b
                        end,
                        set = function(_, r, g, b)
                            NugEnergyDB.energyColor = { r, g, b }

                            if NugEnergy.class == "ROGUE" then
                                NugEnergy.text:SetVertexColor(r, g, b)
                            end
                        end
                    },
                    rageColor = {
                        name = "Rage Color",
                        type = "color",
                        desc = "rage color",
                        order = 2,
                        get = function()
                            local r, g, b = unpack(NugEnergyDB.rageColor)
                            return r, g, b
                        end,
                        set = function(_, r, g, b)
                            NugEnergyDB.rageColor = { r, g, b }

                            if NugEnergy.class == "WARRIOR" then
                                NugEnergy.text:SetVertexColor(r, g, b)
                            end
                        end
                    },
                    tickerColor = {
                        name = "Ticker Color",
                        type = "color",
                        desc = "TickBar color",
                        order = 3,
                        get = function()
                            local r, g, b = unpack(NugEnergyDB.ticker.color)
                            return r, g, b
                        end,
                        set = function(_, r, g, b)
                            NugEnergyDB.ticker.color = { r, g, b }

                            if NugEnergy.class == "ROGUE" then
                                NugEnergyTickerBar:SetVertexColor(r, g, b)
                            end
                        end
                    },
                    tickeralphaBG = {
                        name = "Ticker BG alpha",
                        type = "range",
                        desc = "...",
                        order = 4,
                        get = function()
                            return NugEnergyDB.ticker.alphaBG
                        end,
                        set = function(_, s)
                            NugEnergyDB.ticker.alphaBG = s
                            NugEnergyTickerBackground:SetTexture(0, 0, 0, NugEnergyDB.ticker.alphaBG)
                        end,
                        min = 0,
                        max = 1,
                        step = 0.1
                    }
                }
            },
            tickerOpts = {
                type = "group",
                name = "Ticker",
                guiInline = true,
                order = 4,
                args = {
                    offsetX = {
                        name = "Offset X",
                        type = "range",
                        desc = "Horizontal offset, relative to main frame",
                        order = 1,
                        get = function()
                            return NugEnergyDB.ticker.offsetX
                        end,
                        set = function(_, s)
                            NugEnergyDB.ticker.offsetX = s
                            NugEnergyTicker:SetPoint("CENTER", NugEnergy.frame, "CENTER", NugEnergyDB.ticker.offsetX,NugEnergyDB.ticker.offsetY)
                        end,
                        min = -900,
                        max = 900,
                        step = 5
                    },
                    offsetY = {
                        name = "Offset Y",
                        type = "range",
                        desc = "Vertical offset, relative to main frame",
                        order = 2,
                        get = function()
                            return NugEnergyDB.ticker.offsetY
                        end,
                        set = function(_, s)
                            NugEnergyDB.ticker.offsetY = s
                            NugEnergyTicker:SetPoint("CENTER", NugEnergy.frame, "CENTER", NugEnergyDB.ticker.offsetX, NugEnergyDB.ticker.offsetY)
                        end,
                        min = -700,
                        max = 700,
                        step = 5
                    },
                    width = {
                        name = "Width",
                        type = "range",
                        desc = "ppc",
                        order = 3,
                        get = function()
                            return NugEnergyDB.ticker.width
                        end,
                        set = function(_, s)
                            NugEnergyDB.ticker.width = s
                            NugEnergyTicker:SetWidth(NugEnergyDB.ticker.width)
                        end,
                        min = 20,
                        max = 200,
                        step = 2
                    },
                    height = {
                        name = "Height",
                        type = "range",
                        desc = "eh",
                        order = 4,
                        get = function()
                            return NugEnergyDB.ticker.height
                        end,
                        set = function(_, s)
                            NugEnergyDB.ticker.height = s
                            NugEnergyTicker:SetHeight(NugEnergyDB.ticker.height)
                        end,
                        min = 2,
                        max = 100,
                        step = 2
                    },
                    texure = {
                        type = "select",
                        name = "Texture",
                        desc = "Choose ticker texture",
                        values = bars,
                        order = 5,
                        get = function()
                            return NugEnergyDB.ticker.texture
                        end,
                        set = function(_, s)
                            NugEnergyDB.ticker.texture = s
                            NugEnergyTickerBar:SetTexture(media:Fetch("statusbar", NugEnergyDB.ticker.texture))
                        end
                    }
                }
            }
        }
    }

    local Config = LibStub("AceConfigRegistry-3.0")
    local Dialog = LibStub("AceConfigDialog-3.0")

    Config:RegisterOptionsTable("NugEnergy-Bliz", { name = "NugEnergy", type = "group", args = {} })
    Dialog:SetDefaultSize("NugEnergy-Bliz", 600, 400)

    Config:RegisterOptionsTable("NugEnergy-General", opt.args.general)
    Dialog:AddToBlizOptions("NugEnergy-General", "NugEnergy")

    SLASH_NESLASH1 = "/ne";
    SLASH_NESLASH2 = "/nugenergy";
    SlashCmdList["NESLASH"] = function()
        InterfaceOptionsFrame_OpenToFrame("NugEnergy")
    end
end

function NugEnergy.CreateFrame(width, height, frameName)
    local f = CreateFrame("Frame",frameName,UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetWidth(width)
    f:SetHeight(height)
    f:SetPoint("CENTER", UIParent, "CENTER", NugEnergyDB.posX, NugEnergyDB.posY)

    text = f:CreateFontString(nil, "OVERLAY");
    text:SetFont(media:Fetch("font", NugEnergyDB.font), NugEnergyDB.fontSize)
    text:ClearAllPoints()
    text:SetWidth(width)
    text:SetHeight(height)
    text:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    text:SetJustifyH(NugEnergyDB.align)
    text:SetVertexColor(unpack(NugEnergy.color))

    NugEnergy.currentEnergy = 0

    f:Hide()
    return f, text
end


function NugEnergy.CreateTickerFrame(frameName)
    local f = CreateFrame("Frame", frameName, UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetWidth(NugEnergyDB.ticker.width)
    f:SetHeight(NugEnergyDB.ticker.height)
    f:SetPoint("CENTER", NugEnergy.frame, "CENTER", NugEnergyDB.ticker.offsetX, NugEnergyDB.ticker.offsetY)

    local bg = f:CreateTexture(frameName .. "Background", "BACKGROUND")
    bg:SetWidth(NugEnergyDB.ticker.width)
    bg:SetHeight(NugEnergyDB.ticker.height)
    bg:SetTexture(0, 0, 0, NugEnergyDB.ticker.alphaBG)
    bg:SetAllPoints(f)

    local b = f:CreateTexture(frameName .. "Bar", "ARTWORK")
    b:SetWidth(NugEnergyDB.ticker.width)
    b:SetHeight(NugEnergyDB.ticker.height)
    b:SetTexture(media:Fetch("statusbar", NugEnergyDB.ticker.texture))
    b:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    b:SetVertexColor(unpack(NugEnergyDB.ticker.color))

    NugEnergy.lastTime = GetTime()
    NugEnergy.OnUpdate = function ()
        local now = GetTime()

        if now > NugEnergy.lastTime + 2 then
            NugEnergy.lastTime = now
        end

        local width = (GetTime() - NugEnergy.lastTime) * NugEnergyDB.ticker.width / 2

        if width > 0 then
            NugEnergyTickerBar:SetWidth(width)
        end
    end

    f:SetScript("OnUpdate", NugEnergy.OnUpdate)

    f:Hide()
    return f
end
