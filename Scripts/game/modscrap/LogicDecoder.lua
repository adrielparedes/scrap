LogicDecoder = class( nil )
LogicDecoder.maxChildCount = 64
LogicDecoder.connectionOutput = sm.interactable.connectionType.logic
LogicDecoder.maxParentCount = 1
LogicDecoder.connectionInput = sm.interactable.connectionType.logic
LogicDecoder.colorNormal = sm.color.new( 0x00de51ff )
LogicDecoder.colorHighlight = sm.color.new( 0x02ee88ff )
LogicDecoder.poseWeightCount = 1

function LogicDecoder.server_onCreate( self )
	self:server_init()
end
function LogicDecoder.server_onRefresh( self )
	self:server_init()
end

function LogicDecoder.server_init( self )
	if antennatx == nil then
		antennatx = {};
	end
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	self.interactable:setActive(false)
end

function LogicDecoder.client_onFixedUpdate( self, timeStep )
	if self.interactable:isActive() == true then
		sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
	else
    sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function LogicDecoder.server_onFixedUpdate( self, dt )

	-- clean antennatx table if empty
	local r = 0
	for k, value in pairs (antennatx) do
		if value.shape ~= nil then
			r = r + 1
		end
	end
	if r == 0 then
		antennatx = {}
	end

	local receiver = self.interactable:getSingleParent()
  if receiver ~= nil then
    if receiver.shape:getShapeUuid() == sm.uuid.new("9a218848-bac4-4329-87d2-5c3ba0cb3f5f") then
      local color = self.shape:getColor()
      local code = (color.r / color.g / color.b)
      local buttonStatus = AntennaRX.sv_getInputStatus( receiver, code )
			if buttonStatus ~= nil then
	      if self.interactable:isActive() ~= buttonStatus then
	        self.interactable:setActive(buttonStatus)
	      end
			end
    end
  end
end
