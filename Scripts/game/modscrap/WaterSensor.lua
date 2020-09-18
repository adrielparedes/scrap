WaterSensor = class( nil )
WaterSensor.maxChildCount = 64
WaterSensor.maxParentCount = 0
WaterSensor.connectionInput = sm.interactable.connectionType.none
WaterSensor.connectionOutput = sm.interactable.connectionType.logic
WaterSensor.colorNormal = sm.color.new( 0x910640ff )
WaterSensor.colorHighlight = sm.color.new( 0xb60e55ff )

function WaterSensor.server_onCreate( self )
	self:sv_init()
end

function WaterSensor.sv_init( self )
	self.sv = {}
  self.sv.before = sm.game.getCurrentTick()
end

function WaterSensor.server_onRefresh( self )
  self:sv_init()
end

function WaterSensor.server_onFixedUpdate( self, tick )

  local velocity = self.shape:getBody().velocity.x + self.shape:getBody().velocity.y + self.shape:getBody().velocity.z
  if velocity < 0 then
    velocity = 0 + (-velocity)
  end

  local newPos = self.shape:getWorldPosition()

  if velocity >= 0.1 then
    self.sv.areaTrigger:setWorldPosition(newPos)
  end

  if not self.sv.areaTrigger then
    local size = sm.vec3.new( 0.25, 0.25, 0.1 )
    self.sv.areaTrigger = sm.areaTrigger.createBox( size, newPos, sm.quat.identity() )
  else
    for _, result in ipairs(  self.sv.areaTrigger:getContents() ) do
			if sm.exists( result ) then
        if type( result ) == "AreaTrigger" then
          local userData = result:getUserData()
          if userData and ( userData.chemical == true or userData.water == true ) then
            self.interactable:setActive(true)
          else
            self.interactable:setActive(false)
          end
        else
          self.interactable:setActive(false)
        end
      end
    end
  end
end

function WaterSensor.server_onDestroy( self )
  sm.areaTrigger.destroy(self.sv.areaTrigger)
end
