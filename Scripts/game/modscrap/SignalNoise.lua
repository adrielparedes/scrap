dofile "Libs.lua"
-- SignalNoise.lua --
SignalNoise = class( nil )
SignalNoise.maxParentCount = 1
SignalNoise.maxChildCount = 0
SignalNoise.connectionInput =  sm.interactable.connectionType.logic
SignalNoise.connectionOutput = sm.interactable.connectionType.none
SignalNoise.colorNormal = sm.color.new( 0x470067ff )
SignalNoise.colorHighlight = sm.color.new( 0x601980ff )
SignalNoise.poseWeightCount = 1

if not noisers then noisers = {} end

function SignalNoise.client_onCreate( self )
	self.uvindex = 0
	self.isON = 1
	self.interference = 0 -- time
	table.insert(noisers, self.interactable)
	self.network:sendToServer("server_modeToClient")
end
function SignalNoise.client_onRefresh( self )
	self:client_onCreate()
end

function SignalNoise.client_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then
		self.isON = parent:isActive()
	end

	if self.isON and self.interference == 0 then
		if not self.prevmode then --turned on
			sm.audio.play("Blueprint - Delete", self.shape:getWorldPosition())
			self.interactable:setPoseWeight(0,0)
		end

		self.interactable:setUvFrameIndex(self.uvindex + 50)
		self.uvindex = (self.uvindex + 1)%50
	else
		if self.prevmode then -- turned off
			sm.audio.play("Blueprint - Delete", self.shape:getWorldPosition())
			self.interactable:setPoseWeight(0,1)
			self.interactable:setUvFrameIndex(0)
		end
	end
	if self.interference > 0 then self.interference = self.interference - 1 end
	self.prevmode = self.isON
end

function SignalNoise.client_onProjectile(self, X, hits, four)
	self.interference = 80
end

function SignalNoise.client_onInteract(self, character, lookAt)
	if not lookAt then return end
	self.network:sendToServer("server_changemode")
end

function SignalNoise.client_setmode(self, newmode)
	self.isON = newmode
end

function SignalNoise.server_onCreate(self)
	local storage = self.storage:load()
	self.isONserver = (storage == nil) or storage
end

function SignalNoise.server_onFixedUpdate(self, dt)
	local parent = self.interactable:getSingleParent()
	if parent then
		if self.isONserver ~= parent.active then
			self.isONserver = parent.active
			self.storage:save( parent.active)
		end
	end
	self.interactable.active = (self.isONserver and self.interference == 0)
end

function SignalNoise.server_changemode(self)
	self.isONserver = not self.isONserver
	self.storage:save(self.isONserver)
	self:server_modeToClient()
end
function SignalNoise.server_modeToClient(self)
	self.network:sendToClients("client_setmode", self.isONserver)
end
