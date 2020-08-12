-- Author: Jordan Brown (@DrMelon)
-- 17/08/2015
-- Arcade Mode DLC for SkyView - Stat-Tracking Props
-- This, and the stats within, are for a currently-active prop only and not the global stats
-- for each kind of prop. Those will be handled separately.

if SERVER then
	AddCSLuaFile( "shared.lua" )
end

ENT.Type = "anim"

-- Stats
ENT.TimesBounced = 0
ENT.PlayersKilled = 0
ENT.TimesGrappled = 0
ENT.OtherPropsHit = 0
ENT.SamePropsHit = 0
--ENT.ThrownBy = nil
ENT.LastGrappledBy = nil
ENT.RecentlyBounced = 0
ENT.RemoveTime = 0
ENT.NearMissRadius = 100
ENT.NearMissTime = 0.7
ENT.NearPlayers = nil
ENT.CollidedPlayers = nil
ENT.LastBounce = 0
ENT.BetweenBounceTime = 1
ENT.IsHoming = false
ENT.HomingTarget = nil
ENT.IsSaw = false
--ENT.JustThrown = 0
--ENT.Owner = nil

-- Saw sound
sound.Add( {
	name = "saw_travel",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = { 150, 170 },
	sound = "ambient/machines/spin_loop.wav"
} )

function ENT:Initialize()
	-- Set up physics
	if ( SERVER ) then
		if ( not self:IsInWorld() ) then
			self:Remove()
			return
		end

		if ( self:GetModel() == "models/error.mdl" ) then
			-- The model name is the key; find a random one
			local count = 0
				for model, v in pairs( gmod.GetGamemode().PropDescriptions ) do
					count = count + 1
				end
			local randmodel = math.random( 1, count )
			local currentmodel = 1
			for model, v in pairs( gmod.GetGamemode().PropDescriptions ) do
				if ( randmodel == currentmodel ) then
					self:SetModel( model )
					break
				end
				currentmodel = currentmodel + 1
			end
		end
		self:PhysicsInit( SOLID_VPHYSICS )

		self.RemoveTime = CurTime() + SkyView.Config.RemovePropTime

		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:EnableDrag( false )
			--phys:Wake()
		end
	end

	--self:SetCustomCollisionCheck( true )

	self.NearPlayers = {}
	self.CollidedPlayers = {}
	self.IsHoming = false
	self.HomingTarget = false
	self.IsSaw = false

	-- Change the physics engine settings to allow for faster moving objects
	local perf = physenv.GetPerformanceSettings()
		perf.MaxVelocity = 500000
	physenv.SetPerformanceSettings( perf )
end

function ENT:SetupDataTables()
	-- Thrown-By and Owner Vals
	self:NetworkVar("Entity", 0, "ThrownBy")
	self:NetworkVar("Entity", 1, "PropOwner")
	-- JustThrown Value
	self:NetworkVar("Float", 0, "JustThrown")
end

function ENT:Think()
	if( SERVER ) then
		if ( not self:IsInWorld() ) then
			self:Remove()
			return
		end

		-- Apply homing logic
		self:HomeIn()

		-- Nocollide with owner if saw
		if(self.IsSaw) then
			self:SetJustThrown( 100000 )
		end

		-- Tick down recently bounced timer.
		self.RecentlyBounced = self.RecentlyBounced - 1
		if(self.RecentlyBounced < 0) then
			self.RecentlyBounced = 0
		end

		-- Tick down just-thrown timer
		self:SetJustThrown(math.max(self:GetJustThrown() - 100 * FrameTime(),0))

		-- Tick down until removal of the prop
		if ( CurTime() > self.RemoveTime ) then
			self:StopSound("saw_travel")
			self:Remove()
			return
		end

		-- Near miss logic;
		-- Find near by players and flag them for collision checking, if they collide within a certain time (either before or after)
		-- then they are removed from the near miss tracking; otherwise the stat is incremented and a message displayed
		if ( not self.IsActiveShield ) then
			-- print( "NEAR MISS LOGIC" )
			local nearents = ents.FindInSphere( self:GetPos(), self.NearMissRadius )
			for k, ent in pairs( nearents ) do
				if ( ent:IsPlayer() ) then
					-- Only count a near miss with the throwing player if the entity has existed for a while, and bounced back
					if ( ( self:GetJustThrown() == 0 ) or ( ent ~= self.Owner ) ) then
						if ( not self.NearPlayers[ent:EntIndex()] ) then
							self.NearPlayers[ent:EntIndex()] = CurTime()
						end
					end
				end
			end
		end

		-- Check players that have been near against players which have collided to find those who narrowly missed the object
		for plyindex, neartime in pairs( self.NearPlayers ) do
			if ( ( CurTime() - self.NearMissTime ) > neartime ) then
				local ply = ents.GetByIndex( plyindex )

				-- The time since the player was logged as near
				local nearstarttime = CurTime() - neartime

				-- The time since the player last collided with this prop
				local timedif = math.abs( CurTime() - ( self.CollidedPlayers[plyindex] or CurTime() ) )

				-- Has never collided with the player, or did so some time ago
				if ( ( not self.CollidedPlayers[plyindex] ) or ( timedif > self.NearMissTime ) ) then
					-- Flag this as a collision to delay near miss messages for this player and this prop
					self.NearPlayers[plyindex] = nil
					self.CollidedPlayers[plyindex] = CurTime() + 10
				end
			end
		end

		local phys = self:GetPhysicsObject()
		if ( ( not phys ) or ( not IsValid( phys ) ) ) then
			self:Remove()
			return
		end

		self:NextThink( CurTime() )
		return true
	end
end

function ENT:ReflectVector( vec, normal, bounce )
	return bounce * ( -2 * ( vec:Dot( normal ) ) * normal + vec )
end

function ENT:PhysicsCollide( colData, collider )
	if( SERVER ) then
		-- Make em bouncy
		local hitEnt = colData.HitEntity

		local bounceVel = self:ReflectVector( colData.OurOldVelocity, colData.HitNormal, SkyView.Config.ReflectNum )

		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			if(!hitEnt:IsWorld() and !string.find(hitEnt:GetClass(), "func")) then
				if ( hitEnt.IsShield ) then
					-- print( "BOUNCE SHIELD" )
					hitEnt:EmitSound(SkyView:RandomShieldSound())
					-- Get velocity based on the shield angles
					local bounceVel = self:GetAngles():Forward() * -10000
					phys:SetVelocity(bounceVel)
				end
			elseif ( hitEnt:IsWorld() or string.find( hitEnt:GetClass(), "func" ) ) then
				-- In an attempt to stop physics crashes, props can only bounce every so often
				if ( CurTime() >= self.LastBounce ) then
					-- print( "BOUNCE" )
					phys:SetVelocity(bounceVel)
					self.LastBounce = CurTime() + self.BetweenBounceTime
				end
			end
		end

		if ( self.IsSaw ) then
			self:EmitSound("npc/manhack/grind".. math.random(1,5) ..".wav")
		end

		-- Near miss logic
		if ( hitEnt:IsPlayer() ) then
			self.CollidedPlayers[hitEnt:EntIndex()] = CurTime()
			if ( self.IsSaw ) then
				self:EmitSound("npc/manhack/grind_flesh1.wav", 120)
			end
		end

		-- Stats
		if(colData.Speed > 50) then
			self.TimesBounced = self.TimesBounced + 1
			self.RecentlyBounced = 60 -- engage bounce timer.
		end

		if(hitEnt:GetClass() == "sky_physprop" or hitEnt:GetClass() == "prop_physics") then
			if(hitEnt:GetModel() == self:GetModel()) then
				self.SamePropsHit = self.SamePropsHit + 1
			end
			self.OtherPropsHit = self.OtherPropsHit + 1
		end
	end
end

function ENT:HomeIn()
	-- Make the sawmerang come back
	if(self.IsSaw == true and self:GetPos():Distance(self:GetThrownBy():GetPos()) > 1450) then
		local flightVector = (self:GetThrownBy():GetPos() + self:GetThrownBy():GetAngles():Up() * 80) - self:GetPos()
		flightVector:Normalize()
		flightVector = flightVector * 1000
		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:SetVelocity(phys:GetVelocity() + flightVector)
		end
	end

	if(self.IsHoming == false) then
		return
	end
	-- Apply force towards stored target
	if(self.HomingTarget and IsValid(self.HomingTarget) and self.HomingTarget:Alive()) then
		local flightVector = self.HomingTarget:GetPos() - self:GetPos()
		flightVector:Normalize()
		flightVector = flightVector * 2000
		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:SetVelocity(phys:GetVelocity() + flightVector)
		end
	else -- Try to find a target
		local nearbyEnts = ents.FindInSphere(self:GetPos(), 350)
		for k, v in pairs(nearbyEnts) do
			if(v != nil and IsValid(v) and v:IsPlayer() and v != self:GetThrownBy() and v:Alive()) then
				self.HomingTarget = v
				-- Beep
				self:EmitSound("npc/roller/mine/rmine_tossed1.wav")
			end
		end
	end
end

function ENT:Throw( from, velocity, owner )
	if ( ( not self ) or ( not IsValid( self ) ) ) then return end

	self:SetPos( from )
	local phys = self:GetPhysicsObject()
	if ( phys and IsValid( phys ) ) then
		phys:SetVelocity( velocity )
	end
	if( owner != nil and IsValid(owner)) then
		self:SetThrownBy(owner)
	end
	self:SetJustThrown(1)
end