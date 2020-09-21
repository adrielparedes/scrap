
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/interactables/MapGUI.lua"
dofile "$SURVIVAL_DATA/Scripts/SurvivalPlayer.lua"
dofile "$GAME_DATA/Scripts/CreativePlayer.lua"
dofile "$SURVIVAL_DATA/Scripts/SurvivalGame.lua"
dofile "$SURVIVAL_DATA/Scripts/WayPoints/data.lua" 

Map = class( nil )
Map.WasButtonClickedLocally = false
Map.DeleteMenuBlock = false
Map.Zoom = 700
Map.ToggleOnOff = false
Map.RunCancel = false
Map.HasBeenRun = false
Map.camPos = sm.vec3.new(0, 0, 0)
Map.camDir =  sm.vec3.new(0, 0, 0)
Map.AnimationEnded = false
Map.IdleHasBeenRun = false
Map.BlockPos = sm.vec3.new(0,0,0)
Map.BlockDir = sm.vec3.new(0,0,0)
Map.Ready = false
Map.ExitSwing = false
Map.FailToExit = true
Map.CountTilReset = 0
Map.CrossHair = 1
Map.SaveBlockExists = true
Map.SaveBlockExistsTimer = 0
Map.cameraPos = nil
Map.playerWorld = nil
Map.player = nil
Map.Anim = true
Map.closeAnim = false
Map.CanSave = true
GuiTable = {}
GuiColor = {}
GuiTablePos = {}
GuiTableDistance = {}
Map.tmpHasBeenRun = false
Map.LoadCellsForGUI = false
Map.LoadCellsForGUIPause = 0
Map.Color = 3
Map.MapLevel = 0
Map.NumberOfWaypoints = 0
Map.SaveData = false
Map.MaxViewDist = 10
Map.Tp_Player = false
Map.tmpParams = {}
Map.tmpDestroyList = {}
Map.DestoryInList = false
Map.SendToServerCreate = false
Map.tmpBool = 0
Map.SendToServerPreLoadBool = false
Map.OverWorld = nil
local MaxViewConst = 100
local MaxViewAddConst = 2

local renderablesTp = { "$GAME_DATA/Character/Char_Male/Animations/char_male_tp_handbook.rend", "$GAME_DATA/Character/Char_Tools/Char_handbook/char_handbook_tp_animlist.rend" }
local renderablesFp = { "$GAME_DATA/Character/Char_Tools/Char_handbook/char_handbook_fp_animlist.rend" }

local renderables = {
	"$SURVIVAL_DATA/Scripts/WayPoints/Char_maptablet/char_maptablet.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local Range = 3.0
local SwingStaminaSpend = 1.5

Map.swingCount = 2
Map.mayaFrameDuration = 1.0/30.0
Map.freezeDuration = 0.075

Map.swings = { "open" }
Map.swingFrames = { 4.2 * Map.mayaFrameDuration, 4.2 * Map.mayaFrameDuration }
Map.swingExits = { "close" }

function Map.client_onCreate( self )
	self.isLocal = self.tool:isLocal()
	self:init()
	Map.CrossHair = 1
	Map.player = sm.localPlayer.getPlayer()
	if not GetGameMode() then
		ForceLoadCells( { player = Map.player, pos=sm.vec3.new(0,0,0) } )
	end
end

function DataBlockLoaded()
	print("Data Block Detected...")
	Map:SetNewData()
end

function SetDist( dist )
	Map.MaxViewDist = dist
	Map:SavePlayerData(dist)
end

function Map.SavePlayerData( self, data )
	SavePlayerData(sm.localPlayer.getPlayer():getName(), {maxViewDist = data})
	print(GetPlayerData(sm.localPlayer.getPlayer():getName()))
end

function Map.sv_PreLoadWayPoints( self )
	print("Locating Host...")
	local host
	for _,v in pairs(sm.player.getAllPlayers()) do if v.id == 1 then host = v break end end
	self.network:sendToClients("FindHost", host:getName())
end

function Map.FindHost( self, value )
	if sm.localPlayer.getPlayer():getName() == value then
		print("Host Found: "..value)
		self.network:sendToServer("SaveDataForAll", { pos = GuiTablePos, color = GuiColor, level=GetMapLevel() })
		self.network:sendToServer("PreLoad", { Positions = GuiTablePos, Colors =  GuiColor, name = value} )
	end
end

function Map.PreLoad( self, param )
	self.network:sendToClients("PreLoadWayPoints", param )
end


function Map.SetNewData( self )
	GuiTablePos = GetPositions()
	GuiColor = GetColors()
	Map.SaveBlockExists = true
	SetSavedMapLevel(GetSavedMapLevel()-1)
	Map.MapLevel = GetMapLevel()
	if Map.MapLevel > 5 or Map.MapLevel < 0 then
		Map.MapLevel = 0
	end
	Map.SendToServerPreLoadBool = true
	if not GetGameMode() then
		ForceLoadCells( { player = sm.localPlayer.getPlayer(), pos=sm.vec3.new(0,0,0) } )
	end
end


function Map.PreLoadWayPoints( self, params )
	print("Pre-Loading WayPoints")
	GuiTablePos = params.Positions
	GuiColor = params.Colors
	for i,v in pairs(GuiTablePos) do
		local Color = GuiColor
		GuiTable[i] = sm.gui.createBagIconGui( 1 )
		GuiTable[i]:setWorldPosition(GuiTablePos[i])
		GuiTable[i]:setMaxRenderDistance(10000)
		if Color[i] == nil then
			Color[i] = 3
		end
		local tmpcolor = Color[i]
		local path = ""
		if tmpcolor > 8 then
			tmpcolor = Color[i] - 8
			path = "/BuildingWaypoints/"
		end
		GuiTable[i]:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/"..path.."WayPointIcon"..tostring(tmpcolor)..".png" )
		GuiTable[i]:open()
	end
end

function Map.SetCanSave( self, bool )
	Map.CanSave = bool
end
	


function Map.SpawnDataBlock( self )
	if Map.CanSave then
		self.network:sendToClients("cl_chatMessage", "#03fc20DATA SAVED SUCESSFULLY#ffffff")
		--self.network:sendToServer("MessageAll", )
		print("Data Block Created...")
		sm.shape.createPart( sm.uuid.new("2aa8cb2c-ddd4-4554-9019-5a1c34e2d196"), sm.vec3.new(0,0,-10000), nil, false, nil)
	else
		self.network:sendToClients("cl_chatMessage", "#ff0000PLEASE LEAVE AND REMOVE THE MAP MOD\n\n#0066ffIf You Are Seeing This Message And You Do Not Want To Remove The Map Mod, Please Re-Load This World\n\n".."If You Keep Seing This Message After You Re-Load The World, Stop Playing And Report The Problem To Me On Discord TheGuy920-1402".."\n#ffffff")
	end
	Map.SaveBlockExists = true
end

function Map.MessageAll( self, message )
	self.network:sendToClients("cl_chatMessage", message)
end
function Map.cl_chatMessage( self, message )
	sm.gui.chatMessage(message)
end


function Map.CheckForDataBlock( self )
	local bool = false
	local UUID = sm.uuid.new( "2aa8cb2c-ddd4-4554-9019-5a1c34e2d196" )
	local bodys = sm.body.getAllBodies()
	for k,v in pairs(bodys) do
		local temp = sm.body.getShapes(v)
		for k,v in pairs(temp) do
			if UUID == v:getShapeUuid() then
				bool = true
				break
			end 
		end
	end
	print(bool)
	Map.SaveBlockExists = bool
end



function Map.client_onDestroy( self )

end

function Map.client_onRefresh( self )
	self:init()
	self:loadAnimations()
end

function Map.init( self )
	
	self.attackCooldownTimer = 0.0
	self.freezeTimer = 0.0
	self.pendingRaycastFlag = false
	self.nextAttackFlag = false
	self.currentSwing = 1
	
	self.swingCooldowns = {}
	for i = 1, self.swingCount do
		self.swingCooldowns[i] = 0.0
	end
	
	
	self.swing = false
	self.block = false
	
	
	if self.animationsLoaded == nil then
		self.animationsLoaded = false
	end
end
--maptablet_use_into
function Map.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			--equip = { "open_equipt", { nextAnimation = "idle" } },
			equip = { "handbook_pickup", { nextAnimation = "idle" } },
			unequip = { "handbook_putdown" },
			idle = {"handbook_idle", { looping = true } },
		}
	)
	local movementAnimations = {
		
		--equip = "open_equipt",

		idle = "handbook_idle",

		runFwd = "handbook_run_fwd",
		runBwd = "handbook_run_bwd",

		sprint = "handbook_sprint",

		jump = "handbook_jump",
		jumpUp = "handbook_jump_up",
		jumpDown = "handbook_jump_down",

		land = "handbook_jump_land",
		landFwd = "handbook_jump_land_fwd",
		landBwd = "handbook_jump_land_bwd",

		crouchIdle = "handbook_crouch_idle",
		crouchFwd = "handbook_crouch_fwd",
		crouchBwd = "handbook_crouch_bwd"		
	}
    
	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end
    
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
    
	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{   
				--equip = { "open_equipt", { nextAnimation = "idle" } },
				equip = { "handbook_pickup", { nextAnimation = "idle" } },
				unequip = { "handbook_putdown" },				
				idle = { "handbook_idle",  { looping = true } },
				
				sprintInto = { "handbook_sprint_into", { nextAnimation = "sprintIdle" } },
				sprintIdle = { "handbook_sprint_idle", { looping = true } },
				sprintExit = { "handbook_sprint_exit", { nextAnimation = "idle" } },

				open = { "handbook_use_into" , { nextAnimation = "sprintIdle" } },
				close = { "handbook_use_exit" , { nextAnimation = "idle" } },
			}
		)
		setFpAnimation( self.fpAnimations, "idle", 0.0 )
	end
	self.animationsLoaded = true
end

function Map.server_onFixedUpdate( self, dt )
	if Map.ToggleOnOff and Map.tmpBool >= 20 then
		Map.tmpBool = 0
		--ForceLoadCells( { player = Map.player, pos=Map.cameraPos, size = 3 } )
	end
	Map.tmpBool = Map.tmpBool +1
end

function Map.server_CreateMenuBlock( self, params )
	local SpawnPos = params.location + sm.vec3.new(  params.direction.x - 0.05, params.direction.y - 0.1, params.direction.z + 0.4)
	local UUID = sm.uuid.new( "f08d772f-9851-47b4-83ef-6da7e7cba8cb" )
	sm.shape.createPart( UUID, SpawnPos, nil, false, nil)
end

function Map.server_DestroyMenuBlocks( self, params )
	local SpawnPos = params.location + sm.vec3.new( params.direction.x - 0.05, params.direction.y - 0.1, params.direction.z + 0.4)
	local UUID = sm.uuid.new( "f08d772f-9851-47b4-83ef-6da7e7cba8cb" )
	local bodys = sm.body.getAllBodies()
	for k,v in pairs(bodys) do
		local temp = sm.body.getShapes(v)
		for k,v in pairs(temp) do
			if UUID == v:getShapeUuid() then
				local LocalSpawnPosHigh = sm.vec3.new(math.abs(SpawnPos.x)+0.3, math.abs(SpawnPos.y)+0.3, 0)
				local LocalSpawnPosLow = sm.vec3.new(math.abs(SpawnPos.x)-0.3, math.abs(SpawnPos.y)-0.3, 0)
				local LocalBlockPos = sm.vec3.new(math.abs(v:getWorldPosition().x), math.abs(v:getWorldPosition().y), 0)
				if LocalSpawnPosHigh > LocalBlockPos and LocalSpawnPosLow < LocalBlockPos then
					sm.shape.destroyShape(v,0)
					return
				end
			end 
		end
	end
end

function SetBackUp( player )
	if sm.localPlayer.getPlayer() == player then
		Map.FailToExit = false
	end
end


function Map.ConvertMapLevelPos( self, lvl, xPos, yPos )
	if lvl == 1 then
		return sm.vec3.new(500+xPos, 500+yPos, 0)
	elseif lvl == 2 then
		return sm.vec3.new(750+xPos, 750+yPos, 0)
	elseif lvl == 3 then
		return sm.vec3.new(1250+xPos, 1250+yPos, 0)
	elseif lvl == 4 then
		return sm.vec3.new(2000+xPos, 2000+yPos, 0)
	else
		return sm.vec3.new(3000+xPos, 3000+yPos, 0)
	end
end

function Map.ConvertMapLevelOp( self, lvl, xPos, yPos )
	if lvl == 1 then
		return sm.vec3.new(-500+xPos, -500+yPos, 0)
	elseif lvl == 2 then
		return sm.vec3.new(-700+xPos, -700+yPos, 0)
	elseif lvl == 3 then
		return sm.vec3.new(-1250+xPos, -1250+yPos, 0)
	elseif lvl == 4 then
		return sm.vec3.new(-2000+xPos, -2000+yPos, 0)
	else
		return sm.vec3.new(-3000+xPos, -3000+yPos, 0)
	end
end


----------------------Global Functions----------------------------------------------------------------------------------

function MoveCamera( self, CamMove, playerName )
	if Map.MapLevel ~= GetMapLevel() then
		Map.MapLevel = GetMapLevel()
		SetMapLevel( { level = GetMapLevel() } )
	end
	if not GetGameMode() then
		if playerName == sm.localPlayer.getPlayer():getName() and Map.WasButtonClickedLocally then
			sm.camera.setCameraState( 3 )
			local Limit = Map:ConvertMapLevelPos(Map.MapLevel, sm.localPlayer.getPlayer():getCharacter():getWorldPosition().x, sm.localPlayer.getPlayer():getCharacter():getWorldPosition().y)
			local opLimit = Map:ConvertMapLevelOp(Map.MapLevel, sm.localPlayer.getPlayer():getCharacter():getWorldPosition().x, sm.localPlayer.getPlayer():getCharacter():getWorldPosition().y)
			local Limit1 = sm.vec3.new(4097, 3072, 0)
			local opLimit1 = sm.vec3.new(-4097, -3072, 0)
			local Target = (sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, Map.Zoom) + CamMove*Map.Zoom/100)
			if Target.x < Limit.x and Target.x > opLimit.x and Target.y < Limit.y and Target.y > opLimit.y then
				if Target.x < Limit1.x and Target.x > opLimit1.x and Target.y < Limit1.y and Target.y > opLimit1.y then
					sm.camera.setPosition(Target)
				end
			else
				sm.camera.setPosition(sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, Map.Zoom))
			end
		else
			Map.WasButtonClickedLocally = false
			sm.camera.setCameraState( 1 )
		end
	else
		if playerName == sm.localPlayer.getPlayer():getName() and Map.WasButtonClickedLocally then
			sm.camera.setCameraState( 3 )
			local Limit = sm.vec3.new(705, 705, 0)
			local opLimit = sm.vec3.new(-705, -705, 0)
			local Target = (sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, Map.Zoom) + CamMove*Map.Zoom/100)
			if Target.x < Limit.x and Target.x > opLimit.x and Target.y < Limit.y and Target.y > opLimit.y then
				sm.camera.setPosition(Target)
			else
				sm.camera.setPosition(sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, Map.Zoom))
			end
		else
			Map.WasButtonClickedLocally = false
			sm.camera.setCameraState( 1 )
		end
	end
end


function AddGui( color1 )
	Map.Color = color1
	Map.LoadCellsForGUI = true
end


function DestroyGui()
	Map:client_destroyGui( self )
end

function DestroyAllGui()
	Map:client_destroyAllGui( self )
end

function cl_valueChanged( value )
	local tmpValue = value
	if tmpValue > 15 then
		tmpValue = 1500
	else
		tmpValue = (tmpValue*100) + 200
	end
	Map.Zoom = tmpValue
end

function GetZoom()
	local tmpStart = Map.Zoom
	if Map.Zoom > 1600 then
		tmpStart = 1600
	end
	return tmpStart
end
function ScrollZoom()
	return (Map.Zoom/100)
end
function ScrollChanged( value )
	Map.Zoom = value*100
end

function CancelMap( self, params )
	if sm.localPlayer.getPlayer():getName() == params.name then
		Map.RunCancel = true
		Map.FailToExit = true
		sm.audio.play("Handbook - Turn page", sm.localPlayer.getPlayer():getCharacter():getWorldPosition())
		Map.AnimationEnded = false
		Map.ExitSwing = true
		Map.DeleteMenuBlock = true
		Map.WasButtonClickedLocally = false
		Map.ToggleOnOff = false
		Map.Anim = true
	end
end


function Map.destroyMenu( self, params )
	self.network:sendToServer("server_DestroyMenuBlocks", params)
end

----------------------Global Functions End-------------------------------------------------------------------------------


function Map.client_addGui( self, params )
	print("bru")
	GuiTablePos = GetPositions()
	GuiColor = GetColors()
	SetMapLevel( { level = GetMapLevel() } )
	local Location = nil
	local xPos = sm.camera.getPosition().x
	local yPos = sm.camera.getPosition().y
	if GetPositions() ~= nil then 
		Map.NumberOfWaypoints = #GetPositions() 
	end
	Map.NumberOfWaypoints = Map.NumberOfWaypoints+1
	if params ~= nil then
		Location = params.pos.z - 1.5
		xPos = params.pos.x
		yPos = params.pos.y
		Map.Color = params.color
	end
	local bool, Distance =  sm.physics.distanceRaycast(sm.vec3.new(xPos, yPos, 1000), sm.vec3.new(0, 0, -1000))

	if bool and Location == nil then
		Location = 1000 - Distance * 1000
	elseif Location == nil then
		local bool, Distance =  sm.physics.distanceRaycast(sm.vec3.new(xPos, yPos, 0), sm.vec3.new(0, 0, -1000))
		if bool then
			Location = (500 - Distance * 1000) - 500
		else
			sm.gui.displayAlertText("Warning: Terrain not loaded, waypoint height set to 1")
			Location = 1
		end
	end
	GuiTable[Map.NumberOfWaypoints] = sm.gui.createBagIconGui( 1 )
	GuiTablePos[Map.NumberOfWaypoints] = sm.vec3.new(xPos, yPos, Location+1.5)
	GuiTable[Map.NumberOfWaypoints]:setWorldPosition(sm.vec3.new(xPos, yPos, Location+1.5))
	GuiTable[Map.NumberOfWaypoints]:setMaxRenderDistance(10000)
	local tmpcolor = Map.Color
	local path = ""
	if tmpcolor > 8 then
		tmpcolor = Map.Color - 8
		path = "/BuildingWaypoints/"
	end
	GuiTable[Map.NumberOfWaypoints]:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/"..path.."WayPointIcon"..tostring(tmpcolor)..".png" )
	GuiTable[Map.NumberOfWaypoints]:open()
	GuiColor[Map.NumberOfWaypoints] = Map.Color
	Map.SendToServerCreate = true
	Map.tmpParams = { i=Map.NumberOfWaypoints, LocationXY=Location, xPos=xPos, yPos=yPos, PlayerName=tostring(sm.localPlayer.getPlayer():getName()), color = Map.Color}
	Map.SaveData = true
end

function Map.client_destroyGui( self )
	SetMapLevel( { level = GetMapLevel() } )
	if not GetGameMode() then
		ForceLoadCells( { player = Map.player, pos=Map.cameraPos } )
	end
	GuiTablePos = GetPositions()
	GuiColor = GetColors()
	SetMapLevel( { level = GetMapLevel() } )
	for i,v in pairs(GetPositions()) do
		if (GuiTable[i] ~= nil) then
		local Factor = 3+(Map.Zoom/100)
			if ((GuiTablePos[i].x < sm.camera.getPosition().x+Factor and GuiTablePos[i].x > sm.camera.getPosition().x-Factor) and (GuiTablePos[i].y < sm.camera.getPosition().y+Factor and GuiTablePos[i].y > sm.camera.getPosition().y-Factor) ) then
				GuiTable[i]:close()
				GuiTable[i]:destroy()
				GuiTableDistance[i]:close()
				GuiTableDistance[i]:destroy()
				GuiTablePos[i] = nil
				GuiTable[i] = nil
				GuiTableDistance[i] = nil
				GuiColor[i] = nil
				Map.tmpDestroyList[#Map.tmpDestroyList+1] = i
			end
		end
	end
	Map.SaveData = true
	Map.tmpParams = {PlayerName = sm.localPlayer.getPlayer():getName()}
	Map.DestoryInList = true
end
function Map.client_destroyAllGui( self )
	SetMapLevel( { level = GetMapLevel() } )
	if not GetGameMode() then
		ForceLoadCells( { player = Map.player, pos=Map.cameraPos } )
	end
	GuiTablePos = GetPositions()
	GuiColor = GetColors()
	SetMapLevel( { level = GetMapLevel() } )
	for i,v in pairs(GuiTablePos) do
		if (GuiTable[i] ~= nil) then
			GuiTable[i]:close()
			GuiTable[i]:destroy()
			GuiTableDistance[i]:close()
			GuiTableDistance[i]:destroy()
			GuiTablePos[i] = nil
			GuiTable[i] = nil
			GuiTableDistance[i] = nil
			GuiColor[i] = nil
		end
		Map.tmpDestroyList[#Map.tmpDestroyList+1] = i
	end
	Map.SaveData = true
	Map.tmpParams = {PlayerName = sm.localPlayer.getPlayer():getName()}
	Map.DestoryInList = true
end
-----------------------------------On Server Send To Clients-----------------------------------------

function Map.sv_CreateSVgui( self, params )
	self.network:sendToClients("Create", params)
end

function Map.sv_DestroySVgui( self, params )
	self.network:sendToClients("Delete", params)
end

----------------------------------Redundant Client To Client Calls-----------------------------------

function Map.Create( self, params )
	self:cl_addGui( params )
end

function Map.Delete( self, params )
	self:cl_destroyGui( params )
end

function Map.cl_addGui( self, params )
	GuiTablePos = GetPositions()
	GuiColor = GetColors()
	if params.PlayerName ~= tostring(sm.localPlayer.getPlayer():getName()) then
		Map.NumberOfWaypoints = #GetPositions()
		GuiTable[params.i] = sm.gui.createBagIconGui( 1 )
		GuiTablePos[params.i] = sm.vec3.new(params.xPos, params.yPos, params.LocationXY+1.5)
		GuiTable[params.i]:setWorldPosition(sm.vec3.new(params.xPos, params.yPos, params.LocationXY+1.5))
		GuiTable[params.i]:setMaxRenderDistance(10000)
		local tmpcolor = params.color
		local path = ""
		if tmpcolor > 8 then
			tmpcolor = params.color - 8
			path = "/BuildingWaypoints/"
		end
		GuiTable[params.i]:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/"..path.."WayPointIcon"..tostring(tmpcolor)..".png" )
		GuiTable[params.i]:open()
		GuiColor[params.i] = params.color
	end
end

function Map.cl_destroyGui( self, params )
	GuiTablePos = GetPositions()
	GuiColor = GetColors()
	if params.PlayerName ~= tostring(sm.localPlayer.getPlayer():getName()) then
		GuiTable[params.i]:close()
		GuiTable[params.i]:destroy()
		GuiTableDistance[params.i]:close()
		GuiTableDistance[params.i]:destroy()
		GuiTablePos[params.i] = nil
		GuiTable[params.i] = nil
		GuiTableDistance[params.i] = nil
		GuiColor[params.i] = nil
	end
end

------------------------------------------------------------------------------------------------------
function CrossHair( self, value )
	Map.CrossHair = value
end

function AnimIsOn( param, player )
	if sm.localPlayer.getPlayer():getName() == player then
		Map.Anim = param
	end
end

function Map.SaveDataForAll( self, params )
	local host
	for _,v in pairs(sm.player.getAllPlayers()) do if v.id == 1 then host = v break end end
	params.name = host:getName()
	self.network:sendToClients("SaveAllData", params)
end

function Map.SaveAllData( self, params )
	if params.level > 1 or sm.localPlayer.getPlayer():getName() ~= params.name then
		SetPositions( params.pos )
		SetColors( params.color )
		SetMapLevel( { level = params.level } )
		SetSavedMapLevel(GetSavedMapLevel()-1)
	end
end

function GetWayData()
	return GuiTable
end

function tp_player( bool )
	Map.Tp_Player = bool
end

function GetMapMode()
	return Map.ToggleOnOff, Map.AnimationEnded
end


function Map.client_onUpdate( self, dt )
	if Map.ToggleOnOff and Map.AnimationEnded then
		if self.TargetForPlayerName == nil then
			self.TargetForPlayerName = sm.gui.createNameTagGui( 1 )
			self.TargetForPlayer = sm.gui.createBagIconGui( 1 )
		end
		self.TargetForPlayerName:setText( "Text", "You Are Here" )
		self.TargetForPlayerName:setWorldPosition(sm.localPlayer.getPlayer():getCharacter():getWorldPosition()+sm.vec3.new(0,(Map.Zoom/100)+10,0))
		self.TargetForPlayerName:setMaxRenderDistance(10000)
		self.TargetForPlayerName:open()

		self.TargetForPlayer:setWorldPosition(sm.localPlayer.getPlayer():getCharacter():getWorldPosition())
		self.TargetForPlayer:setMaxRenderDistance(10000)
		self.TargetForPlayer:setImage( "Icon", "$SURVIVAL_DATA/Scripts/WayPoints/Target.png" )
		self.TargetForPlayer:open()
	elseif self.TargetForPlayer ~= nil then
		self.TargetForPlayer:close()
		self.TargetForPlayerName:close()
		self.TargetForPlayerName = nil
		self.TargetForPlayer = nil
	end
	if Map.SendToServerPreLoadBool then
		Map.SendToServerPreLoadBool = false
		self.network:sendToServer("sv_PreLoadWayPoints")
	end
	if sm.localPlayer.getPlayer() ~= nil and not Map.RunCancel then
		if sm.localPlayer.getPlayer():getCharacter() ~= nil then
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				Map.ToggleOnOff = true
			end
		end
	end
	if Map.LoadCellsForGUI then
		GuiTablePos = GetPositions()
		GuiColor = GetColors()
		if not GetGameMode() then
			ForceLoadCells( { player = sm.localPlayer.getPlayer(), pos=sm.camera.getPosition() } )
		end
		tmpHasBeenRun = true
		Map.LoadCellsForGUI = false
	elseif tmpHasBeenRun then
		local bool, Distance =  sm.physics.distanceRaycast(sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, 1000), sm.vec3.new(0, 0, -1000))
		local Location = nil
		if bool and Location == nil then
			Location = 1000 - Distance * 1000
		elseif Location == nil then
			local bool, Distance =  sm.physics.distanceRaycast(sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, 0), sm.vec3.new(0, 0, -1000))
			if bool then
				Location = (500 - Distance * 1000) - 500
			else
				Location = nil
			end
		end
		if Map.LoadCellsForGUIPause == 400 or Location ~= nil then
			print("adding gui")
			self:client_addGui()
			tmpHasBeenRun = false
			Map.LoadCellsForGUIPause = 0
		end
		Map.LoadCellsForGUIPause = Map.LoadCellsForGUIPause + 1
	end
	if sm.localPlayer.getPlayer() ~= nil then
		if sm.localPlayer.getPlayer():getCharacter() ~= nil then
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= nil then
				Map.playerWorld = sm.localPlayer.getPlayer():getCharacter():getWorld()
			end
		end
	end
	if Map.Tp_Player then
		if self.tp_player_bool ~= true then
			if not GetGameMode() then
				ForceLoadCells( { player = sm.localPlayer.getPlayer(), pos=sm.camera.getPosition() } )
			end
			self.tp_player_bool = true
		end
		local bool, Distance =  sm.physics.distanceRaycast(sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, 1000), sm.vec3.new(0, 0, -1000))
		local Location = nil
		if bool and Location == nil then
			Location = 1000 - Distance * 1000
		elseif Location == nil then
			local bool, Distance =  sm.physics.distanceRaycast(sm.vec3.new(sm.camera.getPosition().x, sm.camera.getPosition().y, 0), sm.vec3.new(0, 0, -1000))
			if bool then
				Location = (500 - Distance * 1000) - 500
			else
				Location = nil
			end
		end
		if Location ~= nil then
			poz = sm.camera.getPosition() * sm.vec3.new(1,1,0) + sm.vec3.new(0,0,Location+5)
			if not GetGameMode() then
				SurvivalGame():tp_player({pos =poz, player = sm.localPlayer.getPlayer(), dir=sm.localPlayer.getPlayer():getCharacter():getDirection()})
			else
				CreativeGame():tp_player({pos =poz, player = sm.localPlayer.getPlayer(), dir=sm.localPlayer.getPlayer():getCharacter():getDirection()})
			end
			Map.Tp_Player = false
		end
	end
	Map.cameraPos = sm.camera.getPosition()
	Map.player = sm.localPlayer.getPlayer()
	Map.SaveBlockExistsTimer = Map.SaveBlockExistsTimer +1
	if Map.SaveBlockExistsTimer == 300 then
		print("Checking For Data Block....")
		self.network:sendToServer("CheckForDataBlock")
	end
	if not Map.SaveBlockExists then
		self.network:sendToServer("SpawnDataBlock")
		Map.SaveBlockExists = true
	end
	if Map.SaveData then
		if Map.MapLevel > 1 or GetGameMode() then
			if not GetGameMode() then
				ForceLoadCells( { player = sm.localPlayer.getPlayer(), pos=sm.vec3.new(0,0,0) } )
			end
			self.network:sendToServer("SaveDataForAll", { pos = GuiTablePos, color = GuiColor, level = Map.MapLevel, name = sm.localPlayer.getPlayer():getName() })
		end
		Map.SaveData = false
	end
	if Map.SaveBlockExistsTimer >= 1200 then
		if not GetGameMode() then
			ForceLoadCells( { player = sm.localPlayer.getPlayer(), pos=sm.vec3.new(0,0,0) } )
		end
		Map.SaveBlockExistsTimer = 0
	end
	if Map.CrossHair == nil then
		Map.CrossHair = 1
	end
	self.tool:setCrossHairAlpha( Map.CrossHair )
	if sm.localPlayer.getPlayer() ~= nil then
		if sm.localPlayer.getPlayer():getCharacter() ~= nil then
			if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() == nil and Map.FailToExit == false then
				Map.CountTilReset = Map.CountTilReset +1
			else
				Map.CountTilReset = 0
			end
		end
	end
	if Map.CountTilReset >= 40 then
		Map.FailToExit = true
		Map.AnimationEnded = false
		Map.ExitSwing = true
		Map.DeleteMenuBlock = true
		Map.WasButtonClickedLocally = false
		Map.ToggleOnOff = false
		sm.camera.setCameraState( 1 )
		EmergencyDestroy( sm.localPlayer.getPlayer():getName() )
	end
	if Map.DeleteMenuBlock then
		params = { location = Map.BlockPos, direction =  Map.BlockDir}
		self:destroyMenu( params )
		Map.DeleteMenuBlock = false
	end
	if Map.SendToServerCreate then
		self.network:sendToServer("sv_CreateSVgui", Map.tmpParams )
		Map.SendToServerCreate = false
	end
	if Map.DestoryInList then
		for i,v in pairs(Map.tmpDestroyList) do
			Map.tmpParams = { i = Map.tmpDestroyList[i], PlayerName = Map.tmpParams.PlayerName }
			self.network:sendToServer("sv_DestroySVgui", Map.tmpParams )
		end
		Map.DestoryInList = false
	end
	local isSprinting =  self.tool:isSprinting()
	if self.fpAnimations ~= nil then
		if not isSprinting and not Map.ToggleOnOff and self.fpAnimations.currentAnimation == "sprintExit" then
			local params = { name = "idle" }
			self:client_startLocalEvent( params )
		end
	end
	if Map.ToggleOnOff == true and Map.Anim == false then
		ToggleToggle(true, sm.localPlayer.getPlayer():getName())
	end
	if Map.ToggleOnOff and Map.AnimationEnded then
		isSprinting = true
		Map.closeAnim = true
	elseif self.equipped and Map.closeAnim then
		Map.closeAnim = false
		isSprinting = false
		local params = { name = "close" }
		self:client_startLocalEvent( params )
	end
	--------------Distance-------------------------------------------------
	GuiTablePos = GetPositions()
	if GuiTablePos ~= nil then
		Map.NumberOfWaypoints = #GuiTablePos
	else
		Map.NumberOfWaypoints = 0
	end
	for i,v in pairs(GuiTablePos) do
		if (GuiTablePos[i] ~= nil) then
			local DistanceX = math.pow(math.abs(sm.localPlayer.getPlayer():getCharacter():getWorldPosition().x - GuiTablePos[i].x), 2)
			local DistanceY = math.pow(math.abs(sm.localPlayer.getPlayer():getCharacter():getWorldPosition().y - GuiTablePos[i].y), 2)
			local Distance = math.sqrt(DistanceX + DistanceY)
			if GuiTableDistance ~= nil then
				if GuiTableDistance[i] ~= nil then
					GuiTableDistance[i]:destroy()
				end
			else
				GuiTableDistance = {}
			end
			local DistanceRound = string.format("%.".."f", Distance)
			GuiTableDistance[i] = sm.gui.createNameTagGui()
			GuiTableDistance[i]:setText( "Text", tostring(DistanceRound) )
			local StartHeight = ((Distance/25)+1.5)
			local Position = sm.vec3.new(GuiTablePos[i].x, GuiTablePos[i].y, GuiTablePos[i].z - StartHeight)
			GuiTableDistance[i]:setWorldPosition(Position)
			local MaxView = GetPlayerData(sm.localPlayer.getPlayer():getName())
			if MaxView == nil then
				MaxView = 10000
			elseif MaxView.data.maxViewDist == 17 then
				MaxView = 10000
			else
				MaxView = math.pow(MaxView.data.maxViewDist, 2)
			end
			local OverWorld = sm.localPlayer.getPlayer():getCharacter():getWorld() == Map.OverWorld
			if Map.OverWorld == nil then OverWorld = sm.localPlayer.getPlayer():getCharacter():getWorld().id == 1 end
			if not OverWorld and not GetGameMode() then
				MaxView = 0
			end
			GuiTableDistance[i]:setMaxRenderDistance((MaxView * MaxViewConst) + MaxViewAddConst)
			if GuiTable[i] ~= nil then
				GuiTable[i]:setMaxRenderDistance((MaxView * MaxViewConst) + MaxViewAddConst)
			end
			GuiTableDistance[i]:open()
		else
			GuiTableDistance[i]:destroy()
		end
	end
	--------------End-------------------------------------------------
	if Map.ExitSwing then
		local params = { name = self.swingExits[1], notToggle=true, isLocal = true}
		self:server_startEvent( params )
		Map.ExitSwing = false
	end
	if (Map.ToggleOnOff == true and Map.AnimationEnded and not Map.HasBeenRun and self.equipped and Map.WasButtonClickedLocally) then
		Map.camPos = sm.localPlayer.getPlayer():getCharacter():getWorldPosition() + sm.vec3.new( 0, 0, Map.Zoom )
		Map.camDir = sm.vec3.new( 0, 0, -90 )
		self.tool:setMovementSlowDown( true )
		sm.camera.setCameraState( 3 )
		sm.camera.setPosition(Map.camPos)
		sm.camera.setDirection(Map.camDir)
		ToggleToggle(true, sm.localPlayer.getPlayer():getName())
		--self.tool:setCrossHairAlpha( 1 )
		isSprinting = true
		Map.HasBeenRun = true
	end
	if(Map.IdleHasBeenRun == false and Map.ToggleOnOff == false) then
		self.tool:setMovementSlowDown( false )
		ToggleToggle(false, sm.localPlayer.getPlayer():getName())
		sm.camera.setCameraState( sm.camera.state.default )
	end
	if(Map.AnimationEnded and not Map.IdleHasBeenRun and Map.ToggleOnOff == false) then
		local params = { name = "idle" }
		self:client_startLocalEvent( params )
		Map.IdleHasBeenRun = true
		ToggleToggle(false, sm.localPlayer.getPlayer():getName())
	end
	
	if not self.animationsLoaded then
		return
	end
	
	--synchronized update
	self.attackCooldownTimer = math.max( self.attackCooldownTimer - dt, 0.0 )
	--standard third person updateAnimation
	updateTpAnimations( self.tpAnimations, self.equipped, dt )
	
	--update
	if self.isLocal then
		
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			self:updateFreezeFrame(self.swings[self.currentSwing], dt)
		end
		
		local preAnimation = self.fpAnimations.currentAnimation

		updateFpAnimations( self.fpAnimations, self.equipped, dt )
		
		if preAnimation ~= self.fpAnimations.currentAnimation then
			Map.AnimationEnded = true
			local keepBlockSprint = false
			local endedSwing = preAnimation == self.swings[self.currentSwing] and self.fpAnimations.currentAnimation == self.swingExits[self.currentSwing]
		end

		if isSprinting and self.fpAnimations.currentAnimation == "idle" and self.attackCooldownTimer <= 0 and not isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) then
			local params = { name = "sprintInto" }
			self:client_startLocalEvent( params )
		end
		
		if ( not isSprinting and isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) ) and self.fpAnimations.currentAnimation ~= "sprintExit" then
			local params = { name = "sprintExit" }
			self:client_startLocalEvent( params )
		end
	end
end

function Map.updateFreezeFrame( self, state, dt )
	local p = 1 - math.max( math.min( self.freezeTimer / self.freezeDuration, 1.0 ), 0.0 )
	local playRate = p * p * p * p
	self.fpAnimations.animations[state].playRate = playRate
	self.freezeTimer = math.max( self.freezeTimer - dt, 0.0 )
end

function Map.server_startEvent( self, params )
	if params.isLocal then
		if params.notToggle == nil then
			Map.AnimationEnded = false
			if Map.ToggleOnOff == true then
				Map.ToggleOnOff = false
				Map.HasBeenRun = false
			else
				Map.IdleHasBeenRun = false
				Map.ToggleOnOff = true
			end
		else
			self:client_startLocalEvent(params)
		end
	else
		self.network:sendToClients( "client_startLocalEvent", params )
	end
end

function Map.client_startLocalEvent( self, params3 )
	self:client_handleEvent( params3 )
end

function Map.client_handleEvent( self, params )
	-- Setup animation data on equip
	if params.name == "equip" then
		self.equipped = true
		self:loadAnimations()
	elseif params.name == "unequip" then
		self.equipped = false
	end

	if not self.animationsLoaded then
		return
	end
	
	--Maybe not needed
-------------------------------------------------------------------
	
	-- Third person animations
	local tpAnimation = self.tpAnimations.animations[params.name]
	if tpAnimation then
		local isSwing = false
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.tpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end
		
		local blend = not isSwing
		setTpAnimation( self.tpAnimations, params.name, blend and 0.2 or 0.0 )
	end
	
	-- First person animations
	if self.isLocal then
		local isSwing = false
		
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.fpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end
	
		local blend = not ( isSwing or isAnyOf( params.name, { "equip", "unequip" } ) )
		setFpAnimation( self.fpAnimations, params.name, blend and 0.2 or 0.0 )
	end	
end

function SetOverWorld( world )
	Map.OverWorld = world
end

function Map.client_onEquippedUpdate( self, primaryState, secondaryState, data0, data1, data2 )
	if self.pendingRaycastFlag then
		local time = 0.0
		local frameTime = 0.0
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			time = self.fpAnimations.animations[self.swings[self.currentSwing]].time
			frameTime = self.swingFrames[self.currentSwing]
		end
		if time >= frameTime and frameTime ~= 0 then
			self.pendingRaycastFlag = false
			local raycastStart = sm.localPlayer.getRaycastStart()
			local direction = sm.localPlayer.getDirection()
			local success, result = sm.localPlayer.getRaycast( Range, raycastStart, direction )
			if success then
				self.freezeTimer = self.freezeDuration
			end
		end
	end

	if primaryState == sm.tool.interactState.start  then
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			if self.attackCooldownTimer < self.swingCooldowns[self.currentSwing] - 0.25 then
				self.nextAttackFlag = true
			end
		else
			if self.attackCooldownTimer <= 0 then
				self.currentSwing = 1
				local params = { name = "" }
				if (Map.ToggleOnOff) then
					params.name = self.swingExits[1]
				else
					params.name = self.swings[1]
				end
				sm.audio.play("Handbook - Turn page", sm.localPlayer.getPlayer():getCharacter():getWorldPosition())
				self.network:sendToServer( "server_startEvent", params )
				self:server_startEvent( { isLocal = true } )
				self.pendingRaycastFlag = true
				self.nextAttackFlag = false
				self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
				Map.AnimationEnded = false
			end
		end
		Map.Ready = true
	end
	if primaryState == 0 and Map.Ready == true and Map.ToggleOnOff and Map.AnimationEnded then
		Map.Ready = false
		Map.BlockPos = sm.localPlayer.getPlayer():getCharacter():getWorldPosition() - sm.vec3.new(0,0,sm.localPlayer.getPlayer():getCharacter():getWorldPosition().z-10000)
		Map.BlockDir = sm.localPlayer.getPlayer():getCharacter():getDirection()
		local inventory = nil
		if GetGameMode() or not GetInventoryState() then
			inventory = nil
		else
			inventory = sm.container.totalQuantity( sm.localPlayer.getPlayer():getInventory(), sm.uuid.new("d0afb527-e786-4a22-a014-d847900458a7") )
		end
		local player = sm.localPlayer.getPlayer():getName()
		local OverWorld = sm.localPlayer.getPlayer():getCharacter():getWorld() == Map.OverWorld
		if Map.OverWorld == nil then OverWorld = sm.localPlayer.getPlayer():getCharacter():getWorld().id == 1 end
		cl_MapGuiOn( self, inventory, player, (OverWorld or GetGameMode()) )
		Map.MapLevel = GetMapLevel()
		params = { location = Map.BlockPos, direction =  Map.BlockDir}
		self.network:sendToServer("server_CreateMenuBlock", params)
		Map.WasButtonClickedLocally = true
		ToggleToggle(true, sm.localPlayer.getPlayer():getName())
		Map.Anim = false
		Map.RunCancel = false
	end
	return true, false
end



function Map.client_onEquip( self )
	self.equipped = true
	Map.AnimationEnded = false
	for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
	for k,v in pairs( renderables ) do renderablesFp[#renderablesFp+1] = v end
	
	self.tool:setTpRenderables( renderablesTp )

	self:init()
	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "equip", 0.0001 )

	if self.isLocal then
		self.tool:setFpRenderables( renderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Map.client_onUnequip( self )
	self.SwitchDurration = 0
	Map.HasBeenRun = false
	Map.ToggleOnOff = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "unequip" )
	if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	sm.camera.setCameraState(1)
end
