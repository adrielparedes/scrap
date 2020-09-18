Speedometer = class( nil )
Speedometer.maxParentCount = 1
Speedometer.maxChildCount = -1
Speedometer.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Speedometer.connectionOutput = sm.interactable.connectionType.logic
Speedometer.colorNormal = sm.color.new(0x9c0d44ff)
Speedometer.colorHighlight = sm.color.new(0xc11559ff)
Speedometer.poseWeightCount = 2

function Speedometer.client_onCreate( self )
	self.interactable:setPoseWeight( 0, 1 )
	self.interactable:setPoseWeight( 1, 0 )
end

function Speedometer.client_onCreate( self, timeStep )
	self.ObjectVelLkmh = 0
end

function Speedometer.server_onFixedUpdate( self, timeStep )
	self.input = self.interactable:getSingleParent()
	if self.input then
		self.inputActive = self.input:isActive()
	else
		self.inputActive = false
	end
	if self.lastPosition then
		self.currentPos = sm.shape.getWorldPosition(self.shape)
		Player = server_getNearestPlayer( self.currentPos )
		self.getID = Player:getId()

		ObjectVel = (self.currentPos - self.lastPosition) / timeStep
		ObjectVelL =  ObjectVel:length()
		self.ObjectVelLkmh = ObjectVelL * 3.6
		self.Speedstring = string.format("%.2f",self.ObjectVelLkmh)
		self.network:sendToClients("client_setPoseWeight", { Speed = self.Speedstring, playerID = self.getID, dataActive = self.inputActive })
		self.network:sendToClients("client_Display", { Speed = self.Speedstring, playerID = self.getID, dataActive = self.inputActive })
	end
	self.lastPosition = sm.shape.getWorldPosition(self.shape)
end

function server_getNearestPlayer( position )
	local nearestPlayer = nil
	local nearestDistance = nil
	for id,Player in pairs(sm.player.getAllPlayers()) do
		local length2 = sm.vec3.length2(position - Player.character:getWorldPosition())
		if nearestDistance == nil or length2 < nearestDistance then
			nearestDistance = length2
			nearestPlayer = Player
		end
	end
	return nearestPlayer
end

function Speedometer.client_setPoseWeight( self, Data )
	self.boltValue = Data.Speed / 250
	self.interactable:setPoseWeight( 0, -self.boltValue*2+1 )
	self.interactable:setPoseWeight( 1, self.boltValue*2-1 )
end

function Speedometer.client_Display( self, Data )
	if Data.dataActive == true and Data.playerID == sm.localPlayer.getId() then
		sm.gui.displayAlertText( Data.Speed.." km/h" , 1)
	end
end
