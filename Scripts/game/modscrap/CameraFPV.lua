CameraFPV = class()
CameraFPV.maxParentCount = 1
CameraFPV.maxChildCount = 64
CameraFPV.connectionInput = sm.interactable.connectionType.logic
CameraFPV.connectionOutput = sm.interactable.connectionType.seated + sm.interactable.connectionType.all
CameraFPV.colorNormal = sm.color.new( 0x00de51ff )
CameraFPV.colorHighlight = sm.color.new( 0x02ee88ff )

function CameraFPV.server_onCreate( self )
	self:sv_init()
	table.insert(fpvcamera,self.shape:getId(),self)
end

function CameraFPV.server_onRefresh( self )
  self:sv_init()
end

function CameraFPV.sv_init( self )

	-- load saved
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	self.interactable:setActive(false)
  self.saved.playSound = false
  self.saved.soundToPlay = false
	self.saved.isConnected = false
	self.saved.height = 0

	-- create tables if not exist
	if(fpvcamera == nil) then
		fpvcamera = {}
	end
	if(remotecontrol == nil) then
		remotecontrol = {}
	end

	-- clean remotecontrol table if don't find remote controls.
	local r = 0
	for k, value in pairs (remotecontrol) do
		if value.shape ~= nil then
			r = r + 1
		end
	end
	if r == 0 then
		remotecontrol = {}
	end

end

function CameraFPV.getHeight ( self )
	return self.saved.height
end

function CameraFPV.getRemoteControl ( self )
	if remotecontrol then
		for k, value in pairs (remotecontrol) do
			if value.shape ~= nil then
				if value.saved.frequency == self.saved.frequency then
					return value
				end
			end
		end
	end
	return false
end

function CameraFPV.server_onFixedUpdate ( self, timeStep )

	-- save frequency
	self.saved.frequency = (self.shape:getColor().r / self.shape:getColor().g / self.shape:getColor().b)

	-- define height
	self.saved.height = self.shape:getWorldPosition().z

	-- if have antenna, redefine height
	local antenaUuid = sm.uuid.new("9a218848-bac4-4329-87d2-5c3ba0cb3f5f")
	local antenna = self.interactable:getSingleParent()
	if antenna ~= nil then
		if antenna:getShape():getShapeUuid() == antenaUuid then
			self.saved.height = antenna:getShape():getWorldPosition().z
		end
	end

	-- get remote control in same frequency
	local rc = self:getRemoteControl()

	-- if have remotecontrol and is connected
	if rc then

		-- refresh connection
		self.saved.isConnected = rc:isConnected()

 		if self.saved.isConnected then
			-- turn on camera
			if self.interactable:isActive() == false then
				self.interactable:setActive(true)
			end

			-- engines control
			self.interactable:setPower(rc.getEngine( rc ))

			local rcDir = rc.getDirection( rc )

			-- bearings control
			local bearings = self.interactable:getBearings()
			local dir = 0
			if rcDir < 0 then
				dir = -38.30
			end
			if rcDir > 0 then
				dir = 38.30
			end
			local maxBearingImpulse = 1000
			if #bearings > 0 then
				for b,bearing in ipairs(bearings)
				do
					for i=1,maxBearingImpulse do
						bearing:setTargetAngle( dir, i, i )
					end
				end
			end
			-- if not connected
		else
			if self.interactable:isActive() == true then
				self.interactable:setActive(false)
				self.interactable:setPower(0)
			end
		end
	else
		-- if not have remotecontrol in same frequency
		if self.interactable:isActive() == true then
			self.interactable:setActive(false)
			self.interactable:setPower(0)
		end
	end

end

function CameraFPV.client_onFixedUpdate( self, deltaTime )

	-- play sound
  if self.saved.playSound == true then
    sm.audio.play( self.saved.soundToPlay, self.saved.soundPosition )
    self.saved.playSound = false
  end
  -- show message
  if self.saved.showMsg == true then
    sm.gui.displayAlertText( self.saved.msgToShow )
    self.saved.showMsg = false
  end

end

function CameraFPV.server_onDestroy( self )
  for k, value in pairs (fpvcamera) do
		if value.shape == self.shape then
			fpvcamera[k] = nil
		end
	end
end
