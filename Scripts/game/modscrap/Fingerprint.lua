Fingerprint = class( nil )
Fingerprint.maxChildCount = 64
Fingerprint.maxParentCount = 0
Fingerprint.connectionInput = sm.interactable.connectionType.none
Fingerprint.connectionOutput = sm.interactable.connectionType.logic
Fingerprint.colorNormal = sm.color.new( 0x910640ff )
Fingerprint.colorHighlight = sm.color.new( 0xb60e55ff )
Fingerprint.poseWeightCount = 1

function Fingerprint.server_onCreate( self )
  self.sv = self.storage:load()
	if self.sv == nil then
		self.sv = {}
    self.sv.active = false
	end
end

function Fingerprint.server_onRefresh( self )
  self:sv_init()
end

function Fingerprint.server_saveOwner ( self )
  self.storage:save(self.sv)
end

function Fingerprint.client_onInteract( self, character, state )
  if state then
    if not self.sv.owner then
      self.sv.owner = character:getPlayer().name
      self.network:sendToServer( 'server_saveOwner' )
      sm.gui.displayAlertText( "Player " .. character:getPlayer().name .. " registered an interactive item." )
    end
    if self.sv.owner == character:getPlayer().name then
      if self.sv.active == true then
        self.sv.active = false
      else
        self.sv.active = true
      end
			self:changePose()
    end
  end
end

function Fingerprint.client_onFixedUpdate( self )
  if self.sv.active == true and sm.interactable.getUvFrameIndex(self.interactable) ~= 6 then
		sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
  end
	if self.sv.active == false and sm.interactable.getUvFrameIndex(self.interactable) ~= 0 then
		sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
end

function Fingerprint.server_onFixedUpdate( self, tick )
  if self.interactable:isActive() ~= self.sv.active then
    self.interactable:setActive(self.sv.active)
  end
end


function Fingerprint.server_onDestroy( self )
end
