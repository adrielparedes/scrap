BuildProtector = class()
BuildProtector.maxParentCount = 0
BuildProtector.maxChildCount = 0
BuildProtector.connectionInput = sm.interactable.connectionType.none
BuildProtector.connectionOutput = sm.interactable.connectionType.none
BuildProtector.colorNormal = sm.color.new( 0xfcba03FF )
BuildProtector.colorHighlight = sm.color.new( 0xcad900FF )
BuildProtector.poseWeightCount = 1


function BuildProtector.server_onCreate(self)
	self.sv = self.storage:load()
	if self.sv == nil then
		self.sv = {}
	end
end

function BuildProtector.server_toggleProtection(self)

	if self.sv.isActive == true then
		self.shape:getBody():setLiftable(true)
		for i,v in pairs(self.shape:getBody():getCreationBodies()) do
			v:setErasable(true)
			v:setBuildable(true)
			v:setConnectable(true)
			v:setPaintable(true)
			v:setLiftable(true)
		end
		self.sv.isActive = false
		self.interactable:setActive(false)
	else
		self.shape:getBody():setLiftable(false)
		for i,v in pairs(self.shape:getBody():getCreationBodies()) do
			v:setErasable(false)
			v:setBuildable(false)
			v:setConnectable(false)
			v:setPaintable(false)
			v:setLiftable(false)
		end
		self.sv.isActive = true
		self.interactable:setActive(true)
		print ("Protection ON")
	end
	self.storage:save(self.sv)
end

function BuildProtector.server_saveOwner ( self )
  self.storage:save(self.sv)
end

function BuildProtector.client_onFixedUpdate( self )
  if self.sv.isActive == true and sm.interactable.getUvFrameIndex(self.interactable) ~= 0 then
		sm.interactable.setPoseWeight(self.interactable, 0, 0)
    sm.interactable.setUvFrameIndex(self.interactable, 0)
  end
	if self.sv.isActive == false and sm.interactable.getUvFrameIndex(self.interactable) ~= 6 then
		sm.interactable.setPoseWeight(self.interactable, 0, 1)
    sm.interactable.setUvFrameIndex(self.interactable, 6)
  end
end


function BuildProtector.client_onInteract(self, character, state)
	if state then
		if not self.sv.owner then
      self.sv.owner = character:getPlayer().name
      self.network:sendToServer( 'server_saveOwner' )
      sm.gui.displayAlertText( "Player " .. character:getPlayer().name .. " registered an interactive item." )
    end
    if self.sv.owner == character:getPlayer().name then
			self.network:sendToServer("server_toggleProtection")
    end
	end
end
