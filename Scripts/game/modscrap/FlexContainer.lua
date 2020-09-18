-- ConsumableFlexContainer.lua --

dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

ConsumableFlexContainer = class( nil )
ConsumableFlexContainer.maxChildCount = 255

local ContainerSize = 5

function ConsumableFlexContainer.server_onCreate( self )
	if self.data.stackSize == nil then
		self.data.stackSize = 20
	end
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, ContainerSize, self.data.stackSize )
	end
	if self.data.filterUid then
		local filters = { sm.uuid.new( self.data.filterUid ) }
		if self.data.filterUidFlex then
			filters = { sm.uuid.new( self.data.filterUid ), sm.uuid.new( self.data.filterUidFlex ) }
		end
		container:setFilters( filters )
	end
end

function ConsumableFlexContainer.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function ConsumableFlexContainer.client_onInteract( self, character, state )
	if state == true then
		local container = self.shape.interactable:getContainer( 0 )
		if container then
			local gui = nil

			local shapeUuid = self.shape:getShapeUuid()

			if shapeUuid == sm.uuid.new("ebb4f460-a618-413f-865a-2073aeec7c5f") or shapeUuid == obj_container_flexgas then
				gui = sm.gui.createGasContainerGui( true )
				gui:setText( "UpperName", "             GASOLINE OR CHEMICAL GAS" )

			elseif shapeUuid == sm.uuid.new("2482c8db-ded7-4d88-b1fe-d93f19cd3b31") or shapeUuid == obj_container_crudeoil then
				gui = sm.gui.createGasContainerGui( true )
				gui:setText( "UpperName", "CRUDE OIL" )
			end

			if gui == nil then
				gui = sm.gui.createContainerGui( true )
				gui:setText( "UpperName", "CONTAINER" )
			end

			gui:setContainer( "UpperGrid", container )
			gui:setText( "LowerName", "BACKPACK" )
			gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
			gui:open()
		end
	end
end

function ConsumableFlexContainer.client_onUpdate( self, dt )

	local container = self.shape.interactable:getContainer( 0 )
	if container then
		local quantities = sm.container.quantity( container )

		local quantity = 0
		for _,q in ipairs(quantities) do
			quantity = quantity + q
		end

		if self.data.stackSize == nil then
			self.data.stackSize = 20
		end

		local frame = ContainerSize - math.ceil( quantity / self.data.stackSize )
		self.interactable:setUvFrameIndex( frame )
	end
end

FlexContainer = class( ConsumableFlexContainer )
FlexContainer.connectionOutput = sm.interactable.connectionType.gasoline
FlexContainer.colorNormal = sm.color.new( 0x84ff32ff )
FlexContainer.colorHighlight = sm.color.new( 0xa7ff4fff )


