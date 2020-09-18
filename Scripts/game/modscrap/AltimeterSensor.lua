AltimeterSensor = class( nil )
AltimeterSensor.maxParentCount = 0
AltimeterSensor.maxChildCount = 64
AltimeterSensor.connectionInput = 0
AltimeterSensor.connectionOutput = sm.interactable.connectionType.logic
AltimeterSensor.colorNormal = sm.color.new( 0x009999ff  )
AltimeterSensor.colorHighlight = sm.color.new( 0x11B2B2ff  )
AltimeterSensor.poseWeightCount = 1

AltimeterSensor.types = {
	"OFF", "1", "2", "3", "4", "5", "10", "25", "50", "100"
}
AltimeterSensor.typesPositions = {
	0, 1, 2, 3, 4, 5, 10, 25, 50, 100
}

function AltimeterSensor.cl_onGuiClosed( self )
	self.gui = false
end

function AltimeterSensor.server_onCreate( self )
  self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.sensorType == nil or self.saved.sensorTypeId == nil or self.saved.sensorPosition == nil then
		self.saved.sensorType = "OFF"
		self.saved.sensorTypeId = 1
		self.saved.sensorPosition = 0
	end
  self.interactable:setActive(false)
end

function AltimeterSensor.sv_saveChanges( self )
	self.storage:save( self.saved )
end

function AltimeterSensor.cl_onSliderChange( self, sliderName, sliderPos )
	local sliderNewPosition = sliderPos + 1
	self.saved.sensorType = AltimeterSensor.types[sliderNewPosition]
  self.saved.sensorTypeId = sliderNewPosition
	self.saved.sensorPosition = AltimeterSensor.typesPositions[sliderNewPosition]
	sm.gui.displayAlertText( self.saved.sensorType )
	self.network:sendToServer("sv_saveChanges")
end

function AltimeterSensor.client_onInteract( self, character, state )
  if self.gui == nil then
    self.gui = sm.gui.createEngineGui()
  	self.gui:setText( "Name", "ALTIMETER" )
  	self.gui:setText( "Interaction", "Drag to change altitude" )
  	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
    self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
  	self.gui:setSliderData( "Setting", #AltimeterSensor.types, self.saved.sensorTypeId - 1 )
  	self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
  	self.gui:open()
  else
    self.gui = nil
  end
end

function AltimeterSensor.client_onFixedUpdate( self, timeStep )
	if self.interactable:isActive() == true then
		sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
	else
    sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function AltimeterSensor.server_onFixedUpdate( self, dt )
	local altitude = self.shape:getWorldPosition().z
	if self.saved.sensorPosition > 0 then
		if altitude > self.saved.sensorPosition then
			self.interactable:setActive(true)
		else
			self.interactable:setActive(false)
		end
	end
end

function AltimeterSensor.server_onDestroy( self )
	self.saved = nil
end
