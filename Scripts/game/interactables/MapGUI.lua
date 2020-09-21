--MAP GUI BLOCK--
dofile( "$SURVIVAL_DATA/Scripts/tools/Map.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_constants.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/ElevatorManager.lua"  )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/RespawnManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/UnitManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/Timer.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_units.lua" )
dofile( "$SURVIVAL_DATA/Scripts/WayPoints/map_satellite/launch.lua" )
dofile( "$SURVIVAL_DATA/Scripts/WayPoints/data.lua" )
dofile( "$SURVIVAL_DATA/Scripts/SurvivalPlayer.lua" )


MapGUI = class( nil )
MapGUI.HasBackedUp = false
local MapLevel = 0
local WasHit = false
MapGUI.GuiIsActive = false
local SubGuiIsOn = {}
local CamMove = sm.vec3.new(0,0,0)
MapGUI.Hidegui = sm.gui.createSeatGui()
local Color = 3
local Dist = 10
local WisOn = false
local AisOn = false
local SisOn = false
local DisOn = false
local CountForIcon = 0
local CountForIconBool = false
local boolToNumber={ [true]=1, [false]=0 }
local ToolQuantity=0
MapGUI.PlayerName = ""
MapGUI.SatelliteLaunched = false
MapGUI.SatelliteStage = 0
MapGUI.LaunchLocation = nil
MapGUI.LaunchEffect = nil
MapGUI.LaunchParticle0 = nil
MapGUI.LaunchParticle = nil
MapGUI.LaunchParticle1 = nil
MapGUI.LaunchParticle2 = nil
local IsTaken = false
MapGUI.KickedOut = false
MapGUI.isInOverWorld = true
MapGUI.ButtonHasBeenCalled = false

MapGUI.Levels = {
	["L1"] = { maxConnections = 2, upgrade = L2, cost = 1, title = "LEVEL 1", unlock = { Satellites = "+1", Distance="+250" }, zoomMax = 5 },
	["L2"] = { maxConnections = 4, upgrade = L3, cost = 2, title = "LEVEL 2", unlock = { Satellites = "+2", Distance="+500" }, zoomMax = 7 },
	["L3"] = { maxConnections = 6, upgrade = L4, cost = 4, title = "LEVEL 3", unlock = { Satellites = "+4", Distance="+750" }, zoomMax = 10 },
	["L4"] = { maxConnections = 8, upgrade = L5, cost = 5, title = "LEVEL 4", unlock = { Satellites = "+5", Distance="+1,000" }, zoomMax = 12 },
	["L5"] = { maxConnections = 10, title = "LEVEL 5", zoomMax = 14 }
}

function EmergencyDestroy( player )
	if MapGUI.PlayerName == player then
		if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() == nil then
			if sm.localPlayer.getPlayer():getCharacter() ~= nil then
				sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( nil )
			end
			if MapGUI.Hidegui ~= nil then
				MapGUI.Hidegui:destroy()
			end
			CancelMap( self, {name = MapGUI.PlayerName } )
			MapGUI.GuiIsActive = false
		end
	end
end


function MapGUI.client_onDestroy( self )
	
end

function SetSavedMapLevel( level )
	MapLevel = level
end


function GetMapLevel( self )
	return MapLevel+1
end


function MapGUI.client_onCreate(self)
	SubGuiIsOn[1] = false
	SubGuiIsOn[2] = false
	SubGuiIsOn[3] = false
	SubGuiIsOn[4] = false
	SubGuiIsOn[5] = false
	self.gui = nil
	IsTaken = false
end

function MapGUI.client_onInteract(self, char, active)

end

-----Global Functions-----------


function cl_MapGuiOn( self, tool, playerName, isInOverWorld)
	if IsTaken == false then
		if playerName == sm.localPlayer.getPlayer():getName() then
			if tool == nil then
				ToolQuantity = 999999
				MapLevel = 4
			else
				ToolQuantity = tool
			end
			MapGUI.PlayerName = playerName
			WasHit = true
			MapGUI.isInOverWorld = isInOverWorld
			MapGUI.GuiIsActive = true
			MapGUI.Hidegui = sm.gui.createSeatGui()
			MapGUI.Hidegui:open()
			MapGUI.HasBackedUp = false
			MapGUI:client_onFixedUpdate()
			IsTaken = true
		end
	end
end

function MapGUI.client_showMessage( self, params )
	sm.gui.chatMessage( params )
end

-----Global Functions End-----------

function MapGUI.sv_Exit( self )
	sm.gui.exitToMenu()
end

function SetMapGuiKickedOut( bool )
	MapGUI.KickedOut = bool
end

function MapGUI.client_onAction(self, input, active)
	local allIsFalse = false
	for _,v in pairs(SubGuiIsOn) do
		if not v then 
			allIsFalse = true
		else
			allIsFalse = false
			break
		end
	end
	if MapGUI.SatelliteLaunched then
		active = false
	end
	if (input == 19 and allIsFalse and not MapGUI.SatelliteLaunched) then
		MapGUI.KickedOut = false
		if sm.localPlayer.getPlayer():getCharacter() ~= nil then
			sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( nil )
		end
		if MapGUI.Hidegui ~= nil then
			MapGUI.Hidegui:destroy()
		end
		CancelMap( self, {name = MapGUI.PlayerName } )
		MapGUI.GuiIsActive = false
		WisOn = false
		AisOn = false
		SisOn = false
		DisOn = false
	end
	if MapGUI.isInOverWorld then
		if (input == 20) then
			local tmpVal = ScrollZoom()
			if tmpVal > 2 then
				tmpVal= tmpVal - 1
			end
			ScrollChanged(tmpVal)
		end
		if (input == 21) then
			local tmpVal = ScrollZoom()
			if tmpVal < 15 and (tmpVal+1) <= MapGUI.Levels["L"..(MapLevel+1)].zoomMax then
				tmpVal= tmpVal +1
			end
			ScrollChanged(tmpVal)
		end
		if (input == 5) and allIsFalse and MapGUI.ButtonHasBeenCalled == false then
			self:cl_UpgradeCreate()
			MapGUI.ButtonHasBeenCalled = true
		elseif (input == 5) and SubGuiIsOn[1] == true and not active then
			self:cl_onGuiClosed()
			SubGuiIsOn[1] = false
		elseif (input == 5) and allIsFalse and not active then
			SubGuiIsOn[1] = true
			MapGUI.ButtonHasBeenCalled = false
		end
		if (input == 6) and active and allIsFalse and MapGUI.ButtonHasBeenCalled == false then
			self:cl_setupUiCreate()
			MapGUI.ButtonHasBeenCalled = true
		elseif (input == 6) and SubGuiIsOn[2] == true and not active then
			self:cl_onGuiClosed()
			SubGuiIsOn[2] = false
		elseif (input == 6) and allIsFalse and not active then
			SubGuiIsOn[2] = true
			MapGUI.ButtonHasBeenCalled = false
		end
		if (input == 7) and active and allIsFalse and MapGUI.ButtonHasBeenCalled == false then
			self:cl_setupUiDestroy()
			MapGUI.ButtonHasBeenCalled = true
		elseif (input == 7) and SubGuiIsOn[3] == true and not active then
			self:cl_onGuiClosed()
			SubGuiIsOn[3] = false
		elseif (input == 7) and allIsFalse and not active then
			SubGuiIsOn[3] = true
			MapGUI.ButtonHasBeenCalled = false
		end
		if (input == 8) and active and MapGUI.ButtonHasBeenCalled == false and allIsFalse then
			self:cl_setupUiDestroyAll()
			MapGUI.ButtonHasBeenCalled = true
		elseif (input == 8) and SubGuiIsOn[4] == true and not active then
			self:cl_onGuiClosed()
			SubGuiIsOn[4] = false
		elseif (input == 8) and allIsFalse and not active then
			SubGuiIsOn[4] = true
			MapGUI.ButtonHasBeenCalled = false
		end
		if (input == 9) and allIsFalse and active and MapGUI.ButtonHasBeenCalled == false then
			self:cl_selectViewRange()
			MapGUI.ButtonHasBeenCalled = true
		elseif (input == 9) and SubGuiIsOn[5] == true and not active then
			self:cl_onGuiClosed()
			SubGuiIsOn[5] = false
		elseif (input == 9) and allIsFalse and not active then
			SubGuiIsOn[5] = true
			MapGUI.ButtonHasBeenCalled = false
		end
		if input == 10 and active and GetGameMode() then
			SubGuiIsOn[6] = true
			tp_player(true)
		elseif GetGameMode() then
			SubGuiIsOn[6] = false
		end
		if (input == 1 and active) then
			SisOn = true
		elseif (input == 1 and not active) then
			SisOn = false
		end
		if (input == 2 and active) then
			WisOn = true
		elseif (input == 2 and not active) then
			WisOn = false
		end
		if (input == 3 and active) then
			AisOn = true
		elseif (input == 3 and not active) then
			AisOn = false
		end
		if (input == 4 and active) then
			DisOn = true
		elseif (input == 4 and not active) then
			DisOn = false
		end
	end
	return true
end

--Client function called every tick (40 times per second) that is only used to call the cl_camMove function
function MapGUI.client_onFixedUpdate( self, dt )
	if MapGUI.GuiIsActive then
		if GetGameMode() and SubGuiIsOn[6] == nil then
			SubGuiIsOn[6] = false
		end
		for i=1, 10 do
			if SubGuiIsOn[i] ~= nil then
				MapGUI.Hidegui:setGridItem( "ButtonGrid", i-1, { 
					["itemId"] = "d0afb527-8ea1-4a5a-a907-d847900458a"..i,
					["active"] = SubGuiIsOn[i]
				})
			else
				MapGUI.Hidegui:setGridItem( "ButtonGrid", i-1, nil)
			end
		end
	end
	if MapGUI.GuiIsActive then
		self:GetWayData()
	end
	if MapGUI.KickedOut then
		MapGUI.KickedOut = false
		if sm.localPlayer.getPlayer():getCharacter() ~= nil then
			sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( nil )
		end
		if MapGUI.Hidegui ~= nil then
			MapGUI.Hidegui:destroy()
		end
		CancelMap( self, {name = MapGUI.PlayerName } )
		MapGUI.GuiIsActive = false
		WisOn = false
		AisOn = false
		SisOn = false
		DisOn = false
	end
	if MapGUI.PlayerName == sm.localPlayer.getPlayer():getName() then
		if CountForIconBool and not MapGUI.SatelliteLaunched and SubGuiIsOn[1] and self.gui ~= nil then
			CountForIcon = CountForIcon+1
			if CountForIcon >= 2 then
				self.gui:setImage( "Level", "$SURVIVAL_DATA/Scripts/WayPoints/Map/level-"..tostring(MapLevel+1)..".png" )
				CountForIconBool = false
				CountForIcon = 0
			end
		end
		CamMove = sm.vec3.new(boolToNumber[WisOn] + -boolToNumber[SisOn], boolToNumber[AisOn] + -boolToNumber[DisOn], 0)
		MoveCamera(self, CamMove, MapGUI.PlayerName)
		if WasHit and MapGUI.GuiIsActive then
			sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( self.interactable )
		end
	else
		CountForIconBool = false
		MapGUI.GuiIsActive = false
		WasHit = false
	end
	if sm.localPlayer.getPlayer() and not MapGUI.HasBackedUp then
		if sm.localPlayer.getPlayer():getCharacter() ~= nil then
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				SetBackUp( sm.localPlayer.getPlayer() )
				MapGUI.HasBackedUp = true
			end
		end
	end
	if MapGUI.SatelliteLaunched then
		if MapGUI.LaunchEffect ~= nil then
			MapGUI.LaunchEffect:stop()
		end
		local effect_location = nil
		local rotation = sm.quat.new(0, 0.7071068 , 0.7071068, 0)
		local pos1 = nil
		MapGUI.SatelliteStage = MapGUI.SatelliteStage + 1
		if MapGUI.SatelliteStage < 250 then
			if MapGUI.SatelliteStage == 1 then
				AnimIsOn(true, sm.localPlayer.getPlayer():getName())
			end
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				ToggleToggle(false, sm.localPlayer.getPlayer():getName())
			end
			sm.camera.setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, -20, 20 ))
			local angle = (MapGUI.LaunchLocation.z+(MapGUI.SatelliteStage/1.5)+30)
			sm.camera.setDirection(sm.vec3.new( 0, 90, angle))
			MapGUI.LaunchEffect:setPosition(MapGUI.LaunchLocation + sm.vec3.new(0,0,MapGUI.SatelliteStage/2))
			MapGUI.LaunchEffect:start()
			effect_location = MapGUI.LaunchLocation + sm.vec3.new(0,0,(MapGUI.SatelliteStage/2))
		elseif MapGUI.SatelliteStage < 400 then
			sm.camera.setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, 1.3, ((MapGUI.SatelliteStage/2)*3)+2) )
			sm.camera.setDirection(sm.vec3.new( 0, 0, -90))
			MapGUI.LaunchEffect:setPosition(MapGUI.LaunchLocation + sm.vec3.new(0,0,MapGUI.SatelliteStage/2)*3)
			MapGUI.LaunchEffect:start()
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				ToggleToggle(true, sm.localPlayer.getPlayer():getName())
			end
			effect_location = MapGUI.LaunchLocation + sm.vec3.new( 0, 0, (MapGUI.SatelliteStage/2)*3)
		elseif MapGUI.SatelliteStage < 600 then
			sm.camera.setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, -25, (1400)-7) )
			sm.camera.setDirection(sm.vec3.new( 0, 90, 20))
			rotation = sm.quat.new( -(MapGUI.SatelliteStage/5000), 0.7071068 - (MapGUI.SatelliteStage/10000), 0.7071068 + (MapGUI.SatelliteStage/10000), -(MapGUI.SatelliteStage/5000) )
			MapGUI.LaunchEffect:setRotation(rotation)
			MapGUI.LaunchEffect:setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1352.08 + (MapGUI.SatelliteStage/50)*4))
			MapGUI.LaunchEffect:start()
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				ToggleToggle(false, sm.localPlayer.getPlayer():getName())
			end
			effect_location = MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1352.08 + (MapGUI.SatelliteStage/50)*4)
		elseif MapGUI.SatelliteStage < 800 then
			sm.camera.setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, -25, (1400)-7) )
			sm.camera.setDirection(sm.vec3.new( 0, 90, 20))
			rotation = sm.quat.new( -0.1198 , 0.5339154 - (MapGUI.SatelliteStage-600)/50, 0.77423 + (MapGUI.SatelliteStage-600)/50, -0.1198 )
			MapGUI.LaunchEffect:setRotation(rotation)
			MapGUI.LaunchEffect:setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1376.04 + (MapGUI.SatelliteStage/100)*4))
			MapGUI.LaunchEffect:start()
			pos1 = MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1376.04 + ((MapGUI.SatelliteStage/100)*4))
			effect_location = MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1376.04 + (MapGUI.SatelliteStage/100)*4)
		elseif MapGUI.SatelliteStage < 950 then
			sm.camera.setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, -25, (1400)-7) )
			sm.camera.setDirection(sm.vec3.new( 0, 90, 20))
			MapGUI.LaunchEffect:setPosition(MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1408 ))
			MapGUI.LaunchEffect:start()
			pos1 = (MapGUI.LaunchLocation + sm.vec3.new( 0, 0, 1408 ))
		end
		if MapGUI.SatelliteStage < 350 then
			MapGUI.LaunchParticle1 = sm.particle.createParticle("5_thruster_afterburner_startup_lvl5", effect_location, rotation, sm.color.new(0, 0, 0))
			MapGUI.LaunchParticle2 = sm.particle.createParticle("5_thruster_afterburner_BurstThrust_lvl5", effect_location, rotation, sm.color.new(0, 0, 0))
			MapGUI.LaunchParticle:setPosition(effect_location)
			MapGUI.LaunchParticle0:setPosition(effect_location)
			rotation = sm.quat.new( 0, 1, 0, 0 )
			MapGUI.LaunchParticle:setRotation(rotation)
			sm.audio.play("Character wind", (sm.camera.getPosition()+sm.vec3.new(0,0,15)))
		elseif pos1 ~= nil or effect_location ~= nil then
			local location = nil
			if pos1 == nil then
				location = effect_location
			else
				location = pos1
			end
			local rotation2 = sm.quat.new(sm.quat.getX(rotation), sm.quat.getY(rotation)+0.7071068, sm.quat.getZ(rotation), sm.quat.getW(rotation)+0.7071068)
			MapGUI.LaunchParticle:setPosition(location)
			MapGUI.LaunchParticle:setRotation(rotation2)
			MapGUI.LaunchParticle0:setPosition(location)
			MapGUI.LaunchParticle0:setRotation(rotation2)
			MapGUI.LaunchParticle:setParameter("velocity", 25)
			MapGUI.LaunchParticle:setParameter("radius", 0.01)
			MapGUI.LaunchParticle:setParameter("power", 200)
			MapGUI.LaunchParticle:setParameter("intensity", 0.001)
			MapGUI.LaunchParticle0:setParameter("velocity", 25)
			MapGUI.LaunchParticle0:setParameter("radius", 0.01)
			MapGUI.LaunchParticle0:setParameter("power", 200)
			MapGUI.LaunchParticle0:setParameter("intensity", 0.001)
		end
		if MapGUI.SatelliteStage >= 900 then
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				ToggleToggle(true, sm.localPlayer.getPlayer():getName())
			end
			MapGUI.SatelliteStage = 0
			MapGUI.LaunchLocation = nil
			MapGUI.SatelliteLaunched = false
			sm.camera.setDirection(sm.vec3.new( 0, 0, -90))
			MapGUI.LaunchParticle:stop()
			MapGUI.LaunchParticle0:stop()
			MapGUI.LaunchEffect:stop()
			CrossHair( self, 1 )
			AnimIsOn(false, sm.localPlayer.getPlayer():getName())
		end
	end
end

---------GUI-Modules--------------------------------------

 function MapGUI.cl_setupUiCreate( self )
	self.gui = sm.gui.createChallengeMessageGui()
	self.gui:setText( "Title", "WAY-POINT" )
	self.gui:setText( "Message", "Do you want to create a new Way Point?" )
	self.gui:setText( "SubTitle", "Waypoint Create" )
	self.gui:setText( "Next", "Yes" )
	self.gui:setText( "Reset", "No" )
	-----------------------------------
	self.gui:setImage("AlertImage", "$SURVIVAL_DATA/Scripts/WayPoints/WayPointIcon3.png")
	self.gui:setImage("SubTitleImage", "")
	---------------------------------------------------------------
	self.gui:setButtonCallback( "Next", "cl_selectColorCreate")
	self.gui:setButtonCallback( "Reset", "cl_onGuiClosed")
	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
	self.gui:open()
end

 function MapGUI.cl_UpgradeCreate( self )
	if MapLevel > 4 or MapLevel < 0 then
		MapLevel = 0
	end
	local availableKits = ToolQuantity
	self.gui = sm.gui.createSeatUpgradeGui()
	self.gui:setText( "SubTitle", "Level: ".. tostring(MapLevel+1))
	self.gui:setText( "Name", "MAP UPGRADE" )
	self.gui:setText( "SettingsText", "" )
	------------------------------------
	self.gui:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/Map0.png" )
	--------------------------------------------------------------
	self.gui:setButtonCallback( "Upgrade", "sv_UpgradeMap" )
	self.gui:setText("Lvl1", "")
	----------------------------------------------------------
	if MapLevel < 4 then
		self.gui:setImage( "UpgradeIcon", "$SURVIVAL_DATA/Scripts/WayPoints/Map0.png" )
		self.gui:setImage( "UpgradeButtonIcon", "$SURVIVAL_DATA/Scripts/WayPoints/UpgradeIcon.png" )
		self.gui:setData( "Upgrade", { cost = MapGUI.Levels["L"..tostring(MapLevel+1)].cost, available = ToolQuantity } ) --ToolQuantity
		self.gui:setText( "UpgradeInfo", "Press the upgrade button to upgrade the map" )
		self.gui:setImage( "Level", "$SURVIVAL_DATA/Scripts/WayPoints/Map/level-"..tostring(MapLevel+1)..".png" )
		self.gui:setText( "Settings", "Confirm" )
		local infoData = {}
		infoData.Settings = "\n".."Satellites: "..MapGUI.Levels["L"..tostring(MapLevel+1)].unlock.Satellites.."\n".."Distance: "..MapGUI.Levels["L"..tostring(MapLevel+1)].unlock.Distance
		self.gui:setData( "UpgradeInfo", infoData )
		self.gui:setData( "Upgrade", { cost = MapGUI.Levels["L"..tostring(MapLevel+1)].cost, available = ToolQuantity } ) --ToolQuantity
	elseif MapLevel == 4 then
		self.gui:setImage( "UpgradeButtonIcon", "$SURVIVAL_DATA/Scripts/WayPoints/UpgradeIcon.png" )
		self.gui:setImage( "Level", "$SURVIVAL_DATA/Scripts/WayPoints/Map/level-"..tostring(MapLevel+1)..".png" )
		self.gui:setText( "SubTitle", "Level: ".. tostring(MapLevel+1))
		self.gui:setData( "UpgradeInfo", { } )
		self.gui:setData( "Upgrade", { cost = 1, available = 0 } )
	end
	------------------------------------------------------------
	i = MapLevel +1
	while ( i ~= 0 ) do
		self.gui:setText("Lvl"..i, "")
		i = i-1
	end
	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
	self.gui:open()
	CountForIconBool = true
end

function MapGUI.sv_UpgradeMap( self )
	local level = MapGUI.Levels["L"..tostring(MapLevel+1)]
	if ToolQuantity >= level.cost then
		if (MapGUI.Levels["L"..tostring(MapLevel+1)] ~= MapGUI.Levels["L4"]) then
				ToolQuantity = ToolQuantity - MapGUI.Levels["L"..tostring(MapLevel+1)].cost
				self.gui:setData( "Upgrade", { cost = MapGUI.Levels["L"..tostring(MapLevel+2)].cost, available = ToolQuantity } ) --ToolQuantity
				self.network:sendToServer("SpendInventory", {inventory = sm.localPlayer.getPlayer():getInventory(), cost = MapGUI.Levels["L"..tostring(MapLevel+1)].cost})
				sm.gui.chatMessage("Satellite Launched")
				MapLevel = MapLevel+1
				self.gui:setText("Lvl"..tostring(MapLevel+1), "")
				self.gui:setText( "SubTitle", "Level: ".. tostring(MapLevel+1))
				self.gui:setImage( "Level", "$SURVIVAL_DATA/Scripts/WayPoints/Map/level-"..tostring(MapLevel+1)..".png" )
				self.gui:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/Map0.png" )
				local infoData = {}
				infoData.Settings = "\n".."Satellites: "..MapGUI.Levels["L"..tostring(MapLevel+1)].unlock.Satellites.."\n".."Distance: "..MapGUI.Levels["L"..tostring(MapLevel+1)].unlock.Distance
				self.gui:setData( "UpgradeInfo", infoData )
				self.gui:setImage( "UpgradeButtonIcon", "$SURVIVAL_DATA/Scripts/WayPoints/UpgradeIcon.png" )
		else
			self.network:sendToServer("SpendInventory", {inventory = sm.localPlayer.getPlayer():getInventory(), cost = MapGUI.Levels["L"..tostring(MapLevel+1)].cost})
			MapLevel = 4
			sm.gui.chatMessage("Satellite Launched")
			self.gui:setImage( "Level", "$SURVIVAL_DATA/Scripts/WayPoints/Map/level-"..tostring(MapLevel+1)..".png" )
			self.gui:setText("Lvl"..tostring(MapLevel+1), "")
			self.gui:setText( "SubTitle", "Level: ".. tostring(MapLevel+1))
			self.gui:setImage( "UpgradeButtonIcon", "$SURVIVAL_DATA/Scripts/WayPoints/UpgradeIcon.png" )
			self.gui:setData( "UpgradeInfo", { } )
			self.gui:setData( "Upgrade", { cost = 1, available = 0 } )
		end
		self.network:sendToServer("sv_MapUpgrade", { level = MapLevel, pos = sm.localPlayer.getPlayer():getCharacter():getWorldPosition() } )
	end
end

function MapGUI.sv_MapUpgrade( self, params )
	self.network:sendToClients("cl_LaunchAnimation", params)
	self.network:sendToClients("cl_MapUpgrade", params)
end

function MapGUI.cl_LaunchAnimation( self, params )
	if self.gui ~= nil then
		self.gui:close()
	end
	CrossHair( self, 0 )
	MapGUI.LaunchLocation = params.pos
	MapGUI.LaunchParticle = sm.effect.createEffect("Thruster - Level 5")
	MapGUI.LaunchParticle:setPosition(MapGUI.LaunchLocation+sm.vec3.new(0,0,-2))
	MapGUI.LaunchParticle:setRotation(sm.quat.new(0, 0.7071068 , 0.7071068, 0))
	MapGUI.LaunchParticle:setParameter("velocity", 10000)
	MapGUI.LaunchParticle:setParameter("radius", 8)
	MapGUI.LaunchParticle:setParameter("power", 10000)
	MapGUI.LaunchParticle:setParameter("intensity", 2)
	MapGUI.LaunchParticle:start()
	MapGUI.LaunchParticle0 = sm.effect.createEffect("Thruster - Level 5")
	MapGUI.LaunchParticle:setPosition(MapGUI.LaunchLocation+sm.vec3.new(0,0,-2))
	MapGUI.LaunchParticle0:setParameter("velocity", 10000)
	MapGUI.LaunchParticle0:setParameter("radius", 8)
	MapGUI.LaunchParticle0:setParameter("power", 10000)
	MapGUI.LaunchParticle0:setParameter("intensity", 2)
	MapGUI.LaunchParticle0:start()
	MapGUI.SatelliteLaunched = true
	MapGUI.LaunchEffect = sm.effect.createEffect("ShapeRenderable")
	MapGUI.LaunchEffect:setParameter("uuid", sm.uuid.new("d0afb527-e786-4a22-a014-d847900458a7"))
	MapGUI.LaunchEffect:setParameter("color", sm.color.new(0, 0, 0))
	MapGUI.LaunchEffect:setRotation(sm.quat.new(0, 0.7071068 , 0.7071068, 0))
	MapGUI.LaunchEffect:setPosition(MapGUI.LaunchLocation)
	MapGUI.LaunchEffect:start()
end


function MapGUI.SpendInventory( self, params )
	sm.container.beginTransaction()
	sm.container.spend( params.inventory, sm.uuid.new("d0afb527-e786-4a22-a014-d847900458a7"), params.cost, true )
	sm.container.endTransaction()
end


function MapGUI.cl_MapUpgrade( self, params )
	MapLevel = params.level
end


 function MapGUI.cl_setupUiDestroy( self )
	self.gui = sm.gui.createChallengeMessageGui()
	self.gui:setText( "Title", "WAY-POINT" )
	self.gui:setText( "Message", "Do you want to delete this Way Point?" )
	self.gui:setText( "SubTitle", "Waypoint Delete" )
	self.gui:setText( "Next", "Yes" )
	self.gui:setText( "Reset", "No" )
	-----------------------------------
	self.gui:setImage("AlertImage", "$SURVIVAL_DATA/Scripts/WayPoints/WayPointIcon3.png")
	self.gui:setImage("SubTitleImage", "")
	---------------------------------------------------------------
	self.gui:setButtonCallback( "Next", "cl_destroyWayPoint")
	self.gui:setButtonCallback( "Reset", "cl_onGuiClosed")
	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
	self.gui:open()
end

 function MapGUI.cl_selectColorCreate( self )
	Color = 3
	self:cl_onGuiClosed()
	self.gui = sm.gui.createEngineGui()
	self.gui:setText( "Name", "Color Selector" )
	self.gui:setText( "Interaction", "Adjust the slider to change the Color" )
	self.gui:setText( "SubTitle", "Please select a Color for the waypoint" )
	self.gui:setButtonCallback( "Upgrade", "cl_createWayPoint" )
	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
	self.gui:setSliderCallback( "Setting", "cl_onColorChange" )
	self.gui:setSliderData( "Setting", 20, 3 )
	self.gui:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/WayPointIcon"..tostring(Color)..".png" )
	self.gui:setText( "UpgradeText", "Confirm" )
	self.gui:setImage( "UpgradeIcon", "$SURVIVAL_DATA/Scripts/WayPoints/UpgradeIcon.png" )
	self.gui:setData( "Upgrade", { cost = 0, available = 0 } )
	self.gui:setText( "UpgradeInfo", "Press the confirm button to continue" )
	self.gui:open()
end

function MapGUI.cl_onColorChange( self, sliderName, sliderPos )
	Color = sliderPos
	tmpcolor = Color
	local path = ""
	if tmpcolor > 8 then
		tmpcolor = Color - 8
		path = "/BuildingWaypoints/"
	end
	self.gui:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/"..path.."WayPointIcon"..tostring(tmpcolor)..".png" )
end
MapGUI.localWay = {}
function MapGUI.GetWayData( self )
	MapGUI.localWay = GetWayData()
	for _,v in pairs(MapGUI.localWay) do
		v:open()
	end
end
	
function MapGUI.cl_createWayPoint( self, buttonName )
	self:cl_onGuiClosed()
	AddGui( Color )
end
function MapGUI.cl_destroyWayPoint( self )
	self:cl_onGuiClosed()
	DestroyGui()
end

function MapGUI.cl_onGuiClosed( self )
	SubGuiIsOn[1] = false
	SubGuiIsOn[2] = false
	SubGuiIsOn[3] = false
	SubGuiIsOn[4] = false
	SubGuiIsOn[5] = false
	if self.gui ~= nil then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end


 function MapGUI.cl_setupUiDestroyAll( self )
	self.gui = sm.gui.createChallengeMessageGui()
	self.gui:setText( "Title", "WAY-POINT" )
	self.gui:setText( "Message", "Do you want to delete all Way Points?" )
	self.gui:setText( "SubTitle", "Waypoint Clear" )
	self.gui:setText( "Next", "Yes" )
	self.gui:setText( "Reset", "No" )
	-----------------------------------
	self.gui:setImage("AlertImage", "$SURVIVAL_DATA/Scripts/WayPoints/WayPointIcon3.png")
	self.gui:setImage("SubTitleImage", "")
	---------------------------------------------------------------
	self.gui:setButtonCallback( "Next", "cl_destroyAllWayPoints")
	self.gui:setButtonCallback( "Reset", "cl_onGuiClosed")
	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
	self.gui:open()
end
function MapGUI.cl_destroyAllWayPoints( self )
	self:cl_onGuiClosed()
	DestroyAllGui()
end

function MapGUI.cl_selectViewRange( self )
	dta = GetPlayerData(sm.localPlayer.getPlayer():getName())
	local startPos = dta
	if dta ~= nil then
		startPos = dta.data.maxViewDist
		if startPos > (3 * (MapLevel+1)) + 2 then
			startPos = (3 * (MapLevel+1)) + 2
		end
	else
		startPos = (3 * (MapLevel+1)) + 2
	end
	self:cl_onGuiClosed()
	self.gui = sm.gui.createEngineGui()
	self.gui:setText( "Name", "Waypoint Render Distance" )
	local mssg = ""..math.pow(startPos, 2)*100
	if startPos == 16 then mssg = "inf" end
	if startPos == 0 then mssg = "invisible" end
	self.gui:setText( "Interaction", mssg)
	self.gui:setText( "SubTitle", "Please select the view distance of the waypoints" )
	self.gui:setButtonCallback( "Upgrade", "cl_onSetDist" )
	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
	self.gui:setSliderCallback( "Setting", "cl_onDistChanged" )
	self.gui:setSliderData( "Setting", (3 * (MapLevel+1)) + 2, startPos )
	self.gui:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/WayPointIcon3.png" )
	self.gui:setText( "UpgradeText", "Set Distance" )
	self.gui:setImage( "UpgradeIcon", "$SURVIVAL_DATA/Scripts/WayPoints/UpgradeIcon.png" )
	self.gui:setData( "Upgrade", { cost = 0, available = 0 } )
	self.gui:setText( "UpgradeInfo", "Press the confirm button to continue" )
	self.gui:open()
end

function MapGUI.cl_onDistChanged( self, sliderName, sliderPos )
	Dist = sliderPos
	local mssg = ""..math.pow(Dist, 2)*100
	if Dist == 16 then mssg = "inf" end
	if Dist == 0 then mssg = "invisible" end
	self.gui:setText( "Interaction", mssg)
end

function MapGUI.cl_onSetDist( self, buttonName )
	SetDist(Dist)
	self:cl_onGuiClosed()
end
