ConverterPower = class( nil )
ConverterPower.maxChildCount = 64
ConverterPower.maxParentCount = 1
ConverterPower.connectionInput = sm.interactable.connectionType.power
ConverterPower.connectionOutput = sm.interactable.connectionType.logic
ConverterPower.colorNormal = sm.color.new( 0x007fffff )
ConverterPower.colorHighlight = sm.color.new( 0x3094ffff )
ConverterPower.poseWeightCount = 1

ConverterBearing = class( nil )
ConverterBearing.maxChildCount = 64
ConverterBearing.maxParentCount = 1
ConverterBearing.connectionInput = sm.interactable.connectionType.bearing
ConverterBearing.connectionOutput = sm.interactable.connectionType.logic
ConverterBearing.colorNormal = sm.color.new( 0x007fffff )
ConverterBearing.colorHighlight = sm.color.new( 0x3094ffff )
ConverterBearing.poseWeightCount = 1

function ConverterPower.server_onCreate( self )
  self.saved = self.storage:load()
  if self.saved == nil then
    self.saved = {}
  end
  self.saved.status = 0
end
function ConverterBearing.server_onCreate( self )
  self.saved = self.storage:load()
  if self.saved == nil then
    self.saved = {}
  end
  self.saved.status = 0
end

function ConverterPower.client_onFixedUpdate( self )
  if self.saved.status == 1 then
    sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
  else
    sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function ConverterBearing.client_onFixedUpdate( self )
  if self.saved.status == 1 then
    sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
  else
    sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function ConverterPower.server_onFixedUpdate( self )
  local parent = self.interactable:getSingleParent()
  if parent then
    if parent:isActive() then
      if self.shape.shapeUuid == sm.uuid.new( "e1e66432-6332-46af-909d-4ac6f01e5e32" ) then
        if parent:getPower() > 0 then
          self.interactable:setActive( true )
          self.saved.status = 1
        else
          self.interactable:setActive( false )
          self.saved.status = 0
        end
      end
      if self.shape.shapeUuid == sm.uuid.new( "2a0e7e29-13f5-4127-9c05-d5694e56d110" ) then
        if parent:getPower() < 0 then
          self.interactable:setActive( true )
          self.saved.status = 1
        else
          self.interactable:setActive( false )
          self.saved.status = 0
        end
      end
    end
  end
end

function ConverterBearing.server_onFixedUpdate( self )
  local parent = self.interactable:getSingleParent()
  if parent then
    if parent:isActive() then
      if self.shape.shapeUuid == sm.uuid.new( "bd584234-94a6-4688-928f-06ae37769ef2" ) then
        if parent:getSteeringAngle() < 0 then
          self.interactable:setActive( true )
          self.saved.status = 1
        else
          self.interactable:setActive( false )
          self.saved.status = 0
        end
      end
      if self.shape.shapeUuid == sm.uuid.new( "fac84c0f-ef7f-4b0c-9c8d-c25c424fa25e" ) then
        if parent:getSteeringAngle() > 0 then
          self.interactable:setActive( true )
          self.saved.status = 1
        else
          self.interactable:setActive( false )
          self.saved.status = 0
        end
      end
    end
  end
end
