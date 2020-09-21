--dofile( "$SURVIVAL_DATA/Scripts/tools/Map.lua" )
--dofile( "$SURVIVAL_DATA/Scripts/game/interactables/MapGUI.lua" )

Launch = class( nil )
local animationTime = 0
local idleTime = 0
local AnimIsRunning = false
Launch.StartLaunchBool = false
local openTime = 0
local OpenIsRunning = false
Launch.StartOpenBool = false
Launch.AnimationStaged = false

 renderables = {
	"$SURVIVAL_DATA/Scripts/WayPoints/map_satellite/map_satellite.rend"
}

function Launch.client_onCreate( self )
	animationTime = 0
	AnimIsRunning = false
	local params = { name = "start" }
end

function CallLaunch( self )
	Launch.StartLaunchBool = true
end

function CallOpen( self )
	Launch.StartOpenBool = true
	print("called")
end


function Launch.PrepareForLaunch( self, params )
	self.network:sendToClients( "StartLaunch", params )
end
function Launch.PrepareForOpen( self, params )
	print("calling...")
	self.network:sendToClients( "StartOpen", params )
end

function Launch.StartOpen( self, params )
	self.interactable:setAnimEnabled( "open", true )
	self.interactable:setAnimProgress( "open", 0 )
	OpenIsRunning = true
	print("set...")
end

function Launch.StartLaunch( self, params )
	self.interactable:setAnimEnabled( "launch", true )
	self.interactable:setAnimProgress( "launch", 0 )
	AnimIsRunning = true
end

function Launch.client_onFixedUpdate( self, dt )
	if Launch.StartLaunchBool then
		self.network:sendToServer("PrepareForLaunch", params)
		Launch.StartLaunchBool = false
	end
	if Launch.StartOpenBool then
		Launch.StartOpenBool = false
		print("prepare...")
		self.network:sendToServer("PrepareForOpen", params)
	end
	if AnimIsRunning then
		animationTime = animationTime + 0.002
		if animationTime >= 1 then
			animationTime = 0
			self.interactable:setAnimEnabled( "launch", false )
			AnimIsRunning = false
		end
		self.interactable:setAnimProgress( "launch", animationTime )
	elseif OpenIsRunning then
		if not Launch.AnimationStaged then
			openTime = openTime + 0.002
			Launch.AnimationStaged = true
		end
		print(openTime)
		if openTime >= 1 then
			openTime = 0
			OpenIsRunning = false
		end
		self.interactable:setAnimProgress( "open", openTime )
		self.interactable:setAnimEnabled( "open", true )
	else
		idleTime = idleTime + 0.002
		if idleTime >= 1 then
			idleTime = 0
		end
		self.interactable:setAnimProgress( "idle", idleTime )
		self.interactable:setAnimEnabled( "idle", true )
	end
	Launch.AnimationStaged = false
end