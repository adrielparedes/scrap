-- Velocimeter.lua --
Velocimeter = class( nil )
Velocimeter.maxChildCount = -1
Velocimeter.maxParentCount = -1
Velocimeter.connectionInput = sm.interactable.connectionType.power
Velocimeter.connectionOutput = sm.interactable.connectionType.power
Velocimeter.colorNormal = sm.color.new( 0x76034dff )
Velocimeter.colorHighlight = sm.color.new( 0x8f2268ff )
Velocimeter.poseWeightCount = 2

function Velocimeter.sv_init ( self )
	self.interactable:setActive(true)
end

function Velocimeter.server_onRefresh( self )
	self:sv_init()
end

function Velocimeter.server_onCreate( self )
	self:sv_init()
end

function Velocimeter.server_onFixedUpdate( self, timeStep )
	local power = 0
	power = self.shape.velocity:length()*4

	if power ~= self.interactable.power then
		self.interactable:setPower(power)
	end
end

function Velocimeter.client_onFixedUpdate(self, dt)
	if self.shape.velocity.y > 0.1 then
		self.interactable:setUvFrameIndex(2)
	elseif self.shape.velocity.y < -0.1 then
		self.interactable:setUvFrameIndex(4)
	else
		self.interactable:setUvFrameIndex(0)
	end
	local one = (math.sin(0-2*math.pi*(self.interactable.power+17)/134)+1)/2
	local two = (math.cos(2*math.pi*(self.interactable.power+17)/134)+1)/2
	self.interactable:setPoseWeight(0 ,one)
	self.interactable:setPoseWeight(1 ,two)

end
