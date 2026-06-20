local core_mainmenu = require("core_mainmenu")
local lib_helpers = require("solylib.helpers")
local lib_characters = require("solylib.characters")
local lib_unitxt = require("solylib.unitxt")
local lib_items = require("solylib.items.items")
local lib_menu = require("solylib.menu")
local lib_items_list = require("solylib.items.items_list")
local lib_items_cfg = require("solylib.items.items_configuration")
local cfg = require("DF Helper.configuration")
local cfgMonsters = require("DF Helper.monsters")
cfgMonsters.m[-1] = {cate = "Default", segment = "General"}
cfgMonsters.m[-20] = {cate = "Default", segment = "Slime Origin", color = 0xFFFFFFFF, display = true}

local optionsLoaded, options = pcall(require, "DF Helper.options")
local optionsFileName = "addons/DF Helper/options.lua"

local ConfigurationWindow

local origPackagePath = package.path
package.path = './addons/DF Helper/lua-xtype/src/?.lua;' .. package.path
package.path = './addons/DF Helper/MGL/src/?.lua;' .. package.path
local xtype = require("xtype")
local mgl = require("MGL")
package.path = origPackagePath

local function SetDefaultValue(Table, Index, Value)
    Table[Index] = lib_helpers.NotNilOrDefault(Table[Index], Value)
end
local function SetValue(Table, Index, Value)
    Table[Index] = Value
end
local function convertColorToInt(Alpha,R,G,B)
    return bit.lshift(Alpha, 24) +
    bit.lshift(R, 16) +
    bit.lshift(G, 8) +
    bit.lshift(B, 0)
end

local function LoadOptions()
    if options == nil or type(options) ~= "table" then
        options = {}
    end
    -- If options loaded, make sure we have all those we need
    SetDefaultValue( options, "configurationEnableWindow", true )
    SetDefaultValue( options, "enable", true )
    SetDefaultValue( options, "maxNumTrackers", 100 )
    SetDefaultValue( options, "numTrackers", 25 )
    SetDefaultValue( options, "updateThrottle", 0 )
    SetDefaultValue( options, "server", 1 )

    SetDefaultValue( options, "customScreenResEnabled", false )
    SetDefaultValue( options, "customScreenResX", lib_helpers.GetResolutionWidth() )
    SetDefaultValue( options, "customScreenResY", lib_helpers.GetResolutionHeight() )
    SetDefaultValue( options, "customFoVEnabled", false )
    SetDefaultValue( options, "customFoV0", 86 )
    SetDefaultValue( options, "customFoV1", 87 )
    SetDefaultValue( options, "customFoV2", 88 )
    SetDefaultValue( options, "customFoV3", 89 )
    SetDefaultValue( options, "customFoV4", 90 )

    local section = "tracker"
    if options[section] == nil or type(options[section]) ~= "table" then
        options[section] = {}
    end
    SetDefaultValue( options[section], "EnableWindow", true )
    SetDefaultValue( options[section], "HideWhenMenu", false )
    SetDefaultValue( options[section], "HideWhenSymbolChat", false )
    SetDefaultValue( options[section], "HideWhenMenuUnavailable", true )
    SetDefaultValue( options[section], "FadeInTimer", false )
    SetDefaultValue( options[section], "changed", true )
    SetDefaultValue( options[section], "boxOffsetX", 0 )
    SetDefaultValue( options[section], "boxOffsetY", 0 )
    SetDefaultValue( options[section], "boxSizeX", 40 )
    SetDefaultValue( options[section], "boxSizeY", 40 )
    SetDefaultValue( options[section], "W", 271 )
    SetDefaultValue( options[section], "H", 91 )
    SetDefaultValue( options[section], "AlwaysAutoResize", true )
    SetDefaultValue( options[section], "customFontScaleEnabled", true )
    SetDefaultValue( options[section], "fontScale", 1.0 )
    SetDefaultValue( options[section], "fontDistanceToScale", 100 )
    SetDefaultValue( options[section], "fontDistanceScale", 2.0 )
    SetDefaultValue( options[section], "TransparentWindow", false )
    SetDefaultValue( options[section], "customTrackerColorEnable", true )
    SetDefaultValue( options[section], "customTrackerColorMarker", 0xFF00FFFF )
    SetDefaultValue( options[section], "customTrackerColorBackground", 0xC8000000 )
    SetDefaultValue( options[section], "customTrackerColorWindow", 0x00000000 )
    SetDefaultValue( options[section], "backgroundPosition", 0 )

    SetDefaultValue( options[section], "showNameOverride", false )
    SetDefaultValue( options[section], "showNameClosestItemsNum", 5 )
    SetDefaultValue( options[section], "showNameClosestDist", 130 )
    SetDefaultValue( options[section], "clampItemView", false )
    SetDefaultValue( options[section], "ignoreItemMaxDist", 420 )
    
    -- Initialise options with empty tables
    for id,monster in pairs(cfgMonsters.m) do
        if monster.cate then
            if options[section][id] == nil then
                options[section][id] = {}
            end
        end
    end

    local displayWidgets = {
        "name",
    }
    local function EstablishDisplayWidgets(section, id)
        local shownOptionOrderWasMissing = false
        if options[section][id].shownOptionOrder == nil then
            options[section][id].shownOptionOrder = {}
            shownOptionOrderWasMissing = true
        end
        for i=1, #displayWidgets do
            if options[section][id][displayWidgets[i]] == nil then
                options[section][id][displayWidgets[i]] = {}
            end
            if shownOptionOrderWasMissing then
                options[section][id].shownOptionOrder[i] = i
            end
        end
    end

    -- Slime Origin
    local id = -20
    EstablishDisplayWidgets(section, id)
    SetDefaultValue( options[section][id].name, "show", true )

    for id,monster in pairs(cfgMonsters.m) do
        if monster.cate then
            SetDefaultValue( options[section][id], "enabled", true )

            EstablishDisplayWidgets(section, id)
            SetDefaultValue( options[section][id].name, "show", true )
        end
    end
end
LoadOptions()

local this = {
    first = true,
}

local optionsStringBuilder = ""
local function BuildOptionsString(table, depth)
    local tabSpacing = 4
    local maxDepth = 5
    
    if not depth or depth == nil then
        depth = 0
    end
    local spaces = string.rep(" ", tabSpacing + tabSpacing * depth)
    
    --begin statement
    if depth < 1 then
        optionsStringBuilder = "return\n{\n"
    end
    --iterate over table
    for key, value in pairs(table) do
        
        local ktype = type(key)
        if ktype == "number" then
            -- check is float/double
            if key % 1 == 0 then
                key = string.format("[%i]", key)
            else
                key = string.format("[%f]", key)
            end
            
        end

        local vtype = type(value)
        if vtype == "string" then
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = \"%s\",\n", key, tostring(value))
        
        elseif vtype == "number" then
            -- check is float/double
            if value % 1 == 0 then
                optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = %i,\n", key, tostring(value))
            else
                optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = %f,\n", key, tostring(value))
            end
            
        elseif vtype == "boolean" or value == nil then
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = %s,\n", key, tostring(value))
            
        --recurse
        elseif vtype == "table" then
            if maxDepth > 5 then
                return
            end
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = {\n", key)
            BuildOptionsString(value, depth + 1)
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("},\n", key)
        end
        
    end
    --finalize statement
    if depth < 1 then
        optionsStringBuilder = optionsStringBuilder .. "}\n"
    end
end

local function SaveOptions(options)
    local file = io.open(optionsFileName, "w")
    if file ~= nil then
        BuildOptionsString(options)
        
        io.output(file)
        io.write(optionsStringBuilder)
        io.close(file)
    end
end

local playerSelfAddr = nil
local playerSelfCoords = nil
local playerSelfDirs = nil
local pCoord = nil
local cameraCoords = nil
local cameraDirs = nil
local resolutionWidth = {}
local resolutionHeight = {}
local trackerBox = {}
local trackerWindowPadding = {}
trackerWindowPadding.x = 8.0
trackerWindowPadding.y = 8.0
local screenFov = nil
local aspectRatio = nil
local eyeWorld    = nil
local eyeDir      = nil
local determinantScr = nil
local cameraZoom = nil
local lastCameraZoom = nil
local trackerWindowLookup = {}

-- camera related memory addresses
local _CameraPosX      = 0x00A48780
local _CameraPosY      = 0x00A48784
local _CameraPosZ      = 0x00A48788
local _CameraDirX      = 0x00A4878C
local _CameraDirY      = 0x00A48790
local _CameraDirZ      = 0x00A48794
local _CameraZoomLevel = 0x009ACEDC

-- memory addresses
local _PlayerArray = 0x00A94254
local _PlayerIndex = 0x00A9C4F4
local _PlayerCount = 0x00AAE168

local lua_biginteger = 4294967295 -- current compiled interpreter makes a sad panda...

local _ID = 0x1C
local _PosX = 0x38
local _PosY = 0x3C
local _PosZ = 0x40

local _EntityCount = 0x00AAE164
local _EntityArrayBasePointer = 0x7B4BA0 + 2
local _EntityArray = 0 -- obtained later from base pointer contents

local _MonsterUnitxtID = 0x378
local _MonsterHP = 0x334
local _MonsterEVP = 0x2C8

-- Special addresses for Pofuilly/Pouilly Slime
local _MonsterPofuillySlimeOriginEntityPointer = 0x3F8
local _MonsterOriginSlimePointer = 0x3C4

-- Special address for Ephinea
local _ephineaMonsterArrayPointer = 0x00B5F800
local _ephineaMonsterHPScale = 0x00B5F804

local entityAddressLookup = {}

local Timer = {}
local E1DropTimer = {}
--local E1WalkTimer = {}
local E2DropTimer = {}
local E2WalkTimer = {}
local MorfosTimer = {}
local CanabinTimer = {}
local AnimHistory = {}

local function GetMonsterData(monster)
    local ephineaMonsters = pso.read_u32(_ephineaMonsterArrayPointer)
    
    monster.id = pso.read_u16(monster.address + _ID)
    monster.unitxtID = pso.read_u32(monster.address + _MonsterUnitxtID)

    monster.HP = 0
    monster.EVP= 0
    if ephineaMonsters ~= 0 then
        monster.HP = pso.read_u32(ephineaMonsters + (monster.id * 32) + 0x04)
        monster.EVP = pso.read_u16(monster.address + _MonsterEVP)
    else
        monster.HP = pso.read_u16(monster.address + _MonsterHP)
        monster.EVP = pso.read_u16(monster.address + _MonsterEVP)
    end

    monster.posX = pso.read_f32(monster.address + _PosX)
    monster.posY = pso.read_f32(monster.address + _PosY)
    monster.posZ = pso.read_f32(monster.address + _PosZ)

    monster.name = lib_unitxt.GetMonsterName(monster.unitxtID, _Ultimate)
    monster.display = true

    if AnimHistory[monster.address] == nil then
        AnimHistory[monster.address] = pso.read_i8(monster.address + 184)
    end

    if monster.unitxtID == 26 or monster.unitxtID == 27 or 
    monster.unitxtID == 62 or monster.unitxtID == 63 or 
    monster.unitxtID == 69 or monster.unitxtID == 70 then
        if Timer[monster.address] == nil then
            Timer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8)
        end
        
        if pso.read_i8(monster.address + 0x3B8) ~= 0 then
            Timer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8)
        elseif Timer[monster.address] ~= 62 - pso.read_i8(monster.address + 0x3B8) and Timer[monster.address] > 0 then
            Timer[monster.address] = Timer[monster.address] - 1
        end
        
        if E1DropTimer[monster.address] == nil then
            E1DropTimer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8) + 46
        elseif pso.read_i8(monster.address + 184) ~= AnimHistory[monster.address] and pso.read_i8(monster.address + 184) == 1 and AnimHistory[monster.address] ~= 0 then
            E1DropTimer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8) + 46
        elseif 62 - pso.read_i8(monster.address + 0x3B8) < E1DropTimer[monster.address] then
            E1DropTimer[monster.address] = E1DropTimer[monster.address] - 1
        elseif pso.read_i8(monster.address + 0x3B8) ~= 0 then
            E1DropTimer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8)
        elseif E1DropTimer[monster.address] > 0 then
            E1DropTimer[monster.address] = E1DropTimer[monster.address] - 1
        end
        
        --if E1WalkTimer[monster.address] == nil then
        --    E1WalkTimer[monster.address] = 31 - pso.read_i8(monster.address + 0x3B8) + 46
        --elseif pso.read_i8(monster.address + 184) ~= AnimHistory[monster.address] and pso.read_i8(monster.address + 184) == 2 then
        --    E1WalkTimer[monster.address] = 31 - pso.read_i8(monster.address + 0x3B8) + 46
        --elseif pso.read_i8(monster.address + 184) == 9 then
        --    E1WalkTimer[monster.address] = 31 - pso.read_i8(monster.address + 0x3B8)
        --elseif E1WalkTimer[monster.address] > 0 then
        --    E1WalkTimer[monster.address] = E1WalkTimer[monster.address] - 1
        --end
        
        if E2DropTimer[monster.address] == nil then
            E2DropTimer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8) + 46
        elseif pso.read_i8(monster.address + 184) ~= AnimHistory[monster.address] and pso.read_i8(monster.address + 184) == 0 then
            E2DropTimer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8) + 46
        elseif 62 - pso.read_i8(monster.address + 0x3B8) < E2DropTimer[monster.address] then
            E2DropTimer[monster.address] = E2DropTimer[monster.address] - 1
        elseif pso.read_i8(monster.address + 0x3B8) ~= 0 then
            E2DropTimer[monster.address] = 62 - pso.read_i8(monster.address + 0x3B8)
        elseif E2DropTimer[monster.address] > 0 then
            E2DropTimer[monster.address] = E2DropTimer[monster.address] - 1
        end
        
        if E2WalkTimer[monster.address] == nil then
            E2WalkTimer[monster.address] = 31 - pso.read_i8(monster.address + 0x3B8) + 46
            if pso.read_i8(monster.address + 968) == 1 then
                E2WalkTimer[monster.address] = 47
            end
        elseif AnimHistory[monster.address] == 12 and pso.read_i8(monster.address + 184) == 2 then
            E2WalkTimer[monster.address] = 41
        elseif pso.read_i8(monster.address + 184) ~= AnimHistory[monster.address] and pso.read_i8(monster.address + 184) == 2 then
            E2WalkTimer[monster.address] = 31 - pso.read_i8(monster.address + 0x3B8) + 46
        elseif pso.read_i8(monster.address + 184) == 9 and pso.read_i8(monster.address + 284) == 38 then
            E2WalkTimer[monster.address] = 31 - pso.read_i8(monster.address + 0x3B8)
        elseif E2WalkTimer[monster.address] > 0 then
            E2WalkTimer[monster.address] = E2WalkTimer[monster.address] - 1
        end
    end

    if monster.unitxtID == 66 then
        if MorfosTimer[monster.address] == nil then
            MorfosTimer[monster.address] = 55 - pso.read_i8(monster.address + 0x3B8) + 46 + 25
        elseif pso.read_f32(monster.address + 1228) == 0.5 then
            MorfosTimer[monster.address] = 24
        elseif MorfosTimer[monster.address] > 0 then
            MorfosTimer[monster.address] = MorfosTimer[monster.address] - 1
        end
    end
    
    if monster.unitxtID == 28 or monster.unitxtID == 29 then
        if CanabinTimer[monster.address] == nil then
            CanabinTimer[monster.address] = 45 - pso.read_i8(monster.address + 0x3B8) + 46
        --elseif pso.read_f32(monster.address + 1228) == 0.5 then
        --    CanabinTimer[monster.address] = 24
        elseif CanabinTimer[monster.address] > 0 then
            CanabinTimer[monster.address] = CanabinTimer[monster.address] - 1
        end
    end

    AnimHistory[monster.address] = pso.read_i8(monster.address + 184)

    if monster.HP == 0 then
        Timer[monster.address] = nil
        E1DropTimer[monster.address] = nil
        --E1WalkTimer[monster.address] = nil
        E2DropTimer[monster.address] = nil
        E2WalkTimer[monster.address] = nil
        MorfosTimer[monster.address] = nil
        CanabinTimer[monster.address] = nil
    end
    
    if monster.unitxtID == 0 then
        local mParentAddress = pso.read_u32(monster.address + _MonsterOriginSlimePointer)
        if mParentAddress ~= 0 and entityAddressLookup[mParentAddress] then
            local mParent = entityAddressLookup[mParentAddress]
            local UnitxtID = pso.read_u32(mParent.address + _MonsterUnitxtID)
            if UnitxtID == 19 or UnitxtID == 20 then
                monster.slimeEntityAddress = mParent.address
                monster.isSlimeOrigin = true
                monster.name = "Slime Origin"
                monster.HP = 1
                monster.HPMax = 1
                monster.unitxtID = -20
            end
        end
    end

    return monster
end

local function computePixelCoordinates(pWorld, eyeWorld, eyeDir, determinant)

    local pRaster = mgl.vec2(0)
    local vis = -1

    local vDir = pWorld - eyeWorld
    vDir = mgl.normalize(vDir)
    local fdp = mgl.dot( eyeDir, vDir )

    --fdp must be nonzero ( in other words, vDir must not be perpendicular to angCamRot:Forward() )
    --or we will get a divide by zero error when calculating vProj below.
    if fdp == 0 then
        return pRaster,-1
    end

    --Using linear projection, project this vector onto the plane of the slice
    local ddfp = determinant/fdp
    local vProj = mgl.vec3( ddfp,ddfp,ddfp ) * vDir
    --get the up component from the forward vector assuming world yaxis (vertical axis 0,+1,0) is up
    --https://stackoverflow.com/questions/1171849/finding-quaternion-representing-the-rotation-from-one-vector-to-another/1171995#1171995
    local eyeRight = mgl.cross( eyeDir, mgl.vec3(0,1,0) )
    local eyeLeft  = mgl.cross( eyeRight, eyeDir )

    if fdp > 0.0000001 then
        vis = 1
    end
    pRaster.x =   mgl.dot(eyeRight,vProj) --0.5 * iScreenW + mgl.dot(eyeRight,vProj)
    pRaster.y = - mgl.dot(eyeLeft,vProj) --0.5 * iScreenH - mgl.dot(eyeLeft,vProj)

    return pRaster, vis
end

local function isMonsterShowEnabled(monster, section)
    if  cfgMonsters.m[monster.unitxtID] ~= nil
    and options[section][monster.unitxtID] ~= nil
    then
        if options[section][monster.unitxtID].overridden then
            if options[section][monster.unitxtID].enabled then
                return true
            end
        else -- overridden is false
            if options[section][-1].enabled then
                return true
            end
        end
    end
    return false
end


local function GetMonsterList(section)
    local monsterList = {}
    local monsterPreList = {}
    entityAddressLookup = {}

    local pIndex = pso.read_u32(_PlayerIndex)
    local pAddr = pso.read_u32(_PlayerArray + 4 * pIndex)

    -- If we don't have address (maybe warping or something)
    -- return the empty list
    if pAddr == 0 then
        return monsterList
    end

    local playerCount = pso.read_u32(_PlayerCount)
    local entityCount = pso.read_u32(_EntityCount)

    for i=0, entityCount-1, 1 do
        local addr = pso.read_u32(_EntityArray + 4 * (i + playerCount))
        monsterPreList[i] = {
            display = true,
            index = i,
            address = addr,
        }
        if addr ~= 0 then
            entityAddressLookup[addr] = monsterPreList[i]
        end
    end

    local i = 0
    while i < entityCount do
        local monster = monsterPreList[i]

        -- If we got a pointer, then read from it
        if monster.address ~= 0 then
            monster = GetMonsterData(monster)
            
            --print(string.format('%X',monster.address),monster.name, monster.unitxtID, monster.HPMax, monster.HP, monster.posX,monster.posY,monster.posZ)
            -- if monster.name == 'Nano Dragon' then
            --     print(string.format("%x",monster.address))
            -- end

            if isMonsterShowEnabled(monster, section)
            then
                monster.display = cfgMonsters.m[monster.unitxtID].display

                -- Calculate the distance between it and the player
                -- And hide the monster if its too far
                monster.pos3 = mgl.vec3(monster.posX, monster.posY, monster.posZ)
                monster.curPlayerDistance = mgl.length(monster.pos3 - pCoord)
                if monster.curPlayerDistance == nil then
                    monster.curPlayerDistance = lua_biginteger
                end

                if cfgMonsters.maxDistance ~= 0 and tDist > cfgMonsters.maxDistance then
                    monster.display = false
                end

                -- Do not show monsters that have been killed
                if monster.HP <= 0 then
                    monster.display = false
                end

                -- Get the monster's 3d position to a 2d pixel position
                if monster.display ~= false then
                    local pRaster,visible = computePixelCoordinates(monster.pos3, eyeWorld, eyeDir, determinantScr)
                    monster.screenX = pRaster.x
                    monster.screenY = pRaster.y
                    monster.screenVisDirection = visible
                else
                    monster.screenShow = false
                    monster.screenX = nil
                    monster.screenY = nil
                    monster.screenVisDirection = -1
                end

                if monster.screenVisDirection < 0 then
                    monster.screenShow = false
                else
                    monster.screenShow = true
                end

                if monster.screenShow then
                    table.insert(monsterList, monster)
                end

            end
        end
        i = i + 1
    end

    return monsterList
end

local function GetPlayerCoordinates(player)
    local x = 0
    local y = 0
    local z = 0
    if player ~= 0 then
        x = pso.read_f32(player + 0x38)
        y = pso.read_f32(player + 0x3C)
        z = pso.read_f32(player + 0x40)
    end

    return
    {
        x = x,
        y = y,
        z = z,
    }
end

local function GetPlayerDirection(player)
    local x = 0
    local z = 0
    if player ~= 0 then
        x = pso.read_f32(player + 0x410)
        z = pso.read_f32(player + 0x418)
    end
    
    return
    {
        x = x,
        z = z,
    }
end

local function getCameraZoom()
    return pso.read_u32(_CameraZoomLevel)
end

local function getCameraCoordinates()
    return
    {
        x = pso.read_f32(_CameraPosX),
        y = pso.read_f32(_CameraPosY),
        z = pso.read_f32(_CameraPosZ),
    }
end

local function getCameraDirection()
    return
    {
        x = pso.read_f32(_CameraDirX), -- -1 to 1 in x direction (west to east)
        y = pso.read_f32(_CameraDirY), -- pitch
        z = pso.read_f32(_CameraDirZ), -- -1 to 1 in z direction (north to south)
    }
end

local function clampVal(clamp, min, max)
    return clamp < min and min or clamp > max and max or clamp
end

local function Norm(Val,Min,Max)
    return (Val - Min)/(Max - Min)
end

local function Lerp(Norm,Min,Max)
    return (Max - Min) * Norm + Min
end

local function shiftHexColor(color)
    return
    {
        bit.band(bit.rshift(color, 24), 0xFF),
        bit.band(bit.rshift(color, 16), 0xFF),
        bit.band(bit.rshift(color, 8), 0xFF),
        bit.band(color, 0xFF)
    }
end

local function ARGBtoHexColor(Clr)
    return  bit.lshift(Clr.a, 24) +
            bit.lshift(Clr.r, 16) +
            bit.lshift(Clr.g, 8) +
            bit.lshift(Clr.b, 0)
end

local function HextoARGBColor(Clr)
    return
    {
        a = bit.band(bit.rshift(Clr, 24), 0xFF),
        r = bit.band(bit.rshift(Clr, 16), 0xFF),
        g = bit.band(bit.rshift(Clr, 8), 0xFF),
        b = bit.band(Clr, 0xFF)
    }
end

local function LerpColor(Norm,Color1,Color2)
	local Ctbl = {}
	Ctbl.a = Lerp(Norm,Color1.a,Color2.a)
	Ctbl.r = Lerp(Norm,Color1.r,Color2.r)
	Ctbl.g = Lerp(Norm,Color1.g,Color2.g)
	Ctbl.b = Lerp(Norm,Color1.b,Color2.b)
    return Ctbl
end


local update_delay = options.updateThrottle
local current_time = 0
local last_monster_time = 0
local cache_monster = nil
local monsterCount = 0
local lastnumTrackers = options.numTrackers
local firstLoad = true
local last_inventory_index = -1
local last_inventory_time = 0
local curFontScale = options["tracker"].customFontScaleEnabled and options["tracker"].fontScale or 1.0
local lastFontScale = curFontScale
local cache_inventory = nil
local windowTextSizes = {}
local usedWindowNameIdLookup = {}

local function sortByDistanceP(a,b)
    return a.curPlayerDistance < b.curPlayerDistance
end

local function UpdateMonsterCache(section)
    if last_monster_time + update_delay < current_time or cache_monster == nil then
        cache_monster = GetMonsterList(section)
         table.sort(cache_monster, sortByDistanceP)
        -- reassign a tracker window to its monster
        local prevTrackerWindowLookup = trackerWindowLookup
        trackerWindowLookup = {}
        local cache_monster_notracker = {}
        local function nextWindowNameId()
            local idx
            local retries = 0
            repeat
                idx = math.random(0, lua_biginteger)
                retries = retries + 1
            until not usedWindowNameIdLookup[idx] or retries > 10
            usedWindowNameIdLookup[idx] = true
            return idx
        end
        for i=1, #cache_monster, 1 do
            local monster = cache_monster[i]
            local windowNameId = prevTrackerWindowLookup[monster.id]
            if windowNameId then
                trackerWindowLookup[monster.id] = windowNameId
                monster.windowNameId = windowNameId
            else
                table.insert(cache_monster_notracker, monster)
            end
        end
        -- assign a tracker window to an monster
        for i=1, #cache_monster_notracker, 1 do
            local monster = cache_monster_notracker[i]
            local windowNameId = nextWindowNameId()
            if windowNameId then
                trackerWindowLookup[monster.id] = windowNameId
                monster.windowNameId = windowNameId
            end
        end
        last_monster_time = current_time
    end
end

local function PrintWText(wText)
    for i=1,table.getn(wText),1 do
        local clr = wText[i][2]
        if i ~= 1 then imgui.SameLine(0, 0) end
        if clr then
            imgui.TextColored(clr[2], clr[3], clr[4], clr[1], wText[i][1])
        else
            imgui.Text(wText[i][1])
        end
    end
end

local function getUnWText(wText)
    local str = ""
    for i=1,table.getn(wText),1 do
        str = str .. wText[i][1]
    end
    return str
end

local function getWText(wText,Default)
    if wText then
        return wText
    else
        return { {Default, nil} }
    end
end

local function PresentTargetMonster(monster, section)
    if monster ~= nil then
        if playerSelfAddr == 0 then return end
        
        local moptions
        if  options[section][monster.unitxtID]
            and options[section][monster.unitxtID].overridden
        then
            moptions = options[section][monster.unitxtID]
        else -- not overridden, so use default
            moptions = options[section][-1]
        end

        local function showName_Text(order)
            if options[section][monster.unitxtID].enabled then
                local mName = "          O          "
                
                if monster.unitxtID == -20 then
                    mName = "          S          "
                end

                imgui.SameLine(0,0)
                if not options[section].FadeInTimer then
                    if Timer[monster.address] ~= nil and (
                    monster.unitxtID == 26 or monster.unitxtID == 27 or 
                    monster.unitxtID == 62 or monster.unitxtID == 63 or 
                    monster.unitxtID == 69 or monster.unitxtID == 70
                    ) and (pso.read_i8(monster.address + 184) == 0 or pso.read_i8(monster.address + 184) == 1) then
                        mName = "          " .. Timer[monster.address] .. "          "
                    end
                else
                    if E1DropTimer[monster.address] ~= nil and (monster.unitxtID == 26 or monster.unitxtID == 27) and (pso.read_i8(monster.address + 184) == 0 or pso.read_i8(monster.address + 184) == 1) then
                        if E1DropTimer[monster.address] > 0 then
                            mName = "          " .. E1DropTimer[monster.address] .. "          "
                        end
                    end
                    --if E1WalkTimer[monster.address] ~= nil and pso.read_i8(monster.address + 0x3B8) ~= 0 and (monster.unitxtID == 26 or monster.unitxtID == 27) and (pso.read_i8(monster.address + 184) == 2 or pso.read_i8(monster.address + 184) == 9) then
                    --    mName = "          " .. E1WalkTimer[monster.address] .. "          "
                    --end
                    if E2DropTimer[monster.address] ~= nil and (monster.unitxtID == 62 or monster.unitxtID == 63 or monster.unitxtID == 69 or monster.unitxtID == 70) and pso.read_i8(monster.address + 184) == 0 then
                        if E2DropTimer[monster.address] > 0 then
                            mName = "          " .. E2DropTimer[monster.address] .. "          "
                        end
                    end
                end
                if E2WalkTimer[monster.address] ~= nil and (monster.unitxtID == 62 or monster.unitxtID == 63 or monster.unitxtID == 69 or monster.unitxtID == 70) and (pso.read_i8(monster.address + 184) == 2 or pso.read_i8(monster.address + 184) == 9) then
                    if E2WalkTimer[monster.address] > 0 then
                        mName = "          " .. E2WalkTimer[monster.address] .. "          "
                    end
                end
                if MorfosTimer[monster.address] ~= nil and monster.unitxtID == 66 then
                    if MorfosTimer[monster.address] > 0 then
                        mName = "          " .. MorfosTimer[monster.address] .. "          "
                    end
                end
                if CanabinTimer[monster.address] ~= nil and (monster.unitxtID == 28 or monster.unitxtID == 29) then
                    if CanabinTimer[monster.address] > 0 then
                        mName = "          " .. CanabinTimer[monster.address] .. "          "
                    end
                end
                -- moptions.name.fontScale fontDistanceToScale
                -- monster.curPlayerDistance
                imgui.SetWindowFontScale(curFontScale * math.max(1, 1 + options[section].fontDistanceScale * (options[section].fontDistanceToScale - monster.curPlayerDistance)/100))
                --imgui.Text(math.max(1, (100 - monster.curPlayerDistance)/100))
                --imgui.Text(1 + (100 - monster.curPlayerDistance)/100)
                imgui.Text("")
                local tSizex, tSizeh = imgui.CalcTextSize("          ")
                local xWin, yWin = imgui.GetWindowPos()
                local yCur = imgui.GetCursorPosY()
                local NameSize = imgui.CalcTextSize(mName)
                local CanabinEVP = {109, 100, 222, 137, 380, 202, 706, 532}
                local CanabinRing = false
                for i = 1, #CanabinEVP do
                    if monster.EVP == CanabinEVP[i] then
                        CanabinRing = true
                    end
                end
                if monster.unitxtID == 28 and CanabinRing then
                else
                    imgui.AddCircleFilled(xWin+8.5+NameSize/2, yWin+yCur+tSizeh/2+2-options[section].backgroundPosition, tSizeh/2+3, options[section].customTrackerColorBackground, 20)
                    lib_helpers.TextC(true, options[section].customTrackerColorMarker, mName)
                end
                --imgui.Text(pso.read_f32(monster.address + 1228)) --Morfos Timer
                --imgui.Text(pso.read_i8(monster.address + 184)) --Animation Index
                --imgui.Text(pso.read_i8(monster.address + 284)) --E2 Sinow Untargetable
                --imgui.Text(pso.read_i8(monster.address + 968)) --E2 Sinow Invisibility
                --imgui.Text(pso.read_i8(monster.address + 0x3B8)) --Animation Timer
                --imgui.Text(pso.read_i8(monster.address + 0x3C0))
                --imgui.Text(monster.EVP)
                --imgui.Columns(40)
                --for i = 1, 40, 1 do
                --    imgui.SetColumnOffset(i, (i - 1) * 30)
                --end
                --for i = 800, 1600, 1 do
                --    imgui.Text(pso.read_i8(monster.address + i))
                --    imgui.NextColumn()
                --end
                return true
            end
            return false
        end

        monster_shown_options = {
            showName_Text,
        }

        local showOrder = 1
        for i=1, #monster_shown_options do
            local wasShown = monster_shown_options[moptions.shownOptionOrder[i]](showOrder)
            if wasShown then 
                showOrder = showOrder + 1
            end
        end

    end
end

local function calcScreenResolutions(section, forced)
    if forced or not resolutionWidth.val or not resolutionHeight.val then
        if options.customScreenResEnabled then
            resolutionWidth.val          = options.customScreenResX
            resolutionHeight.val         = options.customScreenResY
        else
            resolutionWidth.val          = lib_helpers.GetResolutionWidth()
            resolutionHeight.val         = lib_helpers.GetResolutionHeight()
        end
        aspectRatio                      = resolutionWidth.val / resolutionHeight.val
        resolutionWidth.half             = resolutionWidth.val * 0.5
        resolutionHeight.half            = resolutionHeight.val * 0.5
        resolutionWidth.clampRescale     = resolutionWidth.val  * 1
        resolutionHeight.clampRescale    = resolutionHeight.val * 1

        trackerBox.sizeX                 = options[section].boxSizeX
        trackerBox.sizeHalfX             = options[section].boxSizeX * 0.5
        trackerBox.sizeY                 = options[section].boxSizeY
        trackerBox.sizeHalfY             = options[section].boxSizeY * 0.5
        trackerBox.offsetX               = options[section].boxOffsetX
        trackerBox.offsetY               = options[section].boxOffsetY

        resolutionWidth.clampBoxLowest   = -resolutionWidth.half  + trackerBox.sizeHalfX
        resolutionWidth.clampBoxHighest  =  resolutionWidth.half  - trackerBox.sizeHalfX
        resolutionHeight.clampBoxLowest  = -resolutionHeight.half + trackerBox.sizeHalfY + 2
        resolutionHeight.clampBoxHighest =  resolutionHeight.half - trackerBox.sizeHalfY - 2
    end
end
local function calcScreenFoV(section, forced)

    if not aspectRatio or not cameraZoom or not resolutionHeight.val then
        cameraZoom        = getCameraZoom()
        calcScreenResolutions(section, forced)
    end

    if forced or cameraZoom ~= lastCameraZoom or cameraZoom == nil then
        if options.customFoVEnabled then
            if     cameraZoom == 0 then
                screenFov = math.rad( options.customFoV0 )
            elseif cameraZoom == 1 then
                screenFov = math.rad( options.customFoV1 )
            elseif cameraZoom == 2 then
                screenFov = math.rad( options.customFoV2 )
            elseif cameraZoom == 3 then
                screenFov = math.rad( options.customFoV3 )
            elseif cameraZoom == 4 then
                screenFov = math.rad( options.customFoV4 )
            else
                screenFov = 69 -- a good guess
            end
        else
            screenFov = math.rad( 
                math.deg( 
                    2*math.atan(0.56470588 * aspectRatio) -- 0.56470588 is 768/1360
                ) - (cameraZoom-1) * 0.600 - clampVal(cameraZoom,0,1) * 0.300 -- the constant here should work for most to all aspect ratios between 1.25 to 1.77, gud enuff.
            ) 
        end
        determinantScr = aspectRatio * 3 * resolutionHeight.val / ( 6 * math.tan( 0.5 * screenFov ) )
        lastCameraZoom = CameraZoom
    end
end


local function present()
    local section = "tracker"

    -- If the addon has never been used, open the config window
    -- and disable the config window setting
    
    if options.configurationEnableWindow then
        ConfigurationWindow.open = true
        options.configurationEnableWindow = false
        SaveOptions(options)
    end
    ConfigurationWindow.Update()
    
    if ConfigurationWindow.changed then
        ConfigurationWindow.changed = false
        if options.numTrackers > lastnumTrackers then
            LoadOptions()
            lastnumTrackers = options.numTrackers
        end

        if options[section].customFontScaleEnabled then
            curFontScale = options[section].fontScale
        else
            curFontScale = 1.0
        end
        if lastFontScale ~= curFontScale then
            lastFontScale = curFontScale
            windowTextSizes = {}
        end
        calcScreenResolutions(section, true)
        calcScreenFoV(section, true)
        SaveOptions(options)
        -- Update the delay too
        update_delay = options.updateThrottle
    end

    -- Global enable here to let the configuration window work
    if options.enable == false then
        return
    end

    --- Update timer for update throttle
    current_time = pso.get_tick_count()
-- --needed?
-- local myFloor = lib_characters.GetCurrentFloorSelf()
-- --needed?
    cameraZoom        = getCameraZoom()
    calcScreenResolutions(section)
    calcScreenFoV(section)
    playerSelfAddr    = lib_characters.GetSelf()
    playerSelfCoords  = GetPlayerCoordinates(playerSelfAddr)
    playerSelfDirs    = GetPlayerDirection(playerSelfAddr)
    pCoord            = mgl.vec3(playerSelfCoords.x,playerSelfCoords.y,playerSelfCoords.z)
    cameraCoords      = getCameraCoordinates()
    cameraDirs        = getCameraDirection()
    eyeWorld          = mgl.vec3(cameraCoords.x, cameraCoords.y, cameraCoords.z)
    eyeDir            = mgl.vec3(  cameraDirs.x,   cameraDirs.y,   cameraDirs.z)

    if _EntityArray == 0 then
        -- Get the address of the entity array from one of the instructions that references it.
        -- Works on base client and on a client patched with a different array.
        _EntityArray = pso.read_u32(_EntityArrayBasePointer)
    end

    UpdateMonsterCache(section)
    monsterCount      = table.getn(cache_monster)

    local monsterIdx = 0
    local windowParams = { "NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings", "AlwaysAutoResize" }

    for i=1, options.numTrackers, 1 do
        monsterIdx = monsterIdx + 1
        if monsterIdx > options.numTrackers or monsterIdx > monsterCount or monsterCount < 1 then break end

        if (options[section].EnableWindow == true)
            and (options[section].HideWhenMenu == false or lib_menu.IsMenuOpen() == false)
            and (options[section].HideWhenSymbolChat == false or lib_menu.IsSymbolChatOpen() == false)
            and (options[section].HideWhenMenuUnavailable == false or lib_menu.IsMenuUnavailable() == false)
        then
            local monster = cache_monster[monsterIdx]
            --print(monster.HP, monster.HPMax, monster.name, monster.index, monster.screenShow )

            if cache_monster[monsterIdx].screenShow then

                if options[section].customTrackerColorEnable == true then
                    local FrameBgColor  = shiftHexColor(options[section].customTrackerColorBackground)
                    local WindowBgColor = shiftHexColor(options[section].customTrackerColorWindow)
                    local TrackerColor  = shiftHexColor(options[section].customTrackerColorMarker)
                    imgui.PushStyleColor("ChildWindowBg", FrameBgColor[2]/255, FrameBgColor[3]/255,  FrameBgColor[4]/255,  FrameBgColor[1]/255)
                    imgui.PushStyleColor("WindowBg",     WindowBgColor[2]/255, WindowBgColor[3]/255, WindowBgColor[4]/255, WindowBgColor[1]/255)
                    imgui.PushStyleColor("Border",        TrackerColor[2]/255, TrackerColor[3]/255,  TrackerColor[4]/255,  TrackerColor[1]/255)
                end

                if options[section].TransparentWindow == true then
                    imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
                end

                local textC = getWText(cache_monster[monsterIdx].wName, cache_monster[monsterIdx].name)
                local textP = getUnWText(textC)
                if options[section].customFontScaleEnabled then -- get text width and height for every item name text
                    local tx, ty
                    if not windowTextSizes[textP] then
                        if imgui.Begin( "##DF Helper - FontDummy",
                            nil, { "NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings" } )
                        then
                            imgui.SetWindowFontScale(curFontScale)
                            tx, ty = imgui.CalcTextSize(textP)
                            windowTextSizes[textP] = {
                                x = tx,
                                y = ty,
                            }
                        end
                        imgui.End()
                    end
                else
                    if not windowTextSizes[textP] then
                        tx, ty = imgui.CalcTextSize(textP)
                        windowTextSizes[textP] = {
                            x = tx,
                            y = ty,
                        }
                    end
                end

                local wx, wy
                local tx = windowTextSizes[textP].x
                local ty = windowTextSizes[textP].y
                local tyh = ty * 0.5
                local wPadding = 6
                local wPaddingh = wPadding * 0.5 - 2
                local wPaddingd = wPadding * 2

                if options[section].W < 1 or options[section].AlwaysAutoResize then
                    wx = clampVal(tx, trackerBox.sizeX, tx) + wPadding + 1
                else
                    wx = options[section].W
                end
                if options[section].H < 1 or options[section].AlwaysAutoResize then
                    wy = ty + trackerBox.sizeY + wPaddingd + 4
                else
                    wy = options[section].H
                end

                local sx, sy
                sx = cache_monster[monsterIdx].screenX + wPaddingh
                sy = cache_monster[monsterIdx].screenY + tyh
                if options[section].clampItemView then
                    sx = clampVal(  sx, 
                                    resolutionWidth.clampBoxLowest, resolutionWidth.clampBoxHighest )
                    sy = clampVal(  sy,
                                    resolutionHeight.clampBoxLowest + tyh, resolutionHeight.clampBoxHighest - tyh)
                end

                
                --local windowName = "DF Helper - Hud" .. cache_monster[monsterIdx].windowNameId
                imgui.PushStyleVar_2("WindowPadding", trackerWindowPadding.x, trackerWindowPadding.y)
                local windowName = "DF Helper - Hud"  .. string.format("%x",cache_monster[monsterIdx].windowNameId)
                if imgui.Begin( windowName,
                    nil, windowParams )
                then
                    imgui.SetWindowFontScale(curFontScale)
                    PresentTargetMonster(cache_monster[monsterIdx], section)
                    local wx, wy = imgui.GetWindowSize()
                    local ps =  lib_helpers.GetPosBySizeAndAnchor( sx, sy, wx, wy, 5 )
                    imgui.SetWindowPos( windowName, ps[1], ps[2]-wy/2, "Always" )
                    --PresentBoxTracker(cache_monster[monsterIdx],section,monsterIdx)
                end
                imgui.End()
                imgui.PopStyleVar()

                if options[section].customTrackerColorEnable == true then
                    imgui.PopStyleColor()
                    imgui.PopStyleColor()
                    imgui.PopStyleColor()
                end
    
                if options[section].TransparentWindow == true then
                    imgui.PopStyleColor()
                end
    
                options[section].changed = false

            end
        end
        if monsterIdx>=monsterCount then
            break
        end
    end
    firstLoad = false
end

local function init()
    ConfigurationWindow = cfg.ConfigurationWindow(options)

    local function mainMenuButtonHandler()
        ConfigurationWindow.open = not ConfigurationWindow.open
    end

    core_mainmenu.add_button("DF Helper", mainMenuButtonHandler)

    return
    {
        name = "DF Helper",
        version = "0.1",
        author = "X9Z0.M2 & Lilyzavoqth",
        description = "Shows floor position of enemies to help DF positioning",
        present = present,
    }
end

return
{
    __addon =
    {
        init = init
    }
}
