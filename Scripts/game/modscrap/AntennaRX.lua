AntennaRX = class( nil )
AntennaRX.maxChildCount = 11
AntennaRX.connectionOutput = sm.interactable.connectionType.logic
AntennaRX.maxParentCount = 0
AntennaRX.connectionInput = sm.interactable.connectionType.none
AntennaRX.colorNormal = sm.color.new( 0x00de51ff )
AntennaRX.colorHighlight = sm.color.new( 0x02ee88ff )
AntennaRX.poseWeightCount = 1

function AntennaRX.server_onCreate( self )
	self:server_init()
end
function AntennaRX.server_onRefresh( self )
	self:server_init()
end

function AntennaRX.server_init( self )
	if antennatx == nil then
		antennatx = {};
	end

	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	self.saved.isConnected = false
	self.interactable:setActive(false)
	self.saved.height = 0
end

function AntennaRX.getHeight ( self )
	return self.saved.height
end

function AntennaRX.sv_getInputStatus ( self, buttonCode )
	if self.saved.isConnected then
		for k, tx in pairs (antennatx) do
			if tx.shape ~= nil then
				if tx.shape:getColor() == self.shape:getColor() then
					local parents = tx.interactable:getParents( sm.interactable.connectionType.logic )
					for j,value in ipairs(parents) do
						local color = value.shape:getColor()
			      local code = (color.r / color.g / color.b)
						if buttonCode == code and value:isActive() == true then
							return value:isActive()
						end
					end
				end
			end
		end
	end
	return false
end

function AntennaRX.server_onFixedUpdate( self, dt )
	local position = self.shape:getWorldPosition()

	for k, tx in pairs (antennatx) do

		if tx.shape ~= nil then
			if tx.shape:getColor() == self.shape:getColor() then
				local dif = position - tx.shape:getWorldPosition()
				self.saved.powertx = tx.interactable:getPower() + position.z
				local rangeSquared = self.saved.powertx * self.saved.powertx
				local distSquared = sm.vec3.length2(dif)
				if (distSquared <= rangeSquared) then
					if self.saved.isConnected ~= true then
						self.interactable:setActive(true)
						tx:changeStatus(true)
						self.saved.isConnected = true
					end
				else
					if self.saved.isConnected ~= false then
						self.interactable:setActive(false)
						tx:changeStatus(false)
						self.saved.isConnected = false
					end
				end
			end
		end
	end
end
