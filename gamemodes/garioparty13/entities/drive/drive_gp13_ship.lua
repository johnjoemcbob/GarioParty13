
AddCSLuaFile()

include( "drive/drive_base.lua" )

-- Derive
local DERIVE = "drive_base"

local SPEED_SETTING = {
	["BACKWARD"]	= 1,
	["EMPTY"]		= 2,
	["HALF_MAST"]	= 3,
	["FULL"]		= 4,
	["COUNT"]		= 5,
}
local SPEEDS = {
	-0.2,
	0,
	0.5,
	1,
}

drive.Register( "drive_gp13_ship",
{
	Init = function( self )
		-- Give the entity a reference to the driving script
		self.Entity.Drive = self

		self.CameraDist 	= 0.5
		self.CameraDistVel 	= 0.1

		self.Speed			= SPEED_SETTING.EMPTY

		self.InitialZ = self.Entity:GetPos().z
	end,

	CalcView =  function( self, view )
		local idealdist = math.max( 10, self.Entity:BoundingRadius() ) * self.CameraDist
		self:CalcView_ThirdPersonClamped( view, idealdist, 0, { self.Entity } )
		-- self:CalcView_ThirdPersonClamped( view, 1, 0, { self.Entity } )
		-- self:CalcView_FirstPersonClamped( view, idealdist )
		view.angles.roll = 0
		-- view.angles.pitch = math.Clamp( view.angles.pitch, 20, 40 )
	end,
	CalcView_FirstPersonClamped = function( self, view, dist )
		local eyeang = self.Player:EyeAngles()
		local min = 10
		local max = 90

		-- Set our calculated origin
		view.origin = self.Entity:GetPos() +
			self.Entity:GetForward() * ( -40 - dist / 10 ) +
			self.Entity:GetUp() * 20

		-- Set the angles to our view angles (not the entities eye angles)
		view.angles = eyeang

		-- view.znear = 0.001
	end,
	CalcView_ThirdPersonClamped = function( self, view, dist, hullsize, entityfilter )
		local eyeang = self.Player:EyeAngles()
		-- eyeang.pitch = math.Clamp( eyeang.pitch, 50, 90 )
		-- From -180->180 to new range
		local min = 1
		local max = 90
		-- print( view.angles.p )

		-- INVERT HERE
		-- eyeang.p = ( ( 1 - ( eyeang.p + 90 ) / 180 ) * ( max - min ) ) + min
		eyeang.p = ( ( ( eyeang.p + 90 ) / 180 ) * ( max - min ) ) + min

		-- Move the view backwards the size of the entity
		local neworigin = view.origin - eyeang:Forward() * dist

		if ( hullsize && hullsize > 0 ) then
			-- Trace a hull (cube) from the old eye position to the new
			local tr = util.TraceHull( {
											start	= view.origin,
											endpos	= neworigin,
											mins	= Vector( hullsize, hullsize, hullsize ) * -1,
											maxs	= Vector( hullsize, hullsize, hullsize ),
											filter	= entityfilter
										})
			-- If we hit something then stop there
			-- [ stops the camera going through walls ]						
			if ( tr.Hit ) then
				neworigin = tr.HitPos
			end
		end

		-- Set our calculated origin
		view.origin = neworigin

		-- Set the angles to our view angles (not the entities eye angles)
		view.angles = eyeang
	end,

	SetupControls = function( self, cmd )
		-- Zoom out when we use the mouse wheel
		self.CameraDistVel = self.CameraDistVel + cmd:GetMouseWheel() * -0.5

		self.CameraDist = self.CameraDist + self.CameraDistVel * FrameTime()
		self.CameraDist = math.Clamp( self.CameraDist, 2, 20 )
		self.CameraDistVel = math.Approach( self.CameraDistVel, 0, self.CameraDistVel * FrameTime() * 2 )
	end,

	StartMove =  function( self, mv, cmd )
		-- Set the observer mode to chase so that the entity is drawn
		self.Player:SetObserverMode( OBS_MODE_CHASE )

		-- Change ship speed
		if ( cmd:KeyDown( IN_FORWARD ) and !self.LastPressedForward ) then
			self.Speed = self.Speed + 1
		elseif ( cmd:KeyDown( IN_BACK ) and !self.LastPressedBackward ) then
			self.Speed = self.Speed - 1
		end
		-- TODO check keys here instead!!
		-- TODO check keys here instead!!
		-- TODO check keys here instead!!
		-- TODO check keys here instead!!
		-- TODO check keys here instead!!
		self.LastPressedForward = cmd:KeyDown( IN_FORWARD )
		self.LastPressedBackward = cmd:KeyDown( IN_BACK )
		self.Speed = math.Clamp( self.Speed, 1, SPEED_SETTING.COUNT - 1 )

		-- Update move position and velocity from our entity
		local ang = mv:GetAngles()
		mv:SetOrigin( self.Entity:GetNetworkOrigin() )
		mv:SetVelocity( self.Entity:GetAbsVelocity() )
		local ang = self.Entity:GetAngles()
			ang.pitch = 0
			ang.roll = 0
		mv:SetMoveAngles( ang )
		mv:SetAngles( self.Entity:GetAngles() )
	end,

	Move = function( self, mv )
		-- Set up a speed
		-- local speed = FrameTime() * 0.0005
		local speed = FrameTime() * 20 * SPEEDS[self.Speed]
		local decreasespeed = FrameTime() * 5
		local rotatespeed = FrameTime() * 0.005
		local tiltspeed = FrameTime() * 0.006
		local rollspeed = FrameTime() * 3
		local risespeed = FrameTime() * 1
		local bobspeed = 0.01

		-- Get information from the movedata
		local ang = mv:GetAngles()
		local pos = mv:GetOrigin()
		local vel = mv:GetVelocity()
		vel = LerpVector( decreasespeed, vel, Vector( 0, 0, 0 ) )

		-- Cancel out the pitch
		ang.pitch = 0
		-- ang.roll = 0

		-- Lerp roll down
		ang.roll = Lerp( rollspeed, ang.roll, 0 )

		-- Turning
		ang:RotateAroundAxis( ang:Up(), -mv:GetSideSpeed() * rotatespeed )
		ang:RotateAroundAxis( ang:Forward(), -mv:GetSideSpeed() * tiltspeed )
		-- Don't allow standing still while turning
		if ( speed == 0 and mv:GetSideSpeed() != 0 ) then
			speed = FrameTime() * 20 * 0.2
		end

		-- Bob on water
		ang:RotateAroundAxis( ang:Forward(), math.sin( CurTime() ) * bobspeed )
		ang:RotateAroundAxis( ang:Right(), math.cos( CurTime() ) * bobspeed )

		-- Bob forward depending on speed
		ang:RotateAroundAxis( ang:Right(), math.sin( CurTime() * speed * 20 ) * 2 )

		-- Apply speed
		vel = vel + ang:Forward() * speed

		-- Move
		local newpos = pos + vel
			pos = pos + vel
			if ( SERVER ) then
				pos.z = self.InitialZ
			end

		-- Store to be applied later in FinishMove
		mv:SetVelocity( vel )
		mv:SetOrigin( pos )
		mv:SetAngles( ang )

		-- Cannons
		local z = 1.5
		local cannons = {
			left = {
				Vector( -32.5, -13, z ),
				Vector( -22.5, -15, z ),
				Vector( -12, -15, z ),
				Vector( -1, -15, z ),
				Vector( 8, -15, z ),
				Vector( 18, -15, z ),
				Vector( 30, -11, z ),
			},
			right = {
				Vector( -32.5, 13, z ),
				Vector( -22.5, 15, z ),
				Vector( -12, 15, z ),
				Vector( -1, 15, z ),
				Vector( 8, 15, z ),
				Vector( 18, 15, z ),
				Vector( 30, 11, z ),
			},
		}
		-- if ( mv:KeyPressed( IN_ATTACK ) ) then
		if ( self.Entity.Owner:KeyPressed( IN_ATTACK ) ) then
			self:OnShoot( mv, -1 )

			-- for k, cannon in pairs( cannons.left ) do
			local ind = 0
			for k, cannon in RandomPairs( cannons.left ) do
				local pitch = ind
				timer.Simple( 0.05 * ind, function()
					self:Shoot( mv, cannon, 1, pitch )
				end )
				ind = ind + 1
			end
		-- elseif ( mv:KeyPressed( IN_ATTACK2 ) ) then
		elseif ( self.Entity.Owner:KeyPressed( IN_ATTACK2 ) ) then
			self:OnShoot( mv, 1 )

			-- for k, cannon in pairs( cannons.right ) do
			local ind = 0
			for k, cannon in RandomPairs( cannons.right ) do
				local pitch = ind
				timer.Simple( 0.05 * ind, function()
					self:Shoot( mv, cannon, -1, pitch )
				end )
				ind = ind + 1
			end
		end
	end,

	FinishMove = function( self, mv )
		-- Update entity transforms
		self.Entity:SetNetworkOrigin( mv:GetOrigin() )
		self.Entity:SetAbsVelocity( mv:GetVelocity() )
		self.Entity:SetAngles( mv:GetAngles() )

		-- Update entity physics on server
		if ( SERVER && IsValid( self.Entity:GetPhysicsObject() ) ) then
			self.Entity:GetPhysicsObject():EnableMotion( true )
			self.Entity:GetPhysicsObject():SetPos( mv:GetOrigin() );
			self.Entity:GetPhysicsObject():Wake()
			self.Entity:GetPhysicsObject():EnableMotion( false )
		end
	end,

	OnShoot = function( self, mv, dir )
		local ang = mv:GetAngles()
			ang:RotateAroundAxis( ang:Forward(), -dir * 5 )
		mv:SetAngles( ang )
	end,

	Shoot = function( self, mv, cannon, dir, pitch )
		local function getcannon( forward, right, up )
			return mv:GetOrigin() +
				mv:GetAngles():Forward() * forward +
				mv:GetAngles():Right() * right +
				mv:GetAngles():Up() * up
		end
		local cannon = getcannon( cannon.x, cannon.y, cannon.z )
		local direction = mv:GetAngles():Right() * dir

		-- Smoke particles
		if ( CLIENT ) then
			local effectdata = EffectData()
				effectdata:SetStart( mv:GetVelocity() )
				effectdata:SetOrigin( cannon )
				effectdata:SetNormal( direction )
			util.Effect( "gp13_cannon", effectdata )
		end

		-- Emit sound
		self.Entity:EmitSound( "phx/explode00.wav", 75, 80 + ( 10 * pitch ) + math.random( -20, 20 ), 0.3 )

		-- Create cannon ball
		if ( SERVER ) then
			local ent = ents.Create( "gp13_cannonball" )
				ent:SetPos( cannon )
			ent:Spawn()
			-- timer.Simple( 1, function()
				ent:Shoot( mv:GetVelocity(), -direction, 1 )
			-- end )

			-- Auto cleanup if no hits
			timer.Simple( 4, function()
				if ( ent and ent:IsValid() ) then
					ent:Remove()
					ent = nil
				end
			end )
		end
	end,
}, "drive_base" )
