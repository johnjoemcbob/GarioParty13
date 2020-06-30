include( "shared.lua" )

include( "drive/drive_gp13_ship.lua" )

net.Receive( HOOK_PREFIX .. "EntScale", function( len, ply )
	local self = net.ReadEntity()
	local scale = net.ReadVector()
	local phys = net.ReadBool()

	local maxtries = 5
	local function try()
		if ( self and self:IsValid() ) then
			self.Scale = scale
			local mat = Matrix()
				mat:Scale( scale )
			self:EnableMatrix( "RenderMultiply", mat )

			local size = Vector( GP13_Plate_Size, GP13_Plate_Size, 1 )
			local min = Vector()
				min.x = -size.x * scale.x
				min.y = -size.y * scale.y
				min.z = -size.z * scale.z
			local max = Vector()
				max.x = size.x * scale.x
				max.y = size.y * scale.y
				max.z = size.z * scale.z
			self:SetRenderBounds( min, max )

			if ( phys ) then
				self:PhysicsInit( SOLID_VPHYSICS )
				GAMEMODE.ResizePhysics( self, self.Scale )
			end
		elseif ( maxtries > 0 ) then
			timer.Simple( 1, function() try() end )
		end
		maxtries = maxtries - 1
	end
	try()
end )

net.Receive( HOOK_PREFIX .. "Drive", function( len )
	local self = net.ReadEntity()

	self.Owner = LocalPlayer()
end )

function ENT:SendRequestInit( ply )
	net.Start( HOOK_PREFIX .. "ClientRequestInit" )
		net.WriteEntity( self )
	net.SendToServer()
end

function ENT:Initialize()
	if ( self.Owner == LocalPlayer() ) then
		self.Loop = self:StartLoopingSound( "ambient/wind/wind_med.wav" )
	end
end

function ENT:Think()
	local vel = self:GetVelocity():Length()
	if ( vel > 10 ) then
		-- Get the position of the back of the ship for leaving trail
		local ang = self:GetAngles()
			ang.pitch = 0
			ang.roll = 0
			ang:RotateAroundAxis( ang:Up(), 90 )
		local pos = self:GetPos()-- + Vector( 0, 0, -5 )
			local sign = ( self:GetAngles().roll < 0 ) and -1 or 1
			-- print( self:GetAngles().roll )
			pos = pos + ang:Forward() * ( 0 - self:GetAngles().roll * 1.5 )
			pos = pos + ang:Right() * -35
		local effectdata = EffectData()
			effectdata:SetOrigin( pos )
			effectdata:SetNormal( ang:Right() )
		util.Effect( "gp13_trail", effectdata )
	end
end

function ENT:Draw()
	-- Last
	local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Right(), 90 )
	self:SetAngles( ang )
	self:SetPos( self:GetPos() + Vector( 0, 0, -75 ) )
	self:DrawModel()
end

function ENT:OnRemove()
	if ( self.Loop and self.Loop >= 0 ) then
		self:StopLoopingSound( self.Loop )
	end
end
