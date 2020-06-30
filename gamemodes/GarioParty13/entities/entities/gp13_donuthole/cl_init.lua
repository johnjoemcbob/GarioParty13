include( "shared.lua" )

include( "drive/drive_gp13_donuthole.lua" )

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

	print( "drvie" )
	print( self )
	-- drive.PlayerStartDriving( LocalPlayer(), self, "drive_gp13_donuthole" )
end )

function ENT:SendRequestInit( ply )
	net.Start( HOOK_PREFIX .. "ClientRequestInit" )
		net.WriteEntity( self )
	net.SendToServer()
end

function ENT:Draw()
	if ( !self.Scale ) then return end

	local scale = self.Scale.x * 2
	local pos = self:GetPos()
	local dir = self:GetUp()
	local segs = 128

	-- Center
	cam.Start3D2D( pos + dir * 0, self:GetAngles(), scale * 1.1 )
		surface.SetDrawColor( GAMEMODE.ColourPalette[self:GetOwner():GetNWInt( "Colour" )] )
		draw.NoTexture()
		draw.Circle( 0, 0, 24, segs, 0 )
	cam.End3D2D()

	local function inner_mask()
		-- Center
		cam.Start3D2D( pos + dir * 0, self:GetAngles(), scale )
			surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
			draw.NoTexture()
			draw.Circle( 0, 0, 24, segs, 0 )
		cam.End3D2D()
	end
	local function inner_inner()
		for k, v in pairs( ents.FindInSphere( pos, GP13_Radius * scale ) ) do
			if ( v:GetClass() == "prop_physics" ) then
				-- print( v )
				v:DrawModel()
			end
		end
	end
	draw.StencilBasic( inner_mask, inner_inner )

	-- self:DrawModel()

	-- local pos, ang = self:GetPos(), self:GetAngles()

	-- local scale = self.Scale.x
	-- for x = -1, 1, 2 do
		-- local y = 3
		-- local size = GP13_Plate_Size * scale
		-- local min = Vector( -size * x, -size * 1, 0 ) * 3
		-- local max = min + Vector( size * x, size * y, 0 ) * 2
			-- min.z = -2
			-- max.z = -1
		-- render.DrawWireframeBox( pos, ang, min, max, Color( 0, 255, 0, 255 ) )
	-- end
	-- for y = -1, 1, 2 do
		-- local x = 1
		-- local size = GP13_Plate_Size * scale
		-- local min = Vector( -size / 3, -size * y, 0 ) * 3
		-- local max = min + Vector( size * x, size * y, 0 ) * 2
			-- min.z = -2
			-- max.z = -1
		-- render.DrawWireframeBox( pos, ang, min, max, Color( 0, 255, 0, 255 ) )
	-- end
end
