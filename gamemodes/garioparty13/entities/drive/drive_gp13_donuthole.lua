
AddCSLuaFile()

include( "drive/drive_base.lua" )

-- Derive
local DERIVE = "drive_base"
-- DEFINE_BASECLASS( DERIVE )

drive.Register( "drive_gp13_donuthole",
{
	--
	-- Called on creation
	--
	Init = function( self )
		self.CameraDist 	= 0.5
		self.CameraDistVel 	= 0.1
	end,

	--
	-- Calculates the view when driving the entity
	--
	CalcView = function( self, view )
	-- 	-- print( "calc view" )
	-- 	--
	-- 	-- Use the utility method on drive_base.lua to give us a 3rd person view
	-- 	--
	-- 	local idealdist = math.max( 2, self.Entity:BoundingRadius() / 2 ) * self.CameraDist

	-- 	-- print( idealdist )
	-- 	--self:CalcView_ThirdPersonClamped( view, idealdist, 1, { self.Entity } )

	-- 	-- view.origin = self.Entity:GetPos() + Vector( 0, 0, 100 )
	-- 	--view.angles.roll = 0
	-- 	--view.zfar = 1000
	-- end,
	-- CalcView_ThirdPersonClamped = function( self, view, dist, hullsize, entityfilter )
	-- 	local eyeang = self.Player:EyeAngles()
	-- 	-- eyeang.pitch = math.Clamp( eyeang.pitch, 50, 90 )
	-- 	-- From -180->180 to new range
	-- 	local min = 1
	-- 	local max = 90
	-- 	-- print( view.angles.p )

	-- 	-- INVERT HERE
	-- 	-- eyeang.p = ( ( 1 - ( eyeang.p + 90 ) / 180 ) * ( max - min ) ) + min
	-- 	eyeang.p = ( ( ( eyeang.p + 90 ) / 180 ) * ( max - min ) ) + min

	-- 	-- Move the view backwards the size of the entity
	-- 	local neworigin = view.origin + Vector( 0, 0, 15 ) - eyeang:Forward() * dist

	-- 	if ( hullsize && hullsize > 0 ) then
	-- 		-- Trace a hull (cube) from the old eye position to the new
	-- 		local tr = util.TraceHull( {
	-- 										start	= view.origin,
	-- 										endpos	= neworigin,
	-- 										mins	= Vector( hullsize, hullsize, hullsize ) * -1,
	-- 										maxs	= Vector( hullsize, hullsize, hullsize ),
	-- 										filter	= entityfilter
	-- 									})
	-- 		-- If we hit something then stop there
	-- 		-- [ stops the camera going through walls ]						
	-- 		if ( tr.Hit ) then
	-- 			neworigin = tr.HitPos
	-- 		end
	-- 	end

	-- 	-- Set our calculated origin
	-- 	view.origin = neworigin

	-- 	-- Set the angles to our view angles (not the entities eye angles)
	-- 	view.angles = eyeang
		LocalPlayer.DriveAngles = view.angles
	end,

	SetupControls = function( self, cmd )

		--
		-- If we're holding the reload key down then freeze the view angles
		--
		if ( cmd:KeyDown( IN_RELOAD ) ) then

			self.CameraForceViewAngles = self.CameraForceViewAngles or cmd:GetViewAngles()

			cmd:SetViewAngles( self.CameraForceViewAngles )

		else

			self.CameraForceViewAngles = nil

		end

		--
		-- Zoom out when we use the mouse wheel (this is completely clientside, so it's ok to use a lua var!!)
		--
		self.CameraDistVel = self.CameraDistVel + cmd:GetMouseWheel() * -0.5

		self.CameraDist = self.CameraDist + self.CameraDistVel * FrameTime()
		self.CameraDist = math.Clamp( self.CameraDist, 2, 20 )
		self.CameraDistVel = math.Approach( self.CameraDistVel, 0, self.CameraDistVel * FrameTime() * 2 )
		-- print( "setup" )
	end,
	--
	-- Called before each move. You should use your entity and cmd to
	-- fill mv with information you need for your move.
	--
	StartMove =  function( self, mv, cmd )

		-- print( "start move" )
		--
		-- Set the observer mode to chase so that the entity is drawn
		--
		self.Player:SetObserverMode( OBS_MODE_CHASE )

		--
		-- Use (E) was pressed - stop it.
		--
		-- if ( mv:KeyReleased( IN_USE ) ) then
			-- self:Stop()
		-- end

		--
		-- Update move position and velocity from our entity
		--
		local ang = mv:GetAngles()
		mv:SetOrigin( self.Entity:GetNetworkOrigin() )
		mv:SetVelocity( self.Entity:GetAbsVelocity() )
		mv:SetMoveAngles( ang )		-- Always move relative to the player's eyes

		mv:SetAngles( self.Entity:GetAngles() )

	end,

	--
	-- Runs the actual move. On the client when there's
	-- prediction errors this can be run multiple times.
	-- You should try to only change mv.
	--
	Move = function( self, mv )

		--
		-- Set up a speed, go faster if shift is held down
		--
		local speed = 0.0005 * FrameTime()
		if ( mv:KeyDown( IN_SPEED ) ) then speed = 0.005 * FrameTime() end

		--
		-- Get information from the movedata
		--
		local ang = mv:GetMoveAngles()
		local pos = mv:GetOrigin()
		local vel = self.Velocity or Vector( 0, 0, 0 )-- mv:GetVelocity()

		-- Cancel out the roll
		ang.pitch = 0
		ang.roll = 0

		--
		-- Add velocities. This can seem complicated. On the first line
		-- we're basically saying get the forward vector, then multiply it
		-- by our forward speed (which will be > 0 if we're holding W, < 0 if we're
		-- holding S and 0 if we're holding neither) - and add that to velocity.
		-- We do that for right and up too, which gives us our free movement.
		--
		vel = vel + ang:Forward()	* mv:GetForwardSpeed()	* speed
		vel = vel + ang:Right()		* mv:GetSideSpeed()		* speed
		vel = vel + ang:Up()		* mv:GetUpSpeed()		* speed

		--
		-- We don't want our velocity to get out of hand so we apply
		-- a little bit of air resistance. If no keys are down we apply
		-- more resistance so we slow down more.
		--
		if ( math.abs(mv:GetForwardSpeed()) + math.abs(mv:GetSideSpeed()) + math.abs(mv:GetUpSpeed()) < 0.1 ) then
			vel = vel * 0.70
		else
			vel = vel * 0.99
		end

		--
		-- Add the velocity to the position (this is the movement)
		--
		-- trace first
		local target = pos + vel * 1
		local tr = util.TraceLine( {
			start = pos,
			endpos = target + vel * 2,
			filter = self.Entity
		} )
		if ( !tr.HitWorld ) then
			pos = target
		end

		--
		-- We don't set the newly calculated values on the entity itself
		-- we instead store them in the movedata. These get applied in FinishMove.
		--
		-- mv:SetVelocity( vel )
		mv:SetOrigin( pos )
		self.Entity:SetPos( pos )
		self.Velocity = vel
	end,

	--
	-- The move is finished. Use mv to set the new positions
	-- on your entities/players.
	--
	FinishMove =  function( self, mv )

		--
		-- Update our entity!
		--
		self.Entity:SetNetworkOrigin( mv:GetOrigin() )
		self.Entity:SetAbsVelocity( mv:GetVelocity() )
		self.Entity:SetAngles( mv:GetAngles() )

		--
		-- If we have a physics object update that too. But only on the server.
		--
		-- if ( SERVER && IsValid( self.Entity:GetPhysicsObject() ) ) then

			-- self.Entity:GetPhysicsObject():EnableMotion( true )
			-- self.Entity:GetPhysicsObject():SetPos( mv:GetOrigin() );
			-- self.Entity:GetPhysicsObject():Wake()
			-- self.Entity:GetPhysicsObject():EnableMotion( false )

		-- end

	end


}, "drive_base" )
