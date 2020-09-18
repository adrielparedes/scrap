RemoteControl = class()
RemoteControl.maxParentCount = 1
RemoteControl.maxChildCount = 1
RemoteControl.connectionInput = sm.interactable.connectionType.seated
RemoteControl.connectionOutput = sm.interactable.connectionType.logic
RemoteControl.colorNormal = sm.color.new( 0x00de51ff )
RemoteControl.colorHighlight = sm.color.new( 0x02ee88ff )

function RemoteControl.server_onCreate( self )
	self:sv_init()
	table.insert(remotecontrol,self.shape:getId(),self)
end

function RemoteControl.server_onRefresh( self )
  self:sv_init()
end

function RemoteControl.sv_init( self )

	-- load saved
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	self.interactable:setActive(false)
  self.saved.playSound = false
  self.saved.soundToPlay = false
  self.saved.isConnected = false
  self.saved.remoteControlPosition = self.shape:getWorldPosition()
  self.saved.cameraPosition = self.saved.remoteControlPosition
  self.saved.cameraUp = self.shape:getUp()
  self.saved.lastTimePlayed = 0
  -- create tables if not exist
	if(fpvcamera == nil) then
		fpvcamera = {}
	end
	if(remotecontrol == nil) then
		remotecontrol = {}
	end

	-- clean fpvcamera table if don't find cameras.
	local r = 0
	for k, value in pairs (fpvcamera) do
		if value.shape ~= nil then
			r = r + 1
		end
	end
	if r == 0 then
		fpvcamera = {}
	end

end

function RemoteControl.getFPV ( self )
	if fpvcamera then
  	for k, value in pairs (fpvcamera) do
  		if value.shape ~= nil then
  			if value.saved.frequency == self.saved.frequency then
  				return value
  			end
  		end
  	end
  	return false
  end
end

function RemoteControl.isConnected ( self )
  return self.saved.isConnected
end

function RemoteControl.getDirection ( self )
  if self.saved.controlDirection ~= nil then
    return self.saved.controlDirection
  else
    return 0
  end
end

function RemoteControl.getEngine ( self )
  if self.saved.enginePower ~= nil then
    return self.saved.enginePower
  else
    return 0
  end
end

function RemoteControl.client_onFixedUpdate( self )

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

function RemoteControl.server_onFixedUpdate( self, dt )

  -- define frequency
  self.saved.frequency = (self.shape:getColor().r / self.shape:getColor().g / self.shape:getColor().b)

  -- define cam view
  if (self.saved.frequency < 7.6 and self.saved.frequency > 7.4 ) then
		self.saved.fpv = false
		self.saved.cameraToShow = 1
	else
		self.saved.fpv = true
		self.saved.cameraToShow = 3
	end

  -- define powertx
  self.saved.powertx = self.shape:getWorldPosition().z * 3

  -- if have antenna, redefine powertx
  local antenaUuid = sm.uuid.new("f16d77ab-f4d8-46e8-b98f-b3559aeec72e")
  local antenna = self.interactable:getChildren()
  if #antenna > 0 then
    for a,value in ipairs(antenna)
    do
      if value then
        if value:getShape():getShapeUuid() == antenaUuid then
          self.saved.powertx = value:getPower()
        end
      end
    end
  end

  --if have camera [fisrt cam found in same frequency]
  local cam = self:getFPV()
  if cam then

    self.saved.cameraUp = cam.shape:getUp()
  	self.saved.cameraPosition = cam.shape:getWorldPosition()
    self.saved.powertx = self.saved.powertx + cam:getHeight()

    -- check range
		self.saved.rangeSquared = self.saved.powertx * self.saved.powertx
    local dif = self.shape:getWorldPosition() - self.saved.cameraPosition
		self.saved.distSquared = sm.vec3.length2(dif)

		-- try connect
		if (self.saved.distSquared <= self.saved.rangeSquared) and (self.saved.cameraPosition ~= self.saved.remoteControlPosition) then

      -- connected
      if self.saved.isConnected == false then
        self.saved.playSound = true
        self.saved.soundToPlay = "Blueprint - Camera"
        self.saved.soundPosition = self.shape:getWorldPosition()
        if self.saved.fpv then
          self.saved.msgToShow = "FPV " .. cam.shape:getId() .. " connected. \nTX/RX: 1" .. RemoteControl.round(self.saved.frequency, 2) .. "MHz"
        else
          self.saved.msgToShow = "Remote " .. cam.shape:getId() .. " connected. TX/RX: 1" .. RemoteControl.round(self.saved.frequency, 2) .. "MHz\nBLACK COLOR - FPV DISABLED"
        end
        self.saved.showMsg = true
        self.saved.isConnected = true
      end

      -- low signal, warn with 70% of max range
      if ( self.saved.distSquared > ( (self.saved.rangeSquared/10) * 7 ) ) then
        if self.saved.lastTimePlayed >= 7 then
          self.saved.lastTimePlayed = 0
          self.saved.msgToShow = "Low Signal"
          self.saved.showMsg = true
          if self.saved.fpv then
            cam.saved.playSound = true
  					cam.saved.soundPosition = cam.shape:getWorldPosition()
            cam.saved.soundToPlay = "Retrowildblip"
  				else
            self.saved.playSound = true
  					self.saved.soundPosition = self.shape:getWorldPosition()
            self.saved.soundToPlay = "Retrowildblip"
          end
        end
        self.saved.lastTimePlayed = self.saved.lastTimePlayed + 0.02
			end

    else

      -- disconnected
      if self.saved.isConnected == true then
        self.saved.playSound = true
        self.saved.soundToPlay = "Blueprint - Close"
        self.saved.soundPosition = self.shape:getWorldPosition()
        self.saved.msgToShow = "Lost signal. TX/RX: 1" .. RemoteControl.round(self.saved.frequency, 2) .. "MHz"
        self.saved.isConnected = false
        self.saved.showMsg = true
      end

    end

  else

    -- no cam in same frequency
    if self.saved.isConnected == true then
      self.saved.playSound = true
      self.saved.soundToPlay = "Blueprint - Close"
      self.saved.soundPosition = self.shape:getWorldPosition()
      self.saved.msgToShow = "Not found cameras. Scanning frequency 1" .. RemoteControl.round(self.saved.frequency, 2) .. "MHz"
      self.saved.isConnected = false
      self.saved.showMsg = true
    end

  end

  -- if is connected
  if self.saved.isConnected then

    -- turn on remote control
    if self.interactable:isActive() ~= true then
      self.interactable:setActive(true)
    end

    -- refresh seat
    self.saved.seated = nil
    self.saved.seat = self.interactable:getSingleParent()
    if self.saved.seat ~= nil then
      self.saved.seated = self.saved.seat:getSeatCharacter()
    end

    -- engine controls
    if self.saved.seated then
      self.saved.enginePower = self.saved.seat:getPower()
      self.saved.controlDirection = self.saved.seat:getSteeringAngle()
    else
      self.saved.enginePower = 0
    end

  -- if is not connected
  else
    -- turn off remote control
    if self.interactable:isActive() ~= false then
      self.interactable:setActive(false)
    end

  end

end

function RemoteControl.client_onUpdate( self )

  -- if connected and seated
  if self.saved.isConnected and self.saved.seated ~= nil then


		if sm.camera.getCameraState() ~= self.saved.cameraToShow then
			self.saved.playSound = true
			self.saved.soundToPlay = "Blueprint - Camera"
			self.saved.soundPosition = self.saved.cameraPosition
			sm.camera.setCameraState(self.saved.cameraToShow)
		end

		if self.saved.fpv then
			sm.camera.setPosition(self.saved.cameraPosition + self.saved.cameraUp * 0.4)
			sm.camera.setDirection(self.saved.cameraUp)
		end

	end

  -- if not connected
  if self.saved.isConnected == false then

		if sm.camera.getCameraState() ~= 1 then
			self.saved.playSound = true
			self.saved.soundToPlay = "Blueprint - Close"
			self.saved.soundPosition = self.saved.cameraPosition
			sm.camera.setCameraState(1)
			sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
      self.saved.seat:setSeatCharacter( sm.localPlayer.getPlayer():getCharacter() )
		end

	end

  -- if not seated
  if self.saved.seated == nil then

		if sm.camera.getCameraState() ~= 1 then
			self.saved.playSound = true
			self.saved.soundToPlay = "Blueprint - Close"
			self.saved.soundPosition = self.saved.cameraPosition
			sm.camera.setCameraState(1)
			sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
		end

	end

end

function RemoteControl.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  if num >= 0 then
    return math.floor(num * mult + 0.5) / mult
  else
    return math.ceil(num * mult - 0.5) / mult
  end
end

function RemoteControl.server_onDestroy( self )
  for k, value in pairs (remotecontrol) do
		if value.shape == self.shape then
			remotecontrol[k] = nil
		end
	end
end
