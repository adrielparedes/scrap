-- StackContainer.lua --

dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

StackContainer = class( nil )
StackContainer.maxChildCount = 255

local ContainerSize = 30

function StackContainer.server_onCreate( self )
	if self.data.stackSize == nil then
		self.data.stackSize = 256
	end
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, ContainerSize, self.data.stackSize )
	end
	if self.data.filterUid then
		local filters = { sm.uuid.new( self.data.filterUid ) }
		container:setFilters( filters )
	end
end

function StackContainer.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function StackContainer.client_onInteract( self, character, state )
	if state == true then
		local container = self.shape.interactable:getContainer( 0 )
		if container then
			local gui = nil
			local shapeUuid = self.shape:getShapeUuid()
			gui = sm.gui.createContainerGui( true )
			gui:setText( "UpperName", "CONTENTS" )
			gui:setContainer( "UpperGrid", container )
			gui:setText( "LowerName", "BACKPACK" )
			gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
			gui:open()
		end
	end
end

function StackContainer.client_onUpdate( self, dt )

	local container = self.shape.interactable:getContainer( 0 )
	if container then
		local quantities = sm.container.quantity( container )

		local quantity = 0
		for _,q in ipairs(quantities) do
			quantity = quantity + q
		end

		if self.data.stackSize == nil then
			self.data.stackSize = 256
		end

		local frame = ContainerSize - math.ceil( quantity / self.data.stackSize )
		self.interactable:setUvFrameIndex( frame )
	end
end

TomatoContainer = class( StackContainer )

local TomatoUuid = {
	obj_plantables_tomato,
}

function TomatoContainer.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container =	self.shape:getInteractable():addContainer( 0, 20, 65535 )
	end
	container:setFilters( TomatoUuid )
end

BlueberryContainer = class( StackContainer )

local BlueberryUuid = {
	obj_plantables_blueberry,
}

function BlueberryContainer.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container =	self.shape:getInteractable():addContainer( 0, 20, 65535 )
	end
	container:setFilters( BlueberryUuid )
end

StackedContainer = class( StackContainer )

function StackedContainer.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container =	self.shape:getInteractable():addContainer( 0, 20, 65535 )
	end
end
