-- FlexEngine.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

FlexEngine = class()
FlexEngine.maxParentCount = 2
FlexEngine.maxChildCount = 255
FlexEngine.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power + sm.interactable.connectionType.gasoline
FlexEngine.connectionOutput = sm.interactable.connectionType.bearing
FlexEngine.colorNormal = sm.color.new( 0xff8000ff )
FlexEngine.colorHighlight = sm.color.new( 0xff9f3aff )
FlexEngine.poseWeightCount = 1

local Gears = {
	{ power = 0 },
	{ power = 30 },
	{ power = 60 },
	{ power = 90 },
	{ power = 150 }, -- 1
	{ power = 240 },
	{ power = 390 }, -- 2
	{ power = 630 },
	{ power = 1020 }, -- 3
	{ power = 1650 },
	{ power = 2670 }, -- 4
	{ power = 4320 },
	{ power = 6990 }, -- 5
}

local v6gears = {
	{ power = 0 },
	{ power = 90 },
	{ power = 150 },
	{ power = 240 },
	{ power = 390 }, -- 1
	{ power = 630 },
	{ power = 1020 }, -- 2
	{ power = 1650 },
	{ power = 2670 }, -- 3
	{ power = 4320 },
	{ power = 5500 }, -- 4
	{ power = 6900 },
	{ power = 8200 }, -- 5
}

local v8gears = {
	{ power = 0 },
	{ power = 150 },
	{ power = 240 },
	{ power = 390 },
	{ power = 630 }, -- 1
	{ power = 1020 },
	{ power = 1650 }, -- 2
	{ power = 2670 },
	{ power = 4320 }, -- 3
	{ power = 5500 },
	{ power = 6900 }, -- 4
	{ power = 8200 },
	{ power = 9600 }, -- 5
}
local tractorGears = {
	{ power = 5000, velocity = math.rad( 0 ) },
	{ power = 5000, velocity = math.rad( 30 ) },
	{ power = 5000, velocity = math.rad( 60 ) },
	{ power = 5000, velocity = math.rad( 90 ) },
}


local EngineLevels = {
	[tostring(sm.uuid.new("00a0333c-3a41-4c83-b758-817cb81a8272"))] = {
		gears = Gears,
		effect = "GasEngine - Level 1",
		upgrade = tostring(sm.uuid.new("524b0ab5-d478-4fb6-bc68-588286959759")),
		cost = 4,
		title = "LEVEL 1",
		gearCount = 5,
		bearingCount = 2,
		pointsPerFuel = 4000
	},
	[tostring(sm.uuid.new("524b0ab5-d478-4fb6-bc68-588286959759"))] = {
		gears = Gears,
		effect = "GasEngine - Level 2",
		upgrade = tostring(sm.uuid.new("d1d80aa7-627f-4e5e-91d4-5030a4923efd")),
		cost = 6,
		title = "LEVEL 2",
		gearCount = 7,
		bearingCount = 4,
		pointsPerFuel = 6000
	},
	[tostring(sm.uuid.new("d1d80aa7-627f-4e5e-91d4-5030a4923efd"))] = {
		gears = Gears,
		effect = "GasEngine - Level 3",
		upgrade = tostring(sm.uuid.new("1f519487-8485-415a-9a2b-10f55475867b")),
		cost = 8,
		title = "LEVEL 3",
		gearCount = 9,
		bearingCount = 6,
		pointsPerFuel = 9000
	},
	[tostring(sm.uuid.new("1f519487-8485-415a-9a2b-10f55475867b"))] = {
		gears = Gears,
		effect = "GasEngine - Level 4",
		upgrade = tostring(sm.uuid.new("2ecc65e1-0fe0-4e39-aeff-2ac41c1acf12")),
		cost = 10,
		title = "LEVEL 4",
		gearCount = 11,
		bearingCount = 8,
		pointsPerFuel = 12000
	},
	[tostring(sm.uuid.new("2ecc65e1-0fe0-4e39-aeff-2ac41c1acf12"))] = {
		gears = Gears,
		effect = "GasEngine - Level 5",
		title = "LEVEL 5",
		gearCount = #Gears,
		bearingCount = 10,
		pointsPerFuel = 20000
	},
	[tostring(sm.uuid.new("9966492a-75a4-4c0c-b387-c918c1551429"))] = {
		gears = Gears,
		effect = "GasEngine - Level 5",
		title = "LEVEL 5",
		gearCount = #v6gears,
		bearingCount = 10,
		pointsPerFuel = 20000
	},
	[tostring(sm.uuid.new("3e85beeb-d53a-43e3-b9eb-7ec4e963e9cb"))] = {
		gears = Gears,
		effect = "GasEngine - Level 5",
		title = "LEVEL 5",
		gearCount = #v8gears,
		bearingCount = 10,
		pointsPerFuel = 20000
	},
	[tostring(sm.uuid.new("62463280-39be-40a2-9222-cf752d15d354"))] = {
		gears = Gears,
		effect = "GasEngine - Level 3",
		title = "LEVEL 5",
		gearCount = #tractorGears,
		bearingCount = 16,
		pointsPerFuel = 30000
	},
}

local RadPerSecond_100KmPerHourOn3BlockDiameterTyres = 74.074074
local RadPerSecond_1MeterPerSecondOn3BlockDiameterTyres = 2.6666667

--[[ Server ]]

function FlexEngine.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, 1, 10 )
	end
	container:setFilters( { obj_consumable_gas, sm.uuid.new( "b4ec8fce-adbb-11ea-a64d-0242ac130004" ) } )

	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	assert(level)
	if level.fn then
		level.fn( self )
	end
	if level.gears == ScrapGears then
		self.scrapOffset = math.random(0, 80)
	else
		self.scrapOffset = 0
	end
	self.pointsPerFuel = level.pointsPerFuel
	self.gears = level.gears
	self:server_init()
end

function FlexEngine.server_onRefresh( self )
	self:server_init()
end

function FlexEngine.server_init( self )

	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.gearIdx == nil then
		self.saved.gearIdx = 1
	end
	if self.saved.fuelPoints == nil then
		self.saved.fuelPoints = 0
	end

	self.power = 0
	self.motorVelocity = 0
	self.motorImpulse = 0
	self.fuelPoints = self.saved.fuelPoints
	self.hasFuel = false
	self.gasType = 0
	self.dirtyStorageTable = false
	self.dirtyClientTable = false

	self:sv_setGear( self.saved.gearIdx )
end

function FlexEngine.sv_setGear( self, gearIdx )
	self.saved.gearIdx = gearIdx
	self.dirtyStorageTable = true
	self.dirtyClientTable = true
end

function FlexEngine.sv_updateFuelStatus( self, fuelContainer )

	if self.saved.fuelPoints ~= self.fuelPoints then
		self.saved.fuelPoints = self.fuelPoints
		self.dirtyStorageTable = true
	end

	local canSpendChemicalGas = sm.container.canSpend( fuelContainer, sm.uuid.new( "b4ec8fce-adbb-11ea-a64d-0242ac130004" ), 1 )
	if ( self.fuelPoints > 0 and self.gasType == 1 ) or canSpendChemicalGas then
		if self.hasFuel ~= hasFuel then
			self.hasFuel = hasFuel
			if self.fuelPoints > 0 then
				self.gasType = 1
			else
				self.gasType = -1
			end
			self.dirtyClientTable = true
		end
	else
		local canSpendGasoline = sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 )
		if ( self.fuelPoints > 0 and self.gasType == 0 ) or canSpendGasoline then
			if self.hasFuel ~= hasFuel then
				self.hasFuel = hasFuel
				if self.fuelPoints > 0 then
					self.gasType = 0
				else
					self.gasType = -1
				end
				self.dirtyClientTable = true
			end
		end
	end

end

function FlexEngine.controlEngine( self, direction, active, timeStep, gearIdx )

	direction = clamp( direction, -1, 1 )
	if ( math.abs( direction ) > 0 or not active ) then
		self.power = self.power + timeStep
	else
		self.power = self.power - timeStep
	end
	self.power = clamp( self.power, 0, 1 )

	if direction == 0 and active then
		self.power = 0
	end

	if self.gears == ScrapGears then
		if active then
			local t = ( sm.game.getServerTick() + self.scrapOffset ) * 2.0 * math.pi / 120
			local scale = ( math.sin( t * 1.1 ) + math.sin( t * 1.7 ) + math.sin( t * 3.1 ) ) / 3
			self.motorVelocity = direction * ( 10 + scale * 4 ) * RadPerSecond_1MeterPerSecondOn3BlockDiameterTyres
			scale = ( math.sin( t ) + math.sin( t * 1.3 ) + math.sin( t * 2.9 ) ) / 3
			self.motorImpulse = self.power * self.gears[gearIdx].power * ( 1 + scale )
			--print("Velocity: ", self.motorVelocity, " - Impulse: ", self.motorImpulse)
		else
			self.motorVelocity = 0
			self.motorImpulse = 0
		end
	else
		self.motorVelocity = ( active and direction or 0 ) * RadPerSecond_100KmPerHourOn3BlockDiameterTyres
		self.motorImpulse = ( active and self.power or 2 ) * self.gears[gearIdx].power
	end
end

function FlexEngine.getInputs( self )

	local parents = self.interactable:getParents()
	local active = true
	local direction = 1
	local fuelContainer = nil
	local hasInput = false
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
			hasInput = true
		end
		if parents[2]:hasOutputType( sm.interactable.connectionType.power ) then
			active = parents[2]:isActive()
			direction = parents[2]:getPower()
			hasInput = true
		end
		if parents[2]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
			hasInput = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.power ) then
			active = parents[1]:isActive()
			direction = parents[1]:getPower()
			hasInput = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[1]:getContainer( 0 )
		end
	end

	return active, direction, fuelContainer, hasInput

end

function FlexEngine.server_onFixedUpdate( self, timeStep )

	-- Check engine connections
	local hadInput = self.hasInput == nil and true or self.hasInput --Pretend to have had input if nil to avoid starting engines at load
	local active, direction, fuelContainer, hasInput = self:getInputs()
	self.hasInput = hasInput

	-- Check fuel container
	if not fuelContainer or fuelContainer:isEmpty() then
		fuelContainer = self.shape.interactable:getContainer( 0 )
	end

	-- Check bearings
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	-- Update motor gear when a steering is added
	if not hadInput and hasInput then
		if self.saved.gearIdx == 1 then
			self:sv_setGear( 2 )
		end
	end

	-- Consume fuel for fuel points
	if self.fuelPoints <= 0 then
		canSpendGasoline = sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 )
		canSpendChemicalGas = sm.container.canSpend( fuelContainer, sm.uuid.new( "b4ec8fce-adbb-11ea-a64d-0242ac130004" ), 1 )
	end

	-- Control engine
	if ( self.fuelPoints > 0 ) or canSpendGasoline or canSpendChemicalGas then

		if hasInput == false then
			self.power = 1
			self:controlEngine( 1, true, timeStep, self.saved.gearIdx )
		else
			self:controlEngine( direction, active, timeStep, self.saved.gearIdx )
		end

		-- Consume fuel points
		local appliedImpulseCost = 0.015625
		local fuelCost = 0
		for _, bearing in ipairs( bearings ) do
			if bearing.appliedImpulse * bearing.angularVelocity <= 0 then -- No added fuel cost if the bearing is decelerating
				if self.gasType == 1 or canSpendChemicalGas then
					fuelCost = fuelCost + math.abs( bearing.appliedImpulse ) * appliedImpulseCost * 2
				else
					fuelCost = fuelCost + math.abs( bearing.appliedImpulse ) * appliedImpulseCost
				end
			end
		end
		fuelCost = math.min( fuelCost, math.sqrt( fuelCost / 7.5 ) * 7.5 )

		self.fuelPoints = self.fuelPoints - fuelCost

		if self.fuelPoints <= 0 and fuelCost > 0 then
			sm.container.beginTransaction()

			if self.gasType == 1 or canSpendChemicalGas then
				sm.container.spend( fuelContainer, sm.uuid.new( "b4ec8fce-adbb-11ea-a64d-0242ac130004" ), 1, true )
			else
				sm.container.spend( fuelContainer, obj_consumable_gas, 1, true )
			end
			if sm.container.endTransaction() then
				self.fuelPoints = self.fuelPoints + self.pointsPerFuel
			end

		end

	else
		self:controlEngine( 0, false, timeStep, self.saved.gearIdx )
	end

	-- Update rotational joints
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
	end

	self:sv_updateFuelStatus( fuelContainer )

	-- Storage table dirty
	if self.dirtyStorageTable then
		self.storage:save( self.saved )
		self.dirtyStorageTable = false
	end

	-- Client table dirty
	if self.dirtyClientTable then
		self.network:setClientData( { gearIdx = self.saved.gearIdx, engineHasFuel = self.hasFuel, scrapOffset = self.scrapOffset } )
		self.dirtyClientTable = false
	end
end

--[[ Client ]]

function FlexEngine.client_onCreate( self )
	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	self.gears = level.gears
	self.client_gearIdx = 1
	self.effect = sm.effect.createEffect( level.effect, self.interactable )
	self.engineHasFuel = false
	self.scrapOffset = self.scrapOffset or 0
	self.power = 0
end

function FlexEngine.client_onClientDataUpdate( self, params )

	if self.gui then
		if self.gui:isActive() and params.gearIdx ~= self.client_gearIdx then
			self.gui:setSliderPosition("Setting", params.gearIdx - 1 )
		end
	end

	self.client_gearIdx = params.gearIdx
	self.interactable:setPoseWeight( 0, params.gearIdx / #self.gears )

	if self.engineHasFuel and not params.engineHasFuel then
		local character = sm.localPlayer.getPlayer().character
		if character then
			if ( self.shape.worldPosition - character.worldPosition ):length2() < 100 then
				sm.gui.displayAlertText( "#{INFO_OUT_OF_FUEL}" )
			end
		end
	end

	if params.engineHasFuel then
		self.effect:setParameter("gas", 0.0 )
	else
		self.effect:setParameter("gas", 1.0 )
	end

	self.engineHasFuel = params.engineHasFuel
	self.scrapOffset = params.scrapOffset
end

function FlexEngine.client_onDestroy( self )
	self.effect:destroy()

	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function FlexEngine.client_onFixedUpdate( self, timeStep )

	local active, direction, externalFuelTank, hasInput = self:getInputs()


	if self.gui then
		self.gui:setVisible( "FuelContainer", externalFuelTank ~= nil )
	end

	if sm.isHost then
		return
	end

	-- Check bearings
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	-- Control engine
	if self.engineHasFuel then
		if hasInput == false then
			self.power = 1

			self:controlEngine( 1, true, timeStep, self.client_gearIdx )
		else

			self:controlEngine( direction, active, timeStep, self.client_gearIdx )
		end
	else
		self:controlEngine( 0, false, timeStep, self.client_gearIdx )
	end

	-- Update rotational joints
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
	end
end

function FlexEngine.client_onUpdate( self, dt )

	local active, direction = self:getInputs()

	self:cl_updateEffect( direction, active )
end

function FlexEngine.client_onInteract( self, character, state )
	if state == true then
		self.gui = sm.gui.createEngineGui()

		self.gui:setText( "Name", "F L E X   E N G I N E" )
		self.gui:setText( "Interaction", "Drag to adjust engine power" )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setSliderData( "Setting", #self.gears, self.client_gearIdx - 1 )
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setButtonCallback( "Upgrade", "cl_onUpgradeClicked" )

		local fuelContainer = self.shape.interactable:getContainer( 0 )

		if fuelContainer then
			self.gui:setContainer( "Fuel", fuelContainer )
		end

		local _, _, externalFuelContainer, _ = self:getInputs()

		if externalFuelContainer then
			self.gui:setVisible( "FuelContainer", true )
		end

		self.gui:open()

		local level = EngineLevels[ tostring( self.shape:getShapeUuid() ) ]
		if level then
			if level.upgrade then
				local nextLevel = EngineLevels[ level.upgrade ]
				self.gui:setData( "UpgradeInfo", { Gears = nextLevel.gearCount - level.gearCount, Bearings = nextLevel.bearingCount - level.bearingCount, Efficiency = 1 } )
				self.gui:setIconImage( "UpgradeIcon", sm.uuid.new( level.upgrade ) )
			else
				self.gui:setVisible( "UpgradeIcon", false )
				self.gui:setData( "UpgradeInfo", nil )
			end

			self.gui:setText( "SubTitle", level.title )
			self.gui:setSliderRangeLimit( "Setting", level.gearCount )

			if level.cost then
				local inventory = sm.localPlayer.getPlayer():getInventory()
				local availableKits = sm.container.totalQuantity( inventory, obj_consumable_component )

				local upgradeData = { cost = level.cost, available = availableKits }
				self.gui:setData( "Upgrade", upgradeData )
			else
				self.gui:setVisible( "Upgrade", false )
			end
		end
	end
end

function FlexEngine.client_getAvailableParentConnectionCount( self, connectionType )
	if bit.band( connectionType, bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.power ) ) ~= 0 then
		return 1 - #self.interactable:getParents( bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.power ) )
	end
	if bit.band( connectionType, sm.interactable.connectionType.gasoline ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.gasoline )
	end
	return 0
end

function FlexEngine.client_getAvailableChildConnectionCount( self, connectionType )
	if connectionType ~= sm.interactable.connectionType.bearing then
		return 0
	end
	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	assert(level)
	local maxBearingCount = level.bearingCount or 255
	return maxBearingCount - #self.interactable:getChildren( sm.interactable.connectionType.bearing )
end

function FlexEngine.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function FlexEngine.cl_onSliderChange( self, sliderName, sliderPos )
	self.network:sendToServer( "sv_setGear", sliderPos + 1 )
	self.client_gearIdx = sliderPos + 1
end

function FlexEngine.cl_onUpgradeClicked( self, buttonName )
	print( "upgrade clicked" )
	self.network:sendToServer("sv_n_tryUpgrade", sm.localPlayer.getPlayer() )
end

function FlexEngine.cl_updateEffect( self, direction, active )
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	local RadPerSecond_100KmPerHourOn3BlockDiameterTyres = 74.074074
	local avgImpulse = 0
	local avgVelocity = 0

	if #bearings > 0 then
		for _, currentBearing in ipairs( bearings ) do
			avgImpulse = avgImpulse + math.abs( currentBearing.appliedImpulse )
			avgVelocity = avgVelocity + math.abs( currentBearing.angularVelocity )
		end

		avgImpulse = avgImpulse / #bearings
		avgVelocity = avgVelocity / #bearings

		avgVelocity = math.min( avgVelocity, RadPerSecond_100KmPerHourOn3BlockDiameterTyres )
	end

	local impulseFraction = 0
	local velocityFraction = avgVelocity / ( RadPerSecond_100KmPerHourOn3BlockDiameterTyres / 1.2 )

	if direction ~= 0 and self.gears[self.client_gearIdx].power > 0 then
		impulseFraction = math.abs( avgImpulse ) / self.gears[self.client_gearIdx].power
	end

	local maxRPM = 0.9 * (self.client_gearIdx / #self.gears)
	local rpm = 0.1

	if avgVelocity > 0 then
		rpm = rpm + math.min( velocityFraction * maxRPM, maxRPM )
	end

	local engineLoad = 0

	if direction ~= 0 then
		engineLoad = impulseFraction - math.min( velocityFraction, 1.0 )
	end

	if #self.interactable:getParents() == 0 then
		if self.effect:isPlaying() == false and #bearings > 0 and self.gears[self.client_gearIdx].power > 0 then
			self.effect:start()
		elseif self.effect:isPlaying() and ( #bearings == 0 or self.gears[self.client_gearIdx].power == 0 ) then
			self.effect:setParameter( "load", 0.5 )
			self.effect:setParameter( "rpm", 0 )
			self.effect:stop()
		end
	else
		if self.effect:isPlaying() and ( #bearings == 0 or active == false or self.gears[self.client_gearIdx].power == 0 ) then
			self.effect:setParameter( "load", 0.5 )
			self.effect:setParameter( "rpm", 0 )
			self.effect:stop()
		elseif self.effect:isPlaying() == false and #bearings > 0 and active == true and self.gears[self.client_gearIdx].power > 0 then
			self.effect:start()
		end
	end

	if self.effect:isPlaying() then
		self.effect:setParameter( "rpm", rpm )
		self.effect:setParameter( "load", engineLoad * 0.5 + 0.5 )
	end
end

function FlexEngine.sv_n_tryUpgrade( self, player )

	local level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	if level and level.upgrade then

		local inventory = player:getInventory()

		if sm.container.totalQuantity( inventory, obj_consumable_component ) >= level.cost then

			if sm.container.beginTransaction() then
				sm.container.spend( inventory, obj_consumable_component, level.cost, true )

				if sm.container.endTransaction() then
					local nextLevel = EngineLevels[level.upgrade]
					assert( nextLevel )
					self.gears = nextLevel.gears
					self.network:sendToClients( "cl_n_onUpgrade", level.upgrade )

					if nextLevel.fn then
						nextLevel.fn( self )
					end

					self.shape:replaceShape( sm.uuid.new( level.upgrade ) )
				end
			end
		else
			print( "Cannot afford upgrade" )
		end
	else
		print( "Can't be upgraded" )
	end

end

function FlexEngine.cl_n_onUpgrade( self, upgrade )
	local level = EngineLevels[upgrade]
	self.gears = level.gears
	self.pointsPerFuel = level.pointsPerFuel

	if self.gui and self.gui:isActive() then
		self.gui:setIconImage( "Icon", sm.uuid.new( upgrade ) )

		if level.cost then
			local inventory = sm.localPlayer.getPlayer():getInventory()
			local availableKits = sm.container.totalQuantity( inventory, obj_consumable_component )

			local upgradeData = { cost = level.cost, available = availableKits }
			self.gui:setData( "Upgrade", upgradeData )
		else
			self.gui:setVisible( "Upgrade", false )
		end

		self.gui:setText( "SubTitle", level.title )
		self.gui:setSliderRangeLimit( "Setting", level.gearCount )
		if level.upgrade then
			local nextLevel = EngineLevels[ level.upgrade ]
			self.gui:setData( "UpgradeInfo", { Gears = nextLevel.gearCount - level.gearCount, Bearings = nextLevel.bearingCount - level.bearingCount, Efficiency = 1 } )
			self.gui:setIconImage( "UpgradeIcon", sm.uuid.new( level.upgrade ) )
		else
			self.gui:setVisible( "UpgradeIcon", false )
			self.gui:setData( "UpgradeInfo", nil )
		end
	end

	if self.effect then
		--self.effect:destroy()
	end
	self.effect = sm.effect.createEffect( level.effect, self.interactable )
	sm.effect.playHostedEffect( "Part - Upgrade", self.interactable )
end
