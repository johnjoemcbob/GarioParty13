AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "drive/drive_gp13_donuthole.lua" )

util.AddNetworkString( HOOK_PREFIX .. "EntScale" )
util.AddNetworkString( HOOK_PREFIX .. "Drive" )

local function sendScale( self, scale, phys )
	-- Parameter can be a float instead of Vector if all axes should be same scale
	if ( scale == tonumber( scale ) ) then
		scale = Vector( 1, 1, 1 ) * scale
	end
	self.Scale = scale

	net.Start( HOOK_PREFIX .. "EntScale" )
		net.WriteEntity( self )
		net.WriteVector( scale )
		net.WriteBool( phys )
	net.Broadcast()
end

local function sendDrive( self, ply )
	net.Start( HOOK_PREFIX .. "Drive" )
		net.WriteEntity( self )
	net.Send( ply )
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end

	local pos = tr.HitPos + tr.HitNormal * 2.5

	local ent = ents.Create( ClassName )
		ent:SetPos( pos )
		ent:SetOwner( ply )
		ent:Spawn()
		ent:Activate()
	return ent
end

-- function ENT:Initialize()
-- 	self:SetPos( self:GetPos() - Vector( 0, 0, 5 ) )
-- end

local init = false
function ENT:Think()
	if ( !init ) then
		self:ResizePhysics( 1 )
		init = true
	end
	-- if ( true ) then return end

	-- Resize
	local scale = self.Size
	-- self:Resize( Vector( scale, scale, 1 ) )

	-- Find new
	local tickfound = {}
		-- for k, v in pairs( ents.FindInSphere( self:GetPos(), GP13_Radius * scale ) ) do
			-- if ( v:GetClass() == "prop_physics" ) then
		for k, v in pairs( ents.FindByClass( "prop_physics" ) ) do
			if ( self:GetPos():DistToSqr( v:GetPos() ) <= ( GP13_Radius * scale ) * ( GP13_Radius * scale ) * DONUT_ALLOWANCE ) then
				local index = v:EntIndex()
				if ( !self.Inside[index] ) then
					--print( "move in" )
					self.Inside[index] = constraint.NoCollideWorld( v, game.GetWorld(), 0, 0 )
				
					local phys = v:GetPhysicsObject()
					if ( phys and phys:IsValid() ) then
						phys:Wake()
						phys:ApplyForceOffset( Vector( 0, 0, phys:GetMass() * 50 ), v:GetPos() + self.PullOffset )
					end
				end
				tickfound[index] = true
			end
		end
	-- Remove any old no longer found
	-- PrintTable( tickfound )
	-- print( "hi" )
	-- for index, con in pairs( self.Inside ) do
		-- if ( !tickfound[index] ) then
			-- if ( con and con:IsValid() ) then
				-- local ent = ents.GetByIndex( index )
				-- if ( ent:GetTable().Constraints ) then
					-- for k, v in pairs( ent:GetTable().Constraints ) do
						-- if ( v == con ) then
							-- print( "found it!" )
							-- con:Remove()
							-- ent:GetTable().Constraints[k] = nil
						-- end
					-- end
				-- end
			-- end
			-- self.Inside[index] = nil
		-- end
	-- end
	-- Handle all within
	for index, v in pairs( tickfound ) do
		local ent = ents.GetByIndex( index )
		-- Pull in any still within
		local down = Vector( 0, 0, -1 )
		local vertforce = 10
		local horiforce = 0-- -250
		local minvel = 20
		local dir = ( ent:GetPos() - self:GetPos() ):GetNormalized()
		--print( ent:GetVelocity():LengthSqr() )
		if ( ent:GetVelocity():LengthSqr() < minvel ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:Wake()
				phys:ApplyForceOffset( ( down * vertforce + dir * horiforce ) * phys:GetMass() * 1, self:GetPos() + self.PullOffset )
			end
		end
		-- Remove any consumed and add size
		local removeforce = 1000
		if ( ent:GetPos().z + self.RemoveAtDepth < self:GetPos().z ) then
			if ( !ent.GP13_Removed ) then
				timer.Simple( self.RemoveTime, function()
					if ( ent and ent:IsValid() and self.Inside ) then
						ent:Remove()
						self.Inside[index] = nil
					end
				end )
				ent.GP13_Removed = true
				self.Size = self.Size + self.SizeIncrement
				-- Resize
				local scale = self.Size
				self:Resize( Vector( scale, scale, 1 ) )

				GAMEMODE.EmitChainPitchedSound(
					"FlyHigh",
					self.Owner,
					Sound_OrchestraHit,
					75,
					0.2,
					100,
					20,
					5,
					0,
					20
				)

				self.Owner:SetNWInt( "Score", self.Owner:GetNWInt( "Score", 0 ) + 1 )
			else
				-- ent:SetPos( ent:GetPos() + down * removeforce )
			end
		end
	end

	-- Every tick
	-- self:NextThink( CurTime() )
	-- return true
end

function ENT:OnRemove()
	drive.End( self.Owner, self )
end

function ENT:Resize( scale )
	self:ResizePhysics( scale )
	self:ResizeVisuals( scale )
end

function ENT:ResizeVisuals( scale )
	sendScale( self, scale )
end

-- From: NoCollideWorld Addon
local MAX_CONSTRAINTS_PER_SYSTEM = 10
local function CreateConstraintSystem()
	local System = ents.Create("phys_constraintsystem")
	if !IsValid(System) then return end
	System:SetKeyValue("additionaliterations", GetConVarNumber("gmod_physiterations"))
	System:Spawn()
	System:Activate()
	return System
end

local function FindOrCreateConstraintSystem(Ent1, Ent2)
	local System
	if !Ent1:IsWorld() and Ent1:GetTable().ConstraintSystem and Ent1:GetTable().ConstraintSystem:IsValid() then System = Ent1:GetTable().ConstraintSystem end
	if System and System:IsValid() and System:GetVar("constraints", 0) > MAX_CONSTRAINTS_PER_SYSTEM then System = nil end
	if !System and !Ent2:IsWorld() and Ent2:GetTable().ConstraintSystem and Ent2:GetTable().ConstraintSystem:IsValid() then System = Ent2:GetTable().ConstraintSystem end
	if System and System:IsValid() and System:GetVar("constraints", 0) > MAX_CONSTRAINTS_PER_SYSTEM then System = nil end
	if !System or !System:IsValid() then System = CreateConstraintSystem() end
	if !System then return end
	Ent1.ConstraintSystem = System
	Ent2.ConstraintSystem = System
	System.UsedEntities = System.UsedEntities or {}
	table.insert(System.UsedEntities, Ent1)
	table.insert(System.UsedEntities, Ent2)
	System:SetVar("constraints", System:GetVar("constraints", 0)+1)
	return System
end

function constraint.NoCollideWorld(Ent1, Ent2, Bone1, Bone2)
	if !Ent1 or !Ent2 then return false end
	
	if Ent1 == game.GetWorld() then
		Ent1 = Ent2
		Ent2 = game.GetWorld()
		Bone1 = Bone2
		Bone2 = 0
	end
	
	if !Ent1:IsValid() or (!Ent2:IsWorld() and !Ent2:IsValid()) then return false end
	
	Bone1 = Bone1 or 0
	Bone2 = Bone2 or 0
	
	local Phys1 = Ent1:GetPhysicsObjectNum(Bone1)
	local Phys2 = Ent2:GetPhysicsObjectNum(Bone2)
	
	if !Phys1 or !Phys1:IsValid() or !Phys2 or !Phys2:IsValid() then return false end
	
	if Phys1 == Phys2 then return false end
	
	if Ent1:GetTable().Constraints then
		for k, v in pairs(Ent1:GetTable().Constraints) do
			if v:IsValid() then
				local CTab = v:GetTable()
				if (CTab.Type == "NoCollideWorld" or CTab.Type == "NoCollide") and ((CTab.Ent1 == Ent1 and CTab.Ent2 == Ent2) or (CTab.Ent2 == Ent1 and CTab.Ent1 == Ent2)) then return false end
			end	
		end
	end
	
	local System = FindOrCreateConstraintSystem(Ent1, Ent2)
	
	if !IsValid(System) then return false end
	
	SetPhysConstraintSystem(System)
	
	local Constraint = ents.Create("phys_ragdollconstraint")
	
	if !IsValid(Constraint) then
		SetPhysConstraintSystem(NULL)
		return false
	end
	Constraint:SetKeyValue("xmin", -180)
	Constraint:SetKeyValue("xmax", 180)
	Constraint:SetKeyValue("ymin", -180)
	Constraint:SetKeyValue("ymax", 180)
	Constraint:SetKeyValue("zmin", -180)
	Constraint:SetKeyValue("zmax", 180)
	Constraint:SetKeyValue("spawnflags", 3)
	Constraint:SetPhysConstraintObjects(Phys1, Phys2)
	Constraint:Spawn()
	Constraint:Activate()
	
	SetPhysConstraintSystem(NULL)
	constraint.AddConstraintTable(Ent1, Constraint, Ent2)
	
	local ctable = 
	{
		Type 			= "NoCollideWorld",
		Ent1  			= Ent1,
		Ent2 			= Ent2,
		Bone1 			= Bone1,
		Bone2 			= Bone2
	}
	
	Constraint:SetTable(ctable)
	
	return Constraint
end
