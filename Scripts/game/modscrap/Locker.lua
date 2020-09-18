dofile "Libs.lua"

Locker = class()
Locker.maxParentCount = -1
Locker.maxChildCount = -1
Locker.connectionInput = sm.interactable.connectionType.logic
Locker.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Locker.colorNormal = sm.color.new( 0x00971dff )
Locker.colorHighlight = sm.color.new( 0x00b822ff )

function Locker.server_onCreate( self )
	self.sv = self.storage:load()
	if self.sv == nil then
		self.sv = {}
    self.sv.active = false
	end

	self.activeTime = 0
	self.strNumber = "0"
	self.enabled = true
end
function Locker.server_onRefresh( self )
	if not sm.exists(self.interactable) then return end
    self:server_onCreate()
	self.interactable.power = 0
	self.interactable.active = false
end

function Locker.server_onFixedUpdate( self, dt )
	if not sm.exists(self.interactable) then return end
	if self.sv.active then
		if self.sv.timer <= 0 then
			self.interactable.active = false
			self.sv.typedPass = 0
		else
			self.interactable.active = true
			self.sv.timer = self.sv.timer - 1
		end
	else
		self.interactable.active = false
		self.sv.typedPass = 0
	end

	if self.buttonPress then
		self.buttonPress = false
		self.network:sendToClients("client_playSound", "Button off")
	end

end

function Locker.server_onButtonPress(self, buttonName)
	if self.enter and buttonName ~= "e" then
		self.strNumber = "0"
		self.enter = false
	end

	if tonumber(buttonName) then
		self.strNumber = self.strNumber..buttonName
	else
		self[buttonName](self)
	end

	self.sv.typedPass = tonumber(self.strNumber)
	if math.abs(self.sv.typedPass) >= 3.3*10^38 then
		if self.sv.typedPass < 0 then self.sv.typedPass = -3.3*10^38 else self.sv.typedPass = 3.3*10^38 end
	end

	if buttonName == "e" then
		if not self.sv.password then
	    self.sv.password = self.sv.typedPass
			self:server_savePass()
			self.network:sendToClients( 'client_savePass' )
	  end
		if self.sv.password == self.sv.typedPass then
			self.sv.active = true
			self.sv.timer = 300
			self.strNumber = 0
		end
	end

	self.buttonPress = true
	self.network:sendToClients("client_playSound","Button on")

end

function Locker.d(self) -- '.'
	self.strNumber = (self.strNumber:find("%.") and self.strNumber or self.strNumber..".")
end
function Locker.m(self) -- '-'
	self.strNumber = (self.strNumber:sub(1,1) == '-' and self.strNumber:sub(2) or '-'..self.strNumber)
end
function Locker.c(self) -- 'clear'
	self.strNumber = "0"
end
function Locker.b(self) -- 'backspace'
	self.strNumber = (self.strNumber:sub(1,(self.strNumber:len()-1)))
	if self.strNumber == "" then self.strNumber = "0" end
end
function Locker.e(self) -- 'enter'
	self.sv.timer = 0
	self.enter = true
end

--- client ---

function Locker.client_savePass ( self )
	sm.gui.displayAlertText( "Password registered!" )
end

function Locker.client_playSound(self, soundName)
	sm.audio.play(soundName, self.shape.worldPosition)
end

function Locker.server_savePass ( self )
  self.storage:save(self.sv)
end

function Locker.client_onCreate(self)
	function networkCall(self, parentInstance)
		parentInstance.network:sendToServer("server_onButtonPress", self.name)
	end
	local virtualButtons = {
		{ name = "1", x = -0.75, y = -0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "2", x = -0.25, y = -0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "3", x =  0.25, y = -0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "4", x = -0.75, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "5", x = -0.25, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "6", x =  0.25, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "7", x = -0.75, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "8", x = -0.25, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "9", x =  0.25, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "0", x = -0.75, y = -0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "d", x = -0.25, y = -0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "m", x =  0.25, y = -0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "b", x =  0.75, y =  0.25, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "c", x =  0.75, y =  0.75, width = 0.25, height = 0.25, callback = networkCall},
		{ name = "e", x =  0.75, y = -0.50, width = 0.25, height = 0.50, callback = networkCall}
	}
	sm.virtualButtons.client_configure(self, virtualButtons)
	self.effect = sm.effect.createEffect( "RadarDot", self.interactable)
	self.effect2 = sm.effect.createEffect( "RadarDot", self.interactable)
end

function Locker.client_onFixedUpdate(self)
	if not sm.exists(self.interactable) then return end
	local hit, hitResult = sm.localPlayer.getRaycast(10)
	if not hit then
		self:client_stopEffect()
		return
	end

	local dotX, dotY = self:getLocalXY(hitResult.pointWorld)
	local buttonX, buttonY = sm.virtualButtons.client_getButtonPosition(self, dotX, dotY)

	if not buttonX then
		self:client_stopEffect()
		return
	end

	self.effect:setOffsetPosition(sm.vec3.new(buttonX/4, buttonY/4, -0.065))
	self.effect2:setOffsetPosition(sm.vec3.new(buttonX/4, buttonY/4, -0.065))
	if not self.effect:isPlaying() then
		self.effect:start()
		self.effect2:start()
	end
end

function Locker.client_onInteract( self, character, lookAt)
	if not lookAt then return end
	local hit, hitResult = sm.localPlayer.getRaycast(10)
	if not hit then return end
	local dotX, dotY = self:getLocalXY(hitResult.pointWorld)
	sm.virtualButtons.client_onInteract(self, dotX, dotY)
end

function Locker.client_canInteract(self)
	return (self.shape.worldPosition - sm.localPlayer.getPosition()):length2() < 4
end

function Locker.client_onDestroy(self)
	self:client_stopEffect()
end


function Locker.getLocalXY(self, vec)
	local hitVec = vec - self.shape.worldPosition
	local localX = self.shape.right
	local localY = self.shape.at
	dotX = hitVec:dot(localX) * 4
	dotY = hitVec:dot(localY) * 4
	return dotX, dotY
end


function Locker.client_stopEffect(self)
	self.effect:setOffsetPosition(sm.vec3.new(100000,0,0))
	self.effect2:setOffsetPosition(sm.vec3.new(100000,0,0))
	if self.effect:isPlaying() then
		self.effect:stop()
		self.effect2:stop()
	end
end
