if myHero.charName ~= "Soraka" then return end

local player = myHero
local playerPos = myHero.pos
local TEAM_ALLY = player.team
local TEAM_ENEMY = 300 - TEAM_ALLY

local function GetComboOrb() 
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
        return "Combo"
    end 
end 

local hard_cc = {
    [5] = true, -- stun
    [8] = true, -- taunt
    [11] = true, -- snare
    [18] = true, -- sleep
    [21] = true, -- fear
    [22] = true, -- charm
    [24] = true, -- suppression
    [28] = true, -- flee
    [29] = true, -- knockup
    [30] = true, -- knockback
}


local spellsToSilence = {
	["Anivia"] = { 3 },
	["Caitlyn"] = { 3 },
	["Darius"] = { 3 },
	["FiddleSticks"] = { 1, 3 },
	["Gragas"] = { 1 },
	["Janna"] = { 3 },
	["Karthus"] = { 3 },
	["Katarina"] = { 3 },
	["Malzahar"] = { 3 },
	["MasterYi"] = { 1 },
	["MissFortune"] = { 3 },
	["Nunu"] = { 3 },
	["Pantheon"] = { 2, 3 },
	["Sion"] = { 0 },
	["TwistedFate"] = { 3 },
	["Varus"] = { 0 },
	["Vi"] = { 0, 3 },
	["Warwick"] = { 3 },
	["Xerath"] = { 0, 3 }
}

local function CanPlayerMove(obj)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if hard_cc[buff.type] then
            return true
        end
    end
    return false
end

local function GetEnemyHeroesInRange(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(pos, Hero.pos) < range then
            Count = Count + 1
        end
    end
    return Count
end

local function LoadingMenu()
    NickySoraka = MenuElement({type = MENU, id = "Soraka", name = "[Nicky]Soraka"})
	--QS
	NickySoraka:MenuElement({id = "QS", name = "(Q) Settings", type = MENU})
    NickySoraka.QS:MenuElement({id = "CQ", name = "Use [Q] In Combo", value = true})
    --WS
    NickySoraka:MenuElement({id = "WS", name = "(W) Settings", type = MENU})
    NickySoraka.WS:MenuElement({id = "CW", name = "Use to Heal Allies", value = true})
    NickySoraka.WS:MenuElement({id = "allyheat", name = "Cast if ally health is < to %", value = 75, min = 1, max = 100, step = 1})
    NickySoraka.WS:MenuElement({id = "mylife", name = "Cast if my health is > to %", value = 20, min = 1, max = 100, step = 1})
    --Es
    NickySoraka:MenuElement({id = "ES", name = "(E) Settings", type = MENU})
    NickySoraka.ES:MenuElement({id = "CE", name = "Use [E] in Combo", value = true})
    NickySoraka.ES:MenuElement({id = "CCj", name = "Use only if target is CC", value = true})
    NickySoraka.ES:MenuElement({id = "inter", name = "Use to Interrupt Spells", value = true})
    --Rs
    NickySoraka:MenuElement({id = "RS", name = "(R) Settings", type = MENU})
    NickySoraka.RS:MenuElement({id = "CR", name = "Use to Save Allies", value = true})
    NickySoraka.RS:MenuElement({id = "AutoR", name = "Cast if ally health is < to %", value = 10, min = 1, max = 100, step = 1})
end

local function AutoSilence(spell)
    if Game.CanUseSpell(2) == 0 and NickySoraka.ES.inter:Value() then
		local champ = spell.activeSpell.owner
		if champ.team == TEAM_ENEMY then
			local slot = spell.activeSpellSlot
			if playerPos:DistanceTo(champ.pos) <= 925 then
				if spell.name == "SummonerTeleport" then
                    Control.CastSpell(HK_E, spell.owner.pos)
				else
					local spells = spellsToSilence[champ.charName]
					if spells then
						for i = 1, #spells do
							if slot == spells[i] then
                                Control.CastSpell(HK_E, spell.owner.pos)
								break
							end
						end
					end
				end
			end
		end
	end
end 

local function CastW()
	if Game.CanUseSpell(1) == 0 then
		if not player.dead and (player.health / player.maxHealth * 100) > NickySoraka.WS.mylife:Value() then
            for i = 1, Game.HeroCount() do
                local unit = Game.Hero(i)
                if unit.isAlly and not unit.isMe then
                    if unit and not unit.dead and unit.pos:DistanceTo(playerPos) < 600 and (unit.health / unit.maxHealth * 100) < NickySoraka.WS.allyheat:Value() then
                        Control.CastSpell(HK_W, unit)
                        break
                    end
                end 
			end
		end
	end
end

local function CastR()
	if Game.CanUseSpell(3) == 0 then
		for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero.isAlly and not hero.isMe then
                if hero and not hero.isDead and (hero.health / hero.maxHealth * 100) < NickySoraka.RS.AutoR:Value() then
                    if #GetEnemyHeroesInRange(hero.pos, 1000) > 0 then
                        Control.CastSpell(HK_R)
                        break
                    end
                end
            end 
		end
	end
end 

local function CastQ(unit)
    if Game.CanUseSpell(0) == 0 then
        if unit.pos:DistanceTo(playerPos) <= 800 then
            local qpred = unit:GetPrediction(2000, 0.25)
            Control.CastSpell(HK_Q, qpred)
        end 
    end 
end

local function CastE(unit)
    if Game.CanUseSpell(2) == 0 then
        if unit.pos:DistanceTo(playerPos) <= 925 then
            if not NickySoraka.ES.CCj:Value() or not CanPlayerMove(unit) then
                Control.CastSpell(HK_E, unit.pos)
            end 
        end 
    end 
end 


local function OnLoading()
    LoadingMenu()
end 

local function OnTick()
    AutoSilence()
    CastW()
    CastR()
    --
    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(1000)
    if not target then return end 
    if not GetComboOrb() == 'Combo' then return end
    CastQ(target)
    CastE(target)
end 


Callback.Add("Tick", function() OnTick() end)
Callback.Add("Load", function() OnLoading() end)
