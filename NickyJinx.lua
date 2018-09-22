if myHero.charName ~= "Jinx" then return end

require('DamageLib')

local player = myHero
local playerPos = myHero.pos
local TEAM_ALLY = player.team
local TEAM_ENEMY = 300 - TEAM_ALLY

local minigun = false
local left_side = Vector(396,182,462)
local right_side = Vector(14340,172,14384)
local recall = {}

local speedR = 1700

local timers = { 
    recall = 8.0;
    odinrecall = 4.5;
   	odinrecallimproved = 4.0;
    recallimproved = 7.0;
    superrecall = 4.0;
}

local side = right_side
if player.team == 200 then
	side = left_side
end

local function GetComboOrb() 
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
        return "Combo"
    end 
end 


local function GetDistance(p1, p2)
	local p2 = p2 or playerPos
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

local function GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or playerPos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx * dx + dz * dz
end

local function MenuJinx()
    NickyJinx = MenuElement({type = MENU, id = "Jinx", name = "[Nicky]Jinx"})
	--QS
	NickyJinx:MenuElement({id = "QS", name = "(Q) Settings", type = MENU})
    NickyJinx.QS:MenuElement({id = "CQ", name = "Use [Q] In Combo", value = true})
    NickyJinx.QS:MenuElement({id = "Mana", name = "Don't use rockets under mana percent", value = 25, min = 0, max = 100, step = 1})
    --WS
    NickyJinx:MenuElement({id = "WS", name = "(W) Settings", type = MENU})
    NickyJinx.WS:MenuElement({id = "CW", name = "Only use W when out of AA range", value = true})
    NickyJinx.WS:MenuElement({id = "mynana", name = "Don't use W under mana percent", value = 20, min = 1, max = 100, step = 1})
    --Es
    NickyJinx:MenuElement({id = "ES", name = "(E) Settings", type = MENU})
    NickyJinx.ES:MenuElement({id = "CE", name = "Use [E] in Combo", value = true})
    NickyJinx.ES:MenuElement({id = "CCj", name = "Auto E on stunned targets", value = true})
    NickyJinx.ES:MenuElement({id = "inter", name = "Auto E on good spots", value = true})
    --Rs
    NickyJinx:MenuElement({id = "RS", name = "(R) Settings", type = MENU})
    NickyJinx.RS:MenuElement({id = "CR", name = "Use [R]", value = true})
    NickyJinx.RS:MenuElement({id = "AutoR", name = "Max ult range", value = 2000, min = 1, max = 6000, step = 1})
end 

local function BuffMinigun(name)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
    	if buff.name == name and buff.count > 0 then 
    		if Game.Timer() <= buff.endTime then
	      		return true, buff.startTime
    		end
    	end
  	end
  	return false, 0
end

local function minigun()
	if BuffMinigun("jinxqicon") then
		return true;
	end
	return false;
end

local function ManaPercente()
	return player.mana / player.maxMana * 100
end

local function CalCULED(dist)
	return (dist > 1350 and (1350*1700+((dist-1350)*2200))/dist or 1700)
end

local spots = {
	{9704,56,3262},{8214,52,3264},{8812,54,4266},{6882,49,4254},{6008,50,4146},{6142,51,3376},{6094,53,2200},{7532,52,2388},{10000,50,2488},{7484,53,6026},{4822,52,5974},{4646,52,6878},{3896,52,7280},{2604,58,6648},{2352,52,9144},{3518,52,8486},{5598,52,7562},{9214,53,7338},{10888,53,7606},{11600,53,8002},{10124,55,8268},{8276,51,10218},{8760,51,10638},{8658,54,11536},{8722,57,12496},{6626,55,11510},{6038,56,10426},{6582,49,4722},{11204,-13,5592},{11878,53,5146},{12528,53,5710},{12204,52,6622},{12228,53,8180},{11900,52,7166},{4884,57,12428},{5224,57,11574},{6818,55,13020},{7208,53,8956},{3568,33,9234},{3980,-15,11392},{6208,-68,9318},{8610,-50,5556},{9944,0,6324},{4820,4,8526}
};

local function CointERR(unit, range)
	local nerds = 0;
	for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)  
    	if Hero and not Hero.dead then 
    		if Hero.pos:DistanceTo(unit.pos) <= range then
    			nerds = nerds + 1;
    		end
    	end
    end
    return nerds;
end

local function ArmaFavorita(unit)
	local nerds = CointERR(unit, 100);
	if not minigun() then
	 	if playerPos:DistanceTo(unit.pos) <= 525 and nerds == 1 or ManaPercente() < NickyJinx.QS.Mana:Value() then
			Control.CastSpell(HK_Q)
		end
	else
		if nerds > 1 then
			Control.CastSpell(HK_Q)
		end
	end
end

local function UsedE(unit)
	if Game.CanUseSpell(1) ~= 0 then return end
	if unit.pos:DistanceTo(playerPos) > 1450 then return end

	local Wpred = unit:GetPrediction(3200, 0.5)
	if not Wpred then return end
		
	if unit:GetCollision(55, 3200, 0.5) then
		Control.CastSpell(HK_W, Wpred)
	end
end

local function OSAA()
    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(1000)
    if not target then return end 
    if not GetComboOrb() == 'Combo' then return end

	if (ManaPercente() > NickyJinx.WS.mynana:Value() and  NickyJinx.WS.CW:Value()) then
		zap(target)
	end

	if ManaPercente() < NickyJinx.QS.Mana:get() then return end

    if minigun() and playerPos:DistanceTo(target.pos) > 525 then
    	Control.CastSpell(HK_Q)
    end
end

local function ISpOET(unit)
	if not NickyJinx.ES.CE:get() then return end
	if Game.CanUseSpell(2) ~= 0 then return end
	for i = 1, #spots do
		local spot_pos = Vector(spots[i][1], spots[i][2], spots[i][3]);
		if GetDistance(spot_pos, unit.pos) < 200 and GetDistance(playerPos, spot_pos) > 100 then
			
			local Epred = unit:GetPrediction(1100, 0.95)
			if not Epred then return end
			Control.CastSpell(HK_E, Epred)
		end
	end
end

local function IsBadCombo()
    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(1000)
    if not target then
		if not minigun() then
            Control.CastSpell(HK_Q)
		end
	 	return
    end
    ISpOET(target);
    
    if not GetComboOrb() == 'Combo' then return end
    
	if not NickyJinx.WS.CW:Value() then
		UsedE(target);
	end
	ArmaFavorita(target);
end 

local function JinxR()
    if not NickyJinx.RS.CR:Value() then return end
    if Game.CanUseSpell(3) ~= 0 then return end
    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(5000)
    
    local dist = playerPos:DistanceTo(target);
    if not target.dead and dist <= NickyJinx.RS.AutoR:get() and dist > 1000 then
        speedR = CalCULED(dist)
        local Rpred = unit:GetPrediction(1700, 0.25)
		if not Rpred then return end
        Control.CastSpell(HK_R, Rpred)
    end     
end 

local function OnLoading()
    MenuJinx()
end 

local function OnTick()
    IsBadCombo();
    JinxR();
end 


Callback.Add("Tick", function() OnTick() end)
Callback.Add("Load", function() OnLoading() end)
