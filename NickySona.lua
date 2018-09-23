if myHero.charName ~= "Sona" then return end

local player = myHero
local playerPos = myHero.pos

local TEAM_ALLY = player.team
local TEAM_ENEMY = 300 - TEAM_ALLY

local function GetComboOrb() 
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
        return "Combo"
    end 
end 


local function AllysInrange(pos, range) 
	local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isAlly and Hero.pos:DistanceTo(pos, Hero.pos) < range then
            Count = Count + 1
        end
    end
    return Count
end

local function LoadingMenu()
    NickySona = MenuElement({type = MENU, id = "Sona", name = "[Nicky]Sona"})
	--QS
	NickySona:MenuElement({id = "QS", name = "Hymn of Valor (Q) Settings", type = MENU})
    NickySona.QS:MenuElement({id = "CQ", name = "Use [Q] In Combo", value = true})
    --WS
    NickySona:MenuElement({id = "WS", name = "Aria of Perseverance (W) Settings", type = MENU})
    NickySona.WS:MenuElement({id = "CW", name = "Use to Heal Allies", value = true})
    NickySona.WS:MenuElement({id = "allyheat", name = "Cast if ally health is < to %", value = 75, min = 1, max = 100, step = 1})
    --Es
    NickySona:MenuElement({id = "ES", name = "Song of Celerity(E) Settings", type = MENU})
    NickySona.ES:MenuElement({id = "CE", name = "Use [E] in Combo", value = true})
    --Rs
    NickySona:MenuElement({id = "RS", name = "(R) Settings", type = MENU})
    NickySona.RS:MenuElement({id = "CR", name = "Use [R] In Combo", value = true})
    --Draw
    NickySona:MenuElement({id = "DD", name = "Soninha (Draws) Settings", type = MENU})
    NickySona.DD:MenuElement({id = "DQ", name = "Draw [Q]", value = true})
    NickySona.DD:MenuElement({id = "DW", name = "Draw [W]", value = true})
    NickySona.DD:MenuElement({id = "DE", name = "Draw [E]", value = true})
    NickySona.DD:MenuElement({id = "DR", name = "Draw [R]", value = true})
end


local function OnDraw()
    if not player.dead then
        if NickySona.DD.DQ:Value() then 
            Draw.Circle(myHero.pos, 825, 0, Draw.Color(255, 192, 255, 43))
        end
        
        if NickySona.DD.DW:Value()  then 
            Draw.Circle(myHero.pos, 1000, 0, Draw.Color(100, 192, 57, 43))
        end
    
        if NickySona.DD.DE:Value()  then 
            Draw.Circle(myHero.pos, 1500, 0, Draw.Color(100, 192, 57, 43))
        end

        if NickySona.DD.DR:Value()  then 
            Draw.Circle(myHero.pos, 900, 0, Draw.Color(255, 255, 255, 255))
        end
    end 
end 

local function OnLoading()
    LoadingMenu()
end 

local function CastW()
    if Game.CanUseSpell(1) == 0 and NickySona.WS.CW:Value() then
		for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero.isAlly and not hero.isMe then
                if hero and not hero.dead and (hero.health / hero.maxHealth * 100) < NickySona.WS.allyheat:Value() and hero.pos:DistanceTo(playerPos) <= 1000 then
                    Control.CastSpell(HK_W)
                    break
                end
            end
		end
	end
end 

local function CastQ(target)
    if Game.CanUseSpell(0) == 0 then
		if NickySona.QS.CQ:Value() then
			if target.pos:DistanceTo(playerPos) <= 825 then
                Control.CastSpell(HK_Q)
			end
		end
	end
end 

local function CastE(target)
	if Game.CanUseSpell(2) == 0 then
		if NickySona.ES.CE:Value() then
			if target.pos:DistanceTo(playerPos) <= 1500 then
				Control.CastSpell(HK_E)
			end
		end
	end
end 

local function CastR(target)
    if Game.CanUseSpell(3) == 0 then
        if NickySona.RS.CR:Value() then
            if target.pos:DistanceTo(playerPos) <= 900 and #AllysInrange(playerPos, 900) > 0 then
                local Rpred = target:GetPrediction(2000, 0.25)
                Control.CastSpell(HK_R, Rpred)
            end 
        end 
    end		
end 

local function OnTick()
    CastW()

    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(1000)
    if not target then return end 
    if not GetComboOrb() == 'Combo' then return end
    CastQ(target)
    CastE(target)
    CastR(target)
end 

Callback.Add("Tick", function() OnTick() end)
Callback.Add("Load", function() OnLoading() end)
Callback.Add("Draw", function() OnDraw() end)