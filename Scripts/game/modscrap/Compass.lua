-- Compass.lua --
Compass = class( nil )
Compass.maxChildCount = -1
Compass.maxParentCount = -1
Compass.connectionInput = sm.interactable.connectionType.power
Compass.connectionOutput = sm.interactable.connectionType.power
Compass.colorNormal = sm.color.new( 0x76034dff )
Compass.colorHighlight = sm.color.new( 0x8f2268ff )
Compass.poseWeightCount = 2

function Compass.sv_init ( self )
	-- load saved
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	self.saved.display = 0
	self.interactable:setActive(true)
end

function Compass.server_onRefresh( self )
	self:sv_init()
end

function Compass.server_onCreate( self )
	self:sv_init()
end


function Compass.server_onFixedUpdate( self, timeStep )
	local power = 0
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
	localY = rot*localY
	power = math.atan2(-localY.x,localY.y)/math.pi * 180

	if power ~= self.interactable.power then
		self.interactable:setPower(power)
	end
	-- north
	if power > -30 and power < 30 then
		self.saved.display = 0
	end
	-- northwest
	if power >= 30 and power < 60 then
		self.saved.display = 12
	end
	-- southwest
	if power >= 120 and power < 155 then
		self.saved.display = 14
	end
	-- south
	if power >= 155 or power <= -155 then
		self.saved.display = 2
	end
	-- southeast
	if power <= -120 and power > -155 then
		self.saved.display = 10
	end
	-- east
	if power <= -60 and power > -120 then
		self.saved.display = 4
	end

	-- northeast
	if power <= -30 and power > -60 then
		self.saved.display = 8
	end
	-- west
	if power >= 60 and power < 120 then
		self.saved.display = 6
	end

end

function Compass.client_onFixedUpdate(self, dt)
	--print(self.interactable.power)

	self.interactable:setUvFrameIndex(self.saved.display)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	local rot = sm.vec3.getRotation(localZ, sm.vec3.new(0,0,1))
	localY = rot*localY*-1

	self.interactable:setPoseWeight(0 ,(localY.x+1)/2)
	self.interactable:setPoseWeight(1 ,(localY.y+1)/2)

end
