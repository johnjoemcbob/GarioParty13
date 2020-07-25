AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self.Damage = 100 -- How much damage the cannon ball does

	self.Entity:SetModel( "models/XQM/Rails/gumball_1.mdl" )
	self.Entity:SetMaterial( "phoenix_storms/point1" )
	self.Entity:SetColor( 0, 0, 0, 255 )
	-- self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:PhysicsInitSphere( 2 )
	self.Entity:SetModelScale( 0.1 )
	-- debugoverlay.Sphere( self.Entity:GetPos(), 2, 5, Color( 255, 255, 0, 255 ), true )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )	
	self.Entity:SetSolid( SOLID_VPHYSICS )

	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		-- phys:EnableGravity( false )
	end
end

function ENT:PhysicsCollide(data, physobj)
	-- self.NearCannon = false
	-- for k,v in pairs(ents.FindInSphere(self.Entity:GetPos(),512)) do
		-- if v:GetClass() == "ship_cannon" then
			-- self.NearCannon = true
		-- end
	-- end

	-- if self.NearCannon == true then else
		for k,v in pairs( ents.FindInSphere( self.Entity:GetPos(), 512 ) ) do
			v:TakeDamage( self.Damage )
		end

		local explosion = ents.Create("env_explosion")
		explosion:SetKeyValue("spawnflags",128)
		explosion:SetPos(self.Entity:GetPos())
		explosion:Spawn()
		explosion:Fire("explode","",0)

		local explosion = ents.Create("env_physexplosion")
		explosion:SetKeyValue("magnitude",2)
		explosion:SetPos(self.Entity:GetPos())
		explosion:Spawn()
		explosion:Fire("explode","",0)
	-- end
	self.Entity:Remove()
end

function ENT:Shoot( vel, dir, mult )
	self:GetPhysicsObject():ApplyForceCenter( ( vel * 110 ) + ( dir * 800 ) * mult + Vector( 0, 0, 1 ) * 50 )
end
