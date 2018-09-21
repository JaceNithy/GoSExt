if myHero.charName ~= "Pyke" then return end

local player = myHero
local playerPos = myHero.pos


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

local function GetComboOrb() 
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
        return "Combo"
    end 
end 

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local function ReleaseSpell(spell, pos, range, delay)
    local delay = delay or 250
    local ticker = GetTickCount()
    if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + Game.Latency() then
        castSpell.state = 1
        castSpell.mouse = mousePos
        castSpell.tick = ticker
    end
    if castSpell.state == 1 then
        if ticker - castSpell.tick < Game.Latency() then
            if not pos:ToScreen().onScreen then
                pos = myHero.pos + Vector(myHero.pos,pos):Normalized() * math.random(530,760)
                Control.SetCursorPos(pos)
                Control.KeyUp(spell)
            else
                Control.SetCursorPos(pos)
                Control.KeyUp(spell)
            end
            castSpell.casting = ticker + delay
            DelayAction(function()
                if castSpell.state == 1 then
                    Control.SetCursorPos(castSpell.mouse)
                    castSpell.state = 0
                end
            end,Game.Latency()/1000)
        end
        if ticker - castSpell.casting > Game.Latency() then
            Control.SetCursorPos(castSpell.mouse)
            castSpell.state = 0
        end
    end
end

local function LoadingMenu()
    NickyPyke = MenuElement({type = MENU, id = "Pyke", name = "[Nicky]Pyke"})
	--Combo
	NickyPyke:MenuElement({id = "Combo", name = "Combo", type = MENU})
	NickyPyke.Combo:MenuElement({id = "CQ", name = "Use [Q]", value = true})
    NickyPyke.Combo:MenuElement({id = "CW", name = "Use [E]", value = true})
    NickyPyke.Combo:MenuElement({id = "RangeD", name = "Only dash if range <", value = 400, min = 100, max = 500, step = 10})
    NickyPyke.Combo:MenuElement({id = "ManE", name = "Only dash mana above %", value = 20, min = 1, max = 100, step = 1})
end 

local function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
        if buff and string.lower(buff.name) == string.lower(buffname) and buff.owner == unit then
            if Game.Timer() <= buff.endTime then
                return true, buff.startTime
            end 
        end 
    end 
    return false, 0
end

local last_q_time = 0;
local function UpdateBuff()
	local buff, time = HasBuff(player, "PykeQ");
	if buff then
		last_q_time = time;
	end
end

local function VectPoint(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

local function QRange()
    local t = Game.Timer() - last_q_time;
    local range = 400;

    if t > 0.5 then
        range = range + (t/.1 * 62);
    end
    
    if range > 1050 then
        return 1050
    end
    return range
end

local scale = {190, 240, 290, 340, 390, 440, 475, 510, 545, 580, 615, 635, 655};
local function RDamage()
    if player.levelData.lvl < 6 then 
        return 0 
    end
	local dmg = scale[player.levelData.lvl - 5];
	local bonus = player.baseDamage;
	return (dmg + (bonus * 0.6));
end

local function ManaPercente()
	return player.mana / player.maxMana * 100
end


local function spear(unit)
	if Game.CanUseSpell(0) ~= 0 then return end
	if (Game.CanUseSpell(2) ~= 0 == 0 and unit.pos:DistanceTo(playerPos) < NickyPyke.Combo.RangeD:Value()) and not HasBuff(player, "PykeQ") and NickyPyke.Combo.CW:Value() then return end
	if unit.pos:DistanceTo(playerPos) > QRange() then return end

	local qpred = unit:GetPrediction(2000, 0.25)
	if not qpred then return end
		
	if not unit:GetCollision(70, qpred) or unit.pos:DistanceTo(playerPos) <= 400 then
		if HasBuff(player, "PykeQ") then
			if unit.pos:DistanceTo(playerPos) + 150 < QRange() or (unit.pos:DistanceTo(playerPos) < 400 and QRange() <= 400) then
				ReleaseSpell(HK_Q, qpred, QRange(), 100)
			end
		else
            Control.CastSpell(HK_Q, playerPos)
		end
	end
end

local function dash(unit)
	if not NickyPyke.Combo.CW:Value() then return end
	if player:spellSlot(2).state ~= 0 then return end
	if HasBuff(player, "PykeQ") then return end
	if unit.pos:DistanceTo(playerPos) > NickyPyke.Combo.RangeD:Value() then return end
	if ManaPercente() < NickyPyke.Combo.ManE:Value() then return end

    Control.CastSpell(HK_E, unit.pos)
end

local ex_data = {};
local last_execute = 0;
local function execute(unit)
    if Game.CanUseSpell(0) == 32 then 
        return 
    end
    if GetDistance(playerPos, unit.pos) > 700 then 
        return 
    end
    if unit.dead or not unit.visible or not unit.isTargetable then 
        return 
    end
    if HasBuff(unit, "sionpassivezombie") then 
        return 
    end
    if last_execute > 0 and Game.Timer() - last_execute < 1.2 then 
        return 
    end

	local rpred = unit:GetPrediction(1100, 0.325 + Game.Latency()/1000)
	if not rpred then return end

	local pred_pos = Vector(rpred.endPos.x, unit.pos.y, rpred.endPos.y);
	if GetDistance(pred_pos, playerPos) > 700 then return end

	local x1 = pred_pos + Vector(200,0,200);
	local x2 = pred_pos + Vector(-200,0,-200);
	local x3 = pred_pos + Vector(200,0,-200);
	local x4 = pred_pos + Vector(-200,0,200);

	ex_data[unit.networkID].draw = {x1, x2, x3, x4};

	local ps1, pl1, line1 = VectPoint(x1, x2, unit);
	local ps2, pl2, line2 = VectPoint(x3, x4, unit);
	local newpos = Vector(pred_pos.x, 0, pred_pos.z);

	if (line1 and GetDistance(newpos, ps1)  < 50 + unit.boundingRadius) or (line2 and newpos:dist(ps2) < 50 + unit.boundingRadius) then
        Control.CastSpell(HK_R, pred_pos)
		last_execute = Game.Timer();
	end
end

local function iscombo()
    if _G.SDK.TargetSelector:GetTarget(1000) == nil then 
        return 
    end
    local target = _G.SDK.TargetSelector:GetTarget(1000)
    if not target then return end 
    if not GetComboOrb() == 'Combo' then return end
    
	spear(target);
	dash(target);

end 

local function OnTick()
    UpdateBuff()

    for i = 1, Game.HeroCount() do
        local nerd = Game.Hero(i)
        if not nerd then 
            return 
        end
        if not ex_data[nerd.networkID] then 
            ex_data[nerd.networkID] = {} 
        end
    	ex_data[nerd.networkID].kill = false;
    	if RDamage() >= nerd.health and not nerd.dead and nerd.visible then
    		ex_data[nerd.networkID].kill = true;
    		execute(nerd);
    	end
    end
    iscombo();
end

local function OnLoading()
    LoadingMenu()
end

local function OnDraw()
    for i = 1, Game.HeroCount() do
        local nerd = Game.Hero(i)
        if not nerd then return end
    	local data = ex_data[nerd.networkID];
    	if not data then return end
        if data.kill and data.draw and nerd.onScreen then
            Draw.Line(data.draw[1], data.draw[2], 50, Draw.Color(100, 192, 57, 43))
			Draw.Line(data.draw[3], data.draw[4], 50, Draw.Color(100, 192, 57, 43))
		end
    end
    if player.onScreen and not player.dead then
		Draw.Circle(playerPos, QRange(), 2, Draw.Color(255, 192, 57, 43))
	end
end 

Callback.Add("Tick", function() OnTick() end)
Callback.Add("Load", function() OnLoading() end)
Callback.Add("Draw", function() OnDraw() end)