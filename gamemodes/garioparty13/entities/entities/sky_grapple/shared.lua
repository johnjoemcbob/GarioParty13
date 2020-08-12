-- Matthew Cormack (@johnjoemcbob)
-- 17/08/15
-- Grapple hook rope entity
-- Fired by the player & moves towards their target,
-- Reels the player in when it hits the target
-- If the target is an entity, also reels the entity in
-- Rope is drawn using render.DrawBeam

if SERVER then
	AddCSLuaFile( "shared.lua" )
end

ENT.Type = "anim"

-- The direction to fire the grapple in, set when it is fired in init.lua
ENT.Direction = Vector( 0, 0, 0 )

-- Flag for when the grapple has collided with either the world or an entity,
-- and the player should begin reeling in
ENT.GrappleAttached = false

-- The time at which the grapple attached to something
ENT.GrappleStartTime = 0

-- The speed at which to shoot out the hook
ENT.CastSpeed = 1500 * 10

-- The speed at which to reel in the player
ENT.ReelSpeed = 1500 * 100

-- The speed at which the hook will stop reeling in the player, if it can't solve them to it's exact position
ENT.MinReelSpeed = 100

-- The multiplier on the inverted object speed for when grappling against players/entities
ENT.InvertSpeedMultiplier = 0.001

-- The distance at which to stop reeling in
ENT.MinDistance = 50

-- The distance from start to end last frame, for stopping the player near the entity & not going past it
ENT.LastDistance = nil

-- The direction the hook was moving in last frame, for stopping the retracting from overshooting
ENT.LastDirection = nil

local RopeMaterial = Material( "cable/cable" )

sound.Add( {
	name = "RopeSound",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/tripwire/ropeshoot.wav"
} )

sound.Add( {
	name = "ReelSound",
	channel = CHAN_STATIC,
	volume = 0.5,
	level = 80,
	pitch = { 40, 80 },
	sound = "weapons/357/357_spin1.wav"
} )

function ENT:Initialize()
	-- Initialize shared properties
	self:DrawShadow( false )
	self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
	self:SetModelScale( 0.1, 0 )
	self:SetSolid( SOLID_BBOX )
	--self:SetCustomCollisionCheck( true )

	if ( SERVER ) then
		-- Physics enabled, gravity disabled
		self:PhysicsInitSphere( 5, "default" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		if ( self:GetPhysicsObject() and IsValid( self:GetPhysicsObject() ) ) then
			self:GetPhysicsObject():EnableGravity( false )
			self:GetPhysicsObject():SetVelocity( ( self.Direction * self.CastSpeed ) + self.Owner:GetVelocity() )
		end

		-- Replicate the owner to clients
		self:SetOwnerIndex( self.Owner:EntIndex() )

		-- Spawn and parent the visual models representing the hook
		self.VisualModels = {}
		for hook = 1, 4 do
			local hookmodel = ents.Create( "prop_dynamic" )
				hookmodel:SetModel( "models/props_junk/meathook001a.mdl" )
				hookmodel:SetAngles( Angle( 0, 90 * hook, 90 ) )
				hookmodel:SetPos( self:GetPos() )
				hookmodel:SetModelScale( 0.25, 0 )
			hookmodel:Spawn()
			hookmodel:SetParent( self )
			table.insert( self.VisualModels, hookmodel )
		end

		-- Rotate the hook to face the target
		self:SetAngles( self.Direction:Angle() + Angle( -90, 0, 0 ) )

		-- Emit the firing sound
		self:EmitSound( "weapons/crossbow/fire1.wav" )

		-- Play the fire and reel in sound loop
		self.Owner:EmitSound( "RopeSound" )

		timer.Create( "ReelSound", 0.3, 0, function()
			if ( self.Reeling ) then
				if ( self.Owner and IsValid( self.Owner ) ) then
					self.Owner:StopSound( "ReelSound" )
					self.Owner:EmitSound( "ReelSound" )
				end
			end
		end )
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "OwnerIndex" )
end

function ENT:Think()
	if ( ( not self.Owner ) or ( not IsValid( self.Owner ) ) ) then return end

	-- If it's in the water then retract
	if ( self:WaterLevel() > 0 ) then
		self:HookRemove()
	end

	-- Retract the hook back towards the player (autoremoved on a timer in HookRemove)
	if ( self.Retracting ) then
		local direction = ( self.Owner:GetPos() - self:GetPos() ):GetNormalized()
		if ( not self.LastDirection ) then
			self.LastDirection = direction
		end

		-- Get the angle between the current direction of retracting and the one used last frame
		local dot = direction:Dot( self.LastDirection )
		local angle = math.deg( math.acos( dot ) )

		-- Remove if it's close to the player, or the direction has changed
		if (
			( self:GetPos():Distance( self.Owner:GetPos() ) < 200 ) or
			( angle > 45 )
		) then
			self:Remove()
			return
		end

		-- Move towards the player
		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			if ( ( not self.LastDirection ) or ( self.LastDirection == direction ) ) then
				phys:SetVelocity( direction * self.ReelSpeed )
			end
		end

		-- Store last direction to stop overshooting
		self.LastDirection = direction
	-- Move towards attached object
	elseif ( IsValid( self.Owner ) and ( self.GrappleAttached ~= false ) ) then
		local grappletype = type( self.GrappleAttached )
		local direction, distance
		-- Moving object
			if ( ( grappletype == "Player" ) or ( grappletype == "Entity" ) ) then
				-- Remove the grapple from the player if it is dead, or has been dead recently
				if (
					( grappletype == "Player" ) and -- Is a player
					(
						( not self.GrappleAttached:Alive() ) -- Is dead
					)
				) then
					self:HookRemove()
					return
				end

				direction = self.GrappleAttached:GetPos() - self.Owner:GetPos()
				distance = self.GrappleAttached:GetPos():Distance( self.Owner:GetPos() )

				-- In player/entity case, move both towards each other
				local phys = self.GrappleAttached:GetPhysicsObject()
				if ( phys and IsValid( phys ) ) then
					if ( self.LastDistance and ( distance > self.LastDistance ) ) then
						--distance = 0
					end

					if ( distance < self.MinDistance ) then
						direction = Vector( 0, 0, 0 )
					end

					local velocity = direction:GetNormalized() * FrameTime() * -self.ReelSpeed
					-- Entity has a physics object, set velocity on that too
					if ( grappletype == "Entity" ) then
						phys:SetVelocity( velocity )
					else
						self.GrappleAttached:SetVelocity( velocity )
					end

					-- Ensure the player is not stuck to the ground
					self.GrappleAttached:SetGroundEntity( nil )
				end
			-- Static world position
			else
				direction = self.GrappleAttached - self.Owner:GetPos()
				distance = self.GrappleAttached:Distance( self.Owner:GetPos() )
			end
			-- Reduce the reeling in speed until it can either solve to the hook position or is too small a speed to notice
			if ( self.LastDistance and ( distance > self.LastDistance ) and ( grappletype == "Vector" ) ) then
				--self.ReelSpeed = self.ReelSpeed / 4
			end
			if ( ( distance < self.MinDistance ) or ( self.ReelSpeed < self.MinReelSpeed ) ) then
				direction = Vector( 0, 0, 0 )
				-- World connection, stop moving
				if ( grappletype == "Vector" ) then
					self.Owner:SetMoveType( MOVETYPE_NONE )
				end

				-- Stop the reel in sound effect
				self.Reeling = false
			else
				-- Start the reel in sound effect
				self.Reeling = true
			end
		-- Crouching changes to reel in mode, if the player is near a surface
		local trace = util.TraceLine( {
			start = self.Owner:GetPos(),
			endpos = self.Owner:GetPos() - Vector( 0, 0, 5 ),
			filter = function( ent )
				if ( ent == self.Owner ) then
					return true
				end
			end
		} )
		if ( ( not self.Owner:KeyDown( IN_DUCK ) ) or ( not trace.Hit ) ) then
			self.Owner:SetVelocity( direction:GetNormalized() * FrameTime() * self.ReelSpeed - self.Owner:GetVelocity() )
		end

		-- Ensure the player is not stuck to the ground
		self.Owner:SetGroundEntity( nil )

		-- Store this distance for next frame
		self.LastDistance = distance
	end
end

function ENT:PhysicsCollide( data, phys )
	local entity
	local hitpos = data.HitPos
	local mattype = MAT_GRASS
	-- Hit world, check for skybox
	if ( data.HitEntity:EntIndex() == 0 ) then
		local trace = util.TraceLine(
			{
				start = self:GetPos(),
				endpos = self:GetPos() + ( ( hitpos - self:GetPos() ) * 100 ),
				mask = MASK_SOLID_BRUSHONLY
			}
		)
		mattype = trace.MatType
		hitpos = trace.HitPos
	-- Otherwise use the entity
	else
		entity = data.HitEntity
	end
	self:Attach( { Entity = entity, HitPos = hitpos, HitNormal = data.HitNormal, MatType = mattype } )
end

function ENT:Attach( trace )
	-- Flagged as disabled
	if ( self.DisableAttach ) then return end
	-- Not world, player or prop
	if ( trace.Entity and ( trace.Entity:GetClass() ~= "player" ) and ( trace.Entity:GetClass() ~= "sky_physprop" ) and ( trace.Entity:GetClass() ~= "prop_physics" ) ) then return end

	-- Don't attach to skyboxes
	if ( trace.MatType == MAT_DEFAULT ) then
		-- Disable ever being able to attach
		self.DisableAttach = true

		-- Enable gravity on the hook
		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:EnableGravity( true )
			phys:SetVelocity( Vector( 0, 0, 0 ) )
		end

		return
	end

	-- Remove collision from the attached hook
	self:PhysicsDestroy()
	self:SetSolid( SOLID_NONE )
	self:SetAngles( trace.HitNormal:Angle() + Angle( -90, 0, 0 ) )
	self:SetPos( trace.HitPos )

	-- Flag as attached to something
	self.GrappleAttached = trace.HitPos
	self.GrappleStartTime = CurTime()

	-- Disable gravity on the player
	self.Owner:SetGravity( 0 )

	if ( IsValid( trace.Entity ) ) then
		-- Parent the hook to the entity/world
		self:SetParent( trace.Entity )

		-- Flag as attached to an object
		self.GrappleAttached = trace.Entity

		-- Attached to a thrown prop or shield
		if ( trace.Entity:GetClass() == "sky_physprop" ) then
			trace.Entity.LastGrappledBy = self.Owner
			trace.Entity.RemoveTime = CurTime() + SkyView.Config.RemovePropTime

			-- Attached to an active shield, make it inactive
			if ( trace.Entity.IsShield and trace.Entity.IsActiveShield ) then
				trace.Entity.IsActiveShield = false
				trace.Entity.Owner.Shield = nil
			end
		end
	end

	-- Stop the reel in sound effect
	self.Owner:StopSound( "RopeSound" )

	-- Emit the firing sound from the entity and from the player so they can always hear it
	self:EmitSound( "weapons/crossbow/bolt_skewer1.wav" )
	sound.Play( "weapons/crossbow/bolt_skewer1.wav", self.Owner:GetPos(), 50 )

	-- Emit the reel in sound effect
	self.Reeling = true
end

function ENT:HookRemove()
	-- Don't retract twice
	if ( self.Retracting ) then return end

	-- Move hook back towards the player
	local phys = self:GetPhysicsObject()
	if ( ( not phys ) or ( not IsValid( phys ) ) ) then
		self:PhysicsInitSphere( 5, "default" )
		self:PhysWake()
	end
	self:SetSolid( SOLID_BBOX )
	self:SetParent( nil )
	self.DisableAttach = true
	self.Retracting = true
	self.GrappleAttached = false
	self.Reeling = true

	-- Stop the reel in sound effect
	if ( self.Owner and IsValid( self.Owner ) ) then
		self.Owner:StopSound( "ReelSound" )
	end

	-- Timer to remove the hook shortly after the animation
	timer.Simple( 2, function()
		if ( self and IsValid( self ) ) then
			self:Remove()
		end
	end )
end

function ENT:OnRemove()
	if ( SERVER ) then
		-- Remove the visual models
		for k, hookmodel in pairs( self.VisualModels ) do
			hookmodel:Remove()
		end

		-- Stop the shoot out sound effect
		if ( self.Owner and IsValid( self.Owner ) ) then
			self.Owner:StopSound( "RopeSound" )
		end
		timer.Destroy( "ReelSound" )
	end
end

if ( CLIENT ) then
	function ENT:Draw()
		if ( ( not self ) or ( not IsValid( self ) ) ) then return end

		self:DrawModel()

		local player = ents.GetByIndex( self:GetOwnerIndex() )
		if ( ( not player ) or ( not IsValid( player ) ) ) then return end

		-- Draw the grapple rope from the owning player to the entity position
		render.SetMaterial( RopeMaterial )
		render.DrawBeam(
			self:GetPos(),
			player:EyePos() - Vector( 0, 0, 10 ),
			2, 
			0, 1, 
			Color( 255, 255, 255, 255 )
		)
	end
end