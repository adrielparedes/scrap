TiltSensor = class( nil )
TiltSensor.maxParentCount = 0
TiltSensor.maxChildCount = 64
TiltSensor.connectionInput = 0
TiltSensor.connectionOutput = sm.interactable.connectionType.logic
TiltSensor.colorNormal = sm.color.new( 0x009999ff  )
TiltSensor.colorHighlight = sm.color.new( 0x11B2B2ff  )
TiltSensor.poseWeightCount = 1

TiltSensor.types = {
	"OFF", "TURN ON WITH 5° OF INCLINATION", "TURN ON WITH 15° OF INCLINATION", "TURN ON WITH 30° OF INCLINATION", "TURN ON WITH 45° OF INCLINATION", "TURN ON WITH 60° OF INCLINATION", "TURN ON WITH 75° OF INCLINATION", "TURN ON WITH 90° OF INCLINATION"
}
TiltSensor.typesPositions = {
	0, 5, 14.82, 28.64, 40, 49, 55, 57
}

function TiltSensor.cl_onGuiClosed( self )
	self.gui = false
end

function TiltSensor.server_onCreate( self )
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

function TiltSensor.sv_saveChanges( self )
	self.storage:save( self.saved )
end

function TiltSensor.cl_onSliderChange( self, sliderName, sliderPos )
	local sliderNewPosition = sliderPos + 1
	self.saved.sensorType = TiltSensor.types[sliderNewPosition]
  self.saved.sensorTypeId = sliderNewPosition
	self.saved.sensorPosition = TiltSensor.typesPositions[sliderNewPosition]
	sm.gui.displayAlertText( self.saved.sensorType )
	self.network:sendToServer("sv_saveChanges")
end

function TiltSensor.client_onInteract( self, character, state )
  if self.gui == nil then
    self.gui = sm.gui.createEngineGui()
  	self.gui:setText( "Name", "TILT SENSOR" )
  	self.gui:setText( "Interaction", "Drag to change activation degrees" )
  	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
    self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
  	self.gui:setSliderData( "Setting", #TiltSensor.types, self.saved.sensorTypeId - 1 )
  	self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
  	self.gui:open()
  else
    self.gui = nil
  end
end

function TiltSensor.client_onFixedUpdate( self, timeStep )
	if self.interactable:isActive() == true then
		sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
	else
    sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function TiltSensor.server_onFixedUpdate( self, dt )
	local degrees = self.shape:getUp().z
	degrees = math.deg(degrees)
	if degrees > self.saved.sensorPosition then
		self.interactable:setActive(true)
	else
		self.interactable:setActive(false)
	end
end

function TiltSensor.server_onDestroy( self )
	self.saved = nil
end
