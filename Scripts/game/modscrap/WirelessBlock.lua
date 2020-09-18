WirelessBlock = class( nil )
WirelessBlock.maxChildCount = 64
WirelessBlock.connectionOutput = sm.interactable.connectionType.logic
WirelessBlock.maxParentCount = 1
WirelessBlock.connectionInput = sm.interactable.connectionType.logic
WirelessBlock.colorNormal = sm.color.new( 0x00de51ff )
WirelessBlock.colorHighlight = sm.color.new( 0x02ee88ff )
WirelessBlock.poseWeightCount = 1

function WirelessBlock.server_onCreate( self )
	self:server_init()
end

function WirelessBlock.server_onRefresh( self )
	self:server_init()
end

function WirelessBlock.server_init( self )
	self.saved = self.storage:load()
	if not self.saved then
		self.saved = {}
		self.saved.power = 3
		self.saved.mode = 0
		self.interactable:setActive(false)
		self.storage:save(self.saved)
	end
	if router == nil then
		router = {};
	end
	table.insert(router,self.shape:getId(),self)
end

function WirelessBlock.server_toggleMode( self )
	if self.saved.mode == 0 then
		self.saved.mode = 1
		self.storage:save(self.saved)
	else
		self.saved.mode = 0
		self.storage:save(self.saved)
	end
end

function WirelessBlock.client_onInteract ( self )
	if self.saved.onInteract == 0 then
		self.network:sendToServer("server_toggleMode")
		self.saved.onInteract = self.saved.onInteract + 0.5
	end
	if self.saved.onInteract >= 1 then
		self.saved.onInteract = 0
	else
		if self.saved.onInteract == nil then
			self.saved.onInteract = 1
		else
			self.saved.onInteract = self.saved.onInteract + 1
		end
	end
end

function WirelessBlock.client_onFixedUpdate( self, timeStep )
	if not self.saved.timer then
		self.saved.timer = 0
	end

	if self.saved.mode == 0 then
		if self.saved.timer == 0 then
			self.saved.timer = 200
		end
		if self.saved.timer < 50 then
			sm.interactable.setUvFrameIndex(self.interactable, 1)
			self.saved.timer = self.saved.timer - 1
		else
			sm.interactable.setUvFrameIndex(self.interactable, self.saved.frequency)
			self.saved.timer = self.saved.timer - 1
		end
	else
		if self.saved.timer == 0 then
			self.saved.timer = 200
		end
		if self.saved.timer < 50 then
			sm.interactable.setUvFrameIndex(self.interactable, 2)
			self.saved.timer = self.saved.timer - 1
		else
			sm.interactable.setUvFrameIndex(self.interactable, self.saved.frequency)
			self.saved.timer = self.saved.timer - 1
		end
	end
end

function WirelessBlock.server_getFrequency( self )
	return self.saved.frequency
end

function WirelessBlock.server_onFixedUpdate( self, dt )

	self.saved.height = self.shape:getWorldPosition().z
	local color = math.deg(self.shape:getColor().r + self.shape:getColor().g + self.shape:getColor().b)
	self.saved.frequency = color


	if self.saved.mode == 0 then

			self.saved.powertx = 3 * self.shape:getWorldPosition().z
			self.interactable:setPower(self.saved.powertx)

	end

	if self.saved.mode == 1 then

		local position = self.shape:getWorldPosition()
		local color = tostring(self.shape:getColor())
		for k, rw in pairs (router) do
			if rw.shape ~= nil then
				if rw:server_getFrequency() == self.saved.frequency then
					local dif = position - rw.shape:getWorldPosition()
					self.saved.powertx = rw.interactable:getPower() + ( 3 * position.z )
					local rangeSquared = self.saved.powertx * self.saved.powertx
					local distSquared = sm.vec3.length2(dif)
					if (distSquared <= rangeSquared) then
						local button = rw.interactable:getSingleParent()
						if button then
							if button:isActive() then
								self.interactable:setActive(true)
							else
								self.interactable:setActive(false)
							end
						end
					else
						self.interactable:setActive(false)
					end
				end
			end
		end

	end

end

function WirelessBlock.server_onDestroy( self )
	for k, value in pairs (router) do
		if value.shape == self.shape then
			router[k] = nil
		end
	end
end
