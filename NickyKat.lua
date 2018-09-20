if myHero.charName ~= "Katarina" then return end

local player = myHero
local playerPos = myHero.pos
local Q = { Range = 625}
local W = { Range = 340 }
local E = { Range = 725 }
local R = { Range = 550}
local DaggerObj = { }
local DaggerCount = 0
local DaggerStart = 0 
local DaggerEnd = 0
local RCasting = false
local Posis = Vector(0,0,0)
local WPos = Vector(0,0,0)
local DaggerPosition = Vector(0,0,0)
local damage = 0
local AD = myHero.totalDamage
local AP = myHero.ap
local bAD = myHero.bonusDamage
local _EnemyHeroes


local function LoadingMenu()
    NicktKat = MenuElement({type = MENU, id = "Katarina", name = "[Nicky]Katarina"})
	--Combo
	NicktKat:MenuElement({id = "Combo", name = "Combo", type = MENU})
	NicktKat.Combo:MenuElement({id = "CQ", name = "Use [Q]", value = true})
	NicktKat.Combo:MenuElement({id = "CW", name = "Use [W]", value = true})
    NicktKat.Combo:MenuElement({id = "CE", name = "Use [E]", value = true})
    NicktKat.Combo:MenuElement({id = "EAA", name = "Use [E + AA]", value = true})
    NicktKat.Combo:MenuElement({id = "CR", name = "Use [R]", value = true})
    --Steal
	NicktKat:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
    NicktKat.Killsteal:MenuElement({id ="KillQ", name = "Use [Q]", value = true})
    NicktKat.Killsteal:MenuElement({id ="KillE", name = "Use [E]", value = true})
    --Draw
	NicktKat:MenuElement({id = "OnDawings", name = "Dawings", type = MENU})
    NicktKat.OnDawings:MenuElement({id ="DQ", name = "Draw [Q]", value = true})
    NicktKat.OnDawings:MenuElement({id ="DE", name = "Draw [E]", value = true})
    NicktKat.OnDawings:MenuElement({id ="CC", name = "Draw [Dagger]", value = true})
end 

local function CalcMagicDmg(target, amount, from)
	local from = from or player
	local target = target 
	local amount = amount or 0
	local targetMR = target.magicResist * math.ceil(from.magicPenPercent) - from.magicPen
	local dmgMul = 100 / (100 + targetMR)
	if dmgMul < 0 then
		dmgMul = 2 - (100 / (100 - magicResist))
	end
	amount = amount * dmgMul
	return math.floor(amount)
end

local function GetEnemyHeroes()
    if _EnemyHeroes then 
        return _EnemyHeroes 
    end
    for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        if unit.isEnemy then
            if _EnemyHeroes == nil then 
                _EnemyHeroes = {} 
            end
            table.insert(_EnemyHeroes, unit)
        end 
    end 
    return {}
end

local function IsValidTarget(unit)
    if unit and unit.isEnemy and unit.valid and unit.isTargetable and not unit.dead and not unit.isImmortal and not (GotBuff(unit, 'FioraW') == 1) and not (GotBuff(unit, 'XinZhaoRRangedImmunity') == 1 and unit.distance < 450) and unit.visible then
        return true
    else 
        return false
    end
end

local function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.name == buffname and buff.count > 0 then
			return true
		end
	end
	return false
end

local function EnemysInrange(pos, range) 
	local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(pos, Hero.pos) < range then
            Count = Count + 1
        end
    end
    return Count
end


local function GetComboOrb() 
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
        return "Combo"
    end 
end 

local function GetLaneOrb() 
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEARS] then
        return "LaneClear"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
        return "LaneClear"
    end 
end 

local function GetDistanceSqr(p1, p2)
    local p2 = p2 or player
    local dx = p1.x - p2.x
    local dz = (p1.z or p1.y) - (p2.z or p2.y)
    return dx * dx + dz * dz
end

local function GetDistance(p1, p2)
    local squaredDistance = GetDistanceSqr(p1, p2)
    return math.sqrt(squaredDistance)
end

local function OnCreatObj()
    for i = 1, Game.ParticleCount() do
        local obj = Game.Particle(i)
        if obj then
            if obj.name == "W_Indicator_Ally" then
                if not table.contains(DaggerObj, obj.pos) then
                    DaggerObj[obj.networkID] = {['obj'] = obj, ['start'] = Game.Timer() + 1.1, ['end'] = Game.Timer() + 5.1 }
                    DaggerCount = DaggerCount + 1
                end 
            end 
        end 
    end 
end 

local function GetBestDaggerPoint(position, target)
    local targetPos = Vector(target.x, target.y, target.z)
    local positionPos = Vector(position.x, position.y, position.z)
    if GetDistanceSqr(targetPos, positionPos) <= 340 * 340 then
        return position
    end 
    return positionPos:Extended(targetPos, 150)
end 

local function LogicDistance(position, target)
    local targetPos = Vector(target.x, target.y, target.z)
    local positionPos = Vector(position.x, position.y, position.z)
    if GetDistanceSqr(targetPos, positionPos) < 340 * 340 then
        return position
    end 
    return positionPos:Extended(targetPos, 200) 
end 

local function LogicInstance(position, target)
    local targetPos = Vector(target.x, target.y, target.z)
    local positionPos = Vector(position.x, position.y, position.z)
    if GetDistanceSqr(targetPos, positionPos) < 340 * 340 then
        return position
    end 
    return positionPos:Extended(targetPos, -50)
end 

local function ELogic(position, target)
    local targetPos = Vector(target.x, target.y, target.z)
    local positionPos = Vector(position.x, position.y, position.z)
    if GetDistanceSqr(targetPos, positionPos) < 340 * 340 then
        return position
    end 
    return positionPos:Extended(targetPos, 50)
end

local function GetBestDaggerPoint(position, target)
    local targetPos = Vector(target.x, target.y, target.z)
    local positionPos = Vector(position.x, position.y, position.z)
    if GetDistanceSqr(targetPos, positionPos) < 340 * 340 then
        return position
    end 
    return positionPos:Extended(targetPos, -150)
end 

local function CastE(target)
    if NicktKat.Combo.EAA:Value() then
        if (DaggerCount == 0 and Game.CanUseSpell(0) == 0 and Game.CanUseSpell(1) == 0) and RCasting == false and GetDistance(target) > Q.Range and GetDistance(target) <= E.Range then
            Control.CastSpell(HK_E, target)
        end 
    end 
    for _, Adaga in pairs(DaggerObj) do
        if Adaga then
            local DaggerPos = Vector(Adaga) + (Vector(target) - Vector(Adaga)):Normalized() * 150
            local DaggerPosExte = Vector(Adaga) + (Vector(target) - Vector(Adaga)):Normalized() * 200
            local DaggerIsRange = Vector(Adaga) + (Vector(target) - Vector(Adaga)):Normalized() * 50
            local DaggerRange = Vector(Adaga) + (Vector(target) - Vector(Adaga)):Normalized() * -50
            local DaggerPos2 = Vector(Adaga) + (Vector(target) - Vector(Adaga)):Normalized() * -150
            if GetBestDaggerPoint(Adaga, target) and GetDistance(target, Adaga) <= 450 then
               Control.CastSpell(HK_E, DaggerPos)
            elseif LogicDistance(Adaga, target) and GetDistance(target, Adaga) <= 450 then
                Control.CastSpell(HK_E, DaggerPosExte)
            elseif LogicInstance(Adaga, target) and GetDistance(target, Adaga) <= 450 then
                Control.CastSpell(HK_E, DaggerRange)
            elseif ELogic(Adaga, target) and GetDistance(target, Adaga) <= 450 then
                Control.CastSpell(HK_E, DaggerIsRange)
            elseif LogicInstance(Adaga, target) and GetDistance(target, Adaga) <= 450 then
                Control.CastSpell(HK_E, DaggerPos2)
            end  
        end 
    end 
end

local function CastW()
    if WPos then
        Control.CastSpell(HK_W)
        return player.Posis 
    end 
end 

local function CastQ(target)
    if GetDistance(target) <= 625 then
        Control.CastSpell(HK_Q, target)
    end 
end 

local function IsCombo()
    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(1000)
    if target ~= nil and not target.dead and target.visible and target.isTargetable and IsValidTarget(target) then
        if Game.CanUseSpell(0) == 0 and GetDistance(target) <= Q.Range and RCasting == false then
            CastQ(target)
        end 
        if Game.CanUseSpell(2) == 0 and (GetDistance(target) <= E.Range+340) and RCasting == false then
            CastE(target)
        end 
        if Game.CanUseSpell(1) == 0  and GetDistance(target) <= W.Range and RCasting == false  then
            CastW(target)
        end
        local HealtEne = target.health + target.shieldAP + target.shieldAD
        local dmg = CalcMagicDmg(player, unit, (((player:GetSpellData(_R).level * 25) - ((player:GetSpellData(_R).level - 1) * 12.5)) + (bAD * 0.22) + (AP * 0.19)))
        if HealtEne < dmg then
            if Game.CanUseSpell(3) == 0 and GetDistance(target) <= W.Range and RCasting == false then
                Control.CastSpell(HK_R, target)
            end
        end
    end 
end 

local function OnCancelR()
    if RCasting == true and #EnemysInrange(player.pos, 550 + 10) == 0 then
        Control.Move(mousePos)
    end 
end 


local function OnLoading()
    LoadingMenu()
end 

local function OnTick()
    OnCreatObj()
    OnCancelR()

    if HasBuff(player, "katarinarsound") then
        RCasting = true
        _G.SDK.Orbwalker:SetAttack(false)
        _G.SDK.Orbwalker:SetMovement(false)
    else 
        RCasting = false
        _G.SDK.Orbwalker:SetAttack(true)
        _G.SDK.Orbwalker:SetMovement(true)
    end 

    if GetComboOrb() == 'Combo' then
        IsCombo()
    end 
end 

local function OnDraw()
    if not player.dead and player.visible then
        if NicktKat.OnDawings.DQ:Value() then
            Draw.Circle(myHero.pos, Q.Range, 0, Draw.Color(255, 255, 0, 0))
        end 
        if NicktKat.OnDawings.DE:Value() then
            Draw.Circle(myHero.pos, E.Range, 0, Draw.Color(255, 255, 0, 0))
        end 
        if NicktKat.OnDawings.CC:Value() then
            if (DaggerCount > 0)  then
                for _, Adaga in pairs(DaggerObj) do
                    if Adaga then
                        Draw.Circle(Vector(Adaga), 340, 0, Draw.Color(255, 255, 0, 0))
                    end 
                end 
            end 
        end 
    end 
end 

Callback.Add("Tick", function() OnTick() end)
Callback.Add("Load", function() OnLoading() end)
Callback.Add("Draw", function() OnDraw() end)
