AntennaTX = class( nil )
AntennaTX.maxChildCount = 0
AntennaTX.connectionOutput = 0
AntennaTX.maxParentCount = 10
AntennaTX.connectionInput = sm.interactable.connectionType.logic
AntennaTX.colorNormal = sm.color.new( 0x00de51ff )
AntennaTX.colorHighlight = sm.color.new( 0x02ee88ff )
AntennaTX.poseWeightCount = 1

AntennaTX.powers = {
	0, 1, 3, 5, 10, 15
}

function AntennaTX.server_onCreate( self )
	self:server_init()
	table.insert(antennatx,self.shape:getId(),self)
end

function AntennaTX.server_onRefresh( self )
	self:server_init()
end

function AntennaTX.server_init( self )
	if antennatx == nil then
		antennatx = {};
	end
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.power == nil or self.saved.powerId == nil then
		self.saved.powerId = 1
		self.saved.power = 0
		self.saved.powertx = 0
		self.interactable:setPower(0)
	end
end

function AntennaTX.changePower ( self, powerId )
	self.saved.powerId = powerId
	self.saved.power = AntennaTX.powers[powerId]
	self.storage:save(self.saved)
end

function AntennaTX.changeStatus ( self, status )
	if self.interactable:isActive() ~= status then
		self.interactable:setActive(status)
	end
end

function AntennaTX.cl_onGuiClosed( self )
	self.gui = false
end

function AntennaTX.cl_onSliderChange( self, sliderName, sliderPos )
	local sliderNewPosition = sliderPos + 1
	self.network:sendToServer("changePower", sliderPos + 1)
	if AntennaTX.powers[sliderNewPosition] ~= 0 then
		sm.gui.displayAlertText( AntennaTX.powers[sliderNewPosition] .. "W" )
	else
		sm.gui.displayAlertText( "OFF" )
	end
end

function AntennaTX.client_onInteract(self, _, state)
	if state then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
			self.gui:setText( "Name", "TRANSMISSION POWER" )
			self.gui:setText( "Interaction", "Drag to adjust power level." )
			self.gui:setOnCloseCallback( "cl_onGuiClosed" )
			self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
			self.gui:setSliderData( "Setting", #AntennaTX.powers, self.saved.powerId - 1 )
			self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
			self.gui:open()
		else
	    self.gui = nil
	  end
	end
end

function AntennaTX.server_onFixedUpdate( self, dt )

	if self.saved.power > 0 then
		self.saved.powertx = self.saved.power * self.shape:getWorldPosition().z
		self.interactable:setPower(self.saved.powertx)
  else
		self.saved.powertx = 0
		self.interactable:setPower(0)
	end
end

function AntennaTX.server_onDestroy( self )
	for k, value in pairs (antennatx) do
		if value.shape == self.shape then
			antennatx[k] = nil
		end
	end
end

function AntennaTX.client_onDestroy( self )
	if self.gui then
		self.effect:destroy()
		self.gui:close()
		self.gui = nil
	end
end
