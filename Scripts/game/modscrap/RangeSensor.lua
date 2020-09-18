RangeSensor = class( nil )
RangeSensor.maxChildCount = 64
RangeSensor.maxParentCount = 0
RangeSensor.connectionInput = sm.interactable.connectionType.none
RangeSensor.connectionOutput = sm.interactable.connectionType.logic
RangeSensor.colorNormal = sm.color.new( 0x910640ff )
RangeSensor.colorHighlight = sm.color.new( 0xb60e55ff )

function RangeSensor.server_onCreate( self )
	self:sv_init()
end

function RangeSensor.sv_init( self )
	self.sv = self.storage:load()
	if self.sv == nil then
		self.sv = {}
		self.sv.range = 45
	end
end

function RangeSensor.changeRange ( self )
	if not self.sv.range then
		self.sv.range = 45
	end
	if self.sv.range == 350 then
		self.sv.range = 45
	end
	if self.sv.range == 180 then
		self.sv.range = 350
	end
	if self.sv.range == 90 then
		self.sv.range = 180
	end
	if self.sv.range == 45 then
		self.sv.range = 90
	end
	self.storage:save(self.sv)
end

function RangeSensor.server_onRefresh( self )
  self:sv_init()
end

function RangeSensor.client_onInteract(self, _, state)
	if state then
		self.network:sendToServer("changeRange")
	end
end

function RangeSensor.server_onFixedUpdate( self, tick )

  local velocity = self.shape:getBody().velocity.x + self.shape:getBody().velocity.y + self.shape:getBody().velocity.z
  if velocity < 0 then
    velocity = 0 + (-velocity)
  end

  local newPos = self.shape:getWorldPosition()

  if velocity >= 0.1 then
    self.sv.areaTrigger:setWorldPosition(newPos)
  end

  if not self.sv.areaTrigger then
    local size = sm.vec3.new( 5, 5, 5 )
    self.sv.areaTrigger = sm.areaTrigger.createBox( size, newPos, sm.quat.identity() )
  else
		self.interactable:setActive(false)
    for _, result in ipairs(  self.sv.areaTrigger:getContents() ) do
			if sm.exists( result ) then
        if type( result ) == "Character" then

					local BestTarget = nil
					local BestConeDist = math.huge

					local ConeAngleCos = 0.707 -- ~cos(45)
					local Direction = self.shape.up

					local Vr = (self.shape:getWorldPosition() - result:getWorldPosition()):normalize()

					local Dot = Vr:dot(Direction)
					local Ang = math.acos(Dot)

					if Ang <= ConeAngleCos and Ang <= BestConeDist then
						BestTarget = result
						BestConeDist = Ang
					end

					local angle = ( 180 - math.deg(Ang) ) * 2

					if (angle < self.sv.range) then
          	self.interactable:setActive(true)
					end

        end
      end
    end
  end
end

function RangeSensor.server_onDestroy( self )
  sm.areaTrigger.destroy(self.sv.areaTrigger)
end
