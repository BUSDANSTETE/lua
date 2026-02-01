--========================================================--
-- PHAZE STYLE MOD MENU
-- DEL to OPEN/CLOSE
--========================================================--

local UI = {}

------------------------------------------------------------
-- CONFIG (PHAZE THEME)
------------------------------------------------------------
UI.cfg = {
    x = 0.76,
    y = 0.12,
    w = 0.22,
    headerH = 0.045,
    tabH = 0.032,
    itemH = 0.032,
    space = 0.002,
    max = 12,
    footerH = 0.025,
    
    colors = {
        headerBg = {25, 35, 55, 255},
        menuBg = {15, 20, 30, 245},
        itemBg = {22, 28, 38, 255},
        itemSelected = {0, 100, 200, 255},
        tabActive = {0, 120, 215, 255},
        tabInactive = {60, 70, 90, 255},
        accent = {0, 150, 255, 255},
        textWhite = {255, 255, 255, 255},
        textGray = {150, 155, 165, 255},
        textMuted = {80, 85, 95, 255},
        separator = {60, 70, 90, 180},
        toggleOn = {0, 180, 100, 255},
        toggleOff = {80, 85, 95, 255},
        footer = {18, 23, 33, 255}
    }
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------
UI.state = {
    open = false, 
    tab = 1, 
    sel = 1, 
    scroll = 0,
    tabs = {"Main", "Party", "Chaos", "Powers", "World", "Vehicle", "Ped", "Extra"}
}

------------------------------------------------------------
-- MENU ITEMS
------------------------------------------------------------
local Menu = {
    Main = {"Cargoplane", "Tugboat", "Rumpo2", "Cerberus", "Dump", "Random Ped Spawn", "Ultra Fast Ped Spawn", "Mega Ped Spawn"},
    Party = {"Random Explosions", "Firework Loop", "Vehicle Rain", "Mass Ped Knockup", "Ear-Rape Sound", "Sticky Bomb Rain"},
    Chaos = {"Meteor Shower", "HELL MODE", "Lightning Storm", "Force Field"},
    Powers = {"Infinite Stamina", "Super Jump", "Fast Run", "No Ragdoll", "God Mode", "Invisible Player"},
    World = {"Freeze Time", "Slow Motion", "Clear Weather", "Storm Weather", "Low Gravity", "Earthquake"},
    Vehicle = {"Vehicle God Mode", "Vehicle Boost", "Vehicle Fly", "Explode All Vehicles", "Random Vehicle Morph"},
    Ped = {"Clone Me", "Clone Army", "Freeze Peds", "Launch Peds", "Ragdoll Loop"},
    Extra = {"Pull All Peds", "Pull All Vehicles", "Pull All Props", "Pull All Animals", "Explosion Loop", "Random Teleport", "Chaos Physics", "Flying Cars", "Random Vehicle Spawn"}
}

------------------------------------------------------------
-- FLAGS / TOGGLES
------------------------------------------------------------
local Chaos = {meteors=false, hell=false, lightning=false, forcefield=false}
local Powers = {stamina=false, superjump=false, fastrun=false, noragdoll=false, god=false, invis=false}
local World = {freeze=false, slowmo=false, lowgrav=false}
local PedCtrl = {freeze=false, launch=false, ragdoll=false}
local VehicleFlags = {god=false, boost=false, fly=false}

------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------
local function RequestModelLoad(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local i = 0
    while not HasModelLoaded(model) and i<50 do Wait(50) i=i+1 end
    return HasModelLoaded(model)
end

local function SpawnVehicle(model)
    local p = PlayerPedId()
    local c = GetEntityCoords(p)
    if RequestModelLoad(model) then
        local veh = CreateVehicle(model,c.x,c.y,c.z+1.0,GetEntityHeading(p),true,false)
        SetVehicleOnGroundProperly(veh)
        SetEntityAsMissionEntity(veh,true,true)
        return veh
    end
end

local function SpawnPed(model,x,y,z)
    if RequestModelLoad(model) then
        local ped = CreatePed(4,model,x,y,z,0,true,true)
        return ped
    end
end

local function PromptNumber(prompt,maxVal)
    DisplayOnscreenKeyboard(1,"FMMC_KEY_TIP1", "", "", "", "", "", maxVal)
    while UpdateOnscreenKeyboard() == 0 do Wait(0) end
    if GetOnscreenKeyboardResult() then
        local val = tonumber(GetOnscreenKeyboardResult())
        if val then return val end
    end
    return 1
end

------------------------------------------------------------
-- FORCE FIELD FUNCTION
------------------------------------------------------------
local function ApplyForceField(radius)
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)

    local h,e = FindFirstPed() local ok
    repeat
        if DoesEntityExist(e) and e~=p then
            local pos = GetEntityCoords(e)
            if #(pc-pos)<radius then
                ApplyForceToEntity(e,1,pc.x-pos.x,pc.y-pos.y,pc.z-pos.z,0,0,0,true,true,true,true,false)
            end
        end
        ok,e = FindNextPed(h)
    until not ok
    EndFindPed(h)

    local h,e = FindFirstVehicle() local ok
    repeat
        if DoesEntityExist(e) then
            local pos = GetEntityCoords(e)
            if #(pc-pos)<radius then
                ApplyForceToEntity(e,1,pc.x-pos.x,pc.y-pos.y,pc.z-pos.z,0,0,0,true,true,true,true,false)
            end
        end
        ok,e = FindNextVehicle(h)
    until not ok
    EndFindVehicle(h)
end

------------------------------------------------------------
-- PHAZE STYLE DRAWING HELPERS
------------------------------------------------------------
local function DrawRectC(x, y, w, h, color)
    DrawRect(x, y, w, h, color[1], color[2], color[3], color[4])
end

local function DrawTextPhaze(text, x, y, scale, color, font, align)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(color[1], color[2], color[3], color[4])
    if align == "center" then
        SetTextCentre(true)
    elseif align == "right" then
        SetTextRightJustify(true)
        SetTextWrap(0, x)
    end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function IsToggleItem(itemName)
    local toggles = {
        "Meteor Shower", "HELL MODE", "Lightning Storm", "Force Field",
        "Infinite Stamina", "Super Jump", "Fast Run", "No Ragdoll", "God Mode", "Invisible Player",
        "Freeze Time", "Slow Motion", "Low Gravity",
        "Vehicle God Mode", "Vehicle Boost", "Vehicle Fly",
        "Freeze Peds", "Launch Peds", "Ragdoll Loop"
    }
    for _, t in ipairs(toggles) do
        if t == itemName then return true end
    end
    return false
end

local function GetToggleState(itemName)
    if itemName == "Meteor Shower" then return Chaos.meteors
    elseif itemName == "Force Field" then return Chaos.forcefield
    elseif itemName == "HELL MODE" then return Chaos.hell
    elseif itemName == "Lightning Storm" then return Chaos.lightning
    elseif itemName == "Super Jump" then return Powers.superjump
    elseif itemName == "God Mode" then return Powers.god
    elseif itemName == "Invisible Player" then return Powers.invis
    elseif itemName == "Infinite Stamina" then return Powers.stamina
    elseif itemName == "Fast Run" then return Powers.fastrun
    elseif itemName == "No Ragdoll" then return Powers.noragdoll
    elseif itemName == "Freeze Time" then return World.freeze
    elseif itemName == "Slow Motion" then return World.slowmo
    elseif itemName == "Low Gravity" then return World.lowgrav
    elseif itemName == "Vehicle God Mode" then return VehicleFlags.god
    elseif itemName == "Vehicle Boost" then return VehicleFlags.boost
    elseif itemName == "Vehicle Fly" then return VehicleFlags.fly
    elseif itemName == "Freeze Peds" then return PedCtrl.freeze
    elseif itemName == "Launch Peds" then return PedCtrl.launch
    elseif itemName == "Ragdoll Loop" then return PedCtrl.ragdoll
    end
    return false
end

------------------------------------------------------------
-- DRAW MENU (PHAZE STYLE)
------------------------------------------------------------
local function DrawMenu()
    local cfg, st = UI.cfg, UI.state
    local col = cfg.colors
    local tab = st.tabs[st.tab]
    local items = Menu[tab]
    
    local baseX = cfg.x
    local baseY = cfg.y
    local menuW = cfg.w
    
    local visibleItems = math.min(#items, cfg.max)
    local contentH = visibleItems * (cfg.itemH + cfg.space)
    
    -- HEADER
    DrawRectC(baseX + menuW/2, baseY + cfg.headerH/2, menuW, cfg.headerH, col.headerBg)
    DrawRectC(baseX + 0.015, baseY + cfg.headerH/2, 0.008, 0.008, col.accent)
    DrawTextPhaze("PHAZE", baseX + 0.032, baseY + 0.01, 0.45, col.textWhite, 4, "left")
    DrawTextPhaze(tab, baseX + menuW - 0.01, baseY + 0.012, 0.32, col.textGray, 4, "right")
    
    -- TAB BAR
    local tabY = baseY + cfg.headerH
    DrawRectC(baseX + menuW/2, tabY + cfg.tabH/2, menuW, cfg.tabH, col.menuBg)
    
    local tabsToShow = 5
    local startTab = math.max(1, st.tab - 2)
    local endTab = math.min(#st.tabs, startTab + tabsToShow - 1)
    if endTab - startTab < tabsToShow - 1 then
        startTab = math.max(1, endTab - tabsToShow + 1)
    end
    
    local tabWidth = menuW / tabsToShow
    local tabIdx = 0
    for i = startTab, endTab do
        local tX = baseX + (tabIdx * tabWidth) + tabWidth/2
        local isActive = (i == st.tab)
        local tabColor = isActive and col.textWhite or col.tabInactive
        DrawTextPhaze(st.tabs[i], tX, tabY + 0.006, 0.28, tabColor, 4, "center")
        if isActive then
            DrawRectC(tX, tabY + cfg.tabH - 0.003, tabWidth * 0.7, 0.004, col.tabActive)
        end
        tabIdx = tabIdx + 1
    end
    
    if startTab > 1 then
        DrawTextPhaze("<", baseX + 0.008, tabY + 0.006, 0.28, col.accent, 4, "left")
    end
    if endTab < #st.tabs then
        DrawTextPhaze(">", baseX + menuW - 0.008, tabY + 0.006, 0.28, col.accent, 4, "right")
    end
    
    -- CONTENT AREA
    local contentY = tabY + cfg.tabH
    DrawRectC(baseX + menuW/2, contentY + contentH/2 + 0.005, menuW, contentH + 0.01, col.menuBg)
    
    local startIdx = st.scroll + 1
    local endIdx = math.min(#items, startIdx + cfg.max - 1)
    local itemY = contentY + 0.008
    
    for i = startIdx, endIdx do
        local isSelected = (i == st.sel)
        local itemName = items[i]
        local bgColor = isSelected and col.itemSelected or col.itemBg
        DrawRectC(baseX + menuW/2, itemY + cfg.itemH/2, menuW - 0.008, cfg.itemH, bgColor)
        
        local textColor = isSelected and col.textWhite or col.textGray
        DrawTextPhaze(itemName, baseX + 0.012, itemY + 0.006, 0.30, textColor, 4, "left")
        
        if IsToggleItem(itemName) then
            local toggleState = GetToggleState(itemName)
            local toggleColor = toggleState and col.toggleOn or col.toggleOff
            DrawRectC(baseX + menuW - 0.025, itemY + cfg.itemH/2, 0.025, cfg.itemH * 0.6, toggleColor)
            DrawTextPhaze(toggleState and "ON" or "OFF", baseX + menuW - 0.025, itemY + 0.006, 0.25, col.textWhite, 4, "center")
        else
            DrawTextPhaze(">", baseX + menuW - 0.015, itemY + 0.006, 0.30, isSelected and col.textWhite or col.textMuted, 4, "right")
        end
        
        itemY = itemY + cfg.itemH + cfg.space
    end
    
    -- SCROLLBAR
    if #items > cfg.max then
        local scrollBarH = contentH - 0.01
        local scrollBarX = baseX + menuW - 0.004
        local scrollBarY = contentY + 0.008
        DrawRectC(scrollBarX, scrollBarY + scrollBarH/2, 0.003, scrollBarH, col.itemBg)
        local thumbH = scrollBarH * (cfg.max / #items)
        local thumbOffset = (scrollBarH - thumbH) * (st.scroll / (#items - cfg.max))
        DrawRectC(scrollBarX, scrollBarY + thumbOffset + thumbH/2, 0.003, thumbH, col.accent)
    end
    
    -- FOOTER
    local footerY = contentY + contentH + 0.01
    DrawRectC(baseX + menuW/2, footerY + cfg.footerH/2, menuW, cfg.footerH, col.footer)
    DrawTextPhaze(string.format("%d/%d", st.sel, #items), baseX + menuW - 0.01, footerY + 0.004, 0.25, col.textMuted, 4, "right")
    DrawTextPhaze("DEL Toggle | Arrows Nav", baseX + 0.008, footerY + 0.004, 0.22, col.textMuted, 4, "left")
end

------------------------------------------------------------
-- MENU INPUT
------------------------------------------------------------
local function HandleMenuInput()
    local st = UI.state
    local items = Menu[st.tabs[st.tab]]
    if not UI.state.open then return end

    if IsControlJustPressed(0, 172) then 
        st.sel = st.sel > 1 and st.sel - 1 or #items 
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    if IsControlJustPressed(0, 173) then 
        st.sel = st.sel < #items and st.sel + 1 or 1 
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    
    if st.sel > st.scroll + UI.cfg.max then st.scroll = st.sel - UI.cfg.max
    elseif st.sel <= st.scroll then st.scroll = st.sel - 1 end

    if IsControlJustPressed(0, 174) then 
        st.tab = st.tab > 1 and st.tab - 1 or #st.tabs 
        st.sel = 1 
        st.scroll = 0 
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    if IsControlJustPressed(0, 175) then 
        st.tab = st.tab < #st.tabs and st.tab + 1 or 1 
        st.sel = 1 
        st.scroll = 0 
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    if IsControlJustPressed(0, 191) then
        local it = items[st.sel]
        local p = PlayerPedId()
        local c = GetEntityCoords(p)
        
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

        -- Vehicle spawns
        local vehicles = {Cargoplane=`cargoplane`, Tugboat=`tug`, Rumpo2=`rumpo2`, Cerberus=`cerberus`, Dump=`dump`}
        if vehicles[it] then SpawnVehicle(vehicles[it]) end

        -- Ped Control
        if it == "Clone Me" then
            local ped = SpawnPed(`a_m_m_skater_01`, c.x+1, c.y+1, c.z)
            if ped then SetPedAsGroupMember(ped, GetPedGroupIndex(p)) end
        elseif it == "Clone Army" then
            local amt = PromptNumber("Number of clones:", 50)
            for i = 1, amt do SpawnPed(`a_m_m_skater_01`, c.x+math.random(-5,5), c.y+math.random(-5,5), c.z) end
        end

        -- Chaos Toggles
        if it == "Meteor Shower" then Chaos.meteors = not Chaos.meteors end
        if it == "HELL MODE" then Chaos.hell = not Chaos.hell end
        if it == "Lightning Storm" then Chaos.lightning = not Chaos.lightning end
        if it == "Force Field" then Chaos.forcefield = not Chaos.forcefield end
        
        -- Powers Toggles
        if it == "Super Jump" then Powers.superjump = not Powers.superjump end
        if it == "God Mode" then Powers.god = not Powers.god end
        if it == "Invisible Player" then Powers.invis = not Powers.invis end
        if it == "Fast Run" then Powers.fastrun = not Powers.fastrun end
        if it == "No Ragdoll" then Powers.noragdoll = not Powers.noragdoll end
        if it == "Infinite Stamina" then Powers.stamina = not Powers.stamina end
        
        -- World Toggles
        if it == "Freeze Time" then World.freeze = not World.freeze end
        if it == "Slow Motion" then World.slowmo = not World.slowmo end
        if it == "Low Gravity" then World.lowgrav = not World.lowgrav end
        
        -- Vehicle Toggles
        if it == "Vehicle God Mode" then VehicleFlags.god = not VehicleFlags.god end
        if it == "Vehicle Boost" then VehicleFlags.boost = not VehicleFlags.boost end
        if it == "Vehicle Fly" then VehicleFlags.fly = not VehicleFlags.fly end
        
        -- Ped Toggles
        if it == "Freeze Peds" then PedCtrl.freeze = not PedCtrl.freeze end
        if it == "Launch Peds" then PedCtrl.launch = not PedCtrl.launch end
        if it == "Ragdoll Loop" then PedCtrl.ragdoll = not PedCtrl.ragdoll end
    end
    
    if IsControlJustPressed(0, 177) then
        UI.state.open = false
        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 178) then 
            UI.state.open = not UI.state.open 
            PlaySoundFrontend(-1, UI.state.open and "SELECT" or "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        end
        if UI.state.open then
            DrawMenu()
            HandleMenuInput()
        end
    end
end)

------------------------------------------------------------
-- EFFECTS LOOP
------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        local p = PlayerPedId()
        local c = GetEntityCoords(p)

        -- Chaos
        if Chaos.forcefield then ApplyForceField(50.0) end
        if Chaos.meteors then
            AddExplosion(c.x+math.random(-40,40), c.y+math.random(-40,40), c.z+math.random(25,45), 29, 10.0, true, false, 2.0)
            Wait(150)
        end
        if Chaos.hell then
            AddExplosion(c.x+math.random(-20,20), c.y+math.random(-20,20), c.z, 2, 5.0, true, false, 1.0)
            Wait(50)
        end
        if Chaos.lightning then
            local lx, ly = c.x+math.random(-50,50), c.y+math.random(-50,50)
            AddExplosion(lx, ly, c.z+50, 28, 5.0, true, false, 1.0)
            Wait(500)
        end

        -- Powers
        if Powers.stamina then RestorePlayerStamina(PlayerId(), 1.0) end
        SetPedCanRagdoll(p, not Powers.noragdoll)
        SetEntityVisible(p, not Powers.invis, false)
        SetRunSprintMultiplierForPlayer(PlayerId(), Powers.fastrun and 1.49 or 1.0)
        if Powers.superjump then SetSuperJumpThisFrame(PlayerId()) end
        SetEntityInvincible(p, Powers.god)

        -- World
        if World.freeze then NetworkOverrideClockTime(12, 0, 0) end
        SetTimeScale(World.slowmo and 0.3 or 1.0)
        SetGravityLevel(World.lowgrav and 1 or 0)
        
        -- Vehicle
        local veh = GetVehiclePedIsIn(p, false)
        if veh ~= 0 then
            SetEntityInvincible(veh, VehicleFlags.god)
            if VehicleFlags.boost and IsControlPressed(0, 21) then
                SetVehicleForwardSpeed(veh, 50.0)
            end
            if VehicleFlags.fly then
                local rot = GetEntityRotation(veh)
                if IsControlPressed(0, 32) then SetEntityVelocity(veh, 0.0, 0.0, 15.0) end
                if IsControlPressed(0, 33) then SetEntityVelocity(veh, 0.0, 0.0, -15.0) end
            end
        end
        
        -- Ped Control
        if PedCtrl.freeze or PedCtrl.launch or PedCtrl.ragdoll then
            local h, e = FindFirstPed()
            local ok
            repeat
                if DoesEntityExist(e) and e ~= p then
                    if PedCtrl.freeze then FreezeEntityPosition(e, true) end
                    if PedCtrl.launch then ApplyForceToEntity(e, 1, 0, 0, 20.0, 0, 0, 0, true, true, true, true, false) end
                    if PedCtrl.ragdoll then SetPedToRagdoll(e, 1000, 1000, 0, false, false, false) end
                end
                ok, e = FindNextPed(h)
            until not ok
            EndFindPed(h)
            if PedCtrl.launch or PedCtrl.ragdoll then Wait(500) end
        end
    end
end)
