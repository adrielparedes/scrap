SeatedClick = class()
SeatedClick.maxParentCount = 1
SeatedClick.maxChildCount = 0
SeatedClick.connectionInput = sm.interactable.connectionType.seated
SeatedClick.connectionOutput = sm.interactable.connectionType.none
SeatedClick.colorNormal = sm.color.new( 0xbfbfbfff )
SeatedClick.colorHighlight = sm.color.new( 0xdadadaff )
SeatedClick.poseWeightCount = 0


function SeatedClick.client_onCreate( self )
	self.comBTrig = false
	self.comBstate = false

	self.corners = {}
	self.cornersShape = nil
end

function SeatedClick.client_onDestroy( self )
	if self.cornersShape ~= nil then
			self:c_cornersStop()
	end
end


function SeatedClick.client_onInteract( self )
	self.comBTrig = true
end



function SeatedClick.client_onFixedUpdate( self )

	local shapeHit

	local par = self.interactable:getSingleParent()
	-- is the comBlock activation needed?
	if par and par:isActive() and par:getSeatCharacter():getPlayer() == sm.localPlayer.getPlayer( ) then

		if self.comBTrig then
			self.comBstate = not self.comBstate
		end

		local hitPoint
		local distTraveled = 0

		for i=0,20 do
			local b, r = sm.localPlayer.getRaycast(7.5 - distTraveled, hitPoint )
			distTraveled = distTraveled + r.fraction * (7.5-distTraveled)
			hitPoint = r.pointWorld + sm.localPlayer.getDirection( )*0.1

			if r.type == "body" and r:getShape().interactable then
				local shapeHitIntType = r:getShape().interactable:getType()
				if not (shapeHitIntType == "seat" or shapeHitIntType == "steering") then
					shapeHit = r:getShape()

					if shapeHitIntType == "button" or shapeHitIntType == "lever" or shapeHitIntType == "radio" then

						-- if trig and On = first trig or if On and button
						if self.comBTrig and self.comBstate or self.comBstate and shapeHitIntType == "button" then
							self.network:sendToServer( 'server_askFire', {shapeHit, sm.localPlayer.getDirection()} )
						end

						-- effect
						if shapeHit ~= self.cornersShape then

							if self.cornersShape ~= nil then
								self:c_cornersStop()
							end
							self.cornersShape = shapeHit

							local boundB = shapeHit:getBoundingBox()

							for i=0,7 do
								self.corners[i] = sm.effect.createEffect("corner", shapeHit:getInteractable())
								if not self.corners[i]:isPlaying() then
									self.corners[i]:start()
								end
								self.corners[i]:setOffsetPosition(
									sm.vec3.new(
										sm.vec3.getX(boundB)*(i%2-0.5),
										sm.vec3.getY(boundB)*(math.floor(i/2)%2-0.5),
										sm.vec3.getZ(boundB)*(math.floor(i/4)%2-0.5)
									)
								)
							end

							self.corners[0]:setOffsetRotation(sm.quat.new(0, 0, 0, 1) )
							self.corners[1]:setOffsetRotation(sm.quat.new(0, -1, 0, 1) )
							self.corners[2]:setOffsetRotation(sm.quat.new(0, 0, -1, 1) )
							self.corners[3]:setOffsetRotation(sm.quat.new(0, 0, 1, 0) )
							self.corners[4]:setOffsetRotation(sm.quat.new(-1, 0, 0, 1) )
							self.corners[5]:setOffsetRotation(sm.quat.new(0, 1, 0, 0) )
							self.corners[6]:setOffsetRotation(sm.quat.new(1, 0, 0, 0) )
							self.corners[7]:setOffsetRotation(sm.quat.new(-1, 0, 1, 0) )
						end

						break -- "all good" break

					end					--if lever/button
					break
				end					--if not seat/steering
			else
				break
			end					--if body & shape & interac

		end	--for

	else  -- not active
		self.comBstate = false
	end

	if self.cornersShape ~= nil and self.cornersShape ~= shapeHit then
			self:c_cornersStop()
	end

	self.comBTrig = false
end


function SeatedClick.c_cornersStop(self)
	for i=0,7 do
		if not self.corners[i]:isPlaying() then	self.corners[i]:start()	end
		self.corners[i]:setOffsetPosition(sm.vec3.new(0,0,-100000))
		if self.corners[i]:isPlaying() then	self.corners[i]:stop()	end
	end
	self.corners = {}
	self.cornersShape = nil
end


function SeatedClick.server_askFire(self, data)
	self.network:sendToClients( "client_askFire", data )
end

function SeatedClick.client_askFire(self, data)
	if sm.isHost then
		local shapeHit = data[1]
		local camDir = data[2]

		local spudDir = camDir

		dirTable = {shapeHit:getAt(), -shapeHit:getAt(), shapeHit:getUp(), -shapeHit:getUp(), shapeHit:getRight(), -shapeHit:getRight()}
		for i=1,6 do
			local b, r = sm.localPlayer.getRaycast(1, shapeHit:getWorldPosition(), dirTable[i])
			if r.type == "body" and r:getShape():getId() == shapeHit:getId() then
				spudDir = dirTable[i]
				break
			end
		end

		sm.projectile.playerFire(
			"smallpotato",
			shapeHit:getVelocity()/40 + shapeHit:getWorldPosition() - spudDir*0.01,
			spudDir
		)
	end
end



function dist(vecA, vecB)
	local v = vecA-vecB
	return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end


function SeatedClick.client_onRefresh( self )
	self:client_onCreate()
end
