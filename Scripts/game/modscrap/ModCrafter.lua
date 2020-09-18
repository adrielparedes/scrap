-- ModCrafter.lua --
dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_survivalobjects.lua"
dofile "$SURVIVAL_DATA/Scripts/game/util/pipes.lua"

ModCrafter = class( nil )
ModCrafter.colorNormal = sm.color.new( 0x84ff32ff )
ModCrafter.colorHighlight = sm.color.new( 0xa7ff4fff )

local RandomSpawnChance = {
	["HAYBOT"] = 30,
	["TOTEBOT_GREEN"] = 20,
	["TAPEBOT"] = 10,
	["FARMBOT"] = 4,
	["WOC"] = 10,
	["GLOWGORP"] = 2,
}

local modcrafters = {
	-- Modcrafter
	[tostring( sm.uuid.new("03997358-1595-44b5-898a-3ce18285995a") )] = {
		needsPower = false,
		slots = 8,
		speed = 2,
		recipeSets = {
			{ name = "modcrafter", locked = false }
		},
		subTitle = "M O D C R A F T E R",
		createGuiFunction = sm.gui.createCraftBotGui
	}
}

local effectRenderables = {
	[tostring( obj_consumable_carrotburger )] = { char_cookbot_food_03, char_cookbot_food_04 },
	[tostring( obj_consumable_pizzaburger )] = { char_cookbot_food_01, char_cookbot_food_02 },
	[tostring( obj_consumable_longsandwich )] = { char_cookbot_food_02, char_cookbot_food_03 }
}

function ModCrafter.server_onCreate( self )
	self:sv_init()
end

function ModCrafter.server_onRefresh( self )
	self.crafter = nil
	self.network:setClientData( { craftArray = {}, pipeGraphs = {} })
	self:sv_init()
end

function ModCrafter.server_canErase( self )
	return #self.sv.craftArray == 0
end

function ModCrafter.client_onCreate( self )
	self:cl_init()
end

function ModCrafter.client_onDestroy( self )
	for _,effect in ipairs( self.cl.mainEffects ) do
		effect:destroy()
	end

	for _,effect in ipairs( self.cl.secondaryEffects ) do
		effect:destroy()
	end

	for _,effect in ipairs( self.cl.tertiaryEffects ) do
		effect:destroy()
	end

	for _,effect in ipairs( self.cl.quaternaryEffects ) do
		effect:destroy()
	end
end

function ModCrafter.client_onRefresh( self )
	self.crafter = nil
	self:cl_disableAllAnimations()
	self:cl_init()
end

function ModCrafter.client_canErase( self )
	if #self.cl.craftArray > 0 then
		sm.gui.displayAlertText( "#{INFO_BUSY}", 1.5 )
		return false
	end
	return true
end

-- Server Init

function ModCrafter.sv_init( self )
	self.crafter = modcrafters[tostring( self.shape:getShapeUuid() )]
	self.sv = {}
	self.sv.clientDataDirty = false
	self.sv.storageDataDirty = true
	self.sv.craftArray = {}
	self.sv.saved = self.storage:load()
	if self.params then print( self.params ) end

	if self.sv.saved == nil then
		self.sv.saved = {}
		self.sv.saved.spawner = self.params and self.params.spawner or nil
		self:sv_updateStorage()
	end

	if self.sv.saved.craftArray then
		self.sv.craftArray = self.sv.saved.craftArray
	end

	self:sv_buildPipesAndContainerGraph()
end

function ModCrafter.sv_markClientDataDirty( self )
	self.sv.clientDataDirty = true
end

function ModCrafter.sv_sendClientData( self )
	if self.sv.clientDataDirty then
		self.network:setClientData( { craftArray = self.sv.craftArray, pipeGraphs = self.sv.pipeGraphs } )
		self.sv.clientDataDirty = false
	end
end

function ModCrafter.sv_markStorageDirty( self )
	self.sv.storageDataDirty = true
end

function ModCrafter.sv_updateStorage( self )
	if self.sv.storageDataDirty then
		self.sv.saved.craftArray = self.sv.craftArray
		self.storage:save( self.sv.saved )
		self.sv.storageDataDirty = false
	end
end

function ModCrafter.sv_buildPipesAndContainerGraph( self )

	self.sv.pipeGraphs = { output = { containers = {}, pipes = {} }, input = { containers = {}, pipes = {} } }

	local function fnOnContainerWithFilter( vertex, parent, fnFilter, graph )
		local container = {
			shape = vertex.shape,
			distance = vertex.distance,
			shapesOnContainerPath = vertex.shapesOnPath
		}
		if parent.distance == 0 then -- Our parent is the craftbot
			local shapeInModCrafterPos = parent.shape:transformPoint( vertex.shape:getWorldPosition() )
			if not fnFilter( shapeInModCrafterPos.x ) then
				return false
			end
		end
		table.insert( graph.containers, container )
		return true
	end

	local function fnOnPipeWithFilter( vertex, parent, fnFilter, graph )
		local pipe = {
			shape = vertex.shape,
			state = PipeState.off
		}
		if parent.distance == 0 then -- Our parent is the craftbot
			local shapeInModCrafterPos = parent.shape:transformPoint( vertex.shape:getWorldPosition() )
			if not fnFilter( shapeInModCrafterPos.x ) then
				return false
			end
		end
		table.insert( graph.pipes, pipe )
		return true
	end

	-- Construct the input graph
	local function fnOnVertex( vertex, parent )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			return fnOnContainerWithFilter( vertex, parent, function( value ) return value <= 0 end, self.sv.pipeGraphs["input"] )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			return fnOnPipeWithFilter( vertex, parent, function( value ) return value <= 0 end, self.sv.pipeGraphs["input"] )
		end
		return true
	end

	ConstructPipedShapeGraph( self.shape, fnOnVertex )

	-- Construct the output graph
	local function fnOnVertex( vertex, parent )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			return fnOnContainerWithFilter( vertex, parent, function( value ) return value > 0 end, self.sv.pipeGraphs["output"] )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			return fnOnPipeWithFilter( vertex, parent, function( value ) return value > 0 end, self.sv.pipeGraphs["output"] )
		end
		return true
	end

	ConstructPipedShapeGraph( self.shape, fnOnVertex )

	table.sort( self.sv.pipeGraphs["input"].containers, function(a, b) return a.distance < b.distance end )
	table.sort( self.sv.pipeGraphs["output"].containers, function(a, b) return a.distance < b.distance end )

	for _, container in ipairs( self.sv.pipeGraphs["input"].containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipeGraphs["input"].pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end

	for _, container in ipairs( self.sv.pipeGraphs["output"].containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipeGraphs["output"].pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end

	self:sv_markClientDataDirty()
end

-- Client Init
function ModCrafter.cl_init( self )
	local shapeUuid = self.shape:getShapeUuid()
	if self.crafter == nil then
		self.crafter = modcrafters[tostring( shapeUuid )]
	end
	self.cl = {}
	self.cl.craftArray = {}
	self.cl.uvFrame = 0
	self.cl.animState = nil
	self.cl.animName = nil
	self.cl.animDuration = 1
	self.cl.animTime = 0

	self.cl.currentMainEffect = nil
	self.cl.currentSecondaryEffect = nil
	self.cl.currentTertiaryEffect = nil
	self.cl.currentQuaternaryEffect = nil

	self.cl.mainEffects = {}
	self.cl.secondaryEffects = {}
	self.cl.tertiaryEffects = {}
	self.cl.quaternaryEffects = {}

	if shapeUuid == sm.uuid.new("03997358-1595-44b5-898a-3ce18285995a") then
		self.cl.mainEffects["unfold"] = sm.effect.createEffect( "Craftbot - Unpack", self.interactable )
		self.cl.mainEffects["idle"] = sm.effect.createEffect( "Craftbot - Idle", self.interactable )
		self.cl.mainEffects["idlespecial01"] = sm.effect.createEffect( "Craftbot - IdleSpecial01", self.interactable )
		self.cl.mainEffects["idlespecial02"] = sm.effect.createEffect( "Craftbot - IdleSpecial02", self.interactable )
		self.cl.mainEffects["craft_start"] = sm.effect.createEffect( "Craftbot - Start", self.interactable )
		self.cl.mainEffects["craft_loop01"] = sm.effect.createEffect( "Craftbot - Work01", self.interactable )
		self.cl.mainEffects["craft_loop02"] = sm.effect.createEffect( "Craftbot - Work02", self.interactable )
		self.cl.mainEffects["craft_finish"] = sm.effect.createEffect( "Craftbot - Finish", self.interactable )
		self.cl.secondaryEffects["craft_loop01"] = sm.effect.createEffect( "Craftbot - Work", self.interactable )
		self.cl.secondaryEffects["craft_loop02"] = self.cl.secondaryEffects["craft_loop01"]
		self.cl.secondaryEffects["craft_loop03"] = self.cl.secondaryEffects["craft_loop01"]
		self.cl.tertiaryEffects["craft_loop02"] = sm.effect.createEffect( "Craftbot - Work02Torch", self.interactable, "l_arm03_jnt" )
	end
	self:cl_setupUI( tostring( self.shape:getShapeUuid() ) )
	self.cl.pipeGraphs = { output = { containers = {}, pipes = {} }, input = { containers = {}, pipes = {} } }
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
end

function ModCrafter.cl_setupUI( self, stringUuid )
	self.cl.guiInterface = self.crafter.createGuiFunction()

	self.cl.guiInterface:setGridButtonCallback( "Craft", "cl_onCraft" )
	self.cl.guiInterface:setGridButtonCallback( "Repeat", "cl_onRepeat" )
	self.cl.guiInterface:setGridButtonCallback( "Collect", "cl_onCollect" )

	self:cl_updateRecipeGrid()
end

function ModCrafter.cl_updateRecipeGrid( self )
	if not g_craftingModRecipes then
		local recipePaths = {
			modcrafter = "$SURVIVAL_DATA/CraftingRecipes/modcrafter.json"
		}
		g_craftingModRecipes = {}
		for name, path in pairs( recipePaths ) do
			local json = sm.json.open( path )
			local recipes = {}
			local recipesByIndex = {}
			for idx, recipe in ipairs( json ) do

				recipe.craftTime = math.ceil( recipe.craftTime * 40 ) -- Seconds to ticks
				for _,ingredient in ipairs( recipe.ingredientList ) do
					ingredient.itemId = sm.uuid.new( ingredient.itemId ) -- Prepare uuid
				end

				recipes[recipe.itemId] = recipe
				recipesByIndex[idx] = recipe

			end
			-- NOTE(daniel): Wardrobe is using 'recipes' by uuid, crafter is using 'recipesByIndex'
			g_craftingModRecipes[name] = { path = path, recipes = recipes, recipesByIndex = recipesByIndex }
		end
	end

	self.cl.guiInterface:clearGrid( "RecipeGrid" )
	for _, recipeSet in ipairs( self.crafter.recipeSets ) do
		print( "Adding", g_craftingModRecipes[recipeSet.name].path )
		self.cl.guiInterface:addGridItemsFromFile( "RecipeGrid", g_craftingModRecipes[recipeSet.name].path, { locked = recipeSet.locked } )
	end
end

function ModCrafter.client_onClientDataUpdate( self, data )
	self.cl.craftArray = data.craftArray
	self.cl.pipeGraphs = data.pipeGraphs

	-- Experimental needs testing
	for _, val in ipairs( self.cl.craftArray ) do
		if val.time == -1 and val.startTick then
			local estimate = max( sm.game.getServerTick() - val.startTick, 0 ) -- Estimate how long time has passed since server started crafing and client recieved craft
			val.time = estimate
		end
	end
end

-- Internal util

function ModCrafter.getParent( self )
	if self.crafter.needsPower then
		return self.interactable:getSingleParent()
	end
	return nil
end

function ModCrafter.getRecipeByIndex( self, index )

	-- Convert one dimensional index to recipeSet and recipeIndex
	local recipeName = 0
	local recipeIndex = 0
	local offset = 0
	for _, recipeSet in ipairs( self.crafter.recipeSets ) do
		assert( g_craftingModRecipes[recipeSet.name].recipesByIndex )
		local recipeCount = #g_craftingModRecipes[recipeSet.name].recipesByIndex

		if index <= offset + recipeCount then
			recipeIndex = index - offset
			recipeName = recipeSet.name
			break
		end
		offset = offset + recipeCount
	end

	print( recipeIndex )
	local recipe = g_craftingModRecipes[recipeName].recipesByIndex[recipeIndex]
	assert(recipe)
	if recipe then
		return recipe, g_craftingModRecipes[recipeName].locked
	end

	return nil, nil
end

-- Server
function ModCrafter.server_onFixedUpdate( self )
	-- If body has changed, refresh the pipe graph
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		self:sv_buildPipesAndContainerGraph()
	end
	local parent = self:getParent()
	if not self.crafter.needsPower or ( parent and parent.active ) then
		-- Update first in array
		for idx, val in ipairs( self.sv.craftArray ) do
			if val then
				local recipe = val.recipe
				local recipeCraftTime = math.ceil( recipe.craftTime / self.crafter.speed ) + 120 -- 1s windup + 2s winddown

				if val.time < recipeCraftTime then

					-- Begin crafting new item
					if val.time == -1 then
						val.startTick = sm.game.getServerTick()
						self:sv_markClientDataDirty()
					end

					val.time = val.time + 1

					local isSpawner = self.sv.saved and self.sv.saved.spawner

					if isSpawner then
						if val.time + 10 == recipeCraftTime then
							--print( "Open the gates!" )
							self.sv.saved.spawner.active = true
						end
					end

					if val.time >= recipeCraftTime then

						if isSpawner then
							print( "Spawning {"..recipe.itemId.."}" )
							self:sv_spawn( self.sv.saved.spawner )
						end

						local containerObj = FindContainerToCollectTo( self.sv.pipeGraphs["output"].containers, sm.uuid.new( recipe.itemId ), recipe.quantity )
						if containerObj then
							sm.container.beginTransaction()
							sm.container.collect( containerObj.shape:getInteractable():getContainer(), sm.uuid.new( recipe.itemId ), recipe.quantity )
							if recipe.extras then
								print( recipe.extras )
								for _,extra in ipairs( recipe.extras ) do
									sm.container.collect( containerObj.shape:getInteractable():getContainer(), sm.uuid.new( extra.itemId ), extra.quantity )
								end
							end
							if sm.container.endTransaction() then -- Has space

								table.remove( self.sv.craftArray, idx )

								if val.loop and #self.sv.pipeGraphs["input"].containers > 0 then
									self:sv_craft( { recipe = val.recipe, loop = true } )
								end

								self:sv_markStorageDirty()
								self.network:sendToClients( "cl_n_onCollectToChest", { shapesOnContainerPath = containerObj.shapesOnContainerPath, itemId = sm.uuid.new( recipe.itemId ) } )
								-- Pass extra?
							else
								print( "Container full" )
							end
						end

					end

					--self:sv_markClientDataDirty()
					break
				end
			end
		end
	end

	self:sv_sendClientData()
	self:sv_updateStorage()
end

--Client

local UV_OFFLINE = 0
local UV_READY = 1
local UV_FULL = 2
local UV_HEART = 3
local UV_WORKING_START = 4
local UV_WORKING_COUNT = 4
local UV_JAMMED_START = 8
local UV_JAMMED_COUNT = 4

function ModCrafter.client_onFixedUpdate( self )
	for idx, val in ipairs( self.cl.craftArray ) do
		if val then
			local recipe = val.recipe
			local recipeCraftTime = math.ceil( recipe.craftTime / self.crafter.speed ) + 120-- 1s windup + 2s winddown

			if val.time < recipeCraftTime then
				val.time = val.time + 1

				if val.time >= recipeCraftTime and #self.cl.pipeGraphs.output.containers > 0 then
					table.remove( self.cl.craftArray, idx )
				end

				break
			end
		end
	end
end

function ModCrafter.client_onUpdate( self, deltaTime )

	local prevAnimState = self.cl.animState

	local craftTimeRemaining = 0

	local parent = self:getParent()
	if not self.crafter.needsPower or ( parent and parent.active ) then
		local guiActive = self.cl.guiInterface:isActive()
		local hasItems = false
		local isCrafting = false

		for idx = 1, self.crafter.slots do
			local val = self.cl.craftArray[idx]
			if val then
				hasItems = true

				local recipe = val.recipe
				local recipeCraftTime = math.ceil( recipe.craftTime / self.crafter.speed ) + 120

				if val.time >= 0 and val.time < recipeCraftTime then -- The one beeing crafted
					isCrafting = true
					craftTimeRemaining = ( recipeCraftTime - val.time ) / 40
				end

				if guiActive and self.interactable.shape.uuid ~= obj_survivalobject_dispenserbot then
					local gridItem = {}
					gridItem.itemId = recipe.itemId
					gridItem.craftTime = recipeCraftTime
					gridItem.remainingTicks = recipeCraftTime - clamp( val.time, 0, recipeCraftTime )
					gridItem.locked = false
					gridItem.repeating = val.loop
					self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )
				end
			else
				if guiActive and self.interactable.shape.uuid ~= obj_survivalobject_dispenserbot then
					local gridItem = {}
					gridItem.itemId = "00000000-0000-0000-0000-000000000000"
					gridItem.craftTime = 0
					gridItem.remainingTicks = 0
					gridItem.locked = false
					gridItem.repeating = false
					self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )
				end
			end
		end

		if isCrafting then
			self.cl.animState = "craft"
			self.cl.uvFrame = self.cl.uvFrame + deltaTime * 8
			self.cl.uvFrame = self.cl.uvFrame % UV_WORKING_COUNT
			self.interactable:setUvFrameIndex( math.floor( self.cl.uvFrame ) + UV_WORKING_START )
		elseif hasItems then
			self.cl.animState = "idle"
			self.interactable:setUvFrameIndex( UV_FULL )
		else
			self.cl.animState = "idle"
			self.interactable:setUvFrameIndex( UV_READY )
		end
	else
		self.cl.animState = "offline"
		self.interactable:setUvFrameIndex( UV_OFFLINE )
	end

	self.cl.animTime = self.cl.animTime + deltaTime
	local animDone = false
	if self.cl.animTime > self.cl.animDuration then
		self.cl.animTime = math.fmod( self.cl.animTime, self.cl.animDuration )

		--print( "ANIMATION DONE:", self.cl.animName )
		animDone = true
	end

	local craftbotParameter = 1

	if self.cl.animState ~= prevAnimState then
		--print( "NEW ANIMATION STATE:", self.cl.animState )
	end

	local prevAnimName = self.cl.animName

	if self.cl.animState == "offline" then
		assert( self.crafter.needsPower )
		self.cl.animName = "offline"

	elseif self.cl.animState == "idle" then
		if self.cl.animName == "offline" or self.cl.animName == nil then
			if self.crafter.needsPower then
				self.cl.animName = "turnon"
			else
				self.cl.animName = "unfold"
			end
			animDone = true
		elseif self.cl.animName == "turnon" or self.cl.animName == "unfold" or self.cl.animName == "craft_finish" then
			if animDone then
				self.cl.animName = "idle"
			end
		elseif self.cl.animName == "idle" then
			if animDone then
				local rand = math.random( 1, 5 )
				if rand == 1 then
					self.cl.animName = "idlespecial01"
				elseif rand == 2 then
					self.cl.animName = "idlespecial02"
				else
					self.cl.animName = "idle"
				end
			end
		elseif self.cl.animName == "idlespecial01" or self.cl.animName == "idlespecial02" then
			if animDone then
				self.cl.animName = "idle"
			end
		else
			--assert( self.cl.animName == "craft_finish" )
			if animDone then
				self.cl.animName = "idle"
			end
		end

	elseif self.cl.animState == "craft" then
		if self.cl.animName == "idle" or self.cl.animName == "idlespecial01" or self.cl.animName == "idlespecial02" or self.cl.animName == "turnon" or self.cl.animName == "unfold" or self.cl.animName == nil then
			self.cl.animName = "craft_start"
			animDone = true

		elseif self.cl.animName == "craft_start" then
			if animDone then
				if self.interactable:hasAnim( "craft_loop" ) then
					self.cl.animName = "craft_loop"
				else
					self.cl.animName = "craft_loop01"
				end
			end

		elseif self.cl.animName == "craft_loop" then
			if animDone then
				if craftTimeRemaining <= 2 then
					self.cl.animName = "craft_finish"
				else
					--keep looping
				end
			end

		elseif self.cl.animName == "craft_loop01" or self.cl.animName == "craft_loop02" or self.cl.animName == "craft_loop03" then
			if animDone then
				if craftTimeRemaining <= 2 then
					self.cl.animName = "craft_finish"
				else
					local rand = math.random( 1, 4 )
					if rand == 1 and craftTimeRemaining >= self.interactable:getAnimDuration( "craft_loop02" ) then
						self.cl.animName = "craft_loop02"
						craftbotParameter = 2
					elseif rand == 2 and craftTimeRemaining >= self.interactable:getAnimDuration( "craft_loop03" ) then
						self.cl.animName = "craft_loop03"
						craftbotParameter = 3
					else
						self.cl.animName = "craft_loop01"
						craftbotParameter = 1
					end
				end
			end

		elseif self.cl.animName == "craft_finish" then
			if animDone then
				self.cl.animName = "craft_start"
			end

		end
	end

	if self.cl.animName ~= prevAnimName then
		--print( "NEW ANIMATION:", self.cl.animName )

		if prevAnimName then
			self.interactable:setAnimEnabled( prevAnimName, false )
			self.interactable:setAnimProgress( prevAnimName, 0 )
		end

		self.cl.animDuration = self.interactable:getAnimDuration( self.cl.animName )
		self.cl.animTime = 0

		--print( "DURATION:", self.cl.animDuration )

		self.interactable:setAnimEnabled( self.cl.animName, true )
	end

	if animDone then

		local mainEffect = self.cl.mainEffects[self.cl.animName]
		local secondaryEffect = self.cl.secondaryEffects[self.cl.animName]
		local tertiaryEffect = self.cl.tertiaryEffects[self.cl.animName]
		local quaternaryEffect = self.cl.quaternaryEffects[self.cl.animName]

		if mainEffect ~= self.cl.currentMainEffect then

			if self.cl.currentMainEffect ~= self.cl.mainEffects["craft_finish"] then
				if self.cl.currentMainEffect then
					self.cl.currentMainEffect:stop()
				end
			end
			self.cl.currentMainEffect = mainEffect
		end

		if secondaryEffect ~= self.cl.currentSecondaryEffect then

			if self.cl.currentSecondaryEffect then
				self.cl.currentSecondaryEffect:stop()
			end

			self.cl.currentSecondaryEffect = secondaryEffect
		end

		if tertiaryEffect ~= self.cl.currentTertiaryEffect then

			if self.cl.currentTertiaryEffect then
				self.cl.currentTertiaryEffect:stop()
			end

			self.cl.currentTertiaryEffect = tertiaryEffect
		end

		if quaternaryEffect ~= self.cl.currentQuaternaryEffect then

			if self.cl.currentQuaternaryEffect then
				self.cl.currentQuaternaryEffect:stop()
			end

			self.cl.currentQuaternaryEffect = quaternaryEffect
		end

		if self.cl.currentMainEffect then
			self.cl.currentMainEffect:setParameter( "craftbot", craftbotParameter )

			if not self.cl.currentMainEffect:isPlaying() then
				self.cl.currentMainEffect:start()
			end
		end

		if self.cl.currentSecondaryEffect then
			self.cl.currentSecondaryEffect:setParameter( "craftbot", craftbotParameter )

			if not self.cl.currentSecondaryEffect:isPlaying() then
				self.cl.currentSecondaryEffect:start()
			end
		end

		if self.cl.currentTertiaryEffect then
			self.cl.currentTertiaryEffect:setParameter( "craftbot", craftbotParameter )

			if self.shape:getShapeUuid() == obj_craftbot_cookbot then
				local val = self.cl.craftArray and self.cl.craftArray[1] or nil
				if val then
					local cookbotRenderables = effectRenderables[val.recipe.itemId]
					if cookbotRenderables and cookbotRenderables[1] then
						self.cl.currentTertiaryEffect:setParameter( "uuid", cookbotRenderables[1] )
						self.cl.currentTertiaryEffect:setScale( sm.vec3.new( 0.25, 0.25, 0.25 ) )
					end
				end
			end

			if not self.cl.currentTertiaryEffect:isPlaying() then
				self.cl.currentTertiaryEffect:start()
			end
		end

		if self.cl.currentQuaternaryEffect then
			self.cl.currentQuaternaryEffect:setParameter( "craftbot", craftbotParameter )

			if self.shape:getShapeUuid() == obj_craftbot_cookbot then
				local val = self.cl.craftArray and self.cl.craftArray[1] or nil
				if val then
					local cookbotRenderables = effectRenderables[val.recipe.itemId]
					if cookbotRenderables and cookbotRenderables[2] then
						self.cl.currentQuaternaryEffect:setParameter( "uuid", cookbotRenderables[2] )
						self.cl.currentQuaternaryEffect:setScale( sm.vec3.new( 0.25, 0.25, 0.25 ) )
					end
				end
			end

			if not self.cl.currentQuaternaryEffect:isPlaying() then
				self.cl.currentQuaternaryEffect:start()
			end
		end
	end
	assert(self.cl.animName)
	self.interactable:setAnimProgress( self.cl.animName, self.cl.animTime / self.cl.animDuration )

	-- Pipe visualization

	if self.cl.pipeGraphs.input then
		LightUpPipes( self.cl.pipeGraphs.input.pipes )
	end

	if self.cl.pipeGraphs.output then
		LightUpPipes( self.cl.pipeGraphs.output.pipes )
	end

	self.cl.pipeEffectPlayer:update( deltaTime )
end

function ModCrafter.cl_disableAllAnimations( self )
	if self.interactable:hasAnim( "turnon" ) then
		self.interactable:setAnimEnabled( "turnon", false )
	else
		self.interactable:setAnimEnabled( "unfold", false )
	end
	self.interactable:setAnimEnabled( "idle", false )
	self.interactable:setAnimEnabled( "idlespecial01", false )
	self.interactable:setAnimEnabled( "idlespecial02", false )
	self.interactable:setAnimEnabled( "craft_start", false )
	if self.interactable:hasAnim( "craft_loop" ) then
		self.interactable:setAnimEnabled( "craft_loop", false )
	else
		self.interactable:setAnimEnabled( "craft_loop01", false )
		self.interactable:setAnimEnabled( "craft_loop02", false )
		self.interactable:setAnimEnabled( "craft_loop03", false )
	end
	self.interactable:setAnimEnabled( "craft_finish", false )
	self.interactable:setAnimEnabled( "aimbend_updown", false )
	self.interactable:setAnimEnabled( "aimbend_leftright", false )
	self.interactable:setAnimEnabled( "offline", false )
end

function ModCrafter.client_canInteract( self )
	local parent = self:getParent()
	if not self.crafter.needsPower or ( parent and parent.active ) then
		sm.gui.setCenterIcon( "Use" )
		local keyBindingText =  sm.gui.getKeyBinding( "Use" )
		sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_USE}" )
	else
		sm.gui.setCenterIcon( "Hit" )
		sm.gui.setInteractionText( "#{INFO_REQUIRES_POWER}" )
		return false
	end
	return true
end

function ModCrafter.cl_setGuiContainers( self )
	if isAnyOf( self.shape:getShapeUuid(), { sm.uuid.new("03997358-1595-44b5-898a-3ce18285995a") } ) then
		local containers = {}
		if #self.cl.pipeGraphs.input.containers > 0 then
			for _, val in ipairs( self.cl.pipeGraphs.input.containers ) do
				table.insert( containers, val.shape:getInteractable():getContainer( 0 ) )
			end
		else
			table.insert( containers, sm.localPlayer.getPlayer():getInventory() )
		end
		self.cl.guiInterface:setContainers( "", containers )
	else
		self.cl.guiInterface:setContainer( "", sm.localPlayer.getPlayer():getInventory() )
	end
end

function ModCrafter.client_onInteract( self, character, state )
	if state == true then
		local parent = self:getParent()
		if not self.crafter.needsPower or ( parent and parent.active ) then

			self:cl_setGuiContainers()

			for idx = 1, self.crafter.slots do
				local val = self.cl.craftArray[idx]
				if val then
					local recipe = val.recipe
					local recipeCraftTime = math.ceil( recipe.craftTime / self.crafter.speed ) + 120

					local gridItem = {}
					gridItem.itemId = recipe.itemId
					gridItem.craftTime = recipeCraftTime
					gridItem.remainingTicks = recipeCraftTime - clamp( val.time, 0, recipeCraftTime )
					gridItem.locked = false
					gridItem.repeating = val.loop
					self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )

				else
					local gridItem = {}
					gridItem.itemId = "00000000-0000-0000-0000-000000000000"
					gridItem.craftTime = 0
					gridItem.remainingTicks = 0
					gridItem.locked = false
					gridItem.repeating = false
					self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )
				end
			end

			self.cl.guiInterface:setText( "SubTitle", self.crafter.subTitle )
			self.cl.guiInterface:open()

			local pipeConnection = #self.cl.pipeGraphs.output.containers > 0
			self.cl.guiInterface:setVisible( "PipeConnection", pipeConnection )
			self.cl.guiInterface:setVisible( "Upgrade", false )

		end
	end
end

-- Gui callbacks

function ModCrafter.cl_onCraft( self, buttonName, index, data )
	print( "ONCRAFT", index )
	local _, locked = self:getRecipeByIndex( index + 1 )
	if locked then
		print( "Recipe is locked" )
	else
		self.network:sendToServer( "sv_n_craft", { index = index + 1 } )
	end
end

function ModCrafter.sv_n_craft( self, params, player )
	local recipe, locked = self:getRecipeByIndex( params.index )
	if locked then
		print( "Recipe is locked" )
	else
		self:sv_craft( { recipe = recipe }, player )
	end
end

function ModCrafter.sv_craft( self, params, player )
	if #self.sv.craftArray < self.crafter.slots then
		local recipe = params.recipe

		-- Charge container
		sm.container.beginTransaction()

		local containerArray = {}
		local hasInputContainers = #self.sv.pipeGraphs.input.containers > 0

		for _, ingredient in ipairs( recipe.ingredientList ) do
			if hasInputContainers then

				local consumeCount = ingredient.quantity

				for _, container in ipairs( self.sv.pipeGraphs.input.containers ) do
					if consumeCount > 0 then
						consumeCount = consumeCount - sm.container.spend( container.shape:getInteractable():getContainer(), ingredient.itemId, consumeCount, false )
						table.insert( containerArray, { shapesOnContainerPath = container.shapesOnContainerPath, itemId = ingredient.itemId } )
					else
						break
					end
				end

				if consumeCount > 0 then
					print("Could not consume enough of ", ingredient.itemId, " Needed ", consumeCount, " more")
					sm.container.abortTransaction()
					return
				end
			else
				if player then
					sm.container.spend( player:getInventory(), ingredient.itemId, ingredient.quantity )
				end
			end
		end


		if sm.container.endTransaction() then -- Can afford
			print( "Crafting:", recipe.itemId, "x"..recipe.quantity )

			table.insert( self.sv.craftArray, { recipe = recipe, time = -1, loop = params.loop or false } )

			self:sv_markStorageDirty()
			self:sv_markClientDataDirty()

			if #containerArray > 0 then
				self.network:sendToClients( "cl_n_onCraftFromChest", containerArray )
			end
		else
			print( "Can't afford to craft" )
		end
	else
		print( "Craft queue full" )
	end
end

function ModCrafter.cl_n_onCraftFromChest( self, params )
	for _, tbl in ipairs( params ) do
		local shapeList = {}
		for _, shape in reverse_ipairs( tbl.shapesOnContainerPath ) do
			table.insert( shapeList, shape )
		end

		local endNode = PipeEffectNode()
		endNode.shape = self.shape
		endNode.point = sm.vec3.new( -5.0, -2.5, 0.0 ) * sm.construction.constants.subdivideRatio
		table.insert( shapeList, endNode )

		self.cl.pipeEffectPlayer:pushShapeEffectTask( shapeList, tbl.itemId )
	end
end

function ModCrafter.cl_n_onCollectToChest( self, params )

	local startNode = PipeEffectNode()
	startNode.shape = self.shape
	startNode.point = sm.vec3.new( 5.0, -2.5, 0.0 ) * sm.construction.constants.subdivideRatio
	table.insert( params.shapesOnContainerPath, 1, startNode)

	self.cl.pipeEffectPlayer:pushShapeEffectTask( params.shapesOnContainerPath, params.itemId )
end

function ModCrafter.cl_onRepeat( self, buttonName, index, gridItem )
	print( "Repeat pressed", index )
	self.network:sendToServer( "sv_n_repeat", { slot = index } )
end

function ModCrafter.cl_onCollect( self, buttonName, index, gridItem )
	self.network:sendToServer( "sv_n_collect", { slot = index } )
end

function ModCrafter.sv_n_repeat( self, params )
	local val = self.sv.craftArray[params.slot + 1]
	if val then
		val.loop = not val.loop
		self:sv_markStorageDirty()
		self:sv_markClientDataDirty()
	end
end

function ModCrafter.sv_n_collect( self, params, player )
	local val = self.sv.craftArray[params.slot + 1]
	if val then
		local recipe = val.recipe
		if val.time >= math.ceil( recipe.craftTime / self.crafter.speed ) then
			print( "Collecting "..recipe.quantity.."x {"..recipe.itemId.."} to container", player:getInventory() )

			sm.container.beginTransaction()
			sm.container.collect( player:getInventory(), sm.uuid.new( recipe.itemId ), recipe.quantity )
			if recipe.extras then
				print( recipe.extras )
				for _,extra in ipairs( recipe.extras ) do
					sm.container.collect( player:getInventory(), sm.uuid.new( extra.itemId ), extra.quantity )
				end
			end
			if sm.container.endTransaction() then -- Has space
				table.remove( self.sv.craftArray, params.slot + 1 )
				self:sv_markStorageDirty()
				self:sv_markClientDataDirty()
			else
				self.network:sendToClient( player, "cl_n_onMessage", "#{INFO_INVENTORY_FULL}" )
			end
		else
			print( "Not done" )
		end
	end
end

function ModCrafter.sv_spawn( self, spawner )
	print( spawner )

	local val = self.sv.craftArray[1]
	local recipe = val.recipe
	assert( recipe.quantity == 1 )

	local uid = sm.uuid.new( recipe.itemId )
	local rotation = sm.quat.angleAxis( math.pi*0.5, sm.vec3.new( 1, 0, 0 ) )
	local size = rotation * sm.item.getShapeSize( uid )
	local spawnPoint = self.sv.saved.spawner.shape:getWorldPosition() + sm.vec3.new( 0, 0, -1.5 ) - size * sm.vec3.new( 0.125, 0.125, 0.25 )
	local spawnedObject = sm.shape.createPart( uid, spawnPoint, rotation )

	table.remove( self.sv.craftArray, 1 )
	self:sv_markStorageDirty()
	self:sv_markClientDataDirty()

end

function ModCrafter.cl_n_onMessage( self, msg )
	sm.gui.displayAlertText( msg )
end

Modcrafter = class( ModCrafter )
