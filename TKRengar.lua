--[[

  _______            _  __    _      _____                             
 |__   __|          | |/ /   | |    |  __ \                            
    | | ___  _ __   | ' / ___| | __ | |__) |___ _ __   __ _  __ _ _ __ 
    | |/ _ \| '_ \  |  < / _ \ |/ / |  _  // _ \ '_ \ / _` |/ _` | '__|
    | | (_) | |_) | | . \  __/   <  | | \ \  __/ | | | (_| | (_| | |   
    |_|\___/| .__/  |_|\_\___|_|\_\ |_|  \_\___|_| |_|\__, |\__,_|_|   
            | |                                        __/ |           
            |_|                                       |___/                                                                      

    By Nebelwolfi

]]--

--[[ Auto updater start ]]--
local version = 0.09
local AUTO_UPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/nebelwolfi/BoL/master/TKRengar.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH.."TKRengar.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local function TopKekMsg(msg) print("<font color=\"#6699ff\"><b>[Top Kek Series]: Rengar - </b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTO_UPDATE then
  local ServerData = GetWebResult(UPDATE_HOST, "/nebelwolfi/BoL/master/TKRengar.version")
  if ServerData then
    ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
    if ServerVersion then
      if tonumber(version) < ServerVersion then
        TopKekMsg("New version available v"..ServerVersion)
        TopKekMsg("Updating, please don't press F9")
        DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () TopKekMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version") end) end, 3)
      else
        TopKekMsg("Loaded the latest version (v"..ServerVersion..")")
      end
    end
  else
    TopKekMsg("Error downloading version info")
  end
end
--[[ Auto updater end ]]--

--[[ Libraries start ]]--
local predToUse = {}
VP  = nil
DP  = nil
HP  = nil
TKP = nil
if FileExist(LIB_PATH .. "/VPrediction.lua") then
  require("VPrediction")
  VP = VPrediction()
  table.insert(predToUse, "VPrediction")
end

if VIP_USER and FileExist(LIB_PATH.."DivinePred.lua") and FileExist(LIB_PATH.."DivinePred.luac") then
  require "DivinePred"
  DP = DivinePred() 
  table.insert(predToUse, "DivinePred")
end

if FileExist(LIB_PATH .. "/HPrediction.lua") then
  require("HPrediction")
  HP = HPrediction()
  table.insert(predToUse, "HPrediction")
end

if FileExist(LIB_PATH .. "/TKPrediction.lua") then
  require("TKPrediction")
  TKP = TKPrediction()
  table.insert(predToUse, "TKPrediction")
end

if predToUse == {} then 
  TopKekMsg("Please download a Prediction") 
  return 
end

if FileExist(LIB_PATH .. "SourceLib.lua") then
  require("SourceLib")
else
  TopKekMsg("Please download SourceLib")
  return
end
--[[ Libraries end ]]--

--[[ Script start ]]--
if  myHero.charName ~= "Rengar" then return end -- not supported :(
if VIP_USER then HookPackets() end
if myHero:GetSpellData(SUMMONER_1).name:find("smite") then Smite = SUMMONER_1 elseif myHero:GetSpellData(SUMMONER_2).name:find("smite") then Smite = SUMMONER_2 end
if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then Ignite = SUMMONER_1 elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then Ignite = SUMMONER_2 end
local QReady, WReady, EReady, RReady, IReady, SReady = function() return myHero:CanUseSpell(_Q) end, function() return myHero:CanUseSpell(_W) end, function() return myHero:CanUseSpell(_E) end, function() return myHero:CanUseSpell(_R) end, function() if Ignite ~= nil then return myHero:CanUseSpell(Ignite) end end, function() if Smite ~= nil then return myHero:CanUseSpell(Smite) end end
local RebornLoaded, RevampedLoaded, MMALoaded, SxOrbLoaded, SOWLoaded = false, false, false, false, false
local Target 
local sts
local enemyTable = {}
local enemyCount = 0
local ultOn, oneShot = false, false
local osTarget = nil
data = {
    [_Q] = { range = 125*2, type = "notarget", aareset = true},
    [_W] = { speed = math.huge, delay = 0.5, range = 390, width = 55, collision = false, aoe = true, type = "circular"},
    [_E] = { speed = 1500, delay = 0.50, range = 1000, width = 80, collision = false, aoe = false, type = "linear"},
    [_R] = { range = 4000, type = "notarget"}
    }

function OnLoad()
  Config = scriptConfig("Top Kek Rengar", "TKRengar")
  
  Config:addSubMenu("Pred/Skill Settings", "misc")
  if VIP_USER then Config.misc:addParam("pc", "Use Packets To Cast Spells", SCRIPT_PARAM_ONOFF, false)
  Config.misc:addParam("qqq", " ", SCRIPT_PARAM_INFO,"") end
  Config.misc:addParam("qqq", "RELOAD AFTER CHANGING PREDICTIONS! (2x F9)", SCRIPT_PARAM_INFO,"")
  Config.misc:addParam("pro", "Type of prediction", SCRIPT_PARAM_LIST, 1, predToUse)

  if ActivePred() == "DivinePred" then Config.misc:addParam("time","DPred Extra Time", SCRIPT_PARAM_SLICE, 0.03, 0, 0.3, 2) end
  if ActivePred() == "HPrediction" then SetupHPred() end

  Config:addSubMenu("Combo Settings", "comboConfig")
  Config.comboConfig:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.comboConfig:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.comboConfig:addParam("Whp", "Use W for HP", SCRIPT_PARAM_ONOFF, true)
  Config.comboConfig:addParam("Whpp", "W for HP under X%", SCRIPT_PARAM_SLICE, 15, 0, 100, 0)
  Config.comboConfig:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)
  --Config.comboConfig:addParam("R", "Use R", SCRIPT_PARAM_ONOFF, true)
  Config.comboConfig:addParam("items", "Use Items", SCRIPT_PARAM_ONOFF, true)
  if Smite ~= nil then Config.comboConfig:addParam("S", "Use Smite", SCRIPT_PARAM_ONOFF, true) end

  Config:addSubMenu("Harrass Settings", "harrConfig")
  Config.harrConfig:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.harrConfig:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.harrConfig:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)
  
  Config:addSubMenu("Farm Settings", "farmConfig")
  Config.farmConfig:addSubMenu("Lane/Jungle Clear", "lc")
  Config.farmConfig:addSubMenu("Last Hit", "lh")
  Config.farmConfig.lc:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.farmConfig.lc:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.farmConfig.lc:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)
  Config.farmConfig.lh:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.farmConfig.lh:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.farmConfig.lh:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)
  Config.farmConfig:addParam("Whp", "Use W for HP while farming", SCRIPT_PARAM_ONOFF, true)
      
  Config:addSubMenu("Killsteal Settings", "KS")
  Config.KS:addParam("enableKS", "Enable Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.KS:addParam("killstealQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.KS:addParam("killstealW", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.KS:addParam("killstealE", "Use E", SCRIPT_PARAM_ONOFF, true)
  if Ignite ~= nil then Config.KS:addParam("killstealI", "Use Ignite", SCRIPT_PARAM_ONOFF, true) end
  if Smite ~= nil then Config.KS:addParam("killstealS", "Use Smite", SCRIPT_PARAM_ONOFF, true) end

  Config:addSubMenu("Draw Settings", "Drawing")
  Config.Drawing:addParam("QRange", "Q Range", SCRIPT_PARAM_ONOFF, true)
  Config.Drawing:addParam("WRange", "W Range", SCRIPT_PARAM_ONOFF, true)
  Config.Drawing:addParam("ERange", "E Range", SCRIPT_PARAM_ONOFF, true)
  Config.Drawing:addParam("dmgCalc", "Damage", SCRIPT_PARAM_ONOFF, true)
  
  Config:addSubMenu("Key Settings", "kConfig")
  Config.kConfig:addParam("combo", "SBTW (HOLD)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
  Config.kConfig:addParam("harr", "Harrass (HOLD)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
  Config.kConfig:addParam("har", "Harrass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("G"))
  Config.kConfig:addParam("lh", "Last hit (Hold)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
  Config.kConfig:addParam("lc", "Lane Clear (Hold)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
  Config:addParam("ragequit",  "Ragequit", SCRIPT_PARAM_ONOFF, false) 
  
  Config:addSubMenu("Orbwalk Settings", "oConfig")
  SetupOrbwalk()

  Config.kConfig:permaShow("combo")
  Config.kConfig:permaShow("harr")
  Config.kConfig:permaShow("har")
  Config.kConfig:permaShow("lh")
  Config.kConfig:permaShow("lc")
  sts = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
  Config:addSubMenu("Target Selector", "sts")
  sts:AddToMenu(Config.sts)

    for i = 1, heroManager.iCount do
        local champ = heroManager:GetHero(i)
        if champ.team ~= player.team then
            enemyCount = enemyCount + 1
            enemyTable[enemyCount] = { player = champ, name = champ.charName, blazed = false, damageQ = 0, damageW = 0, damageE = 0, damageI = 0, damageS = 0, indicatorText = "", damageGettingText = "", ready = true}
        end
    end
end

function SetupOrbwalk()
  if _G.AutoCarry then
    if _G.Reborn_Initialised then
      RebornLoaded = true
      TopKekMsg("Found SAC: Reborn")
      Config.oConfig:addParam("Info", "SAC: Reborn detected!", SCRIPT_PARAM_INFO, "")
    else
      RevampedLoaded = true
      TopKekMsg("Found SAC: Revamped")
      Config.oConfig:addParam("Info", "SAC: Revamped detected!", SCRIPT_PARAM_INFO, "")
    end
  elseif _G.Reborn_Loaded then
    DelayAction(function() SetupOrbwalk() end, 1)
  elseif _G.MMA_Loaded then
    MMALoaded = true
    TopKekMsg("Found MMA")
      Config.oConfig:addParam("Info", "MMA detected!", SCRIPT_PARAM_INFO, "")
  elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
    require 'SxOrbWalk'
    SxOrb = SxOrbWalk()
    SxOrb:LoadToMenu(Config.oConfig)
    SxOrbLoaded = true
    TopKekMsg("Found SxOrb.")
  elseif FileExist(LIB_PATH .. "SOW.lua") then
    require 'SOW'
    require 'VPrediction'
    SOWVP = SOW(VP)
    Config.oConfig:addParam("Info", "SOW settings", SCRIPT_PARAM_INFO, "")
     Config.oConfig:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
    SOWVP:LoadToMenu(Config.oConfig)
    SOWLoaded = true
    TopKekMsg("Found SOW")
  else
    TopKekMsg("No valid Orbwalker found")
  end
end

function OnTick()
  Target = GetCustomTarget()

  DmgCalculations()

  if Target ~= nil then
    if Config.KS.enableKS then 
      Killsteal()
    end

    if not ultOn and (Config.kConfig.har or Config.kConfig.harr) then
      Harrass()
    end

    if Config.kConfig.combo then
      if ultOn and not oneShot then 
        osTarget = Target
      end
      if ultOn or oneShot then 
        oneShot = true
        OneShot()
      else
        Combo()
      end
    end
  end

  if not ultOn and Config.kConfig.lh then
    LastHit()
  end
  if not ultOn and Config.kConfig.lc then
    LaneClear()
    JungleClear()
  end

  if Config.ragequit then Target=myHero.isWindingUp end --trololo ty Hirschmilch
end

function LastHit()
  if myHero.mana == 5 and Config.farmConfig.Whp and (myHero.health / myHero.maxHealth) * 100 < 90 then
    if WReady() and Config.farmConfig.lc.W then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_ENEMY, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.health >= minion.health and ValidTarget(minion, data[1].range) then
          minionTarget = minion
        end
      end
      CastW(minionTarget)
    end  
  else
    if QReady() and Config.farmConfig.lh.Q then
      for i, minion in pairs(minionManager(MINION_ENEMY, data[0].range, player, MINION_SORT_HEALTH_ASC).objects) do
        local QMinionDmg = GetDmg("Q", minion)
        if QMinionDmg >= minion.health and ValidTarget(minion, data[0].range) then
          CastQ(minion)
        end
      end
    end
    if WReady() and Config.farmConfig.lh.W then
      for i, minion in pairs(minionManager(MINION_ENEMY, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        local WMinionDmg = GetDmg("W", minion)
        if WMinionDmg >= minion.health and ValidTarget(minion, data[1].range+data[1].width) then
          CastW(minion)
        end
      end    
    end  
    if EReady() and Config.farmConfig.lh.E then    
      for i, minion in pairs(minionManager(MINION_ENEMY, data[2].range, player, MINION_SORT_HEALTH_ASC).objects) do    
        local EMinionDmg = GetDmg("E", minion)      
        if EMinionDmg >= minion.health and ValidTarget(minion, data[2].range+data[1].width) then
          CastE(minion)
        end      
      end    
    end  
  end
end

function LaneClear()
  if myHero.mana == 5 and Config.farmConfig.Whp and (myHero.health / myHero.maxHealth) * 100 < 90 then
    if WReady() and Config.farmConfig.lc.W then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_ENEMY, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.health >= minion.health and ValidTarget(minion, data[1].range) then
          minionTarget = minion
        end
      end
      CastW(minionTarget)
    end  
  else
    --Check for lowlife: Lasthit = priority!
    if QReady() and Config.farmConfig.lc.Q then
      for i, minion in pairs(minionManager(MINION_ENEMY, data[0].range, player, MINION_SORT_HEALTH_ASC).objects) do
        local QMinionDmg = GetDmg("Q", minion)
        if QMinionDmg >= minion.health and ValidTarget(minion, data[0].range) then
          CastQ(minion)
        end
      end
    end
    if WReady() and Config.farmConfig.lc.W then
      for i, minion in pairs(minionManager(MINION_ENEMY, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        local WMinionDmg = GetDmg("W", minion)
        if WMinionDmg >= minion.health and ValidTarget(minion, data[1].range+data[1].width) then
          CastW(minion)
        end
      end    
    end  
    if EReady() and Config.farmConfig.lc.E then    
      for i, minion in pairs(minionManager(MINION_ENEMY, data[2].range, player, MINION_SORT_HEALTH_ASC).objects) do    
        local EMinionDmg = GetDmg("E", minion)      
        if EMinionDmg >= minion.health and ValidTarget(minion, data[2].range+data[1].width) then
          CastE(minion)
        end      
      end    
    end 
    --Check for lowestlife: Lanceclear - 2nd priority!
    if QReady() and Config.farmConfig.lc.Q then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_ENEMY, data[0].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.health >= minion.health and ValidTarget(minion, data[0].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastQ(minionTarget)
      end
    end
    if WReady() and Config.farmConfig.lc.W then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_ENEMY, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.health >= minion.health and ValidTarget(minion, data[1].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastW(minionTarget)
      end
    end  
    if EReady() and Config.farmConfig.lc.E then   
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_ENEMY, data[2].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.health >= minion.health and ValidTarget(minion, data[2].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastE(minionTarget)
      end
    end 
  end
end

function JungleClear()
  if myHero.mana == 5 and Config.farmConfig.Whp and (myHero.health / myHero.maxHealth) * 100 < 90 then
    if WReady() and Config.farmConfig.lc.W then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.maxHealth < minion.maxHealth and ValidTarget(minion, data[1].range) then
          minionTarget = minion
        end
      end
      CastW(minionTarget)
    end  
  else
    --Check for lowlife: Lasthit = priority!
    if QReady() and Config.farmConfig.lc.Q then
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[0].range, player, MINION_SORT_HEALTH_ASC).objects) do
        local QMinionDmg = GetDmg("Q", minion)
        if QMinionDmg >= minion.health and ValidTarget(minion, data[0].range) then
          CastQ(minion)
        end
      end
    end
    if WReady() and Config.farmConfig.lc.W then
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        local WMinionDmg = GetDmg("W", minion)
        if WMinionDmg >= minion.health and ValidTarget(minion, data[1].range+data[1].width) then
          CastW(minion)
        end
      end    
    end  
    if EReady() and Config.farmConfig.lc.E then    
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[2].range, player, MINION_SORT_HEALTH_ASC).objects) do    
        local EMinionDmg = GetDmg("E", minion)      
        if EMinionDmg >= minion.health and ValidTarget(minion, data[2].range+data[1].width) then
          CastE(minion)
        end      
      end    
    end 
    --Check for lowestlife: Lanceclear - 2nd priority!
    if QReady() and Config.farmConfig.lc.Q then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[0].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.maxHealth < minion.maxHealth and ValidTarget(minion, data[0].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastQ(minionTarget)
      end
    end
    if WReady() and Config.farmConfig.lc.W then
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.maxHealth < minion.maxHealth and ValidTarget(minion, data[1].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastW(minionTarget)
      end
    end  
    if EReady() and Config.farmConfig.lc.E then   
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_JUNGLE, data[2].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.maxHealth < minion.maxHealth and ValidTarget(minion, data[2].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastE(minionTarget)
      end
    end 
  end
end

function Combo()
  if myHero.mana == 5 and Config.comboConfig.Whp and ((myHero.health / myHero.maxHealth) * 100 <= Config.comboConfig.Whpp) then
    if ValidTarget(Target, data[1].range) then
      CastW(Target)
    else
      local minionTarget = nil
      for i, minion in pairs(minionManager(MINION_ENEMY, data[1].range, player, MINION_SORT_HEALTH_ASC).objects) do
        if minionTarget == nil then 
          minionTarget = minion
        elseif minionTarget.health >= minion.health and ValidTarget(minion, data[1].range) then
          minionTarget = minion
        end
      end
      if minionTarget ~= nil then
        CastW(minionTarget)
      end
    end  
  else
    if Config.comboConfig.Q and ValidTarget(Target, data[0].range) then
      CastQ(Target)
    end
    if Config.comboConfig.W and ValidTarget(Target, data[1].range) then
      CastW(Target)
    end
    if Config.comboConfig.E and ValidTarget(Target, data[2].range) then
      CastE(Target)
    end
  end
end

function OneShot()
  if GetDistance(osTarget, myHero) > myHero.range then return end
  if Smite ~= nil and SReady() then CastSpell(Smite, osTarget) end
  if myHero.mana == 5 then 
    if Config.comboConfig.E and GetDistance(osTarget, myHero) < data[2].range then
      CastE(osTarget)
    end
  else
    if Config.comboConfig.Q and GetDistance(osTarget, myHero) < data[0].range then
      CastQ(osTarget)
    end
    if Config.comboConfig.W and GetDistance(osTarget, myHero) < data[1].range then
      CastW(osTarget)
    end
    if Config.comboConfig.E and GetDistance(osTarget, myHero) < data[2].range then
      CastE(osTarget)
    end
    if Config.comboConfig.item and GetDistance(osTarget, myHero) < data[0].range then
      UseItems(osTarget)
    end
  end
  if Ignite ~= nil and IReady() then CastSpell(Ignite, osTarget) end
  if osTarget.dead then oneShot = false end
end

function OnCreateObj(object)
  if object ~= nil and string.find(object.name, "Rengar_Base_R_Buf") then
    ultOn = true
  end 
end
 
function OnDeleteObj(object)
  if object ~= nil and string.find(object.name, "Rengar_Base_R_Buf") then
    ultOn = false
  end
end

function Harrass()
  if Config.harrConfig.Q and ValidTarget(Target, data[0].range) then
    CastQ(Target)
  end
  if Config.harrConfig.W and ValidTarget(Target, data[1].range) then
    CastW(Target)
  end
  if Config.harrConfig.E and ValidTarget(Target, data[2].range) then
    CastE(Target)
  end
end

function CastQ(Targ) 
  if QReady() then CastSpell(_Q, myHero:Attack(Targ)) end
end
function CastW(Targ) 
  if WReady() then CastSpell(_W) end
end
function CastE(Targ) 
  local CastPosition, HitChance, Position = Predict(Targ, 2, myHero)
  if HitChance and HitChance >= 2 and EReady() then
    CCastSpell(_E, CastPosition.x, CastPosition.z)
  end
end
function CastR(Targ) 
  if RReady() then CastSpell(_R) end
end

function EnemiesAround(Unit, range)
  local c=0
  if Unit == nil then return 0 end
  for i=1,heroManager.iCount do hero = heroManager:GetHero(i) if hero ~= nil and hero.team ~= myHero.team and hero.x and hero.y and hero.z and GetDistance(hero, Unit) < range then c=c+1 end end return c
end

function Killsteal()
  for i=1, heroManager.iCount do
    local enemy = heroManager:GetHero(i)
    local qDmg = ((GetDmg("Q", enemy)) or 0)  
    local wDmg = ((GetDmg("W", enemy)) or 0)  
    local eDmg = ((GetDmg("E", enemy)) or 0)  
    local iDmg = (50 + 20 * myHero.level) / 5
    local sDmg = 20 + 8 * myHero.level
    if ValidTarget(enemy) and enemy ~= nil and not enemy.dead and enemy.visible then
      if enemy.health < qDmg and Config.KS.killstealQ and ValidTarget(enemy, data[0].range) then
        CastQ(enemy)
      elseif enemy.health < wDmg and Config.KS.killstealW and ValidTarget(enemy, data[1].range) then
        CastW(enemy)
      elseif enemy.health < eDmg and Config.KS.killstealE and ValidTarget(enemy, data[2].range) then
        CastE(enemy)
      elseif enemy.health < iDmg and Config.KS.killstealI and ValidTarget(enemy, 600) and IReady() then
        CCastSpell(Ignite, enemy)
      elseif enemy.health < sDmg and Config.KS.killstealS and ValidTarget(enemy, 760) and SReady() then
        CCastSpell(Smite, enemy)
      end
    end
  end
end

function GetCustomTarget()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return sts:GetTarget(1000)
end

--[[ Packet Cast Helper ]]--
function CCastSpell(Spell, xPos, zPos)
  if VIP_USER and Config.misc.pc then
    Packet("S_CAST", {spellId = Spell, fromX = xPos, fromY = zPos, toX = xPos, toY = zPos}):send()
  else
    CastSpell(Spell, xPos, zPos)
  end
end

-- Credits: Da Vinci
local CastableItems = {
  Tiamat      = { Range = 400, Slot = function() return GetInventorySlotItem(3077) end,  reqTarget = false, IsReady = function() return (GetInventorySlotItem(3077) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3077)) == READY) end, Damage = function(target) return getDmg("TIAMAT", target, myHero) end},
  Hydra       = { Range = 400, Slot = function() return GetInventorySlotItem(3074) end,  reqTarget = false, IsReady = function() return (GetInventorySlotItem(3074) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3074)) == READY) end, Damage = function(target) return getDmg("HYDRA", target, myHero) end},
  Bork        = { Range = 450, Slot = function() return GetInventorySlotItem(3153) end,  reqTarget = true, IsReady = function() return (GetInventorySlotItem(3153) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3153)) == READY) end, Damage = function(target) return getDmg("RUINEDKING", target, myHero) end},
  Bwc         = { Range = 400, Slot = function() return GetInventorySlotItem(3144) end,  reqTarget = true, IsReady = function() return (GetInventorySlotItem(3144) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3144)) == READY) end, Damage = function(target) return getDmg("BWC", target, myHero) end},
  Hextech     = { Range = 400, Slot = function() return GetInventorySlotItem(3146) end,  reqTarget = true, IsReady = function() return (GetInventorySlotItem(3146) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3146)) == READY) end, Damage = function(target) return getDmg("HXG", target, myHero) end},
  Blackfire   = { Range = 750, Slot = function() return GetInventorySlotItem(3188) end,  reqTarget = true, IsReady = function() return (GetInventorySlotItem(3188) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3188)) == READY) end, Damage = function(target) return getDmg("BLACKFIRE", target, myHero) end},
  Youmuu      = { Range = 350, Slot = function() return GetInventorySlotItem(3142) end,  reqTarget = false, IsReady = function() return (GetInventorySlotItem(3142) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3142)) == READY) end, Damage = function(target) return 0 end},
  Randuin     = { Range = 500, Slot = function() return GetInventorySlotItem(3143) end,  reqTarget = false, IsReady = function() return (GetInventorySlotItem(3143) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3143)) == READY) end, Damage = function(target) return 0 end},
  TwinShadows = { Range = 1000, Slot = function() return GetInventorySlotItem(3023) end, reqTarget = false, IsReady = function() return (GetInventorySlotItem(3023) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3023)) == READY) end, Damage = function(target) return 0 end},
}
function UseItems(unit)
    if unit ~= nil then
        for _, item in pairs(CastableItems) do
            if item.IsReady() and GetDistance(myHero, unit) < item.Range then
                if item.reqTarget then
                    CastSpell(item.Slot(), unit)
                else
                    CastSpell(item.Slot())
                end
            end
        end
    end
end
-- Credits end

function ActivePred()
    local int = Config.misc.pro
    return tostring(predToUse[int])
end

function SetupHPred()
  MakeHPred("E", 2) 
end

function MakeHPred(hspell, i)
  if data[i].type == "linear" then
      if data[i].speed ~= math.huge then 
          HP:AddSpell(hspell, myHero.charName, {type = "DelayLine", range = data[i].range, speed = data[i].speed, width = 2*data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
      else
          HP:AddSpell(hspell, myHero.charName, {type = "PromptLine", range = data[i].range, width = 2*data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
      end
  elseif data[i].type == "circular" then
      if data[i].speed ~= math.huge then 
          HP:AddSpell(hspell, myHero.charName, {type = "DelayCircle", range = data[i].range, speed = data[i].speed, radius = data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
      else
          HP:AddSpell(hspell, myHero.charName, {type = "PromptCircle", range = data[i].range, radius = data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
      end
  else --Cone!
      HP:AddSpell(hspell, myHero.charName, {type = "DelayLine", range = data[i].range, speed = data[i].speed, width = data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
  end
end

local hpSpells = {Spell_Q, Spell_W, Spell_E, Spell_R}
function SetupHPredNew()
  for i=0,3 do
    hpSpells[i] = MakeHPred(i)
  end
end

function MakeHPredNew(i)
 if data[i].type == "linear" or data[i].type == "cone" or data[i].type == "circular" then 
    if data[i].type == "linear" then
        if data[i].speed ~= math.huge then 
            return HPSkillshot({type = "DelayLine", range = data[i].range, speed = data[i].speed, width = 2*data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
        else
            return HPSkillshot({type = "PromptLine", range = data[i].range, width = 2*data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
        end
    elseif data[i].type == "circular" then
        if data[i].speed ~= math.huge then 
            return HPSkillshot({type = "DelayCircle", range = data[i].range, speed = data[i].speed, radius = data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
        else
            return HPSkillshotl({type = "PromptCircle", range = data[i].range, radius = data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
        end
    else --Cone!
        return HPSkillshot({type = "DelayLine", range = data[i].range, speed = data[i].speed, width = data[i].width, delay = data[i].delay, collisionM = data[i].collision, collisionH = data[i].collision})
    end
 end
end

local str = { [_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R" }
function Predict(Target, spell, source)
  if Target == nil then return end
  if ActivePred() == "VPrediction" then
    return VPredict(Target, data[spell], source)
  elseif ActivePred() == "Prodiction" then
    return nil
  elseif ActivePred() == "DivinePred" then
    local State, Position, perc = DPredict(Target, data[spell], source)
    return Position, perc*3/100, Position
  elseif ActivePred() == "HPrediction" then
    local Position, HitChance = HPredict(Target, spell, source)
    return Position, HitChance, Position
  elseif ActivePred() == "TKPrediction" then
    return TKP:Predict(spell, Target, source) 
  end
end

function HPredict(Target, spell, source)
  return HP:GetPredict(str[spell], Target, source) 
end

function DPredict(Target, spell, source)
  local unit = DPTarget(Target)
  local col = spell.collision and 0 or math.huge
  local Spell = nil
  if spell.type == "linear" then
   Spell = LineSS(spell.speed, spell.range, spell.width, spell.delay * 1000, col)
  elseif spell.type == "circular" then
   Spell = CircleSS(spell.speed, spell.range, spell.width, spell.delay * 1000, col)
  elseif spell.type == "cone" then
   Spell = ConeSS(spell.speed, spell.range, spell.width, spell.delay * 1000, col)
  end
  return DP:predict(unit, Spell, 1.2, source)
end

function VPredict(Target, spell, source)
  if spell.type == "linear" then
    if spell.aoe then
      return VP:GetLineAOECastPosition(Target, spell.delay, spell.width, spell.range, spell.speed, source)
    else
      return VP:GetLineCastPosition(Target, spell.delay, spell.width, spell.range, spell.speed, source, spell.collision)
    end
  elseif spell.type == "circular" then
    if spell.aoe then
      return VP:GetCircularAOECastPosition(Target, spell.delay, spell.width, spell.range, spell.speed, source)
    else
      return VP:GetCircularCastPosition(Target, spell.delay, spell.width, spell.range, spell.speed, source, spell.collision)
    end
  elseif spell.type == "cone" then
    if spell.aoe then
      return VP:GetConeAOECastPosition(Target, spell.delay, spell.width, spell.range, spell.speed, source)
    else
      return VP:GetLineCastPosition(Target, spell.delay, spell.width, spell.range, spell.speed, source, spell.collision)
    end
  end
end

local colorRangeReady        = ARGB(255, 200, 0,   200)
local colorRangeComboReady   = ARGB(255, 255, 128, 0)
local colorRangeNotReady     = ARGB(255, 50,  50,  50)
local colorIndicatorReady    = ARGB(255, 0,   255, 0)
local colorIndicatorNotReady = ARGB(255, 255, 220, 0)
local colorInfo              = ARGB(255, 255, 50,  0)
local KillText = {}
local KillTextColor = ARGB(255, 216, 247, 8)
local KillTextList = {"Harass Him", "Combo Kill"}
function OnDraw()
  if Config.Drawing.QRange and QReady() then
    DrawCircle(myHero.x, myHero.y, myHero.z, data[0].range, 0x111111)
  end
  if Config.Drawing.WRange and WReady() then
    DrawCircle(myHero.x, myHero.y, myHero.z, data[1].range+data[1].width/4, 0x111111)
  end
  if Config.Drawing.ERange and EReady() then
    DrawCircle(myHero.x, myHero.y, myHero.z, data[2].range+data[2].width/4, 0x111111)
  end
  if Config.Drawing.dmgCalc then
        for i = 1, enemyCount do
            local enemy = enemyTable[i].player
            if ValidTarget(enemy) then
                local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
                local posX = barPos.x - 35
                local posY = barPos.y - 50
                -- Doing damage
                DrawText(enemyTable[i].indicatorText, 15, posX, posY, (enemyTable[i].ready and colorIndicatorReady or colorIndicatorNotReady))
               
                -- Taking damage
                DrawText(enemyTable[i].damageGettingText, 15, posX, posY + 15, ARGB(255, 255, 0, 0))
            end
        end
    end 
end

function DmgCalculations()
    if not Config.Drawing.dmgCalc then return end
    for i = 1, enemyCount do
        local enemy = enemyTable[i].player
          if ValidTarget(enemy) and enemy.visible then
            local damageAA = GetDmg("AD", enemy)
            local damageQ  = GetDmg("Q", enemy)
            local damageW  = GetDmg("W", enemy)
            local damageE  = GetDmg("E", enemy)
            local damageI  = Ignite and (GetDmg("IGNITE", enemy)) or 0
            local damageS  = Smite and (20 + 8 * myHero.level) or 0
            enemyTable[i].damageQ = damageQ
            enemyTable[i].damageW = damageW
            enemyTable[i].damageE = damageE
            enemyTable[i].damageI = damageI
            enemyTable[i].damageS = damageS
            if enemy.health < damageQ then
                enemyTable[i].indicatorText = "Q Kill"
                enemyTable[i].ready = QReady()
            elseif enemy.health < damageE then
                enemyTable[i].indicatorText = "E Kill"
                enemyTable[i].ready = EReady()
            elseif enemy.health < damageW then
                enemyTable[i].indicatorText = "W Kill"
                enemyTable[i].ready = WReady()
            elseif enemy.health < damageE + damageQ then
                enemyTable[i].indicatorText = "Q + E Kill"
                enemyTable[i].ready = EReady() and QReady()
            elseif enemy.health < damageQ + damageW then
                enemyTable[i].indicatorText = "Q + W Kill"
                enemyTable[i].ready = QReady() and WReady()
            elseif enemy.health < damageW + damageE then
                enemyTable[i].indicatorText = "W + E Kill"
                enemyTable[i].ready = WReady() and EReady()
            elseif enemy.health < damageQ + damageW + damageE then
                enemyTable[i].indicatorText = "Q + W + E Kill"
                enemyTable[i].ready = QReady() and WReady() and EReady()
            elseif enemy.health < damageAA + damageQ + damageW + damageE + damageI + damageS then
                enemyTable[i].indicatorText = "All-In Kill"
                enemyTable[i].ready = QReady() and WReady() and EReady() and IReady()
            else
                local damageTotal = damageAA + damageQ + damageW + damageE + damageI
                local healthLeft = math.round(enemy.health - damageTotal)
                local percentLeft = math.round(healthLeft / enemy.maxHealth * 100)
                enemyTable[i].indicatorText = percentLeft .. "% Harass"
                enemyTable[i].ready = QReady() or WReady() or EReady()
            end
            local enemyDamageAA = getDmg("AD", player, enemy)
            local enemyNeededAA = math.ceil(player.health / enemyDamageAA)            
            enemyTable[i].damageGettingText = enemy.charName .. " kills me with " .. enemyNeededAA .. " hits"
        end
    end
end

function GetDmg(spell, enemy) --Partially from HTTF
  if enemy == nil then
    return
  end
  
  local ADDmg = 0
  local APDmg = 0

  local Level = myHero.level
  local TotalDmg = myHero.totalDamage
  local AP = myHero.ap
  local ArmorPen = myHero.armorPen
  local ArmorPenPercent = myHero.armorPenPercent
  local MagicPen = myHero.magicPen
  local MagicPenPercent = myHero.magicPenPercent
  
  local Armor = math.max(0, enemy.armor*ArmorPenPercent-ArmorPen)
  local ArmorPercent = Armor/(100+Armor)
  local MagicArmor = math.max(0, enemy.magicArmor*MagicPenPercent-MagicPen)
  local MagicArmorPercent = MagicArmor/(100+MagicArmor)

  local QLevel, WLevel, ELevel, RLevel = myHero:GetSpellData(_Q).level, myHero:GetSpellData(_W).level, myHero:GetSpellData(_E).level, myHero:GetSpellData(_R).level

  if spell == "IGNITE" then
    return 50+20*Level
  elseif spell == "AD" then
    ADDmg = TotalDmg
  elseif spell == "Q" then
    ADDmg = 30*QLevel+1.2*TotalDmg
  elseif spell == "W" then
    APDmg = 30*WLevel+20+0.8*AP
  elseif spell == "E" then
    ADDmg = 50*ELevel+0.7*TotalDmg
  elseif spell == "R" then
    return 0
  end

  return ADDmg*(1-ArmorPercent)+APDmg*(1-MagicArmorPercent)
end