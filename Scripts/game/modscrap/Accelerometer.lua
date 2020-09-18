Accelerometer = class( nil )
Accelerometer.maxParentCount = 0
Accelerometer.maxChildCount = 64
Accelerometer.connectionInput = 0
Accelerometer.connectionOutput = sm.interactable.connectionType.logic
Accelerometer.colorNormal = sm.color.new( 0x009999ff  )
Accelerometer.colorHighlight = sm.color.new( 0x11B2B2ff  )
Accelerometer.poseWeightCount = 1

Accelerometer.types = {
	"OFF", "LOW ACCURACY", "HIGH ACCURACY"
}
Accelerometer.typesPositions = {
	0, 1, 2
}

function Accelerometer.cl_onGuiClosed( self )
	self.gui = false
end

function Accelerometer.server_onCreate( self )
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

function Accelerometer.sv_saveChanges( self )
	self.storage:save( self.saved )
end

function Accelerometer.cl_onSliderChange( self, sliderName, sliderPos )
	local sliderNewPosition = sliderPos + 1
	self.saved.sensorType = Accelerometer.types[sliderNewPosition]
  self.saved.sensorTypeId = sliderNewPosition
	self.saved.sensorPosition = Accelerometer.typesPositions[sliderNewPosition]
	sm.gui.displayAlertText( self.saved.sensorType )
	self.network:sendToServer("sv_saveChanges")
end

function Accelerometer.client_onInteract( self, character, state )
  if self.gui == nil then
    self.gui = sm.gui.createEngineGui()
  	self.gui:setText( "Name", "ACCELEROMETER" )
  	self.gui:setText( "Interaction", "Drag to change accuracy" )
  	self.gui:setOnCloseCallback( "cl_onGuiClosed" )
    self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
  	self.gui:setSliderData( "Setting", #Accelerometer.types, self.saved.sensorTypeId - 1 )
  	self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
  	self.gui:open()
  else
    self.gui = nil
  end
end

function Accelerometer.client_onFixedUpdate( self, timeStep )
	if self.interactable:isActive() == true then
		sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
	else
    sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function Accelerometer.server_onFixedUpdate( self, dt )
	local vec3velocity = self.shape:getVelocity()
	local velocity = vec3velocity.x + vec3velocity.y + vec3velocity.z
	if self.saved.sensorPosition > 0 then
		if self.saved.sensorPosition == 1 then
			if velocity > 0.1 or velocity < -0.1 then
				self.interactable:setActive(true)
			else
				self.interactable:setActive(false)
			end
		end
		if self.saved.sensorPosition == 2 then
			if velocity ~= 0 then
				self.interactable:setActive(true)
			else
				self.interactable:setActive(false)
			end
		end
	else
		self.interactable:setActive(false)
	end
end

function Accelerometer.server_onDestroy( self )
	self.saved = nil
end
