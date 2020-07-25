ENT.Type = "anim"
ENT.Base = "base_ai"
ENT.PrintName = "Donut County Hole"
ENT.Author = "johnjoemcbob"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.Spawnable = true
ENT.AdminSpawnable = true

GP13_Plate_Size	= 47.45
GP13_Radius		= 47
DONUT_ALLOWANCE	= 1

include( "drive/drive_gp13_donuthole.lua" )

function ENT:Initialize()
	-- Variables
	self.Inside = {}
	self.Size = 0.5
	self.SizeIncrement = 0.1
	self.RemoveAtDepth = 0.1
	self.RemoveTime = 2
	self.PullOffset = Vector( 0, 0, -500 )

	-- Initialise
	self.Scale = Vector( 1, 1, 1 ) * self.Size

	if ( SERVER ) then
		self.Entity:SetModel( "models/hunter/plates/platehole2x2.mdl" )
		self.Entity:DrawShadow( false )
		self.Entity:Resize( Vector( 1, 1, 1 ) )
	end

	-- Start driving
	timer.Simple( 0.2, function()
		if ( SERVER ) then
			drive.PlayerStartDriving( self.Owner, self, "drive_gp13_donuthole" )
		end
		if ( CLIENT ) then
			self:SetPredictable( true )
			drive.PlayerStartDriving( self.Owner, self, "drive_gp13_donuthole" )
		end
	end )
end

function ENT:ResizePhysics( scale )
	-- Parameter can be a float instead of Vector if all axes should be same scale
	if ( scale == tonumber( scale ) ) then
		scale = Vector( 1, 1, 1 ) * scale
	end

	self:PhysicsInit( SOLID_VPHYSICS )

	local heightoff = -7
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		local physmesh = phys:GetMeshConvexes()
			-- Scale up inner donut hole
			if ( not istable( physmesh ) ) or ( #physmesh < 1 ) then return end

			for convexkey, convex in pairs( physmesh ) do
				for poskey, postab in pairs( convex ) do
					local pos = postab.pos
						pos.x = pos.x * scale.x
						pos.y = pos.y * scale.y
						pos.z = pos.z * scale.z + heightoff - 1
					convex[ poskey ] = pos
				end
			end

			-- Add extra edge meshes before continuing
			-- Long Xs
			for x = -1, 1, 2 do
				local y = 3
				local size = GP13_Plate_Size * scale.x
				local min = Vector( -size * x, -size * 1, 0 ) * 3
				local max = min + Vector( size * x, size * y, 0 ) * 2
					min.z = heightoff - 1
					max.z = heightoff
				table.insert( physmesh, {
					Vector( min.x, min.y, min.z ),
					Vector( min.x, min.y, max.z ),
					Vector( min.x, max.y, min.z ),
					Vector( min.x, max.y, max.z ),
					Vector( max.x, min.y, min.z ),
					Vector( max.x, min.y, max.z ),
					Vector( max.x, max.y, min.z ),
					Vector( max.x, max.y, max.z ),
				} )
				-- debugoverlay.Box( self:GetPos(), min, max, FrameTime() * 14, Color( 0, 255, 0, 100 ) )
			end
			-- Short Ys
			for y = -1, 1, 2 do
				local x = 1
				local size = GP13_Plate_Size * scale.x
				local min = Vector( -size / 3, -size * y, 0 ) * 3
				local max = min + Vector( size * x, size * y, 0 ) * 2
					min.z = heightoff - 1
					max.z = heightoff
				table.insert( physmesh, {
					Vector( min.x, min.y, min.z ),
					Vector( min.x, min.y, max.z ),
					Vector( min.x, max.y, min.z ),
					Vector( min.x, max.y, max.z ),
					Vector( max.x, min.y, min.z ),
					Vector( max.x, min.y, max.z ),
					Vector( max.x, max.y, min.z ),
					Vector( max.x, max.y, max.z ),
				} )
				-- debugoverlay.Box( self:GetPos(), min, max, FrameTime() * 14, Color( 0, 255, 0, 100 ) )
			end
		self:PhysicsInitMultiConvex( physmesh )

		self:EnableCustomCollisions( true )
	end

	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end
end
