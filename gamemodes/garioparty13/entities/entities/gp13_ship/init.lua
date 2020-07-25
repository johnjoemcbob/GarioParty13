AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "drive/drive_gp13_ship.lua" )

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
		ent:SetPos( pos + Vector( 0, 0, 100 ) )
		ent:SetOwner( ply )
		ent:Spawn()
		ent:Activate()
	return ent
end

function ENT:Think()
	-- Sounds
	-- temp, replace with timed or something better
	if ( math.random( 1, 200 ) > 195 ) then
		self:EmitSound( "ambient/creatures/seagull_idle" .. math.random( 1, 3 ) .. ".wav", 75, math.random( 90, 110 ), 0.5 )
	end
	-- print( self.Drive )
	local speedbonus = self:GetAbsVelocity():Length()
	if ( !self.NextWave or self.NextWave <= CurTime() ) then
		-- print( speedbonus )
		self:EmitSound( "ambient/water/wave" .. math.random( 1, 6 ) .. ".wav", 75, math.Clamp( math.random( 90, 110 ) + speedbonus * 50, 1, 254 ), math.Clamp( 0.3 + ( speedbonus / 16 ), 0, 1 ) )
		self.NextWave = CurTime() + 0.5
	end

	-- Every tick
	-- self:NextThink( CurTime() )
	-- return true
end

function ENT:OnRemove()
	drive.End( self.Owner, self )
end
